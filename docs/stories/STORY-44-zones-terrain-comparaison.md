# STORY-44 — Zones sur le terrain : nouveau visuel dans Comparaison

**En tant que** Romain,
**Je veux** un terrain+but général par équipe dans l'onglet Comparaison, avec la même bascule points/zones,
**Afin de** voir d'un coup d'œil la répartition globale des tirs de chaque équipe, ce qui n'existe pas aujourd'hui sur cet écran.

Ajout net (Should au PRD, cf. `docs/prd-v10-zones-terrain-et-tableau-joueurs.md`) — séquencé après STORY-43 dont il dépend directement.

## Contexte technique
- Zone concernée : `app.js`, `renderStatCompare()` (~ligne 2956)
- Réutilise entièrement `renderCourtZones()`/`buildCourtZones()`/le bouton de bascule livrés en STORY-43 — aucune nouvelle géométrie, aucun nouvel état
- Référence design (placement, layout 2 mini-terrains) : `docs/design/zones-terrain-et-tableau-joueurs.md`

## Critères d'acceptation
- [ ] Bloc ajouté entre le bandeau score et le tableau comparatif existant : deux mini-terrains (FENIX / adversaire), même largeur que les blocs déjà utilisés sur Gardiens
- [ ] Agrège **tous** les tirs de l'équipe (même filtre que `renderStatPlayers()` : `S.events.filter(e=>e.team===side&&...)`), pas un joueur ou un gardien en particulier
- [ ] Bouton de bascule partagé avec Joueurs/Gardiens — un seul état `S.shotViewMode`, pas de nouveau réglage local ; basculer ici doit aussi changer l'affichage sur Joueurs/Gardiens si on y retourne
- [ ] Mode "points" et "zones" tous deux fonctionnels, cohérents avec le rendu déjà validé en STORY-43
- [ ] Aucune régression sur le tableau comparatif et le graphique d'évolution du score existants, juste en dessous

## Hors scope
Rien d'autre — c'est un ajout pur, aucune modification du reste de l'écran Comparaison.

## Dépend de
STORY-43 (fondation géométrie + bouton de bascule).

## Taille
M
