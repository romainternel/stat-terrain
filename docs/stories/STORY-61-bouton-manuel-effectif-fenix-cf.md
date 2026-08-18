# STORY-61 — Bouton manuel pour recharger l'effectif FENIX CF

**En tant que** Romain,
**Je veux** un bouton visible pour charger l'effectif FENIX CF,
**Afin de** ne pas dépendre uniquement du chargement automatique lors d'un changement d'appareil.

"J'AI CHANGÉ DE TABLETTE. Je ne trouve pas où est le bouton pour ajouter de manière automatique l'équipe Fenix" — le chargement automatique (STORY-56) existe mais n'a, pour une raison non confirmée à distance, pas eu lieu sur la nouvelle tablette (aucun bouton n'existait jusqu'ici, comportement volontaire à l'origine — "Automatique au premier lancement" avait été choisi explicitement). Plutôt que de dépendre d'un diagnostic à distance en plein préparatif de match, un filet de sécurité manuel est ajouté.

## Contexte technique
Nouveau bouton `⚡ FENIX CF` dans `renderTeamSetup("home")`, visible uniquement quand `isHome && S.teamProfile==="cf"` (jamais côté Adversaire, jamais sur le profil "-18" qui n'a pas de liste fournie). Réutilise `defaultFenixCfTeam()` telle quelle (même liste que le chargement automatique) — confirmation avant remplacement (`safeConfirm`, contrairement à l'auto-chargement qui ne s'exécute que sur un effectif vide) car ce bouton peut être cliqué sur un effectif déjà personnalisé.

## Critères d'acceptation
- [x] Bouton visible sur l'onglet Équipes, côté FENIX Toulouse, uniquement profil "cf"
- [x] Absent côté Adversaire et absent sur le profil "-18"
- [x] Clic → confirmation → remplace `S.home.players` par les 22 joueurs officiels, `gkId` remis à `null` (cohérent avec STORY-60 : aucun n'est encore sélectionné pour ce match)
- [x] Fonctionne même si l'effectif contient déjà des joueurs (recharge complète, pas un ajout)

## Vérifié par CDP
Profil "cf" avec effectif vide → bouton présent, clic → 22 joueurs chargés (`Isaac.M` en premier, `gkId:null`) ; profil "-18" → bouton absent ; un seul bouton dans tout le DOM (jamais dupliqué côté Adversaire).

## Taille
XS — 1 bouton conditionnel + 1 handler réutilisant une fonction existante.

## Addendum — bouton symétrique côté Adversaire
Demande immédiate de suivi : "il me faut idem pour adversaire". Bouton `⚡ Modèle` ajouté dans `renderTeamSetup("away")`, visible sur les deux profils (pas seulement "cf" — le modèle 7 postes n'est pas spécifique à une équipe FENIX). Réutilise `defaultAdversairePlayers()` (pas `defaultAdversaireTeam()`) pour ne remplacer que `players`/`gkId`, **sans jamais toucher `S.away.name`** — un nom d'adversaire déjà saisi (ex. "Ivry") ne doit pas être écrasé par un rechargement du modèle. Vérifié par CDP : nom conservé après clic, effectif remplacé par les 7 postes, un seul bouton présent (jamais dupliqué côté FENIX), capture d'écran confirmant le placement symétrique des deux boutons.
