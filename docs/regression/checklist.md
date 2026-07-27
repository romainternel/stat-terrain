# Checklist de régression — FENIX Stats

*Maintenue par le Regression Guardian — squad de contrôle BMAD*
*Première initialisation le 2026-07-23, à partir de `CLAUDE.md` et des stories validées par le QA.*

| Feature | Introduite | Critère de bon fonctionnement | Criticité | Dernière vérif. OK |
|---|---|---|---|---|
| Navigation entre les 5 onglets (Équipes/Match/Stats/Bilan/Matchs) | historique | Cliquer un onglet du header bascule vers l'écran correspondant, sur iPad et iPhone | Critique | 2026-07-23 (STORY-18) |
| Saisie d'action en match (workflow complet) | historique | Sélection action → équipe → joueur → terrain → zone de but → validation, sans blocage | Critique | Non re-vérifié dans ce cycle (cf. STORY-09, toujours ouverte) |
| Alertes automatiques (TM conseillé, changez de GB) | historique | Se déclenchent selon les règles documentées dans `CLAUDE.md`, anti-spam 30s | Important | Non re-vérifié dans ce cycle |
| Stats GB (arrêts/total, zones d'impact) | historique | Calculs corrects, filtres MT1/MT2 fonctionnels | Important | Non re-vérifié dans ce cycle |
| Export PDF (3 pages) | historique | Génère un PDF avec comparatif, joueurs, gardiens | Important | Non re-vérifié dans ce cycle |
| Import/export CSV équipes | historique | Import respecte le format `number,name,position`, export produit un fichier valide | Secondaire | Non re-vérifié dans ce cycle |
| Mode hors-ligne (PWA/service worker) | historique | L'app fonctionne sans réseau après un premier chargement | Critique | Non re-vérifié dans ce cycle (cf. version SW bumpée à v48, à re-tester après un vrai déploiement) |
| Layout Match iPad (paysage/portrait) | historique | Écran Match utilisable sans chevauchement | Critique | 2026-07-23 (capture `03-match-ipad-landscape.png`, avant le fix nav — non affecté par STORY-18) |
| Layout Match iPhone portrait | STORY-02 | Actions/score/timer/terrain utilisables sans chevauchement, ≤430px portrait | Critique | 2026-07-27 (STORY-02, QA PASSED) |
| Layout Match iPhone paysage | STORY-03 | Score/timer/contrôles FENIX visibles sans scroll ; terrain agrandi (scroll encore nécessaire pour l'effectif complet, cf. QA-03) | Critique | 2026-07-27 (STORY-03, QA PASSED WITH NOTES — voir `docs/qa/QA-03-layout-match-iphone-paysage.md`) |
| Navigation header sur iPhone (5 onglets atteignables) | STORY-18 | Tous les onglets atteignables sans être coupés hors écran, portrait et paysage | Critique | 2026-07-23 (STORY-18, QA PASSED) |

## Note du Regression Guardian

Cette checklist est neuve — construite rétroactivement à partir de `CLAUDE.md` pour les features historiques (jamais vérifiées dans le cadre de ce squad, seulement documentées) et à partir des stories effectivement passées par le QA pour les entrées récentes. Les lignes "Non re-vérifié dans ce cycle" ne sont pas des échecs — elles indiquent simplement qu'aucun changement de ce cycle ne les touchait, donc pas de raison de les re-tester en profondeur (cf. mon mandat : cibler ce qui est plausiblement à risque, test de fumée sur le reste).

**2026-07-27** : STORY-02 a aussi révélé un bug hors checklist — chevauchement des étiquettes joueurs sur le terrain (`.cp-player`) à largeur réduite avec un effectif complet sélectionné. Pas encore une feature "protégée" ici (pas de story de correction livrée) — à ajouter à cette checklist une fois qu'une story dédiée sera passée par le QA.
