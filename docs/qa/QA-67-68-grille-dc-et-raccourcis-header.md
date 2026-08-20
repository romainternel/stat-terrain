# QA — STORY-67 (grille DC) + STORY-68 (raccourcis en-tête)

## Ce que j'ai lu avant de tester
`docs/code-review/STORY-67-68.md` (APPROUVÉ), les 2 stories, `docs/arch/dc-grid-et-raccourcis-header.md`, `docs/risks/dc-grid-et-raccourcis-header.md` (points R2/R3 identifiés comme prioritaires).

## Méthode
CDP contre le vrai backend Supabase de production. Un seul scénario continu combinant les deux stories (les deux sont visibles simultanément à l'écran Match), plus des vérifications ciblées sur les points de risque identifiés par le Risk Analyst.

## Critères d'acceptation vérifiés

**STORY-67 (grille DC)**
- [x] Les 5 joueurs DC réels (Jules.G, Issa.S, Leni.A, Lucas.G, Antonin.V) sélectionnés ensemble → 5 étiquettes distinctes, 3 en rangée haute / 2 en rangée basse, aucun chevauchement — capture `screenshots/qa67-01-dc-5-tablette.png` (tablette 1024×768) et `screenshots/qa68-02-header-iphone.png` (iPhone 390×844, même sélection, toujours lisible)
- [x] Vérifié sur **2 écrans différents** : Match Mode Expert (`screenshots/qa67-04-pvt-3-home.png`) et sélecteur "Passe décisive" (`screenshots/qa67-02-pd-selector-dc.png`) — même disposition sur les deux, confirme que le correctif centralisé dans `courtPlayerPositions()` se propage bien partout
- [x] **Régression PVT (R2)** : 3 joueurs Pivot sélectionnés (Idris.F, Lukas.J-A, Yoran.C) → triangle inchangé (1 devant, 2 derrière), visible sur la même capture que la grille DC (`qa67-04-pvt-3-home.png`) — aucune régression sur le code partagé. PVT à 4 joueurs non testable en direct (le roster réel FENIX CF ne compte que 3 Pivots) — le bloc `4:` de `layouts` est byte-for-byte identique à avant ce changement (vérifié dans le diff du Code Review), risque de régression nul par construction
- [x] DC reste visuellement derrière ARG/ARD, aucune confusion de poste

**STORY-68 (raccourcis en-tête)**
- [x] Raccourcis Mode et Suivi GB visibles dans l'en-tête sur Équipes, Match (avec et sans match actif) — vérifié explicitement les deux états requis par le risque R3
- [x] Tap sur le raccourci Mode : Simple→Expert sans confirmation (testé), Expert→Simple **avec** un événement déjà saisi → confirmation bloquante affichée avec le texte exact attendu ; testé aussi le chemin Annuler → `S.mode` reste inchangé
- [x] Tap sur le raccourci Suivi GB : bascule immédiate, **synchronisation bidirectionnelle vérifiée dans les deux sens** — changement depuis l'en-tête reflété sur le toggle du panneau Match (🧤 Suivi GB), et changement depuis le toggle Équipes reflété dans l'en-tête (même variable `S.trackGK`, pas une copie)
- [x] **Vérification visuelle de l'en-tête (R3)** : espacement cohérent en desktop/tablette (1024px, avec `#settings-btn` visible) et en iPhone étroit (390px, sans/avec `#settings-btn`) — aucune collision, aucun élément collé ou désaligné
- [x] iPhone étroit : le texte "ON"/"OFF" disparaît (icône seule), les 5 onglets de navigation restent tous présents dans le DOM (vérifié par requête directe, pas seulement visuel) — le mécanisme de défilement horizontal STORY-18 n'est pas cassé

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune.

## Nettoyage
Match de test lancé pendant les vérifications (jamais sauvegardé localement, donc jamais apparu dans l'historique) supprimé directement de Supabase (`matches` + `match_events`) via son `currentMatchId` — vérifié absent après coup, aucun match "in_progress" résiduel. Les 2 matchs réels de Romain ("Rodez") jamais touchés.

## Verdict
**PASSED**
