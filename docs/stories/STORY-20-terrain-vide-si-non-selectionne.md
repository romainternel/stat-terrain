# STORY-20 — Terrain vide si aucun joueur sélectionné

**En tant que** Romain,
**Je veux** que le terrain n'affiche que les joueurs que j'ai explicitement sélectionnés pour le match,
**Afin de** ne jamais voir un joueur que je n'ai pas choisi, ni être perturbé par un effectif par défaut trompeur.

## Contexte technique

- Découvert en analysant une capture d'écran réelle de l'app en production : `renderMatchPanel()`, `renderPdSelect()`, `renderPlayerSelect()` dans `app.js` contiennent chacune le même motif :
  ```js
  let roster = S[team].players.filter(p=>p.selected);
  if(roster.length===0) roster = S[team].players;
  ```
  La 2e ligne (filet de sécurité "sinon montre tout le monde") doit être supprimée dans les 3 fonctions.
- Nouvelle fonction `renderCourtEmptyState()` — message affiché à la place des étiquettes joueurs quand `roster.length===0` (spec : `docs/design/terrain-joueurs.md` section 1, style : `docs/visual/terrain-joueurs.md` section 2).
- Le terrain (fond/lignes) reste affiché même vide — seul le contenu joueurs disparaît.

## Critères d'acceptation

- [x] Avec 0 joueur sélectionné pour une équipe, le terrain de l'écran Match n'affiche aucune étiquette joueur, avec le message d'état vide visible.
- [x] Même comportement sur les sélecteurs PD (passe décisive) et 2min/carton — **les deux testés indépendamment** (ce sont deux fonctions distinctes, `renderPdSelect()` et `renderPlayerSelect()` — correction d'une première hypothèse erronée qui les pensait partagées). PD confirmé (`75-story20-pdselect-empty-fixed.png`), 2min confirmé via un vrai clic sur le badge (`76-story20-2min-select-empty.png`).
- [x] Avec au moins 1 joueur sélectionné, seuls les joueurs sélectionnés apparaissent (pas les autres) — confirmé avec 3 joueurs sélectionnés sur 22.
- [x] Le message d'état vide est visible et compréhensible sans explication — corrigé en cours de route (contraste illisible sur le fond clair actuel, voir notes Developer).

## Hors scope

- Le rendu visuel du terrain lui-même (traité dans STORY-22).
- Un lien de navigation direct depuis le message vers l'écran Équipes (texte seul pour cette story).

## Dépend de

Aucune.

## Taille

S

## Notes du Developer (implémentation livrée le 2026-07-28)

**Bug corrigé exactement comme diagnostiqué** : suppression de `if(roster.length===0) roster=S[team].players;` dans les 3 fonctions (`renderMatchPanel`, `renderPdSelect`, `renderPlayerSelect`). Nouvelle fonction `renderCourtEmptyState()` affichée à la place des étiquettes joueurs quand le roster filtré est vide.

**Bug trouvé et corrigé en vérifiant visuellement (pas seulement en lisant le CSS)** : le premier essai du message d'état vide (couleur `--t3`, pensée pour un fond sombre) était **illisible** sur le fond actuel du terrain, qui est encore l'ancienne image claire (`COURT_IMG`, remplacée seulement en STORY-22). Corrigé en donnant à chaque ligne de texte un fond sombre semi-transparent en forme de pastille (`rgba(15,25,35,.85)`) — lisible aussi bien sur ce fond clair actuel que sur le futur fond SVG sombre de STORY-22.

**Vérifié par mesure DOM réelle** (pas seulement visuel) :
- 0 joueur sélectionné → 0 `.cp-player` affiché, message d'état vide présent (`docs/design/screenshots/73-story20-empty-court-fixed.png`).
- 3 joueurs sélectionnés → exactement 3 `.cp-player` affichés, aucun autre (`74-story20-3players-fixed.png`).
- Sélecteur PD (passe décisive) → même comportement vide confirmé indépendamment (`75-story20-pdselect-empty-fixed.png`), pas seulement l'écran Match.

**Fichiers modifiés** : `app.js` (3 fonctions + nouvelle `renderCourtEmptyState()`), `style.css` (`.court-empty-msg`), `sw.js` (v54→v55). Vérifié avec `new Function()` avant livraison (convention du projet).

**Changement de comportement à communiquer à Romain** : comme anticipé par le Risk Analyst, si aucun effectif n'est sélectionné pour un match (ce qui était son cas dans la capture d'écran d'origine), le terrain sera maintenant vide avec le message "Aucun joueur sélectionné" au lieu d'afficher tout le roster par défaut.
