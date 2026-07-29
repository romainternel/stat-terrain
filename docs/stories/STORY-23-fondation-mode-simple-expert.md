# STORY-23 — Fondation du mode Simple/Expert (état, toggle, détection)

**En tant que** Romain,
**Je veux** pouvoir choisir entre un mode de saisie Simple et Expert, mémorisé par appareil,
**Afin de** préparer l'usage occasionnel (aidant, iPhone) sans toucher au mode Expert que j'utilise chaque match.

## Contexte technique
- Nouvel état `S.mode = 'expert' | 'simple'` ajouté à `freshState()`.
- Persistance : nouvelle clé `localStorage.getItem/setItem('hb2_mode', ...)`, cohérente avec `hb2_teams`/`hb2_matches` déjà existants.
- Détection par défaut à la première utilisation (absence de `hb2_mode`) : `window.innerWidth < 700 ? 'simple' : 'expert'` — réutilise le seuil 700px déjà utilisé par les media queries CSS existantes (STORY-02/03/18/19), pas un nouveau seuil.
- Toggle ajouté à deux endroits, via une fonction factorisée unique `renderModeToggle()` (ne pas dupliquer le markup à la main, cf. `docs/architecture/mode-simple-expert.md`) :
  - Écran Équipes (`renderSetup()`), emplacement principal.
  - Panneau `.settings-panel` du Match (variable `settingsHtml`), pour changer en cours de match.
- Bascule Expert → Simple en cours de match (`S.events.length>0`) : passer par `safeConfirm()` (déjà utilisé ailleurs dans l'app) avant d'appliquer le changement, pour éviter une perte accidentelle de richesse de saisie pour le reste du match.
- Cette story pose la fondation d'état et le toggle ; **le rendu de l'écran Match reste celui d'Expert** dans tous les cas à ce stade (le nouvel écran Match Simple arrive en STORY-24) — activer le mode Simple ici ne doit provoquer aucun changement visuel sur l'écran Match, seulement sur le toggle lui-même et sa persistance.

## Critères d'acceptation
- [ ] `S.mode` existe, vaut `'expert'` ou `'simple'`, persiste dans `localStorage` sous `hb2_mode`.
- [ ] À la toute première utilisation sur un appareil (aucun `hb2_mode` en localStorage), le mode par défaut est `'simple'` si `window.innerWidth<700`, sinon `'expert'`.
- [ ] Un appareil qui a déjà un `hb2_mode` enregistré n'est **jamais** réinitialisé à l'ouverture, même si la largeur d'écran correspondrait à un autre mode.
- [ ] Le toggle est visible et fonctionnel sur l'écran Équipes ET dans le panneau Réglages du Match, via une seule fonction `renderModeToggle()` partagée (pas de markup dupliqué).
- [ ] Changer de mode alors qu'aucun événement n'a encore été saisi (`S.events.length===0`) s'applique immédiatement, sans confirmation.
- [ ] Changer de Expert vers Simple alors que des événements existent déjà (`S.events.length>0`) déclenche une confirmation (`safeConfirm()`) avant application.
- [ ] Changer de Simple vers Expert ne nécessite aucune confirmation (on ne perd rien en gagnant en détail).
- [ ] Aucune régression visuelle ou fonctionnelle sur l'écran Match actuel (mode Expert), quel que soit l'état de `S.mode` à ce stade de l'implémentation.

## Hors scope
- Le nouvel écran Match Simple lui-même (actions auto-validées par équipe) — STORY-24.
- L'indicateur de mode actif pendant la saisie — STORY-24.
- Tout changement au modèle de données événement.

## Dépend de
Aucune.

## Taille
M
