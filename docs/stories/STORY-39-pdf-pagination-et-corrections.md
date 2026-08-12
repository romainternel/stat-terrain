# STORY-39 — PDF : pagination robuste + corrections de contenu (glyphe, cohérence Zones d'impact, effectif adverse)

**En tant que** Romain,
**Je veux** un PDF qui ne déborde plus quels que soient les effectifs des deux équipes, dont chaque chiffre affiché se lit sans ambiguïté et documente les deux équipes,
**Afin de** pouvoir distribuer ce document (staff, joueurs) sans avoir à vérifier manuellement qu'il n'est pas cassé à chaque match.

Bundle volontaire de 5 corrections dans une seule story (recommandation de l'Architect et du Risk Analyst, cf. `docs/risks/terrain-postes-multiples-et-pdf-v2.md` R2) : `generatePDF()` a déjà été retouchée 3 fois cette session, une story par point multiplierait les points de régression croisée sur la même fonction.

## Contexte technique
- Zone concernée : `app.js`, fonction `generatePDF()` (~ligne 4432) et ses sous-fonctions internes (`drawGoalZone`, `drawPlayerTable`, la boucle "Carte tir joueur")
- Référence architecture complète (code exact, à suivre précisément) : `docs/arch/terrain-postes-multiples-et-pdf-v2.md`
- Référence visuelle (couleurs RGB exactes, légende) : `docs/visual/terrain-postes-multiples-et-pdf-v2.md`
- Nouvelle fonction `ensurePageSpace(y, neededHeight, title, subtitle)` — garde de débordement générique, appelée **avant le titre de section** (pas seulement avant le contenu, cf. Risk R1) à chaque endroit dont la hauteur dépend du volume de données
- Nouvelle fonction `drawShotCardsSection(y, title, players, teamKey)` — extraction de la boucle FENIX existante de la page "Carte tir joueur", paramétrée par équipe

## Critères d'acceptation

**Pagination (F2)**
- [ ] "ÉVOLUTION DU SCORE" sur sa propre page, après la page Joueurs et avant "Carte tir joueur"
- [ ] PDF généré avec 16 joueurs FENIX + 16 joueurs adverses sélectionnés (ou effectif max réaliste) : aucune section coupée, aucun chevauchement avec le pied de page "Page X/N", sur les pages Joueurs, Évolution, Carte tir joueur
- [ ] Quand `ensurePageSpace()` déclenche un saut de page, le titre de section ("FENIX"/"ADVERSAIRE" etc.) part sur la nouvelle page avec son contenu — jamais orphelin sur la page précédente
- [ ] Page 1 (bandeau/carte score) revérifiée avec le même jeu de données chargé — si le chevauchement signalé par Romain persiste après ce lot, il est documenté comme bug distinct plutôt que bloquant cette story

**Glyphe Top 3 (F3)**
- [ ] Rang 1 du Top 3 affiche `"1."` (plus de `"★"`/`"&"`)
- [ ] Audit rapide de `generatePDF()` : aucun autre caractère Unicode non-ASCII dans un appel `doc.text()`

**Top 3 gardien qualifié (F5)**
- [ ] Ligne d'un gardien en Top 3 affiche `gkS.total`/`gkS.pct` (arrêts/tirs cadrés), pas `gkS.totalAll`
- [ ] Seuil de qualification (≥40%, ≥6 arrêts) recalculé sur la même base "cadrés"
- [ ] Vérifié sur le cas réel du test de Romain (gardien à 6/7 cadrés, 86%) : qualifie toujours

**Carte tir joueur — effectif adverse + centrage (F6)**
- [ ] Section "ADVERSAIRE" ajoutée sur la page Carte tir joueur, même format que FENIX, visible uniquement si au moins un tir adverse est enregistré
- [ ] Rendu FENIX (sans changement de données) visuellement identique à avant le refactor
- [ ] Une dernière ligne à carte unique (nombre impair de joueurs avec tirs) est centrée horizontalement, pas collée à la marge gauche

**Zones d'impact Gardiens — cohérence avec l'app (F4)**
- [ ] Ratio affiché = buts/total (perspective tireur), plus arrêts/total
- [ ] Couleur : vert si buts/total > 0.5, cyan `[78,205,232]` sinon — plus de rouge sur cet encart
- [ ] Légende ajoutée sous le titre, texte identique à l'app : `"Stat des tireurs (ex : 1/1 = 1 but et non arrêt)"`
- [ ] Lettres de zone (HG/HC/HD...) retirées des cellules

## Hors scope
- Idée "Steazzi" (graphique buts/minute) — pas dans ce lot
- Toute modification du fond blanc / encarts bleus / structure déjà livrée non mentionnée dans les critères ci-dessus

## Dépend de
Aucune (indépendante de STORY-38)

## Taille
L (5 corrections bundlées volontairement, cf. justification ci-dessus — mais chacune individuellement contenue à une fonction ou sous-fonction précise)
