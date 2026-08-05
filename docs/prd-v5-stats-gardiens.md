# PRD — Refonte Stats Gardiens

## Objectif
Permettre à Romain de lire la performance d'un gardien — la sienne et celle de l'adverse — **en un seul regard, sans scroller sur iPad**, avec un format de chiffres cohérent avec le reste de l'app (convention `arrêts/total` déjà en place pour les stats pen). C'est une refonte de présentation d'un écran existant (`renderStatGk()`), pas une nouvelle feature : aucune donnée ni calcul ne change (`gkStats()`/`gkStatsCombined()` restent inchangées).

## Décisions actées sur les questions ouvertes du Brief

Romain n'étant pas disponible pour trancher en direct, les questions ouvertes du Brief sont tranchées ci-dessous avec une hypothèse par défaut documentée, en gardant le scope le plus resserré possible. Toute décision marquée *(à confirmer par Romain)* n'est pas bloquante pour Designer → Visual Crafter → Architect → Risk Analyst → Scrum Master, mais devra être validée en conditions réelles avant de considérer le cycle définitivement clos.

1. **Le filtre GB individuel (Tout/GB1/GB2/GB3) — conservé, mais rétrogradé visuellement.**
   Vérification du code (`renderStatGk()`, ligne ~2997-3001 et ~3044-3047) : ce filtre ne pilote pas que l'affichage des 5 chiffres du résumé, il pilote aussi **quels tirs s'affichent sur le terrain d'impact** (`gkIds = filter==="all" ? gbs.map(...) : [filter]`). La table de détail par GB (`renderGkDetailTables()`) donne les chiffres agrégés par gardien, mais **jamais leur localisation sur le terrain**. Le filtre n'est donc pas redondant avec la table — il reste le seul moyen de voir "où tire-t-on sur GB2 spécifiquement" quand une équipe a fait tourner plusieurs gardiens. Décision : le filtre reste, mais devient un contrôle secondaire (visuellement plus discret que le bloc "Tous les GB" par défaut), pas un élément de même poids que la synthèse chiffrée.

2. **Un seul agencement doit servir les deux contextes (bord de terrain ET debrief).**
   Construire deux mises en page distinctes selon le contexte d'usage supposerait de détecter ou de faire choisir le contexte, ce qui n'existe nulle part ailleurs dans l'app et alourdirait le scope sans certitude de valeur. Décision : **une seule disposition responsive**, calibrée sur la contrainte la plus dure (bord de terrain : coup d'œil, sans scroll, iPad) — un agencement qui satisfait "lisible en 2 secondes debout" satisfait a fortiori "lisible en debrief posé". Le repli mobile (<700px, breakpoint déjà établi par STORY-02/03/19/22) reste le seul point de variation d'agencement.
   *(À confirmer par Romain : si le debrief se fait parfois sur iPhone ou desktop, ou face à d'autres personnes, cf. point 5 ci-dessous — n'est pas bloquant pour cette version.)*

