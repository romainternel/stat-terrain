# Brief — Deux équipes distinctes (-18 et CF/N1) dans la même appli

## Origine
Romain, en clarifiant STORY-49 (Championnat) : "C'est une nouveauté d'avoir deux équipes." Le CF FENIX Toulouse gère en réalité **deux équipes distinctes** — l'équipe -18 (moins de 18 ans) et l'équipe CF/N1 (Nationale 1, l'équipe actuellement modélisée par défaut dans l'app) — chacune avec son propre effectif, son propre championnat, son propre historique de matchs.

## Besoin réel
Une seule installation de l'app (un seul dépôt, un seul déploiement Netlify/GitHub Pages, un seul projet Supabase — "se servir de la même appli") doit pouvoir servir les deux équipes **sans mélanger leurs données** : effectif -18 jamais mélangé à l'effectif CF, historique de matchs -18 jamais mélangé à l'historique CF, saisie en cours sur un appareil ne doit jamais afficher/écrire dans les données de l'autre équipe.

Écran d'entrée demandé : un visuel avec deux encarts ("-18" et "CF", en gros), que Romain va fournir ou que je peux proposer — sert à choisir l'équipe active.

## Décision actée avec Romain (AskUserQuestion)
Le choix d'équipe est **mémorisé par appareil** : l'écran de choix apparaît à la première utilisation (ou après un changement volontaire), puis l'appareil reste sur cette équipe à chaque ouverture suivante — cohérent avec l'usage réel (un iPad dédié à chaque équipe la plupart du temps), avec un moyen de changer d'équipe explicitement si besoin (ex: un appareil partagé entre les deux équipes selon les jours).

## Complication déjà identifiée en creusant le code
- `hb2_teams` (localStorage) stocke aujourd'hui **un seul** effectif home/away — doit devenir scopé par équipe.
- Les matchs sauvegardés localement (IndexedDB) et sur Supabase (`matches`) n'ont aujourd'hui aucune notion d'équipe — nécessite un nouveau champ de scoping (`team_profile`), et une adaptation de STORY-48 (rapatriement multi-appareil) pour ne rapatrier que les matchs de l'équipe active, jamais ceux de l'autre équipe.
- Les matchs déjà sauvegardés **avant** cette story (aucun `team_profile`) doivent rester rattachés à l'équipe CF par défaut (c'est elle qui existait avant que -18 soit introduite) — pas de perte de l'historique déjà construit par Romain.
- Le modèle de sécurité reste **inchangé** : un seul compte Supabase partagé (STORY-10/11) pour tout le club — cette story ajoute un filtre de confort côté appli, pas une frontière de sécurité entre les deux équipes au niveau de la base de données (quiconque a le mot de passe partagé technique voit toujours tout, comme aujourd'hui pour une seule équipe).

## Lié à STORY-49 (Championnat, en cours de cadrage)
Le champ Championnat devient plus simple avec les deux équipes : chaque profil (`-18`/`CF`) a naturellement SON propre championnat qui revient match après match (ex: CF joue presque toujours en N1, -18 joue toujours son propre championnat -18) — la saisie libre avec mémorisation par équipe (demandée par Romain : "on écrit à chaque fois... quand c'est écrit une fois ça reste pour pouvoir le resélectionner") s'intègre naturellement au scoping par équipe plutôt que d'être une liste figée globale. STORY-49 est réintégrée dans ce cycle plutôt que traitée séparément.

## Ce qui ne change pas
Le contenu/fonctionnement du reste de l'app (Match, Stats, Bilan, PDF) — une fois l'équipe active choisie, tout se comporte exactement comme aujourd'hui, juste scopé aux données de cette équipe.
