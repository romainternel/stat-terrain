# Risques — Chrono : temps mort et changement de mi-temps

*Produit par le Risk Analyst — squad build BMAD*
*S'appuie sur `docs/architecture/chrono-mi-temps.md`*

## Tableau des risques

| # | Risque | Probabilité | Impact | Recommandation |
|---|---|---|---|---|
| 1 | **Les deux messages de confirmation sont mal distingués sous pression** — en plein match, un coup d'œil rapide sur un `window.confirm()` natif (pas de couleur, pas d'icône stylable) pourrait faire confondre "Oui, MT2" et "Oui, MT1" et valider un changement de mi-temps non voulu, qui remet le chrono à un temps différent de celui attendu. | Moyenne | Moyen-Élevé (perte du repère de temps de jeu) | Le texte des deux boutons doit nommer explicitement la destination (déjà spécifié par le Designer, jamais "OK"/"Confirmer" générique) — critère d'acceptation QA explicite : lire les deux dialogues sur un vrai iPad avant validation, pas seulement en simulateur. |
| 2 | **Aucun tag en mi-temps 1 au moment d'un retour MT2→MT1** (mi-temps changée dès le coup d'envoi, avant le moindre événement) — le chrono se repositionne sur 30:00 par défaut, une valeur qui peut sembler arbitraire à l'utilisateur si le message ne l'explique pas clairement. | Faible | Faible | Comportement déjà spécifié (fallback documenté en Architecture/Design) — s'assurer juste que le message affiché reste cohérent avec la valeur réellement appliquée (pas de texte générique qui contredirait le 30:00 affiché). |
| 3 | **Double appel `upsertMatchSnapshot()` sur la branche retour MT2→MT1** (`stopTimer()` puis un second appel explicite) — un appareil distant connecté en temps réel pourrait recevoir un état transitoire (période déjà à 1, mais encore l'ancien temps de MT2) avant de recevoir l'état final une fraction de seconde après. | Faible | Faible | Pattern déjà présent dans le code actuel (le handler d'origine faisait déjà ce même double appel) — accepté, pas de nouvelle story. À surveiller seulement si un futur retour terrain signale un flash visible sur un 2e appareil. |
| 4 | **`safeConfirm()` fail-open** — si `window.confirm()` lève une exception dans un contexte restreint, `safeConfirm()` retourne `true` automatiquement (comportement déjà en production pour la bascule Expert→Simple). Ici, un changement de mi-temps auto-validé sans intention réelle aurait un impact plus sensible qu'ailleurs : perte du repère chrono en plein match. | Faible | Moyen | Pas une régression nouvelle (le pattern fail-open est un choix déjà assumé dans tout le projet, cf. `CLAUDE.md` "Principe non négociable"), mais à vérifier explicitement par le QA sur le vrai iPad Safari de Romain (pas seulement en environnement de test) avant de considérer la story terminée. |
| 5 | **Corrige potentiellement la cause racine d'un bug déjà documenté** (`docs/brief-v16-retours-premier-match-reel.md`, point 4 : des buts de la "2e mi-temps" enregistrés avec `period:1` parce que le chrono n'était pas fiable au changement de mi-temps) — mais ne corrige **pas rétroactivement** les matchs déjà sauvegardés avec ce défaut. | — (constat, pas un risque à mitiger) | — | Ne pas laisser croire à Romain que ses matchs déjà archivés avec ce symptôme seront corrigés automatiquement — aucune migration de données prévue, hors scope explicite du PRD. À mentionner clairement en fin de cycle (Superviseur/Archiviste) si l'occasion se présente. |

## Classement
- **P1 (critère d'acceptation obligatoire, pas bloquant pour démarrer)** : #1 (lisibilité des deux messages sur vrai iPad), #4 (vérification du comportement `safeConfirm()` sur vrai iPad Safari, pas seulement en test).
- **P2 (à garder à l'œil, non bloquant)** : #2 (fallback 30:00), #3 (double upsert transitoire).
- **P3 (constat, sans action corrective dans ce cycle)** : #5 (non-rétroactivité sur les matchs déjà archivés).

## Stories de mitigation recommandées
- **#1 et #4 → critères d'acceptation ajoutés à la story de changement de mi-temps**, pas de story séparée — les deux sont des vérifications de comportement sur appareil réel, pas des changements de code supplémentaires.
- **#2, #3, #5 → aucune story dédiée** — comportements déjà spécifiés et acceptés en amont (Design/Architecture), ou constat hors scope à communiquer plutôt qu'à corriger.
