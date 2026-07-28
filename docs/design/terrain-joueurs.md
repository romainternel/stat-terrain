# Design — Terrain et affichage des joueurs

*Produit par le Designer — squad build BMAD*
*S'appuie sur `docs/prd-v3-terrain-joueurs.md`*

## 1. État vide du terrain (F11)

Quand aucun joueur n'est sélectionné pour l'équipe concernée, le terrain reste affiché (les lignes réglementaires restent visibles — c'est le fond, pas un composant à masquer), mais aucune étiquette joueur n'apparaît. Un message discret est superposé pour ne pas laisser croire à un bug :

```
┌───────────────────────────────────┐
│                                     │
│      [ lignes du terrain vides ]   │
│                                     │
│      👥 Aucun joueur sélectionné    │
│      Va dans Équipes pour choisir  │
│      ton effectif                  │
│                                     │
└───────────────────────────────────┘
```

- Le message est centré sur le terrain, ton neutre (texte secondaire `--t2`/`--t3`), pas un rouge d'alerte — ce n'est pas une erreur, c'est un état initial normal avant que Romain ait fait sa sélection.
- Pas de bouton d'action direct vers Équipes dans cette première version (rester dans le scope CSS/texte, un lien de navigation ajouterait de la logique JS — à évaluer par l'Architect si jugé utile).

## 2. Numéro de maillot manquant (F13)

Le "?" actuel entre en conflit visuel avec le "?" déjà utilisé ailleurs (nom de joueur non renseigné, avec ✏️). Sur le terrain, le contexte est différent : on sait qui est le joueur (son nom s'affiche à côté), seul le numéro manque.

**Proposition** : remplacer le "?" par un tiret discret (`–`) à la place du numéro, avec une opacité réduite — signale "pas de numéro" sans avoir l'air d'un symbole d'erreur ou d'une question.

```
┌─────────────┐        ┌─────────────┐
│  –  Timéo   │  au lieu de  │  ?  Timéo   │
└─────────────┘        └─────────────┘
```

- Le "?" avec ✏️ de l'écran Équipes (nom de joueur non renseigné) n'est **pas concerné** par ce changement — contexte différent (là, c'est une invite à cliquer pour éditer un champ vide), à ne pas toucher.

## 3. Redesign du terrain lui-même (F10)

Je délègue la décision technique du **type** de rendu (SVG dessiné à la main vs. image retravaillée) au Visual Crafter/Architect — mon rôle ici est de cadrer ce que le terrain doit montrer, pas comment le dessiner en pixels :

- **Éléments réglementaires à conserver, tous visibles et lisibles** : ligne de but, zone des 6m (arc), ligne des 9m (arc pointillé), point de penalty (7m), ligne des 4m (marque courte devant le but).
- **Priorité visuelle** : les lignes du terrain doivent rester en arrière-plan discret — ce sont les étiquettes joueurs qui doivent capter l'attention en premier (cohérent avec l'existant, ne pas inverser cette hiérarchie).
- **Cohérence entre Match et Stats** : même rendu de terrain dans les deux contextes (actuellement déjà partagé via `COURT_IMG`) — la refonte doit s'appliquer aux deux pour éviter un nouvel écart de qualité entre écrans, exactement le problème qu'on corrige ailleurs dans ce cycle.

## Composants réutilisés vs nouveaux

- **Nouveau** : message d'état vide du terrain.
- **Modifié** : `dn()` (affichage numéro), rendu du fond de terrain (`COURT_IMG` ou son remplaçant).
- **Réutilisé** : structure `.cp-player`/`.court-pick` existante, uniquement le fond et le contenu changent.
