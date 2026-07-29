# PRD — Mode Simple / Mode Expert

## Objectif
Introduire deux niveaux de prise de stats — Simple et Expert — sans dégrader le mode Expert actuellement en usage réel chaque match, et sans bloquer sur le chantier Supabase (pas encore développé).

## Décision de séquencement (question posée explicitement par Romain)

**Recommandation : ne pas suspendre le polish du mode Expert, mais ne pas non plus tout dissocier en profondeur dès maintenant.**

Argumentaire :
- Le mode Expert est l'outil utilisé en vrai, chaque match, en ce moment (N1). Le rouvrir en profondeur pour un mode qui n'a aujourd'hui aucun utilisateur confirmé (le chantier Supabase n'est pas construit) fait courir un risque de régression sur l'outil qui sert réellement, pour un bénéfice qui ne sera perçu par personne dans l'immédiat.
- Le déclencheur iPhone, lui, est réel et immédiat (indépendant de Supabase) — il justifie de livrer un mode Simple maintenant, mais pas de réécrire toute l'architecture Match autour de deux modes symétriques.
- L'approche recommandée à l'Architecte (détaillée dans `docs/architecture/mode-simple-expert.md`) : construire le mode Simple comme une **couche additive légère** (un flag d'état qui masque/simplifie l'existant) plutôt qu'un second écran Match dupliqué. Ça évite de doubler la surface de test/QA à chaque future story de polish, et ça ne bloque pas le polish visuel déjà en cours (STORY-04/05, écrans Stats/Bilan/Setup) — les deux chantiers peuvent avancer en parallèle sans se marcher dessus.
- Séquencement proposé : ce cycle (Simple/Expert) passe **après** le polish visuel transverse déjà engagé sur Stats/Bilan/Setup, mais **avant** tout développement du chantier Supabase — de façon à ce que Simple soit prêt et éprouvé le jour où Supabase arrivera.

**Ce choix reste à confirmer explicitement par Romain avant que le Scrum Master ne verrouille l'ordre des stories** — c'est une décision de priorisation produit, pas une évidence technique.

## Features

### Doit avoir (Must Have)
1. **Réglage de mode** (Simple / Expert) — *correction post-vérification code : l'app n'a pas d'écran "Réglages" dédié, seulement un bouton ⚙ Réglages affiché en écran Match qui ouvre un panneau d'actions rapides (sauvegarder/exporter/importer/effectifs/nouveau match). Le toggle de mode suit donc le pattern déjà existant du toggle "Suivi GB" (`S.trackGK`), présent à la fois sur l'écran Équipes (avant de lancer le match) et dans le panneau ⚙ Réglages du Match (pour changer en cours de match).* Mémorisé par appareil (localStorage), pas par match.
2. **Mode Simple pour l'écran Match** : actions limitées à ce qui ne nécessite ni terrain ni zone ni attribution fine — BUT, TIR ARRÊTÉ, TIR NON CADRÉ (au niveau équipe), 2 MIN, CARTON ROUGE, TM. Pas de clic joueur sur terrain, pas de zone de but, pas de PD, pas de PO/PEN détaillé.
3. **Mode Expert inchangé** : comportement actuel de l'app à l'identique — zéro régression, zéro nouvelle friction.
4. **Détection iPhone → Simple par défaut** à la toute première utilisation sur cet appareil (basé sur la largeur d'écran, comme les media queries déjà en place) — mais toujours modifiable manuellement ensuite. Un appareil qui a déjà un réglage explicite ne doit jamais être réinitialisé.
5. **Compatibilité de structure de données** : les événements saisis en Simple utilisent exactement la même structure que ceux d'Expert (mêmes champs), avec les champs non pertinents (x, y, goalZone, assistId...) simplement `null` — pas de nouveau format, pas de migration.

### Devrait avoir (Should Have)
6. **Indicateur visible du mode actif** pendant la saisie (éviter la confusion "où sont passées mes zones ?").
7. **Bascule Simple → Expert en cours de match** sans perte des événements déjà saisis.

### Pourrait avoir (Nice to Have — hors de cette version)
8. Rattrapage a posteriori des détails manquants sur un événement saisi en Simple (ajouter zone/joueur après coup).
9. Adaptation visuelle des écrans Stats/Bilan/PDF selon la richesse réelle des données du match (aujourd'hui : ces écrans afficheront simplement des zones vides/à zéro pour un match saisi en Simple, ce qui est acceptable pour cette version).

## Critères d'acceptation (niveau PRD — détaillés en stories par le Scrum Master)
- Un utilisateur peut choisir/changer de mode dans Réglages, à tout moment.
- Sur iPhone, à la première utilisation de l'app sur cet appareil, le mode par défaut est Simple.
- Sur iPad/desktop, le mode par défaut reste Expert (comportement actuel inchangé).
- En mode Simple, l'écran Match n'affiche ni terrain, ni zone de but, ni PD, ni PO/PEN détaillé.
- Aucune régression du mode Expert n'est détectée (Regression Guardian).
- Le choix de mode est mémorisé par appareil, survit à une fermeture/réouverture de l'app.

## Hors scope
- Le chantier Supabase lui-même.
- Toute nouvelle donnée absente du modèle d'événement actuel.
- Le rattrapage a posteriori des détails (backlog).
- L'adaptation profonde des écrans Stats/Bilan/PDF au mode Simple (ils continueront d'afficher les mêmes écrans, simplement avec moins de données renseignées).

## Dépendances
- Aucune dépendance dure sur le chantier Supabase (livrable indépendamment).
- Dépend de l'état actuel du modèle de données événement (`ACTIONS`, structure d'événement) — pas de changement de structure requis, seulement de nouvelles règles d'affichage conditionnel.

## Risques (détaillés par le Risk Analyst)
- Doublement potentiel de la surface de test si le mode Simple n'est pas conçu comme une couche additive légère.
- Confusion utilisateur si le mode actif n'est pas assez visible.
- Détection iPhone par largeur d'écran : un iPad en mode fenêtré étroit ou un futur appareil intermédiaire pourrait être mal classé — à traiter comme un risque d'edge case, pas un P0.
