# STORY-37 (à cadrer) — Efficacité % peut dépasser 100% sur un match avec penalty

## Origine
Trouvé par le QA pendant la validation de STORY-32/33/34/35/36 (`docs/qa/QA-32-33-34-35-36.md`) : sur un match contenant un but sur penalty, l'onglet Stats → Analyse (match en cours) affiche une "Efficacité" pouvant dépasser 100% (ex. 300% observé en test), alors que Bilan → Analyse (même match, une fois sauvegardé) affiche une valeur cohérente (100%) pour les mêmes données.

## Cause identifiée (pré-existante, non introduite par ce cycle)
- `teamScore(team)` compte via le flag `ACTIONS[e.type].isGoal` → inclut `PEN_GOAL`.
- `teamStat(team, type)` fait une correspondance exacte sur `e.type===type` → `teamStat(team,"GOAL")` exclut `PEN_GOAL`.
- `autoAnalysis()`/`generateExportText()` (Stats → Analyse du match en cours, **non modifiées par ce cycle**) calculent `hTotal = teamStat("home","GOAL")+teamStat("home","SAVE")+teamStat("home","OFF")` — dénominateur qui exclut les tirs pénalty — puis `hEff = hScore/hTotal` avec `hScore` qui, lui, inclut les buts sur pénalty via `teamScore()`. Numérateur et dénominateur ne comptent pas la même chose : l'efficacité peut dépasser 100%.
- `matchStats(m)` (utilisée par le jumeau `matchAnalysis(m)` de Bilan, STORY-35) ne reproduit pas ce bug : `goals`/`saves`/`offs` y sont tous les trois calculés via les flags `isGoal`/`isSave`/`isOff` de façon cohérente, donc `total` inclut bien les tirs pénalty des deux côtés du ratio.

## Pourquoi pas corrigé dans ce cycle
`teamScore`/`teamStat` sont lus par 9 fonctions distinctes dont `renderMatch()` (écran Match en direct) et `saveMatch()` — protégées explicitement par une décision d'architecture actée pour STORY-35 (`docs/arch/analyse-pdf-bilan.md`) : aucune modification de ces helpers pour ne pas risquer de régression sur l'écran utilisé en direct pendant un vrai match. Corriger ce bug proprement nécessite donc un vrai cadrage (Analyst/PM/Architect) plutôt qu'un correctif improvisé en fin de cycle — recommandation du QA suivie : ticket séparé.

## Piste de correctif (à valider lors du cadrage)
Deux options possibles, à trancher : (a) faire compter `teamStat`/les totaux via les flags `isGoal`/`isSave`/`isOff` comme le fait déjà `matchStats(m)` (aligne le comportement, risque de régression sur les 9 call sites à évaluer un par un) ; (b) exclure explicitement les pénaltys du calcul d'efficacité des deux côtés (numérateur ET dénominateur), si c'est la lecture statistique voulue par Romain (l'efficacité "au jeu" séparée de l'efficacité "sur pénalty").

## Statut
Non cadré, non développé. Story stub à reprendre lors d'un prochain cycle `/construire`.
