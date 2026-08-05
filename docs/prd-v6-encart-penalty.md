# PRD — Encart Pénalty sur le terrain

## Objectif
Permettre à Romain d'enregistrer l'intégralité d'un penalty — obtention → issue → zone d'impact dans le but si le suivi GB est actif — **sans quitter le terrain des yeux**, en remplaçant le retour obligatoire vers la barre d'actions par un encart qui apparaît directement sur/au-dessus du terrain juste après l'obtention du PO.

Ce cycle a deux objectifs de valeur égale, pas un objectif principal et un effet de bord :
1. **Réduire la rupture d'attention** pendant le moment de saisie le plus sensible au temps de toute l'app (un penalty se joue en quelques secondes).
2. **Combler un vide fonctionnel réel** : la zone d'impact dans le but (`goalZone`) n'est aujourd'hui **jamais capturée en direct** pour un penalty, même avec `S.trackGK` actif, parce que `validateAndClose()` est appelé de façon synchrone avant que le sélecteur de zone n'ait la moindre chance de s'afficher (confirmé dans le code, `clickActionPlayer()` ligne ~676). C'est un manque de donnée, pas seulement un manque d'ergonomie.

Point de contexte qui rassure sur la faisabilité : le mécanisme d'overlay de sélection de zone (`shotMode`/`renderMatchPanel()`, ~1640-1659) **fonctionne déjà correctement avec la position fixe du penalty** (`mapX:50, mapY:85`) — on peut le vérifier aujourd'hui en éditant un événement PEN_GOAL/PEN_SAVE déjà enregistré depuis le feed (`editEvent()`, ligne ~1690-1703) : la grille de zone s'affiche alors normalement. Le problème n'est donc pas que le composant ne sait pas gérer les penaltys, c'est qu'il n'est jamais atteint pendant la saisie en direct à cause du court-circuit de validation immédiate. Ce cycle consiste à **rendre atteignable en direct un chemin qui existe déjà et fonctionne pour l'édition a posteriori** — une amélioration ciblée d'un workflow de saisie existant, pas une nouvelle feature de fond ni une évolution structurelle de données (aucun nouveau champ d'événement).

Concerne exclusivement le mode Expert (`renderMatchPanel()`) — le mode Simple n'a pas de PO/PEN détaillé, il n'est pas impacté.

## Décisions actées sur les questions ouvertes du Brief

Romain n'étant pas disponible pour trancher en direct, les questions ouvertes du Brief sont tranchées ci-dessous en gardant le scope le plus resserré possible — une amélioration ciblée, pas un nouveau chantier. Les décisions marquées *(à confirmer par Romain)* ne bloquent pas Designer → Visual Crafter → Architect → Risk Analyst → Scrum Master, mais devront être validées en conditions réelles.

1. **Le tireur du penalty n'est pas automatiquement le joueur qui a obtenu le PO — mais dans le cas courant, c'est probablement souvent le même.**
   Le Brief posait 3 options (a/b/c). Décision : **un compromis assumé, ni (a) pur ni (b) pur, qui prend le meilleur des deux.**
   - Le joueur qui a obtenu le PO devient **automatiquement le tireur par défaut** dès l'ouverture de l'encart (`ap.shooterId` pré-rempli) — dans le cas courant où c'est le même joueur, Romain n'a **aucun clic joueur supplémentaire** à faire : il tape directement BUT/ARRÊT/HORS CADRÉ.
   - Le terrain reste visible et les joueurs restent cliquables pendant que l'encart est ouvert, pour permettre à Romain de **réassigner le tireur en un tap** sur un joueur différent, si le cas réel du handball (tireur ≠ obtenteur) se présente — coût : +1 clic, uniquement quand c'est nécessaire, jamais par défaut.
   - Cela répond à la fois à l'intuition de Romain (« une fois qu'on a sélectionné celui qui a créé le PO » → 1 clic dans le cas courant) et à la réalité du jeu (tireur parfois différent), sans imposer un second écran de sélection joueur obligatoire dans tous les cas.
   - **Doit être visuellement explicite** quel joueur est actuellement désigné comme tireur avant validation (pas de changement silencieux) — le joueur pré-sélectionné doit être visiblement marqué sur le terrain, pas juste implicite en mémoire. Sans ce garde-fou, le risque de donnée incohérente identifié par le Brief ("mauvais tireur enregistré sans que ce soit visible") se matérialise. Détail exact de mise en évidence laissé au Designer.

