# STORY-47 — Détail joueur (Stats → Joueurs) au format compact

**En tant que** Romain,
**Je veux** que le détail joueur (clic sur la cible 🎯) s'ouvre dans une fenêtre de la même taille qu'une carte Gardien, pas en plein écran,
**Afin de** garder le geste de consultation léger, cohérent avec le reste de l'écran Stats — retour direct après usage réel de STORY-44/46 (v92), capture d'écran de Stats → Gardiens à l'appui.

## Contexte technique
- Zone concernée : `app.js`, `renderPlayerDetail()` (~ligne 2627-2732) — seule fonction modifiée
- Référence visuelle : `renderGkSheet()` (~ligne 3400), classes CSS déjà existantes `.gk-sheet-body`/`.gk-sheet-nums`/`.gk-sheet-court`/`.gk-lvl1`/`.gk-lvl2`/`.gk-pill`
- Référence de conteneur modal : `renderShotOverlay()`, classe `.overlay` déjà existante
- Design complet : `docs/design/detail-joueur-format-compact.md`
- Architecture complète (structure avant/après, CSS exact) : `docs/arch/detail-joueur-format-compact.md`
- Risques à vérifier explicitement pendant le développement : `docs/risks/detail-joueur-format-compact.md` (R1 cascade CSS, R2 breakpoint, R3 couleur pill)

## Critères d'acceptation
- [ ] Le détail joueur s'ouvre dans une modale centrée (`.overlay` + nouvelle classe `.pd-modal`, `width:min(520px,94vw)`), **pas** en plein écran (`100vw`/`100vh` retiré)
- [ ] `.pd-modal` porte aussi `.card.gk-sheet` (bordure teintée par équipe via `--gk-accent-rgb`, mêmes valeurs que `renderGkSheet()`) — vérifier que la bordure accentuée s'affiche réellement (pas écrasée par une déclaration `border` en double, cf. Risque R1)
- [ ] Disposition interne en 2 colonnes via `.gk-sheet-body`/`.gk-sheet-nums`/`.gk-sheet-court` réutilisées telles quelles — terrain à gauche (65%), chiffres à droite (35%)
- [ ] Colonne chiffres : BUTS en gros (`.gk-lvl1`), EFF% en dessous (`.gk-lvl2`, jaune), PD et TIRS en 2 `.gk-pill` — couleurs RGB des pills vérifiées explicitement (PD jaune, pas une couleur recopiée de Gardien par erreur, cf. Risque R3)
- [ ] Grille Impact + terrain SVG (points ou zones selon `S.shotViewMode`) + légende affichés dans `.gk-sheet-court`, contenu strictement inchangé (mêmes calculs, mêmes `id`/classes internes)
- [ ] En-tête (nom joueur + bascule points/zones + "✕ Fermer") et bande d'info tir sélectionné (`selInfo`) conservés, au-dessus du bloc 2 colonnes
- [ ] Fermeture : uniquement via "✕ Fermer" (pas de fermeture au clic sur le fond assombri, cohérent avec `renderShotOverlay()`)
- [ ] Sélection d'un tir individuel (`data-pd-shot`) continue de filtrer la grille Impact, sans modification de cette logique
- [ ] Bascule points/zones (`S.shotViewMode`) fonctionne toujours à l'identique depuis cette modale
- [ ] Mode lecteur : aucune régression (le détail joueur est une vue en lecture, jamais concerné par `S.readOnly`, à re-confirmer qu'aucune garde n'a été cassée par le changement de conteneur)
- [ ] Vérifié visuellement sur iPad (portrait et paysage — usage principal terrain) et iPhone (largeur étroite, cf. Risque R2 sur le breakpoint 700px)
- [ ] Animation d'ouverture (`pd-modal-in`) respecte `prefers-reduced-motion: reduce`

## Cas limites à tester
- Joueur sans aucun tir (0 événement) : colonne chiffres affiche "0" partout sans erreur, terrain vide, pas de crash
- Effectif avec beaucoup de tirs (terrain + grille + légende) sur iPhone portrait étroit : `max-height:90vh;overflow-y:auto` doit permettre de tout consulter sans que le contenu déborde de l'écran
- Bascule points ↔ zones pendant que la modale est ouverte : le contenu se met à jour sans fermer/rouvrir la modale

## Hors scope
`renderGkSheet()` elle-même (référence uniquement, non modifiée), le bloc Comparaison (STORY-44/46), tout changement de contenu/calcul des stats Joueur.

## Dépend de
Aucune dépendance technique — réutilise des classes CSS déjà livrées (STORY-30, `renderShotOverlay()` historique).

## Taille
S — une seule fonction modifiée, CSS additif uniquement, aucun nouveau state.
