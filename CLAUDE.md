# FENIX STATS - Contexte Projet

## Identité
Application de statistiques en direct pour le handball, développée pour le **Centre de Formation du FENIX Toulouse** (Starligue). Utilisée sur **iPad en bord de terrain** pendant les matchs de Nationale 1.

Responsable : Romain, responsable du centre de formation (CF).

## Architecture
- **4 fichiers séparés** — index.html (shell), style.css, app.js, config.js (identifiants Supabase, isolé pour permettre un clonage futur par un autre coach)
- **Vanilla JS** — pas de framework (React, Vue, etc.)
- **IndexedDB** pour le stockage local des matchs ET la file d'attente de synchronisation (outbox, voir section Stockage des données)
- **PWA** avec `sw.js` (service worker v70) et `manifest.json` pour le mode hors-ligne
- **Hébergé en double, en transition** :
  - Netlify (historique) : fenix-statscf.netlify.app
  - GitHub Pages (nouveau) : romainternel.github.io/stat-terrain/ — dépôt `romainternel/stat-terrain` (renommé depuis `appli-terrain`), **public** (nécessaire pour GitHub Pages gratuit)
  - Garder les deux actifs jusqu'à validation de GitHub Pages sur un vrai match (cache hors-ligne notamment), puis supprimer Netlify
- **jsPDF** et **supabase-js@2** (build UMD, jsdelivr) chargés via CDN, sans étape de build

