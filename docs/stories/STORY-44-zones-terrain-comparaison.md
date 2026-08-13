# STORY-44 — Zones sur le terrain : nouveau visuel dans Comparaison

**En tant que** Romain,
**Je veux** un terrain+but général par équipe dans l'onglet Comparaison, avec la même bascule points/zones, plus les buts/tirs et pertes de balle en un coup d'œil,
**Afin de** voir la répartition globale des tirs de chaque équipe, ce qui n'existe pas aujourd'hui sur cet écran.

Ajout net (Should au PRD, cf. `docs/prd-v10-zones-terrain-et-tableau-joueurs.md`) — séquencé après STORY-43 dont il dépend directement. **Révisée** après un retour direct de Romain une fois STORY-43 en usage réel (placement + contenu affinés, cf. `docs/design/` et `docs/arch/` mis à jour en conséquence).

## Contexte technique
- Zone concernée : `app.js`, `renderStatCompare()` (~ligne 3106)
- Réutilise `renderCourtZones()`/`buildCourtZones()`/le bouton de bascule livrés en STORY-43 — aucune nouvelle géométrie, aucun nouvel état de bascule
- Nouveau : rendu des marqueurs PB (`TURNOVER`, déjà `needsMap:true` mais jamais dessiné sur un terrain jusqu'ici) — capacité locale à cette story
- Référence design (placement, layout 2 mini-terrains, PB) : `docs/design/zones-terrain-et-tableau-joueurs.md` (section F6)
- Référence architecture : `docs/arch/zones-terrain-et-tableau-joueurs.md` (section F6)

## Critères d'acceptation
- [ ] Bloc ajouté **entre le tableau comparatif + graphique d'évolution du score et la carte "🎯 Tirs par poste"** (pas au-dessus du tableau comparatif) : deux mini-terrains (FENIX / adversaire), même largeur que les blocs déjà utilisés sur Gardiens
- [ ] Agrège **tous** les tirs de l'équipe (même filtre que `posShots` juste en dessous : `isGoal||isSave||isOff`, `e.x!=null`), pas un joueur ou un gardien en particulier
- [ ] En-tête de chaque mini-terrain : `Buts/Tirs` (réutilise les valeurs déjà calculées pour le tableau comparatif, pas un recalcul) et `PB` (réutilise `teamStat(side,"TURNOVER")`)
- [ ] Bouton de bascule partagé avec Joueurs/Gardiens — un seul état `S.shotViewMode`, pas de nouveau réglage local ; basculer ici doit aussi changer l'affichage sur Joueurs/Gardiens si on y retourne
- [ ] Mode "points" : marqueurs but/arrêt/hors-cadre comme sur Joueurs/Gardiens, **plus** des marqueurs PB distincts (forme/couleur différente des points de tir) pour les événements `TURNOVER` de l'équipe
- [ ] Mode "zones" : 8 zones + marqueur 7m comme sur Joueurs/Gardiens, ratio buts/tirs uniquement — **les PB ne sont pas affichées dans les zones** (le total PB reste visible via la stat d'en-tête, dans les deux modes)
- [ ] Aucune régression sur le tableau comparatif, le graphique d'évolution du score et la carte "Tirs par poste" existants

## Hors scope
Rien d'autre — c'est un ajout pur, aucune modification du reste de l'écran Comparaison. Les marqueurs PB restent spécifiques à ce bloc (pas ajoutés rétroactivement sur Joueurs/Gardiens).

## Dépend de
STORY-43 (fondation géométrie + bouton de bascule).

## Taille
M
