# Brief v8 — Terrain à effectif variable par poste + corrections PDF (itération 3)

## Contexte
Romain vient de terminer le premier test de bout en bout de l'export PDF et du repositionnement du terrain livrés cette session : un vrai match (FENIX Toulouse vs Yoshi, 14 joueurs sélectionnés de chaque côté) joué au clic réel, sauvegardé, puis exporté en PDF. C'est la première fois que ces deux fonctionnalités sont éprouvées avec un effectif complet des deux côtés plutôt qu'un jeu de données de test restreint (2-3 joueurs). Deux classes de problèmes ressortent, toutes deux des effets de bord du **volume réel de données** que les jeux de test précédents, plus petits, ne révélaient pas :

1. Le terrain ne gérait le repositionnement propre (STORY précédente cette session) que pour le cas à 2 joueurs par poste. Avec un effectif complet, certains postes peuvent compter 3 ou 4 joueurs sélectionnés pour le match — le mécanisme actuel n'a pas de disposition prévue pour ces cas et les encarts se chevauchent.
2. Le PDF, avec deux tableaux complets FENIX + ADVERSAIRE (~14 lignes chacun) au lieu du jeu de test réduit qui avait servi à valider la version précédente, déborde : le graphique "Évolution du score" placé après les deux tableaux est repoussé hors de la page. Plusieurs défauts secondaires de contenu (glyphe mal rendu, incohérence de lecture d'un chiffre entre l'app et le PDF, tableau manquant côté adversaire) ressortent au passage de ce même test réel.

## Problème
Romain ne peut aujourd'hui ni composer une équipe réaliste sur le terrain (3-4 joueurs à un même poste, cas courant en handball — un effectif de 14-16 joueurs sur 7 postes en compte nécessairement plusieurs à 2+) sans chevauchement visuel, ni distribuer un PDF de fin de match fiable dès que les deux effectifs sont complets : du contenu déborde de la page, un chiffre affiché n'a pas le même sens que le même chiffre dans l'app (source de contresens en lecture rapide pendant un debrief), et l'export ne documente que la moitié des tireurs (FENIX, pas l'adversaire).

## Utilisateurs
Romain, seul utilisateur, sur iPad bord de terrain pour la saisie et sur son PC pour la relecture/l'export PDF qu'il partage ensuite (probablement avec son staff ou les joueurs). Le PDF est un livrable qui sort de l'app — contrairement aux écrans internes, ses défauts sont vus par des tiers qui n'ont pas le contexte de développement.

## Vision
Le terrain se comporte correctement quel que soit l'effectif réellement sélectionné pour le match (pas seulement 1 ou 2 par poste), et le PDF reste lisible et cohérent avec l'app quel que soit le volume de données du match (petit ou grand effectif, beaucoup ou peu d'événements) — sans nécessiter un nouveau correctif ponctuel à chaque fois que Romain teste avec un jeu de données plus riche que la fois précédente.

## Scope

**Dans le scope** :
- Terrain : disposition dédiée pour 3 et 4 joueurs au poste Pivot (les deux cas concrets remontés), triangle et carré respectivement
- PDF : découpe de la page Joueurs (tableaux) et de la page Évolution du score en deux pages distinctes, pour ne plus jamais dépendre de la longueur des tableaux
- PDF : diagnostic du chevauchement page 1 signalé (bandeau d'en-tête / carte score) — corrigé s'il est reproduit avec un jeu de données chargé, sinon requalifié comme même cause racine que le point précédent
- PDF : remplacement du glyphe "★" (rendu "&" par la police jsPDF) par du texte ASCII sûr, sur le Top 3 et vérification qu'aucun autre glyphe non-ASCII ne traîne ailleurs dans le PDF
- PDF : ligne Top 3 d'un gardien qualifié — bascule sur arrêts/tirs cadrés (pas tous les tirs)
- PDF : ajout des cartes de tir des joueurs adverses sur la page "Carte tir joueur" (actuellement FENIX uniquement), et centrage de la grille
- PDF : retrait des lettres de zone (HG/HC...) jugées redondantes sur l'encart Zones d'impact Gardiens, et correction de la sémantique du ratio affiché pour qu'elle corresponde à ce que l'app affiche déjà ailleurs (perspective tireur, pas gardien) — avec la même légende explicative que l'app

**Hors scope** :
- Disposition pour 5+ joueurs à un même poste (cas non observé, non réaliste pour un effectif de handball — à documenter comme limite acceptée, pas à développer)
- Toute nouvelle fonctionnalité PDF non mentionnée dans les retours de Romain (le fond blanc, les encarts bleus, le Top 3 mixte joueurs+GB, le tableau ADVERSAIRE déjà ajouté ne sont pas remis en cause)
- L'idée "Steazzi" (graphique buts/minute en complément de l'évolution cumulée) — explicitement mise de côté par Romain pour discussion ultérieure, pas pour ce cycle

## Critères de succès
- Un effectif de 3 ou 4 pivots s'affiche sur le terrain sans qu'aucun encart ne chevauche un autre, à n'importe quelle largeur d'écran raisonnable
- Un PDF généré avec deux effectifs complets (14 joueurs chacun) ne présente plus aucun élément qui déborde de sa page ou chevauche un autre élément
- Le rang 1 du Top 3 s'affiche avec un caractère lisible (pas "&")
- La lecture d'un ratio dans l'encart Zones d'impact du PDF donne la même interprétation que le même encart dans l'app en direct
- La page "Carte tir joueur" documente les deux équipes, pas une seule

## Questions en suspens
- Aucune bloquante identifiée : les 5 points sont précisément décrits par Romain avec suffisamment de détail technique (il a lui-même diagnostiqué la cause du débordement PDF et proposé la solution — sortir Évolution du score sur sa propre page) pour cadrer directement sans aller-retour.
