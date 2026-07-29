# Research — Mode Simple / Mode Expert

## Sujet
Romain propose deux niveaux de prise de stats — un mode "Simple" et un mode "Expert" — avec un choix à l'entrée de l'app, et l'idée que l'iPhone devrait par défaut être en mode Simple. Question ouverte posée par Romain lui-même : finir le polish du mode Expert actuel puis simplifier ensuite, ou dissocier dès maintenant ?

## Benchmark
Le pattern "mode rapide / mode détaillé" est **déjà largement validé** dans la catégorie des apps de stats sportives live :
- Les apps de scorekeeping amateur/semi-pro (volley, basket, hand) proposent quasi-systématiquement un mode "score only" (juste +1/-1 par équipe, parfois par joueur) à côté d'un mode "box score complet" (chaque action, position, joueur).
- Hudl Sideline et les outils de tagging vidéo terrain proposent une saisie "rapide" (tag générique) distincte d'une saisie "détaillée" (position, joueur, contexte) — précisément parce que sous pression de match, ajouter des étapes de saisie fait perdre ou mal placer des événements.
- Le principe sous-jacent : **la vitesse et l'exhaustivité sont en tension directe**. Un utilisateur non-expert qui doit choisir un joueur sur un terrain + une zone de but pour CHAQUE tir décrochera ou se trompera. Le mode simple n'est pas une version "moins bien" du mode expert, c'est un outil différent pour un usage différent.

Conclusion : l'idée n'est pas une lubie, c'est un pattern éprouvé ailleurs. **Go sur le principe.**

## Ce n'est pas une direction totalement nouvelle
Le chantier Supabase déjà cadré (non développé) contient **STORY-16 — "Clarté interface aidant"**, qui anticipait déjà qu'un aidant occasionnel aurait besoin d'une interface différente de celle de Romain. Le mode Simple/Expert n'est donc pas un sujet parallèle au chantier Supabase : c'est probablement **la brique UX qui manquait pour que ce chantier soit réellement utilisable** le jour où il sera développé. Un aidant qui doit gérer terrain + zones + PD + PO sans formation, même avec un compte partagé fonctionnel, resterait bloqué sans un mode simplifié.

Ceci dit, Romain formule un **second déclencheur, indépendant du premier** : l'iPhone lui-même (peu importe qui l'utilise) devrait par défaut proposer le mode simple, parce qu'un petit écran rend l'usage complet plus difficile. Ce sont deux besoins réels mais distincts (profil utilisateur vs appareil) — à ne pas fusionner sans le dire explicitement dans le cadrage.

## Challenge d'utilité
Est-ce que cette feature génère une décision ou une action concrète ? Oui, à condition que "Simple" reste un sous-ensemble strict et cohérent du modèle de données existant (mêmes champs d'événement, juste certains non renseignés) — sinon on fragmente le stockage et les exports (Stats, Bilan, PDF) devraient gérer deux formes de données différentes, ce qui multiplierait la dette pour un gain flou.

Point de vigilance direct : si "Simple" devient juste "Expert avec moins de boutons visibles mais les mêmes écrans Stats/Bilan derrière", le gain réel pour un aidant non-formé est faible — il verra quand même des stats vides/incomplètes sans comprendre pourquoi. Le PM doit trancher précisément ce que Simple **capture** (probablement : score, buts/tirs arrêtés/non cadrés au niveau équipe, éventuellement 2min/carton — sans terrain, sans zone, sans PD, sans PO/PEN détaillé).

## Données de référence
Pas de seuil chiffré à calibrer ici (ce n'est pas un système d'alerte ou de scoring) — le repère pertinent est qualitatif : les apps comparables limitent leur "mode rapide" à 3-5 actions maximum, sans étape de positionnement. Un mode "Simple" qui garde 6+ boutons et un terrain ne serait pas vraiment plus simple, juste visuellement allégé — attention à ne pas livrer un faux Simple.

## Recommandation
**GO**, avec deux garde-fous à poser dès le Brief/PRD :
1. Définir précisément et étroitement ce que Simple capture (probablement : rien qui touche au terrain/zones/attribution fine).
2. Ne jamais verrouiller l'iPhone en mode Simple de façon rigide — Romain lui-même doit pouvoir repasser en Expert sur iPhone s'il dépanne un match en solo avec son téléphone (cf. `CLAUDE.md`, l'app est déjà utilisée sur iPhone en secours, pas seulement sur iPad).

Sur la question de séquencement (finir le polish Expert d'abord vs dissocier maintenant) : ce n'est pas une question de Research mais de priorisation produit — je la remonte explicitement au PM pour trancher dans le PRD, avec les deux arguments en tension : le mode Expert est en usage réel chaque match (risque de régression sur l'outil qui sert vraiment aujourd'hui), alors que le mode Simple n'a aujourd'hui aucun utilisateur réel confirmé (le chantier Supabase n'est pas construit) — sauf pour le cas iPhone-de-Romain, qui lui est réel et immédiat.

## Questions ouvertes
- Qui utilisera réellement le mode Simple en premier : Romain sur iPhone en dépannage, ou un futur aidant Supabase ?
- Le mode Simple doit-il produire des stats exploitables (Stats/Bilan) ou juste un score/résumé minimal ?
- Le choix de mode est-il par appareil (persistant) ou peut-il changer en cours de match ?
- Un match commencé en Simple peut-il être complété a posteriori en Expert (rattrapage), ou le choix est-il figé pour tout le match ?
