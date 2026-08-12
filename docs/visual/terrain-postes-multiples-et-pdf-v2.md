# Visual — Terrain à effectif variable par poste + PDF v2 (itération 3)

Cycle correctif, pas une nouvelle direction visuelle : la charte du terrain (dark theme, `--fenix-sky`/`--red`) et celle du PDF (fond blanc, encarts bleus `rgb(26,40,64)`, `pageHeader()`) sont déjà actées et validées par Romain — rien n'est remis en cause ici. Mon rôle se limite aux éléments réellement nouveaux ou corrigés dans ce cycle.

## 1. Terrain — pivots 3/4 joueurs
Aucun nouveau token : mêmes `.cp-player` (fond `rgba(26,40,64,.9)`, bordure `2px solid rgba(255,255,255,.3)`, `border-radius:7px`) qu'aujourd'hui. Seule la géométrie de placement change (Designer). Un point d'attention cependant : à 4 encarts PVT au lieu de 1-2, la densité locale augmente — vérifier au Developer/QA que l'écart entre les deux profondeurs (devant/derrière) reste au moins égal à la hauteur d'un encart (~30-35px selon viewport) pour ne pas recréer le chevauchement vertical déjà corrigé une fois cette session (cf. `docs/risks/`).

## 2. PDF — glyphe Top 3 (F3)
"★" → texte ASCII uniforme. Recommandation : `"1."`, `"2."`, `"3."` pour toutes les positions (pas de traitement spécial du rang 1) — plus sobre que chercher un symbole de substitution, et élimine tout risque de reproduire le bug avec un autre glyphe non testé. Style inchangé : `wh()` (232,232,232), `fontSize(8)`, `"helvetica","bold"`.

**Règle de prudence pour tout le PDF** : jsPDF (police Helvetica standard, encodage WinAnsi) ne supporte que le charset Latin de base. Aucun caractère hors ASCII imprimable (pas d'emoji, pas de symboles Unicode type ★ ▼ 🧤 🥇) ne doit être utilisé dans `doc.text()`. Les flèches/symboles déjà présents dans l'app (icônes `ACTIONS[type].icon`) ne doivent jamais être copiés tels quels dans le PDF sans vérification — c'est déjà la règle suivie pour le Top 3/Carte tir joueur existants, à auditer une fois sur l'ensemble de `generatePDF()` dans ce cycle (cf. PRD F3).

## 3. PDF — encart Zones d'impact (F4)
Alignement strict sur les tokens déjà utilisés par `goalZoneHeatmap()` côté app, transposés en RGB pour jsPDF (pas de `rgba()`/CSS variables en PDF) :

| Élément | App (CSS) | PDF (RGB jsPDF) |
|---|---|---|
| Zone majoritairement but (gPct > 0.5) | `rgba(80,200,120,opacity)` | `[80,200,120]` |
| Zone majoritairement arrêt/hors-cadre (gPct ≤ 0.5) | `rgba(78,205,232,opacity)` | `[78,205,232]` — **cyan, jamais rouge** (correction : l'implémentation PDF actuelle utilise `[232,70,90]` rouge pour ce cas, à corriger) |
| Cellule vide (aucun tir) | `var(--bg3)` (`#1C2B40`) | `[28,43,64]` |
| Texte du ratio | `#fff` si total>0, sinon `var(--t3)` | `wh()` si total>0, sinon `t3()` — déjà correct côté PDF |
| Légende | italique, `10px`, `var(--t3)` (`rgba(255,255,255,.28)` sur fond sombre app ≈ gris moyen) | `t3()`, `doc.setFontSize(6)` (échelle PDF), texte identique : `"Stat des tireurs (ex : 1/1 = 1 but et non arrêt)"` |

Opacité par volume relatif (`.2+.8*(total/maxLocal)`) : optionnel pour le PDF — la donnée y est déjà segmentée par match unique (volumes plus faibles qu'un agrégat), une opacité fixe autour de 70-80% est suffisante pour rester lisible à l'impression sans complexifier `drawGoalZone()`. Ne pas reproduire la formule si elle n'apporte pas de lisibilité supplémentaire à ce volume de données — cf. Architect pour la décision finale.

Lettres de zone (HG/HC...) : simplement retirées, aucun remplacement visuel nécessaire.

## 4. PDF — page Carte tir joueur, ligne à carte unique centrée (F6)
Quand la dernière ligne d'une grille à 2 colonnes ne contient qu'une carte, elle doit être centrée horizontalement dans la largeur de contenu de la page (pas ancrée à la marge gauche). Calcul : `x_carte_seule = margeGauche + (largeurDisponible - largeurCarte) / 2`. Aucun autre changement visuel sur la carte elle-même (déjà validée).

## 5. PDF — page Évolution du score isolée (F2)
Aucun changement visuel du graphique lui-même (déjà repris cette session : grille éclaircie `[70,85,105]`, lignes `1.8mm`, points `1.3mm`). Seul son placement change (page dédiée). Vérifier que le `card()` conserve la même hauteur (55mm) — la page dédiée lui donne largement la place, pas besoin de l'agrandir.

## Checklist contraste
- Texte blanc (`wh()`, 232,232,232) sur cellule verte (80,200,120) ou cyan (78,205,232) pleine opacité : contraste suffisant dans les deux cas (fonds suffisamment saturés/foncés), cohérent avec l'existant déjà validé sur `drawGoalZone()`/`drawPlayerZoneGrid()`
- Légende `t3()` (107,114,128) sur fond blanc de page (hors encart) : à éviter — la légende doit toujours être positionnée à l'intérieur de l'encart bleu (`card()`), jamais directement sur le fond blanc, comme déjà établi pour tout texte du PDF cette session
