# Visual Crafter — Détail joueur au format compact

Le Design réutilise déjà des classes visuellement abouties (`.gk-sheet-body`, `.gk-lvl1/2`, `.gk-pill`, `.overlay`) — mon rôle ici est de polir les points de jonction que cette réutilisation crée, pas de redessiner l'existant.

## Transition d'ouverture
`.overlay` (réutilisé de `renderShotOverlay()`) n'a aujourd'hui aucune animation d'entrée — apparition instantanée. Pour une **fenêtre modale** (contrairement à l'overlay plein écran qu'elle remplace, où l'effet de "prise de tout l'écran" masquait l'absence de transition), l'apparition instantanée d'une petite carte au milieu de l'écran est plus visible et peut sembler abrupte. Ajout ciblé, uniquement sur `.pd-modal` (ne touche pas `.shot-modal`/`.overlay` pour ne rien changer ailleurs) :
```css
.pd-modal{ animation: pd-modal-in .18s ease-out; }
@keyframes pd-modal-in{ from{ opacity:0; transform:scale(.96); } to{ opacity:1; transform:scale(1); } }
@media (prefers-reduced-motion: reduce){ .pd-modal{ animation:none; } }
```

## Cohérence des pills BUTS/PD vs le reste de l'app
Le Design assigne PD en jaune (`--yellow`) — à vérifier au moment du montage que la variable `--gk-pill-rgb` inline (déjà utilisée en style attribute par `renderGkSheet()`, ex. `style="--gk-pill-rgb:80,200,120;"`) est bien fixée à la valeur RGB du jaune FENIX (`--yellow: #F0C75E` → `240,199,94`) et pas laissée à la valeur verte par défaut copiée-collée de Gardien — piège de recopie facile puisque le composant pill est repris tel quel.

## Bordure/ombre de la carte
`.gk-sheet` a une bordure teintée par équipe (`--gk-accent-rgb`, vert FENIX ou rouge adversaire) — `.pd-modal` doit reprendre ce même principe (`--gk-accent-rgb` fixé selon `pd.side`, exactement comme `renderGkSheet(side)` le fait déjà) plutôt qu'une bordure neutre `var(--border)` uniforme — pour que l'identité visuelle équipe (déjà utilisée pour le nom du joueur en haut) se retrouve aussi sur le cadre de la carte, cohérent avec Gardiens.

## Scrollbar interne (`max-height:90vh;overflow-y:auto`)
Rare en usage normal iPad (le contenu tient sans scroll), mais si le cas se présente sur iPhone portrait étroit, s'assurer que le scroll interne n'entre pas en conflit visuel avec le scroll de la page en dessous (`.overlay` bloque déjà l'interaction avec l'arrière-plan, donc pas de risque de double-scroll confus — juste vérifier au montage qu'aucun `overflow:hidden` du body ne manque pendant que la modale est ouverte, comme c'est déjà le cas pour les autres `.overlay` de l'app).

## Ce qui reste identique, volontairement
Palette, typographie, icônes, style des boutons ✕/toggle — aucune retouche, la carte Gardien sert déjà de référence visuelle validée par plusieurs cycles de QA (STORY-30, STORY-43).
