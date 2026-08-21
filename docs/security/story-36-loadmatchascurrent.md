# Audit sécurité — `loadMatchAsCurrent()` et correctif P0 Realtime (STORY-36)

*Produit par le Security Access Auditor — squad de contrôle final BMAD*
*Audit du code réellement livré dans `app.js` (pas seulement de la spec de la story), vérifié ligne par ligne.*

## Verdict en un mot

**Aucun Critique. Le correctif P0 tient — le trou décrit par le Risk Analyst est réellement colmaté.** Un finding Majeur est remonté, mais il est **préexistant** (identique dans `newMatch()`, déjà en production depuis STORY-12/14) et n'est ni introduit ni aggravé par cette story — il ne bloque donc pas le feu vert de STORY-36, mais mérite un ticket séparé.

## Ressources concernées
- `S.currentMatchId`, canal Realtime (`realtimeChannel`), table `matches`, table `match_events` (Supabase).
- File d'attente locale `pendingSync` (IndexedDB, `outbox*`).
- Fonctions : `loadMatchAsCurrent()` (~1464-1497), `newMatch()` (~1441-1458), `unsubscribeMatchEvents()`/`subscribeMatchEvents()` (~411-434), `upsertMatchSnapshot()`/`queueEventForSync()`/`flushOutbox()` (~253-323), `eventToSupabaseRow()`/`outboxPut`/`outboxGetAll` (~238-246, 486-503).

## 1. Timing exact — ordre des opérations

Vérifié par lecture directe (`app.js` lignes 1464-1497) : `S.currentMatchId = null;` et `unsubscribeMatchEvents();` (lignes 1477-1478) s'exécutent **immédiatement après** le `safeConfirm()` accepté, et **avant** toute ligne touchant `S.home`/`S.away`/`S.events`/`S.time`/`S.period` (lignes 1480+). Conforme à AC1.

Plus important que l'ordre textuel : **il n'existe aucune fenêtre de course possible**, pas seulement "peu probable". `loadMatchAsCurrent()` n'est pas une fonction `async` et ne contient aucun `await` entre la confirmation et le rendu final (`R()` en tout dernier, ligne 1495) — tout le corps s'exécute en un seul tour de boucle d'événements JS, sans interruption possible. `safeConfirm()` (ligne 1145-1147) enveloppe le `window.confirm()` natif, qui est lui-même bloquant/synchrone. Un message Realtime entrant ne peut être traité par le navigateur qu'entre deux tours de la boucle d'événements (JS mono-thread, exécution "run-to-completion") — il ne peut donc jamais s'intercaler entre `unsubscribeMatchEvents()` et le reset de `S.events`. Le pire cas possible est qu'un message déjà en attente s'applique **avant** que l'utilisateur ait cliqué "Charger" (comportement légitime, le vrai match était encore affiché) — jamais après.

**Verdict** : garantie structurelle, pas probabiliste. Confirmé.

## 2. `unsubscribeMatchEvents()` — désabonnement réel ou flag local ?

```js
function unsubscribeMatchEvents(){
  if(!realtimeChannel) return;
  const client=initSupabaseClient();
  if(client){ try{ client.removeChannel(realtimeChannel); }catch(e){} }
  realtimeChannel=null;
}
```

`client.removeChannel(channel)` est la vraie API `supabase-js` v2 : elle désabonne le canal côté serveur (leave Phoenix) **et** le retire de la table de routage interne du client. Même si un message arrivait sur le socket juste après (improbable puisque le serveur a déjà traité le "leave"), le client ne le dispatcherait plus vers ce canal puisqu'il n'est plus dans sa liste. Ce n'est donc pas un flag cosmétique.

Point vérifié en plus : `initSupabaseClient()` (lignes 140-145) met en cache `sbClient` dès le chargement du module (`initSupabaseClient();` ligne 146) et retourne toujours cette même instance ensuite. Un `realtimeChannel` n'existe que si `client` était déjà non-null au moment de sa création (`subscribeMatchEvents` a la même garde) — donc le `if(client)` de `unsubscribeMatchEvents()` ne peut jamais être un faux-négatif dans ce flux : si un canal est actif, le client existe forcément encore.

**Verdict** : désabonnement réel, confirmé.

## 3. Risque résiduel côté `pendingSync`/`flushOutbox()`

Vérifié : `match_id` est **figé au moment de la mise en file**, pas recalculé à l'envoi.

