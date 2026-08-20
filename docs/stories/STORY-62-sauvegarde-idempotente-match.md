# STORY-62 — Sauvegarder un match en cours ne crée plus de doublon

**En tant que** Romain,
**Je veux** que cliquer plusieurs fois sur "💾 Sauvegarder" pendant/après le même match mette à jour la même entrée,
**Afin de** ne jamais fausser silencieusement les statistiques de Bilan → Saison avec un match compté en double.

Trouvé par l'Audit Final du 2026-08-20 (`docs/audit-final/AUDIT-2026-08-20.md`, finding Gênant) : `saveMatch()` génère un `id:Date.now()` neuf à chaque appel, sans jamais vérifier si la session en cours a déjà été sauvegardée.

## Contexte technique
- Zone concernée : `saveMatch()` (`app.js:1605`), `newMatch()` (`app.js:1681`), `loadMatchAsCurrent()` (`app.js:1709`)
- Nouvelle structure : `S.savedMatchId` (`null` par défaut) — voir `docs/arch/audit-corrections-et-mode-simple.md` section F1 pour le détail exact du code attendu
- Impact sur l'existant : aucun changement de schéma IndexedDB (`dbSaveMatch()` fait déjà un `put()` upsert par `id`, `keyPath:"id"`) ; aucun changement au comportement Supabase (`S.currentMatchId`, `upsertMatchSnapshot()`, `markMatchFinished()` non touchés)

## Critères d'acceptation
- [ ] Cliquer "💾 Sauvegarder" deux fois de suite sur la même session de match (sans "Nouveau match" entre les deux) ne crée qu'**une seule** entrée dans l'historique (`dbGetAll()` / écran Matchs)
- [ ] La deuxième sauvegarde reflète l'état le plus récent (score, événements, notes) sous le même `id`
- [ ] `newMatch()` réinitialise `S.savedMatchId=null` — le match suivant sauvegardé crée bien une nouvelle entrée, pas une mise à jour de l'ancienne
- [ ] Annuler la confirmation "Nouveau match ?" (`safeConfirm` refusé) laisse `S.savedMatchId` **inchangé** (le match en cours reste rattaché à sa sauvegarde existante)
- [ ] `loadMatchAsCurrent(id)` fixe `S.savedMatchId = id` (l'identifiant du match archivé chargé) — modifier ce match repris puis le sauvegarder met à jour cette même entrée archivée, n'en crée pas une troisième
- [ ] Le comportement Supabase (`S.currentMatchId`, synchronisation multi-appareil) n'est pas modifié — vérifié en confirmant qu'un match repris sur un second appareil (STORY-14) continue de fonctionner normalement
- [ ] `new Function()` passe sur `app.js` modifié (vérification systématique avant livraison, cf. `CLAUDE.md`)

## Hors scope
- Synchroniser `S.savedMatchId` entre appareils (reste un état local par appareil, cf. `docs/risks/audit-corrections-et-mode-simple.md` R1 — limite documentée, pas corrigée dans cette story)
- Toute modification du flux Supabase (`matches`/`match_events`)

## Dépend de
Aucune

## Taille
S
