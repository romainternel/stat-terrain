# QA — STORY-54 (Écran de lancement dédié sur la page Match)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-54-ecran-lancement-page-match.md`, `docs/code-review/STORY-54.md` (APPROUVÉ).

## Méthode
CDP, vrais clics réels sur `#launch-match-btn`, captures d'écran à 820×1180 (iPad-like) et 390×844 (iPhone).

## Critères d'acceptation
- [x] Écran dédié affiché sur état frais (aucun match actif) — noms d'équipe, gros bouton, liste des manques GB affichée correctement (2 lignes attendues) — confirmé sur les 2 viewports, texte long (nom d'équipe adverse à rallonge) s'enroule proprement sans casser la mise en page
- [x] Bouton retiré d'Équipes — `#launch-match-btn` absent sur cet onglet, remplacé par une phrase d'aide
- [x] Clic réel sur le bouton → `S.running===true`, `S.period===1`, `S.currentMatchId` défini, `.match-launch` disparaît, `.match-layout` (interface complète) apparaît — capture d'écran confirmant le rendu identique à avant (STORY-52)
- [x] Cas `loadMatchAsCurrent()` (simulé : `currentMatchId=null`, un événement déjà présent) → `.match-layout` affiché directement, `.match-launch` absent — **point le plus important de cette QA**, celui qui aurait cassé "📂 Charger" et le raccourci PDF de Bilan sans le correctif trouvé en Code Review
- [x] `#settings-btn` absent sur l'écran de lancement, présent après lancement et dans le cas match chargé

## Cas limites testés
- Nom d'équipe long ("Ivry Handball Club") sur iPhone 390px — s'affiche sur sa propre ligne sous "FENIX Toulouse vs", pas de débordement horizontal.
- Match repris (`resumeMatch()`) — non re-testé en direct dans cette QA (fonction déjà vérifiée en STORY-14), mais son point d'entrée fixe `S.currentMatchId` avant `S.view="match"`, donc structurellement hors d'atteinte de l'écran de lancement — confirmé par lecture de code.

## Bugs trouvés
Aucun dans le périmètre livré — le risque principal (`loadMatchAsCurrent()`) a été anticipé et corrigé avant cette QA, cf. Code Review.

## Régressions détectées
Aucune — STORY-52 (M1, chrono auto) et STORY-53 (bandeau de validation) re-testés après ce changement, comportement identique.

## Verdict
**PASSED**
