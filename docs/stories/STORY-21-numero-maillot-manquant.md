# STORY-21 — Numéro de maillot manquant sur le terrain

**En tant que** Romain,
**Je veux** qu'un joueur sans numéro de maillot enregistré n'affiche pas un "?" sur le terrain,
**Afin de** ne pas confondre une absence d'info avec un symbole d'erreur ou d'action à faire.

## Contexte technique

- Zone concernée : `app.js` — fonction `dn(p)` dupliquée 3 fois (`~ligne 1131, 1554, 1620`), à consolider en une seule fonction `displayNumber(p)` réutilisée partout.
- `displayNumber(p){ return p.number ? p.number : "–"; }` — tiret au lieu de "?", avec la classe `cp-num-missing` (opacité réduite, spec `docs/visual/terrain-joueurs.md` section 3) quand le numéro est absent.
- **Ne touche pas** au "?"/✏️ de `renderTeamSetup` (nom de joueur non renseigné, écran Équipes) — logique différente, à laisser intacte.

## Critères d'acceptation

- [x] Un joueur sans numéro affiche un tiret discret (pas un "?") sur toutes les vues de terrain (Match, sélection PD, sélection 2min/carton) — confirmé via mesure DOM (`.cp-num-missing` + texte "–").
- [x] Le style du tiret (opacité réduite) le distingue visuellement d'un vrai numéro.
- [x] Le "?"/✏️ de l'écran Équipes (nom de joueur non renseigné) reste inchangé — vérifié que c'est un `dn` différent (basé sur `p.name`, pas `p.number`), non touché.
- [x] Une seule fonction `displayNumber()` existe désormais (plus de duplication à 3 endroits).

## Hors scope

- Tout changement sur l'écran Équipes.

## Dépend de

Aucune.

## Taille

XS

## Notes du Developer (implémentation livrée le 2026-07-28)

**Consolidation faite comme prévu** : les 3 `const dn=(p)=>p.number?p.number:"?"` supprimées, remplacées par une fonction unique `displayNumber(p)` au niveau module, réutilisée dans `renderMatchPanel`, `renderPdSelect`, `renderPlayerSelect`. Classe `cp-num-missing` ajoutée conditionnellement.

**Vérification importante avant de toucher au code** : j'ai cherché s'il existait un 4e `dn` (dans `renderTeamSetup`, qui affiche aussi un "?") avant de commencer — c'est un `dn` **différent** (`p.number ? "#"+p.number+" " : ""`, sans "?"), et le "?" visible à cet endroit vient du **nom** du joueur (`p.name==="?"`), pas du numéro. Confirmé non concerné par cette story, non touché.

**Découverte en testant** : le roster par défaut (`DEFAULT_FENIX`) a `number:""` pour **tous** les joueurs — donc dans la capture d'écran d'origine de Romain, c'est bien tous les "?" qu'on voyait à cause de ça, pas un cas isolé. Le tiret discret remplace maintenant systématiquement ce "?" partout où le roster par défaut est utilisé sans numéros renseignés.

**Fichiers modifiés** : `app.js` (3 sites + nouvelle fonction `displayNumber()`), `style.css` (`.cp-num-missing`), `sw.js` (v55→v56). Vérifié avec `new Function()`.

**Vérifié visuellement** : `docs/design/screenshots/80-story21-missing-number.png` — tiret discret, plus de "?" alarmant.
