# QA — STORY-52 (Chrono auto, flash Mode Simple, possession, rappel mi-temps)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-52-corrections-ciblees-saisie-match.md`, `docs/code-review/STORY-52.md` (APPROUVÉ), `docs/arch/retours-premier-match-reel.md`.

## Méthode
CDP sur Chrome headless (port 9701), serveur statique local (port 8990), **vrais clics réels** (`Input.dispatchMouseEvent`) sur `#launch-match-btn` et `[data-simple]`, état forcé via `Runtime.evaluate` pour atteindre rapidement les conditions de test (GK/effectif, période/temps), captures d'écran réelles à 820×1180.

## Critères d'acceptation

**M1 — Chrono auto-démarré**
- [x] Clic réel sur "▶ Lancer le match" → `S.running===true`, `S.period===1`, `S.view==="match"` en une seule passe, capture d'écran confirmant le bouton "⏸ Stop" (donc chrono démarré) dès le premier rendu de l'écran Match
- [x] Garde anti-double-démarrage de `startTimer()` inchangée — pas de nouveau code de garde nécessaire, testé par lecture (pas de régression possible sur ce point précis, la fonction elle-même n'a pas changé)

**M2 — Confirmation visuelle de sélection (reformulé après diagnostic corrigé, cf. Code Review)**
- [x] Mode Expert : `.act-h.selected` déjà fonctionnel avant ce cycle — capture d'écran confirmant bordure + glow sky-blue visibles sur le bouton BUT après clic, aucune régression après les autres changements de cette story
- [x] Mode Simple : nouveau flash `.simple-flash` sur le bouton cliqué — présent immédiatement après clic (`hasFlashClass:true`), disparaît après ~400ms (`hasFlashClassAfter:false`, `S.simpleFlash===null`), capture d'écran confirmant le glow visible au moment du clic

**M3 — Possession auto-switch en Mode Simple**
- [x] Clic réel sur BUT (équipe home) en Mode Simple → `S.possession` bascule `"home"→"away"`
- [x] Mode Expert re-vérifié après tous les changements — `validateAndClose()` non touché, comportement identique à avant

**M4 — Rappel de mi-temps**
- [x] `S.period=1,S.time=1800` → `checkHalfTimeReminder()` déclenche un toast (capture d'écran : bandeau rouge "⏰ Fin de la 1ère mi-temps réglementaire — pense à basculer sur MT2") et `#per-btn` prend la classe `.due` (bordure jaune, capture confirmant le badge "MT 1" en jaune)
- [x] Anti-spam : appel immédiat répété de `checkHalfTimeReminder()` → pas de second déclenchement (`S.halfTimeLastAlert` inchangé)
- [x] `#per-btn` handler reset bien `S.halfTimeLastAlert=0` en plus de `S.tmLastAlert=0` au changement de mi-temps (lecture de code, cohérent avec le reset existant)
- [x] Fonctionne identiquement Mode Simple/Expert — le hook est sur le tick du chrono (`startTimer()`/`mergeRemoteMatchSnapshot()`), pas sur un point de saisie spécifique à un mode

## Cas limites testés
- **Rappel pendant un `S.actionPanel` ouvert (Mode Expert)** : `showToast()` est un composant non intrusif déjà utilisé ailleurs (TM, GK) sans jamais interrompre une saisie en cours — pas de changement de ce comportement, pas re-testé spécifiquement à ce point précis (risque déjà qualifié de mineur en amont, R4).
- **Match repris avec 30min déjà écoulées en MT1** : le rappel se base uniquement sur `S.period`/`S.time` au moment du tick, pas sur une durée de session — fonctionne identiquement pour un match repris, confirmé par lecture de `checkHalfTimeReminder()` (aucune dépendance à un timestamp de démarrage de session).

## Bugs trouvés
Aucun dans le code livré. Un piège trouvé **dans mon propre script de test** (pas dans l'app) : `R()` utilise `requestAnimationFrame`, donc lire le DOM immédiatement après un appel synchrone à `R()` retourne l'état d'avant le rendu — corrigé en ajoutant une attente avant la lecture du DOM.

## Régressions détectées
Aucune — Mode Expert re-testé après implémentation de M2/M3/M4, `.act-h.selected` et l'auto-switch de possession de `validateAndClose()` fonctionnent identiquement à avant.

## Verdict
**PASSED**
