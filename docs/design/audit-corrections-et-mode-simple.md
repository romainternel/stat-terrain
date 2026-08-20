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

### Choix retenu (mis à jour après retour de Romain)
Clarification de Romain : pas forcément tout sur une seule rangée dans l'absolu ("sur tél c'est mieux mais sur tablette et iPad je sais pas") — et il tient explicitement à garder **le nom de l'équipe affiché au-dessus des boutons**, pas seulement la surbrillance/couleur de possession comme seul repère.

Plutôt que d'inventer une nouvelle logique de rupture responsive (1 rangée sur téléphone / 2 rangées sur tablette, avec un seuil arbitraire à maintenir), la disposition retenue **réutilise telle quelle la barre d'actions du Mode Expert** (`.ml-actions`/`.act-h`, `app.js` fonction `renderMatchPanel()`/zone `.ml-actions`) : ces boutons sont **déjà** sur une seule rangée flex, **déjà** responsive (rétrécissement de padding/icônes en paysage iPhone ≤932px, `style.css:787-804`), et **déjà** validés en conditions réelles sur iPhone et iPad pour 6 boutons (BUT/ARRÊT/NON CADRÉ/PB/PO/JET FRANC). Le Mode Simple n'a besoin que de 5 boutons (pas de PO) — donc structurellement moins serré que la barre Expert déjà éprouvée. Répond aux deux retours à la fois : compact sur téléphone (une seule rangée, comme demandé), confortable sur tablette/iPad (la même rangée, juste avec plus d'air), sans code responsive supplémentaire à écrire ni à tester séparément.

Le nom de l'équipe reste affiché en toutes lettres au-dessus de cette rangée, dans tous les cas — la surbrillance de couleur est un **renfort**, jamais un remplacement du texte.

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

**Après (1 seul bloc, une seule rangée de 5 boutons, libellé dynamique) :**
```
┌───────────────────────────────────────────┐
│  ⚡ MODE SIMPLE ACTIF                      │
├───────────────────────────────────────────┤
│  ● FENIX TOULOUSE            (en possession)
│  [BUT] [ARRÊT] [NON CADRÉ] [PB] [JET FRANC]│
└───────────────────────────────────────────┘
```
Après un but (possession bascule vers l'Adversaire) :
```
┌───────────────────────────────────────────┐
│  ⚡ MODE SIMPLE ACTIF                      │
├───────────────────────────────────────────┤
│  ● AUDIT TEST                (en possession)
│  [but] [arrêt] [non cadré] [pb] [jet franc]│
└───────────────────────────────────────────┘
```
Sur téléphone (viewport étroit), la même rangée se comprime automatiquement via les points de rupture déjà existants de `.act-h` (icônes/padding réduits) — pas une disposition différente, la même barre qui rétrécit, exactement comme la barre Mode Expert le fait déjà aujourd'hui.

- Le **nom de l'équipe reste écrit en toutes lettres** au-dessus des boutons dans tous les cas — exigence explicite de Romain, pas seulement la couleur/surbrillance.
- Le point `●` devant le nom d'équipe reprend le code couleur déjà utilisé pour la pastille "◉ POSSESSION" du scoreboard (renfort visuel en plus du texte, pas à la place).
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
Double gain, sur deux axes différents :
- **Vertical** (un seul bloc au lieu de deux empilés) : profite à tous les viewports, mais surtout à iPhone portrait où l'écran Match Mode Simple nécessitait un peu de scroll avec deux équipes empilées.
- **Horizontal** (rangée unique de 5 boutons au lieu de 3+2) : en réutilisant `.act-h`/`.ml-actions`, hérite gratuitement des points de rupture déjà validés pour la barre Mode Expert (rétrécissement icônes/padding en paysage iPhone ≤932px, `style.css:787-804`) — pas de nouveau test responsive à concevoir, seulement à re-vérifier que 5 boutons Mode Simple se comportent aussi bien que les 6 boutons Mode Expert déjà éprouvés, sur les mêmes viewports historiques (390×844 portrait, paysage iPhone, iPad).

## Composants réutilisés vs nouveaux
- **Réutilisés** : `launchWarnings()`/pattern bandeau réductible (F2), `S.possession`/`S.simpleFlash`/couleurs d'équipe existantes (F4), liste d'insights `ANALYSE AUTOMATIQUE` existante (F3).
- **Nouveaux** : stockage en mémoire des 3 dernières alertes (F2, pas de composant visuel nouveau — juste plus de contenu dans un composant existant) ; fonction `simpleBtn`/`teamRow` de `renderMatchSimple()` à restructurer pour n'émettre qu'un seul bloc (F4, refactor interne, pas un nouveau composant visuel).
