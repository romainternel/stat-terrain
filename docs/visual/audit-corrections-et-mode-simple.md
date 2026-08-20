# Visual — Corrections Audit Final + Mode Simple à équipe unique

F1 et F3 n'ont aucune surface visuelle nouvelle (voir Design) — ce document couvre F2 (historique des alertes) et F4 (Mode Simple à équipe unique).

## F2 — Historique des alertes critiques

### Palette de tokens (réutilise le système d'alerte jaune déjà établi, ne pas en créer un nouveau)
- Fond du bloc : `rgba(240,199,94,.12)` (identique à `launchWarnings()`/`.ap-badge-pen`)
- Bordure : `1.5px solid var(--yellow)` (`#F0C75E`)
- Texte : `var(--yellow)`, `font-weight:700` pour le titre "🔔 Dernières alertes", `font-weight:400` pour chaque ligne d'alerte (le titre doit dominer, pas les entrées)
- Séparateur visuel avec le bandeau GB au-dessus (s'il est aussi présent) : `margin-top:6px`, pas de bordure dupliquée — même rythme d'empilement que deux `.ap-badge-pen` consécutifs

### Horodatage
`font-size:10px;color:var(--t2);` (couleur de texte secondaire déjà utilisée pour les sous-titres partout ailleurs, ex. `.logo small`) — l'heure ne doit jamais concurrencer visuellement le texte de l'alerte elle-même.

### Pastille réduite `[🔔3]`
Même traitement que la pastille GB réduite (`[–]` à côté de "⚙ Réglages") :
- `width:26px;height:26px;border-radius:50%;border:1.5px solid var(--yellow);background:rgba(240,199,94,.15);color:var(--yellow);font-size:13px;` — c'est la spec exacte déjà utilisée pour ce type de pastille (`style.css` ligne ~581), à reprendre à l'identique pour la cohérence, pas à réinventer.
- Le chiffre (nombre d'alertes) prend la place de l'icône dans la pastille, en `font-weight:800`.

### Micro-animation
Une nouvelle entrée qui apparaît en haut de la liste : `animation:fadeIn .25s ease-out` (keyframe déjà existant dans `style.css`, `@keyframes fadeIn{from{opacity:0;transform:translateY(-5px);}...}`, déjà utilisé ailleurs — pas de nouveau keyframe à écrire). Aucune animation sur les entrées qui décalent vers le bas ou qui sortent de la liste (au-delà de 3) — un `fadeOut` sur une ligne qui disparaît serait plus de mouvement que ce contexte (plein match, attention limitée) ne peut se permettre.

### Contraste
Jaune `#F0C75E` sur fond carte `rgba(255,255,255,.04)` sur `--bg:#0F1923` : déjà validé dans le reste de l'app (bandeau GB, badges pénalty) — aucune nouvelle vérification WCAG nécessaire, c'est le même texte sur le même type de fond.

## F4 — Mode Simple à équipe unique

### Indicateur de possession sur le libellé d'équipe
Reprend exactement le traitement déjà utilisé pour `.mlt-poss-home.mlt-poss-active`/`.mlt-poss-away.mlt-poss-active` (le glow de la pastille POSSESSION du scoreboard), appliqué au point `●` devant le nom d'équipe dans `renderMatchSimple()` :
- FENIX en possession : `color:var(--fenix-sky); text-shadow:0 0 8px rgba(95,168,211,.7);`
- Adversaire en possession : `color:var(--red); text-shadow:0 0 8px rgba(232,70,90,.7);`
(glow réduit de moitié par rapport à la pastille scoreboard — `14px` → `8px` — car c'est un indicateur secondaire ici, le vrai focus reste les boutons)

### Transition au changement de possession
Le bloc entier (libellé + boutons) se redessine avec la couleur de la nouvelle équipe active. Pour éviter un changement de couleur trop brutal (le bloc change de bleu à rouge à chaque but, potentiellement plusieurs fois par minute en fin de match serré) :
- `transition:color .15s ease-out` sur le libellé et les icônes/labels de boutons (`.ah-icon`, `.ah-label`, déjà stylées inline via `color:${accent}` — passer cet accent par une variable CSS transposable en transition plutôt qu'un style inline recalculé à chaque render, si le Developer juge que c'est faisable sans complexifier `R()`)
- Le flash de confirmation (`.simple-flash`, `simple-flash-pop .4s ease-out`) reste strictement inchangé — il s'exécute sur le bouton cliqué juste avant la bascule de couleur, les deux ne doivent pas se chevaucher visuellement de façon confuse (le flash dure 400ms, la transition de couleur 150ms — le flash reste dominant, cohérent avec son rôle de confirmation de clic)

### Disposition (mise à jour après retour de Romain)
Les 5 boutons (`BUT`/`ARRÊT`/`NON CADRÉ`/`PB`/`JET FRANC`) passent sur **une seule rangée**, dans le conteneur `.ml-actions` déjà utilisé par la barre Mode Expert (même classe, mêmes `.act-h` enfants, mêmes points de rupture responsive `style.css:787-804`) — pas un nouveau composant, une réutilisation directe. Aucune nouvelle règle CSS de disposition à écrire : `.ml-actions{display:flex;gap:5px;...}` et `.act-h{flex:1.4;...}` gèrent déjà le rétrécissement proportionnel sur téléphone. Le nom d'équipe (`● ${name}`) reste sur sa propre ligne, au-dessus de `.ml-actions`, dans le même bloc — jamais retiré, exigence explicite de Romain (pas seulement la couleur d'accent comme repère).

### États hover/active/focus
Aucun changement — `.act-h:active{transform:scale(.94);background:rgba(255,255,255,.09);}` déjà en place et suffisant, pas de nouvel état à définir puisque le bloc grisé non cliquable (`.simple-inactive`) disparaît structurellement (plus besoin de styler un état "grisé" puisqu'il n'existe plus).

## Checklist contraste
Aucune nouvelle combinaison de couleurs introduite — F2 et F4 réutilisent exclusivement des tokens et des glows déjà validés ailleurs dans l'application (`--yellow` pour les alertes, `--fenix-sky`/`--red` pour l'identité d'équipe). Rien à revalider au niveau WCAG.
