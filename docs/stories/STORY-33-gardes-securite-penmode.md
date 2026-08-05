# STORY-33 — Robustesse de l'encart pénalty face aux actions concurrentes

**En tant que** Romain (saisie en direct, mode Expert),
**Je veux** que les actions "à côté" de l'encart pénalty (annuler le dernier événement, changer la possession, éditer un ancien événement du feed) ne puissent jamais faire planter l'écran Match ni corrompre les données du match pendant que l'encart est ouvert,
**Afin de** ne jamais perdre un match en cours (écran figé) ni enregistrer silencieusement un événement faux (mauvaise équipe, tireur fantôme, panneau bloqué sans explication).

## Contexte

STORY-32 introduit un changement de fond dans le cycle de vie de l'état : **`S.actionPanel` reste non-null en continu, sur plusieurs re-rendus consécutifs, pendant que le terrain reste cliquable** (`S.penMode===true`). Avant ce cycle, le PEN_OBT se validait en synchrone en un seul clic — cette fenêtre temporelle n'existait pas.

Le Risk Analyst a vérifié ligne par ligne trois points d'entrée qui restent **actifs et non gardés** à l'écran pendant cette fenêtre, et qui cassent l'invariant central posé par STORY-32 ("tant que `S.penMode===true`, `S.actionPanel` est garanti non-null"). Cette story ferme ces trois trous, plus deux points connexes moins critiques trouvés par la même analyse.

**Cette story n'a de sens qu'une fois STORY-32 livrée** : les scénarios ci-dessous ne sont reproductibles/testables qu'avec l'encart pénalty réellement fonctionnel (sous-étapes "3 boutons" et "grille de zone" toutes deux atteignables).

## Contexte technique

- `undoLast()` — `app.js` ~996-1004
- Toggle POSSESSION (`data-poss`, boutons `.mlt-poss-btn` dans `.ml-left`, rendu 2 fois — une fois par équipe) — handler bindé ~3816
- `editEvent(idx)` — `app.js` ~1690-1703
- Écran Équipes / roster (`p.selected`) — pour le critère de revalidation du tireur
- Activation du mode lecteur (fonction qui bascule `S.readOnly`, ex. `setReadOnly()`/toggle du panneau ⚙ Réglages du Match)

## Critères d'acceptation

### P0-1 — `undoLast()` doit fermer proprement la transaction pénalty en cours

Traitement retenu : **l'action reste possible** (annuler doit toujours fonctionner, c'est le filet de sécurité principal de l'app) — mais elle nettoie l'état en même temps, à l'identique de ce que fait `closePenPanel()`.

- Modifier `undoLast()` : quand l'événement supprimé (`S.events[0]`) est un `PEN_OBT`, la fonction doit désormais faire, dans le même appel :
```js
if(S.events[0]?.type==='PEN_OBT'){
  S.penMode=false;
  S.actionPanel=null;
  S.selectedAction=null;
}
```
(au lieu du seul `S.penMode=false` actuel).
- Test — sous-étape "3 boutons" : ouvrir l'encart (PO obtenu), taper "↩ Annuler" → le `PEN_OBT` disparaît de `S.events`, **aucune exception JS n'est levée**, l'écran Match se ré-affiche normalement (barre d'actions active, terrain normal, aucun encart résiduel).
- Test — sous-étape "grille de zone" (après avoir tapé BUT/ARRÊT avec `S.trackGK` actif) : taper "↩ Annuler" → mêmes resets ; un tap **ultérieur** sur une cellule de la grille de zone ne produit plus aucun effet (aucun `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF` orphelin n'est créé, puisque `S.actionPanel` est désormais `null`).
- Non-régression : `undoLast()` sur un événement qui n'est **pas** un `PEN_OBT` (BUT normal, PB, carton, etc.) garde un comportement strictement identique à avant ce cycle.

### P0-2 — Le toggle POSSESSION doit être neutralisé pendant l'encart pénalty

Traitement retenu : **l'action est bloquée** (pas de raison légitime de changer d'équipe pendant qu'on résout l'issue d'un pénalty déjà attribué à une équipe fixée) — avec le même signal visuel que celui déjà prévu pour `.ml-actions` dans STORY-32, pour que ce ne soit jamais perçu comme un bug silencieux.

- Modifier le handler `data-poss` (~3816) pour ajouter une garde en tête :
```js
if(S.penMode) return;
```
avant toute mutation de `S.possession`/`S.actionPanel.team`.
- Test : ouvrir l'encart (PO obtenu par l'équipe A, tireur désigné), taper le bouton `data-poss` de l'équipe B → **aucun effet** : `S.possession` ne change pas, `ap.team` ne change pas, `ap.shooterId` ne change pas, l'encart reste affiché à l'identique.
- Traitement visuel obligatoire : les boutons `data-poss` des deux équipes apparaissent visuellement grisés/désactivés pendant `S.penMode` (`opacity:.35;pointer-events:none` — même traitement que `.match-layout.is-readonly .act-h`, `style.css` ~409-420).
- Non-régression : hors `S.penMode`, le toggle POSSESSION fonctionne exactement comme avant (y compris la mise à jour de `S.actionPanel.team` pour un tir normal en cours, comportement actuel préservé).