2. **Le badge « 🎯 MODE PENALTY » est absorbé par l'encart — pas de double signalement.**
   Le badge et l'encart apparaissent exactement dans la même condition (`S.penMode===true`) : maintenir les deux serait un signal redondant au moment précis où l'attention de Romain doit être la plus concentrée. Décision : le badge autonome (`.ml-status`, ligne ~1838) disparaît en tant qu'élément séparé une fois l'encart affiché ; l'encart lui-même (icône/label clairs) porte désormais ce signal. Détail exact de traitement visuel laissé au Designer (l'exigence fonctionnelle est : pas de double affichage du même signal).

3. **`S.trackGK` désactivé : validation immédiate, jamais de grille de zone — cohérent avec le comportement déjà en place pour les tirs normaux.**
   C'est exactement la logique déjà codée pour les tirs hors pénalty (`showGZ = S.trackGK && ...`, ligne ~1642, et `clickCourtPosition()` ligne ~719 pour le cas non-cadré). Décision : même règle pour l'encart pénalty, sans variation. Pas de nouvelle logique à inventer, juste la même condition appliquée au nouveau chemin.

4. **Sortie explicite de l'encart sans supprimer le PEN_OBT déjà enregistré — ajoutée en Must Have, pas en `undoLast()`.**
   Aujourd'hui, la seule sortie de `S.penMode` sans aller au bout est destructrice (`undoLast()` supprime le PEN_OBT). Scénario réel identifié par le Brief : penalty invalidé après coup (arbitre/vidéo), ou mauvaise manipulation. Décision : un contrôle explicite (ex. `✕` dédié dans l'encart) qui referme l'encart et remet `S.penMode=false` **sans toucher à `S.events`** — le PEN_OBT reste dans le feed, consultable/éditable/supprimable normalement comme n'importe quel autre événement. Ce contrôle doit être visuellement distinct du bouton d'annulation destructeur existant (« ↩ Annuler » / `undoLast()`) pour éviter toute confusion entre "fermer l'encart" et "supprimer l'événement".

5. **Mixage silencieux des zones pénalty dans les heatmaps déjà validées (STORY-30) — refusé pour ce cycle, protégé explicitement.**
   Vérification du code : `renderGkSheet()` (ligne ~3038, `allShots`) et `goalZoneHeatmap()` (ligne ~1059) ne filtrent **pas** les événements pénalty (`isPen`) — ils sont déjà inclus dans le calcul de zone dès qu'ils ont un `x` non-nul (ce qui est déjà le cas aujourd'hui, position fixe 50/85) et compteraient dès que `goalZone` cesse d'être `null`. Sans garde-fou, le jour où ce cycle capture enfin `goalZone` pour les penaltys, la heatmap de zone de l'écran Gardiens déjà livré et validé par Romain (brief-v5/STORY-30) **changerait de chiffres silencieusement**, sans qu'aucun code de cet écran n'ait été explicitement modifié pour ça — exactement le type d'effet de bord que le Brief signale comme risque à éviter. Décision : **exclure explicitement les événements `isPen` du calcul existant** (`allShots` dans `renderGkSheet()`), pour que ce cycle ne change silencieusement aucun chiffre d'un écran déjà validé. L'affichage éventuel des zones pénalty dans les stats gardien est une question de présentation distincte, reportée (voir Hors scope / Nice to Have).
   *(Les stats numériques `gkStats()` — arrêts/total, % — excluent déjà correctement les pénaltys, `!ACTIONS[e.type].isPen` ligne ~1018-1020 ; seul le calcul de zone/heatmap avait ce trou.)*

