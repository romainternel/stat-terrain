# STORY-52 — Corrections ciblées : chrono auto, highlight action, possession Mode Simple, rappel mi-temps

**En tant que** Romain,
**Je veux** que le chrono démarre seul au lancement du match, que sélectionner une action se voie clairement, que la possession bascule automatiquement en Mode Simple comme en Mode Expert, et qu'on ne puisse plus oublier de passer en mi-temps 2,
**Afin de** fiabiliser la saisie en direct sans y penser à chaque instant.

Retours directs de Romain après son premier match réel (Mode Simple). Référence complète : `docs/design/retours-premier-match-reel.md`, `docs/arch/retours-premier-match-reel.md` (sections M1-M4).

## Contexte technique
4 corrections indépendantes, risque faible — pas de Designer/Visual Crafter nécessaire au-delà des valeurs déjà spécifiées.

## Critères d'acceptation

**M1 — Chrono auto-démarré**
- [ ] Clic sur "▶ Lancer le match" démarre le chrono automatiquement (`startTimer()` appelé), plus besoin de cliquer "▶ Start" ensuite
- [ ] `S.period` fixé explicitement à `1` au même moment
- [ ] Double-clic rapide sur "Lancer le match" ne démarre pas deux fois le chrono (garde déjà existante dans `startTimer()`)

**M2 — Highlight de sélection d'action visible**
- [ ] `--accent`/`--accent-rgb` définies dans `style.css` — cliquer sur BUT/Tir arrêté/etc (Mode Expert) montre clairement une bordure + un léger glow sur le bouton sélectionné
- [ ] Vérifié sur fond sombre, contraste suffisant

**M3 — Possession auto-switch en Mode Simple**
- [ ] En Mode Simple, cliquer BUT/ARRÊT/NON CADRÉ/PB bascule `S.possession` vers l'équipe adverse, exactement comme en Mode Expert
- [ ] Vérifié aussi en Mode Expert (non-régression — le comportement déjà existant ne doit pas changer)

**M4 — Rappel de mi-temps**
- [ ] À `S.period===1` et `S.time>=1800` (30 min), un toast rappelle de basculer en MT2, répété toutes les 2 minutes tant que non fait
- [ ] Le bouton "MT [N]" devient visuellement plus visible (bordure/pulsation) une fois ce seuil dépassé, redevient neutre après la bascule
- [ ] Fonctionne identiquement en Mode Simple et Mode Expert (le rappel est déclenché par le tick du chrono, pas par un événement de saisie)
- [ ] Anti-spam indépendant du rappel TM existant (les deux mécanismes ne se bloquent pas mutuellement)

## Cas limites à tester
- Rappel de mi-temps déclenché pendant qu'un `S.actionPanel` est ouvert (Mode Expert) : le toast ne doit pas interrompre la saisie en cours
- Match rechargé/repris (STORY-14) après 30 minutes de MT1 déjà écoulées : le rappel doit pouvoir se déclencher normalement, pas seulement sur un match démarré dans la session courante

## Hors scope
Fenêtre de validation au lancement et mode équipe générale (STORY-53).

## Dépend de
Aucune.

## Taille
S — 4 corrections ciblées, aucune nouvelle structure de données complexe.
