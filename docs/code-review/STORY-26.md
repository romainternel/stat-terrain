# Code Review — STORY-26 : Mode lecteur (verrouillage de la saisie)

## Suivi de correction (2e passe)

Correctifs apportés depuis le REJETÉ initial :
- `if(S.readOnly) return;` ajouté en tête de `selectAction` (l.573), `clickActionPlayer` (l.617), `clickGoalZone` (l.659), `clickCourtPosition` (l.671), `importMatchCSV` (l.1142), `saveMatch` (l.1297), `newMatch` (l.1325), et du handler `[data-load-match]` (l.3812).
- CSS ajouté : `.feed-panel.is-readonly .feed-item-edit{cursor:default;pointer-events:none;}` (style.css l.380-382), traitant le point Recommandé sur le feed.

### Vérification bloquant n°1 (terrain)
Confirmé : les 4 fonctions (`selectAction`, `clickActionPlayer`, `clickGoalZone`, `clickCourtPosition`) ont bien la garde en toute première ligne, avant tout accès à `S.actionPanel`/`S.selectedAction`. Le scénario décrit dans le rejet initial (mode lecteur activé pendant qu'une action est déjà sélectionnée, puis clic joueur → zone de but → position) est maintenant coupé net dès le premier clic après activation : plus aucune étape du workflow ne peut s'exécuter silencieusement. `selectAction` étant elle-même gardée, `S.selectedAction` ne peut plus non plus être positionné du tout pendant que le mode lecteur est actif — couvre aussi le cas clavier (focus + Entrée/Espace) que le seul `pointer-events:none` ne bloquait pas. Trou fonctionnel comblé.

Reste un écart mineur, déjà implicite dans le rejet initial mais pas repris comme Recommandé séparé : les éléments du terrain (`.cp-player`, `[data-gz]`, `[data-court-position]`, `#ap-court-svg`) ne sont toujours pas désaturés en CSS sous `.match-layout.is-readonly`, contrairement aux boutons d'action (`.act-h`) qui le sont. Fonctionnellement inoffensif désormais (les clics ne font plus rien), mais un aidant peut encore taper le terrain sans aucun signal visuel qu'il est verrouillé — pur écart de cohérence visuelle, pas de trou de données. Voir Recommandé ci-dessous.

### Vérification bloquant n°2 (Réglages)
Confirmé : `saveMatch`, `newMatch`, `importMatchCSV` et le handler `[data-load-match]` ont chacun la garde en première ligne, avant toute mutation d'état ou tout appel à `markMatchFinished`/`dbSaveMatch`/écriture Supabase. Vérification des points d'appel : ces 4 fonctions ne sont invoquées que depuis leurs bindings UI respectifs (`save-match-btn`, `new-btn`, `import-match`, `[data-load-match]`) — aucun appel interne/automatique (autosave, sync entrante) qui aurait pu être bloqué à tort par la garde. Aucune régression détectée.

### Vérification non-régression générale
- `S.readOnly` est initialisé au chargement du module (l.108, `try{ S.readOnly = localStorage.getItem(...)==="1"; }catch(e){}`) avant tout binding UI ou premier `R()` — pas de risque d'appel avec `S.readOnly` à `undefined` au démarrage.
- La réception temps réel (`mergeRemoteEvent`, `mergeRemoteMatchSnapshot`) n'a pas été touchée par ces ajouts — toujours non gardée, conforme au principe fail-open déjà validé en 1ère passe.
- Style des 8 gardes ajoutées cohérent avec celles déjà en place (early-return d'une ligne, en tête de fonction/handler).

## Périmètre revu (1ère passe, pour mémoire)
- `app.js` : `S.readOnly` dans `freshState()` + chargement `localStorage("hb2_readonly")`, `setReadOnly(val)`.
- Gardes `if(S.readOnly) return;` en tête de `startTimer`, `stopTimer`, `resetTimer`, `recordTM`, `clickTeam`, `clickActionMap`, `validateActionPanel`, `validateAndClose`, `recordEvent`, `undoLast`, `deleteEvent`, `editEvent`.
- Gardes inline dans `bind()` : `per-btn`, `[data-gk-sel]`, `pd-btn`, `[data-pick-pd]`, `pd-remove`, `[data-badge]`.
- Bouton toggle dans `settingsHtml` (panneau Réglages), bandeau `.readonly-banner`, classes `.is-readonly` sur `.match-layout`/`.feed-panel`.
- `style.css` : règles `opacity:.35;pointer-events:none;` sur une liste de sélecteurs sous `.match-layout.is-readonly` et `.feed-panel.is-readonly .feed-del-btn`.
- `sw.js` : bump v69 → v70.

## Conformité architecture / cohérence offline-first
- **Point vérifié et conforme** : `mergeRemoteEvent()` (l.323) et `mergeRemoteMatchSnapshot()` (l.343) ne contiennent aucune garde `S.readOnly` — la réception temps réel (sync entrante Supabase, STORY-13/14) continue de s'appliquer normalement sur un appareil verrouillé. C'est exactement le comportement attendu ("le mode lecteur ne bloque que l'écriture locale, jamais la réception") et le principe fail-open/offline-first documenté dans `CLAUDE.md` n'est pas remis en cause.
- **Point vérifié et conforme** : le panneau Réglages (`settings-panel`) et son bouton de bascule (`readonly-toggle-btn`) ne sont ciblés par aucune règle CSS `is-readonly`, et `setReadOnly()` est appelé sans condition sur `S.readOnly` — pas d'auto-verrouillage hors d'atteinte, comme demandé par la story.

## Bloquant (1ère passe — corrigés, voir Suivi de correction ci-dessus)

1. **La surface d'écriture principale — le clic joueur sur le terrain — n'est ni verrouillée en JS ni assombrie en CSS.** `clickActionPlayer()` (l.615, liée à `[data-ap-player]`/`.cp-player`), `clickGoalZone()` (l.656, `[data-gz]`) et `clickCourtPosition()` (l.667, `[data-court-position]`) ne contiennent **aucune** garde `if(S.readOnly) return;`, contrairement à `clickActionMap()` qui l'a. Aucune de ces classes/sélecteurs (`.cp-player`, `[data-gz]`, `[data-court-position]`, `#ap-court-svg`) n'apparaît non plus dans la liste `style.css` des éléments désaturés/désactivés par `.match-layout.is-readonly`.
   - Conséquence concrète : si `S.selectedAction` est déjà positionné au moment où le mode lecteur est activé (scénario réaliste : l'aidant avait commencé à sélectionner une action juste avant qu'on lui bascule le mode), il peut ensuite taper un joueur sur le terrain, taper une position d'impact, taper une zone de but — toute la séquence visuelle du workflow se déroule normalement, sans aucun signal de blocage — et ce n'est qu'à l'ultime étape (`validateAndClose()`/`validateActionPanel()`, elles bien gardées) que rien n'est enregistré, silencieusement.
   - Aucune perte de donnée n'en résulte (les points de commit réels sont gardés), mais c'est précisément le genre de confusion que la story demande d'éviter ("Un bandeau visuel + une désaturation des boutons d'écriture signalent clairement l'état verrouillé, pour éviter toute confusion"). Le terrain est le contrôle le plus manipulé pendant un match — le laisser visuellement et partiellement fonctionnellement actif est le pire endroit où avoir ce trou.
   - `selectAction()` (l.572, liée à `[data-act]`) n'a elle non plus aucune garde JS — elle est protégée uniquement par le CSS `pointer-events:none` sur `.act-h`. Ça fonctionne au clic souris/tactile normal, mais ce n'est pas cohérent avec le pattern « garde en tête de fonction » suivi partout ailleurs dans cette même story, et `pointer-events:none` n'empêche pas une activation clavier (focus + Entrée/Espace) sur un bouton déjà focus. À corriger par une garde explicite comme les autres.

2. **Plusieurs actions destructrices sur le match en cours, situées dans le panneau Réglages, restent totalement non gardées** — et le panneau Réglages est délibérément exempté de tout verrouillage CSS/JS :
   - `saveMatch()` (l.1291, bouton `save-match-btn`) — persiste le match en IndexedDB **et** appelle `markMatchFinished()` qui met à jour le statut Supabase en `finished`, ce qui ferait disparaître le match "en cours" pour tous les autres appareils qui suivent la reprise (STORY-14). Aucune garde `S.readOnly`.
   - `newMatch()` (l.1318, bouton `new-btn`) — réinitialise `S.events`, `S.time`, `S.period`, etc. localement et appelle aussi `markMatchFinished()`. Aucune garde `S.readOnly`.
   - `importMatchCSV()` (l.1137, bouton `import-match`) — écrase entièrement `S.home`/`S.away`/`S.events` à partir d'un fichier CSV choisi sur l'appareil. Aucune garde `S.readOnly`.
   - Ces trois fonctions sont exactement le type de "connerie" que Romain a demandé de pouvoir empêcher (citation de la story). Le raisonnement "le panneau Réglages reste cliquable pour ne jamais s'auto-verrouiller" est valable pour le **bouton de bascule** — il ne justifie pas d'exempter des actions destructives qui n'ont rien à voir avec la sortie du mode lecteur. Ces trois boutons doivent soit être gardés par `S.readOnly` côté JS (avec un petit message/toast explicatif si nécessaire, puisqu'ils resteront visuellement actifs dans un panneau non verrouillé), soit être eux-mêmes désaturés/désactivés spécifiquement.
   - Le handler `[data-load-match]` ("📂 Charger" — l.3803, dans l'onglet historique des matchs, hors écran Match) a le même défaut : il remplace `S.home`/`S.away`/`S.events` par un match sauvegardé, avec seulement une confirmation `safeConfirm` comme garde-fou, ce qui est justement le niveau de protection que ce chantier cherche à renforcer. Comme ce n'est pas dans l'écran Match, c'est un peu en marge du périmètre strict de la story, mais c'est bien une écriture sur "le match en cours" au sens large (le prompt lui-même le dit : "Le match en cours sera remplacé") — à couvrir par la même garde par cohérence, ou à documenter explicitement comme hors-scope si le choix est assumé.

## Recommandé

- ~~Les lignes de la file d'événements (`.feed-item-edit`, `data-edit-ev`)...~~ **Corrigé** dans cette passe (CSS `.feed-panel.is-readonly .feed-item-edit`).
- **Nouveau (issu de la vérification de cette passe)** : les éléments du terrain (`.cp-player`, `[data-gz]`, `[data-court-position]`, `#ap-court-svg`) ne sont toujours pas désaturés/assombris sous `.match-layout.is-readonly`, alors qu'ils sont désormais bien gardés en JS et donc inertes au clic. Un aidant peut taper le terrain en mode lecteur sans aucun signal visuel que ça ne fait rien — même remarque que celle déjà faite (et corrigée) pour `.feed-item-edit`. Non-bloquant (pas de trou fonctionnel ni de perte de données), mais mérite le même traitement CSS par cohérence.
- Le toggle de possession (`[data-poss]`, `.mlt-poss-btn`) n'est ni gardé ni désaturé. Il ne provoque pas directement une écriture d'événement, mais change l'état affiché du terrain pendant la saisie — à couvrir par cohérence puisqu'il fait partie du même flux de saisie que les points ci-dessus.
- Les notes d'implémentation de la story devraient être mises à jour pour lister explicitement les 8 gardes ajoutées dans cette passe (`selectAction`, `clickActionPlayer`, `clickGoalZone`, `clickCourtPosition`, `saveMatch`, `newMatch`, `importMatchCSV`, `[data-load-match]`), afin que la documentation reste une source fiable.

## Note
- `importAllMatches()` (import en masse de l'historique de matchs sauvegardés, hors match en cours) n'est pas gardée, mais elle écrit dans l'historique IndexedDB local, pas dans `S.events`/`S.home`/`S.away` du match en cours — cohérent avec le hors-scope volontaire de la story sur tout ce qui n'est pas la saisie live.
- Style des gardes ajoutées (`if(S.readOnly) return;` en une ligne, en tête de fonction) cohérent avec les conventions déjà en place dans le fichier (early-return, pas de framework).
- `sw.js` correctement incrémenté (v69 → v70), conforme à la procédure de déploiement documentée dans `CLAUDE.md`.
- Sécurité basique : RAS, pas de clé/secret en dur, pas de nouvelle requête Supabase non filtrée introduite par cette story.

## Verdict
**APPROUVÉ**

Les deux points Bloquants de la 1ère passe sont corrigés et vérifiés ligne par ligne :
1. le workflow de saisie terrain (`selectAction`, `clickActionPlayer`, `clickGoalZone`, `clickCourtPosition`) est maintenant coupé dès le premier geste en mode lecteur, plus seulement au commit final ;
2. les actions destructives du panneau Réglages (`saveMatch`, `newMatch`, `importMatchCSV`, `[data-load-match]`) sont désormais gardées, sans qu'aucun appel interne légitime n'ait été bloqué par erreur (vérifié : ces 4 fonctions ne sont appelées que depuis leurs bindings UI).

Aucune régression identifiée : `S.readOnly` est initialisé avant tout binding/rendu, le fail-open de la réception temps réel (`mergeRemoteEvent`/`mergeRemoteMatchSnapshot`) reste intact, et le style des gardes est cohérent avec l'existant.

Un point Recommandé (non-bloquant) subsiste : les éléments du terrain ne sont pas visuellement désaturés en mode lecteur (contrairement aux boutons d'action), ce qui peut laisser croire à un aidant que le terrain répond alors qu'il ne fait plus rien — cf. section Recommandé. Peut être traité dans une story de polish ultérieure sans bloquer le passage QA.
