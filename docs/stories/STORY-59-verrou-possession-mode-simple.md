# STORY-59 — Verrou de possession en Mode Simple

**En tant que** Romain,
**Je veux** ne pouvoir tagger une action que pour l'équipe qui a la possession,
**Afin de** ne pas pouvoir enregistrer par erreur une action pour l'équipe qui n'a pas le ballon.

"En mode simple je vois sur la manière de tagguer les boutons Fenix en haut et adversaire en bas. Chacun à ses boutons. Et on peut cliquer partout, même si on a pas la possession. Ce qui est pas normal. Pour avoir bouton actif il faut la possession. Donc message d'erreur si j'appuis sur bouton d'une équipe qui n'a pas la possession. et surtout ne pas enregistrer si je tape dessus et que la possession n'était pas pour l'équipe en question."

## Contexte technique
`S.possession` existe déjà et est fiable en Mode Simple depuis STORY-52/M3 (bascule automatiquement après BUT/ARRÊT/NON CADRÉ/PB). Deux changements coordonnés, défense en profondeur plutôt qu'un seul mécanisme :
1. **Visuel** (`renderMatchSimple()`/`simpleBtn()`) : les boutons de l'équipe qui n'a pas `S.possession` reçoivent la classe `.simple-inactive` (opacité réduite) — reste cliquable (pas `pointer-events:none`), pour que le clic déclenche bien le message d'erreur plutôt qu'un blocage silencieux.
2. **Blocage effectif** (`bind()`, handler `[data-simple]`) : avant tout appel à `recordEvent()`, vérifie `team===S.possession` — si faux, `showToast("⚠️ [Nom équipe] n'a pas la possession", true)` et **retour immédiat, aucun enregistrement**.

## Critères d'acceptation
- [x] Équipe en possession : boutons pleinement visibles/actifs
- [x] Équipe sans possession : boutons visuellement grisés (`.simple-inactive`)
- [x] Clic sur un bouton de l'équipe sans possession → toast d'erreur affiché, **aucun événement ajouté à `S.events`**, `S.possession` inchangée
- [x] Clic sur un bouton de l'équipe en possession → comportement inchangé (enregistrement + flash de confirmation + bascule de possession, STORY-52)
- [x] Après bascule de possession, les classes `.simple-inactive` s'inversent correctement (l'équipe qui vient de perdre le ballon devient grisée)

## Vérifié par CDP (vrais clics)
Possession "home" → bouton BUT home actif (pas de classe), bouton BUT away grisé (`simple-inactive`) ; clic sur away (sans possession) → 0 événement, `S.possession` toujours "home", toast "⚠️ Adversaire n'a pas la possession" visible à l'écran (capture d'écran) ; clic sur home (avec possession) → 1 événement enregistré, `team:"home"`, possession bascule vers "away" ; classes re-vérifiées après bascule : home devient grisé, away devient actif.

## Hors scope
Mode Expert non concerné (le flux terrain existant repose déjà sur `S.possession` pour déterminer quelle équipe est active — sélectionner l'équipe adverse suppose déjà un choix explicite via le bouton POSSESSION lui-même, comportement différent et non signalé comme problématique).

## Taille
XS — 1 classe CSS + 1 garde de 4 lignes dans un handler existant.
