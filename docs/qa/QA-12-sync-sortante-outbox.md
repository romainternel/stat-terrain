# QA — STORY-12 : Synchronisation sortante (outbox)

## Méthode de test
Tests réels via CDP contre le vrai projet Supabase (sans session valide, faute d'accès aux identifiants — cf. limite documentée). Vérification directe de l'état IndexedDB (`outboxGetAll()`), pas de simulation.

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| Action sans réseau/session enregistrée localement, sans erreur visible | ✅ | Événement créé normalement (`S.events`), aucune exception, aucun message d'erreur affiché à l'utilisateur |
| Envoi automatique dès que possible, sans action de Romain | ⚠️ Mécanisme vérifié, envoi réussi non vérifiable | `flushOutbox()` s'exécute automatiquement (après événement, `online`, intervalle 15s) ; l'échec sans session est confirmé silencieux et correct, mais un envoi **réussi** contre le vrai projet nécessite une vraie session (à vérifier par Romain) |
| Pas de doublon sur rejeu d'un envoi déjà réussi | ✅ | `upsert()` sur clé primaire `id` (uuid stable) — idempotent par construction, propriété du mécanisme Supabase, pas une supposition |
| File d'attente survit à un rechargement complet | ✅ | Testé : événement mis en file (IndexedDB), page rechargée, événement toujours présent et prêt à être retenté |
| Aucune régression de vitesse de saisie perceptible | ✅ | Vérifié par lecture de code : aucun `await` sur `queueEventForSync()` dans les chemins d'écriture (`recordEvent`, `validateActionPanel`, etc.) — la fonction retourne immédiatement, la sync se fait après |

## Cas limites testés
- `gid()` : vérifié qu'il produit un vrai UUID v4 valide (regex de conformité), pas juste "quelque chose qui ressemble".
- Annulation (`undoLast()`) d'un événement encore en file d'attente : retiré correctement de la file avant tout envoi.
- Événement créé via le mode Simple (STORY-24, `recordEvent` réutilisée) : correctement mis en file également — pas un chemin oublié.

## Bugs trouvés
Aucun.

## Point non couvert (documenté, pas un échec)
- Envoi réussi vers le vrai projet Supabase, avec une vraie session : non vérifiable par le QA (pas d'accès aux identifiants). Romain doit vérifier une fois en conditions réelles : se connecter, saisir quelques événements, ouvrir Supabase → Table Editor → `match_events`, confirmer que les lignes apparaissent avec les bonnes valeurs.
- Suppression propagée (`dequeueEventSync`) en cas de coupure réseau au moment précis de l'annulation d'un événement déjà synchronisé ailleurs : limite connue et documentée par le Developer (pas de file de suppression avec retry) — accepté, pas un bug de cette story.

## Régressions détectées
Aucune. Testé : les 5 écrans de l'app restent fonctionnels, le workflow BUT complet (Expert) et le mode Simple fonctionnent normalement avec les appels de sync ajoutés.

## Verdict
**PASSED WITH NOTES**

Tous les critères vérifiables par le QA sont satisfaits. L'envoi réussi contre le vrai projet reste à valider par Romain — recommandation : le faire avant le prochain vrai match, pas un blocage du déploiement.
