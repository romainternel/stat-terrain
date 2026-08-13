# Brief — Zones d'origine du tir + split 1ère/2e mi-temps (PDF)

## Origine
Romain a partagé un PDF de référence produit par un outil concurrent (Steazzi, rapport de match handball) pour évaluation par le squad BMAD. Deux éléments de cette référence répondent à un vrai manque identifié dans le PDF FENIX Stats actuel (v88, post-STORY-39) ; un troisième (activité +/- et temps de jeu réel) a été explicitement écarté de ce lot — cf. section Hors scope.

## Besoin réel (pas juste "copier la référence")
Le PDF FENIX Stats répond déjà bien à *"où le tir a fini"* : la grille Zones d'impact (page Gardiens et Carte tir joueur, STORY-39) montre le ratio buts/total par zone du BUT, perspective tireur. Il ne répond à aucune question sur *"d'où le tir est parti"* — alors que FENIX Stats capture déjà cette donnée (x/y de chaque tir via `clickCourtPosition()`), elle n'est actuellement utilisée que pour positionner un point sur le mini-terrain (`drawCourt()`), jamais agrégée par zone. C'est une vraie question de coach ("d'où marque-t-on efficacement ? d'où perd-on des tirs ?") qui reste sans réponse chiffrée dans le PDF alors que la donnée existe déjà.

Le second besoin est plus mineur mais réel : le tableau Joueurs affiche le total de buts par joueur sans distinguer la 1ère et la 2e mi-temps, alors que `event.period` est déjà capturé sur chaque événement et que la question "ce joueur a-t-il été décisif en fin de match ?" revient régulièrement en debrief.

## Ce qui n'est PAS le besoin
- Ne pas dupliquer mécaniquement le découpage à 7 zones de la référence (aile G/D, demi-centre G/D, centrale, 7m, éloignée) sans le confronter à la géométrie réelle du handball et à ce qui existe déjà dans FENIX Stats.
- Ne pas ajouter une 3e grille de couleurs différente — la nouvelle grille doit se lire comme une extension naturelle de la grille Zones d'impact déjà connue de Romain, pas comme un nouveau système à apprendre.
- Ne pas surcharger visuellement des pages déjà denses (Gardiens, Carte tir joueur) — le PDF a déjà fait l'objet de 3+ refontes cette session (v80-v88), la discipline de scope prime sur l'exhaustivité.

## Hors scope (explicitement écarté de ce lot)
- **"Activité - Résumé"** (indicateur +/- par joueur, temps de jeu réel) — vu dans la référence Steazzi, suppose de tracker les entrées/sorties de terrain en direct pendant la saisie, un concept absent du modèle de données actuel (`S.events` n'a aucune notion de "qui est sur le terrain à l'instant T"). C'est un chantier de saisie live, pas un ajout PDF — à recadrer séparément si Romain le souhaite.
- **Timeline de tirs possession par possession** (page "TIRS" de la référence, pastilles numérotées par possession) — jugée par le Visual Crafter trop dense pour l'impression face à ce que FENIX a déjà (carte de tir + zones). Non retenue.

## Parties prenantes
Romain (utilisateur unique, coach FENIX Toulouse Nationale 1) — décideur final sur la lecture terrain de la nouvelle grille.

## Contrainte de fond
`generatePDF()` (app.js) est la fonction la plus retouchée de la session (STORY-38 indirectement, STORY-39 directement, plus 3 correctifs hors-cycle avant elles). Toute nouvelle grille doit réutiliser au maximum les fonctions de rendu déjà en place (`drawGoalZone`, couleurs, légendes) plutôt qu'introduire un système parallèle.
