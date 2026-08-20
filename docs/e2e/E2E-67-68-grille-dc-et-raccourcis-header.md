# E2E — STORY-67 (grille DC) + STORY-68 (raccourcis en-tête)

## Contexte
Le QA a déjà validé les deux stories en détail (captures, vérifications visuelles multi-écrans/multi-largeurs). Cette passe E2E se concentre sur ce que seul un vrai clic souris peut confirmer : que les nouveaux éléments compacts de l'en-tête (petits, collés au logo) et les joueurs les plus densément regroupés de la grille DC sont **réellement cliquables**, pas seulement visuellement présents. Contre le vrai backend Supabase de production.

## Parcours testés (clics réels, pas de dispatch programmatique)

1. **Raccourci Suivi GB** — clic réel sur `🧤 ON` → `S.trackGK` passe à `false`, libellé du bouton redevient `🧤 OFF` au re-rendu → reclic réel → retour à `ON`.
2. **Raccourci Mode** — clic réel sur `🎯` (Expert) → `S.mode` passe à `"simple"` → clic réel sur `⚡` → retour à `"expert"`. Les deux clics ont atteint le bon bouton malgré le re-rendu complet de l'en-tête entre les deux (icône différente au même endroit).
3. **Point le plus exigeant** : après lancement d'un match, clic réel sur **Antonin.V**, le joueur du coin bas-droit de la grille DC à 5 (la position la plus resserrée, adjacente à Mattéo.A du poste Arrière D juste à côté) → `S.actionPanel.shooterId` correctement résolu vers Antonin.V, pas vers un voisin — confirme que le repositionnement de STORY-67 n'a pas seulement l'air correct visuellement, les zones cliquables ne se chevauchent pas non plus.

## Résultat par parcours
- ✅ Raccourci Suivi GB : fonctionne dans les deux sens, clic réel
- ✅ Raccourci Mode : fonctionne dans les deux sens, clic réel, y compris juste après le re-rendu de l'en-tête déclenché par le changement d'icône
- ✅ Clic réel sur le joueur le plus densément entouré de la grille DC : résolu vers le bon joueur, aucune zone cliquable qui déborderait sur sa voisine

## Écarts avec le verdict QA
Aucun.

## Console navigateur
0 erreur sur l'ensemble de la passe.

## Nettoyage / impact production
Le match lancé pour tester le clic sur Antonin.V (jamais sauvegardé, action annulée avant validation) a été supprimé directement de Supabase via son `currentMatchId` — vérifié aucun match `in_progress` résiduel après coup. Les 2 matchs réels de Romain jamais touchés.

## Verdict
**CONFIRMÉ** — aucun désaccord avec le QA. Les deux points les plus à risque identifiés par le Risk Analyst (compacité des raccourcis d'en-tête, densité de la grille DC) fonctionnent correctement au clic réel, pas seulement à l'écran.
