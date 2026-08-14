# Brief — Champ Championnat / Amical

## Origine
Suite directe de STORY-48 (sync historique) : en discutant de l'extension du schéma Supabase, Romain a proposé d'ajouter un champ pour distinguer le type de compétition. Précisé ensuite : "CHAMPIONNAT ca sera N1 N2 -18 ou Amical. Possible d'avoir option d'écrire aussi." et "Amical doit être exclu des stat de la saison".

## Besoin réel
Aujourd'hui, `S.season`/`S.journee` existent déjà (état global, édités via un clic + `prompt()` sur un badge compact dans l'écran Match, `app.js` ~ligne 1962-1968) mais rien ne distingue un match de championnat officiel d'un match amical. Conséquence concrète : `renderBilanSaison()` (~ligne 3904, l'agrégation "Saison" — victoires/nuls/défaites/stats moyennes/top joueurs) inclut aujourd'hui **tous** les matchs d'une saison sans distinction, ce qui fausse le bilan si des matchs amicaux y sont mêlés.

## Ce qui est demandé
- Un champ "Championnat" par match : 4 valeurs rapides (N1, N2, -18, Amical) + une option de saisie libre pour les cas non prévus (coupe, tournoi, autre catégorie).
- Vit au même endroit que Saison/Journée (même badge compact dans l'écran Match), pas un nouvel écran.
- Persisté par match, poussé vers Supabase en même temps que Saison/Journée/Notes coach (STORY-48, colonne déjà ajoutée à la migration existante).
- **Un match "Amical" est exclu du calcul des statistiques agrégées de saison** (victoires/nuls/défaites, stats moyennes, top joueurs/GB) — mais reste visible normalement dans l'historique et son propre Bilan individuel.

## Contexte technique déjà établi (à réutiliser)
Migration Supabase déjà étendue (`docs/supabase-migration-season-journee-notes.sql`, colonne `championnat` déjà ajoutée par anticipation) — Romain doit l'exécuter une seule fois pour STORY-48 et STORY-49 ensemble. Point d'écriture Supabase déjà découplé en 2 appels séparés dans `markMatchFinishedById()` (STORY-48) — le nouveau champ s'ajoute au 2e appel (champs "confort"), sans risque pour le comportement critique existant.

## Ce qui ne change pas
Le mécanisme de rapatriement lui-même (STORY-48), le Bilan par match individuel (affiche toujours tous les matchs, amicaux compris), l'export/import CSV.
