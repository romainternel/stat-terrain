# STORY-42 — PDF : tableau Joueurs, format BUT/TIR + colonne PO

**En tant que** Romain,
**Je veux** un tableau Joueurs avec BUT/TIR en format combiné, une colonne PO, et MT1/MT2 aussi en format but/tir,
**Afin de** lire l'efficacité réelle par mi-temps sans recalculer à la main, dans l'ordre de lecture qui me convient.

Révision du format livré en STORY-41 (v89), suite à retour direct de Romain — cf. `docs/brief-v10-zones-terrain-et-tableau-joueurs.md`.

## Contexte technique
- Zone concernée : `app.js`, `generatePDF()` — agrégation `playerStats` (~ligne 4770) et `drawPlayerTable()` (~ligne 4834)
- Référence architecture (colonnes exactes, largeurs, calcul) : `docs/arch/zones-terrain-et-tableau-joueurs.md`
- `PEN_OBT` déjà capturé avec `playerId` (`app.js` ~ligne 693) — pas de nouvelle capture, juste un comptage à ajouter

## Critères d'acceptation
- [ ] Colonnes dans l'ordre : `#, NOM, POSTE, BUT/TIR, EFF%, PO, PD, PB, 2M, MT1, MT2`
- [ ] `BUT/TIR` affiche un format combiné (ex "6/8"), plus de colonnes BUTS/TIRS séparées
- [ ] `PO` compte les événements `PEN_OBT` attribués au `playerId` de la ligne
- [ ] `MT1`/`MT2` affichent un format combiné "buts/tirs de la mi-temps" (ex "3/5"), pas seulement le nombre de buts — la dénominateur inclut but+arrêt+hors-cadre de cette mi-temps, pas seulement les buts (cf. Risk R5, piège de double comptage)
- [ ] `tableX` (centrage) recalculé en cohérence avec la nouvelle somme de largeurs de colonnes (150mm) — vérifié visuellement, pas seulement calculé
- [ ] Effectif complet (14+14, jeu de test déjà utilisé en STORY-39/40/41) : tableau toujours centré, lisible, sans chevauchement, y compris avec des valeurs à 2 chiffres dans BUT/TIR ou MT1/MT2
- [ ] Cas limite : joueur avec un tir arrêté en MT1 et aucun but → affiche "0/1" en MT1, pas "0/0" ni une case vide

## Hors scope
Tout ce qui touche à la visualisation de zones sur le terrain (STORY-43/44/45) — story indépendante, aucune dépendance.

## Dépend de
Aucune.

## Taille
S
