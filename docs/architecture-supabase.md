# Architecture — Stockage Supabase + saisie partagée

*Produit par l'Architect — squad build BMAD*
*S'appuie sur `docs/prd-v2-cloud-multiuser.md` et `docs/design/acces-partage-et-reprise-match.md`*

## Verdict sur la question "déconstruire pour reconstruire ?"

**Non, pas de reconstruction de l'app.** Je confirme et je précise la recommandation de l'Analyst : on ne touche ni au rendu (`R()` et toutes les fonctions `render*`), ni au workflow de saisie (`selectAction`, `clickTeam`, `clickActionPlayer`, `clickGoalZone`, `validateActionPanel`...), ni aux stats/PDF. Tout ça reste exactement comme aujourd'hui.

**Ce qui est réellement reconstruit : la couche de persistance.** Aujourd'hui : `S` en mémoire → `dbSaveMatch()` une seule fois en fin de match → IndexedDB. Demain : `S` en mémoire → écriture IndexedDB immédiate à chaque événement (déjà prévu par STORY-01 du cycle 1) → **file d'attente de synchronisation** vers Supabase, en tâche de fond, jamais bloquante. C'est une brique en plus, pas une réécriture de l'existant.

## Décision technique — Supabase

### Client
- `supabase-js` chargé via CDN (`<script>` dans `index.html`), exactement comme `jsPDF` aujourd'hui — cohérent avec le principe du projet ("pas de bundler, pas de build step").
- Config isolée dans un **nouveau petit fichier `config.js`**, chargé avant `app.js` :
  ```js
  const SUPABASE_URL = "...";
  const SUPABASE_ANON_KEY = "...";
  ```
  Cloner l'app pour un autre coach = copier le repo + remplacer ces deux lignes. `app.js` ne contient jamais ces valeurs en dur — ça répond directement à F9 et à la contrainte de Romain de ne pas "mélanger le contenu" entre déploiements.

