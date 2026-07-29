# Visual — Mode Simple / Mode Expert

## Palette de tokens
Réutilise la palette existante — pas de nouvelle teinte pour rester cohérent avec l'identité déjà posée (STORY-04/05) :
- Sélection du bloc de mode actif : `border-color: var(--fenix-sky)` + `background: rgba(95,168,211,.15)` + `box-shadow: 0 0 14px rgba(var(--accent-rgb),.22)` — exactement le traitement déjà utilisé pour `.act-h.selected`, pour que le choix de mode ressemble visuellement à un choix d'action déjà familier.
- Bloc non-sélectionné : `border: 1.5px solid var(--border)`, `background: rgba(255,255,255,.04)` — identique au `.act-h` non sélectionné.
- Indicateur de mode actif (badge pendant la saisie) : `background: rgba(240,199,94,.12); border: 1.5px solid var(--yellow)` — même traitement que le badge "🎯 MODE PENALTY" déjà existant (`ml-status`), pour que l'utilisateur associe déjà ce style à "un mode spécial est actif, sois attentif".

## Typographie
- Titre du bloc de mode ("⚡ SIMPLE" / "🎯 EXPERT") : 14px, weight 800, uppercase, letter-spacing .05em — identique à `.ah-label` niveau `xl`.
- Sous-texte descriptif ("Score + buts rapide") : 11px, weight 500, `color: var(--t3)` — ton discret, ne doit pas concurrencer le titre.
- Badge indicateur de mode actif : 10px, weight 700, letter-spacing .06em, uppercase — identique au badge PENALTY existant.

## Ombres & effets
- Bloc de mode sélectionné : reprend `--shadow-accent` (déjà défini dans `:root` depuis STORY-04) plutôt que d'inventer un nouvel effet — cohérence transverse.
- Pas de glassmorphism ni d'effet nouveau ici : ce composant doit se fondre dans le langage visuel déjà établi, pas ouvrir un nouveau style.

## États interactifs
- `:active` sur un bloc de mode non sélectionné : `transform: scale(.96); background: rgba(255,255,255,.09)` — identique à `.act-h:active`.
- `:focus-visible` : `outline: 2px solid var(--accent); outline-offset: 2px` — reprend la règle globale déjà posée en STORY-05, pas de règle spécifique à écrire.
- Transition de sélection : `transition: all .13s` — même timing que `.act-h`, pour que le choix de mode ait le même "feel" tactile que le reste de l'app.

## Micro-animations
- Aucune animation nouvelle nécessaire — le changement de mode n'est pas un événement fréquent (une fois par appareil, rarement en cours de match), inventer une transition dédiée serait un effort visuel disproportionné par rapport à sa fréquence d'usage. Le `transition: all .13s` déjà standard suffit pour l'état actif/inactif.
- Popup de confirmation (bascule Expert → Simple en cours de match) : réutilise le style déjà existant des `showConfirm()`/modals de l'app (cf. `safeConfirm()`), pas de nouveau composant modal.

## Checklist contraste WCAG
- Texte `var(--t3)` sur fond `--bg` : déjà validé ailleurs dans l'app (utilisé pour tous les sous-textes existants) — pas de nouveau risque introduit.
- Badge jaune (`var(--yellow)` sur `rgba(240,199,94,.12)`) : déjà en production pour le badge PENALTY, contraste déjà accepté.
- Aucune nouvelle combinaison couleur/fond n'est introduite par cette feature — c'est une réutilisation stricte de tokens déjà validés, donc pas de nouvel audit de contraste nécessaire.

## Note du Visual Crafter
Cette feature ne justifie aucun nouveau token ni nouvel effet : elle doit être **visuellement invisible en tant que "nouveauté"** — un utilisateur qui ouvre l'app doit sentir que le choix de mode a toujours fait partie du design, pas qu'il vient d'être ajouté par-dessus. La discipline ici est de résister à la tentation d'habiller ce nouveau composant différemment du reste de l'app.
