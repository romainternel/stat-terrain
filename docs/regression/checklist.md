# Checklist de régression — FENIX Stats

*Maintenue par le Regression Guardian — squad de contrôle BMAD*
*Première initialisation le 2026-07-23, à partir de `CLAUDE.md` et des stories validées par le QA.*

| Feature | Introduite | Critère de bon fonctionnement | Criticité | Dernière vérif. OK |
|---|---|---|---|---|
| Navigation entre les 5 onglets (Équipes/Match/Stats/Bilan/Matchs) | historique | Cliquer un onglet du header bascule vers l'écran correspondant, sur iPad et iPhone | Critique | 2026-07-23 (STORY-18) |
| Saisie d'action en match (workflow complet) | historique | Sélection action → joueur → terrain → zone de but → validation, sans blocage | Critique | 2026-07-27 (STORY-09 — audit par vrais clics, BUT/PB/2min/PD/undo testés en direct, SAVE/OFF/PO/jet franc/RED/TM vérifiés par lecture de code, aucune friction trouvée) |
| Alertes automatiques (TM conseillé, changez de GB) | historique | Se déclenchent selon les règles documentées dans `CLAUDE.md`, anti-spam 30s | Important | Non re-vérifié dans ce cycle |
| Stats GB (arrêts/total, zones d'impact) | historique | Calculs corrects, filtres MT1/MT2 fonctionnels | Important | Non re-vérifié dans ce cycle |
| Export PDF (3 pages) | historique | Génère un PDF avec comparatif, joueurs, gardiens | Important | Non re-vérifié dans ce cycle |
| Import/export CSV équipes | historique | Import respecte le format `number,name,position`, export produit un fichier valide | Secondaire | Non re-vérifié dans ce cycle |
| Mode hors-ligne (PWA/service worker) | historique | L'app fonctionne sans réseau après un premier chargement | Critique | Non re-vérifié dans ce cycle (cf. version SW bumpée à v48, à re-tester après un vrai déploiement) |
| Layout Match iPad (paysage/portrait) | historique | Écran Match utilisable sans chevauchement | Critique | 2026-07-23 (capture `03-match-ipad-landscape.png`, avant le fix nav — non affecté par STORY-18) |
| Layout Match iPhone portrait | STORY-02 | Actions/score/timer/terrain utilisables sans chevauchement, ≤430px portrait | Critique | 2026-07-27 (STORY-02, QA PASSED) |
| Layout Match iPhone paysage | STORY-03 | Score/timer/contrôles FENIX visibles sans scroll ; terrain agrandi (scroll encore nécessaire pour l'effectif complet, cf. QA-03) | Critique | 2026-07-27 (STORY-03, QA PASSED WITH NOTES — voir `docs/qa/QA-03-layout-match-iphone-paysage.md`) |
| Navigation header sur iPhone (5 onglets atteignables) | STORY-18 | Tous les onglets atteignables sans être coupés hors écran, portrait et paysage | Critique | 2026-07-23 (STORY-18, QA PASSED) |
| Étiquettes joueurs sur le terrain lisibles (largeur réduite) | STORY-19 | Aucun chevauchement avec un effectif réel (plusieurs joueurs par position) ; effectif complet dégradé mais lisible | Critique | 2026-07-27 (STORY-19, QA PASSED WITH NOTES — zone tactile sous 44px, limite physique assumée, voir `docs/qa/QA-19-chevauchement-joueurs-terrain.md`) |
| Cartes Stats/Bilan/Setup avec relief visuel | STORY-04 | `.card`/`.gk-stat` avec dégradé/bordure/ombre cohérents, sans régression de contraste | Important | 2026-07-27 (STORY-04, QA PASSED WITH NOTES — impact visuel confirmé mais jugé insuffisant à lui seul pour "ça claque", voir `docs/qa/QA-04-polish-tokens-ombres-cartes.md`) |
| États interactifs généralisés (active/focus) | STORY-05 | `.nav-b`/`.st-tab` réagissent au tap ; focus clavier visible ; `.act-h`/`.btn` du Match non affectés | Important | 2026-07-27 (STORY-05, QA PASSED — vérifié par vraies touches Tab, pas seulement `.focus()` programmatique) |
| Terrain n'affiche que les joueurs sélectionnés | STORY-20 | Aucun joueur affiché (Match, PD, 2min/carton) tant qu'aucune sélection explicite n'a été faite ; sélection partielle respectée | Critique | 2026-07-28 (STORY-20, QA PASSED — 3 fonctions distinctes testées indépendamment) |
| Numéro manquant affiché discrètement | STORY-21 | Tiret (pas "?") sur le terrain quand un joueur n'a pas de numéro ; `renderTeamSetup` non affecté | Secondaire | 2026-07-28 (STORY-21, QA PASSED) |
| Terrain SVG (fond visuel Match/Stats/PD) | STORY-22 | Fond de terrain SVG sur les 7 emplacements (Match, Stats GB, mode tir, sélecteurs PD/2min), proportions 6m/9m/7m/4m, référentiel `viewBox 0 0 350 208` préservé | Important | 2026-07-28 (STORY-22, QA PASSED WITH NOTES — validation visuelle explicite de Romain en attente, voir `docs/qa/QA-22-refonte-svg-terrain.md`) |

## Note du Regression Guardian

Cette checklist est neuve — construite rétroactivement à partir de `CLAUDE.md` pour les features historiques (jamais vérifiées dans le cadre de ce squad, seulement documentées) et à partir des stories effectivement passées par le QA pour les entrées récentes. Les lignes "Non re-vérifié dans ce cycle" ne sont pas des échecs — elles indiquent simplement qu'aucun changement de ce cycle ne les touchait, donc pas de raison de les re-tester en profondeur (cf. mon mandat : cibler ce qui est plausiblement à risque, test de fumée sur le reste).
