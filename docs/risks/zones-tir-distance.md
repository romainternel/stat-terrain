# Risques — Zones de tir : vraie distinction 6m / 6-9m / 9m

*Produit par le Risk Analyst — squad build BMAD*
*S'appuie sur `docs/architecture/zones-tir-distance.md`*

## Tableau des risques

| # | Risque | Probabilité | Impact | Recommandation |
|---|---|---|---|---|
| 1 | **Polygones de zone géométriquement incorrects** (trou entre deux zones, chevauchement, sommet mal calculé à la jonction aile/6m) — l'Architect lui-même signale que la dérivation exacte des sommets `6M*`/`69M*` n'est pas triviale et ne peut pas être garantie sans rendu réel. Une erreur ici est invisible en lisant le code mais immédiatement visible (et embarrassante en plein match) à l'écran. | Élevée | Moyen-Élevé (visuel cassé sur l'écran le plus regardé en direct) | Suivre la méthode déjà recommandée en Architecture : construire d'abord l'arc R6 seul en overlay de debug, le valider visuellement contre la ligne des 6m déjà tracée par `courtSvgMarkup()`, **avant** de construire les polygones remplis. Ne pas écrire les 3 nouveaux polygones d'un coup sans étape de vérification intermédiaire. |
| 2 | **Régression de satisfaction sur un écran déjà validé** — le système à 8 zones a demandé 8 itérations avant validation par Romain. Passer à 11 zones plus fines pourrait ne pas convenir du premier coup (positions de label, tailles de zone jugées trop petites pour taper dessus sur iPad), rouvrant potentiellement un cycle d'itération similaire. | Moyenne | Moyen | Déjà couvert par le PRD (F5, critère d'acceptation non négociable) : revalidation visuelle explicite par Romain avant de considérer la story terminée — ne pas la traiter comme un simple ajustement technique. |
| 3 | **Contrainte d'espace PDF (11 cellules dans 34×14mm)** — texte à 4-4.5pt, déjà à la limite basse de lisibilité du projet (5pt est la plus petite taille actuellement en production, `drawPlayerOriginZone`). Un export réel pourrait s'avérer illisible malgré un rendu correct à l'écran de développement. | Moyenne | Moyen | Le repli déjà proposé par le Design (fusionner `69M*`/`9M*` uniquement dans l'affichage PDF, en gardant la vraie classification à 11 buckets en sous-jacent) doit être testé sur un **export PDF réel imprimé ou zoomé à 100%**, pas seulement visualisé à l'écran en zoom navigateur — un PDF qui semble lisible zoomé peut ne plus l'être imprimé en A4. |
| 4 | **Fusion `drawOriginZone`/`drawPlayerOriginZone` en une fonction partagée** — une erreur dans cette factorisation (les deux fonctions étaient dupliquées à ~90%, jamais fusionnées jusqu'ici) pourrait casser silencieusement la génération du PDF entier : jsPDF échoue parfois de façon peu explicite sur une page, pas seulement sur la grille de zones. | Faible à Moyenne | Élevé (rapport PDF entier inutilisable, pas seulement une page) | Critère d'acceptation explicite : générer un vrai PDF après la modification et l'ouvrir en entier (pas seulement vérifier que `new Function()` passe, qui ne détecte pas les erreurs runtime spécifiques à jsPDF) — cf. story. |
| 5 | **Les statistiques par zone d'un match déjà archivé changent de valeur silencieusement** après cette mise à jour — la classification est recalculée à la volée depuis `x`/`y` à chaque affichage, jamais persistée. Un match consulté avant et après la mise à jour montrera des répartitions de zone différentes (correctement, mais sans qu'aucun changement ne soit signalé à l'utilisateur). | — (constat, pas un risque à mitiger) | Faible | Pas une régression — comportement attendu et cohérent avec l'architecture existante (aucune donnée de zone n'a jamais été stockée). À mentionner à Romain une fois livré, pour qu'il ne soit pas surpris de voir d'anciens matchs "changer" de répartition par zone. |

## Classement
- **P0 (à traiter avant tout dev)** : aucun — pas de risque bloquant le démarrage, mais #1 conditionne fortement la méthode de développement (à respecter dès la première ligne de `buildCourtZones()`, pas après coup).
- **P1 (critère d'acceptation obligatoire)** : #1 (méthode de vérification incrémentale), #2 (revalidation Romain, déjà en PRD), #4 (export PDF réel testé, pas seulement `new Function()`).
- **P2 (à garder à l'œil, non bloquant)** : #3 (lisibilité PDF à taille réelle).
- **P3 (constat, sans action corrective)** : #5 (changement rétroactif silencieux des stats de zone).

## Stories de mitigation recommandées
- **#1 → critère d'acceptation dans la story F1**, pas une story séparée : méthode de développement incrémentale (arc de debug avant polygone rempli) imposée, pas seulement recommandée.
- **#2 → déjà couvert par le critère d'acceptation F5 du PRD**, rien à ajouter.
- **#3 → critère d'acceptation dans la story F4** : test d'export PDF réel à taille d'impression, pas seulement un rendu écran.
- **#4 → critère d'acceptation transverse** sur toute story touchant le PDF : ouverture réelle du fichier généré après modification, pas seulement passage de `new Function()`.
- **#5 → aucune story**, communication seule à prévoir en fin de cycle.
