# QA — STORY-13 : Synchronisation entrante (temps réel)

## Méthode de test
Tests réels via CDP sur la logique de fusion (pas de simulation d'état) — appels directs aux fonctions avec des payloads représentatifs du format réel des lignes Supabase.

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| Événement saisi sur A apparaît sur B en quelques secondes | ⚠️ **Non vérifiable par le QA** | Nécessite deux sessions authentifiées réelles. Mécanisme implémenté et sa logique interne vérifiée ; la réception réelle bout-en-bout reste à faire par Romain (critère obligatoire du Risk Analyst, pas optionnel) |
| Aucun doublon visuel/statistique | ✅ | Testé : écho d'un événement déjà connu (même id) → mis à jour en place, `S.events.length` inchangé |
| Déconnexion/reconnexion ne casse pas l'abonnement | ✅ (mécanisme) | Ré-abonnement défensif sur `online` vérifié présent dans le code ; combiné à la reconnexion native de `supabase-js`. Non testé en conditions de coupure réseau réelle (difficile à simuler fidèlement via CDP) |
| Test sur vrai déploiement (pas localhost seul) | ⚠️ **Non vérifiable par le QA** | Idem — à faire par Romain |

## Point critique trouvé pendant la vérification
En préparant les tests, découverte que la réplication Realtime n'était pas activée sur `match_events` côté Supabase (étape absente du script SQL de STORY-10) — sans elle, **aucun test à deux appareils n'aurait pu fonctionner**, silencieusement. Corrigé : script `docs/supabase-realtime-setup.sql` fourni, à exécuter par Romain avant son test. Sans ce script, ne pas considérer cette story testable du tout côté deux-appareils.

## Cas limites testés
- Insertion d'un événement distant plus ancien que tous les événements locaux déjà présents (doit s'insérer en fin de liste, pas en tête) : testé et correct.
- Insertion d'un événement distant intercalé chronologiquement entre deux événements locaux existants : testé et correct (position exacte vérifiée).
- Suppression distante d'un événement présent localement : testé et correct (simulé, la vraie propagation Realtime nécessite deux sessions réelles).

## Bugs trouvés
Aucun dans la logique elle-même. Le point Realtime non activé (ci-dessus) est une omission de configuration, pas un bug de code — corrigée avant que Romain ne puisse être bloqué dessus.

## Régressions détectées
Aucune. STORY-12 (sync sortante) non affectée par cet ajout.

## Verdict
**PASSED WITH NOTES**

La logique de fusion est solide et vérifiée concrètement. Les critères nécessitant deux sessions réelles restent à la charge de Romain — ce n'est pas un échec, c'est la nature même de cette story (elle ne peut réellement se prouver qu'en conditions multi-appareils réelles, exactement comme le Risk Analyst l'avait anticipé).
