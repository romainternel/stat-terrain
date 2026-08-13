# Visual — Zones sur le terrain + tableau Joueurs PDF

## Couleurs — strictement les valeurs déjà en usage
- Vert (but majoritaire) : SVG `#50C878` (déjà utilisé pour les points "but" existants) / jsPDF `[80,200,120]`
- Cyan (sinon) : SVG `#4ECDE8` / jsPDF `[78,205,232]`
- Neutre (zone sans tir) : contour du terrain visible (`var(--court-line)`/`[123,167,194]`), remplissage transparent ou très légèrement teinté (`var(--bg3)` côté SVG, `[28,43,64]` côté PDF) — la zone doit rester lisible comme partie du terrain, pas disparaître
- Texte du ratio : blanc `#fff`/`[232,232,232]`, bold, taille proportionnelle à la zone (les zones larges comme 9mC peuvent se permettre un texte plus grand que AilG/AilD, plus étroites) — **c'est le seul texte affiché dans les zones**, aucun code de zone (pas de "6mG"/"AilG" écrit sur le terrain, validé sur le prototype)

## Tracé des zones — s'appuie sur la géométrie déjà écrite, ne la redessine pas
Côté SVG (`courtSvgMarkup()`, viewBox 350×208) : les zones sont des `<path>` construits à partir des mêmes points d'arc que les lignes 6m/9m déjà dessinées (poteaux à X=148.75/201.25, rayons 105/157.5) — un contour de zone = un ou deux arcs + segments droits reliant les bornes d'angle de la zone, avec `fill` conditionnel (vert/cyan/neutre) et un `<text>` centré sur le centroïde approximatif de la zone.
Côté PDF (`drawHandballZone()`, coordonnées mm), même logique transposée : `doc.path()`/succession de `lineTo`/arcs via le même échantillonnage par petits segments déjà utilisé dans `drawHandballZone()` (steps=36 quarts de cercle), fill conditionnel, `doc.text()` centré.

Bordures de zone : trait fin `1px`/`0.3mm`, couleur `var(--court-line)`/`[123,167,194]` (même teinte que les lignes 6m/9m déjà tracées) — les zones doivent se lire comme un tracé tactique du terrain, pas comme un calque de cases par-dessus.

## Marqueurs 7m et Sans GB
**7m** : pastille distincte (cercle, couleur or `--z-7m`) positionnée exactement au point de penalty déjà marqué sur `courtSvgMarkup()` (ligne 168–182 à Y=122.5 en SVG / équivalent PDF) — libellé "7m" (minuscule) au-dessus du ratio. Ne fait pas partie du dégradé de zones de terrain — reste visuellement "posé dessus".
**Sans GB** : badge distinct (pilule arrondie, couleur neutre `--z-sansgb`), position fixe en bas du terrain, sous les zones 9m — libellé "SANS GB". Reste vide/neutre tant qu'aucune capture n'alimente cette donnée (cf. `docs/arch/`, hors scope de ce lot) — ne doit jamais bloquer le rendu si `t===0`.

## Repères du vrai terrain (nouveaux, obligatoires)
En plus des zones et marqueurs, tracer par-dessus (même couleur `var(--line)`/`[123,167,194]` que les lignes déjà existantes) : la **ligne des 6m** en trait plein (repère seulement, ne borne aucune zone), la **ligne des 9m** en pointillé (frontière réelle 6m*/9m*), la **marque des 4m** et la **marque des 7m** (petits traits courts sur l'axe du but, mêmes coordonnées que `courtSvgMarkup()`). Sans ces repères, le terrain ne se lit plus comme un vrai terrain de hand — retour explicite de Romain sur le prototype.

## Bouton de bascule
Deux segments accolés (type segmented control), largeur totale ~140px, hauteur alignée sur les boutons `.st-tab` existants (32-36px), coins arrondis 6-8px, état actif en fond `var(--fenix-sky)`/texte foncé, état inactif fond transparent/bordure `var(--border)`. Icônes : 📍 pour Points, 🔲 (ou 🗺️) pour Zones — cohérent avec le reste de l'usage d'emojis fonctionnels déjà présent dans l'app (🧤, 👤, 📊...).

## Tableau Joueurs PDF
Colonne `BUT/TIR` : texte combiné centré (ex "6/8"), couleur verte bold comme l'ancienne colonne BUTS. Colonne `PO` : couleur jaune (`var(--yellow)`/`[240,199,94]`, cohérent avec la couleur déjà utilisée pour PD). `MT1`/`MT2` : même style que BUT/TIR mais taille de police légèrement réduite si besoin pour tenir dans la largeur de colonne (à ajuster par l'Architect selon la largeur réelle disponible).

## Règle absolue reconduite
Aucun caractère non-ASCII dans un appel `doc.text()` côté PDF (bug STORY-39). Les seuls textes affichés dans les zones sont des ratios chiffrés (`"5/9"`) ; les badges 7m/Sans GB utilisent "7m" et "SANS GB" en ASCII pur, "m" toujours en minuscule (retour explicite de Romain — ne pas repasser en "7M"/majuscule).
