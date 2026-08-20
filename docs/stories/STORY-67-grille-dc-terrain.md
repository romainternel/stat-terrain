# STORY-67 — Les joueurs Demi-Centre ne se chevauchent plus sur le terrain

**En tant que** Romain,
**Je veux** que les étiquettes des joueurs Demi-Centre restent lisibles et distinctes sur le terrain même quand plusieurs sont sélectionnés,
**Afin de** composer mon effectif (jusqu'à 5 DC dans le roster réel) sans avoir des noms illisibles collés les uns sur les autres, notamment sur tablette.

Remonté par Romain en conditions réelles d'usage.

## Contexte technique
- Zone concernée : `POS_XY.DC` (`app.js:48`), `courtPlayerPositions()` (`app.js:2781`, objet `layouts` de la branche `spread==="grid"`)
- Nouvelles structures : aucune — ajout d'une entrée `5` à un objet déjà existant, et de 3 propriétés (`spread`, `hSpread`, `vSpread`) à une entrée déjà existante de `POS_XY`
- Impact sur l'existant : tous les écrans qui appellent `courtPlayerPositions()` héritent automatiquement (Match Mode Expert, sélecteurs PD/2min/carton, Stats Joueurs/Gardiens/Comparaison) ; PVT partage le même bloc de code (branche `grid`), non modifié mais à re-tester par prudence (cf. risque R2)
- Détail exact du correctif (valeurs, calcul de bornes, alternatives écartées) : `docs/arch/dc-grid-et-raccourcis-header.md`

## Critères d'acceptation
- [ ] Les 5 joueurs DC du roster FENIX CF réel (Jules.G, Issa.S, Leni.A, Lucas.G, Antonin.V), tous sélectionnés, s'affichent avec 5 étiquettes visuellement distinctes sur le terrain (3 en rangée haute, 2 en rangée basse), sans chevauchement
- [ ] Testé sur tablette (paysage et portrait) et sur téléphone
- [ ] 1, 2, 3 et 4 joueurs DC sélectionnés restent également sans chevauchement
- [ ] DC reste visuellement derrière l'alignement ARG/ARD (pas mélangé avec eux, pas de confusion de poste)
- [ ] Vérifié sur au moins 2 écrans différents parmi ceux qui rendent le terrain (Match Mode Expert + un sélecteur PD/2min/carton ou une carte Stats)
- [ ] **Régression PVT** : à 3 joueurs et à 4 joueurs Pivot sélectionnés, la disposition reste identique à avant ce changement (le code partagé n'a pas régressé)
- [ ] `new Function()` passe sur `app.js` modifié

## Hors scope
- Toute disposition dédiée pour un poste autre que DC (ALG/ARG/ARD/ALD restent en spread vertical simple).
- Gestion d'un effectif DC à 6 joueurs ou plus (retombe sur le fallback générique existant, comportement dégradé mais non cassé, accepté pour cette itération).

## Dépend de
Aucune

## Taille
S
