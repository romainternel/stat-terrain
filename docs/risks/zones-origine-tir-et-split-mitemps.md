# Risques — Zones d'origine du tir + split 1ère/2e mi-temps (PDF)

## R1 — Calibrage des seuils de zone perçu comme "faux" par Romain (P2)
`shotOriginZone()` classe par bandes x/y approximatives, pas par la géométrie exacte des arcs 6m/9m (décision assumée de l'Architect). Un tir proche d'une frontière (ex. y=54% vs 56%) peut tomber dans une zone différente de ce que Romain se rappelle avoir vu en vrai. Comme il n'existe **aucun équivalent live dans l'app** pour cette métrique (contrairement à STORY-39 où le PDF devait matcher `goalZoneHeatmap()` exactement), il n'y a pas de risque de contradiction avec un autre écran — seulement un risque de confiance si le zonage semble arbitraire à l'usage réel.
**Mitigation** : ne pas chercher une précision géométrique parfaite avant d'avoir eu un retour de Romain sur un vrai match — traiter les seuils comme ajustables, pas comme acquis définitivement dès cette story.

## R2 — `scCellH` (46→62mm) fait ricocher le calcul de pagination Carte tir joueur (P1)
La pagination dynamique de STORY-39 (`ensurePageSpace()`, `drawShotCardsSection()`) est générique et devrait absorber une carte plus haute sans casser — mais c'est exactement le type de changement mineur-en-apparence qui a déjà produit un vrai bug de débordement plus tôt cette session (genèse de STORY-39 elle-même). Non re-testé automatiquement par le simple fait que le code soit générique.
**Mitigation** : QA doit re-générer un PDF avec un effectif réaliste plein (14+14, comme le test STORY-39) après ce changement et vérifier explicitement le nombre de cartes par page et l'absence de coupure — pas se contenter d'un visuel à effectif réduit.

## R3 — Page Gardiens sans protection anti-débordement, zone de risque pré-existante non couverte par ce lot (P2)
Confirmé par l'Architect : `ensurePageSpace()` n'est utilisé nulle part sur la page Gardiens (Stats GB, Zones d'impact&Origine, Localisation tirs, Timeline, Notes du coach — tout en position fixe). La décision du Designer d'élargir la carte existante plutôt que d'ajouter une carte (donc de ne pas changer la hauteur totale de la page) neutralise le risque **pour ce lot précis**. Mais le texte de légende passe d'1 à 2 lignes (fontSize 4) dans un espace vertical inchangé entre le titre (y=64) et le début des grilles (y=70) — à vérifier concrètement que ça tient sans chevaucher les grilles.
**Mitigation** : vérification visuelle explicite de ce point précis pendant le développement (pas seulement "la carte ne déborde pas de la page" — aussi "le contenu ne déborde pas de la carte"). Ne pas profiter de cette story pour corriger le manque de garde générale sur cette page — hors scope, à traiter séparément si un futur ajout la rend nécessaire.

## R4 — Bon respect de la convention STORY-37 (flags isGoal/isSave/isOff, pas comparaison exacte) (P1)
`shotOriginZone()`/`drawOriginZone()`/`drawPlayerOriginZone()` et le calcul MT1/MT2 doivent utiliser `ACTIONS[e.type]?.isGoal` etc. (jamais `e.type==="GOAL"`), pour inclure correctement les variantes `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` — c'est exactement la classe de bug corrigée en STORY-37 ailleurs dans le fichier. Le code proposé par l'Architect respecte déjà cette règle, mais c'est un point de vérification explicite pour le Code Reviewer et le QA, pas à assumer silencieusement correct parce que "l'Architect l'a écrit comme ça".

## R5 — Colonnes MT1/MT2 à 9mm, cas limite score élevé en une mi-temps (P3)
Rare en handball de Nationale 1 (un joueur à 10+ buts sur une seule mi-temps serait exceptionnel) mais pas structurellement impossible. À largeur 9mm, un nombre à 2 chiffres doit rester lisible centré — vérification visuelle rapide suffisante, pas de garde de code nécessaire.

## R6 — Cette feature appelle probablement une version "live" plus tard (information, pas un risque pour ce lot)
Une fois que Romain voit la grille Zones d'origine dans le PDF, il est plausible qu'il demande la même chose en direct sur l'écran Gardiens de l'app (comme `goalZoneHeatmap()` existe déjà en live pour l'impact). Ce n'est pas un risque de cette story — `shotOriginZone()` est une fonction pure sans dépendance jsPDF, donc réutilisable telle quelle côté rendu HTML le jour où cette demande arrive. Signalé ici pour que le Scrum Master n'invente pas une story prématurée, et que l'Architect d'un futur cycle sache que la fonction existe déjà.

## R7 — Régression sur `drawPlayerTable()` déjà durci en STORY-39 (P1)
Changement du tableau `colW`/`cols` dans une fonction testée à effectif plein (14 joueurs) il y a une story à peine. Risque standard de régression de centrage/alignement, pas spécifique à cette feature.
**Mitigation** : le Regression Guardian doit re-tester `drawPlayerTable()` à effectif plein (pas seulement F1), comme prolongement naturel de la checklist "Export PDF" déjà mise à jour en v88.

## Synthèse pour le Scrum Master
Pas de risque P0. F1 (zones d'origine) et F2 (split MT1/MT2) touchent des fonctions différentes (`drawGoalZone`/`drawPlayerZoneGrid`/`drawShotCardsSection` d'un côté, `drawPlayerTable` de l'autre) sans dépendance entre elles — **peuvent être 2 stories indépendantes** plutôt qu'un bundle forcé comme STORY-39 (qui bundlait par nécessité, 5 corrections sur les mêmes fonctions). Recommandation : découper en 2 stories séparées, chacune plus petite et plus rapide à vérifier isolément que ne l'aurait été un bundle.
