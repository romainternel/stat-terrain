# QA — STORY-39 (PDF : pagination robuste + corrections de contenu)

## Ce que j'ai lu avant de tester
- `docs/stories/STORY-39-pdf-pagination-et-corrections.md` (critères d'acceptation + hors scope)
- `docs/code-review/STORY-39.md` — verdict APPROUVÉ, aucun point bloquant
- `docs/arch/terrain-postes-multiples-et-pdf-v2.md`, `docs/visual/terrain-postes-multiples-et-pdf-v2.md`
- `CLAUDE.md` (section PDF, section Design & UI pour les couleurs)

## Méthode
Génération de PDF réels via CDP (pas d'injection de rendu, appel direct de `generatePDF()` dans la page chargée), en remplaçant `save()` par une capture du buffer pour éviter le dialogue de téléchargement natif. Deux jeux de données :
1. **Cas volumineux réaliste** (`pdf-story39-test.pdf`, 6 pages) : 14 joueurs FENIX + 14 IVRY, 43 événements avec tirs/zones, un gardien FENIX performant pour tester la qualification Top 3.
2. **Cas limite vide** (`pdf-story39-edge-empty.pdf`, 4 pages) : 1 joueur de champ + 1 GB par équipe, **aucun événement** (`S.events = []`).
Les 10 pages au total ont été capturées en image et inspectées visuellement.

## Critères d'acceptation

**Pagination (F2)**
- [x] "ÉVOLUTION DU SCORE" sur sa propre page — confirmé cas volumineux (page 3/6, seule sur la page, footer "Page 3/6" propre) et cas vide (page 3/4)
- [x] 14+14 joueurs sélectionnés : aucune section coupée, aucun chevauchement avec le pied de page, sur Joueurs/Évolution/Carte tir joueur — confirmé sur les 6 pages du cas volumineux
- [x] Titre de section jamais orphelin lors d'un saut de page déclenché par `ensurePageSpace()` — confirmé au moins deux fois : "ADVERSAIRE" (tableau Joueurs) part avec son tableau sur la page 2 sans coupure, "ADVERSAIRE" (Carte tir joueur) part proprement en page 5 avec son contenu
- [x] Page 1 (bandeau + carte score) revérifiée avec un jeu de données chargé des deux côtés — **aucun chevauchement constaté**, le bug remonté par Romain n'est pas reproduit avec cette implémentation ; considéré résolu par cette story (le bandeau bleu, la carte score, le COMPARATIF et les deux blocs Top 3 sont bien espacés)

**Glyphe Top 3 (F3)**
- [x] Rang 1 affiche "1." — confirmé sur les deux blocs (FENIX et ADVERSAIRE), plus de "&"
- [x] Audit non-ASCII : voir note du Code Reviewer (deux `·` pré-existants hors périmètre de cette story, dans l'en-tête de page de garde — non introduits par STORY-39, jugés sans risque car dans le charset WinAnsi contrairement à "★")

**Top 3 gardien qualifié (F5)**
- [x] Ligne GB affiche `arrets/cadrés (%)` — confirmé "GB 9/15 arrets (60%)" (Meunier) et "GB 11/17 arrets (65%)" (Koch) sur la page 1, correspond exactement à "Arrets/Cadres" affiché page Gardiens (pas 9/22 qui est la base "tous tirs")
- [x] Seuil de qualification recalculé sur base cadrés — vérifié dans le code (`gkS.total`/`gkS.saves`, cf. revue de code) ; cas limite testé : gardien à 0 tir cadré affronté (`0/0`) ne qualifie pas et ne fait pas planter la génération (`gkS.total>0` dans la condition)
- [x] Cas réel de Romain (6/7 cadrés, 86%) : `saves=6>=6` et `6/7≈0.857>=0.4` → qualifie avec la formule actuelle. Vérifié par lecture du code (donnée réelle non rejouable ici, hors app de prod)

**Carte tir joueur — effectif adverse + centrage (F6)**
- [x] Section "ADVERSAIRE" présente sur la page Carte tir joueur, même format que FENIX — confirmé pages 4-5 du cas volumineux (7 cartes FENIX + carte seule #8 Simon, puis 7 cartes ADVERSAIRE + carte seule #8 Vidal)
- [x] Rendu FENIX visuellement identique à l'existant (mini-terrain + zone d'impact + PB) — confirmé, aucune régression visuelle
- [x] Dernière carte à ligne impaire centrée, pas collée à gauche — confirmé sur les deux occurrences (#8 Simon et #8 Vidal), la carte seule est visuellement centrée sous la grille à 2 colonnes au-dessus
- [x] Cas limite : aucun tir enregistré nulle part → section "Carte tir joueur" absente **entièrement** (pas de page vide/cassée) — confirmé, le PDF passe de 6 à 4 pages sans cette section

**Zones d'impact Gardiens — cohérence avec l'app (F4)**
- [x] Ratio = buts/total (perspective tireur) — confirmé, cellules "2/2", "1/1" etc. correspondent aux buts encaissés/total sur la zone, pas aux arrêts
- [x] Couleur : vert si >50% buts, cyan `[78,205,232]` sinon, jamais de rouge — confirmé visuellement sur les deux gardiens du cas volumineux (mélange vert/cyan cohérent avec les ratios affichés)
- [x] Légende "Stat des tireurs (ex : 1/1 = 1 but, pas d'arret)" présente sous le titre — confirmé, texte lisible
- [x] Lettres de zone (HG/HC...) retirées des cellules — confirmé, seules les cellules colorées + ratio restent
- [x] Cas limite : gardien sans tir affronté (0/0 partout) → grille entièrement neutre (bleu foncé), aucune cellule ne tente d'afficher un ratio, aucune division par zéro / NaN visible — confirmé sur le cas vide (page 4/4)

## Cas limites testés
- **Vide total** (aucun événement, effectif minimal 1+1 par équipe) : génération sans erreur JS (try/catch autour de `generatePDF()` n'a rien capturé), 4 pages cohérentes, section Carte tir joueur absente comme attendu, Zones d'impact affichées à vide sans crash.
- **Volume max réaliste** (14 vs 14, 43 événements) : 6 pages, aucun débordement, dernière carte de grille impaire centrée des deux côtés (FENIX ET adversaire) — le cas qui avait initialement révélé le bug de Romain.
- Cas non testé explicitement mais couvert par lecture de code : nombre pair de joueurs avec tirs (pas de carte seule à centrer) — logique `isLastAlone` ne s'active que si `gcol===0` sur le dernier élément, donc n'affecte pas les grilles complètes ; jugé suffisamment simple pour ne pas nécessiter un rendu séparé.

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune — le rendu Comparatif, Top 3 (structure), page Joueurs (hors ajout du tableau ADVERSAIRE déjà en place avant cette story), et le graphique Évolution du score sont visuellement conformes à ce qui existait avant STORY-39, seulement repositionnés/corrigés selon les critères ci-dessus.

## Verdict
**PASSED**
