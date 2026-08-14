# PRD — Synchronisation de l'historique des matchs entre appareils

## Objectif
Un match sauvegardé sur un appareil devient visible sur les autres appareils connectés au même compte partagé, sans action manuelle.

## Must (cette version)
1. **M1** — À l'ouverture de l'écran Matchs (`S.view="history"`), l'appli récupère en arrière-plan les matchs `status='finished'` présents sur Supabase mais absents localement, et les ajoute à `dbGetAll()`/`S.matchHistory` — sans bloquer l'affichage de la liste locale existante (celle-ci s'affiche immédiatement, les matchs distants s'ajoutent dès qu'ils arrivent).
2. **M2** — **Extension du schéma Supabase** (`matches`) : ajout des colonnes `season`, `journee`, `coach_notes` (absentes aujourd'hui). Sans cette extension, un match récupéré sur un autre appareil arriverait sans saison/journée — et l'agrégation "Saison" (qui groupe par `S.season`) le classerait mal ou l'ignorerait silencieusement selon la saison actuellement sélectionnée. Coût faible (3 colonnes nullable, script SQL fourni), risque de confusion évité important pour un coach qui suit sa saison par journée.
3. **M3** — `scoreH`/`scoreA` reconstruits à partir des événements récupérés (`teamScore()`-équivalent), pas stockés tels quels — cohérent avec le fait qu'ils ne sont déjà pas dans le schéma actuel, pas une nouvelle colonne nécessaire.
4. **M4** — Déduplication stricte par `supabaseMatchId` : un match déjà présent localement (créé sur cet appareil, ou déjà rapatrié lors d'une session précédente) n'est jamais re-téléchargé ni dupliqué dans la liste.
5. **M5** — Aucune régression sur la sauvegarde locale, l'export/import CSV, la suppression (STORY-27), la reprise d'un match en cours (STORY-14).

## Won't (hors scope explicite)
- Pas de bouton "Synchroniser" manuel (tranché avec Romain : automatique uniquement).
- Pas de synchronisation descendante en temps réel de l'historique (contrairement aux événements d'un match en cours) — le rapatriement se fait au moment de l'ouverture de l'écran Matchs, pas en continu ni en arrière-plan permanent.
- Pas de fusion/résolution de conflit si le même match a été modifié différemment sur deux appareils après coup (cas non prévu par l'architecture actuelle de toute façon — un match fini n'est plus édité).
- Pas de migration rétroactive des matchs déjà sauvegardés localement **avant** cette story pour leur ajouter `season`/`journee` côté Supabase — seuls les nouveaux matchs sauvegardés après cette story bénéficient du schéma étendu (même limite déjà acceptée pour `supabaseMatchId` en STORY-27).

## Contrainte de déploiement
Le script SQL d'extension de schéma (`docs/supabase-migration-season-journee-notes.sql`) doit être exécuté manuellement par Romain sur son projet Supabase **avant** que cette story soit fonctionnelle — même modèle que `docs/supabase-setup.sql`/`docs/supabase-realtime-setup.sql` déjà utilisés pour STORY-10. À signaler explicitement dans le résumé de livraison, ce n'est pas automatique.

## Priorité
Une seule story pour le rapatriement (nécessite le nouveau schéma comme prérequis direct) — pas de découpage supplémentaire nécessaire, la migration SQL et le code applicatif sont livrés ensemble.
