# QA — STORY-11 : Écran d'accès partagé

## Méthode de test
Tests réels via CDP — vrais clics et vraie saisie clavier (`Input.dispatchKeyEvent`), sur iPad (1024×768) et iPhone portrait (390×844). Le client Supabase utilisé est le vrai client connecté au projet `stat-terrain` (pas de mock).

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| Écran à un seul champ + bouton "Entrer" avant l'app | ✅ | Vérifié : sans session, `.access-screen` s'affiche, `.match-layout`/`.setup-grid` absents du DOM |
| Mauvais mot de passe → erreur claire | ✅ | Testé avec un mauvais mot de passe réel contre le vrai projet : `"Code d'accès incorrect."` affiché, pas d'ambiguïté possible (un seul champ existe) |
| Persistance de session (pas de redemande à chaque ouverture), testée sur iPad/iPhone Safari réel | ⚠️ **Non vérifiable par le QA** | Nécessite les vrais identifiants du compte partagé, connus uniquement de Romain, et un vrai appareil iOS (fermeture complète de Safari). Mécanisme sous-jacent (persistance `localStorage` par `supabase-js`) est le comportement standard de la librairie, non modifié par ce code — mais **ce n'est pas la même chose que vérifié concrètement**. Recommandation : Romain doit faire ce test lui-même avant de considérer STORY-11 totalement terminée, cf. section dédiée dans la story. |
| Déconnexion explicite disponible dans les réglages | ✅ | Bouton "🔒 Se déconnecter" présent dans le panneau Réglages du Match (uniquement si Supabase configuré), testé : ramène bien à l'écran d'accès après confirmation |

## Cas limites testés
- Supabase non configuré/indisponible (simulé) : l'app reste utilisable (fail-open), pas de blocage — comportement voulu, vérifié par lecture de code et cohérent avec le principe déjà établi.
- Appui sur "Entrée" clavier dans le champ mot de passe : déclenche la connexion comme le bouton "Entrer" (testé, pas seulement supposé par lecture de code).

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune. Le reste de l'app (Match, Stats, Équipes, Bilan) fonctionne normalement une fois l'accès autorisé — vérifié en forçant `S.authOk=true` puis en naviguant entre écrans.

## Verdict
**PASSED WITH NOTES**

Tous les critères vérifiables par le QA sont satisfaits. Un critère (persistance de session testée sur vrai appareil iOS avec vrais identifiants) reste explicitement en attente de vérification par Romain — ce n'est pas un échec, c'est un test qui nécessite un accès que le QA n'a pas et ne doit pas demander (mot de passe du compte partagé).
