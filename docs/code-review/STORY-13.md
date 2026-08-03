# Code Review — STORY-13 : Synchronisation entrante (temps réel)

## Périmètre revu
- `app.js` : `supabaseRowToEvent`, `mergeRemoteEvent`, `subscribeMatchEvents`/`unsubscribeMatchEvents`, appels ajoutés dans `queueEventForSync` (abonnement à la création du match) et `newMatch()` (désabonnement), ré-abonnement défensif dans le listener `online`.
- `docs/supabase-realtime-setup.sql` (nouveau) : activation de la réplication Realtime sur `match_events`.
- `sw.js` : bump v65.

## Conformité architecture
- Conforme à `docs/architecture-supabase.md` (fonctions nommées comme spécifié, fusion par id).
- **Trouvaille importante, bien gérée** : l'absence d'activation de la réplication Realtime (`alter publication supabase_realtime add table ...`) est exactement le genre de piège silencieux que `docs/risks/supabase-multiuser.md` (risque #2) anticipait — bon réflexe de l'avoir cherché activement plutôt que de supposer que RLS seule suffit.

## Conventions de code
- Cohérent avec le reste du fichier. Symétrie `eventToSupabaseRow` / `supabaseRowToEvent` bien nommée, facile à suivre.
- Un seul canal global (`realtimeChannel`) avec désabonnement systématique avant recréation — évite l'accumulation d'abonnements fantômes, bon réflexe pour un mécanisme rappelé potentiellement plusieurs fois (reconnexion réseau).

## Réutilisation vs duplication
- RAS.

## Scope
- Diff contenu à la réception temps réel. N'a pas touché à `queueEventForSync`/`flushOutbox` (STORY-12) au-delà de l'ajout de l'appel d'abonnement — vérifié, pas de logique de sync sortante modifiée.

## Point à vérifier par le Security Auditor
- Les subscriptions `postgres_changes` sont-elles bien soumises à RLS comme les requêtes classiques ? (déjà noté comme risque #2 par le Risk Analyst — à confirmer explicitement, pas juste supposer que "ça doit marcher comme RLS normal".)
- La fonction `mergeRemoteEvent` fait-elle confiance aveuglément aux données reçues via le canal (`payload.new`) ? Vérifier qu'aucune validation supplémentaire n'était nécessaire ici (le seul expéditeur possible est un autre appareil déjà authentifié avec le même compte partagé).

## Verdict
**APPROUVÉ**, sous réserve du passage du Security Auditor (obligatoire, story touchant le canal Realtime backend).
