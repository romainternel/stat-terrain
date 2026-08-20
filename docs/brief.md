# Brief — Corrections Audit Final (2026-08-20) + Mode Simple à équipe unique

## Contexte
Deux sources convergent vers ce cycle :
1. L'Audit Final du 2026-08-20 (`docs/audit-final/AUDIT-2026-08-20.md`) a trouvé 1 bug Gênant (pas de Bloquant) et proposé 2 suggestions, toutes acceptées par Romain pour correction.
2. Romain a lui-même identifié, en marge de l'audit, un vrai problème d'usage sur l'écran Match en Mode Simple sur téléphone : les boutons de résultat sont dupliqués (une rangée par équipe, FENIX puis Adversaire empilées), ce qui prend deux fois l'espace vertical nécessaire sur un écran déjà contraint.

Pourquoi maintenant : le Mode Simple existe depuis STORY-23/24 et a été pensé "iPhone-first" (détection auto sous 700px), mais son layout actuel n'a jamais remis en cause le principe "une rangée par équipe" hérité du Mode Expert (qui, lui, affiche forcément les deux équipes côte à côte car le workflow est différent). Romain l'utilise en conditions réelles depuis plusieurs matchs et remonte maintenant ce retour terrain.

## Problème
**Aujourd'hui, sans ces corrections :**
- Un coach qui sauvegarde un match par réflexe en cours de partie puis re-sauvegarde en fin de match crée deux entrées distinctes dans l'historique — sans le savoir, sans message d'avertissement. Bilan → Saison compte alors un match en trop (victoire/défaite en double).
- Les alertes critiques en plein match (buts consécutifs, TM conseillé) s'affichent 2,5 à 4 secondes puis disparaissent sans laisser de trace. Un coach qui a les yeux sur le terrain au mauvais moment les rate intégralement — contrairement au bandeau de rappel GB (STORY-53) qui lui reste affiché.
- L'analyse automatique de fin de match tient un discours de jugement ("jeu trop individuel") même sur un échantillon d'événements minuscule (match écourté, mi-temps interrompue), ce qui n'a pas de sens statistique et peut être perçu comme un jugement hâtif par le coach qui le lit ou le montre aux joueurs.
- En Mode Simple sur téléphone, la moitié de l'écran de saisie est occupée par les boutons de l'équipe qui n'a **pas** la balle — grisés, non cliquables, mais toujours présents et prenant de la place. Le coach doit descendre/remonter dans l'écran plus que nécessaire pour saisir vite, alors que la saisie rapide est justement la raison d'être du Mode Simple.

## Utilisateurs
Romain (et tout aidant occasionnel amené à saisir), en bord de terrain, un œil sur le match et un doigt sur l'écran — le contexte d'usage exact documenté dans `CLAUDE.md` pour le Mode Simple : iPhone en priorité, saisie one-handed, sous contrainte de temps réelle (le jeu continue pendant la saisie).

## Vision
Fiabiliser deux points de fond découverts par l'audit sans changer le comportement visible ailleurs, et réduire de moitié l'espace vertical occupé par la zone de saisie du Mode Simple en n'affichant que les boutons de l'équipe qui a effectivement la balle — la bascule d'équipe devient un simple changement de libellé/couleur, pas un nouveau geste à apprendre.

## Scope

**Dans le scope :**
1. `saveMatch()` met à jour la sauvegarde locale existante de la session en cours plutôt que d'en créer une nouvelle à chaque clic.
2. Les alertes critiques (TM conseillé, changez de GB) laissent une trace consultable après leur disparition — pas seulement le bandeau GB déjà persistant à l'ouverture du match.
3. `autoAnalysis()` n'affiche plus les insights à jugement qualitatif (PD, pertes de balle, efficacité, séries) en dessous d'un seuil minimal d'événements représentatif.
4. Mode Simple : un seul jeu de boutons de résultat affiché à la fois, celui de l'équipe en possession (`S.possession`) ; le libellé et la couleur d'accent basculent automatiquement au changement de possession.

**Hors scope :**
- Toute refonte du Mode Expert (workflow terrain/zone), non concerné.
- Le mécanisme de bascule manuelle de possession (bouton "◉ POSSESSION" du scoreboard) reste inchangé — c'est lui qui pilote quelle équipe est affichée en Mode Simple, pas une nouvelle UI à créer.
- La correction du bug de sauvegarde ne touche pas la synchronisation Supabase (`upsertMatchSnapshot`/`markMatchFinished`), déjà correcte et testée — seul le comportement de l'IndexedDB local (`dbSaveMatch`) change.
- Pas de nouveau système de notifications persistant complexe (centre de notifications) — un historique simple et local suffit pour répondre au besoin.

## Critères de succès
- Sauvegarder deux fois le même match en cours de session ne produit **jamais** deux entrées dans l'historique ni dans Bilan → Saison.
- Une alerte "changez de GB" ratée au moment de son affichage reste consultable dans les secondes/minutes qui suivent, sans devoir la déclencher à nouveau.
- Un match à moins de N événements (seuil à définir par le PM) n'affiche plus d'insights de jugement qualitatif non pertinents à ce volume.
- En Mode Simple, l'écran de saisie n'affiche plus qu'une seule équipe à la fois ; changer de possession (auto après une action, ou manuellement) fait basculer instantanément le libellé et la couleur sans étape supplémentaire ; aucune régression sur le flash de confirmation (`S.simpleFlash`) ni sur l'enregistrement des événements.

## Questions en suspens
- Seuil exact du garde-fou d'événements pour l'Analyse (le PM tranchera un chiffre raisonnable, ex. 10 tirs cumulés).
- Forme exacte de la "trace" des alertes ratées : un petit historique dépliable dans le bandeau existant, ou un nouvel élément dédié ? (le Designer tranchera, en respectant "je ne réinvente pas ce qui existe déjà").
- Mode Simple à équipe unique : Romain a dit "une seule ligne de bouton" — à clarifier si c'est littéral (5 boutons sur une seule rangée CSS) ou "un seul jeu de boutons" (peut garder sa disposition actuelle en 2 rangées de 3+2, juste non dupliqué par équipe). Le Designer proposera une maquette et Romain validera au moment de la story.
