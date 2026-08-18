# STORY-57 — Le scroll remonte en haut à chaque sélection de joueur

**En tant que** Romain,
**Je veux** que la liste reste où j'étais quand je sélectionne un joueur,
**Afin de** ne pas devoir refaire défiler toute la liste à chaque joueur sélectionné.

"Quand je fais défiler pour sélectionner les joueurs qui vont jouer et que je suis descendu bas, une fois cliqué sur le joueur, l'écran repasse sur le haut et il faut refaire défiler."

## Root cause
En paysage tablette/desktop (`@media (orientation:landscape) and (min-width:700px)`, cf. STORY-08), `body{overflow:hidden}` et `#app{overflow-y:auto}` font de `#app` lui-même le conteneur de scroll réel — pas `window`. `R()` ne capturait/restaurait que `window.scrollY` (et le scroll du panneau `.feed`) : à chaque re-rendu (chaque clic de sélection déclenche `R()`), `#app` est remplacé par un nouveau nœud (`cloneNode`+`replaceChild`, pattern "double-buffer" existant) qui démarre toujours à `scrollTop:0`, et rien ne le corrigeait ensuite. En portrait/téléphone, `window`/`body` défile normalement, donc le bug n'était pas visible dans ce mode (explique pourquoi il n'avait pas été détecté avant — probablement jamais testé longuement en paysage tablette avec un effectif assez long pour déborder, un cas devenu bien plus fréquent depuis STORY-56, 22 joueurs FENIX CF chargés d'un coup).

## Fix
`R()` capture désormais aussi `app.scrollTop` avant le swap et le restaure sur le nouveau nœud après (même schéma que `feedScroll` déjà existant pour `.feed`). Capturer/restaurer `window.scrollY` **et** `app.scrollTop` simultanément est sans risque quel que soit le mode : celui qui n'est pas le vrai conteneur de scroll dans le mode courant vaut déjà 0 des deux côtés.

## Vérifié par CDP
- **Paysage ≥700px** (1024×700, layout confirmé : `body{overflow:hidden}`, `#app{overflow-y:auto}`) : `#app` scrollé à 1078px, clic sur le dernier joueur de la liste (effectif FENIX CF complet, 22 joueurs) → `#app.scrollTop` toujours à 1078px après le re-rendu (avant le fix : retombait à 0).
- **Portrait/téléphone** (390×844) : `window.scrollY` scrollé à 1631px, même clic → toujours à 1631px après (non régressé).

## Taille
XS — 3 lignes ajoutées à `R()`, aucun autre fichier touché.
