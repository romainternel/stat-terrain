# Design — Corrections Audit Final + Mode Simple à équipe unique

## F1 — Sauvegarde idempotente
Aucun changement visuel. Le message de confirmation existant ("✅ Match sauvegardé !") reste identique — il continue de fonctionner à l'identique que ce soit une création ou une mise à jour, l'utilisateur n'a pas besoin de savoir laquelle des deux s'est produite.

## F3 — Garde-fou volume d'événements (Analyse)
Aucun nouveau composant. Sous le seuil retenu, les lignes d'insight qualitatif sont simplement absentes de la liste `ANALYSE AUTOMATIQUE` déjà existante (Stats → Analyse et Bilan → Analyse) — le résultat/score reste toujours en première ligne. Pas de message "pas assez de données" à afficher : une liste plus courte est auto-explicite, ajouter un texte d'excuse serait plus intrusif que le silence.

## F2 — Historique des alertes critiques

### Point d'ancrage
Réutilise le bandeau non-bloquant déjà en place pour le rappel GB/effectif (`launchWarnings()`, STORY-53) plutôt qu'un nouveau composant — même famille de pattern déjà connu de Romain (réductible en pastille `[–]`, fermable `[✕]`), simplement enrichi d'une deuxième source de contenu.

### Maquette — bandeau enrichi, état déplié (écran Match, dans le flux normal, sous le scoreboard)
```
┌───────────────────────────────────────────────────┐
│ ⚠️ À vérifier avant de commencer            [–][✕] │
│  • GB non sélectionné pour FENIX Toulouse          │
├───────────────────────────────────────────────────┤
│ 🔔 Dernières alertes                        [–][✕] │
│  • 21:04 · 🚨 5 buts encaissés de suite !          │
│  • 18:41 · 💡 3 buts encaissés de suite → TM ?     │
│  • 14:02 · 💡 TM conseillé (3 attaques sans marquer)│
└───────────────────────────────────────────────────┘
```
- Bloc "Dernières alertes" absent tant qu'aucune alerte n'a été déclenchée dans la session (pas de bloc vide à afficher — même logique que `launchWarnings()` qui n'affiche rien s'il n'y a rien à signaler).
- 3 entrées maximum, la plus récente en haut ; une 4e alerte fait disparaître la plus ancienne de la liste (pas d'historique illimité, cf. hors scope PRD).
- Chaque entrée : heure de match (`fmtTime`, cohérent avec le reste de l'appli) + icône + texte identique à celui du toast d'origine — aucune reformulation, l'utilisateur retrouve exactement ce qu'il a raté.
- `[–]` réduit vers une pastille à côté de "⚙ Réglages", comme le bandeau GB (même emplacement, une seconde pastille juste à côté si les deux bandeaux sont réduits en même temps) ; `[✕]` ferme définitivement pour la session, comme aujourd'hui.

### État réduit (les deux bandeaux repliés)
```
⚙ Réglages  [–]  [🔔3]
```
La pastille alertes affiche le nombre d'alertes reçues (badge numérique discret), pour rester visible sans reprendre l'espace du bandeau déplié.

### Responsive
Comportement identique au bandeau GB existant sur tous les viewports déjà couverts (iPhone portrait/paysage, iPad) — même conteneur, mêmes points de rupture, rien de nouveau à valider visuellement.

## F4 — Mode Simple : un seul jeu de boutons

### Choix retenu
Romain a dit "une seule ligne de bouton" — interprété comme **un seul jeu de boutons affiché à la fois**, pas une compression littérale des 5 boutons sur une seule rangée CSS (qui les rendrait trop petits pour un usage au doigt sur iPhone, à l'encontre du besoin exprimé). La disposition interne (3 boutons puis 2 en dessous) est conservée telle quelle — c'est la **duplication par équipe** qui disparaît, pas la disposition des boutons eux-mêmes. À confirmer avec Romain au moment de la revue de la story si ce n'est pas ce qu'il avait en tête.

### Maquette — avant/après

**Avant (aujourd'hui, 2 blocs empilés) :**
```
┌─────────────────────────────────┐
│  ⚡ MODE SIMPLE ACTIF            │
├─────────────────────────────────┤
│  FENIX TOULOUSE                  │
│  [BUT] [ARRÊT] [NON CADRÉ]      │
│  [PB]  [JET FRANC]              │
├─────────────────────────────────┤
│  AUDIT TEST                      │
│  [but] [arrêt] [non cadré]  ← grisés, non cliquables
│  [pb]  [jet franc]              │
└─────────────────────────────────┘
```

**Après (1 seul bloc, libellé dynamique) :**
```
┌─────────────────────────────────┐
│  ⚡ MODE SIMPLE ACTIF            │
├─────────────────────────────────┤
│  ● FENIX TOULOUSE  (en possession)
│  [BUT] [ARRÊT] [NON CADRÉ]      │
│  [PB]  [JET FRANC]              │
└─────────────────────────────────┘
```
Après un but (possession bascule vers l'Adversaire) :
```
┌─────────────────────────────────┐
│  ⚡ MODE SIMPLE ACTIF            │
├─────────────────────────────────┤
│  ● AUDIT TEST  (en possession)  │
│  [but] [arrêt] [non cadré]      │
│  [pb]  [jet franc]              │
└─────────────────────────────────┘
```
- Le point `●` devant le nom d'équipe reprend le code couleur déjà utilisé pour la pastille "◉ POSSESSION" du scoreboard (cohérence visuelle, pas un nouveau symbole à apprendre).
- Couleur d'accent des boutons = couleur de l'équipe active (bleu FENIX / rouge Adversaire), exactement comme aujourd'hui pour le bloc actif — la seule différence est que le bloc inactif ne s'affiche plus du tout, il ne devient pas "cliquable pour l'autre équipe" par erreur.
- Le flash de confirmation (`.simple-flash`) et le badge "⚡ MODE SIMPLE ACTIF" restent identiques.

### Interactions
- Taper un bouton enregistre l'action pour l'équipe affichée (= équipe en possession), puis la possession bascule (règle déjà existante, inchangée) — le bloc se redessine avec le nom/couleur de l'autre équipe pour l'action suivante, sans étape ni confirmation supplémentaire.
- Le bouton "◉ POSSESSION" du scoreboard (inchangé) reste le seul moyen de changer manuellement d'équipe active — utile en début de match ou pour corriger une perte de balle non taguée.
- Plus de toast d'erreur "impossible, l'autre équipe n'a pas la balle" en Mode Simple : ce cas devient structurellement impossible (il n'y a plus de bouton pour l'équipe qui n'a pas la balle à cliquer par erreur).

### États
- **Aucune possession définie** (tout début de match, avant le premier événement) : `S.possession` a déjà une valeur par défaut existante (cf. code) — le bloc affiche cette équipe par défaut, comme le fait déjà le scoreboard aujourd'hui. Pas de nouvel état "vide" à gérer.
- **Mode lecteur actif** : le bloc reste affiché en lecture seule, comme aujourd'hui pour l'écran Match complet — pas de changement de ce comportement.

### Responsive
Le gain d'espace vertical (un seul bloc au lieu de deux) profite directement au cas visé par Romain : iPhone portrait, où l'écran Match Mode Simple nécessitait un peu de scroll avec deux équipes empilées. À re-vérifier visuellement sur 390×844 une fois implémenté (même viewport que les vérifications historiques STORY-24).

## Composants réutilisés vs nouveaux
- **Réutilisés** : `launchWarnings()`/pattern bandeau réductible (F2), `S.possession`/`S.simpleFlash`/couleurs d'équipe existantes (F4), liste d'insights `ANALYSE AUTOMATIQUE` existante (F3).
- **Nouveaux** : stockage en mémoire des 3 dernières alertes (F2, pas de composant visuel nouveau — juste plus de contenu dans un composant existant) ; fonction `simpleBtn`/`teamRow` de `renderMatchSimple()` à restructurer pour n'émettre qu'un seul bloc (F4, refactor interne, pas un nouveau composant visuel).
