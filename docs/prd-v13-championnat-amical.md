# PRD — Champ Championnat / Amical

## Objectif
Distinguer le type de compétition par match (N1/N2/-18/Amical/libre) et exclure les matchs amicaux du bilan agrégé de saison.

## Must (cette version)
1. **M1** — Nouvel état `S.championnat`, valeur par défaut `"N1"` (cohérent avec le contexte du club, Nationale 1 étant la compétition principale du CF FENIX Toulouse). **Réinitialisé à `"N1"` par `newMatch()`** (contrairement à `S.season` qui persiste) — décision revue après coup par le Risk Analyst : persister "Amical" comme `S.season` ferait qu'un match de championnat réel juste après un amical hérite silencieusement de "Amical" si Romain oublie de le rebasculer, l'excluant à tort du bilan de saison (M4). Redemander "N1" par défaut à chaque nouveau match coûte un clic occasionnel pour les cas N2/-18/Amical, contre un risque de corruption silencieuse des stats de saison sinon — asymétrie tranchée en faveur de la sécurité des données.
2. **M2** — Sélecteur avec les 4 valeurs rapides (N1, N2, -18, Amical) + une option "Autre…" qui ouvre une saisie libre — au même emplacement visuel que Saison/Journée dans l'écran Match.
3. **M3** — `championnat` inclus dans l'objet match local (`saveMatch()`) et poussé vers Supabase dans le même appel `update()` que `season`/`journee`/`coach_notes` (STORY-48) — pas un appel réseau séparé.
4. **M4** — `renderBilanSaison()` exclut les matchs où `championnat==="Amical"` du calcul agrégé (victoires/nuls/défaites, buts, stats joueurs/GB) — un match amical n'apparaît dans aucun total de cette vue.
5. **M5** — Le Championnat est visible dans la liste "Matchs sauvegardés" (`renderHistory()`), à côté de Journée — pour que Romain distingue visuellement, sans ouvrir chaque match, lesquels comptent dans le bilan de saison.
6. **M6** — Les matchs sans `championnat` renseigné (créés avant cette story) sont traités comme faisant partie du bilan de saison (pas exclus par défaut) — seule la valeur explicite `"Amical"` déclenche l'exclusion, pas l'absence de valeur.

## Won't (hors scope explicite)
- Pas de filtre/toggle pour "voir aussi les matchs amicaux" dans le bilan de saison — exclusion systématique et non configurable pour cette version (Romain n'a pas demandé d'option, juste l'exclusion).
- Pas de deuxième niveau "niveau du championnat" séparé — un seul champ combiné, confirmé par Romain.
- Pas de migration rétroactive des matchs existants pour leur assigner un championnat — ils restent inclus dans le bilan de saison par défaut (cf. M6), à corriger manuellement par Romain si besoin (déjà possible via l'édition du champ).
- Pas de statistiques séparées "bilan des matchs amicaux" dans cette version — juste l'exclusion, pas un nouvel écran dédié aux amicaux.

## Priorité
Une seule story (STORY-49) — dépend de la migration SQL déjà livrée avec STORY-48 (même script, déjà étendu), pas de nouvelle dépendance technique.
