# FENIX STATS - Contexte Projet

## Identité
Application de statistiques en direct pour le handball, développée pour le **Centre de Formation du FENIX Toulouse** (Starligue). Utilisée sur **iPad en bord de terrain** pendant les matchs de Nationale 1.

Responsable : Romain, responsable du centre de formation (CF).

## Architecture
- **3 fichiers séparés** — index.html (shell), style.css, app.js
- **Vanilla JS** — pas de framework (React, Vue, etc.)
- **IndexedDB** pour le stockage local des matchs
- **PWA** avec `sw.js` (service worker v26) et `manifest.json` pour le mode hors-ligne
- **Hébergé sur Netlify** : fenix-statscf.netlify.app
- **jsPDF** chargé via CDN pour l'export PDF

## Fichiers
```
fenix/
├── index.html      ← shell HTML (~20 lignes)
├── style.css       ← tout le CSS (~271 lignes)
├── app.js          ← toute la logique JS (~3718 lignes)
├── sw.js           ← service worker (cache v26 : index + style + app)
└── manifest.json   ← config PWA
```

## Design & UI
- **Dark theme** exclusivement — couleurs : `--bg: #0D1B2A`, `--card: #1A2840`, `--fenix-sky: #7BA7C2`
- Vert (`#50C878`) = FENIX/buts, Rouge (`#E8465A`) = adversaire/arrêts, Orange = hors cadre, Jaune = PD/penaltys
- **Optimisé iPad** : gros boutons, texte lisible, mode paysage et portrait
- Image du terrain et logo FENIX embarqués en base64 dans le HTML
- Police par défaut du système, pas de font externe

## Fonctionnalités principales

### Match (prise de stats en direct)
- **Scoreboard** avec timer, score, sélecteur de GB pour chaque équipe
- **Barre d'actions** : But, Tir arrêté, Tir non cadré, PB, PO, PEN, Jet franc, 2min, Carton R, TM
- **Workflow d'action** : sélectionne action → clique équipe → terrain joueurs (tireur) → terrain impact (localisation) + zone de but (9 zones) → valider
- **PB, PO, Jet franc** : même workflow mais sans zone de but, auto-validation au clic terrain
- **PEN** : popup avec 3 choix (But / Arrêté / Hors cadre) puis terrain + zone impact
- **PD (passe décisive)** : 2e clic joueur après tireur = PD
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
- Import/export CSV (format : `number,name,position`)
- Positions : ALG, ARG, DC, ARD, ALD, PVT, GB
- Photos joueurs (optionnel, base64)
- Sélection du roster pour chaque match

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

## Déploiement
1. Modifier `style.css` et/ou `app.js`
2. Incrémenter la version dans `sw.js` (ex: `fenix-stats-vXX`)
3. Zip le dossier fenix/ avec les 5 fichiers (index.html, style.css, app.js, sw.js, manifest.json)
4. Glisser le dossier sur Netlify (app.netlify.com → Deploys → drag & drop)
5. Fermer Safari complètement sur iPad → réouvrir pour forcer le nouveau SW

## Règles importantes
- **TOUJOURS** vérifier le JS avec `new Function()` avant de livrer
- **Modifications CSS** → dans `style.css` uniquement
- **Modifications logique** → dans `app.js` uniquement
- **TOUJOURS** tester les modifications sur iPad Safari (scrolling, touch, 100dvh)
- Les noms de joueurs sur le terrain doivent être **gros** (22px numéro, 16px nom)
- La zone de but (goal zone grid) ne s'affiche PAS pour PB, PO, Jet franc
- Le terrain d'impact s'affiche pour TOUTES les actions sauf 2min, Carton R et TM
- Les stats pen s'affichent en format `arrêts/total` (ex: `3/5`) pas en colonnes séparées
