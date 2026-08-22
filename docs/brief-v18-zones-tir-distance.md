# Brief — Zones de tir : vraie distinction 6m / 6-9m / 9m

## Origine
Remarque de Romain en passant, pendant le cadrage de STORY-70/71 : "un tir à 8m est comptabilisé comme un tir à 6m sans personne. [...] garder les secteurs de gauche à droite mais ajouter la limite de la zone en plus de ces secteurs gauche/centre/droit avec donc 6m, 6m-9m et 9m."

## Ce que le code révèle — DEUX systèmes de zones existent, et TOUS LES DEUX ont le défaut décrit
Vérifié en lisant `app.js` en détail, pas supposé :

### 1. Le système "live" (`shotZoneCourt()`, `app.js:2670`) — utilisé sur Stats Comparaison/Gardiens/Joueurs
Déjà un système de zones **validé par Romain via un prototype visuel réel (8 itérations)**, cf. commentaire dans le code (`docs/arch/zones-terrain-et-tableau-joueurs.md`). 8 zones : `AILG, 6MG, 6MC, 6MD, AILD, 9MG, 9MC, 9MD`.

**Le défaut exact que Romain décrit y est bien présent** : la fonction n'utilise qu'**un seul rayon de coupure, R9 (9m = 157.5 unités)**, jamais R6 (6m). Le commentaire du code l'assume explicitement : *"N'utilise le rayon 6m (R6) nulle part [...] la vraie frontière de zone est R9 partout ; la ligne des 6m [...] reste un pur repère visuel, pas une frontière."* Concrètement : un tir à 6m et un tir à 8m dans l'axe tombent **tous les deux dans "6MC"** — seule la frontière à 9m distingue "proche" (étiqueté "6M...") de "loin" (étiqueté "9M..."). Le nom "6M" est donc trompeur : il désigne en réalité "tout ce qui est à moins de 9m", pas "à moins de 6m". C'est très probablement le système que Romain regarde en match (Stats en direct) et qui déclenche sa remarque.

### 2. Le système "PDF" (`shotOriginZone()`, `app.js:5358`) — utilisé uniquement dans le rapport PDF exporté
Un système **séparé et plus grossier**, jamais synchronisé avec le premier : classification par bandes Y fixes (proche/loin) + détection de côté (aile si X<20 ou X>80), zones nommées d'après des postes (`ALG/PVT/ALD/ARG/DC/ARD` + `AUTRE`). Ne calcule **aucune vraie distance géométrique** (pas de rayon depuis les poteaux) — un tir à 8m dans l'axe (`y<55`, pas aile) tombe dans "PVT", la zone censée représenter le poste de pivot au ras du but. C'est très probablement lui qui produit le "6m sans personne" dans le vocabulaire de Romain (un tir de mi-distance comptabilisé dans la case pivot/6m, sans qu'aucun joueur à ce poste ne l'ait tiré).

## Pourquoi c'est plus gros qu'un simple correctif de rapport
Le premier réflexe ("le PDF utilise une classification différente et moins précise que le live, il suffit de le faire pointer vers le système live déjà validé") **ne résout qu'à moitié le problème** : le système live lui-même n'a que 2 bandes de profondeur (moins de 9m / plus de 9m), pas 3. Faire pointer le PDF vers `shotZoneCourt()` tel quel corrigerait l'incohérence PDF/live, mais ne donnerait toujours pas la vraie distinction 6m/6-9m/9m demandée — juste une distinction "6-9m" vs "9m+" avec l'étiquette "6m" mal nommée.

Pour obtenir réellement ce que Romain demande, il faut ajouter une vraie 3e bande de profondeur (rayon R6=105 déjà utilisé ailleurs pour tracer la ligne des 6m, jamais pour classifier) — et la question de fond est **où** : uniquement dans le système partagé live (`shotZoneCourt`, qui alimente déjà 3 écrans + potentiellement le PDF si on les unifie), ou seulement dans un nouveau calcul isolé au PDF.

## Ce qui ne change pas dans tous les cas
- Les secteurs gauche/centre/droit (et les ailes) restent une distinction pertinente et déjà correcte selon Romain — rien à changer sur cet axe.
- Aucune des deux fonctions de classification ne modifie la structure d'un événement (`x`/`y` restent la seule donnée source, déjà présente).

## Questions en suspens — scope à trancher avant d'aller plus loin
1. **La vraie distinction 6m/6-9m/9m doit-elle apparaître sur l'écran de zones en direct (Stats Gardiens/Joueurs/Comparaison), ou seulement dans le PDF exporté après le match ?** Ce n'est pas neutre : le système live est celui que Romain a déjà validé visuellement pendant un cycle dédié (8 itérations de prototype) — y ajouter une 3e bande change la forme des zones affichées à l'écran (zones plus fines, potentiellement plus dures à lire/taper d'un coup d'œil sur iPad en plein match) et touche 3 écrans en production. Le PDF, lui, n'est regardé qu'après coup, hors contrainte de rapidité tactile — un changement y est strictement plus sûr.
2. Si le live est concerné : faut-il garder la même *forme* de zones (polygones actuels) avec juste une bande supplémentaire, ou Romain a-t-il une préférence de disposition pour la nouvelle grille 3 profondeurs × 3 secteurs ?

## Recommandation de l'Analyst (à valider par Romain)
Ne pas trancher unilatéralement ce fork avant d'avoir la préférence de Romain — c'est exactly le type de décision "risque produit/UX sur un écran déjà validé" qui doit remonter avant Design/Architecture, pas après.
