# Brief — Mode Simple / Mode Expert

## Contexte
FENIX Stats a été conçu et affiné tout un cycle pour un usage **expert unique** : Romain, en bord de terrain, sur iPad, qui saisit chaque action avec position sur le terrain et zone de but. Deux besoins nouveaux émergent, distincts mais complémentaires :
1. Le chantier Supabase (cadré, pas développé) prévoit qu'un aidant occasionnel puisse co-saisir des stats sur un autre appareil — mais l'interface actuelle suppose une expertise que cet aidant n'a pas (cf. `docs/research/mode-simple-expert.md`, qui relie ce besoin à STORY-16 déjà identifiée dans ce chantier).
2. Indépendamment de tout aidant, l'iPhone lui-même (petit écran) rend l'usage complet plus difficile — Romain souhaite qu'il propose un mode simplifié par défaut.

## Problème
Aujourd'hui, l'app n'a qu'un seul niveau de complexité : la saisie complète (terrain, zone de but, PD, PO/PEN, gestion GB). C'est adapté à Romain sur iPad, mais :
- Un utilisateur occasionnel ne peut pas saisir sans formation.
- Sur un écran iPhone, ce niveau de détail est plus difficile à manipuler rapidement pendant un match réel.

## Utilisateurs
- **Romain** — expert, utilisateur quotidien, principalement iPad, parfois iPhone en dépannage (doit pouvoir garder l'accès au mode complet même sur iPhone).
- **Aidant occasionnel** (cible future du chantier Supabase, pas encore développé) — non technique, besoin de saisir vite sans se tromper.
- Éventuellement un bénévole/parent qui veut juste suivre le score sans détail.

## Vision
Permettre à FENIX Stats de servir aussi bien l'analyse fine de Romain que la saisie occasionnelle d'un non-expert, en adaptant la complexité de saisie au profil et à l'appareil, sans jamais dégrader le mode complet existant.

## Scope

**Dedans :**
- Un mode "Simple" qui retire la saisie fine (pas de terrain, pas de zone de but, pas de PD, pas de PO/PEN détaillé) et ne garde que l'essentiel au niveau équipe (score, buts, tirs arrêtés/non cadrés, éventuellement exclusions/cartons).
- Un mode "Expert" strictement identique au comportement actuel de l'app — aucune régression.
- Un moyen de choisir/changer de mode, mémorisé par appareil.
- Sur iPhone, mode Simple par défaut à la première utilisation — mais toujours modifiable manuellement (Romain doit pouvoir repasser en Expert sur son iPhone).

**Dehors (cette version) :**
- Le chantier Supabase lui-même (reste non développé — ce cycle prépare seulement le terrain UX).
- Toute nouvelle donnée qui n'existe pas déjà dans le modèle d'événement actuel.
- Le rattrapage a posteriori des détails manquants sur un événement saisi en mode Simple (backlog, pas cette version).

## Critères de succès
- Romain peut basculer entre les deux modes sans perte de données ni confusion.
- Un utilisateur non-formé peut suivre un match en mode Simple sans se tromper ni chercher des boutons absents.
- Le mode Expert reste identique en tous points à aujourd'hui (zéro régression).
- Sur iPhone, le mode par défaut est Simple, mais Romain peut repasser en Expert en une action claire.

## Questions en suspens
- **Séquencement** (remontée explicitement par Romain) : finir le polish visuel du mode Expert en cours, puis dissocier — ou dissocier dès maintenant ? À trancher par le PM dans le PRD.
- Le mode Simple doit-il produire des Stats/Bilan exploitables, ou juste un score/résumé minimal ?
- Le choix de mode est-il figé par appareil (localStorage) ou peut-il changer en cours de match ?
- Un match commencé en Simple peut-il être complété a posteriori en Expert ?