### P0-3 — `editEvent()` doit refuser de démarrer tant que l'encart pénalty est ouvert

Traitement retenu : **l'action est bloquée avec un message explicite** (pas de fermeture silencieuse en arrière-plan — éditer un ancien événement est un geste délibéré à deux taps, mérite un signal clair plutôt qu'un effet de bord invisible sur l'encart en cours).

- Ajouter en tête d'`editEvent(idx)` :
```js
if(S.penMode){
  safeAlert("Terminez ou fermez le pénalty en cours avant de modifier un autre événement.");
  return;
}
```
- Test : ouvrir l'encart pénalty, ouvrir le fil d'événements, taper "modifier" sur n'importe quel événement (y compris un ancien `PEN_OBT`/`PEN_GOAL`, ou un tir normal) → le message s'affiche, le panneau d'édition ne s'ouvre pas, `S.penMode` reste `true`, `S.actionPanel` reste celui du pénalty en cours **inchangé** (tireur désigné, sous-étape en cours non affectée).
- Non-régression : après avoir fermé l'encart normalement (✕ Fermer ou validation d'une issue), éditer un événement fonctionne exactement comme avant ce cycle.

### P1-4 — Revalidation du tireur désigné contre le roster courant (priorité secondaire, faible coût)

Contexte : l'écran Équipes reste modifiable pendant un match en cours (le mode lecteur l'exclut volontairement, cf. `CLAUDE.md`). Si Romain navigue vers Équipes pendant que l'encart est ouvert et désélectionne/supprime le joueur désigné comme tireur, `ap.shooterId` devient une référence qui ne correspond plus à personne.

- Avant toute validation finale (dans `choosePenOutcome()` et/ou au moment où `clickGoalZone()`/`validateAndClose()` s'apprête à écrire l'événement), vérifier que `ap.shooterId` correspond toujours à un joueur `selected:true` de `S[ap.team].players`.
- Si ce n'est plus le cas : ne créer **aucun** événement `PEN_GOAL`/`PEN_SAVE`/`PEN_OFF`, réinitialiser `ap.shooterId=null`, afficher un message clair (ex. via `showToast()`) invitant à resélectionner un joueur, et laisser l'encart ouvert à l'étape "3 boutons" (ou revenir à cette étape si on était déjà sur la grille de zone).
- Test : ouvrir l'encart, aller sur Équipes, désélectionner le tireur désigné, revenir sur Match, taper BUT → aucun événement créé, message affiché, `ap.shooterId` est `null`, l'anneau doré n'apparaît plus sur aucun joueur.

### P2-5 — Activer le mode lecteur sur son propre appareil doit fermer proprement sa propre transaction pénalty

Contexte : `closePenPanel()` (STORY-32) commence par `if(S.readOnly) return;` — si Romain active le mode lecteur sur son **propre** appareil pendant que son propre encart est ouvert, le bouton ✕ Fermer devient lui-même inutilisable, gelant l'encart à l'écran sans aucun moyen de le refermer tant que le mode lecteur reste actif.

- Dans la fonction qui bascule `S.readOnly` à `true` (ex. `setReadOnly()`), fermer explicitement toute transaction pénalty en cours **au moment même de l'activation**, par symétrie avec `newMatch()`/le chargement d'un match qui font déjà ce type de reset lors d'une transition d'état :
```js
S.actionPanel=null;
S.selectedAction=null;
S.penMode=false;
```
(le `PEN_OBT` déjà enregistré, s'il y en a un, reste intact — cette fonction ne touche jamais `S.events`).
- Test : ouvrir l'encart pénalty, activer le mode lecteur depuis le panneau ⚙ Réglages du Match → l'encart disparaît immédiatement, le `PEN_OBT` reste dans le feed, aucune erreur, aucun contrôle figé à l'écran.

## Hors scope

- **Limite acceptée explicitement (#5a du Risk Analyst), aucun correctif prévu** : si l'appareil qui saisit (Safari tué en arrière-plan sur iPad, crash, rechargement) ferme/recharge pendant que l'encart pénalty est ouvert, le `PEN_OBT` déjà synchronisé peut rester définitivement sans issue associée dans l'historique partagé. Cohérent avec la sortie explicite `✕ Fermer` déjà acceptée par le PRD (décision actée #4 : un PO sans issue est un état valide, pas une corruption). Aucun mécanisme de reprise/réouverture d'un encart pour un `PEN_OBT` existant a posteriori n'est prévu dans ce cycle — si Romain rencontre ce cas, le `PEN_OBT` reste lisible/éditable normalement dans le feed comme n'importe quel événement sans suite.
- Toute modification du comportement d'`undoLast()`, du toggle POSSESSION, ou d'`editEvent()` **hors** `S.penMode` — doit rester strictement identique à avant ce cycle.
- La protection défensive de `renderGkSheet()`/`goalZoneHeatmap()` — couverte par STORY-34, indépendante de celle-ci.

## Dépend de

STORY-32 (nécessite que l'encart pénalty existe réellement — sous-étapes "3 boutons" et "grille de zone" toutes deux atteignables — pour que ces gardes aient un sens et soient testables).

## Taille

M
