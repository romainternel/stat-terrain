# PRD — Analyse & Notes Coach accessibles depuis Bilan (PDF archivé différé)

## Objectif

Permettre à Romain de retrouver, dans **Bilan**, l'analyse automatique et ses notes de coach de **n'importe quel match sauvegardé** qu'il sélectionne dans l'historique — sans jamais toucher ni risquer d'écraser le match en cours (`S`) — en plus de la consultation déjà possible dans Stats pour le match actif.

Le Brief demandait trois choses : Analyse, notes coach, et PDF, toutes accessibles depuis Bilan. L'audit du code (`app.js`) montre que ces trois chantiers n'ont **pas le même coût** :
- `autoAnalysis()` (~2540-2632, ~90 lignes) et `generateExportText()` (~2634-2672) ne lisent que `S.events`/`S.home`/`S.away` via des helpers courts (`teamScore`, `teamStat`, `teamPoss`, `periodScore`) — un pattern de généralisation existe déjà dans le projet (`matchStats(m)`, ~3109-3133) et s'applique directement ici.
- `generatePDF()` (~4025-4429, **~400 lignes**) fait la même chose mais y ajoute du dessin `jsPDF` complet (terrain, zones de but, timeline GB, 3 pages) entièrement câblé sur `S`. La généraliser proprement — ou en écrire un jumeau scoped-match — est un chantier à part entière, d'une ampleur comparable (voire supérieure) à tout le reste de cette version réuni.

Décision de ce PRD : **cette version livre Analyse + Notes coach en entier et en sécurité (aucune écriture possible sur le match en cours), et traite le PDF archivé comme un chantier séparé**, avec un raccourci pragmatique à coût quasi nul en attendant (cf. Should Have). Romain avait dit "ok" à l'entre-deux (Analyse/PDF dans Stats + aussi dans Bilan) sans connaître cette différence d'ampleur révélée par le Brief — ce découpage lui est donc présenté explicitement, pas imposé silencieusement.

