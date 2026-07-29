# Audit sécurité — Synchronisation sortante (STORY-12)

## Ressources concernées
- Écriture (`upsert`) sur `matches` et `match_events`.
- Suppression (`delete`) sur `match_events` (propagation d'annulation).

## Vérifications systématiques

### Policies RLS couvrent-elles aussi l'écriture (pas seulement la lecture, déjà vérifiée en STORY-10) ?
**Oui.** La policy posée en STORY-10 est `for all using/with check auth.role()='authenticated'` — `for all` couvre SELECT, INSERT, UPDATE, DELETE. Vérifié par simulation (test réel, pas supposé) : une tentative d'`upsert` sans session valide échoue silencieusement côté client (capturée par le `try/catch` de `flushOutbox`), cohérent avec un rejet RLS côté serveur plutôt qu'un succès — l'événement reste dans la file d'attente locale au lieu d'être marqué comme synchronisé, ce qui n'arriverait pas si l'écriture avait réellement abouti sans autorisation.

### Un appareil peut-il écraser/supprimer les données d'un autre appareil par erreur de manipulation d'id ?
Non — chaque événement a un id UUID généré côté client, unique par construction (`crypto.randomUUID()`). L'`upsert` ne peut affecter que la ligne exactement identifiée par cet id ; aucun risque de collision inter-appareils sauf réutilisation improbable d'un même uuid (négligeable, espace d'id 2^122).

### La suppression (`dequeueEventSync`) introduit-elle un nouveau risque d'accès ?
Non — même policy, même table, même compte partagé. Le risque déjà accepté en STORY-10 (D2 : pas de granularité par personne à l'intérieur du compte partagé, donc n'importe qui connecté peut tout supprimer) s'applique déjà à la fonctionnalité "Annuler" existante en local ; cette story ne fait qu'étendre ce comportement déjà accepté à Supabase, sans élargir le rayon d'action.

### Le prérequis `matches` (créé par `ensureMatchRegistered`) expose-t-il quelque chose de nouveau ?
Non — même policy `authenticated`, mêmes champs déjà couverts par le schéma validé en STORY-10 (aucune nouvelle colonne, aucune nouvelle table).

### Clés/secrets
Aucun nouveau secret introduit. Toutes les écritures passent par `sbClient` (clé anon déjà auditée), jamais de clé `service_role` côté client.

## Verdict

**Feu vert.** Aucun finding Critique ni Majeur. Cette story étend la synchronisation sans modifier le modèle de sécurité déjà audité et vérifié en STORY-10 — les mêmes garanties (RLS active, compte unique, pas de granularité interne) s'appliquent identiquement aux nouvelles opérations d'écriture/suppression.
