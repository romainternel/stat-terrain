# Audit sécurité — Suppression réelle d'un match sur Supabase (STORY-27)

*Audit de l'implémentation réelle (`app.js`) après livraison, avant feu vert QA. Rejoue le contexte déjà acté dans `docs/security/supabase-multiuser.md` (design) et `docs/security/supabase-project-live.md` (vérification sur le vrai projet) — ce document-ci se concentre spécifiquement sur ce que la nouvelle capacité de suppression change (ou non) à ce périmètre déjà validé.*

## Verdict en une ligne

**Aucun Critique.** `deleteSupabaseMatch(matchId)` n'introduit **aucun nouveau risque d'accès** : elle s'exécute entièrement à l'intérieur du modèle de permission déjà accepté et vérifié en feu vert depuis STORY-10 (compte unique partagé, RLS `for all` = accès total lecture/écriture/**suppression** à quiconque authentifié). Un seul point Mineur relevé (avertissement UI incomplet sur le caractère irréversible/multi-appareil de la suppression).

## Ressources concernées
- Table `matches` (DELETE), table `match_events` (DELETE) — `docs/supabase-setup.sql`.
- Fonction `deleteSupabaseMatch(matchId)` (`app.js:1371-1378`), appelée depuis le handler `[data-del-match]` (`app.js:3890-3902`).
- Policy déjà en place : `create policy "authenticated full access" on matches for all using (auth.role() = 'authenticated') with check (...)` — idem sur `match_events`. **`for all` inclut DELETE**, ce n'était pas nouveau : `dequeueEventSync()` (`app.js:275-281`, STORY-12) fait déjà `client.from('match_events').delete().eq('id',event.id)` depuis longtemps sous la même policy.

## Findings

### 🟢 Point 1 — Forge de `matchId` pour supprimer le match d'un autre : pas un nouveau risque

**Analyse.** `matchId` vient du champ local `supabaseMatchId` (uuid `crypto.randomUUID()`, généré par `gid()`, `app.js:37-42`) stocké sur l'objet match en IndexedDB. Un utilisateur du compte partagé pourrait effectivement, via la console du navigateur, appeler `deleteSupabaseMatch(idQuelconque)` avec n'importe quel uuid — y compris celui d'un match qu'il n'a pas lui-même créé.

**Mais ce n'est pas une nouvelle surface d'attaque.** La policy RLS `for all using (auth.role() = 'authenticated')` donne déjà, à tout appareil authentifié avec le mot de passe partagé, un accès total en suppression sur **toutes** les lignes des deux tables — avec ou sans cette fonction. Un utilisateur mal intentionné n'a même pas besoin de connaître un `matchId` précis ni de passer par `deleteSupabaseMatch` : il peut ouvrir la console et exécuter directement `sbClient.from('matches').delete()` (sans filtre `.eq`) pour vider la table entière, ou `dequeueEventSync()` existe déjà depuis STORY-12 pour supprimer n'importe quel `match_events` par id arbitraire. `deleteSupabaseMatch` ne fait qu'exposer, via un bouton UI, une capacité de suppression ciblée (par `match_id` précis) qui était de toute façon déjà disponible en clair à quiconque a le mot de passe partagé.

**Conclusion** : le périmètre de risque ne change pas. C'est le modèle "compte unique = confiance totale entre appareils connectés" déjà tranché et documenté en D2/STORY-10 (`docs/security/supabase-multiuser.md`, finding 🟠 Majeur "Aucune distinction lecture/écriture au sein du compte unique", déjà accepté comme risque assumé). Rien à bloquer ici — mais je confirme explicitement que ce Majeur déjà accepté couvre désormais aussi la suppression ciblée par match, pas seulement l'écriture/lecture en vrac. Pas de recommandation nouvelle au-delà de ce qui est déjà acté (isolation par compte individuel serait le seul vrai remède, explicitement hors scope du projet).

### 🟢 Point 2 — Confirmation utilisateur avant suppression : bien en place, pas de suppression en masse

Vérifié dans le handler (`app.js:3890-3902`) :
```js
el.onclick=async()=>{
  const id=parseInt(el.dataset.delMatch);
  if(!safeConfirm("Supprimer ce match ?")) return;
  const m=S.matchHistory.find(x=>x.id===id);
  try{
    await dbDelete(id);
    S.matchHistory=await dbGetAll();
    if(m?.supabaseMatchId) deleteSupabaseMatch(m.supabaseMatchId);
  }catch(e){ console.error(e); }
  R();
};
```
- `safeConfirm(...)` bloque bien l'exécution si l'utilisateur annule (`return` immédiat) — un seul clic sur 🗑 ne peut pas contourner la confirmation.
- Un seul match est traité par clic ; recherche exhaustive dans `app.js` (`dbDelete`, `deleteSupabaseMatch`, boucle sur `matchHistory`) : **aucun point d'appel en boucle/masse** n'existe. Pas de fonction "tout supprimer" qui itérerait sans confirmation individuelle.
- `deleteSupabaseMatch` n'est appelée qu'à un seul endroit, avec garde `if(m?.supabaseMatchId)` côté appelant et garde `if(!client||!matchId) return;` côté fonction elle-même — pas de risque d'appel avec un id `undefined`/vide qui viendrait heurter une clause `.eq()` mal formée.

Aucun risque de suppression accidentelle en masse identifié.

### 🟡 Mineur — Texte de confirmation ne mentionne pas le caractère irréversible ni la portée multi-appareil

Le texte `"Supprimer ce match ?"` ne précise pas que :
1. L'action est **définitive** (pas de corbeille, pas d'annulation possible une fois la ligne supprimée côté Supabase et en local) ;
2. Dans une architecture multi-appareil synchronisée en temps réel, la suppression retire aussi ce match de **tous les autres appareils connectés** qui l'auraient éventuellement (le match n'existe plus qu'en tant que ligne Supabase pour un appareil qui ne l'a pas en local, ex. reprise via `resumeMatch()`).

Ce n'est pas une faille d'accès (la confirmation existe, elle bloque bien l'action) mais un manque d'information qui augmente le risque d'une suppression regrettée par un aidant occasionnel peu familier de l'app — cohérent avec le Majeur déjà noté dans `supabase-multiuser.md` ("aucune barrière technique au-delà des confirmations UI, donc ces confirmations doivent rester systématiques et suffisamment explicites").

**Recommandation (non bloquante)** : enrichir le texte, par exemple `"Supprimer ce match ? Cette action est définitive et supprime aussi les données sur Supabase (tous les appareils)."` — coût quasi nul, améliore la seule barrière réelle qui existe dans ce modèle de permission.

## Ce qui N'est PAS un problème (vérifié, pour mémoire)

- **Pas d'injection** : `deleteSupabaseMatch` utilise l'API `supabase-js` (`.eq('match_id', matchId)`), pas de construction de requête SQL brute — pas de surface d'injection.
- **Ordre des suppressions respecté** : `match_events` supprimés avant `matches`, conforme à l'absence de `ON DELETE CASCADE` dans `docs/supabase-setup.sql` — pas un problème de sécurité mais confirme que le comportement décrit dans STORY-27 correspond au code livré.
- **Best-effort, non bloquant** : l'échec réseau de `deleteSupabaseMatch` est absorbé (`catch(e){}`), cohérent avec le principe fail-open déjà acté dans `CLAUDE.md` — n'affecte pas la sécurité, seulement la résilience.
- **Pas de nouvelle clé/secret exposé** : aucune clé supplémentaire introduite par cette feature, le client Supabase utilisé est le même `sbClient` déjà audité.
- **Traçabilité** : toujours absente (aucun log de qui a supprimé quoi), mais c'est un Mineur déjà documenté et accepté dans `supabase-multiuser.md`, pas une régression introduite par STORY-27.

## Verdict

**Feu vert du Security Auditor pour STORY-27.** Aucun Critique, aucun Majeur nouveau. Le risque théorique de suppression d'un match "qui n'est pas le sien" existe, mais il n'est pas nouveau : il découle entièrement du modèle de permission `for all`/compte partagé déjà tranché en STORY-10 et déjà vérifié en feu vert sur le projet réel (`supabase-project-live.md`). Un seul point Mineur (texte de confirmation à enrichir) — amélioration recommandée, non bloquante pour le QA.

## Comment je travaille avec les autres agents
Le point Mineur (texte de confirmation) peut être traité en petite correction hors-cycle par le Developer sans repasser par tout le squad. Aucun blocage transmis au QA — mon verdict Critique ne s'applique pas ici, donc pas d'obstacle à son feu vert.
