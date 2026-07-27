# Code Review — STORY-19 (Chevauchement des étiquettes joueurs sur le terrain)

*Produit par le Code Reviewer — squad de contrôle BMAD*

## Diff revu

`style.css` (+6 lignes, media query `max-width:700px` sur `.cp-player`/`.cp-num`/`.cp-name`) + bump `sw.js` `v51`→`v52`.

## Vérifications

- **Conformité architecture** : respecte le hors-scope de la story — aucun recalcul de coordonnées en JS, `app.js` non touché, uniquement du CSS.
- **Qualité du diagnostic** : le Developer ne s'est pas arrêté au symptôme (effectif complet = cas limite) — il a lu `courtPlayerPositions()` dans `app.js` pour comprendre que le partage de position entre plusieurs joueurs est un usage **normal** (Romain sélectionne l'effectif dispo, pas exactement 7), et l'a vérifié empiriquement (4 chevauchements avec un jeu de données "réaliste" avant fix). C'est le bon niveau de rigueur — le diagnostic initial de la story ("effectif complet sélectionné par erreur") aurait sous-estimé la fréquence réelle du problème.
- **Conventions du projet** : seuil `max-width:700px` cohérent avec le reste du fichier.
- **Scope** : strictement dans la zone déclarée (`.cp-player`/`.cp-num`/`.cp-name`).
- **Honnêteté sur le compromis** : le Developer signale explicitement que le critère "44px minimum" n'est pas pleinement atteint, avec la donnée précise (23px après fix vs 34px sur iPad avant même cette story) et l'explication du pourquoi (tension directe avec la résolution du chevauchement). C'est exactement le niveau de transparence attendu plutôt que de cocher silencieusement un critère non satisfait.
- **Taille/complexité** : +6 lignes CSS pour un gain mesuré et significatif (4→0 chevauchements sur le cas réaliste, 19→9 sur le cas extrême) — très bon rapport effort/valeur.

## Remarques

**Bloquant** : aucun.

**Recommandé** :
- Le compromis largeur tactile (23px de haut) est raisonnable vu la contrainte, mais si Romain remonte une difficulté réelle à taper le bon joueur sur le terrain en conditions de match, il faudra probablement revoir le POSITIONNEMENT (pas juste la taille) — ça sortirait du scope CSS-only de cette story.

**Note** :
- Le plafonnement de `.cp-name` à `15vw` (au lieu d'une valeur fixe en px) s'adapte proportionnellement à la largeur d'écran — bon choix pour rester cohérent entre 390px et 700px de large, plutôt qu'une valeur fixe qui serait trop généreuse ou trop stricte selon la largeur exacte.

## Verdict

**APPROUVÉ**
