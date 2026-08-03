# Audit sécurité — Reprise de match sur un autre appareil (STORY-14)

## Ressources concernées
- Lecture de `matches` (liste des matchs `in_progress`, puis lecture d'un match spécifique).
- Lecture de `match_events` filtrée par `match_id` (déjà couverte par STORY-13).
- Écriture élargie sur `matches` (roster, GK, période, chrono, statut).

## Vérifications

### La liste des matchs "en cours" expose-t-elle quelque chose de sensible ?
Non — noms d'équipes et horaire de début, aucune donnée personnelle identifiante au-delà de ce qui est déjà visible dans l'app une fois connecté (noms de joueurs déjà accessibles via `home_roster`/`away_roster` de toute façon, protégés par la même policy RLS `authenticated`). Pas de nouvelle catégorie de donnée exposée par rapport à ce qui était déjà accepté en STORY-10.

### `resumeMatch()` peut-il charger un match qu'il ne devrait pas ?
Non — la policy RLS (`for all using auth.role()='authenticated'`) s'applique de la même façon qu'aux lectures déjà vérifiées : un client non authentifié ne peut lire ni `matches` ni `match_events` (déjà confirmé empiriquement en STORY-10/12). Un client authentifié avec le compte partagé peut tout lire — cohérent avec D2 (pas de granularité par personne), aucun élargissement du modèle de menace.

### L'écriture élargie du snapshot (roster complet, GK, chrono) introduit-elle un risque ?
Non — même table, même policy, mêmes colonnes déjà définies dans le schéma de STORY-10 (`home_roster`/`away_roster`/`home_gk_id`/etc. existaient déjà dans le schéma SQL, simplement non utilisées jusqu'ici). Pas de nouvelle colonne, pas de nouvelle table.

### Le statut "finished" peut-il être usurpé pour masquer un match à tort ?
Le compte partagé unique a de toute façon un accès total en écriture (déjà accepté) — marquer un match "finished" par erreur serait au pire une gêne (il faudrait le rouvrir manuellement via le dashboard Supabase), pas une fuite ou une perte de données (les événements restent en base, seul le champ `status` change). Impact limité, cohérent avec le risque déjà accepté #3 de `docs/risks/supabase-multiuser.md`.

## Verdict

**Feu vert.** Cette story élargit l'usage des colonnes déjà définies et déjà protégées par la policy RLS auditée en STORY-10 — aucun nouveau vecteur d'accès non autorisé introduit. Aucun finding Critique ni Majeur.