- `queueEventForSync(event)` (ligne 271) appelle `eventToSupabaseRow(event, S.currentMatchId)` **au moment de l'appel**, avant tout `await` — la valeur de `S.currentMatchId` à cet instant précis (celle du vrai match en cours) est gravée dans l'objet `row` avant d'être poussée dans IndexedDB via `outboxPut`.
- `flushOutbox()` (ligne 301) relit ces objets tels quels via `outboxGetAll()` et fait `client.from('match_events').upsert(row)` — il utilise `row.match_id` (déjà figé), **jamais** `S.currentMatchId` au moment du flush.

Conséquence : des événements du vrai match en cours, mis en file avant le chargement du match archivé (ex. réseau coupé), continueront d'être envoyés vers le **bon** `match_id` même si `S.currentMatchId` a changé entre-temps (mis à `null`, puis régénéré pour un autre contexte). Aucune contamination croisée possible par ce chemin.

**Finding résiduel (Majeur, préexistant, hors scope de blocage pour STORY-36)** : `matchRegisteredThisSession` (ligne 249) est un flag global qui ne repasse jamais à `false` après son premier passage à `true`, ni dans `newMatch()` ni dans `loadMatchAsCurrent()`. `flushOutbox()` n'appelle `ensureMatchRegistered()` (qui crée la ligne `matches`) que si ce flag est encore `false` (ligne 310). Scénario réaliste : le vrai match est déjà enregistré tôt dans la session (flag passé à `true`) ; l'utilisateur charge un match archivé (`S.currentMatchId=null`), puis déclenche une seule action de score (ex. TM ou but) **sans** passer par sélection GB/chrono/mi-temps (les seuls autres appels directs à `upsertMatchSnapshot()`) — `queueEventForSync` régénère alors un nouvel id via `gid()`, mais comme le flag est déjà `true`, aucune ligne `matches` n'est jamais créée pour ce nouvel id. Le schéma SQL (`docs/supabase-setup.sql` ligne 19 : `match_id uuid references matches(id)`) impose une contrainte de clé étrangère — l'`upsert` sur `match_events` échoue alors silencieusement (capturé par le `catch` générique, commentaire trompeur "réseau indisponible"), la ligne reste en file d'attente **indéfiniment**, retentée toutes les 15s sans jamais réussir, sans erreur distincte pour l'utilisateur au-delà de l'indicateur "↻ envoi…" qui ne se résout jamais.

Ce défaut est **identique et déjà présent dans `newMatch()`** (même pattern `S.currentMatchId=null` sans reset du flag, déjà en production) — STORY-36 ne fait qu'étendre un pattern déjà accepté, elle ne l'introduit pas. Il touche l'intégrité/fiabilité de la synchronisation (perte silencieuse d'événements en file), pas un accès non autorisé entre rôles — hors du périmètre strict de cet audit d'accès, mais je le remonte car il touche directement la question d'intégrité des données Supabase partagées posée pour cette story. **Recommandation : ticket séparé (Code Reviewer/Developer), pas un blocage de STORY-36.**

## 4. Régénération de `match_id` "à la volée" — cohérent avec `newMatch()` ou nouveau trou ?

Scénario testé explicitement (l'utilisateur charge le match archivé pour le PDF, ne fait **aucune** action supplémentaire, revient en arrière) : **aucune écriture Supabase ne se produit**. Vérifié :
- Le seul timer périodique global est `setInterval(()=>flushOutbox(),15000)` (ligne 330) ; `flushOutbox()` retourne immédiatement si `pending.length===0` (ligne 309) — rien n'est en file, donc rien n'est envoyé.
- `upsertMatchSnapshot()` se protège elle-même : `if(!client||!S.currentMatchId) return;` (ligne 255) — tant qu'aucun événement n'a régénéré un id, elle est un no-op garanti.

Donc l'hypothèse précise posée par la story (aucune action, retour en arrière) est **sûre**, confirmé.

Si l'utilisateur agit malgré tout (sélection GB, chrono, ou pire, saisie d'un score), le comportement "nouvel id régénéré au prochain événement" est **strictement symétrique** à `newMatch()`, déjà accepté en production — pas un nouveau cas non couvert en soi. Nuance notée en positif : le nouveau raccourci PDF (`data-load-match-pdf`) atterrit directement sur Stats→PDF (`gotoView:"stats"`), donc **hors de l'écran Match** où vivent les boutons d'action — la surface de clic accidentel pour déclencher une action de score y est en pratique plus réduite que via "📂 Charger" de l'Historique (qui atterrit lui sur l'écran Match complet, comportement inchangé et déjà accepté). Le seul vrai risque résiduel dans ce scénario "action accidentelle" est le finding Majeur préexistant du point 3 ci-dessus (échec silencieux de sync, pas une fuite de données).

