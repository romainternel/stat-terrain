# Brief (diagnostic) — Les matchs PC n'apparaissent pas sur iPad/iPhone

## Rapport de Romain
"pour -18 il n'y a pas mais pour cf oui. Par contre toujours pas les matchs qui apparaissent sur ipad iphone si ils sont en cours ou même enregistré sur pc"

## Ce qui est confirmé fonctionner
Le filtrage par équipe fonctionne au moins en partie : la proposition de reprise de match diffère correctement entre -18 (rien) et CF (un match trouvé) — le mécanisme `team_profile` n'est donc pas cassé partout.

## Relecture ligne par ligne du chemin critique (menée avant toute hypothèse)
- `fetchMissingArchivedMatches()`, `importArchivedMatch()`, `syncArchivedMatchesIntoLocal()` (`app.js` ~ligne 299-346) : logique relue intégralement, cohérente avec l'architecture documentée, aucune erreur trouvée dans le code lui-même.
- Point d'appel (nav `[data-v="history"]`, ~ligne 4402-4415) : se déclenche uniquement au clic réel sur l'onglet "📁 Matchs" — c'est le chemin normal d'usage, pas un angle mort.
- `config.js` (identifiants Supabase) : vérifié suivi par git (`git ls-files`), pas ignoré, donc déployé à l'identique sur tous les appareils/domaines — écarte une hypothèse de config Supabase absente sur un déploiement particulier.

**Aucun bug de code trouvé à la relecture.** Ça ne veut pas dire qu'il n'y en a pas un (le round-trip Supabase réel à deux appareils physiques n'a jamais été testé, seulement simulé via CDP sur un seul navigateur) — mais rien de suspect n'est ressorti d'une lecture attentive.

## Hypothèses classées par plausibilité

**H1 — Service worker pas à jour sur iPad/iPhone (la plus probable)**
`CLAUDE.md` documente déjà ce piège précis pour ce projet : *"Fermer Safari complètement sur iPad → réouvrir pour forcer le nouveau SW"*. Si Romain a testé sur iPad/iPhone en reprenant une session déjà ouverte (pas une fermeture complète + réouverture), ces appareils peuvent exécuter encore une version de `app.js` antérieure à STORY-48/50/51 — dans ce cas, aucune des nouvelles fonctionnalités n'existe sur ces appareils (pas d'écran de choix d'équipe, pas de rapatriement), ce qui produirait exactement le symptôme observé. Cohérent avec le fait que les tests concluants (reprise différenciée -18/CF) semblent avoir été faits sur l'appareil où le code est à jour (probablement le PC).

**H2 — Les deux appareils ne sont pas sur le même profil d'équipe**
Si PC est sur "cf" et iPad/iPhone sur "-18" (ou l'inverse, ou n'a jamais été jusqu'au bout de l'écran de choix), les données ne se rejoindront jamais — comportement voulu (isolation stricte), pas un bug, mais indiscernable d'un bug si ce n'est pas vérifié explicitement.

**H3 — Migration SQL pas ré-exécutée après l'ajout de `team_profile`**
Moins probable : si `team_profile` n'existait pas côté Supabase, `fetchInProgressMatches()` (qui filtre aussi dessus) échouerait silencieusement pour CF aussi, pas seulement pour le rapatriement — or CF fonctionne pour la reprise. Gardée comme hypothèse secondaire, pas écartée à 100%.

**H4 — Bug de code non détecté à la relecture**
Le round-trip Supabase réel entre deux appareils physiques n'a jamais été testé en conditions réelles — seulement simulé. Reste possible malgré une relecture propre.

## Questions factuelles posées à Romain (AskUserQuestion)
- Fermeture complète iPad/iPhone après mise à jour : **Oui** → H1 écartée.
- Même équipe (CF) sur PC et iPad/iPhone : **Oui** → H2 écartée.
- Migration SQL ré-exécutée après ajout de `championnat`/`team_profile` : **"Je ne sais pas"** → H3 restait ouverte.

## Confirmation directe (requête REST brute sur la vraie base Supabase, sans passer par l'appli)
```
GET /rest/v1/matches?select=id,team_profile,championnat
→ team_profile seul : {"code":"42703",...,"message":"column matches.team_profile does not exist"} (HTTP 400)
GET /rest/v1/matches?select=id,season,journee,coach_notes,championnat
→ 200 OK (colonnes toutes présentes, résultat vide car RLS bloque l'accès anonyme aux lignes — la structure de la requête, elle, est valide)
```
**H3 confirmée avec certitude, pas juste plausible** : la colonne `team_profile` n'existe pas sur la vraie base. `season`/`journee`/`coach_notes`/`championnat` existent bien (migration en 4 colonnes déjà exécutée avec succès) — seule la 5ᵉ colonne, ajoutée plus tard pour STORY-50, n'a jamais été poussée. **Erreur de communication de ma part** : j'ai mis à jour le fichier de migration en ajoutant `team_profile` sans redemander explicitement à Romain de le ré-exécuter.

## Conséquence exacte de la colonne manquante
- `upsertMatchSnapshot()` (payload principal incluant `team_profile`) échoue intégralement à chaque appel depuis le déploiement de STORY-50 — PostgREST rejette toute la requête pour une colonne inconnue, pas seulement ce champ. Aucun match "en cours" n'est donc plus correctement synchronisé vers Supabase depuis ce moment (silencieux, `try/catch`).
- `fetchInProgressMatches()`/`fetchMissingArchivedMatches()` (toutes deux filtrées sur `team_profile`) échouent de la même façon — retournent toujours `[]`.
- Le fait que Romain ait observé un résultat différent entre -18 et CF pour la reprise de match reste à éclaircir (peut-être une observation faite avant ce diagnostic, ou un état local résiduel) — **sans incidence sur la conclusion** : la colonne manquante suffit à elle seule à expliquer l'absence totale de synchronisation multi-appareil, quelle que soit l'équipe.

## Verdict de ce cycle
**Pas un bug de code.** Aucune story de correctif nécessaire — le code est correct et cohérent avec le schéma **une fois la colonne présente**. Action requise : Romain ré-exécute le script SQL (déjà idempotent, sans risque de le rejouer). Cf. message direct avec le SQL exact à coller.

## Résolution confirmée
Romain a ré-exécuté le script. Revérifié directement en requête REST brute sur la vraie base : `GET /rest/v1/matches?select=id,team_profile,season,journee,coach_notes,championnat` → HTTP 200 (auparavant HTTP 400 `42703` sur `team_profile` seul). Les 5 colonnes existent maintenant.

## 2e round — le symptôme persistait malgré la colonne corrigée
Romain a retesté avec un match déjà sauvegardé sur PC : toujours invisible sur iPad. Deux questions factuelles posées (AskUserQuestion) :
- Le match testé a été **joué avant** le correctif SQL, pas après.
- L'onglet "📁 Matchs" a bien été ouvert sur iPad (élimine l'hypothèse "mauvais écran").

