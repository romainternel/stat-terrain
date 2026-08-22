# Visual — Zones de tir : vraie distinction 6m / 6-9m / 9m

*Produit par le Visual Crafter — squad build BMAD*
*S'appuie sur `docs/design/zones-tir-distance.md`*

## Cadrage
Aucune nouvelle couleur, aucun nouvel effet — le système de couleur par efficacité (`rgba(80,200,120,.85)` si >50%, `rgba(78,205,232,.85)` sinon, `var(--bg3)` si vide) est déjà défini, déjà validé, et s'applique tel quel aux 3 nouvelles zones `69M*`. Mon rôle ici est uniquement d'ajuster ce qui doit changer d'**échelle** — traits et texte — pour que 11 zones restent aussi lisibles que 8 l'étaient, sur terrain comme en PDF.

## Palette de tokens (réutilisée, aucune nouvelle valeur)
- Fill par zone : inchangé (`d.t===0` → `var(--bg3)` ; sinon vert `rgba(80,200,120,.85)` / bleu `rgba(78,205,232,.85)` selon efficacité).
- Contour de polygone : `stroke="var(--court-line)"` inchangé en couleur — **épaisseur** revue ci-dessous.
- PDF : mêmes triplets RGB déjà utilisés (`[28,43,64]` neutre, `[80,200,120]` vert, `[78,205,232]` bleu) — aucune nouvelle teinte.

## Typographie
- **Terrain live** : le label `but/tir` (`font-size:9px;font-weight:800`, contour `stroke:rgba(0,0,0,.45);stroke-width:1.6px`) reste la référence pour les zones qui gardent une surface comparable (`9M*`, `AILG`/`AILD`). Pour les zones désormais plus étroites (`6M*`, resserrées autour du but ; `69M*`, nouvelle bande intermédiaire), réduire à **7-8px** si un premier rendu réel montre un débordement du texte hors du polygone — ne pas réduire préventivement partout, seulement là où la géométrie l'exige (à vérifier zone par zone sur le premier rendu, cf. Design).
- **PDF** : la grille passe de 6 à 11 cellules dans le même espace (34×14mm) — le texte `${g}/${t}` doit descendre à **4-4.5pt** (contre 5-6pt aujourd'hui) pour les cellules `69M*`/`6M*`/`9M*` de la grille centrale, la police 5pt déjà utilisée par `drawPlayerOriginZone` (variante compacte) restant la limite basse déjà éprouvée dans le projet — ne pas descendre en dessous sans test d'impression réel.

## Ombres & effets
Aucun changement — les polygones de zone n'ont jamais eu d'ombre portée ni d'effet de profondeur (cohérent avec le style plat du reste du terrain SVG), pas de raison d'en introduire ici.

## États interactifs
- Zone tapée pour filtrer (mécanisme déjà existant côté Gardiens/Joueurs) : le highlight au tap reste le même traitement qu'aujourd'hui, appliqué aux 3 nouvelles zones sans changement de logique.

## Micro-animations
Aucune — cohérent avec la note déjà actée dans `docs/visual/mode-simple-expert.md` : cet écran ne justifie pas d'animation dédiée, cette feature ne change pas cette position.

## Checklist contraste WCAG
Aucune nouvelle combinaison couleur/fond introduite (mêmes trois états de fill déjà validés) — le seul point à re-vérifier n'est pas le contraste des couleurs mais la **lisibilité du texte à taille réduite** (7-8px terrain / 4-4.5pt PDF) sur les zones les plus petites, à confirmer visuellement, pas calculable a priori.

## Note du Visual Crafter
Le risque visuel réel ici est la densité, pas la couleur : passer de 8 à 11 zones sur la même surface de terrain réduit mécaniquement la taille moyenne de chaque zone. Je recommande un **contour de polygone légèrement plus fin** (`stroke-width:.4` au lieu de `.6`) uniquement sur les nouvelles zones `69M*` et sur `6M*` une fois resserré — un trait trop épais sur une petite zone mange une part disproportionnée de sa surface utile et dégrade la lecture du fill/texte à l'intérieur. Ce n'est pas une nouvelle esthétique, juste un ajustement d'échelle cohérent avec la réduction de taille des zones.