6. **Réutilisation du mécanisme `shotMode` existant pour l'encart — hypothèse technique, pas une décision PM.**
   Le Brief note que le composant d'overlay `shotMode` (~1640-1659) semble directement réutilisable (position fixe = pas d'étape de clic terrain avant la zone). Confirmé faisable en pratique : ce même chemin est déjà emprunté sans bug aujourd'hui quand on édite un PEN_GOAL/PEN_SAVE existant depuis le feed (`editEvent()`). Le PM ne tranche pas l'implémentation — c'est à l'Architect de confirmer si le composant existant est adapté tel quel ou nécessite une variante dédiée pour l'entrée "juste après PO" (par opposition à l'entrée "édition").

7. **Présentation des zones pénalty dans les stats/heatmaps existantes — question réellement ouverte, non tranchée, non bloquante.**
   Le Brief la signale comme dépassant son cadre (question de lecture, pas de saisie). Décision : reportée, cf. point 5 (protégée par exclusion pour ce cycle) et Nice to Have ci-dessous. Si Romain confirme vouloir voir ces zones apparaître (séparément ou fusionnées) après avoir testé la capture en direct, c'est un fast-follow ciblé sur `renderGkSheet()`/`goalZoneHeatmap()`, pas un chantier de ce cycle.

## Features

### Doit avoir (Must Have)
1. **Encart post-PO remplaçant le retour obligatoire vers `.ml-actions`** : dès que le PEN_OBT est validé (`S.penMode=true`), un encart apparaît automatiquement sur/au-dessus du terrain proposant BUT / TIR ARRÊTÉ / TIR NON CADRÉ — sans que Romain ait à remonter son regard vers la barre d'actions du haut.
2. **Tireur par défaut = joueur du PO, réassignable en un tap** : `ap.shooterId` est pré-rempli avec le joueur qui vient d'obtenir le PO. Le terrain reste visible et les autres joueurs restent cliquables pendant que l'encart est ouvert, pour permettre une réassignation en un seul clic si le tireur réel diffère. Le joueur actuellement désigné comme tireur doit être visuellement marqué sans ambiguïté sur le terrain (pas de changement silencieux de tireur).
3. **Sélecteur de zone d'impact (grille 3×3) déclenché après le choix BUT ou ARRÊT dans l'encart, uniquement si `S.trackGK` est actif** — comble le vide fonctionnel identifié : `goalZone` est désormais réellement enregistré pour un PEN_GOAL/PEN_SAVE. Jamais affiché pour TIR NON CADRÉ (cohérent avec STORY-31, un tir non cadré n'a pas d'impact dans le but par définition).
4. **`S.trackGK` désactivé → validation immédiate**, sans jamais afficher la grille de zone, après le choix BUT/ARRÊT/HORS CADRÉ dans l'encart — même règle que pour les tirs normaux (`showGZ`), aucune nouvelle logique de condition.
5. **Absorption du badge « 🎯 MODE PENALTY »** : pas de double signalement pendant que l'encart est affiché — l'encart lui-même porte le signal "on est en train de traiter un penalty". Détail visuel laissé au Designer.
6. **Sortie explicite de l'encart sans supprimer le PEN_OBT** : un contrôle dédié (visuellement distinct du bouton d'annulation destructeur `undoLast()`/« ↩ Annuler ») referme l'encart et remet `S.penMode=false` en laissant le PEN_OBT intact dans le feed.
7. **Protection défensive des stats gardien déjà livrées (STORY-30/brief-v5)** : exclusion explicite des événements pénalty (`isPen`) du calcul de zone/heatmap existant (`allShots` dans `renderGkSheet()`, alimentant `goalZoneHeatmap()`) — pour que ce cycle ne change silencieusement aucun chiffre affiché sur un écran déjà validé par Romain. Rien d'autre ne change dans `renderGkSheet()`.
8. **Aucune régression** sur : le workflow normal non-pénalty (BUT/TIR ARRÊTÉ/TIR NON CADRÉ), le comportement STORY-31 (pas de zone de but pour un tir non cadré), la structure de données d'événement (aucun nouveau champ), le mode Simple (non concerné, pas de PO/PEN détaillé), et le mode lecteur (`S.readOnly` doit bloquer ce nouveau point d'écriture comme tous les autres, convention documentée dans `CLAUDE.md`).

