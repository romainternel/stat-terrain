# Design — Accès partagé, reprise de match, clarté aidant (F6/F7/F8)

*Produit par le Designer — squad build BMAD*
*S'appuie sur `docs/prd-v2-cloud-multiuser.md`*

## Contexte

Trois besoins concrets à maquetter : (1) un écran d'accès protégé mais minimal, (2) un moyen pour un deuxième appareil de reprendre un match déjà commencé, (3) rendre la saisie compréhensible pour quelqu'un qui découvre l'app en plein match.

## 1. Écran d'accès (F7)

```
┌───────────────────────────────────┐
│                                     │
│         🤾  FENIX STATS            │
│                                     │
│     Code d'accès                   │
│     [ • • • • • • • •  ]           │
│                                     │
│         [ Entrer ]                 │
│                                     │
└───────────────────────────────────┘
```
- Un seul champ, un seul bouton. Pas de champ email, pas de "mot de passe oublié" visible (Romain gère ça lui-même s'il perd le code).
- Une fois validé sur un appareil, l'accès reste actif (pas de redemande à chaque ouverture) — seul un "déconnecter" explicite dans les réglages le redemande.

## 2. Reprendre un match en cours (nouveau, remplace le simple bouton "Nouveau match" quand un match est déjà actif ailleurs)

```
┌───────────────────────────────────┐
│  Matchs                            │
├───────────────────────────────────┤
│  ┌───────────────────────────────┐ │
│  │ 🟢 EN COURS                    │ │
│  │ FENIX vs Nantes — 12 : 8       │ │
│  │ Débuté il y a 34 min            │ │
│  │           [ Reprendre → ]      │ │
│  └───────────────────────────────┘ │
│                                     │
│  [ + Nouveau match ]                │
└───────────────────────────────────┘
```
- N'apparaît que s'il existe un match "en cours" non terminé sur ce projet Supabase (cohérent avec D4 du brief : passation entre appareils, pas de compte individuel à choisir).
- "Reprendre" ouvre l'écran Match directement dans l'état exact où il en est (score, timer, GB sélectionné, feed).
- Si aucun match n'est en cours, on va directement sur l'écran actuel de démarrage (pas de changement pour l'usage solo habituel).

## 3. Indicateur de synchronisation (discret, dans l'écran Match)

```
┌───────────────────────────────────┐
│ FENIX 12   🕐 08:42    NANTES 8    │
│ [GB ▼]        ✓ sync      [GB ▼]  │
└───────────────────────────────────┘
```
- États possibles : `✓ sync` (à jour), `↻ ...` (en cours d'envoi), `⚠ hors-ligne` (pas de réseau — la saisie continue normalement, juste un rappel visuel discret que la sync attend le retour du réseau).
- Ne doit **jamais** être alarmant ni bloquant — c'est une info de confort, pas un avertissement qui inquiète Romain en plein match. Ton neutre, petite taille, coin de la scoreboard.

## 4. Clarté de la saisie pour un aidant non-spécialiste (F8)

- Pas de nouvel écran : on renforce l'existant.
- Vérifier que chaque bouton d'action garde son icône **et** son label texte (déjà le cas : `.a-icon` + `.a-label`) — ne jamais réduire à l'icône seule pour gagner de la place, l'icône seule est ambiguë pour un non-initié.
- Le bouton d'annulation (`undo`) doit être visuellement aussi accessible que les boutons d'action, pas relégué dans un menu secondaire — un aidant qui se trompe doit pouvoir corriger aussi vite qu'il a agi.
- Pas de tooltip/aide contextuelle supplémentaire proposée ici : ajouter du texte explicatif surchargerait l'écran (contraire au principe "moins c'est mieux" du Designer) — la clarté vient de labels déjà bons, pas d'une couche d'aide en plus.

## Composants réutilisés vs nouveaux

- **Nouveaux** : écran d'accès (F7), écran "Matchs en cours / Reprendre" (F6), indicateur de sync (petit composant dans la scoreboard).
- **Réutilisés tels quels** : tout l'écran Match, tous les boutons d'action, le feed, les stats — F8 ne change aucune structure, seulement une vérification/durcissement des labels existants.