### Authentification (F7)
- **Un seul compte Supabase Auth pré-créé** pour ce déploiement (ex : `coach@fenix.local` + mot de passe choisi par Romain), jamais un compte par personne.
- L'écran d'accès (maquette Designer) ne demande que le **mot de passe** — l'email est fixe, stocké dans `config.js` avec l'URL/clé (ce n'est pas un secret, juste un identifiant de compte).
- La session Supabase (token) est persistée automatiquement par `supabase-js` (localStorage) — pas de redemande à chaque ouverture, cohérent avec le critère d'acceptation F7.

### Schéma de données

```sql
matches (
  id uuid primary key default gen_random_uuid(),
  status text not null default 'in_progress',  -- 'in_progress' | 'finished'
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  home_name text, away_name text,
  home_roster jsonb,   -- snapshot de l'effectif au démarrage du match
  away_roster jsonb,
  home_gk_id text, away_gk_id text,
  period int, time_offset_seconds int, running boolean, last_start_at timestamptz,
  timeouts jsonb        -- compteur TM par équipe/mi-temps
)

match_events (
  id uuid primary key,          -- généré CÔTÉ CLIENT (uuid v4), jamais par la base
  match_id uuid references matches(id),
  type text, team text, time int, raw_time int, period int,
  x real, y real, gk_id text,
  player_id text, player_name text, player_number text,
  assist_id text, assist_name text, assist_number text,
  goal_zone text,
  created_at timestamptz default now()
)
```

**Pourquoi l'id des événements est généré côté client** : c'est ce qui permet à deux appareils d'insérer sans jamais créer de doublon même en cas de rejeu (retry après coupure réseau) — un insert avec un id déjà existant est simplement ignoré (upsert idempotent), au lieu de créer un deuxième événement identique.

**Pourquoi le timer n'est pas écrit à chaque seconde** : stocker `running` + `last_start_at` + `time_offset_seconds` permet à n'importe quel appareil de recalculer le temps affiché localement (`offset + (now - last_start_at)` si `running`), sans avoir besoin d'un write par seconde vers Supabase — un write suffit à chaque start/pause/changement de mi-temps.

### RLS (policies)
Un seul projet Supabase = une seule "équipe" (D3 du brief) → pas de séparation par utilisateur à l'intérieur du projet. Policy simple et volontairement plate :
```sql
create policy "authenticated full access"
on matches for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');
-- idem sur match_events
```
Pas de règle par `user_id` : n'importe quel appareil connecté avec le compte partagé du projet a accès à tout — c'est le comportement voulu (D2 : pas d'identité individuelle à l'intérieur de l'app). La vraie barrière de sécurité est **en amont** : qui connaît le mot de passe du compte partagé.

### Synchronisation (offline-first)

1. **Écriture locale immédiate** (déjà prévu par STORY-01 du cycle 1) : chaque événement va d'abord dans `S.events` + IndexedDB, sans jamais attendre le réseau.
2. **File d'attente ("outbox")** : chaque événement local est aussi ajouté à une file `pendingSync` (IndexedDB), traitée par une fonction `flushOutbox()` :
   - Appelée après chaque nouvel événement, sur l'événement navigateur `online`, et par un intervalle de rattrapage (ex : toutes les 15s tant que la file n'est pas vide).
   - Envoie les événements en attente vers `match_events` par petits lots ; en cas d'échec réseau, ne fait rien de plus, retentera au prochain déclenchement.
3. **Réception temps réel** : abonnement Supabase Realtime sur `match_events` filtré par `match_id`. Un événement reçu d'un autre appareil est fusionné dans `S.events` (par id, pas de doublon si l'app l'a déjà via son propre outbox), puis `R()` est appelé pour rafraîchir l'affichage.
4. **Reprise de match** (écran Designer "Matchs en cours") : au chargement, requête `matches` où `status='in_progress'`. Si un match ouvert existe, proposer de le reprendre : charger le snapshot `matches` + tous les `match_events` liés pour reconstituer `S`.

### Impact sur l'existant

- `dbSaveMatch()` : ne change pas de rôle (toujours le point de sauvegarde "match terminé" en local) — un miroir Supabase du même contenu est envoyé en plus, pas à la place.
- `recordEvent()` : gagne un appel supplémentaire (ajout à l'outbox) après l'écriture locale actuelle — pas de changement de signature ni de comportement visible.
- `sw.js` : les assets CDN (jsPDF, Google Fonts, et maintenant `supabase-js`) ne sont pas dans la liste de précache (`ASSETS`) mais la stratégie de fetch actuelle (network-first avec fallback cache, sans distinction d'origine) les met déjà en cache après un premier chargement réussi — pas de régression, mais je recommande d'ajouter `supabase-js` à la précache explicite pour fiabiliser le tout premier lancement en conditions de réseau faible (gymnase). Bump de version `sw.js` nécessaire (ex : `fenix-stats-v48`) dès ce changement, comme à chaque déploiement.

### Nouvelles fonctions (responsabilités)
- `initSupabaseClient()` — instancie le client à partir de `config.js`.
- `signInShared(password)` — connexion avec le compte unique.
- `queueEventForSync(event)` / `flushOutbox()` — gestion de la file d'attente.
- `subscribeMatchEvents(matchId)` / `mergeRemoteEvent(event)` — réception temps réel.
- `fetchInProgressMatches()` / `resumeMatch(matchId)` — reprise de match sur un nouvel appareil.
- `upsertMatchSnapshot()` — écrit l'état global du match (score, GK, timer, period) sur changement significatif (pas à chaque frame).

## Risques (vue technique)

Voir `docs/risks/supabase-multiuser.md` pour le détail complet (Risk Analyst) — le point le plus sensible du point de vue architecture est la dépendance réseau en gymnase : toute la conception ci-dessus part du principe que **la saisie ne doit jamais attendre Supabase**, uniquement s'en servir en best-effort.

## Critère de bascule

Si un jour ce projet doit gérer plusieurs équipes/coachs dans le **même** projet Supabase (multi-tenant réel), la policy RLS plate décrite ici ne suffira plus — il faudra alors une vraie notion de `team_id`/`owner_id` par ligne. Ce n'est pas le cas aujourd'hui (chaque coach a son propre projet, D3) donc pas nécessaire maintenant.
