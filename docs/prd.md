# PRD — Corrections Audit Final + Mode Simple à équipe unique

## Objectif
Livrer les 3 corrections issues de l'Audit Final du 2026-08-20 et la simplification du Mode Simple demandée par Romain, sans régression sur le reste de l'application (Mode Expert, synchronisation Supabase, alertes existantes).

## Features

### F1 — Sauvegarde idempotente d'un match en cours (Must Have)
`saveMatch()` doit reconnaître qu'une sauvegarde locale existe déjà pour la session en cours et la **mettre à jour** plutôt que d'en créer une nouvelle. Un `id` de sauvegarde est mémorisé en mémoire (`S`) dès le premier `saveMatch()` réussi de la session, et réutilisé pour tout `saveMatch()` suivant tant que `S.events`/`S.currentMatchId` correspondent à la même session. Un nouveau match (`newMatch()`) ou le chargement d'un autre match archivé réinitialise ce marqueur.

### F2 — Historique des alertes critiques (Should Have)
Les alertes "TM conseillé" et "changez de GB" (issues de `checkTimeoutAdvisor()`/`checkGkConsecutiveAlert()`) restent, en plus du toast existant, consultables après leur disparition — au minimum les 3 dernières de la session en cours, horodatées, visibles depuis un point d'entrée déjà existant à l'écran Match (pas un nouvel onglet).

### F3 — Garde-fou volume d'événements sur l'Analyse automatique (Should Have)
`autoAnalysis()` n'affiche plus les insights à jugement qualitatif (PD "jeu trop individuel", pertes de balle, séries de buts encaissés, blocs d'efficacité par tranche de 10 min) tant que le volume d'événements du match n'atteint pas un seuil minimal représentatif. Les insights factuels non qualitatifs (résultat, score) restent toujours affichés, quel que soit le volume.

### F4 — Mode Simple : un seul jeu de boutons, équipe déterminée par la possession (Must Have)
`renderMatchSimple()` n'affiche plus qu'un seul bloc de boutons de résultat à la fois — celui de l'équipe actuellement en possession (`S.possession`). Le libellé d'équipe et la couleur d'accent (bleu FENIX / rouge Adversaire) basculent automatiquement au changement de possession (auto après une action, ou via le bouton "◉ POSSESSION" du scoreboard, inchangé). Le score et les autres contrôles du scoreboard (GB, TM, 2min, carton) restent affichés pour les deux équipes comme aujourd'hui — seule la zone des boutons de résultat est concernée.

## Priorités
- **Must Have** : F1, F4 — un bug de données confirmé et une demande explicite de Romain sur un flux qu'il utilise à chaque match.
- **Should Have** : F2, F3 — suggestions de l'audit, réelles mais non bloquantes ; à livrer dans le même cycle car petites et déjà cadrées, mais F1/F4 priment si le temps manque.

## Critères d'acceptation

**F1**
- [ ] Cliquer "💾 Sauvegarder" deux fois de suite sur la même session de match ne crée qu'une seule entrée dans `dbGetAll()`.
- [ ] La deuxième sauvegarde reflète l'état le plus récent (score, événements) sous le même `id`.
- [ ] `newMatch()` et le chargement d'un match archivé (`loadMatchAsCurrent()`) réinitialisent bien le marqueur — sauvegarder le match suivant crée une nouvelle entrée, pas une mise à jour de l'ancienne.
- [ ] Le comportement Supabase (`upsertMatchSnapshot`, `markMatchFinished`) n'est pas modifié.

**F2**
- [ ] Après la disparition du toast "changez de GB" ou "TM conseillé", l'alerte reste consultable (au moins les 3 dernières, horodatées) depuis l'écran Match.
- [ ] Aucune alerte supplémentaire n'est déclenchée par ce changement — même anti-spam, mêmes seuils qu'aujourd'hui (`CLAUDE.md`).
- [ ] Le bandeau de rappel GB existant (STORY-53) n'est pas dupliqué ni modifié par cette feature.

**F3**
- [ ] Sur un match de très peu d'événements (sous le seuil retenu), les insights qualitatifs (PD, pertes de balle, séries, blocs d'efficacité) n'apparaissent pas.
- [ ] Le résultat (victoire/défaite/nul) et le score restent toujours affichés, quel que soit le volume.
- [ ] Sur un match au volume normal (au-dessus du seuil), le comportement est strictement identique à aujourd'hui — aucune régression sur `docs/qa/` existants touchant l'Analyse.

**F4**
- [ ] En Mode Simple, un seul bloc de boutons de résultat est visible à l'écran, jamais deux.
- [ ] Le libellé affiché correspond toujours à `S.possession` ; changer la possession (auto après BUT/ARRÊT/NON CADRÉ/PB, ou manuellement) fait basculer le bloc instantanément.
- [ ] Cliquer un bouton enregistre toujours l'événement pour la bonne équipe (celle en possession au moment du clic) — vérifié notamment juste après un changement de possession.
- [ ] Le flash de confirmation (`S.simpleFlash`) fonctionne toujours après le clic.
- [ ] Aucune régression sur le score, les stats GB, les alertes (F2/existant), déjà branchées sur `recordEvent()`.
- [ ] Le scoreboard (score, GB, TM, 2min, carton, chrono) reste affiché pour les deux équipes, inchangé.

## Hors scope
- Refonte du Mode Expert.
- Nouveau composant de bascule de possession (le bouton existant suffit).
- Historique des alertes au-delà de la session en cours (pas de persistance long terme/multi-match pour F2).
- Personnalisation du seuil de F3 par l'utilisateur (seuil fixe dans le code, pas un réglage).

## Dépendances
- F1 s'appuie sur `S.currentMatchId`/`newMatch()`/`loadMatchAsCurrent()` déjà en place (STORY-14/36/54) — pas de nouvelle donnée serveur.
- F4 s'appuie sur `S.possession`/`S.simpleFlash` déjà en place (STORY-52/59) — pas de nouvelle donnée.
- F2 peut réutiliser le pattern de bandeau non-bloquant déjà utilisé par `launchWarnings()` (STORY-53) plutôt qu'un nouveau composant.
- Aucune dépendance entre F1/F2/F3/F4 — les 4 sont indépendantes et livrables dans n'importe quel ordre.

## Risques
- Voir `docs/risks/audit-corrections-et-mode-simple.md` (Risk Analyst) pour le détail — points d'attention en amont : robustesse de F1 face à un match repris sur un autre appareil (identifiant de sauvegarde local, pas partagé), et non-régression de F4 sur le verrou de possession (STORY-59) qui devient structurellement inutile en Mode Simple une fois une seule équipe affichée.
