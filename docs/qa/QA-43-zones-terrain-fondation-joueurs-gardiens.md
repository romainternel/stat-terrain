# QA — STORY-43 (Zones sur le terrain : fondation + Joueurs/Gardiens)

## Ce que j'ai lu avant de tester
`docs/stories/STORY-43-zones-terrain-fondation-joueurs-gardiens.md`, `docs/code-review/STORY-43.md` (APPROUVÉ), `docs/arch/`, `docs/design/`, `docs/risks/zones-terrain-et-tableau-joueurs.md`.

## Méthode
Application lancée en local (serveur statique), pilotée par clics réels via CDP (pas seulement injection d'état) : ouverture de l'overlay détail joueur via un vrai clic sur la cible 🎯, clic réel sur le bouton de bascule, navigation réelle vers l'onglet Gardiens, re-bascule réelle. Jeu de données dédié : 8 tirs d'un même joueur (Lemoine) contre le gardien adverse, un par zone attendue (coordonnées choisies pour couvrir explicitement AilG/6mG/6mC/6mD/AilD/9mG/9mC/9mD), plus 2 événements `PEN_GOAL`/`PEN_SAVE` pour le marqueur 7m.

## Critères d'acceptation

**Fondation (F2/F3)**
- [x] `buildCourtZones()` produit 8 polygones sans trou ni chevauchement visible — confirmé sur les captures Joueurs et Gardiens, formes identiques au prototype déjà validé par Romain
- [x] Constantes de calibrage reprises du prototype (`AY=56, AX=88`, colonne centrale doublée/centrée) — confirmé par lecture de code (Code Review) et par le rendu visuel (proportions identiques au prototype)
- [x] Repères visuels 6m/9m/4m/7m visibles — confirmé (déjà fournis par `courtSvgMarkup()`, non régressés)
- [x] `S.shotViewMode` persiste par appareil, défaut `"points"` — confirmé : première ouverture de l'app affiche les points (comportement historique inchangé) tant qu'aucun clic n'a eu lieu
- [x] `S.shotViewMode` n'est PAS réinitialisé par `newMatch()`/`loadMatchAsCurrent()` — confirmé par recherche de code (aucune référence), cohérent avec le fait que `S.mode` (même pattern) n'y est pas réinitialisé non plus
- [x] Bouton de bascule actif en mode lecteur — confirmé : `S.readOnly=true` puis clic réel sur le bouton, `S.shotViewMode` change bien

**Stats → Joueurs**
- [x] Bouton de bascule visible dans l'en-tête, à côté de "✕ Fermer"
- [x] Mode "zones" : les 8 zones colorées avec ratio buts/tirs, marqueur 7m avec son propre ratio (1/2 sur le jeu de test) — confirmé visuellement, exactement cohérent avec le prototype
- [x] Mode "points" : comportement identique à avant STORY-43 (8 points aux positions attendues, couleurs but/arrêt/hors-cadre inchangées)
- [x] Grille Impact (HG/HC/etc.) non affectée par le bouton — confirmé, "5/8" identique dans les deux modes

**Stats → Gardiens**
- [x] Bouton de bascule visible, fonctionne en mode combiné et individuel — testé sur les deux cartes (FENIX/Meunier 0 tir, IVRY/Koch 8 tirs)
- [x] État partagé confirmé : en revenant de Joueurs vers Gardiens sans toucher au bouton, le mode "zones" choisi précédemment est resté actif (un seul réglage global, pas un état par écran)
- [x] `goalZoneHeatmap()` (grille Impact 3×3) non affectée par le bouton

## Cas limites testés
- **Gardien sans tir affronté** (Meunier, FENIX, 0 tir contre lui dans ce jeu de données) : carte "0/0", terrain en mode zones entièrement neutre, aucune erreur, aucun crash.
- **Zone à la limite exacte 6m/9m** : un premier jeu de test (`y=75%`) est tombé juste sous le vrai seuil (75.7%) et a été classé en `6mC` au lieu de `9mC` — **comportement du code correct**, confirmé en resoumettant un point clairement au-delà (`y=85%`) qui s'est bien classé en `9mC`. Documenté dans le Code Review comme point de vigilance pour de futurs tests, pas un bug.
- **Mode lecteur** : bouton de bascule reste cliquable et fonctionnel, comme attendu (ce n'est pas une écriture de donnée de match).

## Point vérifié séparément — marqueur "Sans GB"
Absent du rendu live (décision du Developer, documentée dans le code et le Code Review) plutôt qu'un badge affiché en permanence vide. Aucun critère d'acceptation de STORY-43 n'exige littéralement sa présence visuelle (seule la fondation architecture le mentionne comme "prévu mais vide") — **jugé conforme à l'esprit de la story** (pas de faux repère visuel pour une donnée qui n'existe pas encore). Signalé à Romain comme point à confirmer si le rendu vide était en fait souhaité visuellement.

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune — page Joueurs (stats, grille Impact) et page Gardiens (stats numériques, filtre GB, filtre type de tir, heatmap) visuellement conformes à leur état avant STORY-43, en dehors du changement prévu (bascule points/zones).

## Verdict
**PASSED**
