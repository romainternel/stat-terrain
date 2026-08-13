# Design — Visualisation "zones sur le terrain" + tableau Joueurs PDF

## F2 — Zonage : 8 zones + 2 marqueurs, validé par prototype visuel réel avant tout code
**Ce zonage a été itéré 8 fois avec Romain sur un prototype SVG interactif** (pas sur ce document seul) avant d'être figé — le détail exact (tailles, positions de texte) est dans `docs/arch/zones-terrain-et-tableau-joueurs.md`, ce document décrit l'intention validée :

```
   AilG                                    AilD
     \                                      /
      \_____________ 9mG | 9mC | 9mD ______/     ← au-dela de la ligne des 9m
       \                                  /
        \_____ 6mG | 6mC (large,centre) | 6mD ___/   ← de la ligne de but a la ligne des 9m
                        (7m)                      ← marqueur, pas une zone
                      [Sans GB]                   ← marqueur, capture a construire separement
```

- **AilG / AilD** : coin près de la ligne de but, côté touche (angle fermé, ailiers) — plus petites que les autres zones
- **6mG / 6mC / 6mD** : tout ce qui reste entre la ligne de but et la ligne des 9m une fois les ailes retirées — c'est la zone "tir de 6m" au sens coach, même si géométriquement ça va jusqu'au 9m (convention explicitement validée par Romain). **6mC est deux fois plus large que la largeur du but et centrée sur l'axe** — pas la largeur du but elle-même, décision itérée avec Romain.
- **9mG / 9mC / 9mD** : tout ce qui est au-delà de la ligne des 9m
- **7m** : **pas une zone de terrain** — un marqueur fixe au point de penalty, alimenté par les événements `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` (déjà comptés séparément dans `gkStats()`/`playerStats`, jamais par x/y puisque l'origine d'un 7m est toujours le même point).
- **Sans GB** : **pas une zone de terrain**, marqueur pour cage vide/contre-attaque — Romain a confirmé que ça nécessite une nouvelle capture en direct (pas déductible des données actuelles). Le marqueur existe dans le modèle visuel (même famille que 7m) mais reste vide tant que cette capture n'est pas construite — hors scope de ce lot.

Chaque zone affiche uniquement son ratio `buts/tirs` en texte (ex "5/9"), centré à une position pré-calculée par zone (pas le centroïde géométrique brut) — **aucun code de zone (6mG/AilG/etc.) n'est affiché sur le terrain**, ni de légende : la forme suffit à un coach qui regarde un terrain de hand. C'est un changement par rapport à l'intention initiale (revue explicitement par Romain sur le prototype).

Les vrais repères du terrain sont tracés par-dessus les zones : **ligne des 6m** (trait plein), **ligne des 9m** (pointillé), **marque des 4m** (retrait gardien), **marque des 7m** — mêmes coordonnées que `courtSvgMarkup()`/`drawHandballZone()`. Ce sont des repères visuels, aucun ne borne une zone (seule la ligne des 9m sert de vraie frontière).

## Convention couleur — inchangée
Même code que la grille Impact : vert si buts/tirs > 0.5, cyan sinon, zone neutre (gris/bleu foncé, contour du terrain visible mais sans remplissage coloré) si aucun tir enregistré dans cette zone. Jamais de rouge. Le marqueur 7m suit la même règle ; le marqueur Sans GB reste neutre tant qu'il n'y a pas de données.

## Bouton de bascule points ↔ zones
Un seul composant visuel réutilisé aux 4 emplacements (Joueurs, Gardiens, Comparaison, et implicitement le PDF qui n'a pas de bouton puisque statique — il applique simplement le réglage en vigueur au moment de la génération) : une paire de boutons compacte type toggle, libellés "📍 Points" / "🔲 Zones" (ou icônes équivalentes déjà dans la charte), positionné en haut à droite de chaque bloc terrain concerné, dans le même style que les boutons `.st-tab`/filtre déjà utilisés ailleurs dans Stats — pas un nouveau style de composant.

## F4/F5 — Joueurs et Gardiens
Remplacement in-place : même emplacement, même taille de terrain, seul le contenu dessiné par-dessus `courtSvgMarkup()` change selon le réglage. La grille Impact (HG/HC/etc.) reste identique, non affectée par le bouton.

## F6 — Nouveau bloc Comparaison (révisé après retour Romain, usage réel de STORY-43)
Placement revu : **au-dessus de la carte "🎯 Tirs par poste"** (pas au-dessus du tableau comparatif — ce dernier reste la toute première chose visible sous le bandeau score, inchangé). Logique : ce nouveau bloc et "Tirs par poste" sont tous deux des vues de répartition des tirs (par zone terrain vs par poste de jeu), ça les regroupe visuellement.

Deux mini-terrains côte à côte (FENIX à gauche, adversaire à droite, même largeur que les blocs déjà utilisés dans `renderStatGk()`), chacun avec son but et son propre ratio global par zone (tous tireurs confondus côté équipe). Même bouton de bascule, partagé avec les 2 autres écrans (un seul réglage global, donc l'état affiché ici reflète le même choix que Joueurs/Gardiens).

**Nouveau — stats d'en-tête par carte** : chaque mini-terrain affiche en en-tête `Buts/Tirs` (agrégat équipe, même calcul que la ligne "Buts/Tirs" du tableau comparatif juste en dessous — pas une nouvelle source de vérité) et `PB` (pertes de balle, agrégat équipe, `teamStat(side,"TURNOVER")`, déjà calculé ailleurs sur cet écran).

**Nouveau — PB sur le terrain, mode "points" uniquement** : `TURNOVER` capture déjà `x`/`y` (`needsMap:true`) mais n'était affiché sur aucun terrain jusqu'ici. Romain veut les pertes de balle visibles comme marqueurs sur le mini-terrain **seulement en mode "points"** (marqueur distinct des points but/arrêt/hors-cadre — icône `↩` déjà utilisée pour PB ailleurs dans l'app, couleur `var(--red)` déjà celle de PB dans `ACTIONS`). **En mode "zones", les PB ne sont pas affichées** : chaque zone n'écrit que le ratio buts/tirs (comme sur Joueurs/Gardiens) — ajouter un 3e nombre par zone surchargerait un texte déjà dense ; le total PB reste visible via la stat d'en-tête, quel que soit le mode.

## F1 — Tableau Joueurs PDF
Colonnes `#, NOM, POSTE, BUT/TIR, EFF%, PO, PD, PB, 2M, MT1, MT2` — même style de cellule que l'existant (couleurs conditionnelles déjà en place : vert si but, jaune si PD/PO, rouge si PB/2M non nul), simplement une colonne de plus (PO) et deux colonnes fusionnées en une (BUT/TIR).
