# Design — Zones de tir : vraie distinction 6m / 6-9m / 9m

*Produit par le Designer — squad build BMAD*
*S'appuie sur `docs/prd-v18-zones-tir-distance.md`*

## Contexte
Deux surfaces concernées, avec deux contraintes d'espace radicalement différentes : le terrain live (SVG plein écran, déjà validé visuellement par Romain sur 8 itérations) et le PDF (grille figée de 34×14mm, contrainte d'impression). Je traite les deux séparément — la fidélité visuelle du live ne doit pas dicter une mise en page illisible dans le PDF.

## F1+F2 — Terrain live : 8 zones → 11 zones

```
                    ┌──────────┐
                    │   BUT    │
   ┌────────────────┴──────────┴────────────────┐
   │  AILG                                 AILD  │
   │  ┌──┐        ┌────┐  ┌────┐  ┌────┐   ┌──┐ │
   │  │  │        │ 6MG│  │6MC │  │ 6MD│    │  │ │
   │  │  │        └────┘  └────┘  └────┘    │  │ │
   │  │  │       ┌─────┐ ┌─────┐ ┌─────┐    │  │ │
   │  │  │       │69MG │ │69MC │ │69MD │     │  │ │
   │  │  │       └─────┘ └─────┘ └─────┘    │  │ │
   │  │  │      ┌──────┐┌──────┐┌──────┐    │  │ │
   │  │  │      │ 9MG  ││ 9MC  ││ 9MD  │    │  │ │
   │  │  │      └──────┘└──────┘└──────┘    │  │ │
   │  └──┘                                  └──┘ │
   └───────────────────────────────────────────────┘
```
- Les zones `6M*` se resserrent visuellement plus près du but (elles couvrent désormais un vrai rayon de 6m, plus petit qu'aujourd'hui) — les zones `9M*` gardent leur portée extérieure inchangée. La bande `69M*` occupe l'espace intermédiaire, aujourd'hui absorbé dans `6M*`.
- Couleurs et comptage `but/tir` par zone : mécanisme identique à l'existant (`data-t===0` → gris neutre, sinon vert si >50% d'efficacité, bleu sinon) — aucun nouveau code couleur à apprendre pour Romain.
- Labels textuels des 3 nouvelles zones `69M*` : positionnés à mi-chemin entre les labels `6M*` et `9M*` actuels (valeurs de départ indicatives, à ajuster visuellement en conditions réelles comme les 8 itérations précédentes l'ont déjà nécessité pour `6MG`/`6MD` — ne pas figer une position finale sans un premier rendu réel).

## F3+F4 — PDF : grille compacte, 34×14mm (carte gardien) / plus petit encore (carte tir joueur)
11 zones en polygones fidèles n'entrent pas dans cet espace de façon lisible (le grille actuelle à 6 cellules est déjà à la limite, texte à 5-6px). Proposition : une grille rectangulaire 3 colonnes (Gauche/Centre/Droit) × 3 lignes (6m/6-9m/9m), les ailes affichées en **deux cellules fines** de part et d'autre de la grille plutôt qu'intégrées à la trame 3×3 :

```
┌────┬──────┬──────┬──────┬────┐
│ AI │ 6M-G │ 6M-C │ 6M-D │ AI │
│ L  ├──────┼──────┼──────┤ L  │
│ G  │69M-G │69M-C │69M-D │ D  │
│    ├──────┼──────┼──────┤    │
│    │ 9M-G │ 9M-C │ 9M-D │    │
└────┴──────┴──────┴──────┴────┘
```
- Les deux cellules "AIL" (gauche/droite) s'étendent sur toute la hauteur de la grille (une seule valeur `but/tir`, pas subdivisée — cohérent avec F2).
- Densité : 11 cellules dans 34mm de large → environ 3mm par cellule centrale. Texte réduit à la taille déjà utilisée pour la variante compacte (`drawPlayerOriginZone`, 5px) — **à vérifier sur un vrai export PDF avant de considérer F4 terminé**, la marge de lisibilité est fine (cf. Risques).
- Alternative de repli si la grille à 11 cellules s'avère illisible à l'impression réelle : fusionner `69M*` avec `9M*` dans le PDF uniquement (revenir à 8 cellules affichées, tout en gardant la vraie classification à 11 buckets en sous-jacent pour les écrans live) — **décision à trancher après un premier test d'impression réel, pas a priori**.

## Interactions
Aucun nouveau geste — le bouton de bascule points/zones (`shotViewToggleHtml()`) et le tap sur une zone (déjà existant côté gardien/joueur pour filtrer) restent identiques dans leur mécanique, seul le nombre de zones cliquables augmente.

## États
- **Zone sans tir** (`t===0`) : rendu neutre inchangé (`var(--bg3)`), y compris pour les 3 nouvelles zones `69M*`.
- **Beaucoup de tirs concentrés en `69M*`** (cas attendu si c'est effectivement la zone la plus fréquente en usage réel, comme le laisse penser la remarque de Romain) : aucun traitement spécial, le dégradé de couleur existant (vert/bleu selon l'efficacité) suffit.

## Responsive
Le terrain live garde son comportement responsive existant (SVG, `viewBox` inchangé) — ajouter des zones ne change pas le mécanisme de mise à l'échelle, seulement le nombre de polygones dessinés dedans.

## Composants réutilisés
- `courtSvgMarkup()` (fond du terrain, lignes 6m/9m déjà tracées) — inchangé, sert justement de référence visuelle pour positionner les nouvelles frontières de zone.
- Bouton de bascule points/zones, mécanisme de tap-to-filter sur une zone — inchangés.
- Grille `doc.rect()` du PDF (déjà utilisée par `drawOriginZone`/`drawPlayerOriginZone`) — même technique de rendu, juste un nombre de cellules et une disposition différents.

## Point de vigilance explicite pour le Developer/QA
Cette feature modifie un écran (terrain "zones") **déjà validé par Romain après 8 itérations** — ne pas le considérer "juste un ajout technique". Un premier rendu réel doit être montré à Romain avant de fermer la story (cf. PRD F5), avec la possibilité réelle qu'il demande un ajustement de position/taille des nouvelles zones, comme cela a déjà été le cas pour `6MG`/`6MD` lors du cycle précédent.
