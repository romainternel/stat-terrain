# STORY-28 — Abandonner un match proposé comme "reprenable"

## Origine
Romain bloqué sur l'écran "Match en cours" (STORY-14) : deux anciens matchs de test ("FENIX Toulouse vs Adversaire", "FENIX Toulouse vs IVRY", débutés la veille) continuaient à être proposés en reprise à chaque ouverture de l'app. Le seul bouton disponible en dehors de "Reprendre" était "Non, nouveau match", qui ne fait que fermer l'écran localement (`dismissResumePrompt()`) sans jamais marquer ces matchs comme terminés côté Supabase — ils réapparaissaient donc indéfiniment, sur tous les appareils.

## Comportement attendu
- Chaque match proposé dans l'écran de reprise a maintenant un bouton 🗑 à côté de "Reprendre →".
- Cliquer dessus demande confirmation, puis marque ce match `status:'finished'` sur Supabase (même mécanisme que lorsqu'on sauvegarde ou abandonne son propre match en cours) — il ne sera donc plus jamais proposé en reprise.
- Les événements déjà saisis pour ce match restent sur Supabase (pas de suppression) — cohérent avec le comportement existant de `newMatch()`/`saveMatch()` qui ne font eux non plus que "finir" un match, jamais le supprimer.
- Le match disparaît immédiatement de la liste affichée après confirmation.

## Notes d'implémentation
- `markMatchFinished()` (existant, opérait uniquement sur `S.currentMatchId`) généralisé en `markMatchFinishedById(matchId)`, `markMatchFinished()` devient un simple alias pour ne pas toucher aux appels existants.
- Nouvelle fonction `discardResumableMatch(matchId)` : confirmation → `markMatchFinishedById` → retire le match de `S.resumePrompt` → re-render.
- Bouton `[data-discard-match]` ajouté dans `renderResumePrompt()`, lié dans `bind()`.

## Dépend de
STORY-14.

## Taille
XS
