# STORY-41 — PDF : split 1ère/2e mi-temps sur le tableau Joueurs

**En tant que** Romain,
**Je veux** voir dans le PDF combien de buts chaque joueur a marqué en 1ère et en 2e mi-temps,
**Afin de** repérer en un coup d'œil les joueurs décisifs en fin de match, sans recalculer à la main.

Née de l'évaluation par le squad BMAD d'un PDF de référence (outil concurrent Steazzi) partagé par Romain — cf. `docs/brief-v9-zones-origine-tir-et-split-mitemps.md`.

## Contexte technique
- Zone concernée : `app.js`, fonction `drawPlayerTable(x,y,players)` (page Joueurs)
- Référence architecture (colonnes exactes, largeurs, calcul MT1/MT2) : `docs/arch/zones-origine-tir-et-split-mitemps.md`
- Colonnes actuelles : `["#","NOM","POSTE","BUTS","PD","TIRS","EFF%","PB","2M"]`, largeurs `[10,28,15,13,12,13,15,12,12]` (130mm)
- Nouvelles colonnes : `["#","NOM","POSTE","MT1","MT2","PD","TIRS","EFF%","PB","2M"]`, largeurs `[10,28,15,9,9,12,13,15,12,12]` (135mm)

## Critères d'acceptation
- [ ] Colonne "BUTS" remplacée par deux colonnes "MT1"/"MT2" (buts marqués par mi-temps), même style d'en-tête/cellule que les colonnes existantes
- [ ] Valeurs calculées via `ACTIONS[e.type]?.isGoal` filtré sur `(e.period||1)===1` / `===2` — pas de comparaison exacte de type (convention STORY-37)
- [ ] Total centrage du tableau (`tableX`) reste correct avec la nouvelle largeur totale (135mm) — le calcul déjà dynamique (`totalW=colW.reduce(...)`) ne doit pas être court-circuité
- [ ] Effectif complet des deux côtés (14+14, comme le test STORY-39) : tableau FENIX puis ADVERSAIRE toujours lisibles, sans chevauchement ni débordement, colonnes MT1/MT2 lisibles même à 2 chiffres
- [ ] Aucune régression sur les autres colonnes (#, NOM, POSTE, PD, TIRS, EFF%, PB, 2M) ni sur la pagination Joueurs/Évolution héritée de STORY-39

## Hors scope
- Split mi-temps sur d'autres statistiques que les buts (PD, PB, etc.) — pas demandé, pas dans ce lot
- Colonne "Total" redondante — le total reste lisible par somme visuelle MT1+MT2

## Dépend de
Aucune (indépendante de STORY-40)

## Taille
S