3. **Le mot "feuille" ne déclenche pas d'alignement avec le PDF dans cette version.**
   Vérification du code : la page 3 du PDF ("STATISTIQUES GARDIENS", `app.js` ~ligne 4322+) est produite par des appels `doc.text()`/`jsPDF` directs, un rendu entièrement séparé de `renderStatGk()` (pas de HTML/CSS partagé). Aligner les deux formats serait un chantier distinct (refonte de la page PDF en jsPDF), non demandé explicitement par Romain, et hors de la contrainte "amélioration ciblée d'un écran". Décision : **écran seulement pour ce cycle**, le PDF n'est pas touché. Le mot "feuille" est traité comme désignant la vue récapitulative par équipe à l'écran, pas une référence littérale au PDF.
   *(Question à reposer explicitement à Romain lors de la validation : si son usage réel du PDF en debrief révèle la même gêne de lecture, l'alignement PDF devient un cycle à part entière, pas un ajout à celui-ci.)*

4. **"L'un en dessous de l'autre" = repli mobile, pas une préférence à tester indépendamment de l'appareil.**
   Cohérent avec l'avis informel déjà circulé et avec le pattern déjà établi ailleurs dans l'app (breakpoint 700px). Tester une variante empilée même en desktop/iPad est noté en Nice to Have si Romain le redemande après avoir vu la V1 — pas d'A/B test formel dans ce cycle.

5. **Audience du debrief (joueurs/staff regardant l'écran) — question réellement ouverte, non tranchée, non bloquante.**
   Aucun élément du Brief ni de `CLAUDE.md` ne permet de trancher raisonnablement (aucune mention d'un mode "projection" ou "écran partagé" ailleurs dans l'app). Hypothèse par défaut : usage solo sur iPad tenu en main, comme le reste de l'app. Documentée comme **question ouverte reportée** — si Romain confirme un usage collectif/projeté, un ajustement de lisibilité à distance (tailles de police, contraste) sera un fast-follow, pas un blocage de ce cycle.

6. **Priorité vs migration d'hébergement Netlify→GitHub Pages : pas de conflit, pas de séquencement imposé.**
   Ce chantier est un changement de présentation front (`app.js`/`style.css`), la migration d'hébergement est un sujet d'infra/déploiement indépendant du code applicatif. Les deux peuvent avancer en parallèle ou dans n'importe quel ordre sans se bloquer mutuellement — aucune dépendance technique entre les deux.

## Features

### Doit avoir (Must Have)
1. **Fusion des cartes empilées en une "carte gardien" par équipe** : la carte résumé (nom + chiffres) et la carte "tirs subis" (heatmap + terrain SVG) actuellement séparées et empilées (`renderStatGk()`, 2 blocs `stat-courts` distincts) deviennent une seule unité de lecture par équipe, terrain et chiffres visibles simultanément sans devoir scroller pour relier l'un à l'autre.
2. **Reformat des chiffres de synthèse avec hiérarchie à 3 niveaux**, aligné sur la convention `arrêts/total` déjà utilisée pour les stats pen (documentée dans `CLAUDE.md`) :
   - Niveau 1 (primaire) : `arrêts/total` (ex. `3/5`) — remplace les deux chiffres séparés ARRÊTS et TIRS CADRÉS affichés aujourd'hui côte à côte avec le même poids.
   - Niveau 2 (dérivé du niveau 1) : `%` — reste rattaché visuellement au ratio, pas isolé au même rang.
   - Niveau 3 (contextuel/secondaire) : hors cadre (`offs`) — reste visible mais clairement subordonné aux deux premiers.
   - ENCAISSÉS (`goals`) reste visible (c'est le nombre de buts subis, donnée de score) mais n'a plus le même poids visuel qu'aujourd'hui — sa hiérarchie exacte (regroupé avec le ratio ou en secondaire) est un détail de layout laissé au Designer, tant que les 3 niveaux ci-dessus sont respectés.
3. **Terrain d'impact + heatmap intégrés dans la même carte que la synthèse chiffrée** (pas seulement le même onglet) — la proximité visuelle chiffre ↔ localisation est le cœur du problème de lecture identifié par le Brief.
4. **Comportement responsive sans régression** : sur iPad (paysage et portrait), la carte fusionnée tient sans scroll. Sous 700px (iPhone), repli vertical défini par le Designer, sans réintroduire les problèmes de terrain écrasé/illisible déjà rencontrés et corrigés (STORY-02/03/19/22).
5. **Filtre GB individuel (Tout/GB1/GB2/GB3) conservé**, fonctionnellement inchangé (il continue de piloter à la fois les chiffres affichés et les tirs affichés sur le terrain), mais visuellement secondaire par rapport au bloc "Tous les GB" affiché par défaut.
6. **Table de détail par GB (`renderGkDetailTables()`) conservée**, fonctionnellement inchangée, repositionnable dans la page si le Designer le juge utile pour la hiérarchie de lecture, mais toujours accessible sans clic supplémentaire (pas caché derrière un accordéon/toggle dans cette version).
7. **Aucun changement de données** : `gkStats()`, `gkStatsCombined()`, la structure d'événement, et tout calcul existant restent strictement inchangés — ce cycle est 100% présentation.

### Devrait avoir (Should Have)
8. **Filtre de type de tir (Encaissés/Arrêtés/Hors cadre) sur le terrain conservé**, repositionné si nécessaire dans la nouvelle carte fusionnée, fonctionnellement inchangé.
9. **Validation réelle par Romain** en conditions bord de terrain ET debrief avant de considérer le cycle clos (critère de succès explicite du Brief) — au-delà de la revue Designer/QA habituelle sur écran.

### Pourrait avoir (Nice to Have — hors de cette version)
10. Tester une variante "chiffres empilés verticalement" comme préférence de lecture indépendante de l'appareil (au-delà du simple repli mobile), si Romain la redemande après avoir vu la V1.
11. Alignement de la page Gardiens du rapport PDF (jsPDF) sur ce nouveau format — chantier distinct, à ouvrir seulement si Romain confirme que la gêne existe aussi côté PDF.
12. Ajustement de lisibilité pour écran partagé/projeté (tailles de police, contraste renforcé) si Romain confirme un usage collectif en debrief.
13. Repenser plus profondément le filtre GB individuel ou la table de détail (fusion, suppression, autre présentation) — non justifié tant que le filtre reste la seule source d'info "terrain par GB spécifique".

## Critères d'acceptation
- Sur iPad (paysage et portrait), Romain peut lire pour une équipe donnée : arrêts/total, %, hors cadre, ET voir où les tirs ont atterri, **sans scroller**.
- Le format `arrêts/total` est utilisé pour la synthèse gardien, visuellement cohérent avec le format déjà utilisé pour les stats pen ailleurs dans l'app.
- Sous 700px (iPhone), aucune régression : pas de terrain écrasé ou illisible, repli vertical propre.
- Le filtre Tout/GB1/GB2/GB3 reste fonctionnel (chiffres ET terrain se mettent à jour ensemble) et visuellement secondaire.
- La table de détail par GB reste accessible sans clic supplémentaire depuis l'onglet Gardiens.
- Aucune régression sur `gkStats()`/`gkStatsCombined()`/structure d'événement — le Regression Guardian ne détecte aucun changement de valeur affichée, seulement de présentation.
- Romain confirme en conditions réelles (bord de terrain ET debrief) que la nouvelle version répond mieux à son usage que l'actuelle.

## Hors scope
- Toute nouvelle donnée ou calcul gardien (les fonctions `gkStats()`/`gkStatsCombined()` ne changent pas).
- La page Gardiens du rapport PDF (jsPDF) — décision actée ci-dessus, écran seulement pour ce cycle.
- Les autres onglets Stats (Comparaison, Joueurs, Analyse) — aucun changement, même si une cohérence de format pourrait un jour s'y étendre.
- Toute détection automatique de contexte d'usage (bord de terrain vs debrief) — une seule disposition responsive sert les deux.
- Toute suppression ou refonte profonde du filtre GB individuel ou de la table de détail par GB.
- Tout ajustement pour écran partagé/projeté (audience multiple en debrief) — reporté, non tranché.

## Dépendances
- Aucune dépendance sur le chantier de migration d'hébergement en cours (Netlify → GitHub Pages) — les deux peuvent avancer indépendamment.
- Dépend uniquement du code existant de `renderStatGk()`, `renderGkDetailTables()`, `gkStats()`, `gkStatsCombined()`, `selectedGbs()`, `goalZoneHeatmap()`, `courtSvgMarkup()` (`app.js`, ~lignes 1014-1053 et 2946-3094) — aucune évolution structurelle de données requise.
- Dépend des contraintes CSS déjà établies pour la largeur de terrain SVG en iPad/iPhone (STORY-22 notamment, géométrie réglementaire 6m/9m) — le Designer et l'Architect doivent réutiliser ces contraintes, pas les redéfinir.

## Risques (détaillés par le Risk Analyst)
- **Faux sentiment de gain** : un écran plus dense visuellement mais qui reste aussi long à parcourir si la fusion des cartes n'est qu'un empilement resserré sans vraie hiérarchie (risque déjà identifié dans le Brief — "le pire résultat si mal fait").
- **Régression iPhone portrait** : un format de chiffres/terrain qui fonctionne en iPad mais redevient illisible ou provoque un débordement sous 700px (risque déjà rencontré plusieurs fois : STORY-02/03/18/19/22).
- **Ambiguïté sur le poids du filtre GB** : si le Designer le rend trop discret, Romain pourrait perdre la capacité de vérifier visuellement où tire-t-on sur un gardien précis (fonction que la table de détail ne couvre pas).
- **Question de l'audience partagée non tranchée** : si le debrief s'avère être un moment collectif/projeté, la validation réelle par Romain pourrait révéler un besoin de lisibilité à distance non anticipé dans cette version — accepté comme fast-follow, pas comme blocage.
- **Confusion "feuille" vs PDF** : si Romain, en validant, s'attendait implicitement à voir le PDF aligné aussi, le cycle pourrait sembler incomplet malgré un scope explicitement resserré à l'écran — à clarifier dès la présentation de la V1, pas après.
