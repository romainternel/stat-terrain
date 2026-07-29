# Design — Mode Simple / Mode Expert

## Principe UX
Le mode Simple n'est pas un "Expert allégé visuellement" — c'est un **écran Match différent**, avec des actions qui s'auto-valident sans étape intermédiaire (pas de terrain, pas de zone). L'utilisateur non-expert ne doit jamais voir un écran qui suggère qu'il "manque une étape" (ex : un terrain vide qui attend un clic qu'il ne comprend pas).

## Où se trouve le choix de mode
Pas d'écran "Réglages" dédié dans l'app actuelle (vérifié dans le code — seul un bouton ⚙ ouvre un panneau d'actions rapides en Match). Le toggle Simple/Expert suit donc le pattern déjà existant du toggle "🧤 Suivi GB" :
- **Écran Équipes** (avant de lancer le match) — emplacement principal, visible avant que la question se pose.
- **Panneau ⚙ Réglages en Match** — pour changer en cours de match (Should Have du PRD).

### Maquette — Écran Équipes, zone toggle de mode
```
┌─────────────────────────────────────────────────┐
│  🧤 Suivi gardien & zones de tir      [✓ Activé] │
├─────────────────────────────────────────────────┤
│  🎚 Mode de saisie                                │
│   ┌───────────────┐  ┌───────────────┐           │
│   │  ⚡ SIMPLE     │  │  🎯 EXPERT     │           │
│   │  Score + buts  │  │  Terrain, zones│  ← sélectionné (bordure accent)
│   │  rapide        │  │  PD, GB...     │           │
│   └───────────────┘  └───────────────┘           │
│   Sur iPhone, Simple est proposé par défaut.      │
└─────────────────────────────────────────────────┘
```
Deux blocs cliquables côte à côte (comme un choix binaire clair), pas un switch on/off ambigu — le mode Expert n'est pas "la valeur par défaut désactivée", les deux sont des choix égaux et nommés.

### Maquette — Panneau ⚙ Réglages (Match), ligne ajoutée
```
┌───────────────────────┐
│ 💾 Sauvegarder         │
│ 📤 Exporter            │
│ 📥 Importer            │
│ ✏️ Effectifs           │
│ 🎚 Mode : Expert  [⇄]  │  ← nouvelle ligne
│ 🆕 Nouveau match       │
│ ✕ Fermer               │
└───────────────────────┘
```

## Maquette — Écran Match en mode Simple
Comparé à l'écran Match actuel (Expert), tout ce qui suppose une expertise disparaît : pas de terrain, pas de sélection de joueur par clic, pas de zone de but, pas de PD, pas de PO/PEN.

```
┌──────────────────────────────────────────────────┐
│ CF FENIX STAT          [Équipes][Match][Stats]... │
├──────────────────────────────────────────────────┤
│  FENIX Toulouse                    2              │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐     │
│  │ ⚽ BUT  │ │🧤 ARRÊT │ │↗ NON   │ │⛔ 2 MIN │     │
│  │        │ │        │ │  CADRÉ │ │        │     │
│  └────────┘ └────────┘ └────────┘ └────────┘     │
│                                                    │
│         MT 1   00:00   [▶ Start] [↺]              │
│                                                    │
│  US Nantes Hb                       1             │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐     │
│  │ ⚽ BUT  │ │🧤 ARRÊT │ │↗ NON   │ │⛔ 2 MIN │     │
│  │        │ │        │ │  CADRÉ │ │        │     │
│  └────────┘ └────────┘ └────────┘ └────────┘     │
│                                                    │
│  [ Feed : dernier événement, annulable ]          │
└──────────────────────────────────────────────────┘
```

Différences structurelles clés vs Expert :
- Chaque bouton BUT/ARRÊT/NON CADRÉ **s'auto-valide au clic** — pas de sélection joueur, pas de terrain, pas de zone. L'action est directement au niveau équipe.
- Pas de possession à toggler séparément (le tap sur "BUT" de l'équipe X valide directement pour l'équipe X) — supprime une étape que l'aidant occasionnel pourrait mal comprendre (le workflow Expert actuel utilise la possession comme état implicite, ce qui suppose de comprendre le concept).
- 2 MIN et Carton Rouge restent (actions simples déjà auto-validées aujourd'hui côté sanctions, pas de changement de complexité).
- Pas de PB (Perte de balle), pas de PO/PEN, pas de Jet franc : ce sont des actions à plus faible valeur pour un suivi "score + tendance générale", et elles nécessitent souvent de comprendre le règlement pour bien les distinguer d'un tir raté classique.

## Interactions
- Tap sur BUT/ARRÊT/NON CADRÉ → auto-validation immédiate, incrémente le score/stat correspondant, ajoute un événement au feed (annulable comme aujourd'hui).
- Le feed reste identique (overlay glissant, clic pour éditer/annuler) — c'est un composant déjà partagé, pas dupliqué.
- Le timer, TM, changement de mi-temps : identiques à Expert (aucune raison de les simplifier, ils ne demandent pas d'expertise).

## États
- **Vide (avant le premier événement)** : identique à Expert, juste sans terrain à afficher.
- **Bascule Simple → Expert en cours de match** : les événements déjà saisis (avec x/y/goalZone null) restent affichés normalement dans le feed et les stats ; l'écran Match affiche alors le terrain complet pour la suite du match.
- **Bascule Expert → Simple en cours de match** : possible mais à confirmer par une popup ("Les prochains événements seront saisis sans terrain ni zone — continuer ?") pour éviter une bascule accidentelle qui ferait perdre en richesse le reste d'un match déjà commencé en détail.

## Responsive
- Le mode Simple est justement **plus** adapté à l'iPhone (moins de composants à faire tenir), donc les media queries iPhone existantes (STORY-02/03/18/19) s'appliquent moins ou pas du tout à cet écran simplifié — à vérifier par l'Architect si une variante spécifique est nécessaire ou si les règles génériques suffisent déjà.
- Sur iPad/desktop, le mode Simple garde la même disposition deux-colonnes (équipes à gauche, actions à droite) mais sans le panneau terrain à droite — l'espace libéré peut afficher le feed en plus grand ou rester simplement plus aéré.

## Composants réutilisés vs nouveaux
**Réutilisés** : `.ml-left` (bloc équipes/timer), `.ml-timer`, le feed d'événements, le panneau `.settings-panel`, le pattern de toggle `S.trackGK` (nouveau toggle `S.mode` suit la même mécanique).
**Nouveaux** : le bloc de choix de mode sur l'écran Équipes, la variante d'actions "auto-validation équipe" (4 boutons par équipe au lieu de la barre d'actions + terrain partagés), l'indicateur de mode actif.
