# PRD v2 — Stockage Supabase + saisie partagée

*Produit par le Product Manager — squad build BMAD*
*S'appuie sur `docs/brief-v2-cloud-multiuser.md`. Complète `docs/prd.md` (cycle 1, toujours valide pour F1/F2).*

## 1. Objectif

Permettre à un match d'être suivi depuis plusieurs appareils (Romain, et occasionnellement un aidant bénévole) via un stockage partagé Supabase, sans jamais dépendre du réseau pour continuer à saisir, et sans complexifier l'usage quand Romain est seul — ce qui reste le cas le plus fréquent.

## 2. Features

### F6 — Stockage partagé Supabase (source de vérité durable)
Le match en cours est répliqué sur Supabase (en plus du stockage local existant) pour que :
- un autre appareil puisse ouvrir le même match et voir son état (score, événements déjà saisis, GB en cours),
- les données survivent à la perte/casse d'un appareil,
- l'historique de matchs terminés soit centralisé (au lieu de rester uniquement dans l'IndexedDB d'un seul appareil).
La saisie reste **toujours locale en premier** (écriture immédiate dans l'état de l'app, cf. STORY-01 du cycle 1) ; la synchronisation vers Supabase se fait en arrière-plan et se rattrape automatiquement après une coupure réseau.

### F7 — Accès protégé par un identifiant unique partagé
Un seul point d'entrée protège l'app (empêcher un inconnu sur internet d'accéder aux données de match), sans gestion de comptes individuels. Un identifiant/mot de passe unique, que Romain partage verbalement à qui l'aide ce jour-là. Une fois entré sur un appareil, plus besoin de ressaisir tant que la session est valide.

### F8 — Clarté de l'interface pour un aidant occasionnel non-spécialiste
Pas un nouveau "mode" séparé (ça ajouterait de la complexité) — un durcissement de la lisibilité de l'écran de saisie existant pour qu'une personne non familière du handball ou peu à l'aise avec le numérique (le cas décrit par Romain : bénévole, parfois âgé) puisse saisir sans formation :
- Labels d'action sans jargon ambigu (vérifier que BUT/TIR/PB/PO/PEN restent compréhensibles sans légende).
- Annulation (`undo`) très accessible en cas d'erreur de saisie — cas fréquent avec un aidant qui découvre l'app.
- Pas de geste caché ni de double-tap requis pour une action courante.

### F9 (non-fonctionnel) — Déploiement clonable et isolé
Chaque déploiement (FENIX aujourd'hui, potentiellement le coach des -18 demain) a son **propre** projet Supabase et son propre repo — jamais de partage de données entre déploiements. La config Supabase (URL + clé) doit être isolée dans l'app pour qu'un clonage soit une simple substitution de config, pas une réécriture.

## 3. Priorités

| Feature | Priorité | Justification |
|---|---|---|
| F6 — Stockage partagé Supabase | **Must Have** | C'est la demande explicite et la brique qui rend le reste possible. |
| F7 — Accès protégé | **Must Have** | Sans ça, F6 expose les données de match à n'importe qui sur internet — non négociable dès qu'il y a un backend public. |
| F8 — Clarté interface aidant | **Should Have** | Améliore la fiabilité de la saisie par un tiers, mais l'interface actuelle (gros boutons, workflow simple) part déjà d'une bonne base. |
| F9 — Déploiement clonable isolé | **Must Have** | Condition explicite de Romain pour ne pas "bouffer" son quota/contenu avec d'autres coachs. |

## 4. Critères d'acceptation

**F6**
- [ ] Une action saisie sur un appareil apparaît sur un autre appareil ouvrant le même match, en quelques secondes, quand les deux ont du réseau.
- [ ] Une coupure réseau pendant la saisie n'empêche jamais d'enregistrer une action localement ; la sync se termine automatiquement au retour du réseau.
- [ ] Aucun événement n'est perdu ni dupliqué si deux appareils écrivent au même moment (rare, mais doit être géré sans casser le fil du match).
- [ ] Un match peut être joué et sauvegardé de bout en bout sans aucun réseau disponible (comme aujourd'hui), la sync se faisant a posteriori.

**F7**
- [ ] Un appareil sans le bon identifiant ne peut ni lire ni modifier les données de match.
- [ ] Une fois l'identifiant saisi sur un appareil, il n'est pas redemandé à chaque ouverture (dans une limite raisonnable de durée de session).

**F8**
- [ ] Un utilisateur non initié (simulation : quelqu'un qui découvre l'app) peut saisir un but et l'annuler sans aide.

**F9**
- [ ] La configuration Supabase (URL, clé) est isolée dans un seul endroit du code, jamais dispersée — un clonage se résume à remplacer ces valeurs.

## 5. Hors scope

- Comptes utilisateurs individuels, gestion de rôles/permissions par personne.
- Multi-tenant (plusieurs clubs/coachs dans le même projet Supabase).
- Migration des matchs déjà stockés localement (décision de Romain : seuls les nouveaux matchs utilisent Supabase).
- Résolution de conflit avancée avec interface dédiée (pas nécessaire vu l'usage réel : un seul preneur de stats actif la plupart du temps).

## 6. Dépendances

- F7 doit être livré **avant ou en même temps que** F6 — jamais de backend ouvert sans protection d'accès, même temporairement.
- F9 doit être posé dès la mise en place initiale de Supabase (décision de config), pas ajouté après coup.
- F8 peut être livré indépendamment, à tout moment.

## 7. Risques

Voir `docs/risks/supabase-multiuser.md` (Risk Analyst) pour le détail — notamment le risque de dépendance réseau en gymnase et la nécessité de garder un fonctionnement 100% offline-capable.
