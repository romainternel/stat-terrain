# QA — STORY-14 : Reprise de match sur un autre appareil

## Méthode de test
Tests réels via CDP. Le client Supabase (`sbClient.from`) a été temporairement mocké pour simuler les réponses réseau (match + événements) et vérifier la logique de reconstruction de `resumeMatch()` de façon isolée et déterministe, sans dépendre d'une vraie session.

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| Match en cours proposé clairement avec "Reprendre" | ✅ | Écran dédié affiché après connexion, capture d'écran vérifiée visuellement, conforme à l'esprit de la maquette (déviation du point d'affichage documentée et justifiée) |
| Reprise restaure l'état exact | ✅ | Testé avec données simulées : noms d'équipe, effectifs (1 joueur chacun), période (2), chrono (300s), 2 événements correctement mappés et triés chronologiquement — vérifié champ par champ |
| Aucun changement si pas de match en cours | ✅ | Vérifié par lecture de code : `checkForResumableMatch()` ne fait rien si `fetchInProgressMatches()` retourne un tableau vide |
| Sync active après reprise | ✅ | `resumeMatch()` pose `S.currentMatchId` et appelle `subscribeMatchEvents()` avant de rendre l'écran Match |
| Test réel bout-en-bout (créer sur A, reprendre sur B) | ⚠️ **Non vérifiable par le QA** | Nécessite une vraie session Supabase — à faire par Romain |

## Cas limites testés
- Chrono en cours d'exécution au moment du snapshot (`running:true` avec `last_start_at`) : le temps écoulé est recalculé, pas juste lu tel quel — logique vérifiée par lecture de code (`Date.now() - last_start_at`).
- "Lancer le match" crée bien `S.currentMatchId` immédiatement, avant tout événement — testé par clic réel.
- Dismiss ("Non, nouveau match") : `S.resumePrompt` repasse à `null`, l'écran Équipes normal s'affiche, testé par clic réel.

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune. Testé : workflow BUT complet (Expert), démarrage/arrêt du chrono, changement de mi-temps, les 5 écrans de l'app, `newMatch()` — tous fonctionnels, aucune erreur console à aucun moment.

## Verdict
**PASSED WITH NOTES**

Toute la logique de reconstruction est vérifiée concrètement avec des données simulées, pas supposée. Le scénario réel à deux appareils (le cœur de cette story) reste à la charge de Romain, cohérent avec les stories précédentes du même chantier.
