# STORY-66 — Un match rechargé puis modifié se synchronise fiablement

**En tant que** Romain,
**Je veux** que corriger un match archivé après coup (le recharger puis ajouter un événement oublié) se synchronise vers Supabase comme n'importe quelle autre saisie,
**Afin de** ne jamais perdre silencieusement une correction faite après coup sur un match déjà terminé.

Trouvé par le QA pendant `/verifie` STORY-62-65 (`docs/qa/QA-62-65-corrections-audit-et-mode-simple.md`), hors scope de ces 4 stories, root cause déjà identifiée.

## Contexte technique
- Zone concernée : `queueEventForSync()` (`app.js:459`)
- Impact sur l'existant : aucun — la correction n'ajoute qu'un appel (`await upsertMatchSnapshot();`) dans une branche qui ne s'exécute jamais pendant le flux normal (`▶ Lancer le match` a déjà `S.currentMatchId` défini et `upsertMatchSnapshot()` déjà appelée à ce stade) ni pendant `resumeMatch()` (`S.currentMatchId` toujours déjà défini sur un id existant). Seul chemin affecté : `loadMatchAsCurrent()` (📂 Charger, et le raccourci PDF de Bilan STORY-36) suivi d'un nouvel événement sans relance.
- Détail exact du correctif et des alternatives écartées : `docs/arch/fix-sync-match-recharge.md`

## Critères d'acceptation
- [ ] Recharger un match archivé (`📂 Charger`), ajouter un nouvel événement → une ligne `matches` existe côté Supabase pour le `currentMatchId` régénéré (vérifiable par une requête directe `select` sur `matches`)
- [ ] Plus aucune erreur 409 répétée sur `match_events` dans ce scénario (vérifiable sur plusieurs événements consécutifs, pas seulement le premier)
- [ ] Le flux normal (`▶ Lancer le match` → saisie Mode Expert/Simple) reste identique : pas d'appel `upsertMatchSnapshot()` superflu pendant la saisie (la branche corrigée ne doit jamais s'exécuter dans ce flux)
- [ ] `resumeMatch()` (reprise d'un match `in_progress` depuis un autre appareil, STORY-14) non affecté — non re-testé en profondeur si le Code Reviewer confirme par lecture que `S.currentMatchId` y est toujours déjà défini avant tout événement
- [ ] `new Function()` passe sur `app.js` modifié

## Hors scope
- Nettoyage de données Supabase déjà existantes (aucune ligne orpheline connue à ce jour en production).
- Tout changement de schéma `matches`/`match_events`.

## Dépend de
Aucune

## Taille
XS
