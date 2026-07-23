# Design — Écran Match, adaptation iPhone (F1)

*Produit par le Designer — squad build BMAD*
*S'appuie sur `docs/prd.md` (F1)*

## Contexte

L'écran Match actuel (`match-layout`) est une grille 2 colonnes (`240px 1fr`) : équipes + timer à gauche, actions + terrain à droite. Ce layout fonctionne bien sur iPad (large, souvent en paysage). Sur iPhone (largeur utile 375–430px en portrait), une colonne fixe de 240px ne laisse quasi plus de place pour le terrain — il faut repenser la hiérarchie, pas juste réduire les tailles.

**Principe directeur** : en match, l'œil de Romain doit rester sur le terrain réel. L'écran ne doit jamais lui demander de chercher un bouton — les zones les plus utilisées (actions, terrain) doivent être atteignables au pouce, sans naviguer.

## Maquette ASCII — iPhone portrait (≤430px)

```
┌───────────────────────────────────┐
│ FENIX  12    🕐 08:42     ADVERSE 8│  ← score condensé, 1 ligne
│ [GB: Dupont ▼]      [▼ GB: Martin] │
├───────────────────────────────────┤
│ [⏱ Start] [TM 1/2]  [2min] [🟥]    │  ← contrôles compacts, 1 ligne scroll-x si besoin
├───────────────────────────────────┤
│ BUT  TIR  HC   PB   PO  PEN  ⋯     │  ← actions : scroll horizontal si >5, jamais wrap
├───────────────────────────────────┤
│                                     │
│         [ TERRAIN JOUEURS ]        │  ← pleine largeur, priorité d'espace
│                                     │
│                                     │
├───────────────────────────────────┤
│ [📋 Feed]  [↩ Annuler]  [⚙]        │  ← contrôles bas, toujours visibles
└───────────────────────────────────┘
```

## Maquette ASCII — iPhone paysage (≤932px large, ~430px haut)

```
┌──────────┬──────────────────────────────┐
│ FENIX 12 │ BUT TIR HC PB PO PEN ⋯        │
│ 🕐 08:42 │ ┌───────────────────────────┐ │
│ ADV    8 │ │                           │ │
│──────────│ │      TERRAIN JOUEURS      │ │
│ TM 2min🟥│ │                           │ │
│          │ └───────────────────────────┘ │
│          │ [Feed] [Annuler] [⚙]          │
└──────────┴──────────────────────────────┘
```
Même logique qu'iPad (colonne gauche + terrain à droite) mais colonne gauche réduite à l'essentiel (score, timer, contrôles courts) — pas de place pour les stats GB détaillées visibles en continu comme sur iPad large.

## Interactions

- Le changement d'orientation ne doit jamais faire perdre l'action en cours de saisie (état `S` inchangé, seul le rendu change).
- Les boutons d'action passent en **scroll horizontal** plutôt qu'en retour à la ligne dès que la largeur ne suffit plus (garde la même hauteur d'écran utile pour le terrain).
- Le terrain garde toujours la priorité d'espace vertical restant après score/actions/contrôles bas.

## États

- **Pas de GB sélectionné** : le select GB reste visible et cliquable même en version compacte (ne pas le masquer pour gagner de la place — c'est une info nécessaire en direct).
- **Action en cours** (bouton sélectionné) : doit rester visible même si la barre d'actions scrolle — envisager un indicateur "action active : BUT" au-dessus du terrain si la barre défile hors-vue.
- **Alerte auto (TM conseillé, changez de GB)** : le toast existant (`showToast`) doit rester lisible en pleine largeur sur petit écran, pas tronqué.

## Responsive — règles de bascule

| Largeur viewport | Comportement |
|---|---|
| ≥700px (iPad portrait et plus) | Layout actuel inchangé (`240px 1fr` ou empilé selon orientation, sans changement) |
| <700px portrait (iPhone) | Layout vertical : score condensé → contrôles → actions (scroll-x) → terrain (priorité d'espace) → bas de page |
| <700px paysage (iPhone) | Colonne gauche réduite (score/timer/contrôles courts uniquement) + terrain à droite, sans le détail GB affiché sur iPad |

## Composants réutilisés vs nouveaux

- **Réutilisés tels quels** : `.act-h` (boutons d'action), `.court-pick` (terrain), `.mlt-*` (bloc équipe), `showToast`.
- **Nouveaux** : classes de layout conditionnelles pour le mode "iPhone compact" (`.match-layout.compact` ou équivalent média-query dédiée) — décision de nommage/implémentation laissée à l'Architect.
- **Modifié** : la barre d'actions doit gagner un mode scroll horizontal qu'elle n'a pas aujourd'hui (actuellement `flex-wrap` implicite via flex sans wrap, à vérifier avec l'Architect si un `overflow-x:auto` suffit ou s'il faut réordonner le HTML).
