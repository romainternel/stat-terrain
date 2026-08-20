# Code Review — STORY-55 à STORY-61 (cycle "rosters par défaut, tag terrain PB/Jet franc, verrous et rappels")

## Portée revue
Diff complet des 7 commits `6940380`..`8955de9` (`git diff 6940380^..8955de9`) : `app.js` (+147/-27 sur la plage), `style.css` (+27/-13), `sw.js` (v101→v109). Chaque story a déjà un fichier `docs/stories/STORY-N-*.md` détaillé ; cette revue vérifie le code livré indépendamment de ces notes, pas seulement leur cohérence interne.

## Développeur
Code déjà implémenté et déployé (7 commits poussés sur `main`, service worker en v109). Aucune nouvelle implémentation nécessaire pour cette passe — cette revue porte sur le code tel que livré.

## Conformité et cohérence

**STORY-55/56 (rosters par défaut)** — `defaultAdversairePlayers()`/`defaultAdversaireTeam()`/`defaultFenixCfTeam()` cohérents entre eux (même schéma de génération d'id via `gid()`, même structure de player). Différence volontaire et correcte entre les deux : `defaultAdversaireTeam()` présélectionne tout (`selected:true`, prêt à l'emploi) tandis que `defaultFenixCfTeam()` laisse tout désélectionné + `gkId:null` (comportement d'un import CSV classique, cohérent avec le commentaire STORY-60 expliquant pourquoi `gkId` n'est plus préassigné).

**STORY-57/58/59 (needsMap, scroll, possession)** — Le changement `isGoal||isSave||isOff` → `act.needsMap` dans `clickActionPlayer()`/`renderMatchPanel()` a été tracé jusqu'à tous ses effets de bord : `PEN_OBT` est intercepté dans une branche antérieure (jamais affecté), `PEN_GOAL/PEN_SAVE/PEN_OFF` ne transitent jamais par ce chemin (assignés uniquement via `choosePenOutcome()`). Vérifié qu'aucun code d'agrégation de tirs (`renderPlayerDetail`, PDF, GK stats, `renderCompareCourt`) ne filtre par `needsMap` — tous utilisent explicitement `isGoal||isSave||isOff` (ou `type==="TURNOVER"` exact pour les marqueurs PB dédiés) : **le nouvel `x`/`y` réel de TURNOVER/FREEKICK ne fuite dans aucun affichage de "tirs"**, confirmé par recherche exhaustive plutôt que supposé.

**Point notable (pas un bug)** : `teamShots()` (ligne 1314, filtre par `needsMap` large) alimente `renderShotOverlay()`/`S.shotOverlay` — ce chemin est **du code mort** : `S.shotOverlay` n'est jamais mis à `{...}` par un flux atteignable (son seul écrivain non-null, `selectPlayerForAction()`, n'est appelé qu'avec `ps.type` ∈ {TWO_MIN, RED} via les badges de sanction, tous deux `needsMap:false`). Pré-existant, non aggravé par ce cycle — même famille que `clickTeam()`/`renderMiniCompare()` déjà notés dead code ailleurs dans le projet. Aucune action requise.

**STORY-60 (rappel GB)** — `hasValidGk()` correctement utilisée dans `launchWarnings()`. Le reset de `gkId` à la désélection (`[data-sel-player]`) couvre le cas où le coach retire le GB en cours de sélection ; combiné à `defaultFenixCfTeam()` qui ne préassigne plus de `gkId`, les deux points empêchent la même classe de bug (gardien fantôme non sélectionné) par deux angles différents — défense en profondeur cohérente, pas redondante.

**STORY-61 (boutons manuels)** — Gating de visibilité vérifié correct par lecture (`isHome&&S.teamProfile==="cf"` / `!isHome`). Le bouton Adversaire ne touche jamais `S.away.name`, contrairement à `defaultAdversaireTeam()` — différence volontaire et documentée en commentaire, cohérente avec l'objectif (ne pas écraser un nom d'adversaire déjà saisi).

## Finding — Recommandé (non bloquant)
Les deux nouveaux handlers `[data-load-fenix-cf]`/`[data-load-adversaire-template]` appellent `saveTeams(); R();` mais **pas `upsertMatchSnapshot()`**, contrairement au handler `[data-sel-player]` juste au-dessus dans le même fichier qui, lui, l'appelle systématiquement après une modification d'effectif. Si l'un de ces boutons est cliqué pendant qu'un match est déjà actif (`S.currentMatchId` non-null — possible en théorie, l'onglet Équipes n'étant jamais verrouillé pendant un match), le nouvel effectif ne se propage pas immédiatement à Supabase ; un autre appareil qui reprendrait ce match avant la prochaine action de synchronisation verrait l'ancien effectif. Risque faible en pratique (`upsertMatchSnapshot()` est déjà un no-op silencieux tant qu'aucun match n'est lancé — le cas le plus probable — et le prochain toggle de sélection individuel republierait de toute façon l'effectif complet). Pas bloquant, mais à corriger si l'occasion se présente : ajouter `upsertMatchSnapshot();` aux deux handlers, par cohérence avec le pattern déjà établi.

## Remarques classées

**Bloquant** : aucune.

**Recommandé** :
- Ajouter `upsertMatchSnapshot()` aux deux handlers de rechargement manuel (voir finding ci-dessus).
- Edge case mineur non bloquant : si un coach vide complètement l'effectif FENIX CF via "🗑 Vider" puis recharge la page, `loadTeamsForActiveProfile()` le traite comme "jamais sauvegardé" (`saved.home.players.length>0` faux) et **recharge automatiquement les 22 joueurs par défaut** plutôt que de respecter le vide intentionnel. Comportement hérité du pattern préexistant (même condition utilisée avant ce cycle), pas une régression introduite ici — mais vaut la peine d'être su si jamais rapporté comme "je vide et ça revient".

**Note** :
- Les positions de Jet franc (`x`/`y`) sont désormais capturées (STORY-58) mais n'ont **aucune visualisation dédiée** nulle part (contrairement à PB, qui a ses marqueurs losange sur `renderCompareCourt()` depuis STORY-44/58) — donnée disponible, pas encore exploitée. Pas un défaut, une opportunité pour une future story si Romain le demande.

## Verdict
**APPROUVÉ**
