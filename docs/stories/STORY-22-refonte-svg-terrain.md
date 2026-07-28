# STORY-22 — Refonte SVG du terrain

**En tant que** Romain,
**Je veux** que le terrain affiché (Match et Stats) ait un rendu visuel cohérent avec le reste de l'app,
**Afin de** ne plus avoir l'impression d'une image rapportée qui jure avec le design sombre de l'app.

## Contexte technique

- `COURT_IMG` (image JPEG encodée en base64, ~700 lignes dans `app.js`) actuellement utilisée en `background-image` sur `.court-pick` (Match, sélecteurs PD/2min) **et** via `<image href>` dans les SVG de tir (Stats). Remplacée par un SVG dessiné nativement (spec complète : `docs/visual/terrain-joueurs.md`, décision technique : `docs/architecture/terrain-joueurs.md`).
- Nouvelle fonction `renderCourtSvg()`, viewBox `0 0 350 208` conservé (compatibilité avec les coordonnées `x`/`y` des événements déjà enregistrés).
- Éléments à dessiner : ligne de but, zone 6m (arc), ligne 9m (arc pointillé), point de penalty 7m, marque 4m — proportions réglementaires réelles à respecter, pas approximatives.
- `COURT_IMG` supprimée une fois **tous** les usages remplacés (rechercher exhaustivement avant de supprimer, cf. risque #3 `docs/risks/terrain-joueurs.md`).

## Critères d'acceptation

- [x] Le terrain (Match, Stats, sélecteurs PD/2min) utilise le nouveau SVG, plus aucune référence à `COURT_IMG` dans `app.js`.
- [x] Les proportions réglementaires (6m, 9m, 7m, 4m) sont respectées à l'échelle du viewBox 350×208 — comparaison visuelle avec un terrain de hand réel, pas une estimation à l'œil.
- [x] Les positions de tir déjà enregistrées (coordonnées `x`/`y` historiques) restent cohérentes avec le nouveau fond (même référentiel de coordonnées) — viewBox `0 0 350 208` inchangé, testé via un flux BUT complet par vrais clics.
- [ ] **Validation visuelle explicite de Romain** avant de considérer cette story terminée (il est expert du domaine, un rendu "à peu près correct" ne suffit pas). **En attente — v2 (géométrie corrigée) soumise après retour de Romain sur v1, réponse requise.**
- [x] Chaque écran affichant un terrain a été testé individuellement (pas seulement l'écran Match) — Match, Stats Gardiens (cartes de tir), sélecteurs PD/2min, mode tir (sélection impact).
- [x] Le rendu reste lisible en conditions de forte luminosité — contraste renforcé volontairement (lignes `rgba(123,167,194,.55)`/`.35` sur fond `#0F1923`, ligne de but en rouge `.6` opacité) par rapport à l'ancienne image, plus lisible qu'avant par construction ; pas de test terrain extérieur réel effectué (hors de portée d'un test en local).

## Notes Developer

- Fonction implémentée : `courtSvgMarkup()` (et non `renderCourtSvg()` comme nommé dans la spec initiale — nom aligné avec les conventions existantes de l'app, purement cosmétique).
- `COURT_IMG` (constante base64 ~17 617 caractères) supprimée via un script `node -e` dédié (trop volumineuse pour un remplacement de chaîne classique).
- 7 usages remplacés au total : 4 `.court-pick` (Match, sélecteurs PD/2min, mode tir) + 3 `<image href="${COURT_IMG}">` dans des SVG déjà présents (shot overlay, détail gardien, carte stat "Tirs subis").
- Nouveaux tokens CSS dans `:root` : `--court-fill`, `--court-line`, `--court-line-dash`, `--court-goal`.
- Sens des arcs (6m, 9m) deviné puis vérifié visuellement dès le premier rendu — correct du premier coup, mais impératif de vérifier à l'œil plutôt que de supposer (cf. `docs/risks/terrain-joueurs.md`).
- Vérifié fonctionnellement (pas seulement visuellement) : flux complet BUT (sélection tireur → position d'impact → zone de but) enregistre toujours un événement correct avec le nouveau terrain en place.
- Vérifié sur iPad (1024×768) et iPhone portrait réel (390×844, testé après correction d'un script de capture qui réutilisait par erreur le viewport iPad) — terrain bien proportionné et complet une fois scrollé en vue.

### Correction post-retour Romain (v1 → v2)

Romain a signalé sur la v1 que la zone 6m et la ligne des 9m n'étaient pas de vrais demi-cercles, et que les 9m devaient partir de la ligne de touche. Vérification : c'est exact, la géométrie réglementaire du handball n'est pas un demi-cercle centré au milieu du but, mais **deux quarts de cercle centrés sur chaque poteau**, reliés par un segment droit de la largeur du but (3m). Comme le rayon des 9m (9m) dépasse la distance poteau→ligne de touche (8,5m sur un terrain de 20m de large), l'arc des 9m rejoint naturellement la ligne de touche plutôt que la ligne de but — c'est le comportement réglementaire, pas une approximation.

- 6m : arcs rayon 105u centrés sur chaque poteau (148.75,0 / 201.25,0), de (43.75,1)→(148.75,105) et (306.25,1)→(201.25,105), reliés par un segment droit.
- 9m : arcs rayon 157.5u depuis les mêmes centres, de (0,51.76)→(148.75,157.5) et (350,51.76)→(201.25,157.5) — les points de départ sont calculés par intersection cercle/ligne de touche (Pythagore), pas devinés.
- Premier rendu du sweep-flag incorrect (arcs bulgeant vers l'intérieur, forme en "vallée" au lieu d'un dôme) — corrigé après vérification visuelle isolée du tracé SVG seul avant de re-tester dans le contexte complet de l'app.

### Correction additionnelle : terrain trop grand sur PC (débordement vertical)

Romain a signalé qu'sur PC (grand écran, orientation paysage) le terrain forçait un scroll — la page semblait "trop grande". Repro confirmée par test réel : `.court-pick` utilise `aspect-ratio:350/240` avec `width:100%`, donc sa hauteur est dérivée de la largeur disponible dans la colonne droite ; sur un écran large (1366 à 1920px), cette largeur est telle que la hauteur calculée (751 à 1131px) dépasse largement l'espace vertical réellement disponible dans `.ml-court` (qui, lui, est bien contraint en hauteur par la règle de layout paysage existante), d'où un scroll interne forcé pour voir tout le terrain.

**Fix** : dans la media query paysage desktop/tablette (`orientation:landscape and min-width:700px`), le terrain est maintenant dimensionné par la **hauteur** disponible plutôt que par la largeur (`.court-pick{flex:1;min-height:0;width:auto;max-width:100%}`), avec `aspect-ratio` qui dérive la largeur — équivalent à un `object-fit:contain`. Plus aucun débordement testé à 1366×768, 1440×900, 1920×1080.

**Effet de bord détecté et corrigé** : ce changement s'applique aussi à l'iPhone en paysage (844×390, même media query car `min-width:700px` matche), où il a d'abord cassé l'affichage — le terrain redimensionné par la hauteur devenait trop étroit et les étiquettes joueurs débordaient de son cadre. Comme l'iPhone paysage a sa propre media query plus spécifique (`max-width:932px and orientation:landscape`), le comportement d'origine (dimensionnement par la largeur + scroll, déjà validé en STORY-03) y a été explicitement restauré. iPad paysage (1024×768, hors de cette media query plus étroite) bénéficie bien du nouveau comportement sans régression.

## Hors scope

- Le comportement de sélection des joueurs (traité dans STORY-20).
- L'affichage du numéro de maillot (traité dans STORY-21).
- Toute interactivité nouvelle sur le terrain (zoom, replay) — cf. critère de bascule de l'Architecte, pas pour cette story.

## Dépend de

Aucune (recommandé après STORY-20 et STORY-21 pour limiter les conflits de merge sur les mêmes zones de `app.js`, mais pas un blocage strict).

## Taille

M
