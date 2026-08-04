# STORY-27 — Suppression réelle d'un match sur Supabase

## Origine
Question directe de Romain après la clôture du chantier Supabase : « Il manque peut-être aussi la sauvegarde du match ou la possibilité quand il a été sauvegardé de le supprimer et donc de supprimer les données de ce match sur supabase ? »

Vérification : `saveMatch()` marquait déjà correctement le match Supabase comme `status:'finished'` (via `markMatchFinished()`, existant depuis STORY-14), mais **supprimer un match depuis l'historique local (`[data-del-match]`) ne supprimait jamais rien côté Supabase** — la ligne `matches` et tous ses `match_events` restaient indéfiniment sur le serveur, alors que l'app donnait l'impression d'une suppression complète.

## Comportement attendu
- Quand un match sauvegardé est supprimé depuis l'écran Matchs (historique), sa ligne `matches` correspondante ET tous ses `match_events` sont aussi supprimés sur Supabase.
- La suppression Supabase est **best-effort** : elle ne bloque jamais la suppression locale (cohérent avec le principe fail-open déjà établi dans ce projet — voir CLAUDE.md), et une panne réseau au moment de la suppression n'empêche pas l'utilisateur de continuer à utiliser l'app normalement.
- **Limite acceptée et documentée** : cette fonctionnalité ne peut s'appliquer qu'aux matchs sauvegardés **après** ce correctif. Les matchs déjà présents dans l'historique local avant cette story n'ont jamais eu leur identifiant Supabase (`supabaseMatchId`) enregistré — ils ne peuvent donc pas être nettoyés automatiquement côté serveur. Vu le volume de données concerné (une saison de handball), ce n'est pas un problème pratique.

## Notes d'implémentation
- Nouveau champ `supabaseMatchId` (= `S.currentMatchId` au moment de la sauvegarde) ajouté à l'objet match persisté par `saveMatch()`.
- Nouvelle fonction `deleteSupabaseMatch(matchId)` : supprime d'abord les lignes `match_events` (par `match_id`), puis la ligne `matches` — le schéma (`docs/supabase-setup.sql`) n'a pas de `ON DELETE CASCADE`, l'ordre est donc important pour ne pas heurter la contrainte de clé étrangère.
- Handler `[data-del-match]` : après la suppression locale réussie, appelle `deleteSupabaseMatch(m.supabaseMatchId)` si ce champ existe sur le match supprimé.

## Hors scope
- Nettoyage rétroactif des matchs déjà sauvegardés avant cette story (voir limite ci-dessus).
- Ajout d'un `ON DELETE CASCADE` au schéma SQL (l'ordre explicite de suppression dans le code suffit, pas de migration nécessaire).

## Dépend de
STORY-12, STORY-14.

## Taille
XS
