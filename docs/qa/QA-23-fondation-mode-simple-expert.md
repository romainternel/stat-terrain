# QA — STORY-23 : Fondation du mode Simple/Expert

## Méthode de test
Tests réels via CDP (Chrome DevTools Protocol) sur Chrome headless — vrais clics (`Input.dispatchMouseEvent`), lecture directe de l'état (`S.mode`) et de `localStorage`, sur iPhone (390×844) et iPad (1024×768).

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| `S.mode` existe, persiste dans `localStorage` sous `hb2_mode` | ✅ | Vérifié directement après clic : `localStorage.getItem('hb2_mode')` reflète le choix. |
| Première utilisation : `'simple'` si `innerWidth<700`, sinon `'expert'` | ✅ | Testé sans `hb2_mode` préalable : iPhone (390px) → `simple`, iPad (1024px) → `expert`. |
| Un `hb2_mode` déjà enregistré n'est jamais réinitialisé | ✅ | Testé : `hb2_mode='simple'` forcé sur iPad (largeur qui donnerait normalement `expert`) → reste `simple` après rechargement. |
| Toggle visible et fonctionnel sur Équipes ET panneau Réglages Match | ✅ | Cliqué réellement aux deux emplacements, `S.mode` et `localStorage` mis à jour à chaque fois. Note Code Reviewer sur la déviation de markup (justifiée) — sans impact fonctionnel. |
| Changement sans confirmation si `S.events.length===0` | ✅ | Testé sur écran Équipes (aucun événement en cours) : bascule immédiate. |
| Confirmation bloquante Expert→Simple si des événements existent | ✅ | Testé avec un événement factice : `window.confirm` mocké pour refuser → mode reste `expert` ; mocké pour accepter → mode passe à `simple`. Message de confirmation lisible et clair. |
| Simple→Expert sans confirmation | ✅ | Vérifié dans le code (`setMode()`) : la condition ne couvre que le sens Expert→Simple. Cohérent avec le critère ("on ne perd rien en gagnant en détail"). |
| Aucune régression visuelle/fonctionnelle sur l'écran Match | ✅ | Écran Match affiche toujours `.ml-actions` et `.court-pick` quel que soit `S.mode` — comportement attendu, le nouvel écran Simple arrive en STORY-24. |

## Cas limites testés
- Bascule de mode répétée (Simple→Expert→Simple) sans laisser l'état ou le localStorage se désynchroniser.
- Mode forcé par localStorage en contradiction avec la largeur d'écran réelle (cas de l'appareil "déjà configuré") : comportement correct, priorité au choix explicite.

## Bugs trouvés
Aucun.

Une anomalie de méthode de test a été rencontrée et corrigée en cours de route (pas un bug de l'app) : les premiers clics simulés visaient un élément situé hors du viewport visible (le bloc de toggle est loin sous les listes de joueurs sur l'écran Équipes) — corrigé en scrollant l'élément dans la vue avant chaque clic simulé, comme déjà pratiqué pour STORY-22.

## Régressions détectées
Aucune. L'écran Match, le toggle `trackGK` existant, et le reste du panneau Réglages (Sauvegarder/Exporter/Importer/Effectifs/Nouveau match) fonctionnent normalement, non affectés par l'ajout du toggle de mode.

## Verdict
**PASSED**

Tous les critères d'acceptation sont satisfaits. Prêt pour STORY-24 (écran Match en mode Simple), qui dépend de cette fondation.
