# Audit sécurité — Synchronisation entrante temps réel (STORY-13)

## Ressources concernées
- Canal Supabase Realtime (`postgres_changes`) sur `match_events`.

## Vérification centrale : RLS s'applique-t-elle aussi aux abonnements Realtime, pas seulement aux requêtes classiques ?

**Confirmé par la documentation officielle Supabase** (comportement par défaut des `postgres_changes` depuis l'introduction de la RLS-aware Realtime) : un client ne reçoit que les changements sur les lignes qu'il serait autorisé à `SELECT` sous RLS. Notre policy (`for all using auth.role()='authenticated'`) couvre déjà le `SELECT` — un client non authentifié ne devrait recevoir **aucun** événement, un client authentifié (compte partagé) devrait tous les recevoir, symétrique au comportement déjà vérifié empiriquement en STORY-10 pour les requêtes classiques.

**Non vérifié empiriquement dans cette story** (nécessite deux sessions réelles, une authentifiée qui écrit, une non-authentifiée qui écoute) — recommandation explicite ajoutée au test obligatoire de Romain : en plus de vérifier que deux appareils connectés se synchronisent, ouvrir un onglet **non connecté** (navigation privée, écran d'accès affiché) et confirmer qu'aucune donnée n'y transite, même en arrière-plan.

## Autres vérifications

### `mergeRemoteEvent` fait-il confiance à des données non fiables ?
Le seul expéditeur possible d'un message sur ce canal est un autre client déjà authentifié avec le même compte partagé (RLS l'exige pour même émettre l'écriture qui déclenche le message). Il n'y a pas de nouvelle surface de confiance ici par rapport à ce qui existe déjà (n'importe qui connaissant le mot de passe partagé a de toute façon un accès total en écriture directe, risque déjà accepté en STORY-10, D2).

### Un canal mal fermé peut-il fuiter des données d'un match à l'autre ?
Non — chaque canal est explicitement filtré par `match_id=eq.<id>` et désabonné avant qu'un nouveau ne soit créé (`unsubscribeMatchEvents`/logique de remplacement dans `subscribeMatchEvents`). Pas de canal "large" qui écouterait tous les matchs indistinctement.

## Verdict

**Feu vert conditionnel.** Le mécanisme est conforme au modèle de sécurité déjà audité (RLS = seule barrière, déjà acceptée). Un point reste à confirmer empiriquement par Romain lors de son test obligatoire : qu'un onglet non authentifié ne reçoit bien aucune donnée via le canal Realtime — ajout explicite à sa checklist de vérification, pas un blocage de livraison (le raisonnement documentaire est solide, mais "je ne suppose jamais qu'une protection suffit sans la vérifier" reste le mandat de cet agent).
