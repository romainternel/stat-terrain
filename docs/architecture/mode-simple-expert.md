# Architecture — Mode Simple / Mode Expert

## Décision technique
Implémenter le mode Simple comme une **couche additive conditionnelle** sur l'état existant, pas comme un second écran dupliqué avec sa propre logique de données. Un seul flag d'état gouverne le rendu ; le modèle d'événement, l'agrégation des stats, le stockage IndexedDB/localStorage restent strictement identiques entre les deux modes.

### Nouvel état
```javascript
S.mode = 'expert' | 'simple'   // ajouté à freshState(), persisté séparément des matchs
```
- Stockage : nouvelle clé `localStorage.setItem('hb2_mode', S.mode)`, cohérente avec le préfixe déjà utilisé (`hb2_teams`, `hb2_matches`).
- Chargement au démarrage : si `hb2_mode` existe → on l'utilise tel quel (**un choix explicite ne doit jamais être réinitialisé**, exigence du PRD). Si absent (première utilisation sur cet appareil) → détection par largeur d'écran : `window.innerWidth < 700 ? 'simple' : 'expert'`. 700px est déjà la constante de breakpoint utilisée dans les media queries CSS existantes (`@media (max-width:700px) and (orientation:portrait)`, `min-width:700px` pour paysage) — pas de nouveau seuil à inventer, on réutilise celui déjà éprouvé par 4 stories iPhone précédentes.
- C'est la **première fois que l'app fait une détection de viewport côté JS** (jusqu'ici, toute la responsivité passe par CSS pur). C'est un précédent technique à noter : léger, une seule lecture au chargement, pas de listener resize (le mode ne doit pas changer tout seul si l'utilisateur pivote son écran ou redimensionne une fenêtre desktop).

### Rendu conditionnel
- `renderHeader()` / écran Équipes (`renderSetup`) : ajout du bloc de choix de mode (cf. Design), toggle simple `onclick` qui met à jour `S.mode` + `localStorage` + `R()`, même mécanique que le toggle `S.trackGK` déjà existant.
- Panneau `.settings-panel` (Match) : ajout d'une ligne de bascule identique, pour changer en cours de match (Should Have du PRD). Si bascule Expert→Simple en cours de match : `safeConfirm()` (déjà utilisé ailleurs dans l'app) avant d'appliquer, pour éviter une bascule accidentelle qui réduirait la richesse de saisie du reste du match.
- Écran Match (`.match-layout`) : nouvelle fonction `renderMatchSimple()` appelée à la place du bloc `.ml-actions` + `.ml-court` existants quand `S.mode==='simple'`. `.ml-left` (équipes/timer/GB toggle) est **entièrement réutilisé sans changement** — ce n'est pas la partie qui doit se simplifier.

### Nouvelle fonction de saisie
```javascript
function recordSimpleEvent(team, type){
  const opp = team==='home' ? 'away' : 'home';
  S.events.unshift({
    id: uid++, type, team,
    time: S.time, rawTime: S.rawTime, period: S.period,
    x: null, y: null,
    gkId: S[opp].gkId,          // toujours renseigné, ne nécessite aucune saisie côté aidant
    playerId: null, playerName: null, playerNumber: null,
    assistId: null, assistName: null, assistNumber: null,
    goalZone: null
  });
  R();
}
```
Cette fonction **ne remplace pas** le workflow `selectedAction`/`actionPanel` existant (celui-ci reste intouché pour le mode Expert) — c'est un chemin de code séparé et court-circuité, exactement comme le préconise le PRD ("couche additive légère").

## Pourquoi (alternatives considérées et rejetées)
- **Dupliquer tout l'écran Match en deux versions parallèles** (rejeté) : double la surface de maintenance/QA à chaque future story de polish visuel (ce qui est précisément le risque que le PM voulait éviter en recommandant de ne pas tout dissocier maintenant).
- **Un seul écran avec des éléments simplement masqués en CSS** (rejeté) : le workflow Expert (clic action → clic joueur → clic terrain → clic zone) n'a pas de sens à moitié masqué ; il faut un vrai chemin de saisie différent (auto-validation par équipe), pas juste des boutons cachés.
- **Stocker les événements Simple dans une structure différente** (rejeté) : fragmenterait immédiatement Stats/Bilan/PDF, qui devraient alors gérer deux formats. Le modèle d'événement actuel supporte déjà des champs optionnels nuls (vérifié ci-dessous) — inutile de le changer.

## Impact sur l'existant — vérifié dans le code, pas supposé
- `teamScore()`, `teamStat()`, `teamPoss()` (lignes 636-644) filtrent uniquement par `team`/`type`, jamais par `playerId` — **le score et les stats équipe fonctionneront correctement sans aucune modification** pour des événements Simple.
- `teamShots()` (ligne 685) filtre déjà `e.x!=null` — les événements Simple (x null) sont **déjà exclus proprement** des vues terrain/zones de tir (Stats Gardiens, shot maps) sans crash ni `NaN`. Comportement de dégradation déjà défensif, aucune modification requise.
- `gkStats(gkId)` (ligne 645) filtre par `gkId`, jamais par `playerId` — fonctionnera normalement pour des événements Simple **à condition que `gkId` soit bien renseigné** (cf. `recordSimpleEvent` ci-dessus, qui le fait automatiquement).
- **Point de vigilance réel identifié** : la table "Joueurs" (Stats) agrège par `playerId` — un match mixte (Simple puis Expert, ou l'inverse) aura des événements Simple qui ne s'attribuent à aucun joueur. La somme des buts par joueur sera alors **inférieure** au score total de l'équipe. Ce n'est pas un bug (le PRD exclut explicitement le rattrapage a posteriori), mais ça doit être un critère d'acceptation explicite pour que le Developer/QA ne le prennent pas pour une régression. Remonté au Risk Analyst.

## Nouvelles structures de données
Aucune. Le champ `S.mode` est la seule addition à l'état global ; la structure d'un événement ne change pas (cf. `CLAUDE.md`, section "Structure de données d'un événement" — tous les champs existent déjà et acceptent déjà `null`).

## Nouvelles fonctions/modules
- `recordSimpleEvent(team, type)` — construit et pousse un événement Simple.
- `renderMatchSimple()` — rendu de la colonne droite (actions + zone) en mode Simple, réutilise `.ml-left` tel quel.
- Bloc de toggle de mode, réutilisé à deux endroits (Équipes, panneau Réglages Match) — factoriser en une seule fonction `renderModeToggle()` pour éviter une 3e duplication du pattern déjà vu avec `dn()`/`displayNumber` (cf. STORY-21).

## Risques (détaillés par le Risk Analyst)
- Table Joueurs sous-comptant les buts sur un match à mode mixte (cf. ci-dessus).
- Détection de largeur d'écran au chargement : un iPad utilisé en split-view étroit, ou un futur appareil pliable, pourrait être mal classé à la première ouverture — impact faible (l'utilisateur peut changer manuellement), pas un P0.
- Popup de confirmation de bascule Expert→Simple : doit vraiment apparaître avant toute perte de richesse de saisie, à tester explicitement par le QA (cas limite facile à oublier).

## Critère de bascule (quand une refonte structurelle deviendrait nécessaire)
Si un jour un 3e mode ou une granularité intermédiaire est demandée (ex: "Simple mais avec attribution joueur, sans terrain"), la couche conditionnelle actuelle (`if S.mode==='simple'`) devra être remplacée par une vraie configuration de "profil de saisie" (liste de capacités activées/désactivées) plutôt qu'un flag binaire. Pas nécessaire aujourd'hui — deux modes clairs suffisent tant qu'aucun 3e cas d'usage réel n'existe.
