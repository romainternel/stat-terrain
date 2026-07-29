# Audit sécurité — Projet Supabase réel (post-configuration STORY-10)

*Rejoue sur le vrai projet `stat-terrain` (org FENIXCF) les deux findings Critiques identifiés au stade design dans `docs/security/supabase-multiuser.md`. Ce document-ci vérifie l'exécution réelle, pas le plan sur papier.*

## Ressources concernées
- Tables `matches`, `match_events` (projet `stat-terrain`, réf. `kxfhxzbhemnowvbmtwsg`).
- Authentification Supabase (compte unique `romain.ternel@fenix-toulouse.fr`).
- `config.js` : URL + clé `anon`/`publishable`, commitées dans le dépôt public `romainternel/stat-terrain`.

## Vérifications — findings du design, confirmés ou non sur le vrai projet

### 🔴 Critique #1 (design) — Auto-inscription possible si non désactivée
**Vérifié sur le vrai projet.** Capture d'écran fournie par Romain : toggle "Allow new users to sign up" désactivé et sauvegardé (Authentication → Sign In / Providers → User Signups). **Résolu.**

Test complémentaire effectué par simulation d'accès (CDP, requête réelle contre le projet live) :
- Tentative de connexion avec des identifiants invalides → rejetée proprement (`"Invalid login credentials"`), confirme que l'endpoint d'auth répond normalement sans laisser passer n'importe quoi.
- Non testé ici (volontairement, pas d'accès aux vrais identifiants) : qu'une tentative de **création** de compte via l'API échoue bien maintenant que le toggle est désactivé. Recommandation : Romain peut vérifier une fois, depuis un navigateur en navigation privée, que `sbClient.auth.signUp(...)` échoue — test rapide, à faire une seule fois avant tout match réel.

### 🔴 Critique #2 (design) — RLS non activée sur les tables
**Vérifié sur le vrai projet.** Capture d'écran du Table Editor : badge "1 RLS policy" affiché sur `matches` ET `match_events` — confirme à la fois que RLS est activée ET qu'une policy existe (les deux conditions nécessaires, cf. finding original qui distinguait bien les deux).

Test complémentaire effectué par simulation d'accès non autorisé (CDP, requête réelle) :
```
sbClient.from('matches').select('*')  // sans session active
→ { data: [], error: null }
```
0 ligne retournée sans authentification — comportement RLS correct, la table n'est **pas** accessible en clair à quiconque possède seulement la clé anon. **Résolu et vérifié par simulation, pas juste supposé.**

## Nouveaux points vérifiés (spécifiques à l'implémentation réelle)

### 🟢 Clé exposée dans `config.js` (dépôt public)
Vérifié : c'est bien la clé `anon`/`publishable` (préfixe `sb_publishable_`), récupérée depuis la section "Project API keys" du dashboard (pas la section `service_role`). Ce type de clé est conçu pour être public — la sécurité réelle repose sur RLS (vérifiée ci-dessus), pas sur le secret de cette clé. **Pas un finding, comportement attendu.**

### 🟢 Un seul compte utilisateur
Vérifié sur capture d'écran (Users) : un seul utilisateur listé, `romain.ternel@fenix-toulouse.fr`. Le compteur "10 users (estimated)" affiché par le dashboard est un artefact d'estimation Supabase (cache non rafraîchi sur un projet neuf), pas des comptes réels cachés — un seul enregistrement effectivement présent dans le tableau.

### 🟡 Mineur — "Confirm email" toujours activé globalement
Le toggle "Confirm email" (Authentication → Sign In / Providers) est resté activé. Sans impact réel puisque l'auto-inscription est désactivée (personne ne peut passer par ce chemin) — mentionné pour mémoire, pas une action requise.

## Verdict

**Feu vert pour F6/F7.** Les deux findings Critiques du design sont confirmés résolus sur le vrai projet, par vérification directe (capture d'écran des réglages) et par simulation d'accès non autorisé (requête réelle bloquée), conformément à mon mandat ("je ne suppose jamais qu'une protection côté interface suffit, je vérifie côté serveur/base"). Aucun blocage restant pour continuer vers STORY-11.
