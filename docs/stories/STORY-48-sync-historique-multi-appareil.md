# STORY-48 — Synchronisation de l'historique des matchs entre appareils

**En tant que** Romain,
**Je veux** retrouver sur mon iPhone les matchs que j'ai sauvegardés sur mon PC (et inversement),
**Afin de** consulter l'historique complet de l'équipe depuis n'importe quel appareil, pas seulement celui qui a servi à sauvegarder chaque match.

Retour direct de Romain ("je ne vois pas sur mon iPhone les matchs sauvegardés sur mon PC") — diagnostiqué comme une absence de chemin de lecture retour depuis Supabase vers l'historique local des autres appareils (`renderHistory()`/`renderBilan()` ne lisent que `dbGetAll()`, jamais Supabase). Décision actée avec Romain (AskUserQuestion) : rapatriement **automatique** à l'ouverture de l'écran Matchs, pas de bouton manuel.

## ⚠️ Prérequis de déploiement — action manuelle de Romain
**Avant** que cette story soit fonctionnelle, exécuter `docs/supabase-migration-season-journee-notes.sql` dans le SQL Editor du projet Supabase (ajoute 3 colonnes nullable à `matches` : `season`, `journee`, `coach_notes`). Sans cette étape, le rapatriement fonctionne quand même (fail-open, cf. Risque R1) mais les matchs récupérés arrivent sans saison/journée tant que la migration n'est pas faite.

## Contexte technique
- Référence design (indicateur, toast, absence de badge distinctif) : `docs/design/sync-historique-multi-appareil.md`
- Référence architecture (fonctions exactes, point d'appel, découplage des deux `update()`) : `docs/arch/sync-historique-multi-appareil.md`
- Risques à vérifier explicitement pendant le développement : `docs/risks/sync-historique-multi-appareil.md` (R1 déjà mitigé par construction — à confirmer en Code Review que les 2 `update()` sont bien séparés)

## Critères d'acceptation
- [ ] Migration SQL livrée (`docs/supabase-migration-season-journee-notes.sql`), colonnes nullable, `if not exists`
- [ ] `markMatchFinishedById()` : 2 appels `update()` **séparés** (statut d'abord, season/journee/coach_notes ensuite) — un échec du 2e n'affecte jamais le 1er
- [ ] Nouvelles fonctions `fetchMissingArchivedMatches()`/`importArchivedMatch()`/`syncArchivedMatchesIntoLocal()` conformes à l'Architecture — déduplication stricte par `supabaseMatchId`, jamais de doublon dans `dbGetAll()`
- [ ] Déclenchement automatique à l'ouverture de l'écran Matchs (`S.view==="history"`), une seule fois par chargement de page (`S._historySyncedThisLoad`) — pas à chaque re-render
- [ ] Liste locale affichée immédiatement, sans attendre la réponse Supabase (jamais de blocage/écran de chargement)
- [ ] Indicateur discret pendant la recherche (`🔄 Recherche de matchs sur les autres appareils…`), disparaît silencieusement si rien de nouveau ou si Supabase indisponible (fail-open, cohérent avec le principe déjà en place ailleurs dans l'app)
- [ ] Toast `showToast()` si N matchs rapatriés (`+N match(s) récupéré(s) depuis un autre appareil`), pas de notification si 0
- [ ] Aucun badge/traitement visuel distinctif pour un match rapatrié vs un match local — un seul historique unifié
- [ ] `renderBilan()` bénéficie du rapatriement sans changement de code supplémentaire (même `S.matchHistory`)
- [ ] Aucune régression sur : `resumeMatch()`/`fetchInProgressMatches()` (in_progress, non touché), `saveMatch()`, suppression de match (STORY-27), export/import CSV, sauvegarde locale hors-ligne

## Cas limites à tester
- **Migration non exécutée** (simuler colonnes absentes) : le statut `finished` continue de se mettre à jour normalement, seul l'enrichissement season/journee/coach_notes échoue silencieusement
- **Aucun match à rapatrier** (historique déjà synchronisé) : pas d'indicateur qui reste bloqué affiché, pas de toast, requête rapide (liste déjà à jour)
- **Beaucoup de matchs à rapatrier** (premier appareil, jamais synchronisé) : tous récupérés sans doublon, un seul toast récapitulatif à la fin (pas un toast par match)
- **Supabase indisponible/non configuré** : écran Matchs fonctionne exactement comme avant cette story (liste locale uniquement, aucune erreur visible)
- **Deux appareils ouvrent Matchs en même temps** : pas de mécanisme de verrou nécessaire, `dbSaveMatch()` est un `put()` idempotent par id local généré indépendamment sur chaque appareil — pas de conflit d'écriture possible entre appareils différents (chacun sa propre IndexedDB)

## Hors scope
Bouton de synchronisation manuel, synchronisation en continu/temps réel de l'historique, résolution de conflit sur un match modifié différemment sur deux appareils, migration rétroactive des matchs sauvegardés avant cette story.

## Dépend de
Migration SQL fournie avec la story (prérequis d'exécution manuelle, pas une dépendance de développement).

## Taille
M — nouvelles fonctions contenues, mais touche un flux critique déjà en production (`markMatchFinishedById()`) : vigilance particulière en Code Review sur le découplage des deux `update()`.
