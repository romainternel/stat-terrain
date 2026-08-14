# Visual Crafter — Deux équipes distinctes

## Écran de choix — piste d'animation provisoire
Romain décrit quelque chose qui "apparaît d'un coin à un autre... et disparaît" — sans sa référence, je propose une piste simple et réversible plutôt que d'inventer une chorégraphie complexe qui serait probablement à refaire :
```css
.team-picker-card{ animation: team-card-in .4s ease-out backwards; }
.team-picker-card:nth-child(1){ animation-delay:.05s; }
.team-picker-card:nth-child(2){ animation-delay:.15s; }
@keyframes team-card-in{ from{ opacity:0; transform:translateY(16px) scale(.97); } to{ opacity:1; transform:none; } }
```
Une légère entrée décalée entre les deux cartes (pas une diagonale "d'un coin à l'autre" — trop spécifique pour deviner sans l'image) — **à remplacer entièrement** dès réception de la référence de Romain, ce code n'est qu'un point de départ pour ne pas livrer un écran statique en attendant.

## Sortie de l'écran au choix
```css
.team-picker{ transition: opacity .25s ease, transform .25s ease; }
.team-picker.leaving{ opacity:0; transform:scale(.98); }
```
Fondu court à la sélection, avant de basculer sur l'écran Équipes normal — évite un changement d'écran instantané et brutal pour ce qui est un moment "structurant" (premier choix d'identité de l'appareil).

## Couleurs des deux cartes
Ne pas présumer une association de couleur "âge" (ex: bleu clair pour les jeunes) sans validation de Romain — proposition neutre : CF reprend `--fenix-sky` (couleur déjà associée à l'équipe principale dans toute l'app), -18 une teinte secondaire déjà présente dans la palette (`--purple`, actuellement seulement utilisée pour Jet Franc, sous-exploitée ailleurs) plutôt qu'une nouvelle couleur inventée pour l'occasion.

## Typographie "en gros"
Les libellés "-18"/"CF" en `font-size` très large (`clamp(48px, 12vw, 96px)`) et poids maximal (`font-weight:800`) — Romain insiste sur "en gros", donc pas un simple `.card-t` standard (13px) mais un traitement typographique dédié à cet écran, cohérent avec le fait que c'est un moment ponctuel et rare (une fois par appareil), pas un écran consulté en continu où la densité d'info prime.

## Cohérence avec le reste de l'app
Pas de nouveau système de composant "carte cliquable pleine largeur" — réutilise `.card` comme base (bordure, ombre déjà cohérentes) avec juste la typo/taille étendues pour cet usage ponctuel.
