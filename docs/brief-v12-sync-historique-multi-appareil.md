# Brief — Synchronisation de l'historique des matchs entre appareils

## Origine
Romain : "je ne vois pas sur mon iPhone les matchs sauvegardés sur mon PC."

## Diagnostic (confirmé par lecture de code, pas une supposition)
La synchronisation multi-appareil construite en STORY-10 à 14 couvre uniquement les matchs **en cours** (`status='in_progress'`) : `fetchInProgressMatches()`/`resumeMatch()` permettent à un appareil de reprendre un match démarré ailleurs, tant qu'il n'est pas terminé. Une fois un match sauvegardé (`saveMatch()` → `markMatchFinished()` → `status='finished'` côté Supabase), il reste bien présent sur Supabase, mais **aucun code ne va jamais le rechercher** pour l'ajouter à l'historique local d'un autre appareil — `renderHistory()` et `renderBilan()` lisent exclusivement `dbGetAll()` (IndexedDB, strictement local à l'appareil).

Autrement dit : chaque appareil a son propre historique local, indépendant, même si les matchs ont transité par Supabase pendant qu'ils étaient en cours. Ce n'est pas une perte de données (le match est bien sur Supabase), c'est une absence de chemin de lecture retour.

## Complication technique trouvée en creusant (à trancher avant le PRD)
Le schéma Supabase actuel de la table `matches` (colonnes écrites par `upsertMatchSnapshot()`) ne contient **pas** `season`, `journee`, ni `coachNotes` — ces champs n'existent que dans l'objet match local (`saveMatch()`). `scoreH`/`scoreA` n'y sont pas non plus stockés directement (recalculables depuis les événements). Un match récupéré depuis Supabase sur un autre appareil arrivera donc **sans saison/journée/notes coach** tant que le schéma n'est pas étendu.

## Besoin réel
Que l'historique des matchs (écran "Matchs" + Bilan) soit visible depuis n'importe quel appareil connecté au même compte partagé, pas seulement celui qui a sauvegardé le match — cohérent avec la promesse déjà faite ailleurs dans l'app ("un appareil peut reprendre un match en cours démarré par un autre appareil").

## Décision actée avec Romain
Déclenchement du rapatriement : **automatique à l'ouverture de l'écran Matchs**, pas un bouton manuel — dès qu'on ouvre l'onglet, l'appli va chercher en arrière-plan les matchs archivés sur Supabase absents localement et les ajoute à la liste.

## Ce qui ne change pas
Le fonctionnement actuel de la sync pendant qu'un match est en cours (STORY-10 à 14), la sauvegarde locale elle-même (`saveMatch()`), l'export/import CSV, la suppression d'un match (STORY-27).
