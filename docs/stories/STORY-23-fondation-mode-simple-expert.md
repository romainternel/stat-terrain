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
- [x] `S.mode` existe, vaut `'expert'` ou `'simple'`, persiste dans `localStorage` sous `hb2_mode`.
- [x] À la toute première utilisation sur un appareil (aucun `hb2_mode` en localStorage), le mode par défaut est `'simple'` si `window.innerWidth<700`, sinon `'expert'`.
- [x] Un appareil qui a déjà un `hb2_mode` enregistré n'est **jamais** réinitialisé à l'ouverture, même si la largeur d'écran correspondrait à un autre mode.
- [x] Le toggle est visible et fonctionnel sur l'écran Équipes ET dans le panneau Réglages du Match. *Voir notes Developer : markup volontairement différent entre les deux (pas une fonction unique littéralement partagée), mais un seul point de vérité pour la logique (`setMode()` + binding `[data-mode]`).*
- [x] Changer de mode alors qu'aucun événement n'a encore été saisi (`S.events.length===0`) s'applique immédiatement, sans confirmation.
- [x] Changer de Expert vers Simple alors que des événements existent déjà (`S.events.length>0`) déclenche une confirmation (`safeConfirm()`) avant application.
- [x] Changer de Simple vers Expert ne nécessite aucune confirmation (on ne perd rien en gagnant en détail).
- [x] Aucune régression visuelle ou fonctionnelle sur l'écran Match actuel (mode Expert), quel que soit l'état de `S.mode` à ce stade de l'implémentation.

## Notes Developer

- **Déviation assumée par rapport à la story** : le toggle n'utilise pas littéralement la même fonction de rendu aux deux emplacements. `renderModeToggle()` (deux blocs larges avec sous-texte descriptif) est utilisée sur l'écran Équipes, où il y a de la place. Le panneau `.settings-panel` du Match est une colonne étroite flottante (~180px) où ce même markup aurait été écrasé/tronqué — j'y ai mis une variante compacte (deux boutons `btn-sm` côte à côte). **Ce qui est réellement partagé et non dupliqué** : la logique de clic (`setMode()`) et le binding (`[data-mode]` unique dans `bind()`) — les deux emplacements appellent exactement le même chemin de code, seul l'habillage visuel diffère selon l'espace disponible. Signalé explicitement pour le Code Reviewer.
- `setMode()` place la garde anti-reset directement dans la logique de chargement initial (lecture `hb2_mode` avant tout calcul de largeur d'écran) plutôt que dans une fonction séparée — plus simple, un seul endroit à lire.
- Testé via CDP (clics réels, pas de simulation) : détection iPhone/iPad par défaut, persistance du choix explicite, toggle sur les deux écrans, confirmation bloquante/acceptée à l'aller-retour Expert→Simple avec événements existants, aucune régression visuelle sur l'écran Match (celui-ci reste rendu en Expert quel que soit `S.mode`, conformément au scope de cette story — le nouvel écran Simple arrive en STORY-24).
- Correction en cours de route : une faute de frappe introduite par erreur dans la couleur du bouton "Lancer le match" existant (`rgba(123,167,212,...)` au lieu de `194`) a été détectée et corrigée avant de livrer — aucune trace dans le code final.

## Hors scope
- Le nouvel écran Match Simple lui-même (actions auto-validées par équipe) — STORY-24.
- L'indicateur de mode actif pendant la saisie — STORY-24.
- Tout changement au modèle de données événement.

## Dépend de
Aucune.

## Taille
M
