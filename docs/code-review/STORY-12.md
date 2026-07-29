# Code Review — STORY-12 : Synchronisation sortante (outbox)

## Périmètre revu
- `app.js` : `gid()` (UUID v4), `OUTBOX_STORE`/`DB_VER` bump, `outboxPut`/`outboxGetAll`/`outboxDelete`, `eventToSupabaseRow`, `ensureMatchRegistered`, `queueEventForSync`, `flushOutbox`, `dequeueEventSync`, appels ajoutés à tous les points de création/édition d'événement + `undoLast()`.
- `sw.js` : bump v64.

## Conformité architecture
- Respecte `docs/architecture-supabase.md` : id généré côté client, file d'attente persistée en IndexedDB, `flushOutbox()` déclenchée après chaque événement + `online` + intervalle 15s, upsert idempotent.
- **Déviation bien gérée et documentée** : le changement de `gid()` vers de vrais UUID v4 n'était pas explicitement demandé mais nécessaire (colonne `uuid` côté Supabase). Vérifié : recherche exhaustive de tout code parsant le format d'id → aucun trouvé, changement sûr.
- **Ajout hors texte strict, bien justifié** : `ensureMatchRegistered()` (prérequis FK non mentionné explicitement dans la story mais indispensable), et `dequeueEventSync()` pour propager les annulations (gap réel identifié : sans ça, un `undo` resterait invisible sur les autres appareils). Les deux sont documentés clairement dans les notes Developer avec leurs limites assumées — exactement le type de déviation à signaler plutôt qu'à cacher.

## Conventions de code
- Cohérent avec le reste du fichier. Bonne discipline : chaque fonction de sync est `try/catch`-ée individuellement, jamais de point de défaillance qui remonterait à l'UI.

## Réutilisation vs duplication
- Point à signaler (non bloquant) : les 6 points de création/édition d'événement (`clickTeam` TM, `recordTM`, `validateActionPanel`×2 branches, `validateAndClose`×2 branches, `recordEvent`) appellent chacun `queueEventForSync()` séparément — c'est de la répétition d'un seul appel, pas une vraie duplication de logique (chaque site a de toute façon sa propre construction d'événement déjà dupliquée avant cette story). Une factorisation plus poussée (un seul point d'entrée `pushEvent()` qui fait `unshift` + `queueEventForSync`) aurait été plus élégante, mais aurait touché à la structure déjà existante de 6 fonctions distinctes — risque de régression plus élevé que le bénéfice pour cette story. Acceptable tel quel.

## Scope
- Diff contenu à la synchronisation sortante. Aucune touche à la réception (STORY-13) ni à la reprise de match (STORY-14).

## Gestion d'erreurs
- Exemplaire pour ce type d'intégration best-effort : `queueEventForSync`, `flushOutbox`, `ensureMatchRegistered`, `dequeueEventSync` échouent tous silencieusement (try/catch) sans jamais remonter d'exception à l'appelant — cohérent avec le principe "la saisie ne doit jamais dépendre de Supabase".
- `flushInProgress` (verrou simple) évite les flush concurrents qui se chevaucheraient — bon réflexe.

## Sécurité basique
- Aucune clé/secret nouvelle exposée. Les écritures passent par le client authentifié (`sbClient`), protégées par RLS déjà vérifiée en STORY-10 — à confirmer par le Security Auditor que rien ici ne contourne ça (story touchant une ressource backend).

## Verdict
**APPROUVÉ**, sous réserve du passage du Security Auditor (obligatoire, story touchant une ressource backend).
