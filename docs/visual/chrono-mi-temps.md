# Visual — Chrono : temps mort et changement de mi-temps

*Produit par le Visual Crafter — squad build BMAD*
*S'appuie sur `docs/design/chrono-mi-temps.md`*

## Cadrage
Cette feature n'introduit **aucun nouveau composant visuel**. Elle réutilise trois briques déjà en production : `window.confirm()` (via `safeConfirm()`, non stylable, déjà accepté pour la bascule Expert→Simple), `showToast(msg, isAlert)` avec ses deux variantes déjà existantes (neutre / alerte critique), et les boutons `per-btn`/`t-toggle`/`.mlt-btn-tm` inchangés. Mon rôle ici se limite à trancher **quelle variante de toast** utiliser pour chaque nouveau message, pas à créer un nouveau style.

## Palette de tokens (réutilisée, aucune nouvelle valeur)
- **F5 — rappel gardiens** ("🧤 Pense à vérifier les gardiens !") : variante `isAlert:true` de `showToast()` — fond `rgba(232,70,90,.95)`, bordure `2px solid #FF3344`, 15px/weight 800. Même traitement que "Changez de GB !" déjà en production : c'est délibéré, ce message appartient à la même famille (alerte gardien), l'utilisateur doit le reconnaître instantanément comme faisant partie d'un groupe de messages déjà familier, pas comme une nouveauté.
- **F4 — confirmation de retour MT1** ("↩ Retour à la mi-temps 1 — chrono en pause à 12:34") : variante neutre de `showToast()` (`isAlert:false`) — fond `#1A2840`, bordure `1px solid #7BA7C2`, 13px/weight 400. C'est un accusé de réception d'une action volontaire, pas une alerte — ne doit pas entrer dans l'historique des 3 dernières alertes critiques (STORY-63), qui doit rester réservé aux vrais signaux d'attention (TM conseillé, changez de GB, ce nouveau rappel gardien F5).
- **Bouton `per-btn`** : aucun changement visuel dans les deux états MT1/MT2 — la classe `.due` (pulsation jaune `var(--yellow)`) reste exclusivement pilotée par `checkHalfTimeReminder()`, sans interaction avec cette feature.
- **Bouton `.mlt-btn-tm`** : aucun changement — le retour visuel du temps mort passe uniquement par l'état du bouton `t-toggle` (▶/⏸), pas par une nouvelle couleur sur le bouton TM lui-même.

## États interactifs
- `t-toggle` en état "pause" suite à un TM : identique pixel pour pixel à un arrêt manuel — aucune variante visuelle spécifique à créer pour distinguer "pausé par TM" de "pausé manuellement" (le PRD ne le demande pas, et ça ajouterait un signal sans valeur d'usage réelle en plein match).

## Micro-animations
Aucune nécessaire. `window.confirm()` utilise l'animation native du navigateur (hors contrôle CSS de l'app) ; les deux toasts réutilisent le fade-out déjà en place (`opacity` + `transition .3s`, 2.5s neutre / 4s alerte) — cohérent avec tous les toasts existants, pas de nouveau timing à justifier.

## Checklist contraste WCAG
Aucune nouvelle combinaison couleur/fond : les deux variantes de toast (`isAlert:true`/`false`) sont déjà en production et déjà validées ailleurs dans l'app (rappels TM, alertes GB). Rien à ré-auditer.

## Note du Visual Crafter
Le seul risque visuel réel ici n'est pas esthétique mais **fonctionnel** : `safeConfirm()` s'appuie sur `window.confirm()`, dont le texte et les deux boutons ne sont pas stylables — c'est le Designer qui porte la responsabilité de rendre les deux messages (MT1→MT2 vs MT2→MT1) distinguables **par le texte seul**, pas par la couleur, puisque je n'ai aucune prise dessus. Je valide que le texte proposé par le Designer (verbes différents : "Oui, MT2" / "Oui, MT1", jamais un "OK" générique) suffit à cette distinction sans intervention visuelle de ma part.
