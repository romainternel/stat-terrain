# Design — Champ Championnat / Amical

## Widget de sélection : `<select>` compact, pas un nouveau composant custom
Ajouté juste à côté du badge Saison/Journée existant (`app.js` ~ligne 1962-1968, bloc `.ml-extra`) :
```
[2025-2026 · J5 · N1 ▾]
```
`<select id="edit-championnat">` avec options `N1`, `N2`, `-18`, `Amical`, `Autre…` — même taille/police que le texte Saison/Journée environnant (`font-size:10px`, `color:var(--t3)`), pas un `<select>` visuellement lourd. Choisir "Autre…" déclenche immédiatement un `prompt()` (même mécanisme que Saison/Journée déjà en place) pour saisir une valeur libre ; si la valeur libre ne correspond à aucune des 4 options rapides, le `<select>` doit pouvoir l'afficher quand même (cf. Architecture — option dynamique ajoutée si nécessaire, pas une 5e valeur perdue).

**Pourquoi un `<select>` et pas un `prompt()` direct comme Saison/Journée** : contrairement à Saison/Journée qui sont des chaînes vraiment libres à chaque fois, Championnat a 4 valeurs qui reviendront la plupart du temps (surtout N1) — un menu déroulant évite de retaper "N1" à la main à chaque match. Le `prompt()` reste réservé au cas "Autre" (rare), cohérent avec le principe "pas de friction pour le cas courant, la saisie libre reste disponible pour l'exception".

## Couleur
`Amical` distinct visuellement des 3 valeurs de championnat officiel — `color:var(--t3)` (neutre/atténué) pour Amical (signale "hors comptage"), une couleur neutre standard pour N1/N2/-18 (pas besoin de 3 couleurs différentes entre elles, elles ont toutes le même statut "compte dans le bilan").

## Affichage dans la liste "Matchs sauvegardés" (`renderHistory()`)
Un petit badge à côté de Journée sur chaque ligne :
```
J5  [N1]   FENIX Toulouse  28-24  IVRY
```
Pour un match Amical, badge visuellement distinct (fond légèrement grisé, texte `var(--t3)`) — permet à Romain de repérer d'un coup d'œil dans la liste pourquoi un match ne remonte pas dans le bilan de saison, sans avoir à l'ouvrir. Matchs sans championnat renseigné (créés avant cette story) : pas de badge affiché (état vide silencieux, cohérent avec `m.journee||"—"` déjà utilisé pour l'absence de valeur — mais ici on n'affiche rien plutôt qu'un tiret, un badge vide serait plus intrusif qu'utile).

## Valeur par défaut d'un nouveau match
`"N1"` — pas de prompt ni de choix forcé à la création d'un match (`newMatch()`), cohérent avec le fait que la grande majorité des matchs du CF sont en N1 (contexte déjà documenté dans `CLAUDE.md`) ; changer pour un match spécifique (Amical, N2, -18) reste un geste volontaire d'un clic sur le sélecteur.

## Bilan de saison — pas de changement visuel autre que les totaux
`renderBilanSaison()` n'a pas besoin d'un nouvel indicateur "X matchs amicaux exclus" dans cette version (Won't du PRD) — les totaux (victoires/nuls/défaites) reflètent simplement moins de matchs si des amicaux existent dans la saison, sans message explicatif supplémentaire. Simplicité délibérée, à revoir si Romain trouve ça pas assez explicite en usage réel.
