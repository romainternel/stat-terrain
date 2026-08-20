# STORY-68 — Raccourcis Mode de saisie et Suivi GB dans l'en-tête

**En tant que** Romain (ou tout aidant occasionnel),
**Je veux** pouvoir basculer le mode de saisie (Simple/Expert) et le suivi GB en un tap, depuis n'importe quel écran,
**Afin de** ne pas devoir naviguer vers Équipes ou ouvrir les Réglages à chaque fois que je veux changer l'un de ces deux réglages.

Demande directe de Romain.

## Contexte technique
- Zone concernée : `renderHeader()` (`app.js:1893`), `bind()` (nouveaux handlers), `style.css` (nouvelles règles `.hdr-shortcuts`/`.hdr-shortcut`/`.hdr-shortcut-gk`)
- Nouvelles structures : aucune — réutilise `S.mode`/`S.trackGK`/`setMode()` déjà existants
- Impact sur l'existant : `#settings-btn` perd son `margin-left:auto` inline (déplacé sur `.hdr-shortcuts`, toujours présent désormais) — **point d'attention explicite**, cf. risque R3 de `docs/risks/dc-grid-et-raccourcis-header.md`
- Maquette exacte (desktop et iPhone étroit) : `docs/design/dc-grid-et-raccourcis-header.md` section F2 ; specs couleur exactes : `docs/visual/dc-grid-et-raccourcis-header.md` section F2
- Code de référence détaillé : `docs/arch/dc-grid-et-raccourcis-header.md` section F2

## Critères d'acceptation
- [ ] Un raccourci Mode (icône ⚡ si Simple actif, 🎯 si Expert actif) et un raccourci Suivi GB (icône 🧤, coloré selon l'état ON/OFF) sont visibles dans l'en-tête sur **tous** les écrans (Équipes, Match, Stats, Bilan, Matchs) — pas seulement en match actif
- [ ] Tap sur le raccourci Mode : bascule `S.mode` via `setMode()` (pas de logique dupliquée) — si Mode Expert avec événements déjà saisis et bascule vers Simple, la confirmation bloquante existante s'affiche normalement
- [ ] Tap sur le raccourci Suivi GB : bascule `S.trackGK` immédiatement, sans confirmation (comportement identique aux 2 emplacements existants)
- [ ] Les 2 emplacements existants (toggle Équipes, toggle panneau Réglages) restent fonctionnels et reflètent le même état que les raccourcis d'en-tête (même variable d'état, pas une copie) — vérifié en changeant depuis l'en-tête puis en consultant Équipes, et inversement
- [ ] **Vérification visuelle explicite de l'en-tête** (cf. risque R3) : sur un écran sans match actif (logo + raccourcis + nav, pas de `#settings-btn`) ET sur un écran avec match actif (logo + raccourcis + ⚙ Réglages + nav) — espacement cohérent dans les deux cas, aux largeurs desktop/tablette et iPhone étroit (≤700px)
- [ ] Sur iPhone étroit, le texte "ON"/"OFF" du raccourci Suivi GB disparaît (icône seule), les 5 onglets de navigation restent atteignables en défilement horizontal comme avant (STORY-18) — pas d'illisibilité ni de perte d'accès à un onglet
- [ ] `new Function()` passe sur `app.js` modifié

## Hors scope
- Suppression des emplacements existants (Équipes, Réglages) — les raccourcis s'ajoutent, ne remplacent rien.
- Tout nouveau raccourci au-delà de Mode et Suivi GB.
- Confirmation avant bascule du Suivi GB (cohérence volontaire avec les 2 sites existants, cf. risque R4 accepté).

## Dépend de
Aucune

## Taille
S
