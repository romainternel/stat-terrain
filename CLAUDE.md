# FENIX STATS - Contexte Projet

## Identité
Application de statistiques en direct pour le handball, développée pour le **Centre de Formation du FENIX Toulouse** (Starligue). Utilisée sur **iPad en bord de terrain** pendant les matchs de Nationale 1.

Responsable : Romain, responsable du centre de formation (CF).

## Architecture
- **4 fichiers séparés** — index.html (shell), style.css, app.js, config.js (identifiants Supabase, isolé pour permettre un clonage futur par un autre coach)
- **Vanilla JS** — pas de framework (React, Vue, etc.)
- **IndexedDB** pour le stockage local des matchs ET la file d'attente de synchronisation (outbox, voir section Stockage des données)
- **PWA** avec `sw.js` (service worker v109) et `manifest.json` pour le mode hors-ligne
- **Hébergé sur GitHub Pages** : romainternel.github.io/stat-terrain/ — dépôt `romainternel/stat-terrain` (renommé depuis `appli-terrain`), **public** (nécessaire pour GitHub Pages gratuit)
  - Migration depuis Netlify validée par Romain sur un vrai match (2026-08-20) — Netlify (fenix-statscf.netlify.app) à supprimer côté tableau de bord Netlify ; action manuelle hors de portée de ce dépôt, aucun fichier de config Netlify local à nettoyer (l'intégration se faisait uniquement via le dashboard Netlify, jamais un `netlify.toml`)
- **jsPDF** et **supabase-js@2** (build UMD, jsdelivr) chargés via CDN, sans étape de build

## Fichiers
```
fenix/
├── index.html      ← shell HTML (~20 lignes)
├── style.css       ← tout le CSS (~895 lignes)
├── app.js          ← toute la logique JS (~5790 lignes)
├── config.js       ← identifiants Supabase (SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_AUTH_EMAIL), jamais la clé service_role
├── sw.js           ← service worker (cache v109 : index + style + app + config + fenix-stat-badge.png, chemins relatifs "./" pour fonctionner en sous-dossier)
├── manifest.json   ← config PWA (start_url/scope en "./", relatifs)
└── .nojekyll       ← nécessaire pour GitHub Pages (sert les fichiers tels quels, sans traitement Jekyll)
```

## Design & UI
- **Dark theme** exclusivement — couleurs : `--bg: #0F1923`, `--card: rgba(255,255,255,.04)`, `--fenix-sky: #5FA8D3`
- Bleu ciel FENIX (`--fenix-sky`/`--green`, toutes deux `#5FA8D3` — il n'y a plus de vert distinct) = FENIX/buts, Rouge (`#E8465A`) = adversaire/arrêts, Orange (`#E88A4E`) = hors cadre, Jaune (`#F0C75E`) = PD/pénaltys/TM, Violet (`#9B7ECF`) = Jet franc
- **Optimisé iPad** : gros boutons, texte lisible, mode paysage et portrait
- Image du terrain et logo FENIX embarqués en base64 dans le HTML
- Police par défaut du système, pas de font externe

## Fonctionnalités principales

### Mode Simple / Mode Expert (STORY-23/24)
- Deux niveaux de saisie, contrôlés par `S.mode` ("simple" | "expert"), persisté par appareil (`localStorage hb2_mode`)
- **Détection à la 1ère utilisation** (aucun `hb2_mode` enregistré) : `window.innerWidth<700` → Simple, sinon Expert. Un choix explicite déjà enregistré n'est **jamais** réinitialisé
- **Toggle** visible à deux endroits : écran Équipes (bloc dédié) et panneau ⚙ Réglages du Match (markup différent aux deux endroits par contrainte d'espace, mais même logique de clic partagée : `setMode()`)
- **Bascule Expert → Simple en cours de match** (événements déjà saisis) : confirmation bloquante (`safeConfirm`) avant application, pour ne pas perdre la richesse de saisie du reste du match sans le vouloir
- **Mode Expert** : comportement décrit ci-dessous dans "Match (prise de stats en direct)" — inchangé, c'est le mode historique
- **Mode Simple** : écran Match remplacé par `renderMatchSimple()` — 5 boutons par équipe (BUT, ARRÊT, NON CADRÉ, PB, JET FRANC — les deux derniers ajoutés en STORY-52 sur retour de Romain) qui **auto-valident directement** via `recordEvent(type, team)` (sans terrain, sans zone, sans attribution joueur — `playerId`/`x`/`y`/`goalZone` restent `null`). Pas de PD, pas de PO/PEN détaillé. 2min/Carton Rouge/TM restent disponibles (ils vivent déjà dans `.ml-left`, partagé entre les deux modes). Badge "⚡ MODE SIMPLE ACTIF" visible en continu pendant la saisie
  - **Verrou de possession** (STORY-59) : seule l'équipe qui a `S.possession` peut enregistrer une action — les boutons de l'autre équipe sont grisés (`.simple-inactive`) et bloqués au clic (toast d'erreur, aucun événement créé). La possession bascule automatiquement après BUT/ARRÊT/NON CADRÉ/PB (STORY-52/M3), même règle qu'en Mode Expert
  - Un flash bref (`.simple-flash`, ~400ms) confirme chaque clic — Mode Simple n'a pas d'état "sélectionné" persistant comme `.act-h.selected` en Expert, ce flash est le seul retour visuel du clic (STORY-52/M2)
  - Les alertes TM conseillé/changez de GB (voir plus bas) se déclenchent aussi en Mode Simple depuis STORY-60 — n'étaient branchées qu'en Mode Expert avant, gap de parité corrigé
- **Comportement accepté** : sur un match à mode mixte (Simple puis Expert ou l'inverse), la table Stats "Joueurs" peut afficher une somme de buts par joueur inférieure au score total de l'équipe — les événements Simple ne s'attribuent à aucun joueur, par conception (pas de rattrapage a posteriori prévu)

### Lancement du match (STORY-52/53/54)
- Onglet Match sans match actif (`!S.currentMatchId && S.events.length===0`) → écran dédié (`renderMatchLaunch()`) : gros bouton "▶ Lancer le match" centré + noms des deux équipes, interface de saisie complète masquée tant qu'il n'est pas cliqué. Reste transparent pour un match chargé depuis l'historique ou repris sur un autre appareil (n'affiche jamais cet écran dans ces cas, `S.events` déjà non-vide ou `currentMatchId` déjà fixé)
- Clic → chrono démarré automatiquement, `S.period=1` fixé explicitement, bascule sur l'interface de saisie complète
- Bandeau non bloquant si GB ou effectif manquant (`launchWarnings()`), affiché sur l'écran de lancement et rappelable après coup pendant le match (pastille `[–]` à côté de "⚙ Réglages", `[✕]` pour fermer définitivement pour la session). Le rappel GB vérifie que le gardien assigné (`gkId`) est réellement sélectionné pour ce match, pas seulement qu'un `gkId` existe (STORY-60 — un roster par défaut peut préremplir un `gkId` non joueur)
- Rappel de mi-temps (30min de MT1 écoulées) : toast répété toutes les 2 min + bouton "MT" pulsant, indépendamment du mode

### Match (prise de stats en direct) — mode Expert
- **Scoreboard** avec timer, score, sélecteur de GB pour chaque équipe
- **Barre d'actions** : But, Tir arrêté, Tir non cadré, PB, PO, Jet franc (2min/Carton R vivent dans le bloc sanctions `.ml-left`, TM dans le timer — pas dans cette barre ; l'ancien type `ACTIONS.PEN` autonome existe encore dans le code mais n'est relié à aucun bouton, `S.penResultSelect` explicitement marqué `// kept for compat (unused)`)
- **Workflow d'action** : sélectionne action → clique joueur sur le terrain (équipe déterminée par le toggle POSSESSION) → terrain impact (localisation) + zone de but (9 zones) → auto-validation. Pas d'étape "clique équipe" séparée.
- **PB, Jet franc** : terrain d'impact requis comme pour un tir (validation dès le tap), mais jamais de zone de but — `x`/`y` désormais réellement capturés (STORY-58, correctif d'un bug de longue date : `needsMap:true` était déjà déclaré pour ces deux actions mais 4 endroits du code ne vérifiaient que `isGoal/isSave/isOff`, donc validation instantanée au clic joueur, jamais de vraies coordonnées enregistrées avant ce correctif).
- **PO** reste seul à s'auto-valider dès le clic joueur, sans terrain (il ouvre directement le mode pénalty décrit ci-dessous).
- **PO (PEN_OBT) active un mode pénalty** (`S.penMode`, STORY-32/33/34) : encart dédié directement sur le terrain (pas de popup) — tireur pré-désigné (réassignable en un tap), 3 boutons BUT/ARRÊT/HORS CADRE. Si le suivi GB (`S.trackGK`) est actif et l'issue est BUT ou ARRÊT, une étape de zone d'impact (9 zones) s'affiche avant validation — capturée réellement pour la première fois (jamais enregistrée avant STORY-32). Barre d'actions et sélecteur d'équipe verrouillés tant que l'encart est ouvert.
- **PD (passe décisive)** : bouton dédié **"🎯 PD"** qui apparaît après un but, ouvre un sélecteur de joueur sur le terrain pour assigner l'assist rétroactivement au dernier événement — ce n'est pas un 2e clic pendant la saisie du tir (un 2e clic joueur à ce moment-là remplace le tireur).
- **Auto-validation** : quand on sélectionne une nouvelle action, l'action en cours est validée automatiquement
- **Bouton ✓ VALIDER** : gros bouton vert à droite du terrain d'impact
- **Feed d'événements** : overlay glissant, cliquable pour éditer
- **TM (temps mort)** : bouton dans le timer, compteur par mi-temps (max 2/mi-temps, 3 total)

### Alertes automatiques (FENIX uniquement)
Actives en Mode Simple **et** Expert depuis STORY-60 (`recordEvent()`/`validateAndClose()`/`validateActionPanel()`/`recordTM()` appellent toutes désormais `checkGkConsecutiveAlert()`/`checkTimeoutAdvisor()` — n'étaient branchées qu'en Mode Expert avant, jamais en Mode Simple).
- **3 buts encaissés consécutifs** → "TM conseillé" (si TM disponible)
- **5+ buts consécutifs** → "Changez de GB !"
- **3 attaques sans marquer + 2+ buts adverses** → "TM conseillé"
- **3 PB d'affilée** → "TM conseillé"
- Les alertes se réinitialisent au changement de mi-temps
- Anti-spam : 30s minimum entre les suggestions TM

### Timeline GB
- Overlay plein écran accessible via 📊 à côté du GB
- Barres bleues (arrêts) vers le haut, rouges (buts encaissés) vers le bas
- Points noirs = changements de GB
- Filtres MT1/MT2

### Stats (onglets)
- **📊 Comparaison** : barres comparatives, légende affichée des deux côtés de chaque ligne — `Buts/Tirs, Pen, Efficacité, Arrêts GB, Non cadrés, PB, Jet franc, 2 min, Carton R, Possessions` dans cet ordre (PD/PO volontairement retirés de ce tableau) + évolution du score avec TM. Même tableau, homogénéisé avec Bilan → Match.
- **🧤 Gardiens** : stats GB, zones d'impact 3×3, terrain avec localisation des tirs, filtres par GB et type
- **👤 Joueurs** : tableau avec buts, PD, tirs, efficacité, PB, 2min
- **🧠 Analyse** : auto-détection de patterns + notes coach + export texte pour Claude
- **📄 PDF** : rapport multi-pages (comparatif+joueurs, cartes de tirs des joueurs FENIX ayant tiré [page conditionnelle], gardiens) — pagination "Page X/N" calculée dynamiquement. Page joueurs : tout l'effectif FENIX sélectionné, pas seulement ceux ayant un événement individuel.
- **Bouton ⛶ plein écran** sur chaque carte de stats

### Bilan
- **Match** : résumé comparatif d'un match archivé — même tableau homogénéisé que Stats → Comparaison
- **Analyse** (STORY-35) : auto-analyse + notes coach éditables et réellement persistées pour n'importe quel match archivé, isolé du match en cours
- **PDF** (STORY-36) : raccourci pour charger un match archivé et générer directement son PDF, protégé par un correctif de sécurité P0 (coupe la souscription Realtime avant tout reset)
- **Saison** : agrégation de tous les matchs (victoires, nuls, défaites, stats moyennes, top joueurs, GB)

### Deux équipes distinctes -18 / CF (STORY-50/51)
- Écran de choix au premier lancement par appareil (`S.teamProfile`, `"cf"|"u18"`), mémorisé (`localStorage hb2_team_profile`), changeable depuis Réglages ou en cliquant le logo du header (`switchTeamProfile()`)
- Effectifs, historique de matchs et championnat **strictement isolés** entre les deux profils — clés localStorage distinctes par équipe, colonne `team_profile` côté Supabase (matchs d'avant cette story rattachés à "cf" par défaut)
- Décision actée par Romain (2026-08-20) sur le point de gouvernance signalé lors de STORY-50/51 (l'équipe -18 est composée de mineurs, le modèle un-seul-mot-de-passe-partagé expose leurs données à quiconque a ce mot de passe) : l'effectif -18 n'affichera que des **prénoms**, jamais de nom complet ; si l'appellation "-18" elle-même posait un problème RGPD, Romain accepte de la renommer — pas d'inquiétude sur le modèle de mot de passe partagé lui-même. Aucun roster par défaut n'existe encore pour "-18" à ce jour (voir Gestion d'équipes)

### Gestion d'équipes
- **Rosters par défaut** (STORY-55/56, réintroduits après leur suppression lors du passage du dépôt en public — cf. Décisions en attente) :
  - **FENIX CF** : 22 joueurs réels (`FENIX_CF_ROSTER`, format `Prénom.InitialeNom`, sans numéro) chargés automatiquement au premier lancement du profil "cf" sur un appareil (`defaultFenixCfTeam()`), jamais réappliqués après une première sauvegarde locale. Bouton manuel "⚡ FENIX CF" (onglet Équipes, STORY-61) pour recharger à la demande — filet de sécurité en cas de changement d'appareil où le chargement automatique n'aurait pas eu lieu
  - **Adversaire** : modèle générique 7 postes (`defaultAdversairePlayers()` — un joueur par poste, nom = code de poste comme "ALG"/"GB", volontairement pas des "?" à renommer : permet de lire le poste directement sur le terrain sans renommer personne) rechargé à **chaque** `newMatch()`. Bouton manuel "⚡ Modèle" (STORY-61) pour le recharger sans passer par un nouveau match
  - Profil "-18" : aucune liste fournie à ce jour, effectif vide par défaut (voir décision ci-dessus sur le prénom-seul pour quand elle sera fournie)
- Import/export CSV (format : `number,name,position`)
- Positions : ALG, ARG, DC, ARD, ALD, PVT, GB
- Photos joueurs (optionnel, base64)
- Sélection du roster pour chaque match

### Accès partagé & synchronisation multi-appareil (STORY-10 à 14)
- Écran d'accès à mot de passe unique (`S.authOk`) devant toute l'app — email fixe (`config.js`), un seul compte Supabase, pas d'auto-inscription
- **Fail-open volontaire** : si Supabase est indisponible/non configuré, `S.authOk` passe à `true` automatiquement — l'app reste utilisable en local
- Chaque événement + l'état complet du match sont synchronisés en continu vers Supabase (voir "Stockage des données"), réception en temps réel sur les autres appareils
- Un appareil peut reprendre un match en cours démarré par un autre appareil, avec reconstruction complète de l'état

### Mode lecteur (STORY-26)
- `S.readOnly`, persistant par appareil (`localStorage hb2_readonly`), bascule dans le panneau ⚙ Réglages du Match
- Verrouille toute écriture locale (terrain, TM, sanctions, chrono, mi-temps, gardien, undo/delete/edit, PD, sauvegarde/nouveau match, import CSV) sans jamais bloquer la réception distante (sync entrante Supabase continue de fonctionner)
- Hors scope volontaire : l'écran Équipes n'est pas verrouillé par ce mode
- Signalé par un bandeau visuel + désaturation des contrôles d'écriture (`.match-layout.is-readonly`, `.feed-panel.is-readonly`)

## Stockage des données

### Local (par appareil)
- **IndexedDB** (`fenix_stats`, `DB_VER=2`) : historique des matchs sauvegardés (store `matches`, fonctions `dbSaveMatch()`/`dbGetAll()`/`dbDelete()`) + file d'attente de synchronisation sortante (store `pendingSync`, voir ci-dessous)
- **localStorage** : effectif par équipe (`hb2_teams_cf`/`hb2_teams_u18` — `hb2_teams` legacy, migré une fois vers `hb2_teams_cf`), profil équipe actif (`hb2_team_profile`), championnat mémorisé par équipe (`hb2_championnats_cf`/`hb2_championnats_u18`), mode Simple/Expert (`hb2_mode`), mode lecteur (`hb2_readonly`), affichage points/zones (`hb2_shotview`), session Supabase (gérée automatiquement par `supabase-js`)

### Partagé (Supabase, STORY-10 à 14)
- Deux tables : `matches` (état complet du match — équipes, effectifs, gardiens, période, chrono, statut `in_progress`/`finished`, plus `season`/`journee`/`coach_notes`/`championnat`/`team_profile` ajoutées par `docs/supabase-migration-season-journee-notes.sql`, déjà exécuté) et `match_events` (un événement par ligne, colonnes snake_case miroir de la structure d'événement locale)
- **RLS activée** sur les deux tables, policy `authenticated` en lecture/écriture — inscription publique désactivée, un seul compte partagé
- **Realtime doit être activé séparément de RLS**, table par table (`alter publication supabase_realtime add table ...`, script `docs/supabase-realtime-setup.sql`) — sans cette étape, l'abonnement ne lève aucune erreur mais ne reçoit jamais rien (piège découvert pendant STORY-13)
- Écriture : `queueEventForSync()` pousse dans l'outbox local puis vide la file vers `match_events` (upsert, idempotent par `id` uuid) dès que réseau + session sont disponibles ; `upsertMatchSnapshot()` pousse l'état complet du match vers `matches` en continu
- Lecture : abonnement `postgres_changes` en temps réel, un canal sur `match_events`, un sur `matches` (UPDATE) — nécessaire séparément pour que le chrono/la mi-temps se synchronisent (fix hors-cycle, sans quoi seuls les événements se synchronisaient)
- Reprise : un appareil qui se connecte et trouve un match `in_progress` peut le reprendre entièrement (équipes, effectifs, gardiens, période, chrono recalculé, tous les événements) via `resumeMatch()`
- **Principe non négociable** : la saisie locale ne doit jamais dépendre de la disponibilité de Supabase — fail-open partout (auth, sync, mode lecteur)

## Types d'actions (objet ACTIONS)
```javascript
GOAL:     { needsMap:true,  isGoal:true }
SAVE:     { needsMap:true,  isSave:true }
OFF:      { needsMap:true,  isOff:true }
TURNOVER: { needsMap:true }              // PB
PEN_OBT:  { needsMap:true }              // PO
PEN_GOAL: { needsMap:true,  isGoal:true, isPen:true }
PEN_SAVE: { needsMap:true,  isSave:true, isPen:true }
PEN_OFF:  { needsMap:true,  isOff:true,  isPen:true }
PEN:      { needsMap:false }             // sélection résultat
FREEKICK: { needsMap:true }
TWO_MIN:  { needsMap:false, isExcl:true }
RED:      { needsMap:false, isCard:true }
TM:       { needsMap:false, isTM:true }
```

## Structure de données d'un événement
```javascript
{
  id, type, team, time, rawTime, period,
  x, y,                    // position sur le terrain (null si needsMap:false)
  gkId,                    // GB adverse au moment du tir
  playerId, playerName, playerNumber,
  assistId, assistName, assistNumber,  // PD
  goalZone                 // "HG","HC","HD","MG","MC","MD","BG","BC","BD"
}
```

## Stats GB (objet gkStats)
- `saves/total` = arrêts sur tirs cadrés (hors pénaltys)
- `penSaves/penTotal` = arrêts pénaltys (inclut PEN_GOAL + PEN_SAVE + PEN_OFF)
- Affichage : format `3/5` (arrêts/total) + `%`

## Conventions de code
- État global dans l'objet `S` (State)
- Rendu via fonction `R()` qui reconstruit le HTML et rebind les événements
- Pas de virtual DOM — innerHTML complet à chaque render
- Double-buffer anti-flicker pour le rendu
- `safeAlert()` / `safeConfirm()` pour compatibilité Claude HTML viewer
- `showToast()` pour les notifications (paramètre `isAlert` pour le style rouge)
- `showExportModal()` pour les exports (fallback clipboard)
- IndexedDB via fonctions `dbSaveMatch()`, `dbGetAll()`, `dbDelete()`
- Client Supabase nommé `sbClient` (pas `supabase`) pour ne pas entrer en conflit avec le namespace global de la librairie CDN
- Toute fonction/handler d'écriture (saisie, chrono, undo, réglages destructifs) commence par `if(S.readOnly) return;` — convention à respecter pour tout nouveau point d'écriture ajouté à l'avenir
- Pour tout total agrégé au niveau équipe (buts/tirs/efficacité), filtrer par les flags `isGoal`/`isSave`/`isOff` (inclut automatiquement les variantes pénalty), jamais par correspondance exacte de `type` via `teamStat(team,"GOAL")` — cette dernière approche a causé le bug STORY-37. `teamScore()`/`teamStat()` eux-mêmes restent inchangés (9 call sites partagés, dont l'écran Match en direct).

## Déploiement
1. Modifier `style.css` et/ou `app.js`
2. Incrémenter la version dans `sw.js` (ex: `fenix-stats-vXX`)
3. `git add` + `git commit` + `git push` sur `main` — GitHub Pages redéploie automatiquement depuis GitHub (plus de zip/drag & drop manuel)
4. Fermer Safari complètement sur iPad → réouvrir pour forcer le nouveau SW

**Piège rencontré (à garder en tête)** : le dépôt `stat-terrain` avait deux branches, `main` (tout le travail réel) et `master` (figée au tout premier commit, jamais mise à jour). GitHub Pages avait été activé sur `master` par défaut, servant une version obsolète de l'app. Corrigé : branche par défaut du dépôt + source GitHub Pages basculées sur `main`. Si un futur outil se base sur "la branche par défaut", vérifier que c'est bien `main`.

**Second piège rencontré** : activer RLS sur une table Supabase ne suffit pas à activer le Realtime dessus — ce sont deux réglages indépendants. Sans `alter publication supabase_realtime add table ...` exécuté séparément (script `docs/supabase-realtime-setup.sql`), un abonnement `postgres_changes` semble fonctionner (aucune erreur) mais ne reçoit jamais aucun événement. À vérifier explicitement après toute nouvelle table destinée à du temps réel.

## Règles importantes
- **TOUJOURS** vérifier le JS avec `new Function()` avant de livrer
- **Modifications CSS** → dans `style.css` uniquement
- **Modifications logique** → dans `app.js` uniquement
- **TOUJOURS** tester les modifications sur iPad Safari (scrolling, touch, 100dvh)
- Les noms de joueurs sur le terrain doivent être **gros** (22px numéro, 16px nom)
- PO seul s'auto-valide dès le clic joueur, sans terrain. PB et Jet franc demandent un tap sur le terrain (comme un tir) mais jamais de zone de but (STORY-58)
- La zone de but reste exclusive à But/Tir arrêté (et leurs variantes pénalty) — jamais pour Tir non cadré, PB ou Jet franc
- Les stats pen s'affichent en format `arrêts/total` (ex: `3/5`) pas en colonnes séparées

## État d'avancement

### Livré et déployé
- **STORY-18** — Navigation du header inaccessible sur iPhone (corrigé, scroll horizontal + logo condensé sous 700px)
- **STORY-02** — Layout Match iPhone portrait (corrigé, actions/score/terrain sans chevauchement)
- **STORY-03** — Layout Match iPhone paysage (corrigé, chrono/actions visibles, terrain agrandi)
- **STORY-09** — Audit du workflow de saisie par clics réels : aucune friction de code trouvée
- **STORY-04/05** — Polish visuel transverse (ombres/bordures cartes, états interactifs actifs/focus)
- **STORY-19** — Chevauchement des étiquettes joueurs sur le terrain à largeur réduite (corrigé)
- **STORY-20** — Terrain affiche vide tant qu'aucun joueur n'est explicitement sélectionné (corrigé, 3 fonctions distinctes)
- **STORY-21** — Numéro de maillot manquant affiché en tiret discret plutôt qu'un "?" (corrigé)
- **STORY-22** — Refonte du terrain en SVG natif, remplace l'ancienne image raster (corrigé, y compris géométrie réglementaire 6m/9m validée par Romain, et débordement desktop/tablette paysage corrigé)
- **STORY-23** — Fondation du mode Simple/Expert (état, toggle, détection iPhone par défaut)
- **STORY-24** — Écran Match en mode Simple (saisie rapide par équipe, sans terrain/zone)
- **STORY-25** — Polish visuel de la carte joueur sur l'écran Équipes (badge numéro, accent d'équipe cohérent des deux côtés, lisibilité de l'état non-sélectionné) — QA PASSED
- **STORY-10** — Fondation Supabase sécurisée (config.js, RLS activée + vérifiée sur le vrai projet, inscription publique désactivée) — QA PASSED
- **STORY-11** — Écran d'accès partagé (mot de passe unique) — QA PASSED, persistance de session confirmée par Romain sur son iPad/iPhone réel
- **STORY-12** — Synchronisation sortante (outbox IndexedDB, idempotente, jamais bloquante) — QA PASSED, envoi réel confirmé par Romain sur le vrai projet Supabase
- **STORY-13** — Synchronisation entrante temps réel (fusion sans doublon, ré-abonnement défensif) — QA PASSED, réception réelle à deux appareils physiques confirmée par Romain
- **STORY-14** — Reprise de match sur un autre appareil — QA PASSED, scénario réel à deux appareils confirmé par Romain (démarrage sur un appareil, reprise sur l'autre, chrono/mi-temps/événements synchronisés)
- **STORY-26** — Mode lecteur (verrouillage de saisie par appareil) — QA PASSED, non-régression complète vérifiée par le Regression Guardian (46/46, v70), confirmé par Romain en conditions réelles à deux appareils
- **STORY-15** — Indicateur discret de statut de synchronisation (✓ sync / ↻ envoi… / ⚠ hors-ligne) dans le bandeau haut de l'écran Match, absorbe/remplace définitivement STORY-06 (bandeau d'export manuel, superseded)
- **STORY-16** — Audit de clarté d'interface pour un aidant occasionnel : critères déjà satisfaits par le code existant (icône+label toujours ensemble sur les boutons d'action, bouton "↩ Annuler" aussi visible que les actions principales) — aucun changement de code nécessaire, confirmé par test réel CDP. Le Mode Simple (STORY-23/24) répond en pratique mieux encore au besoin initial de cette story.
- **STORY-17** — Documentation de clonage pour un autre coach (voir section "Cloner ce projet" ci-dessous)
- **STORY-27** — Suppression réelle d'un match sur Supabase (`matches` + `match_events`) quand il est supprimé de l'historique local — QA PASSED, Security Auditor feu vert, Regression Guardian RAS (36/36). Limite acceptée : ne s'applique qu'aux matchs sauvegardés après cette story (ceux d'avant n'ont pas l'identifiant Supabase nécessaire pour être nettoyés a posteriori)
- **STORY-28** — Abandonner un match "reprenable" indésirable (bouton 🗑, marque `finished` côté Supabase)
- **STORY-29** — Audit de lisibilité (Designer) : panneau Réglages réorganisé en 3 groupes, scroll de la barre d'actions plus visible sur iPhone
- **STORY-30** — Fusion carte Gardien (chiffres + terrain) en une "feuille" par équipe — QA PASSED
- **STORY-31** — Hors-cycle : plus de zone de but demandée pour un tir non cadré ; légende ajoutée sur la heatmap gardien
- **STORY-32/33/34** — Refonte pénalty en encart (voir Match ci-dessus) + gardes de robustesse + protection heatmap Gardiens — Code Review (1 rejet puis approuvé), QA PASSED AVEC RÉSERVES, Regression Guardian RAS (v79)
- **STORY-35/36** — Analyse/notes coach + raccourci PDF depuis Bilan (voir Bilan ci-dessus) + correctif sécurité P0 — Security Auditor convoqué (rien de critique), QA PASSED AVEC RÉSERVES, Regression Guardian RAS (v79)
- **STORY-37** — Efficacité de tir pouvant dépasser 100% sur pénalty (trouvé par QA pendant 32-36). Corrigé hors cycle formel (demande directe de Romain), 4 endroits alignés sur le calcul par flags — vérifié par test direct (CDP), pas de rapport QA/Regression Guardian dédié
- **Corrections hors-cycle (session du 11-12/08)** : terrain PDF corrigé (échelle, orientation, géométrie handball réelle, palette) ; marqueurs de tir réduits ; tableau Comparatif homogénéisé Stats/Bilan ; chevauchement nom équipe/bouton plein écran corrigé ; PDF page Joueurs étendue à tout l'effectif + nouvelle page "Cartes de tirs" par joueur
- **Point d'attention (non résolu)** : `renderMiniCompare()` et `renderGkBar()` se sont révélés être du code mort (définis, jamais appelés) — ni supprimés ni réactivés, à vérifier avant de supposer qu'ils s'affichent quelque part
- Corrections hors-cycle : validation d'ajout de joueur adverse assouplie (nom OU numéro suffit, plus seulement numéro) ; import CSV ignorant désormais la ligne d'en-tête (évitait un joueur fantôme "Nom"/DC au ré-import) ; synchronisation temps réel du chrono/mi-temps (nécessitait un abonnement realtime séparé sur la table `matches`, en plus de celui sur `match_events`)
- **STORY-38 à STORY-47** — Refonte terrain SVG multi-postes (spread grille pour 3/4 pivots), pagination PDF robuste (Évolution du score sur sa propre page, Top 3 ASCII, cartes tir joueur adversaire), zones d'origine du tir (grille 7 zones, inspirée d'un PDF concurrent partagé par Romain), split MT1/MT2 sur le tableau Joueurs du PDF, fondation "zones sur le terrain" (bascule points/zones, 8 zones + marqueur 7m, partagée Joueurs/Gardiens/Comparaison), détail joueur converti en modale compacte (au lieu d'un overlay plein écran)
- **STORY-48** — Rapatriement automatique de l'historique de matchs archivés entre appareils (un match sauvegardé sur un appareil devient visible sur les autres, dédupliqué par id Supabase)
- **STORY-50/51** — Deux équipes distinctes -18/CF (voir section dédiée plus haut) — écran de choix mémorisé par appareil, effectifs/historique/championnat isolés ; 3 fuites de filtrage par équipe trouvées et corrigées en Code Review (export/import CSV "Tout", suppression de match — la plus sérieuse aurait pu exposer les données -18 dans un export déclenché depuis le profil CF)
- **STORY-52 à STORY-54** — Retours du premier match réel testé par Romain en conditions live : chrono auto-démarré au lancement, highlight de sélection d'action (déjà fonctionnel en Mode Expert, diagnostic initial du brief corrigé avant tout code), possession auto-switch étendue à Mode Simple, rappel de mi-temps (toast + bouton pulsant), écran de lancement dédié sur l'onglet Match (remplace le petit bouton d'Équipes, gère aussi le cas d'un match chargé/repris pour ne jamais bloquer ces flux)
- **STORY-55/56** — Effectifs par défaut : modèle 7 postes pour l'Adversaire (rechargé à chaque nouveau match), liste réelle des 22 joueurs FENIX CF (chargée une fois par appareil, encodage source cp1252 décodé explicitement pour les accents)
- **STORY-57** — Bug de scroll qui remontait en haut à chaque sélection de joueur en paysage tablette/desktop (`#app`, pas `window`, est le vrai conteneur de scroll dans ce mode ; le double-buffer de rendu ne restaurait jamais son `scrollTop`)
- **STORY-58** — PB et Jet franc enfin taguables sur le terrain en Mode Expert (bug de longue date : jamais atteint l'étape terrain malgré `needsMap:true`, jamais de vraies coordonnées enregistrées) + surbrillance de l'équipe en possession renforcée (bordure/fond/glow)
- **STORY-59** — Verrou de possession en Mode Simple : impossible d'enregistrer une action pour l'équipe qui n'a pas la balle (bouton grisé + message d'erreur, aucun enregistrement si cliqué quand même)
- **STORY-60** — Rappel GB rendu fiable (vérifie que le gardien assigné est réellement sélectionné pour le match, pas juste qu'un `gkId` existe) + alertes TM conseillé/changez de GB étendues à Mode Simple (jamais branchées avant, même famille de gap que la possession auto-switch de STORY-52)
- **STORY-61** — Boutons manuels de rechargement des effectifs par défaut (FENIX CF et Adversaire, onglet Équipes) — filet de sécurité pour un changement d'appareil sans dépendre d'un diagnostic à distance

## Cloner ce projet pour un autre coach/équipe (STORY-17)

Décision actée : **un projet Supabase = un déploiement = un coach** (voir aussi la section Décisions en attente). Chaque clone a son propre repo GitHub et son propre projet Supabase, pour ne pas mélanger données/quotas entre équipes.

1. **Copier le repo** — fork ou clone GitHub de `stat-terrain` vers un nouveau dépôt.
2. **Créer un nouveau projet Supabase** dédié (compte gratuit suffit pour l'usage occasionnel prévu).
3. **Exécuter le script de création des tables/policies** : `docs/supabase-setup.sql` (tables `matches`/`match_events`, RLS activée), puis `docs/supabase-realtime-setup.sql` (active le Realtime — étape séparée de RLS, indispensable, cf. piège documenté plus haut). Checklist détaillée pas-à-pas : `docs/stories/STORY-10-checklist-manuelle.md`.
4. **Remplacer `config.js`** avec l'URL et la clé `anon`/`publishable` du nouveau projet (jamais la clé `service_role`).
5. **Créer le compte unique** (Authentication → Users → Add user) — un seul email/mot de passe partagé pour toute l'équipe, pas de compte par personne.
6. **Désactiver l'inscription publique** (Authentication → Providers/Settings → Email → "Enable email signups" désactivé) — non négociable, sans quoi n'importe qui trouvant l'URL pourrait créer un compte et accéder à toutes les données.
7. Vérifier que RLS est bien activée (badge vert) sur les deux tables avant tout usage réel avec de vraies données.

## Décisions en attente / Roadmap

- **Tout le backlog cadré lors du chantier Supabase (STORY-10 à 17) est livré et validé en conditions réelles** (2026-08-03) : synchronisation multi-appareil, mode lecteur, indicateur de sync, audit de clarté d'interface, doc de clonage.
- **Migration d'hébergement terminée** (validée par Romain sur un vrai match, 2026-08-20) : GitHub Pages est désormais l'unique hébergement. Netlify (fenix-statscf.netlify.app) à supprimer côté dashboard Netlify — action manuelle restant à faire par Romain, rien à nettoyer dans ce dépôt. Les captures d'écran de vérification technique (`docs/design/screenshots/`) restent retirées de l'état courant du dépôt (montraient l'ancien roster par défaut avec de vrais prénoms) — l'historique Git antérieur les contient encore, pas de réécriture d'historique effectuée. **Rosters réels réintroduits depuis** (STORY-55/56) avec un principe de minimisation assumé (prénoms/prénom+initiale, jamais de nom complet).
- **Efficacité de tir (STORY-37)** : décidé d'inclure les pénaltys dans le calcul partout, plutôt que de les exclure (deuxième option envisagée) — acté et implémenté.
- **Mode hors-ligne (PWA/service worker) — jamais re-testé en conditions réelles sans réseau depuis la v48** (actuellement v109, ~60 versions plus tard). Romain a validé les prérequis architecturaux le 2026-08-20 : sauvegarde locale d'un match (IndexedDB, `dbSaveMatch()`) et export ultérieur (`exportAllMatches()`, CSV) doivent tous deux rester possibles hors-ligne, et l'export ne doit jamais effacer les matchs locaux — les deux points sont déjà satisfaits par l'architecture existante (sauvegarde locale-first, export en lecture seule). Reste à faire : un vrai test iPad en coupant le réseau, jamais effectué à ce jour malgré le nombre de versions livrées depuis.
- **Gouvernance -18/mineurs (R0, `docs/risks/deux-equipes.md`) — tranchée par Romain** (2026-08-20) : effectif -18 en prénoms seuls (jamais de nom complet) ; si l'appellation "-18" elle-même posait un problème RGPD, il accepte de la renommer. Pas d'inquiétude exprimée sur le modèle de mot de passe unique partagé lui-même (déjà accepté depuis STORY-10).
