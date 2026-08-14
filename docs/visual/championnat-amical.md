# Visual Crafter — Champ Championnat / Amical

Surface visuelle réduite (un `<select>` compact + un badge de liste) — attention portée à ce que ça ne complique pas le badge Saison/Journée déjà très condensé, plutôt qu'à créer un nouvel effet.

## Le `<select>` ne doit pas casser l'alignement du badge existant
`[2025-2026 · J5 · N1 ▾]` : le style natif d'un `<select>` (bordure, padding, flèche du navigateur) contraste facilement avec du texte simple environnant. Neutraliser l'apparence native pour qu'il se fonde dans la ligne :
```css
#edit-championnat{ appearance:none; -webkit-appearance:none; background:transparent; border:none;
  color:inherit; font:inherit; cursor:pointer; padding:0 12px 0 0;
  background-image:url("data:image/svg+xml,..."); background-repeat:no-repeat; background-position:right center; background-size:8px; }
```
(flèche en `background-image` SVG minuscule plutôt que la flèche native du navigateur, qui a un style très inconsistant entre iOS Safari/Chrome/desktop — micro-détail mais visible sur un élément aussi compact).

## Badge Amical dans la liste : ne pas utiliser une couleur d'alerte
`var(--t3)` (déjà le gris le plus neutre de la palette) plutôt que orange/rouge — un match amical n'est pas une anomalie ou un problème, juste une catégorie différente. Réserver les couleurs d'alerte de l'app (orange/rouge) à ce qu'elles signifient déjà ailleurs (hors cadre, encaissé) évite de leur faire perdre leur sens.

## Cohérence des tailles
Badge Championnat dans `renderHistory()` à la même taille que le badge Journée existant (`font-size:11px`, même `border-radius`/padding que les badges déjà utilisés ailleurs dans les listes de l'app — pas une nouvelle échelle de badge).
