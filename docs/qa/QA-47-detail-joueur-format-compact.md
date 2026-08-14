# QA — STORY-47 (Détail joueur au format compact)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-47-detail-joueur-format-compact.md`, `docs/code-review/STORY-47.md` (APPROUVÉ), `docs/design/` et `docs/arch/detail-joueur-format-compact.md`, `docs/risks/detail-joueur-format-compact.md`.

## Méthode
CDP sur Chrome headless, **vrais clics réels** (`Input.dispatchMouseEvent`) pour toutes les interactions (pas seulement injection d'état) : clic sur la cible 🎯, clic sur un tir individuel, clic sur "✕ Fermer". Captures d'écran réelles sur 3 viewports : iPad paysage (1024×768), iPad portrait (768×1024), iPhone portrait (390×844).

## Critères d'acceptation

- [x] Modale centrée (`.overlay`+`.pd-modal`, `width:min(520px,94vw)`), plus de `100vw`/`100vh` — confirmé sur les 3 captures, **centrage horizontal ET vertical vérifié explicitement** (priorité signalée par Romain) : sur iPad paysage, centre de la modale à (1000,750) pour un viewport rendu de 2000×1500 — quasi exactement le centre de l'écran dans les deux axes
- [x] Bordure teintée par équipe (`.gk-sheet` via `--gk-accent-rgb`) visible — confirmé sur capture
- [x] Disposition 2 colonnes (terrain 65% / chiffres 35%) sur iPad — confirmé, côte à côte comme Gardiens
- [x] Colonne chiffres : BUTS (gros, bleu FENIX), EFF% (jaune), pills PD (jaune) et TIRS (gris neutre) — toutes les valeurs cohérentes avec le jeu de test (2 buts/4 tirs = 50%, 0 PD)
- [x] Grille Impact + terrain (points ou zones) + légende affichés dans la colonne terrain, contenu identique à avant (mêmes ratios par zone, mêmes marqueurs sur le terrain)
- [x] En-tête (nom + bascule + "✕ Fermer") et info tir sélectionné conservés au-dessus du bloc 2 colonnes
- [x] Fermeture uniquement via "✕ Fermer" — testé par clic réel, la modale se ferme (`#pd-detail-overlay` disparaît du DOM)
- [x] Sélection d'un tir individuel (`data-pd-shot`) — testé par clic réel : grille Impact filtrée sur la zone du tir sélectionné, halo blanc sur le marqueur, bande d'info affichée ("But — Zone: HG — 1:00 ✕ tout voir"), stats d'en-tête (BUTS/EFF%/PD/TIRS) **non filtrées** par la sélection — comportement identique à avant (vérifié, pas une régression)
- [x] Bascule points/zones fonctionne depuis la modale — testé, rendu correct dans les deux modes
- [x] Mode lecteur : la modale s'ouvre normalement (`S.readOnly=true`, clic réel sur 🎯 → modale ouverte) — cohérent avec le fait que `renderPlayerDetail()` n'a jamais eu de garde `readOnly` (vue en lecture seule, pas une écriture)
- [x] iPad portrait et paysage : aucun chevauchement, disposition 2 colonnes correcte dans les deux orientations
- [x] iPhone portrait (390px) : bascule automatique en colonne unique (terrain au-dessus, chiffres en dessous) — confirmé, hérité du breakpoint `@media(max-width:700px)` déjà existant sur `.gk-sheet-body`, sans modification nécessaire

## Cas limites testés
- **Joueur sans aucun tir** (`S.events=[]`) : `renderPlayerDetail()` ne lève aucune exception, rendu produit (5713 caractères), stats à "0" partout — pas de crash.
- **Mode lecteur** : modale ouvrable et consultable normalement (comportement voulu, ce n'est pas une écriture de donnée de match).
- **Collision d'id `pd-overlay`** trouvée et corrigée par le Developer avant cette QA (cf. Code Review) — vérifié qu'elle n'existe plus (`id="pd-detail-overlay"` utilisé, recherche de code confirmant un seul élément avec cet id).

## Bugs trouvés
Aucun dans le périmètre de cette QA — la collision d'`id` a été trouvée et corrigée par le Developer avant la revue de code, cf. `docs/code-review/STORY-47.md`.

## Régressions détectées
Aucune — grille Impact, terrain (points/zones), sélection de tir, bascule, mode lecteur tous vérifiés fonctionnellement identiques à avant, seul le conteneur visuel a changé.

## Verdict
**PASSED**
