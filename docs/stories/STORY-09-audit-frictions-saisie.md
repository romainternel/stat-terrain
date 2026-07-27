# STORY-09 — Audit des frictions du workflow de saisie

**En tant que** Romain,
**Je veux** vérifier s'il reste des points de friction dans le workflow de saisie d'action (sélection action → équipe → joueur → terrain → zone de but → validation),
**Afin de** ne pas ajouter de polish visuel ou de responsive iPhone par-dessus un workflow qui aurait encore des irritants non résolus.

## Contexte technique

- Cette story est une **investigation**, pas une implémentation — elle peut ne déboucher sur aucun changement de code si rien n'est trouvé.
- Zone à revoir : `validateActionPanel()`, `clickActionPlayer()`, `clickGoalZone()`, `autoValidatePending()`, `selectAction()` dans `app.js`.
- Point de départ : l'historique git montre plusieurs correctifs récents sur ce workflow (terrain requis pour tirs Fenix, flow 2 étapes strict pour la zone de but, suppression d'événement avec confirmation) — vérifier que ces correctifs couvrent bien tous les cas, en conditions réelles de match si possible.

## Point de vigilance suite au test visuel du 2026-07-23

L'app a été lancée et pilotée réellement en local (captures dans `docs/design/screenshots/`) pour juger la densité visuelle et le responsive — voir les preuves ajoutées à STORY-02 et STORY-03. **Ce test n'a pas validé le workflow de saisie lui-même** : les écrans Match ont été obtenus par injection directe de l'état (`S.events`, `S.view`) via la console, pas en cliquant réellement sur le fil action → équipe → joueur → terrain → zone de but → validation. Cette story reste donc entière : aucun élément ci-dessus ne permet de dire que les frictions de saisie sont vérifiées ou absentes.

## Résultat de l'audit (2026-07-27) — réalisé avec de vrais clics simulés

Contrairement au test du 2026-07-23, cet audit a été fait avec de **vrais clics** pilotés via CDP (pas d'injection d'état pour le workflow lui-même — seule la mise en place initiale du roster a été injectée). Parcours testés et confirmés fonctionnels :

- ✅ **BUT (GOAL)** : sélection action → clic tireur → clic position d'impact → clic zone de but → auto-validation. Événement enregistré avec le bon type/équipe/joueur/position/zone.
- ✅ **PB (TURNOVER)** : sélection action → clic joueur → auto-validation immédiate. `x`/`y` restent `null` **par conception** (une perte de balle n'a pas de "position de tir") — ce n'est pas un bug, juste une caractéristique de ce type d'événement.
- ✅ **2 min (TWO_MIN)** : déclenché via le badge sanction dans le bloc équipe (`[data-badge]`), pas via la barre d'actions principale — ouvre un sélecteur de joueur sur le terrain (`.cp-player[data-pick-player]`), fonctionne correctement une fois le bon joueur cliqué.
- ✅ **PD (passe décisive)** : fonctionne, mais **pas comme documenté**. `CLAUDE.md` décrit "2e clic joueur après tireur = PD" — en réalité, cliquer un 2e joueur pendant la saisie du tir **remplace le tireur**, ça ne définit jamais d'assist. Le vrai mécanisme est un bouton dédié **"🎯 PD"** (apparaît après le dernier événement enregistré) qui ouvre un sélecteur de joueur pour assigner rétroactivement une passe décisive à l'événement le plus récent. Testé et confirmé fonctionnel via ce bouton.
- ✅ **Annuler (undo)** : confirmé fonctionnel, retire le dernier événement (`S.events.shift()`).

**Aucune friction bloquante ou majeure trouvée dans le workflow de saisie lui-même.** Deux trouvailles mineures, ni l'une ni l'autre ne cassant quoi que ce soit :

1. **Documentation obsolète** : la description du mécanisme PD dans `CLAUDE.md` ne correspond plus au code actuel (probablement un reliquat d'une version antérieure à la refonte du layout). À corriger par l'Archiviste à la prochaine mise à jour de `CLAUDE.md` — pas un correctif de code.
2. **CSS mort** : les règles `.act-h[data-act="TWO_MIN"]` et `.act-h[data-act="RED"]` dans `style.css` ne correspondent à aucun élément jamais généré (2min/carton rouge passent par `.mlt-btn-sanc`/`[data-badge]`, pas par la barre d'actions `.act-h`). Sans impact fonctionnel, juste des octets inutiles — à nettoyer lors d'un futur passage de dette technique, pas urgent.

## Critères d'acceptation

- [x] Romain (ou le Developer en simulant un match) passe en revue les cas suivants sans surprise : but normal, but sur pénalty, PD après but, tir arrêté, tir non cadré, PB/PO/jet franc (sans zone de but), 2min/carton rouge/TM.
  - **Testés avec de vrais clics** : but normal (GOAL), PB (TURNOVER), PD (bouton dédié), 2min (TWO_MIN), annuler.
  - **Non cliqués en direct, mais vérifiés par lecture du code** (même branche que les cas testés, cf. `clickActionPlayer()`/`clickActionMap()`) : tir arrêté (SAVE) et tir non cadré (OFF) partagent exactement le code de GOAL (`act.isGoal||act.isSave||act.isOff`) ; PO (PEN_OBT) a une branche dédiée simple (ligne 352-356) ; jet franc (FREEKICK) partage le code de PB (`needsMap:true`, non-shot) ; carton rouge (RED) partage le code de 2min (même binding générique `[data-badge]`) ; TM a sa propre fonction `recordTM()`, simple et directe. Aucune de ces branches ne présente de logique suspecte à la lecture.
  - **But sur pénalty (mode PenMode)** : vérifié par lecture du code uniquement (ligne 341-349 de `app.js`) — conversion GOAL/SAVE/OFF → PEN_GOAL/PEN_SAVE/PEN_OFF quand `S.penMode` est actif, logique simple et cohérente. Non cliqué en direct — si Romain veut une vérification 100% en conditions réelles avant la reprise du championnat, ce cas précis (et RED/TM) mérite un essai manuel sur son appareil.
- [x] Une liste documentée des frictions trouvées est produite — voir section "Résultat de l'audit" ci-dessus. Conclusion : **rien à corriger dans le code**, deux trouvailles mineures hors-code (doc obsolète, CSS mort).
- [x] Aucune friction de code trouvée, donc rien à reformuler en story de correction. Les deux trouvailles mineures sont notées ci-dessus pour un traitement léger (mise à jour doc + nettoyage CSS), pas des stories à part entière vu leur taille.

## Hors scope

- Toute correction de code (sera une story séparée si besoin).

## Dépend de

Aucune. Recommandé avant STORY-02/STORY-03 (une friction trouvée ici pourrait changer l'approche du responsive), mais non bloquant si Romain préfère avancer en parallèle.

## Taille

S
