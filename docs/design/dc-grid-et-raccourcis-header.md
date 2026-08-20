# Design — Grille DC sur le terrain + Raccourcis en-tête

## F1 — Disposition en grille pour DC

### Avant (aujourd'hui, 5 joueurs DC sélectionnés)
```
┌─────────────────────────────┐
│           (but)              │
│  ALG              ALD        │
│                               │
│           PVT (grille)       │
│                               │
│  ARG                   ARD   │
│                               │
│      [J][I][L][A][A]  ← 5 étiquettes DC empilées/collées
│      (chevauchement, illisible)
└─────────────────────────────┘
```

### Après (grille 2 rangées, cohérente avec la grille PVT déjà existante)
```
┌─────────────────────────────┐
│           (but)              │
│  ALG              ALD        │
│                               │
│           PVT (grille)       │
│                               │
│  ARG                   ARD   │
│                               │
│      [Jules.G] [Issa.S] [Leni.A]   ← rangée du haut (3)
│         [Lucas.G]  [Antonin.V]     ← rangée du bas (2)
└─────────────────────────────┘
```
- Reste centré sur l'axe horizontal du terrain (x:50, inchangé), **derrière** la ligne ARG/ARD comme aujourd'hui — aucune confusion possible avec ces deux postes qui restent ancrés sur les côtés (x:0/x:100).
- 2 rangées plutôt que 3 (le fallback générique actuel du code produirait 3 rangées de 2/2/1 pour 5 joueurs) : plus compact verticalement, tient mieux dans la marge réduite disponible à cette position basse du terrain. Décision technique exacte (nouvelle disposition dédiée à 5 vs ajustement des paramètres du fallback générique) laissée à l'Architect.
- À 1, 2, 3 ou 4 joueurs DC sélectionnés : dispositions déjà couvertes par le mécanisme `spread:"grid"` existant (1 seul joueur au centre, 2/3/4 déjà gérés par les layouts existants réutilisés tels quels pour PVT) — DC en hérite automatiquement en adoptant le même type de spread.

### États
- Aucun nouvel état — le rendu est purement dérivé du nombre de joueurs DC sélectionnés, comme c'est déjà le cas pour PVT.

### Responsive
Le terrain se redimensionne déjà de façon responsive (STORY-22/38) — la grille DC en hérite automatiquement, aucun nouveau point de rupture à définir.

## F2 — Raccourcis Mode et Suivi GB dans l'en-tête

### Maquette — en-tête, écran large (desktop/iPad paysage)
```
┌──────────────────────────────────────────────────────────────────┐
│ [logo] CF FENIX STAT      [⚡] [🧤 ON]   [Équipes][Match][Stats]...│
│        TOULOUSE HANDBALL                                          │
└──────────────────────────────────────────────────────────────────┘
```
- `[⚡]` : raccourci Mode — icône seule, ⚡ si Mode Simple actif, 🎯 si Mode Expert actif (reprend les icônes déjà utilisées par `renderModeToggle()`, pas de nouveau symbole à apprendre). Un tap bascule directement vers l'autre mode (pas de sous-menu à ouvrir) — cohérent avec l'esprit "raccourci en un geste" demandé par Romain.
- `[🧤 ON]` / `[🧤 OFF]` : raccourci Suivi GB — icône 🧤 (déjà associée au gardien partout dans l'app) + état textuel court "ON"/"OFF", coloré selon l'état (bleu FENIX si actif, gris neutre si inactif) — reprend le code couleur déjà utilisé par les deux toggles existants (Équipes, Réglages).
- Les deux raccourcis suivent le même pattern visuel que `#settings-btn` déjà existant (`flex-shrink:0`, pilule compacte) — pas un nouveau langage visuel.

### Maquette — en-tête, iPhone étroit (≤700px, portrait)
```
┌───────────────────────────────┐
│ [●]FENIX  [⚡][🧤]  Équipes▸...│
└───────────────────────────────┘
```
- Sous 700px, le libellé texte du raccourci Suivi GB ("ON"/"OFF") disparaît — icône seule, avec la couleur comme seul indicateur d'état (même traitement que `.logo small` qui disparaît déjà à cette largeur). Le raccourci Mode était déjà icône seule, inchangé.
- La nav (`.nav`) continue de défiler horizontalement comme aujourd'hui (STORY-18) — les 2 nouveaux raccourcis, en `flex-shrink:0` comme `#settings-btn`, ne rétrécissent jamais eux-mêmes ; c'est la nav qui absorbe l'espace restant et défile, exactement le mécanisme déjà en place pour `#settings-btn`.

### Interactions
- Tap sur `[⚡]`/`[🎯]` → appelle `setMode()` directement (pas de nouvelle logique) → si Mode Expert avec événements déjà saisis et qu'on bascule vers Simple, la confirmation bloquante déjà existante s'affiche, inchangée.
- Tap sur `[🧤]` → bascule `S.trackGK`, effet immédiat (aucune confirmation nécessaire, comme aujourd'hui).
- Les emplacements existants (Équipes, Réglages) restent fonctionnels et reflètent le même état — un changement depuis l'en-tête s'y reflète immédiatement au prochain rendu (c'est le même `S.mode`/`S.trackGK`, pas une copie).

### États
- Raccourci Mode : 2 états visuels (⚡ Simple / 🎯 Expert), toujours l'un ou l'autre, jamais un 3e état.
- Raccourci Suivi GB : 2 états visuels (ON coloré / OFF neutre).
- Écran d'accès (avant authentification) et écran de choix de profil : l'en-tête n'y est pas affiché (déjà le cas aujourd'hui), donc les raccourcis n'y apparaissent pas non plus — rien de spécial à gérer.

### Composants réutilisés vs nouveaux
- **Réutilisés** : icônes ⚡/🎯 (`renderModeToggle()`), icône 🧤 et code couleur (les deux toggles Suivi GB existants), pattern `flex-shrink:0` de `#settings-btn`, `setMode()`.
- **Nouveaux** : le rendu des deux boutons dans `renderHeader()` lui-même (markup + binding) — pas un nouveau composant visuel, une nouvelle instance des mêmes primitives.
