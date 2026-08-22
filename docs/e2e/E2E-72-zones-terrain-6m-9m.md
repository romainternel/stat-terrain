# E2E — STORY-72 : vraie distinction 6m / 6-9m / 9m sur le terrain de zones

*Produit par le E2E Tester — squad de contrôle BMAD*
*S'appuie sur `docs/qa/QA-72-zones-terrain-6m-9m.md` (PASSED AVEC RÉSERVES)*

## Environnement de test
Même dispositif que les stories précédentes (serveur local temporaire, `config.js` factice en mémoire pour le fail-open, `config.js` réel sur disque jamais touché, aucun accès au vrai Supabase). Cette story a demandé un travail de vérification **pendant le développement lui-même** (pas seulement après) — détaillé ci-dessous, avant même d'atteindre cette étape formelle.

## Vérification géométrique menée pendant le développement (rapportée ici pour traçabilité)
L'Architecture imposait une méthode incrémentale (vérifier l'arc R6 visuellement avant tout polygone rempli) plutôt qu'un algorithme figé. Cette méthode a été suivie via ce même serveur Playwright, en 3 passes :
1. Classification pure (`shotZoneCourt()`) testée sur 11 points à distance réelle connue (6 corridors × 3 profondeurs + 2 ailes) — 11/11 corrects.
2. Rendu isolé des polygones (couleurs contrastées, opacité partielle pour révéler tout chevauchement) — **un défaut réel trouvé** : `6MG`/`6MD` débordaient sur le territoire `AILG`/`AILD` (l'arc R6 croise la diagonale du triangle d'aile avant d'atteindre la ligne de but, contrairement à R9).
3. Correctif (recherche du point de croisement exact par bissection) puis **re-vérification visuelle** confirmant des zones propres, sans trou ni chevauchement, dans l'ordre de rendu réel de l'application.

Cette découverte-et-correction a eu lieu **avant** le Code Review formel (déjà documentée dans `docs/code-review/STORY-72.md`) — rapportée ici car c'est la preuve concrète que la méthode prescrite par l'Architecture a fonctionné, pas une simple affirmation.

## Parcours testés (étape E2E formelle)
1. Connexion (fail-open), profil "CF".
2. Injection de 11 événements de tir synthétiques (un par zone, `x`/`y` identiques aux points de test géométriques ci-dessus) directement dans `S.events` — technique déjà utilisée dans les cycles précédents de ce projet pour peupler des données de volume sans passer par 11 tirs cliqués un par un sur le terrain.
3. Navigation réelle (clic) vers l'onglet **Stats → Comparaison**, déjà en mode "zones" (`S.shotViewMode`).
4. Navigation réelle (clic) vers l'onglet **Stats → Gardiens**.
5. Vérification console sur l'ensemble de la session.

## Résultat par parcours
- ✅ **Parcours 3** : le terrain FENIX Toulouse affiche les 11 zones avec leurs comptages exacts (`1/1`, `0/1`, etc. — correspondant précisément aux 11 événements injectés), rendu dans le vrai contexte CSS/DOM de l'application (carte, bordures, palette sombre) — pas seulement dans le harnais de test isolé utilisé pendant le développement. Capture : `e2e-story72-stats-comparaison-zones.png`. Bandes visuellement propres, cohérentes avec la vérification géométrique isolée.
- ✅ **Parcours 4** : navigation sans erreur vers Gardiens (données non peuplées côté GB puisque les événements de test n'ont pas de `gkId` — comportement attendu, "Aucun gardien sélectionné" affiché pour FENIX ; le point vérifié ici est l'absence de crash/erreur au changement d'onglet avec ce jeu de données, pas le contenu du tableau GB lui-même, déjà hors scope de cette story).
- ✅ **Parcours 5** : 0 erreur console sur l'ensemble de la session (injection de données, changement de vue zones, 2 navigations d'onglets).

## Écarts avec le verdict QA
Aucun.

## Point non couvert par cette étape (rappel, déjà signalé par le QA)
La revalidation visuelle par Romain (PRD F5) reste un critère ouvert — hors du périmètre que l'E2E Tester peut satisfaire seul. Les captures produites ici et pendant le développement donnent une base de discussion solide, pas un substitut à sa propre revue.

## Verdict
**CONFIRMÉ**

Le rendu fonctionne correctement dans le vrai contexte applicatif (pas seulement en isolation), sans régression console, avec une méthode de développement qui a effectivement intercepté et corrigé un défaut géométrique réel avant la mise en production.
