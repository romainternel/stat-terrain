# Brief — Correctif synchronisation : match archivé rechargé puis modifié

## Contexte
Trouvé par le QA pendant le cycle `/verifie` de STORY-62-65 (`docs/qa/QA-62-65-corrections-audit-et-mode-simple.md`), en dehors du périmètre de ces 4 stories — sujet distinct, cadré par le QA lui-même avec la root cause déjà identifiée par lecture de code. Demande explicite de Romain de le corriger maintenant.

## Problème
Un coach recharge un match déjà archivé (bouton "📂 Charger", écran Matchs — par exemple pour corriger un événement oublié après coup) puis continue à saisir de nouveaux événements **sans relancer le match**. Chaque nouvel événement échoue silencieusement à se synchroniser vers Supabase : `queueEventForSync()` régénère un `S.currentMatchId` (puisque `loadMatchAsCurrent()` l'avait remis à `null`, comportement voulu par STORY-36 pour éviter d'écrire sur le mauvais match Supabase) mais **n'appelle jamais `upsertMatchSnapshot()`** pour créer la ligne `matches` correspondante — contrairement au bouton "▶ Lancer le match" qui le fait toujours. L'événement peut alors se retrouver écrit côté `match_events` sans ligne `matches` parente, et les tentatives de synchronisation suivantes échouent en boucle (erreur 409, retentée toutes les 15s par `flushOutbox()`).

Aujourd'hui, sans ce correctif : la saisie locale reste correcte (principe fail-open respecté, rien de visible ne casse pour le coach), mais les corrections apportées à un match rechargé ne se propagent jamais de façon fiable aux autres appareils — un autre appareil qui rouvrirait ce même match ne verrait pas les événements ajoutés après coup.

## Utilisateurs
Romain (ou un aidant occasionnel) sur iPad/iPhone, en train de corriger un match archivé après coup — un scénario plus rare que la saisie en direct pendant un match, mais réel (ex. un événement oublié pendant le match, repéré en revoyant le Bilan).

## Vision
Qu'ajouter un événement à un match rechargé se synchronise aussi fiablement que la saisie d'un match qu'on vient de lancer — sans geste supplémentaire pour le coach, sans qu'il ait besoin de savoir que ce chemin existe.

## Scope

**Dans le scope :**
- `queueEventForSync()` crée la ligne `matches` correspondante (via `upsertMatchSnapshot()`) avant de synchroniser le premier événement d'une session dont `S.currentMatchId` était `null` — symétrique à ce que fait déjà le bouton "▶ Lancer le match".

**Hors scope :**
- Tout le reste de la synchronisation (outbox, realtime, reprise multi-appareil STORY-13/14) — déjà correct, non touché.
- Nettoyage rétroactif d'éventuelles lignes `match_events` déjà orphelines côté production (aucune connue à ce jour — celle créée pendant le test QA a déjà été supprimée manuellement).
- Toute refonte du modèle de données ou de la stratégie offline-first.

## Critères de succès
- Recharger un match archivé puis ajouter un événement crée bien la ligne `matches` correspondante côté Supabase avant que l'événement ne s'y synchronise — plus aucune erreur 409 en boucle sur ce chemin.
- Aucune régression sur le flux normal (`▶ Lancer le match` déjà correct, ne doit pas appeler `upsertMatchSnapshot()` deux fois inutilement).

## Questions en suspens
Aucune — root cause et correctif déjà clairs, pas d'ambiguïté à lever avant de coder.
