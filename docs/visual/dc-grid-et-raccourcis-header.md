# Visual — Grille DC sur le terrain + Raccourcis en-tête

## F1 — Grille DC
Aucune nouvelle surface visuelle : les étiquettes joueurs DC utilisent le même style que tous les autres postes (`cpBoxStyle()`, déjà validé). Ce correctif est une repositionnement, pas un nouveau composant — rien à spécifier ici.

## F2 — Raccourcis en-tête

### Base : réutilise `.btn`/`.btn-xs`, pas de nouvelle classe de composant
Les deux raccourcis sont des pilules `.btn.btn-xs` (`style.css:98,106` — `padding:4px 10px;font-size:12px;border-radius:var(--r2);border:1.5px solid ...`), la variante la plus compacte déjà définie dans le design system, cohérente avec le besoin de rester discret à côté de la nav.

### Raccourci Mode (`⚡`/`🎯`)
- Icône seule (pas de texte), `font-size:15px` (légèrement plus grand que le texte environnant pour rester identifiable en un coup d'œil, cohérent avec `.ah-icon` ailleurs dans l'app)
- Couleur : `var(--fenix-sky)` quel que soit l'état (Simple ou Expert) — c'est le symbole (⚡ vs 🎯) qui porte l'information, pas la couleur (contrairement au Suivi GB, qui est binaire actif/inactif)
- Bordure : `1.5px solid rgba(95,168,211,.35)`, fond `rgba(95,168,211,.08)` — pilule discrète mais visible, cohérente avec la teinte FENIX générale de l'en-tête (`.logo h1` est déjà `var(--fenix-sky)`)
- `:active` : `transform:scale(.94)` (déjà le comportement standard `.btn:active`, hérité automatiquement)

### Raccourci Suivi GB (`🧤`)
Reprend exactement la logique de couleur déjà en place pour les 2 toggles existants (`app.js:1930` et `:2316`), transposée en version compacte :
- **Actif** : `border-color:var(--fenix-sky)`, `background:rgba(95,168,211,.15)`, `color:var(--fenix-sky)`
- **Inactif** : `border-color:var(--border)`, `background:transparent`, `color:var(--t3)`
- Sur écran large (>700px) : icône 🧤 + texte "ON"/"OFF", `font-size:11px;font-weight:700`
- Sous 700px : icône seule (le texte "ON"/"OFF" est retiré du DOM, pas juste caché en CSS — cohérent avec `.logo small{display:none}` qui fait déjà disparaître un texte secondaire à cette largeur plutôt que de le comprimer illisible)

### Espacement dans l'en-tête
`gap:6px` entre le logo et les deux raccourcis, `gap:6px` entre les deux raccourcis eux-mêmes, `margin-left:8px` sur le premier raccourci (léger décollement du logo, sans les coller). Les deux raccourcis et `#settings-btn` (quand il est visible, en match actif) coexistent dans le même groupe `flex-shrink:0` — jamais de superposition entre eux, `#settings-btn` vient toujours après les deux nouveaux raccourcis dans l'ordre visuel (Mode → Suivi GB → Réglages), les trois avant la nav.

### Contraste
Aucune nouvelle combinaison de couleurs — `var(--fenix-sky)` sur fond carte et `var(--t3)` sur fond carte sont déjà validés ailleurs dans l'app (pastilles GB, bandeau warning). Rien à revérifier.

### Micro-animation
`transition:all .15s` (déjà la transition standard `.btn`, héritée) — aucune animation supplémentaire, le changement d'état (couleur/icône) doit être perçu comme instantané, cohérent avec l'esprit "raccourci rapide" de la demande.