### Devrait avoir (Should Have)
9. **Validation réelle par Romain en conditions de match** avant de considérer le cycle définitivement clos (critère de succès explicite du Brief) — au-delà de la revue Designer/QA sur écran, puisque le cœur de la valeur (moins de rupture d'attention) ne se vérifie qu'en direct, sous pression du jeu réel.

### Pourrait avoir (Nice to Have — hors de cette version)
10. **Affichage des zones d'impact pénalty dans les stats/heatmaps gardien existantes** (`goalZoneHeatmap()`, feuille fusionnée STORY-30), séparément ou fusionné avec les tirs normaux — décision de présentation reportée (cf. décision actée #5/#7), à ouvrir en cycle dédié seulement si Romain le demande après avoir vu les nouvelles données captées en direct.
11. **Alignement de la page Gardiens du rapport PDF (jsPDF)** pour refléter les zones d'impact pénalty désormais disponibles — chantier distinct, non demandé.
12. **Réassignation a posteriori du joueur ayant obtenu le PO lui-même** (pas seulement du tireur) — non demandé par le Brief, l'édition existante depuis le feed (`editEvent()`) couvre déjà ce cas marginal si besoin.

## Critères d'acceptation
- Après validation du PEN_OBT (clic sur le joueur qui a obtenu le penalty), un encart BUT/TIR ARRÊTÉ/TIR NON CADRÉ apparaît directement sur/au-dessus du terrain, sans retour nécessaire vers `.ml-actions`.
- Le joueur ayant obtenu le PO est visuellement désigné comme tireur par défaut ; un tap sur un autre joueur du terrain (toujours cliquable pendant que l'encart est ouvert) le remplace comme tireur avant validation.
- Si `S.trackGK` est actif et que le choix est BUT ou ARRÊT : la grille de zone 3×3 s'affiche avant validation finale ; l'événement PEN_GOAL/PEN_SAVE enregistré porte un `goalZone` non-null.
- Si le choix est TIR NON CADRÉ, ou si `S.trackGK` est désactivé : validation immédiate, aucune grille de zone n'est affichée à aucun moment.
- Le badge « 🎯 MODE PENALTY » autonome ne s'affiche plus séparément une fois l'encart visible (pas de double signal).
- Un contrôle explicite ferme l'encart sans supprimer le PEN_OBT : après usage de ce contrôle, le PEN_OBT reste visible dans le feed d'événements, et aucun PEN_GOAL/PEN_SAVE/PEN_OFF n'a été créé.
- Sur un jeu de données identique, `renderGkSheet()` (chiffres ET heatmap de zone) affiche exactement les mêmes valeurs qu'avant ce cycle — aucune inclusion silencieuse des nouveaux `goalZone` de pénalty.
- Aucune régression constatée sur le workflow non-pénalty (BUT/TIR ARRÊTÉ/TIR NON CADRÉ) ni sur le comportement STORY-31.
- En mode lecteur (`S.readOnly`), l'encart ne déclenche aucune écriture (ouverture, sélection tireur, choix outcome, sélection zone, validation) — comportement identique à tous les autres points d'écriture de l'app.
- Romain confirme, en conditions réelles de match, que l'enchaînement est plus rapide et plus confortable qu'aujourd'hui, et que la zone d'impact des penaltys est désormais bien enregistrée.

## Hors scope
- Le mode Simple (pas de PO/PEN détaillé dans ce mode, non impacté).
- Le workflow des tirs normaux hors pénalty (inchangé).
- Toute nouvelle métrique ou calcul de stats gardien au-delà de rendre possible la capture de `goalZone` pour les penaltys (`gkStats()`/`gkStatsCombined()` ne changent pas).
- L'affichage des zones d'impact pénalty dans les heatmaps/PDF existants — protégées/exclues ce cycle (décision #5/#7), pas construites différemment. Question de présentation reportée en Nice to Have.
- Le rattrapage des penaltys déjà enregistrés sans zone d'impact dans les matchs passés (aucune zone n'a jamais été capturée pour eux ; pas de backfill).
- La réassignation a posteriori du joueur ayant obtenu le PO (couverte marginalement par l'édition existante depuis le feed si besoin).
- Toute évolution de la structure de données d'événement (aucun nouveau champ requis — `goalZone` existe déjà dans le schéma, seul son alimentation pour les penaltys change).

## Dépendances
- Code existant à modifier/étendre : `clickActionPlayer()` (~659-699, notamment la branche `S.penMode` ligne ~671-679 et la branche PEN_OBT ligne ~682-686), `validateAndClose()` (~886-934), `renderMatchPanel()`/mécanisme `shotMode` (~1612-1677), badge penMode dans `.ml-status` (~1836-1840), `renderGkSheet()`/`allShots` (~2996-3094), `goalZoneHeatmap()` (~1059-...).
- Réutilisation probable (à confirmer par l'Architect) du mécanisme d'overlay `shotMode` déjà existant pour les tirs normaux — déjà confirmé fonctionnel avec la position fixe du penalty via le chemin d'édition (`editEvent()`, ~1690-1703).
- Aucune dépendance sur le chantier stats gardiens (brief-v5/prd-v5, déjà livré et déployé) au-delà de la protection défensive du Must Have #7 ci-dessus (une ligne de filtre, pas une modification de cet écran).
- Aucune dépendance sur la migration d'hébergement Netlify → GitHub Pages en cours (chantiers indépendants).
- Ne nécessite aucune évolution structurelle de données ni du schéma Supabase (`goalZone` existe déjà dans `match_events`, seule son alimentation change pour les penaltys) — s'inscrit dans l'architecture existante (état `S`, rendu `R()`, vanilla JS).

## Risques (détaillés par le Risk Analyst)
- **Risque central identifié par le Brief** : livrer un bel encart qui résout la rupture d'attention mais qui reste câblé sur un `validateAndClose()` immédiat sans jamais laisser la grille de zone s'afficher — reproduirait exactement le bug actuel sous un nouvel habillage visuel. Doit être vérifié explicitement par le Risk Analyst et testé par QA avec `S.trackGK` actif.
- **Incohérence de tireur silencieuse** : si le mécanisme de réassignation (tap sur un autre joueur pendant que l'encart est ouvert) n'est pas suffisamment visible sous la pression du direct, un mauvais joueur pourrait être crédité comme tireur sans que Romain s'en aperçoive avant validation.
- **Régression silencieuse sur un écran déjà validé (STORY-30)** : si l'exclusion défensive des événements `isPen` (Must Have #7) est oubliée pendant l'implémentation, la heatmap de zone de l'écran Gardiens changerait de chiffres dès le premier penalty capturé avec zone, sans qu'aucun code de cet écran n'ait été en apparence modifié — régression difficile à détecter sans test dédié.
- **Confusion sortie vs annulation** : si le nouveau contrôle de sortie (Must Have #6) n'est pas visuellement net par rapport à `undoLast()`/« ↩ Annuler », Romain pourrait supprimer un PEN_OBT par erreur en pensant seulement fermer l'encart, ou inversement.
- **Mode lecteur oublié** : tout nouveau point d'écriture (ouverture d'encart, choix outcome, sélection zone, réassignation tireur, sortie) doit commencer par la garde `if(S.readOnly) return;` (convention documentée dans `CLAUDE.md`) — un oubli exposerait une écriture locale non désirée en mode lecture seule.
- **Pression du direct** : un penalty se joue en quelques secondes ; toute latence de rendu perceptible introduite par le nouvel encart casserait la valeur même de ce cycle. Le re-render complet (`R()`, innerHTML intégral) déjà en place ailleurs dans l'app doit rester aussi réactif pour ce nouveau chemin.