Concernant les 4 critères de succès du Brief : ce PRD ferme intégralement les critères 1 et 2 pour **Analyse et Notes**, ferme intégralement le critère 3 (non-régression), et ferme **partiellement** le critère 1/4 pour **PDF** (raccourci existant réutilisé, pas de nouveau chemin non-destructif cette version — cf. Nice to Have #N1 pour la fermeture complète).

## Décisions actées sur les questions ouvertes du Brief

Romain n'étant pas disponible pour trancher en direct, les questions ouvertes du Brief sont tranchées ci-dessous en gardant le scope le plus resserré possible. Les décisions marquées *(à confirmer par Romain)* ne bloquent pas Designer → Visual Crafter → Architect → Risk Analyst → Scrum Master, mais devront être validées en conditions réelles.

1. **Les notes coach affichées dans le nouvel onglet Analyse de Bilan sont éditables — ce n'est pas qu'une lecture.**
   Le Brief pose la question sans trancher. Décision : oui, éditables — c'est explicitement ce que demande le critère de succès n°2 du Brief ("Les notes de coach lues/éditées depuis Bilan"). L'édition se fait sur une copie du match sélectionné, jamais sur `S.coachNotes`, jamais sur `S` du tout.

2. **Le bouton "💾 Sauvegarder notes" devient un vrai déclencheur d'écriture — mais seulement dans le contexte Bilan, pas dans Stats.**
   Aujourd'hui (Stats, match en cours), ce bouton n'affiche qu'un toast — la frappe écrit déjà en continu dans `S.coachNotes`, et la persistance réelle sur disque n'arrive que plus tard via `saveMatch()`. Pour un match déjà archivé consulté depuis Bilan, il n'existe aucun "plus tard" équivalent. Décision : dans Bilan uniquement, ce bouton déclenche un `dbSaveMatch(m)` immédiat sur le match sélectionné. Dans Stats, le comportement actuel (toast cosmétique) reste strictement inchangé — deux comportements différents pour le même libellé de bouton, dans deux écrans différents, documentés explicitement pour ne pas passer pour une incohérence ou un oubli.

3. **`generateExportText()` (bouton "📋 Copier le résumé d'analyse") est inclus dans le Must Have, au même titre que les insights.**
   Il fait partie du même onglet Analyse déjà existant dans Stats et son coût de généralisation est comparable à celui d'`autoAnalysis()` (texte seul, aucune dépendance `jsPDF`/dessin). L'exclure produirait un onglet Analyse de Bilan visiblement incomplet par rapport à son équivalent Stats, pour une économie de scope marginale.

4. **Généralisation littérale (paramètre partagé dans les helpers) vs jumeau scoped-match (pattern `matchStats(m)`) — arbitrage technique, pas une décision PM.**
   Comme pour le précédent de `matchStats(m)` (déjà dupliqué plutôt que branché sur `teamScore`/`teamStat`), ce choix est laissé à l'Architect pour `autoAnalysis()`/`generateExportText()`. Le PM ne fixe qu'une exigence fonctionnelle : quel que soit le mécanisme choisi, le calcul du match archivé doit être **prouvé indépendant** de `S` (testable avec un match en cours actif en parallèle affichant des chiffres différents).

5. **Le PDF complet pour un match archivé est repoussé hors de cette version (Nice to Have #N1), pas annulé.**
   Coût identifié : ~400 lignes, 6 helpers concernés (`teamScore`, `teamStat`, `teamPoss`, `periodScore`, `countType`, `gkStats`) plus la logique de dessin `jsPDF` (`drawCourt`, `drawGoalZone`, timeline GB, 3 pages) intégralement câblée sur `S`. Généraliser ou dupliquer ce volume est un chantier au moins aussi gros que tout le reste de ce PRD réuni, pour une valeur incrémentale réelle mais moins urgente que consulter/éditer une analyse et des notes (usage de debrief hebdomadaire probable, pas quotidien). Décision : hors scope explicite cette version, à cadrer dans un Brief/PRD dédié si Romain confirme le besoin après avoir testé cette version.

6. **En attendant, un raccourci pragmatique reste proposé dans Bilan pour le PDF (Should Have), pas un vide total.**
   Le flux "Charger ce match" (`data-load-match`, ~3901-3924) existe déjà, avec sa confirmation destructrice déjà en place ("Le match en cours sera remplacé"). Décision : proposer ce même flux comme raccourci explicite depuis Bilan, qui enchaîne automatiquement vers Stats → PDF après confirmation — zéro duplication de `generatePDF()`, coût quasi nul. Ce raccourci **ne satisfait pas** le critère de succès "sans jamais toucher ni risquer d'écraser le match en cours" pour le PDF — il doit être présenté à Romain comme un pis-aller assumé, explicitement distinct de la garantie de sécurité totale offerte pour Analyse/Notes, pour éviter toute confusion du type déjà documentée dans prd-v5 ("feuille" vs PDF).

7. **Synchronisation Supabase des notes éditées a posteriori sur un match `finished` — hors scope cette version, risque accepté.**
   Un match `finished` n'est plus poussé en continu vers Supabase (contrairement au match en cours via `upsertMatchSnapshot()`). Décision : l'édition de notes depuis Bilan reste strictement locale (IndexedDB, `dbSaveMatch()`) cette version — cohérent avec l'usage réel actuel (un seul utilisateur, Romain). Aucun mécanisme de push explicite n'est construit. Si Romain édite les notes d'un même vieux match depuis deux appareils différents, la dernière sauvegarde locale de chaque appareil peut diverger sans détection ni fusion — signalé au Risk Analyst, pas résolu ici *(à confirmer par Romain : fréquence réelle d'un tel usage multi-appareil sur un match déjà terminé — jugée rare aujourd'hui)*.

8. **Rattrapage des matchs sans `coachNotes`** : traité en `m.coachNotes||""`, comme déjà fait ailleurs dans le code (ex. ~3912) — pas de migration.

## Features

### Doit avoir (Must Have)

1. **Nouvel onglet "🧠 Analyse" dans la barre `S.bilanTab`** (aux côtés de 🔍 Match / 🏆 Saison, ~3526-3536), visible/actif uniquement quand un match est sélectionné (`S.bilanMatch` non nul) — cohérent avec le placeholder déjà en place dans `renderBilanMatch()` ("↑ Sélectionne un match pour le revoir") tant qu'aucun match n'est choisi.
2. **Insights auto-détectés scopés sur le match sélectionné** : une version du calcul d'`autoAnalysis()` (~2540-2632) produisant les mêmes types d'insights (résultat, efficacité, pertes de balle, séries de buts encaissés, analyse mi-temps, passes décisives, meilleure/pire période, top/flop joueur) mais calculée **exclusivement** à partir de `m.events`/`m.home`/`m.away` du match archivé — jamais de `S`. Mécanisme précis (paramètre partagé vs jumeau scoped-match) laissé à l'Architect (cf. Décision actée #4).
3. **Export texte scopé identique** : le bouton "📋 Copier le résumé d'analyse" (`generateExportText()`, ~2634-2672) produit, pour le match sélectionné dans Bilan, le même format de texte que dans Stats (score, insights, stats, top joueurs, notes coach) — reflétant `m`, jamais `S`.
4. **Notes coach lues et éditables depuis Bilan** : une textarea affiche `m.coachNotes||""` du match sélectionné à l'ouverture de l'onglet ; la frappe modifie une copie locale de ce match précis, jamais `S.coachNotes`.
5. **Persistance réelle des notes** : dans ce contexte Bilan, le bouton "💾 Sauvegarder notes" déclenche un vrai `dbSaveMatch(m)` (écriture IndexedDB immédiate, keyée sur `m.id`) — pas un toast cosmétique. Une confirmation visible (toast) s'affiche après écriture réussie.
6. **Reflet immédiat + survie au rechargement** : après sauvegarde, la note éditée reste visible si on change de match puis revient sur le même, sans re-sélection nécessaire dans la session ; et après un rechargement complet de la page + re-sélection du même match, la note éditée est toujours là (persistée en IndexedDB, indépendamment de Supabase).
7. **Isolation stricte du match en cours** : consulter/éditer Analyse ou Notes depuis Bilan ne lit ni n'écrit jamais `S` (état du match en cours) — vérifiable en ayant un match activement en cours de saisie en parallèle (potentiellement sur un autre appareil) avec des données différentes, sans que les deux vues n'interfèrent l'une avec l'autre.
8. **Mode lecteur respecté** : si `S.readOnly` est actif, l'édition des notes (textarea + bouton "Sauvegarder notes") dans Bilan est bloquée, cohérent avec la convention documentée dans `CLAUDE.md` pour tout nouveau point d'écriture — même si le match consulté est archivé et non le match en cours (le mode lecteur verrouille l'appareil, pas seulement la saisie live).
9. **Aucune régression sur Stats → Analyse pour le match en cours** : `autoAnalysis()`, `generateExportText()`, `renderAnalyse()`, la textarea liée à `S.coachNotes`, et le bouton "Sauvegarder notes" (qui reste un toast cosmétique dans ce contexte, cf. Décision actée #2) restent strictement identiques à aujourd'hui.

### Devrait avoir (Should Have)

10. **Raccourci PDF pragmatique depuis Bilan** (bouton dans un onglet "📄 PDF" minimal, ou intégré à l'onglet Analyse — détail laissé au Designer) : déclenche le flux déjà existant "Charger ce match" (`data-load-match`, avec sa confirmation destructrice déjà en place — "Le match en cours sera remplacé") puis navigue automatiquement vers Stats → PDF, prêt à générer. Zéro duplication de `generatePDF()`. Doit être présenté visuellement de façon à ne pas laisser croire qu'il s'agit d'une génération PDF sécurisée à froid — le risque d'écraser le match en cours (déjà accepté aujourd'hui pour "Charger", avec confirmation explicite) reste identique, contrairement à Analyse/Notes qui n'ont aucun risque de ce type.
11. **Validation réelle par Romain en conditions réelles** (consulter un vieux match, lire l'analyse, éditer une note, recharger la page, revérifier) avant de considérer le cycle Analyse/Notes définitivement clos — au-delà de la revue Designer/QA sur écran (critère de succès explicite du Brief).

### Pourrait avoir (Nice to Have — hors de cette version)

12. **Génération PDF complète pour un match archivé, sans passer par le chargement destructif** — nécessite de généraliser ou dupliquer `generatePDF()` (~400 lignes, `teamScore`/`teamStat`/`teamPoss`/`periodScore`/`countType`/`gkStats` + dessin `jsPDF` terrain/zone de but/timeline). Chantier séparé, à cadrer dans un Brief/PRD dédié (candidat naturel : la suite directe de ce cycle) si Romain confirme le besoin après avoir testé cette version et son raccourci (Should Have #10).
13. **Mécanisme de synchronisation Supabase des notes éditées a posteriori** sur un match `finished`, si l'usage réel de Romain révèle un vrai besoin multi-appareil sur l'historique (aujourd'hui jugé rare).
14. **Analyse ou PDF agrégés au niveau saison** (hors du périmètre du Brief, qui ne couvre que l'analyse/le PDF par match).
15. **Rattrapage/migration des matchs sans `coachNotes`** — pas justifié, le `||""` suffit.

## Critères d'acceptation

- Depuis Bilan, l'onglet "🧠 Analyse" n'est accessible/actif que lorsqu'un match est sélectionné dans le menu déroulant de l'historique ; sinon un message invite à en sélectionner un (cohérent avec le comportement déjà en place de `renderBilanMatch()`).
- Les insights affichés dans cet onglet pour un match sélectionné correspondent **exactement** à ce match (mêmes chiffres que si on les recalculait à la main sur ses événements) — jamais au match en cours, y compris quand un match est activement en cours de saisie en parallèle (potentiellement sur un autre appareil) avec des données différentes.
- Le bouton "📋 Copier le résumé d'analyse" dans Bilan produit un texte reflétant le match sélectionné (score, insights, joueurs, notes), pas le match en cours.
- La textarea notes coach de Bilan affiche `m.coachNotes||""` du match sélectionné dès l'ouverture de l'onglet.
- Changer de match dans le sélecteur d'historique affiche immédiatement les notes propres à ce nouveau match — jamais celles du match précédemment consulté, ni celles du match en cours.
- Éditer la note et cliquer "💾 Sauvegarder notes" déclenche une écriture réelle : après un rechargement complet de la page puis re-sélection du même match, la note éditée est toujours présente.
- Pendant toute consultation/édition dans Bilan, `S.coachNotes` et l'onglet Stats → Analyse du match en cours restent strictement inchangés (testable avec une saisie active en parallèle).
- En mode lecteur (`S.readOnly` actif), la textarea de notes dans Bilan ne peut pas être éditée ni sauvegardée.
- Aucune régression sur Stats → Analyse pour le match en cours : insights, export texte, notes, et le bouton "Sauvegarder notes" (toast cosmétique) se comportent exactement comme avant ce cycle.
- Aucune régression sur Stats → PDF pour le match en cours : `generatePDF()` n'est ni modifiée ni impactée par ce cycle.
- (Should Have) Le raccourci PDF depuis Bilan charge effectivement le match sélectionné (avec la confirmation destructrice déjà existante) puis atterrit sur Stats → PDF prêt à générer, sans erreur.
- Romain confirme, en conditions réelles, qu'il peut consulter et éditer l'analyse/les notes d'un match passé sans avoir eu besoin de le charger comme match en cours — et qu'il comprend explicitement que le PDF, lui, nécessite encore ce chargement pour cette version.

## Hors scope

- Génération PDF complète pour un match archivé sans chargement destructif (voir Nice to Have #12 — chantier séparé, disproportionné pour cette version).
- Toute refonte visuelle des onglets Stats existants, au-delà du strict nécessaire pour partager la logique de calcul avec Bilan.
- Le comparatif déjà affiché dans `renderBilanMatch()` (buts, tirs, PD, joueurs, fil du match) — déjà fonctionnel, non concerné.
- Analyse automatique ou PDF au niveau saison (agrégé sur plusieurs matchs).
- Rattrapage des matchs sauvegardés sans champ `coachNotes` (traité en `||""`, pas de migration).
- Toute garantie de synchronisation multi-appareil des notes éditées sur un match déjà `finished` (risque accepté, cf. Décision actée #7 et Risques).
- Toute modification du comportement actuel du bouton "Sauvegarder notes" dans le contexte Stats (reste un toast cosmétique, cf. Décision actée #2).
- Toute détection/fusion automatique de conflit si les notes d'un même match archivé sont éditées depuis deux appareils différents.

## Dépendances

- Pattern de référence déjà existant à réutiliser : `matchStats(m)` (~3109-3133) — jumeau scoped-match qui recalcule ses propres agrégats à partir de `m.events` plutôt que de rebrancher `teamScore`/`teamStat` sur `S`.
- Code à généraliser/dupliquer : `autoAnalysis()` (~2540-2632), `generateExportText()` (~2634-2672), `renderAnalyse()` (~2674-2700).
- Code à étendre : `renderBilan()`/barre `S.bilanTab` (~3526-3536), `renderBilanMatch()` (~3135-3291), sélecteur déjà existant `S.bilanMatch`/`S.bilanMatchId` (~3665-3671).
- Persistance : `dbSaveMatch()` (~448-456, `put()` IndexedDB keyé sur `match.id`) — mécanisme déjà existant, réutilisé tel quel, aucune évolution de schéma nécessaire.
- Comportement existant réutilisé pour le Should Have #10 : flux "Charger ce match" (`data-load-match`, ~3901-3924) avec sa confirmation destructrice déjà en place.
- Convention transverse à respecter : garde `if(S.readOnly) return;` sur tout nouveau point d'écriture (documentée dans `CLAUDE.md`).
- Aucune dépendance sur la migration d'hébergement Netlify → GitHub Pages en cours (chantiers indépendants).
- Aucune évolution structurelle de données ni de schéma Supabase requise (`coachNotes` existe déjà dans l'objet match archivé depuis `saveMatch()`) — s'inscrit dans l'architecture existante (état `S`, rendu `R()`, vanilla JS, IndexedDB).
- Le Nice to Have #12 (PDF complet archivé), s'il est ouvert en cycle séparé, dépendra en plus de `generatePDF()` (~4025-4429), `gkStats()`/`gkStatsCombined()` (~1016-1053) et de la logique de dessin `jsPDF` (`drawCourt`, `drawGoalZone`).

## Risques (détaillés par le Risk Analyst)

- **Confusion silencieuse S vs m** (risque central identifié par le Brief) : si l'implémentation choisie oublie de lire `m.events` au lieu de `S.events` dans un recoin d'`autoAnalysis()` ou de `generateExportText()`, l'onglet Analyse de Bilan afficherait silencieusement des données du match en cours en les faisant passer pour celles du match archivé — à vérifier explicitement par QA avec un match en cours ET un match archivé affichant des chiffres différents en simultané.
- **Perte d'édition silencieuse** : `dbSaveMatch(m)` n'a pas de mécanisme de retry/outbox contrairement à la synchronisation Supabase du match en cours — un échec d'écriture IndexedDB (quota, navigateur) pourrait ne pas être signalé clairement à Romain.
- **Divergence multi-appareil non détectée** : notes éditées sur un même vieux match depuis deux appareils différents peuvent diverger silencieusement (pas de sync Supabase pour les matchs `finished`, cf. Décision actée #7) — risque accepté mais à surveiller si l'usage réel s'avère plus multi-appareil que prévu.
- **Mode lecteur oublié** sur ce nouveau point d'écriture (textarea + bouton "Sauvegarder notes" de Bilan) — un oubli exposerait une écriture locale non désirée en mode lecture seule, à l'encontre de la convention documentée.
- **Attente de Romain déçue sur le PDF** si le raccourci (Should Have #10) est perçu comme "le vrai PDF Bilan" plutôt que comme le pis-aller assumé qu'il est réellement — à clarifier explicitement dès la présentation de cette version, pas après coup (risque de confusion du même type que celui documenté dans prd-v5 autour de "feuille"/PDF).
- **Sous-estimation future du chantier PDF complet (#12)** si un futur cycle le reprend sans tenir compte de son ampleur réelle (~400 lignes, 6 helpers, dessin `jsPDF` complet) — documenté ici précisément pour éviter ce piège lors du cadrage du prochain Brief/PRD.
- **Rendu du nouvel onglet trop proche visuellement de Stats → Analyse au point de faire croire à Romain qu'il consulte le match en cours** alors qu'il est dans Bilan — le Designer doit garantir un signal visuel clair rattachant l'onglet au match sélectionné (ex. rappel du nom/score du match dans l'en-tête de l'onglet), cohérent avec le "pire résultat si mal fait" identifié par le Brief.
