# STORY-72 — Vraie distinction 6m / 6-9m / 9m sur le terrain de zones

**En tant que** Romain, en train de consulter les stats de zone en direct (Comparaison, Gardiens, Joueurs),
**Je veux** qu'un tir à 8m ne soit plus compté comme un tir à 6m,
**Afin d'** avoir une lecture précise de la distance de tir réelle, pas seulement proche/loin.

Demande directe de Romain (`docs/brief-v18-zones-tir-distance.md`) — portée confirmée "live + PDF" par Romain lui-même quand la question lui a été posée explicitement (choix entre PDF seul, live+PDF, ou alternative sans redessiner le terrain).

## Contexte technique
- Zone concernée : `shotZoneCourt()` (`app.js:2670`), `buildCourtZones()` (`app.js:2704`), `COURT_ZONE_ORDER` (`app.js:2689`), `COURT_ZONE_LABEL_POS` (`app.js:2695`) — `aggregateCourtZones()`/`renderCourtZones()` itèrent déjà sur `COURT_ZONE_ORDER` sans changement nécessaire.
- Nouvelles structures : aucune — `COURT_ZONE_ORDER` passe de 8 à 11 entrées (ajout `69MG`/`69MC`/`69MD`), `COURT_ZONE_LABEL_POS` gagne 3 entrées correspondantes.
- Impact sur l'existant : le mode "points" (`S.shotViewMode==="points"`) n'est pas concerné, vérifié aux 4 sites d'appel de `renderCourtZones()`. Aucune migration de données (classification recalculée à la volée depuis `x`/`y`, jamais persistée).
- Code de référence détaillé (classification, prête à coder) et approche de visualisation (méthode incrémentale imposée) : `docs/architecture/zones-tir-distance.md` section F1.
- Maquette du terrain à 11 zones : `docs/design/zones-tir-distance.md`.
- Ajustements de trait/typographie pour les zones plus fines : `docs/visual/zones-tir-distance.md`.

## Critères d'acceptation
- [ ] `shotZoneCourt(x,y)` retourne `6MC`/`69MC`/`9MC` correctement pour 3 points de test connus dans le couloir central (ex: pile devant le but à une distance équivalente à 5m/7.5m/11m réels) — vérifiable indépendamment du rendu visuel avant de toucher `buildCourtZones()`.
- [ ] `shotZoneCourt(x,y)` retourne la même distinction 3 bandes pour les couloirs Gauche et Droit (pas seulement le centre).
- [ ] Les zones d'aile (`AILG`/`AILD`) restent inchangées — pas de subdivision par profondeur, comportement identique à avant cette story.
- [ ] **Méthode de développement imposée** (cf. risque #1) : l'arc de la nouvelle frontière R6 est d'abord vérifié visuellement en overlay de debug contre la ligne des 6m déjà tracée par `courtSvgMarkup()`, avant toute construction de polygone rempli — pas de polygone `6M*`/`69M*` écrit sans cette étape de vérification intermédiaire préalable.
- [ ] Le terrain "zones" (bouton 🗺️, Stats Comparaison/Gardiens/Joueurs) affiche 11 zones sans trou ni chevauchement visible entre elles, avec le comptage `but/tir` correct par zone.
- [ ] Le mode "points" (📍) reste strictement inchangé.
- [ ] `_courtZonesCache` continue de fonctionner (polygones calculés une seule fois, pas de recalcul à chaque render).
- [ ] **Revalidation visuelle explicite par Romain** du rendu réel (pas juste un accord de principe) avant de considérer la story terminée — cet écran a déjà demandé 8 itérations de prototype avant validation initiale.
- [ ] `new Function()` passe sur `app.js` modifié.

## Hors scope
- Le mode "points" (`S.shotViewMode==="points"`) — inchangé.
- Le PDF (`shotOriginZone`, `drawOriginZone`, `drawPlayerOriginZone`) — traité séparément dans STORY-73.
- La zone d'impact (`e.goalZone`, 9 zones HG/HC/HD/...) — système différent, non concerné.
- Toute généralisation du système de zones à un nombre de bandes paramétrable — cf. Architecture, critère de bascule, pas nécessaire aujourd'hui.

## Dépend de
Aucune

## Taille
L
