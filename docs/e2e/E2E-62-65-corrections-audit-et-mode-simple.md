# E2E — STORY-62 à STORY-65 (corrections Audit Final + Mode Simple à équipe unique)

## Contexte
Le QA a déjà testé les 4 stories en profondeur via CDP (dispatch d'événements sur les éléments). Cette passe E2E se concentre spécifiquement sur ce que le QA ne peut pas garantir de la même façon : le parcours critique exécuté avec de **vrais clics souris** (hit-testing réel, pas de dispatch programmatique) — la seule façon de détecter un bouton visuellement présent mais réellement inatteignable (recouvrement, z-index, zone cliquable trop petite). Contre le vrai backend Supabase de production, mot de passe fourni par Romain.

## Parcours testé (un seul scénario continu, de bout en bout, tous les clics réels)
1. Renommage de l'Adversaire ("E2E TEST") via clic + saisie réelle sur le champ
2. Navigation `🤾 Équipes` → `⚡ Match` (clic réel sur les onglets)
3. `▶ Lancer le match` (clic réel)
4. Mode Simple déjà actif (persisté du passage QA précédent) — bloc unique affiché avec la rangée de 5 boutons
5. Clic réel sur `⚽ BUT` (équipe FENIX, en possession) → score FENIX passé à 1, possession basculée vers "E2E TEST", bloc redessiné avec le nouveau libellé/couleur
6. Clic réel sur `🧤 ARRÊT` — **sur le bouton fraîchement redessiné pour l'équipe adverse**, sans re-snapshot intermédiaire, pour vérifier que le vrai clic tombe bien sur le bon élément après le re-rendu (pas un ancien nœud DOM détaché) → événement correctement attribué à "away", possession revenue à "home"
7. `⚙ Réglages` (clic réel) → `💾 Sauvegarder` (clic réel) → "3 match(s) en mémoire" (2 réels + celui-ci, conforme)
8. `📁 Matchs` (clic réel) → entrée "1 - 0 E2E TEST · 2 événements" visible dans la liste (capture d'écran)
9. `🗑` (clic réel) → confirmation → suppression

## Résultat par étape
- ✅ Renommage réel : champ mis à jour, propagé jusqu'à l'écran de lancement puis au scoreboard
- ✅ Lancement réel : chrono démarré, interface complète affichée
- ✅ Premier clic réel sur le bloc Mode Simple : événement enregistré pour la bonne équipe, score et possession mis à jour instantanément
- ✅ **Second clic réel juste après le re-rendu du bloc** (le test le plus significatif de cette passe pour STORY-65) : le clic est tombé sur le bon bouton du nouveau bloc, pas sur un fantôme de l'ancien — confirme que le double-buffer de rendu (`cloneNode`/`replaceChild`, `CLAUDE.md`) ne casse pas l'interactivité immédiate après une bascule de possession en Mode Simple
- ✅ Sauvegarde réelle : compteur exact, pas de doublon (cohérent avec le passage QA)
- ✅ Affichage réel dans Matchs : score/nom/nombre d'événements corrects, capture d'écran `docs/e2e/screenshots/e2e-62-65-01-matchs-liste.png`
- ✅ Suppression réelle confirmée vide côté Supabase après coup

## Écarts avec le verdict QA
Aucun. Tous les parcours testés en vrais clics se comportent exactement comme le QA les avait décrits via dispatch d'événements — aucune divergence détectée entre un clic simulé et un clic réel sur cette interface.

## Console navigateur
0 nouvelle erreur pendant cette passe (vérifié par le compteur par-navigation, qui reste à "0 errors" à chaque étape). Les erreurs 409 visibles dans l'historique cumulé du navigateur proviennent du passage QA précédent (bug hors scope déjà signalé dans `docs/qa/QA-62-65-corrections-audit-et-mode-simple.md`, déjà nettoyé avant cette passe E2E).

## Nettoyage / impact production
Aucune trace laissée : le match de test "E2E TEST" a été supprimé (local + Supabase), vérifié vide par requête directe après coup. Les 2 matchs réels de Romain ("Rodez") n'ont jamais été touchés.

## Verdict
**CONFIRMÉ** — aucun désaccord avec le QA. Le parcours critique de STORY-65 (le plus visible pour l'utilisateur final) fonctionne en conditions réelles de clic, y compris juste après une bascule de possession qui redessine entièrement le bloc de boutons.
