# Code Review — STORY-14 : Reprise de match sur un autre appareil

## Périmètre revu
- `app.js` : `upsertMatchSnapshot()` (remplace/enrichit `ensureMatchRegistered`), hooks dans `startTimer`/`stopTimer`/période/GK/sélection roster, création du match dès "Lancer le match" (`launch-match-btn`), `fetchInProgressMatches`/`checkForResumableMatch`/`resumeMatch`/`dismissResumePrompt`, `renderResumePrompt()`, branchement dans `R()`, `markMatchFinished()` (dans `saveMatch()` et `newMatch()`).
- `sw.js` : bump v68.

## Conformité architecture
- Conforme à `docs/architecture-supabase.md` (noms de fonctions, logique de reprise décrite).
- **Retrofit bien géré** : la découverte que STORY-12 n'avait écrit qu'un snapshot minimal (insuffisant pour cette story) est documentée clairement, et corrigée par une extension logique de la même fonction plutôt qu'un système parallèle — cohérent.
- **Déviation de la maquette assumée et justifiée** : l'écran de proposition de reprise s'affiche à la connexion plutôt que dans l'onglet "Matchs" comme suggéré par `docs/design/acces-partage-et-reprise-match.md`. Raisonnement solide (un aidant ne doit pas avoir à deviner où chercher) — c'est le genre de déviation UX qui aurait dû repasser par le Designer dans un cycle normal, mais étant donné le contexte (retour direct de l'utilisateur en cours de test), l'écart est mineur et l'intention du critère d'acceptation ("propose clairement avec un bouton Reprendre") est respectée.

## Conventions de code
- Cohérent avec le reste du fichier.
- Point mineur : `upsertMatchSnapshot()` est maintenant appelée à de nombreux endroits (7 sites d'appel) — chacun est un one-liner, pas de duplication de logique, juste une invocation répétée. Acceptable, cohérent avec le pattern déjà observé pour `queueEventForSync` en STORY-12.

## Réutilisation vs duplication
- `ensureMatchRegistered()` conservée comme alias fin vers `upsertMatchSnapshot()` plutôt que supprimée — évite de casser le point d'appel existant dans `flushOutbox` (STORY-12), bon réflexe de compatibilité minimal.

## Scope
- Diff large mais cohérent avec l'ampleur réelle de la story (une vraie reprise nécessite un snapshot riche, pas juste la story STORY-12 existante). Pas de dérive vers STORY-15+ (indicateur de statut, doc de clonage).

## Point à vérifier par le Security Auditor
- `resumeMatch()` charge et affiche l'intégralité d'un match Supabase (roster, événements) — confirmer que ça reste dans le périmètre déjà accepté (compte partagé unique, pas de filtrage par utilisateur, cohérent avec D2).
- La liste de matchs "en cours" proposée à la connexion (`fetchInProgressMatches`) expose-t-elle quoi que ce soit qui ne devrait pas l'être ? (noms d'équipes, horaire de début — pas de donnée sensible a priori, mais à confirmer explicitement).

## Verdict
**APPROUVÉ**, sous réserve du passage du Security Auditor (obligatoire, story touchant une ressource backend et une nouvelle surface de lecture multi-match).
