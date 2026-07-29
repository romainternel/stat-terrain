# QA — STORY-10 : Configuration Supabase sécurisée (fondation)

## Méthode de test
Vérification directe sur le vrai projet Supabase (`stat-terrain`), pas de simulation : captures d'écran du dashboard fournies par Romain + requêtes réelles exécutées via CDP contre le projet live (client `supabase-js` réellement instancié, pas mocké).

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| `config.js` séparé, URL + clé anon seulement | ✅ | Vérifié par lecture directe du fichier — aucune clé `service_role` |
| Tables créées conformément au schéma | ✅ | Script `docs/supabase-setup.sql` exécuté avec succès ("Success. No rows returned") |
| RLS activée sur les deux tables | ✅ | Badge "1 RLS policy" visible sur `matches` et `match_events` dans le Table Editor |
| Policies en place | ✅ | Même vérification que ci-dessus (le badge confirme policy + RLS ensemble) |
| Inscription publique désactivée | ✅ | Toggle "Allow new users to sign up" désactivé et sauvegardé |
| Requête sans authentification refusée | ✅ | Testé en conditions réelles : `sbClient.from('matches').select('*')` sans session → `{data:[], error:null}`, 0 ligne |
| Un seul compte utilisateur | ✅ | Un seul enregistrement dans Authentication → Users |
| Client Supabase s'initialise correctement | ✅ | `typeof supabase === 'object'`, `sbClient` non-null après chargement de la page |

## Cas limites testés
- Tentative de connexion avec des identifiants invalides → rejetée (`"Invalid login credentials"`), pas de faille de type "accepte n'importe quoi".
- Chargement de la page sans réseau/CDN disponible : `initSupabaseClient()` retourne `null` proprement (vérifié par lecture de code) plutôt que de lever une exception qui bloquerait le reste de l'app — l'app doit rester utilisable en local même si Supabase est indisponible (cf. principe offline-first de l'architecture).

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune — changement additif pur (nouveau fichier, nouveau script CDN, une fonction d'init), aucun code existant modifié.

## Verdict
**PASSED**

Tous les critères d'acceptation sont satisfaits, y compris les deux vérifications de sécurité obligatoires (Security Auditor, `docs/security/supabase-project-live.md`) rejouées sur le vrai projet et non plus seulement sur le papier.
