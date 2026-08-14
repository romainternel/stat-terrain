# Risques — Champ Championnat / Amical

## R1 — Persistance de `S.championnat` entre matchs (P1, déjà corrigé — Must du PRD revu)
**Trouvé en analysant l'Architecture initiale** (qui calquait `S.championnat` sur `S.season`, jamais réinitialisé) : si un coach joue un match Amical puis enchaîne avec un vrai match de championnat sans repenser à rebasculer le sélecteur, le match de championnat hériterait silencieusement de "Amical" et serait **exclu à tort du bilan de saison** — une corruption silencieuse des statistiques, sans aucun signal d'erreur, découverte seulement si Romain remarque un total de victoires/matchs incohérent. **Corrigé** : `S.championnat` réinitialisé à `"N1"` par `newMatch()`, comme `S.journee` (auto-incrémentée) plutôt que comme `S.season` (persistante). Coût accepté : un clic supplémentaire pour re-sélectionner N2/-18/Amical à chaque match qui n'est pas en N1, jugé largement préférable à un risque silencieux sur l'intégrité des stats.

## R2 — Valeur "Autre…" mal réaffichée après un rechargement de page (P3, déjà mitigé au Design d'architecture)
Si `S.championnat` contient une valeur libre (ex: "Coupe de France") et que le `<select>` ne prévoit que les 4 options fixes + "Autre…", rouvrir l'écran Match afficherait "N1" par défaut (le navigateur sélectionne la première option faute de correspondance) alors que la vraie valeur est différente — **le champ en mémoire (`S.championnat`) resterait correct**, seul l'affichage du menu mentirait. Mitigé par l'Architecture (option dynamique ajoutée au `<select>` si la valeur courante ne correspond à aucune des 4 options fixes) — à vérifier explicitement en Code Review que cette branche est bien présente, pas juste esquissée.

## R3 — Matchs déjà sauvegardés sans `championnat` (P3, déjà couvert par M6 du PRD)
Un match créé avant cette story n'a pas de `championnat` — traité comme inclus dans le bilan de saison par défaut (seule la valeur exacte `"Amical"` exclut), pas de risque de perte rétroactive de données déjà sauvegardées. Comportement neutre, pas un risque actif à mitiger davantage.

## R4 — Couplage avec STORY-48 (écriture Supabase) (P2)
`championnat` s'ajoute au même appel `update()` "confort" que `season`/`journee`/`coach_notes` (déjà découplé du `update({status:'finished'})` critique par STORY-48, cf. R1 de `docs/risks/sync-historique-multi-appareil.md`). Si STORY-49 est développée **après** que STORY-48 a déjà été codée et testée, le Developer doit impérativement modifier ce même appel existant plutôt que d'en ajouter un 3e séparé — un 3e appel réseau par sauvegarde de match serait un gaspillage inutile (déjà 2 aujourd'hui) sans bénéfice, la découplage du statut critique étant déjà acquis dès le 1er appel. Signalé explicitement dans l'Architecture pour ne pas être manqué en Code Review.

## Sécurité — Security Auditor non convoqué
Aucune nouvelle table, aucune nouvelle policy — utilise la colonne `championnat` déjà ajoutée à `matches` par la migration commune avec STORY-48, même modèle d'accès déjà audité. Pas de nouvelle surface d'exposition.

## Recommandation de découpage
Une seule story (STORY-49) — dépend de la migration SQL déjà livrée, dépend techniquement du point d'écriture Supabase déjà spécifié par STORY-48 (à réutiliser, pas à redéfinir), mais le reste (état, UI, filtre du bilan de saison) est autonome et ne nécessite pas de découpage supplémentaire.
