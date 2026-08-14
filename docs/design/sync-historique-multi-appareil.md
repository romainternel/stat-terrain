# Design — Synchronisation de l'historique des matchs entre appareils

## Principe général : la liste locale s'affiche toujours en premier, immédiatement
Cohérent avec le principe non négociable déjà en place ("la saisie locale ne doit jamais dépendre de la disponibilité de Supabase") : ouvrir l'écran Matchs affiche `dbGetAll()` (local) **sans attendre** la réponse Supabase. Le rapatriement se fait ensuite, en arrière-plan, et les matchs récupérés s'ajoutent à la liste déjà affichée dès qu'ils arrivent — jamais d'écran de chargement bloquant, jamais de dépendance dure à la disponibilité réseau.

## Indicateur discret pendant la recherche
Une ligne fine sous le titre de l'écran Matchs, dans le même esprit que l'indicateur de statut de sync déjà présent en Match (STORY-15) — texte discret, pas une bannière imposante :
- Pendant la requête : `🔄 Recherche de matchs sur les autres appareils…` (`color:var(--t3)`, `font-size:11px`)
- Rien trouvé de nouveau, ou Supabase indisponible (fail-open) : l'indicateur disparaît simplement, silence total — pas de message "aucun match trouvé" qui ajouterait du bruit pour le cas normal (la majorité des ouvertures, une fois l'historique déjà synchronisé)
- Si nouveaux matchs récupérés : remplace l'indicateur par un `showToast("+N match(s) récupéré(s) depuis un autre appareil")` (réutilise `showToast()` déjà existant, pas un nouveau composant) — évite que le coach se demande d'où viennent des matchs qu'il n'a pas l'impression d'avoir sauvegardés lui-même sur cet appareil

## Emplacement des matchs récupérés dans la liste
Aucun traitement visuel distinct (pas de badge "☁️ synchronisé" permanent) — une fois dans `dbGetAll()`, un match récupéré est indiscernable d'un match créé localement, cohérent avec le principe "un seul historique unifié" plutôt que deux catégories parallèles à maintenir visuellement. Le tri déjà en place (`dbGetAll()` trie par `id` décroissant) s'applique normalement.

## Matchs sans saison/journée (matchs déjà existants avant cette story, jamais mis à jour côté Supabase)
Pour les matchs sauvegardés **avant** l'extension du schéma (Won't du PRD — pas de migration rétroactive), un rapatriement plus tard sur un autre appareil afficherait saison/journée vides. Traitement minimal : `season`/`journee` vides affichés comme "–" dans la liste (comportement déjà existant du champ optionnel, pas un nouvel état à construire).

## Écran Bilan
`renderBilan()` utilise le même `S.matchHistory` que Matchs (`dbGetAll()`) — bénéficie automatiquement du rapatriement sans changement supplémentaire, cohérent avec le PRD (même source de données, un seul point de rapatriement à construire).
