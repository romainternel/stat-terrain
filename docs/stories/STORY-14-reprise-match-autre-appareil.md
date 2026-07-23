# STORY-14 — Reprendre un match en cours sur un autre appareil

**En tant que** Romain (ou la personne qui m'aide),
**Je veux** pouvoir ouvrir un match déjà commencé depuis un nouvel appareil,
**Afin de** passer la main pendant le match sans avoir à ressaisir quoi que ce soit.

## Contexte technique

- Zone concernée : nouvel écran "Matchs" (maquette `docs/design/acces-partage-et-reprise-match.md`), nouvelles fonctions `fetchInProgressMatches()`, `resumeMatch(matchId)`.
- Au chargement (après connexion), requêter `matches` où `status='in_progress'`.
- `resumeMatch()` charge le snapshot `matches` (score, GK, timer, roster) + tous les `match_events` liés, reconstitue `S`, puis appelle `subscribeMatchEvents()` (STORY-13) pour continuer à recevoir les événements suivants.

## Critères d'acceptation

- [ ] Si un match est en cours (statut `in_progress`), l'écran "Matchs" le propose clairement avec un bouton "Reprendre".
- [ ] Reprendre un match restaure exactement l'état où il en était (score, timer, GK sélectionné, tous les événements déjà saisis).
- [ ] Si aucun match n'est en cours, le comportement actuel (bouton "Nouveau match") reste identique — aucune friction ajoutée pour l'usage solo habituel.
- [ ] Après reprise, les nouveaux événements saisis sur ce nouvel appareil sont bien synchronisés (STORY-12/13) avec l'appareil d'origine s'il rouvre l'app.

## Hors scope

- Migration des matchs déjà en local avant ce cycle (décision de Romain : seuls les nouveaux matchs utilisent Supabase).

## Dépend de

STORY-10, STORY-13.

## Taille

M