## 5. Modèle de permission — périmètre inchangé ?

Confirmé, aucune nouvelle surface :
- `loadMatchAsCurrent(id)` lit uniquement `S.matchHistory` (tableau local, IndexedDB, ids numériques `Date.now()`) — totalement indépendant des `id` uuid de Supabase (`matches.id`). Aucune nouvelle requête Supabase en lecture n'est introduite par cette fonction.
- Le seul effet de bord Supabase est `unsubscribeMatchEvents()` — une fermeture de canal, pas une nouvelle exposition.
- Aucune nouvelle table, colonne, ni policy RLS touchée. La policy `authenticated` "full access" (lecture/écriture totale pour le compte unique partagé, `docs/supabase-setup.sql`) reste strictement celle déjà auditée en STORY-10/12/13/14/27.
- Aucune clé/secret nouveau exposé côté client — toujours via `sbClient` (clé anon déjà auditée), jamais `service_role`.

**Verdict** : périmètre de permission inchangé, cohérent avec `docs/security/supabase-multiuser.md` et les audits précédents.

## Synthèse des findings

| # | Sévérité | Résumé | Bloque STORY-36 ? |
|---|----------|--------|--------------------|
| 1 | — | Timing du correctif P0 : garantie structurelle (mono-thread, pas d'`await`), pas seulement testée empiriquement | Non — conforme |
| 2 | — | `unsubscribeMatchEvents()` fait un vrai désabonnement Realtime (`removeChannel`), pas un flag local | Non — conforme |
| 3 | 🟠 Majeur (préexistant) | `matchRegisteredThisSession` jamais réinitialisé → un `match_id` régénéré à la volée peut échouer silencieusement à se synchroniser (violation FK), retenté indéfiniment sans erreur claire. Identique dans `newMatch()`, déjà en prod | **Non** — non introduit par cette story, ticket séparé recommandé |
| 4 | — | Scénario "charge le PDF, ne fait rien, revient" : zéro écriture Supabase, vérifié par lecture de code | Non — conforme |
| 5 | — | Aucune nouvelle surface de permission/exposition, périmètre RLS inchangé | Non — conforme |

Aucun Critique. Le correctif P0 protège réellement contre le scénario décrit par le Risk Analyst (écrasement du vrai match en cours par les données d'un match archivé via Realtime ou `upsertMatchSnapshot()`) — vérifié au niveau du code, pas seulement de la spec.

## Comment je travaille avec les autres agents
Le finding Majeur (#3) n'est pas un blocage pour le feu vert de STORY-36 (préexistant, symétrique à `newMatch()` déjà en production, hors diff de cette story), mais je le signale explicitement pour qu'il devienne un ticket de dette technique suivi séparément — sans quoi il resterait un angle mort silencieux sur la fiabilité de la synchronisation Supabase pour n'importe quel 2e match démarré dans la même session navigateur.

## Addendum (2026-08-21) — finding #3 refermé, sans lien direct

Repéré à nouveau lors d'un compte-rendu Superviseur (jamais transformé en ticket entre-temps), puis testé en conditions réelles avant correction. **Le scénario ne reproduit plus** : `queueEventForSync()` (STORY-66, livrée le 2026-08-20 pour une raison totalement différente — corriger une boucle d'erreurs 409 sur un match archivé rechargé puis modifié) appelle désormais `upsertMatchSnapshot()` directement et sans condition dès qu'un `S.currentMatchId` vide se voit régénérer un id — donc avant même que `matchRegisteredThisSession` n'entre en jeu. Vérifié empiriquement : flag forcé à `true` juste après un reset de `S.currentMatchId`, puis un événement réel enregistré — la ligne `matches` du nouveau match est bien créée et l'événement synchronise correctement malgré le flag périmé.

`matchRegisteredThisSession` reste maintenant remis à `false` aux 3 points où `S.currentMatchId` est invalidé (`newMatch()`, `loadMatchAsCurrent()`, `switchTeamProfile()` — ce dernier partageait le même défaut, jamais mentionné dans l'audit d'origine) — un durcissement défensif documenté comme tel dans le code, pas un correctif d'un bug actif. Pas de story dédiée, pas de cycle QA/E2E complet : changement à risque nul, gardé sur décision explicite de Romain après explication du contexte.