## Fichiers
```
fenix/
├── index.html      ← shell HTML (~20 lignes)
├── style.css       ← tout le CSS (~544 lignes)
├── app.js          ← toute la logique JS (~4341 lignes)
├── config.js       ← identifiants Supabase (SUPABASE_URL / SUPABASE_ANON_KEY / SUPABASE_AUTH_EMAIL), jamais la clé service_role
├── sw.js           ← service worker (cache v70 : index + style + app + config, chemins relatifs "./" pour fonctionner en sous-dossier)
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
- **Mode Simple** : écran Match remplacé par `renderMatchSimple()` — 3 boutons par équipe (BUT, ARRÊT, NON CADRÉ) qui **auto-valident directement** via la fonction `recordEvent(type, team)` déjà existante (sans terrain, sans zone, sans attribution joueur — `playerId`/`x`/`y`/`goalZone` restent `null`). Pas de PD, pas de PO/PEN détaillé. 2min/Carton Rouge/TM restent disponibles (ils vivent déjà dans `.ml-left`, partagé entre les deux modes). Badge "⚡ MODE SIMPLE ACTIF" visible en continu pendant la saisie
- **Comportement accepté** : sur un match à mode mixte (Simple puis Expert ou l'inverse), la table Stats "Joueurs" peut afficher une somme de buts par joueur inférieure au score total de l'équipe — les événements Simple ne s'attribuent à aucun joueur, par conception (pas de rattrapage a posteriori prévu)

### Match (prise de stats en direct) — mode Expert
- **Scoreboard** avec timer, score, sélecteur de GB pour chaque équipe
- **Barre d'actions** : But, Tir arrêté, Tir non cadré, PB, PO, PEN, Jet franc, 2min, Carton R, TM
- **Workflow d'action** : sélectionne action → clique joueur sur le terrain (équipe déterminée par le toggle POSSESSION) → terrain impact (localisation) + zone de but (9 zones) → auto-validation. Pas d'étape "clique équipe" séparée.
- **PB, PO, Jet franc** : auto-validation immédiate dès le clic sur le joueur — pas de terrain d'impact ni de zone de but pour ces 3 actions (`x`/`y` restent `null`).
- **PO (PEN_OBT) active un mode pénalty** (`S.penMode`) : le clic joueur suivant sur BUT/Tir arrêté/Tir non cadré se convertit automatiquement en PEN_GOAL/PEN_SAVE/PEN_OFF (position fixe, validation immédiate). Pas de popup à 3 choix.
- **PD (passe décisive)** : bouton dédié **"🎯 PD"** qui apparaît après un but, ouvre un sélecteur de joueur sur le terrain pour assigner l'assist rétroactivement au dernier événement — ce n'est pas un 2e clic pendant la saisie du tir (un 2e clic joueur à ce moment-là remplace le tireur).
- **Auto-validation** : quand on sélectionne une nouvelle action, l'action en cours est validée automatiquement
- **Bouton ✓ VALIDER** : gros bouton vert à droite du terrain d'impact
- **Feed d'événements** : overlay glissant, cliquable pour éditer
- **TM (temps mort)** : bouton dans le timer, compteur par mi-temps (max 2/mi-temps, 3 total)

### Alertes automatiques (FENIX uniquement)
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
- **📊 Comparaison** : barres comparatives côte à côte + évolution du score avec TM
- **🧤 Gardiens** : stats GB, zones d'impact 3×3, terrain avec localisation des tirs, filtres par GB et type
- **👤 Joueurs** : tableau avec buts, PD, tirs, efficacité, PB, 2min
- **🧠 Analyse** : auto-détection de patterns + notes coach + export texte pour Claude
- **📄 PDF** : génération de rapport 3 pages (comparatif, joueurs, gardiens)
- **Bouton ⛶ plein écran** sur chaque carte de stats

### Bilan
- **Match review** : résumé comparatif d'un match sauvegardé
- **Saison** : agrégation de tous les matchs (victoires, nuls, défaites, stats moyennes, top joueurs, GB)

### Gestion d'équipes
- **Aucun roster par défaut** : les deux équipes (FENIX et adversaire) démarrent avec un effectif vide, symétriquement — à charger via saisie manuelle ou import CSV. (Un roster FENIX était codé en dur avec de vrais prénoms de joueurs du Centre de Formation ; supprimé entièrement lors du passage du dépôt en public, pour ne pas exposer ces données.)
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
- **localStorage** : effectifs courants (`hb2_teams`), mode Simple/Expert (`hb2_mode`), mode lecteur (`hb2_readonly`), session Supabase (gérée automatiquement par `supabase-js`)

### Partagé (Supabase, STORY-10 à 14)
- Deux tables : `matches` (état complet du match — équipes, effectifs, gardiens, période, chrono, statut `in_progress`/`finished`) et `match_events` (un événement par ligne, colonnes snake_case miroir de la structure d'événement locale)
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

## Déploiement
1. Modifier `style.css` et/ou `app.js`
2. Incrémenter la version dans `sw.js` (ex: `fenix-stats-vXX`)
3. `git add` + `git commit` + `git push` sur `main` — Netlify **et** GitHub Pages redéploient automatiquement depuis GitHub (plus de zip/drag & drop manuel)
4. Fermer Safari complètement sur iPad → réouvrir pour forcer le nouveau SW

**Piège rencontré (à garder en tête)** : le dépôt `stat-terrain` avait deux branches, `main` (tout le travail réel) et `master` (figée au tout premier commit, jamais mise à jour). GitHub Pages avait été activé sur `master` par défaut, servant une version obsolète de l'app. Corrigé : branche par défaut du dépôt + source GitHub Pages basculées sur `main`. Si un futur outil se base sur "la branche par défaut", vérifier que c'est bien `main`.

**Second piège rencontré** : activer RLS sur une table Supabase ne suffit pas à activer le Realtime dessus — ce sont deux réglages indépendants. Sans `alter publication supabase_realtime add table ...` exécuté séparément (script `docs/supabase-realtime-setup.sql`), un abonnement `postgres_changes` semble fonctionner (aucune erreur) mais ne reçoit jamais aucun événement. À vérifier explicitement après toute nouvelle table destinée à du temps réel.

## Règles importantes
- **TOUJOURS** vérifier le JS avec `new Function()` avant de livrer
- **Modifications CSS** → dans `style.css` uniquement
- **Modifications logique** → dans `app.js` uniquement
- **TOUJOURS** tester les modifications sur iPad Safari (scrolling, touch, 100dvh)
- Les noms de joueurs sur le terrain doivent être **gros** (22px numéro, 16px nom)
- Ni le terrain d'impact ni la zone de but ne s'affichent pour PB, PO, Jet franc (auto-validation dès le clic joueur)
- Le terrain d'impact + la zone de but s'affichent uniquement pour But, Tir arrêté, Tir non cadré (et leurs variantes pénalty)
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
- Corrections hors-cycle : validation d'ajout de joueur adverse assouplie (nom OU numéro suffit, plus seulement numéro) ; import CSV ignorant désormais la ligne d'en-tête (évitait un joueur fantôme "Nom"/DC au ré-import) ; synchronisation temps réel du chrono/mi-temps (nécessitait un abonnement realtime séparé sur la table `matches`, en plus de celui sur `match_events`)

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

- **Tout le backlog cadré lors du chantier Supabase (STORY-10 à 17) est maintenant livré et validé en conditions réelles** (2026-08-03) : synchronisation multi-appareil, mode lecteur, indicateur de sync, audit de clarté d'interface, doc de clonage. Plus aucune story ouverte dans ce cycle.
- **Migration d'hébergement en cours** : dépôt GitHub renommé `stat-terrain` et rendu **public** pour permettre GitHub Pages (nécessaire côté offre gratuite). Netlify gardé en parallèle jusqu'à validation réelle. Les captures d'écran de vérification technique (`docs/design/screenshots/`) ont été retirées de l'état courant du dépôt (elles montraient l'ancien roster par défaut avec de vrais prénoms) — l'historique Git antérieur les contient encore, pas de réécriture d'historique effectuée.
