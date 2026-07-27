# FENIX STATS - Contexte Projet

## Identité
Application de statistiques en direct pour le handball, développée pour le **Centre de Formation du FENIX Toulouse** (Starligue). Utilisée sur **iPad en bord de terrain** pendant les matchs de Nationale 1.

Responsable : Romain, responsable du centre de formation (CF).

## Architecture
- **3 fichiers séparés** — index.html (shell), style.css, app.js
- **Vanilla JS** — pas de framework (React, Vue, etc.)
- **IndexedDB** pour le stockage local des matchs
- **PWA** avec `sw.js` (service worker v51) et `manifest.json` pour le mode hors-ligne
- **Hébergé sur Netlify** : fenix-statscf.netlify.app
- **jsPDF** chargé via CDN pour l'export PDF

## Fichiers
```
fenix/
├── index.html      ← shell HTML (~20 lignes)
├── style.css       ← tout le CSS (~497 lignes)
├── app.js          ← toute la logique JS (~3848 lignes)
├── sw.js           ← service worker (cache v51 : index + style + app)
└── manifest.json   ← config PWA
```

## Design & UI
- **Dark theme** exclusivement — couleurs : `--bg: #0F1923`, `--card: rgba(255,255,255,.04)`, `--fenix-sky: #5FA8D3`
- Bleu ciel FENIX (`--fenix-sky`/`--green`, toutes deux `#5FA8D3` — il n'y a plus de vert distinct) = FENIX/buts, Rouge (`#E8465A`) = adversaire/arrêts, Orange (`#E88A4E`) = hors cadre, Jaune (`#F0C75E`) = PD/pénaltys/TM, Violet (`#9B7ECF`) = Jet franc
- **Optimisé iPad** : gros boutons, texte lisible, mode paysage et portrait
- Image du terrain et logo FENIX embarqués en base64 dans le HTML
- Police par défaut du système, pas de font externe

## Fonctionnalités principales

### Match (prise de stats en direct)
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
3. `git add` + `git commit` + `git push` — Netlify redéploie automatiquement depuis GitHub (plus de zip/drag & drop manuel)
4. Fermer Safari complètement sur iPad → réouvrir pour forcer le nouveau SW

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

### Connu, pas encore corrigé
- Chevauchement des étiquettes joueurs sur le terrain (`.cp-player`) à largeur réduite avec un effectif complet sélectionné — pas encore de story dédiée

## Décisions en attente / Roadmap

- **Chantier Supabase cadré, pas développé** : passage d'un stockage 100% local à un stockage partagé Supabase pour permettre la saisie par un aidant occasionnel sur un autre appareil. Voir `docs/architecture-supabase.md`, `docs/prd-v2-cloud-multiuser.md`, stories `STORY-10` à `STORY-17`. Point de vigilance sécurité déjà identifié : désactiver l'inscription publique + activer RLS avant toute donnée réelle (voir `docs/security/supabase-multiuser.md`).
- **Polish visuel transverse (STORY-04/05)** : étendre le traitement visuel déjà présent sur l'écran Match (ombres, états interactifs) aux écrans Stats/Bilan/Setup — pas encore développé.
