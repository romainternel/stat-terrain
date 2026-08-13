# STORY-43 — Zones sur le terrain : fondation + bascule Joueurs/Gardiens (live app)

**En tant que** Romain,
**Je veux** basculer entre points localisés et zones dessinées sur le terrain, sur l'écran détail d'un joueur et sur l'écran Gardiens,
**Afin de** lire la localisation des tirs directement sur la forme réelle du terrain plutôt qu'en points isolés.

Bundle volontaire de la fondation géométrique + ses deux premiers usages (recommandation du Risk Analyst — F2 est un prérequis strict, ne peut être vérifiée qu'à travers un usage réel) — cf. `docs/risks/zones-terrain-et-tableau-joueurs.md`.

## Contexte technique
- Zone concernée : `app.js` — nouvelles fonctions `shotZoneCourt(xPct,yPct)`, `buildCourtZones()`, `aggregateZones(shots)`, `renderCourtZones()` ; nouvel état `S.shotViewMode` + `setShotViewMode()` ; modification de `renderPlayerDetail()` (~ligne 2485) et `renderGkSheet()` (~ligne 3179)
- Référence architecture complète (géométrie exacte, code) : `docs/arch/zones-terrain-et-tableau-joueurs.md`
- Référence design (zonage, rationale) : `docs/design/zones-terrain-et-tableau-joueurs.md`
- Référence visuelle (couleurs, style bouton) : `docs/visual/zones-terrain-et-tableau-joueurs.md`
- **8 zones** (validées via un prototype visuel réel, 8 itérations avec Romain avant tout code) : AilG, 6mG, 6mC, 6mD, AilD, 9mG, 9mC, 9mD + marqueur `7m` distinct (alimenté par `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF`, pas par x/y) + marqueur `Sans GB` (prévu dans le modèle visuel mais **toujours vide** — capture live hors scope de cette story, cf. `docs/arch/`)
- Aucun code de zone ("6mG"/"AilG"/etc.) affiché sur le terrain — seul le ratio `buts/tirs` dans chaque zone, "m" toujours en minuscule dans les libellés ("7m", pas "7M")
- Repères visuels du vrai terrain à tracer en plus des zones : ligne des 6m (trait plein), ligne des 9m (pointillé, déjà frontière de zone), marque des 4m, marque des 7m

## Critères d'acceptation

**Fondation (F2/F3)**
- [ ] `buildCourtZones()` produit 8 polygones qui tuilent le terrain sans trou ni chevauchement visible, à au moins 3 largeurs de conteneur différentes (mobile portrait, mobile paysage, iPad/desktop large) — cf. Risk R1
- [ ] Constantes de calibrage exactes reprises du prototype validé (`AY=56, AX=88` pour les ailes, colonne centrale `6mC`/`9mC` doublée par rapport à la largeur du but et centrée sur l'axe, pas alignée sur les poteaux) — ne pas re-deviner ces valeurs
- [ ] Repères visuels 6m/9m/4m/7m tracés sur le terrain (cf. `docs/arch/`), en plus des zones colorées
- [ ] `S.shotViewMode` persiste par appareil (`localStorage`), défaut `"points"` (comportement actuel préservé tant que non basculé)
- [ ] `S.shotViewMode` n'est PAS réinitialisé par `newMatch()` ni par `[data-load-match]` (cf. Risk R2 — contrairement à `S.gkFilter`)
- [ ] Le bouton de bascule reste actif en mode lecteur (`S.readOnly`) — ce n'est pas une écriture de donnée de match (cf. Risk R3)

**Stats → Joueurs (`renderPlayerDetail()`)**
- [ ] Bouton de bascule visible dans l'en-tête de l'overlay détail joueur
- [ ] Mode "zones" : le terrain affiche les 8 zones colorées avec ratio buts/tirs (texte seul, pas de code de zone), plus le marqueur `7m` si le joueur a des tirs de 7m
- [ ] Mode "points" : comportement actuel strictement inchangé
- [ ] La grille Impact (HG/HC/etc., dans le but) n'est pas affectée par le bouton, dans les deux modes

**Stats → Gardiens (`renderGkSheet()`)**
- [ ] Bouton de bascule visible, fonctionne pour le mode combiné (tous GB) et individuel (`S.gkFilter`)
- [ ] Mode "zones" cohérent avec le filtre de type de tir déjà existant (`S.gkShotFilter` — but/arrêt/hors-cadre)
- [ ] `goalZoneHeatmap()` (grille Impact) non affectée

## Hors scope
- Comparaison (STORY-44), PDF (STORY-45) — stories séparées
- Tableau Joueurs PDF (STORY-42) — indépendante

## Dépend de
Aucune.

## Taille
L
