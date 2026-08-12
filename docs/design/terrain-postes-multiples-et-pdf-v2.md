# Design — Terrain à effectif variable par poste + PDF v2 (itération 3)

## 1. Terrain — disposition Pivot à 3 et 4 joueurs

Référentiel inchangé : but en haut (y=0), y augmente vers le bas. Les encarts restent centrés horizontalement pour PVT (pas d'ancrage bord comme ALG/ARG) — seule la disposition relative change.

### 3 pivots — triangle (un devant, deux derrière)
Le joueur le plus proche du but (habitude tactique : celui qui reçoit le plus la balle en pivot central) est seul en haut, centré. Les deux autres sont en dessous, symétriques de part et d'autre.

```
                    (ligne 6m)
                       ╲___╱
              ┌──────────────────┐
              │   9 Dumas        │      ← y = base - décalage
              └──────────────────┘
   ┌──────────────────┐  ┌──────────────────┐
   │  14 Barbier       │  │  22 Petit         │   ← y = base + décalage
   └──────────────────┘  └──────────────────┘
```

### 4 pivots — carré (deux d'un côté, deux de l'autre)
Deux colonnes symétriques par rapport au centre du terrain, chaque colonne avec un joueur devant / un derrière.

```
                    (ligne 6m)
                       ╲___╱
   ┌──────────────┐          ┌──────────────┐
   │  9 Dumas      │          │  22 Petit     │   ← y = base - décalage
   └──────────────┘          └──────────────┘
   ┌──────────────┐          ┌──────────────┐
   │  14 Barbier   │          │  7 Roux       │   ← y = base + décalage
   └──────────────┘          └──────────────┘
```

### Comportement à 1 et 2 joueurs
Inchangé (déjà livré) : 1 joueur centré sur la position de base ; 2 joueurs côte à côte au même niveau de profondeur.

### 5+ joueurs (hors scope développement, comportement à garantir)
Pas de disposition dédiée. L'Architecture doit garantir que le mécanisme actuel (spread générique) continue de s'appliquer sans erreur JS et sans que les encarts sortent du cadre du terrain — un chevauchement resterait visuellement dégradé mais silencieux, jamais un plantage. Cas jugé non réaliste pour un effectif de handball (aucun poste n'aligne 5 joueurs en même temps sur un match) donc non prioritaire au-delà de cette garantie.

## 2. PDF — restructuration des pages

Nouvelle séquence de pages (le nombre exact de pages dépend toujours dynamiquement des données, comme aujourd'hui — la pagination "Page X/N" reste calculée après coup) :

```
Page 1 — COMPARATIF          (inchangée)
Page 2 — JOUEURS              (tableau FENIX + tableau ADVERSAIRE, inchangés dans leur contenu)
Page 3 — ÉVOLUTION DU SCORE   (NOUVEAU : sur sa propre page, ne dépend plus de la hauteur de la page 2)
Page 4+ — CARTE TIR JOUEUR    (FENIX puis ADVERSAIRE, conditionnelle si au moins un tir enregistré côté concerné)
Page N — GARDIENS             (inchangée)
```

### Page 3 — Évolution du score, seule sur sa page
```
┌──────────────────────────────────────────────────┐
│  ÉVOLUTION DU SCORE                    FENIX 8-3  │  ← pageHeader() inchangé
├──────────────────────────────────────────────────┤
│                                                    │
│   ┌────────────────────────────────────────┐     │
│   │  4 ●\                                   │     │
│   │  3  \___●                               │     │
│   │  2      \___●                           │     │
│   │  1           \___●                      │     │
│   │  0'    10'   20'   30'   40'   50'  60' │     │
│   └────────────────────────────────────────┘     │
│                                                    │
│              (page dédiée : plus de contrainte    │
│               de hauteur héritée du tableau)      │
│                                                    │
└──────────────────────────────────────────────────┘
```
Toute la place de la page est disponible — le graphique peut rester à sa taille actuelle (55mm de haut) sans risque, avec une marge de sécurité large avant le pied de page.

### Page 4+ — Carte tir joueur, FENIX puis ADVERSAIRE
Même schéma que la page Joueurs (titre de section coloré au-dessus de chaque groupe, sur le modèle déjà en place pour les tableaux) :
```
┌──────────────────────────────────────────────────┐
│  CARTE TIR JOUEUR                      FENIX 8-3  │
├──────────────────────────────────────────────────┤
│  FENIX                                            │
│  ┌───────────────────┐  ┌───────────────────┐    │
│  │ #4 Girard          │  │ #15 Roche          │    │
│  │ [terrain] [impact]  │  │ [terrain] [impact]  │    │
│  └───────────────────┘  └───────────────────┘    │
│  ┌───────────────────┐                            │
│  │ #10 Bouvier         │        ← ligne à 1 seule   │
│  │ [terrain] [impact]  │          carte : CENTRÉE   │
│  └───────────────────┘          (pas collée à       │
│                                   gauche)            │
│                                                    │
│  ADVERSAIRE                                        │
│  ┌───────────────────┐  ┌───────────────────┐    │
│  │ #5 N. Chevalier     │  │ #18 Y. Morin       │    │
│  │ [terrain] [impact]  │  │ [terrain] [impact]  │    │
│  └───────────────────┘  └───────────────────┘    │
└──────────────────────────────────────────────────┘
```
Si un des deux effectifs n'a aucun tir enregistré, sa section (titre + grille) ne s'affiche simplement pas — même logique que le tableau ADVERSAIRE déjà en place.

## 3. PDF — encart Zones d'impact Gardiens

Retrait des lettres de zone (HG/HC/HD...) sous chaque cellule — la position dans la grille 3×3 suffit. Ajout d'une légende explicative sous le titre, reprenant exactement la formulation déjà utilisée dans l'app (`goalZoneHeatmap()`), pour que la lecture soit identique des deux côtés.

```
┌────────────────────────────┐
│  ZONES D'IMPACT             │
│  Stat des tireurs            │   ← légende ajoutée, identique à l'app
│  (ex : 1/1 = 1 but,          │
│   pas d'arrêt)               │
│  ┌────┬────┬────┐           │
│  │1/1 │0/2 │1/1 │           │   ← ratio = buts/total (perspective tireur),
│  ├────┼────┼────┤           │      plus arrêts/total (perspective gardien)
│  │1/1 │1/1 │1/1 │           │
│  ├────┼────┼────┤           │   ← plus de lettre HG/HC/HD sous les cellules
│  │    │1/1 │    │           │
│  └────┴────┴────┘           │
└────────────────────────────┘
```

## Composants réutilisés vs nouveaux
- Réutilisé tel quel : `card()`, `pageHeader()`, `drawCourt()`, `drawHandballZone()`, `drawPlayerZoneGrid()`, `drawPlayerTable()` (le mécanisme partagé FENIX/ADVERSAIRE déjà en place sert de modèle direct pour la page Carte tir joueur)
- Nouveau : logique de sous-disposition PVT à 3/4 joueurs dans `courtPlayerPositions()` ; découpage de page dédié pour Évolution du score ; section ADVERSAIRE sur la page Carte tir joueur ; légende + ratio buts/total dans `drawGoalZone()` (PDF)

## États
- Terrain à 0 pivot sélectionné : rien à afficher, comportement déjà couvert par STORY-20 (terrain vide tant qu'aucune sélection)
- PDF sans aucun tir adverse enregistré : section ADVERSAIRE absente de la page Carte tir joueur (pas de carte vide)
- PDF sans aucun gardien qualifié pour le Top 3 : comportement déjà en place (Top 3 composé uniquement de joueurs de champ), inchangé
