# QA — STORY-48 (sync historique), STORY-50 (fondation deux équipes), STORY-51 (écran de choix)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-48-sync-historique-multi-appareil.md`, `STORY-50-fondation-deux-equipes.md`, `STORY-51-ecran-choix-equipe.md`, `docs/code-review/STORY-48-50-51.md` (APPROUVÉ, 3 fuites de filtrage trouvées et corrigées en revue), `docs/risks/deux-equipes.md`, `docs/risks/sync-historique-multi-appareil.md`.

## Méthode
CDP sur Chrome headless. Vrais clics réels (`Input.dispatchMouseEvent`) pour l'écran de choix d'équipe et le workflow principal. Vérifications de fond (isolation des données, exclusion Amical) faites par appel direct des fonctions de filtrage/agrégation avec des jeux de données construits, pour tester précisément la logique sans dépendre du rendu DOM (contournement du bug d'outillage CDP déjà documenté cette session).

## Critères d'acceptation — STORY-51 (écran de choix)
- [x] Écran affiché tant qu'aucun `S.teamProfile` n'est mémorisé — confirmé par clic réel, capture d'écran
- [x] Clic réel sur "-18" → `S.teamProfile==="u18"`, écran disparaît, effectif par défaut "FENIX Toulouse -18" chargé
- [x] Persistance confirmée après un **vrai rechargement complet de page** (pas juste en mémoire) — écran de choix non réaffiché, profil toujours "u18"
- [x] Aucun bouton retour sur cet écran — confirmé par lecture du markup généré

## Critères d'acceptation — STORY-50 (fondation)
- [x] **Isolation stricte des effectifs** : `hb2_teams_cf`/`hb2_teams_u18` indépendantes — confirmé par lecture de code et par le nom d'équipe par défaut correct selon le profil actif
- [x] **Isolation stricte des matchs locaux** : un match sauvegardé sous "cf" (`teamProfile:"cf"`) est absent de la liste filtrée sous "u18", et réciproquement — testé directement sur `dbGetAll()` + filtre, avec un vrai match sauvegardé en IndexedDB (pas une simulation en mémoire)
- [x] **Championnat en saisie libre avec mémoire par équipe** : simulation d'un événement `change` réel sur le champ → valeur mémorisée dans `hb2_championnats_u18`, distincte de celle de `hb2_championnats_cf`
- [x] **Exclusion "Amical" du bilan de saison, insensible à la casse** : jeu de 4 matchs (`N1`, `Amical`, `amical`, `N2`) → seuls les 2 matchs non-amicaux retenus, testé avec la casse mixte explicitement pour vérifier `.toLowerCase()`
- [x] **`newMatch()` réinitialise bien `S.championnat` à `""`**, et `markMatchFinished()` est appelée **avant** les resets (pas après) — vérifié par lecture de code après correction du bug d'ordre trouvé en Code Review
- [x] **Bouton "Changer d'équipe"** affiche le profil actif dans son propre libellé — confirmé par lecture directe du texte du bouton rendu (`🔄 Changer d'équipe (actuellement : -18)`)
- [x] **`checkForResumableMatch()` correctement gardée** aux deux points d'appel (`checkAuthSession`/`signInShared`) — vérifié par lecture de code

## Critères d'acceptation — STORY-48 (sync historique)
- [x] Fonctions de rapatriement (`fetchMissingArchivedMatches`/`importArchivedMatch`/`syncArchivedMatchesIntoLocal`) présentes et conformes à l'architecture — filtrées par `team_profile` en plus de `status='finished'` (extension apportée par STORY-50, cohérente)
- [x] Indicateur "🔄 Recherche de matchs..." et toast "+N match(s) récupéré(s)" présents dans `renderHistory()` — vérifiés par lecture de code
- [x] Une seule tentative par chargement de page (`S._historySyncedThisLoad`) — vérifié par lecture de code

## Cas limites testés
- **Fuites de filtrage** (trouvées en Code Review, pas en QA — déjà corrigées avant cette passe) : `exportAllMatches()`, `importAllMatches()`, suppression de match — tous les 3 re-vérifiés après correction, filtrage confirmé présent dans le code livré
- **Casse mixte sur "Amical"** ("Amical" vs "amical") : les deux exclus correctement
- **Migration `hb2_teams`→`hb2_teams_cf`** : logique one-shot vérifiée par lecture de code (`if(!localStorage.getItem("hb2_teams_cf") && localStorage.getItem("hb2_teams"))`) — ne s'exécute qu'une fois, ne écrase jamais un `hb2_teams_cf` déjà présent

## Point non vérifiable dans cet environnement — à confirmer par Romain
`<datalist>` (suggestions du champ Championnat) sur un **vrai iPad Safari** — CDP headless ne permet pas de valider fidèlement le rendu natif de ce composant sur iOS. Signalé explicitement à Romain, pas juste noté dans les docs internes.

## Bugs trouvés
Aucun dans le périmètre de cette QA — les 3 fuites de filtrage et le bug d'ordre dans `newMatch()` ont été trouvés et corrigés en amont (Developer/Code Review), déjà re-vérifiés ici comme corrigés.

## Régressions détectées
Aucune — `resumeMatch()`, mode lecteur, bascule Simple/Expert, export/import CSV (comportement fonctionnel préservé, juste correctement filtré maintenant) tous vérifiés non cassés par lecture de code ciblée sur les fonctions modifiées.

## Verdict
**PASSED** — avec un point de vigilance explicite (datalist iPad) et un point de gouvernance explicite (R0, données de mineurs) à confirmer par Romain, non bloquants pour la mise en production mais nécessitant sa validation consciente.
