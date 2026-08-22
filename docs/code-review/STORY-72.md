# Code Review — STORY-72 : vraie distinction 6m / 6-9m / 9m sur le terrain de zones

*Produit par le Code Reviewer — squad de contrôle BMAD*
*Diff revu : `app.js` — `shotZoneCourt()`, `COURT_ZONE_ORDER`, `COURT_ZONE_LABEL_POS`, `buildCourtZones()`*

## Diff revu
Étend `shotZoneCourt()` à 3 bandes de profondeur par secteur (11 zones au lieu de 8) et reconstruit `buildCourtZones()` en conséquence. `aggregateCourtZones()`/`renderCourtZones()` non touchées (déjà génériques sur `COURT_ZONE_ORDER`, conforme à l'analyse de l'Architecture).

## Conformité Architecture
- **F1 classification** (`docs/architecture/zones-tir-distance.md`) : implémentée exactement comme spécifié — extension `b6`/`b9` à 3 issues, `R6=105` ajouté.
- **F1 visualisation** : l'Architecture recommandait explicitement de NE PAS livrer un algorithme de polygones figé sans vérification visuelle incrémentale ("construire d'abord l'arc R6 seul en overlay de debug... puis seulement construire les polygones"). C'est exactement la méthode suivie : premier jet avec les polygones `6MG`/`6MD` fermés sur la ligne de but, **erreur trouvée par vérification visuelle** (le polygone débordait sur le territoire `AILG`/`AILD`), corrigée avec une recherche par bissection du point de croisement réel entre l'arc R6 et la diagonale du triangle d'aile, revérifiée visuellement (capture avant/après). Exactement la méthode prescrite, avec un vrai résultat trouvé et corrigé — pas une case cochée sans y regarder.
- Technique de superposition peinte (`6MG`/`6MD` dessinés après `69MG`/`69MD`, cf. `COURT_ZONE_ORDER`) au lieu d'une soustraction de polygones exacte : décision d'ingénierie raisonnable, documentée en commentaire, vérifiée visuellement sans résidu de l'ancienne couleur "en dessous".

## Conventions de nommage et de style
Conforme au style existant (`arcPoints`/`angleAtX` réutilisés tels quels, pas redéfinis). La nouvelle fonction `wingArcCrossAngle()` (bissection) introduit une technique numérique absente ailleurs dans le fichier (le reste est en solutions fermées trigonométriques) — **c'est un point notable, pas un défaut** : aucune solution fermée simple n'existe pour ce croisement (transcendantal), et la bissection est bornée à 40 itérations, déterministe, sans risque de non-convergence. Commentée avec la raison (pas de solution fermée) et référence au risque concerné.

## Réutilisation vs duplication
`69MG`/`69MD` réutilisent l'exacte même géométrie que l'ancien `6MG`/`6MD` (juste réétiquetés) — pas de nouvelle géométrie inventée là où l'existante convient déjà. `6MC`/`69MC`/`9MC` réutilisent le même schéma de construction (`arcPoints`/`toPct`) déjà en place pour le reste du fichier.

## Scope
Uniquement les 4 symboles concernés par F1 (`shotZoneCourt`, `COURT_ZONE_ORDER`, `COURT_ZONE_LABEL_POS`, `buildCourtZones`). Aucun débordement vers `renderCourtZones()`/`aggregateCourtZones()` (non nécessaire, déjà génériques) ni vers le PDF (F3/F4, hors scope de cette story — traité par STORY-73).

## Point notable — positions de label `6MG`/`6MC`/`6MD` (nouvelles)
`[24,16]`/`[50,19]`/`[76,16]` sont une estimation raisonnable (vérifiée non-chevauchante avec le marqueur 7m et les autres labels lors du rendu de test), mais **pas issues d'un cycle d'itération avec Romain** comme l'ont été les positions historiques (`6mG`/`6mD` "déplacés entre les lignes 6m et 9m, retour Romain, usage réel" — cf. commentaire préexistant). Le commentaire du code le signale explicitement ("à ajuster visuellement si un premier rendu réel montre un chevauchement"). Pas bloquant — cohérent avec le PRD (F5 : revalidation visuelle explicite par Romain avant de considérer la story terminée).

## Gestion d'erreurs
N/A — fonction pure, aucun appel externe, aucune entrée utilisateur directe (les x/y proviennent déjà d'événements validés à la saisie).

## Sécurité basique
N/A.

## Vérification indépendante du Code Reviewer
Au-delà de la lecture du diff : j'ai rejoué la vérification par bissection sur quelques valeurs de rayon pour confirmer la convergence (40 itérations sur un intervalle initial de 56 unités converge à une précision largement sous 10⁻¹⁰ unité — trivialement suffisant pour un rendu à l'écran). Pas de contre-vérification indépendante de la géométrie des polygones au-delà des captures déjà produites par le Developer — je m'appuie sur elles plutôt que de tout rejouer, cohérent avec mon mandat (je ne teste pas le comportement fonctionnel, ça c'est le rôle du QA).

## Verdict
**APPROUVÉ**

Aucun point bloquant. La méthode de développement prescrite par l'Architecture (vérification visuelle incrémentale) a été suivie et a effectivement intercepté un bug réel avant qu'il n'atteigne le QA — exactement le résultat recherché.
