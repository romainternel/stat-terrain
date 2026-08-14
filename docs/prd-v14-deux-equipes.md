# PRD — Deux équipes distinctes (-18 et CF/N1)

## Objectif
Une seule appli, un seul déploiement, sert les deux équipes du CF FENIX Toulouse sans jamais mélanger leurs effectifs, leurs matchs, ni leur historique.

## Must (cette version)
1. **M1** — Nouvel état `S.teamProfile` (`"cf"` | `"u18"`), persisté par appareil (`localStorage hb2_team_profile`) — jamais réinitialisé automatiquement, changeable uniquement via une action explicite (réglages).
2. **M2** — Écran de choix d'équipe (2 encarts, "-18" et "CF") affiché **une seule fois par appareil** : à la première utilisation (aucun `S.teamProfile` en mémoire) ou après un changement volontaire déclenché depuis les réglages. Jamais affiché à chaque ouverture si un choix est déjà mémorisé (décision actée avec Romain).
3. **M3** — Effectifs (`hb2_teams`) scopés par équipe — l'effectif -18 et l'effectif CF sont deux listes totalement indépendantes, jamais mélangées à l'affichage ni à l'édition.
4. **M4** — Matchs (locaux et Supabase) taggés par équipe active au moment de la sauvegarde — l'historique Matchs/Bilan/Saison n'affiche jamais que les matchs de l'équipe active. Le rapatriement multi-appareil (STORY-48) filtre aussi par équipe : un appareil sur le profil -18 ne rapatrie jamais un match CF, et inversement.
5. **M5** — **Migration de compatibilité** : tous les matchs déjà sauvegardés avant cette story (aucun `teamProfile`) sont traités comme appartenant au profil `"cf"` — aucune perte de l'historique déjà construit par Romain avec l'équipe CF actuelle.
6. **M6** — Champ Championnat (reprend et remplace le périmètre de STORY-49) : saisie libre avec mémorisation des valeurs déjà tapées **par équipe** (le profil -18 mémorise son propre historique de valeurs, indépendant de celui de CF) — pas de liste figée N1/N2/-18/Amical globale.
7. **M7** — "Amical" (valeur exacte, insensible à la casse) reste exclu du bilan de saison, comme déjà spécifié — comportement inchangé, juste la saisie qui devient libre.
8. **M8** — Un moyen explicite de changer d'équipe depuis les réglages (⚙), avec confirmation bloquante si un match est en cours (cohérent avec les confirmations déjà utilisées ailleurs — ex: bascule Simple/Expert).
9. **M9** — Nom d'équipe par défaut cohérent par profil : `"FENIX Toulouse"` pour `cf`, `"FENIX Toulouse -18"` pour `u18` (pas le même nom pour les deux, pour éviter la confusion dans les listes/exports).

## Won't (hors scope explicite)
- Pas de séparation de sécurité au niveau de la base de données (RLS) entre les deux équipes — même compte partagé, même modèle qu'aujourd'hui (accepté, cf. Brief).
- Pas de bascule "voir les deux équipes en même temps" (ex: un bilan combiné -18+CF) — chaque profil reste une vue strictement séparée.
- Pas de migration automatique d'une partie de l'historique CF existant vers -18 — si Romain veut réattribuer manuellement un match précis, ce sera une action manuelle future, hors scope ici.
- Le design visuel exact de l'écran des deux encarts (couleurs, animation précise "d'un coin à l'autre") **attend la référence visuelle de Romain** — le Designer/Visual Crafter proposent une direction raisonnable à valider/remplacer, pas un rendu final déjà figé.
- Pas de 3e profil ni de système de profils extensible à l'infini — deux profils fixes (`cf`/`u18`), codés en dur, pas une liste configurable (cohérent avec le besoin réel exprimé, pas une généralisation spéculative).

## Priorité et découpage
Recommandation (à confirmer par le Risk Analyst/Scrum Master) : séparer la **fondation données** (state, scoping local+Supabase, migration de compatibilité, réglage de changement d'équipe) de **l'écran visuel de choix** (dépend de la référence de Romain, peut suivre après). STORY-49 (Championnat) est absorbée dans la fondation plutôt que développée séparément, pour éviter de coder deux fois le même point d'écriture Supabase.