**Cause exacte identifiée** : `upsertMatchSnapshot()` (payload principal incluant `team_profile`) échouait à **chaque appel** pendant toute la durée de vie de ce match (lancement, changements de mi-temps, chrono, sélection GB...) puisque la colonne n'existait pas encore — la ligne Supabase correspondante n'a donc **jamais été créée**. `saveMatch()`/`markMatchFinishedById()` ne fait que des `update()` (jamais de création) — marquer "finished" une ligne qui n'existe pas est un no-op silencieux, sans erreur. Le match est resté sauvegardé **localement uniquement** sur le PC (visible dans son propre historique), jamais poussé vers Supabase, donc jamais rapatriable ailleurs.

## Correctif appliqué (auto-réparation, `saveMatch()`)
Ajout d'un appel `upsertMatchSnapshot()` (qui fait un vrai `upsert` — crée la ligne si absente) juste avant `markMatchFinished()` dans `saveMatch()`. Rend la sauvegarde résiliente à ce type d'incident (colonne manquante, coupure réseau pendant le match, etc.) — le geste de sauvegarde final garantit désormais que la ligne Supabase existe et contient l'état correct avant d'être marquée terminée, plutôt que de supposer qu'elle a été créée correctement plus tôt.

## Le match spécifique déjà perdu par ce match précis
`loadMatchAsCurrent()` (bouton "📂 Charger" depuis Matchs) coupe volontairement `S.currentMatchId` (fix P0 de STORY-36, à ne pas toucher — évite qu'un match archivé rechargé reçoive par erreur les écritures temps réel d'un autre match). Recharger ce match spécifique depuis la liste ne le "reconnectera" donc pas à Supabase. Deux options pour Romain :
- Si ce match précis est encore ouvert dans l'onglet où il a été joué (jamais rechargé depuis) : cliquer à nouveau sur "💾 Sauvegarder" maintenant que le correctif est en place — devrait créer la ligne manquante.
- Sinon : ce match reste local au PC (perte mineure, pas de perte de données locales, juste pas de copie cloud) — pas de mécanisme de réparation a posteriori construit pour ce cas précis (pas demandé, coût/bénéfice discutable pour un seul match).

## Verdict final de ce cycle
Bug de code réel trouvé (pas seulement un oubli de déploiement) : `saveMatch()` n'avait aucune garantie de créer la ligne Supabase si les upserts précédents avaient échoué pour une raison quelconque — corrigé. **Reste à confirmer par un test avec un match démarré et joué entièrement après ce correctif.**

## 3e round — le match apparaît mais le score ne correspond pas ("1-0" sur iPhone)
Romain : "Quand je l'enregistre il se met à 1-0 sur mon iphone et ne correspond pas à ce que j'ai sur PC."

**Cause** : les événements (buts, tirs...) transitent par une file d'attente locale (`outbox`, IndexedDB) vidée passivement toutes les 15s (`setInterval(flushOutbox,15000)`) — jamais vidée explicitement par `saveMatch()`. Ce match précis avait tous ses événements bloqués dans cette file depuis la période où `team_profile` manquait (la table `matches` n'existant pas encore pour ce match, la contrainte de clé étrangère de `match_events` rejetait tout). Une fois la ligne `matches` recréée (correctif précédent), la file a commencé à se vider **progressivement** via le cycle de 15s — mais le rapatriement côté iPhone a eu lieu **avant** que tous les événements aient fini de se synchroniser, capturant un état partiel (1 seul but sur plusieurs). Or `fetchMissingArchivedMatches()` déduplique par `supabaseMatchId` — un match déjà connu localement n'est **jamais** revérifié ni remis à jour ensuite, même si la source se complète plus tard. La copie partielle reste donc figée sur iPhone indéfiniment.

**Correctif** : `saveMatch()` vide maintenant explicitement la file (`await flushOutbox()`) avant de marquer le match terminé — ferme la fenêtre de course pour tout nouveau match sauvegardé à partir de maintenant.

**Pour ce match précis déjà importé (incomplet) sur iPhone** : ⚠️ ne pas utiliser le bouton 🗑 sur iPhone sans réfléchir — la suppression locale déclenche aussi une tentative de suppression côté Supabase (même `supabaseMatchId`), ce qui supprimerait la seule copie cloud existante. Cette copie de test n'a pas d'enjeu réel (née pendant la fenêtre de debug) — recommandation : ignorer ce match de test précis, et valider le correctif avec un **match entièrement nouveau** joué de bout en bout maintenant que le fix est en place (le chemin le plus sûr et le plus représentatif d'un usage réel).
