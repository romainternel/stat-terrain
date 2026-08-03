# STORY-26 — Mode lecteur (verrouillage de la saisie)

## Origine
Demande directe de Romain suite au chantier Supabase multi-appareil (STORY-10 à 14) : « Est-ce qu'on peut mettre un mode lecteur simplement qui verrouillerait pour pas écrire de connerie ? »

Contexte : plusieurs appareils peuvent maintenant suivre/modifier le même match en temps réel. Un aidant occasionnel qui regarde sur son téléphone peut cliquer par erreur et fausser les statistiques du match en cours. Le mode lecteur permet de verrouiller localement un appareil en lecture seule, sans toucher aux autres appareils ni au serveur.

## Comportement attendu
- Un bouton dans le panneau Réglages (écran Match) bascule `S.readOnly` on/off.
- L'état est mémorisé par appareil (`localStorage`), donc persiste au rechargement — chaque appareil garde son propre statut lecteur/éditeur.
- Quand actif : toute action d'écriture sur le match en cours est bloquée (but/tir/TM/sanction/PD, timer, mi-temps, sélection GB, annuler/supprimer un événement).
- La réception d'événements distants (sync entrante Supabase, STORY-13/14) continue de fonctionner normalement — le mode lecteur ne bloque que l'écriture locale, jamais la lecture/synchronisation entrante.
- Un bandeau visuel + une désaturation des boutons d'écriture signalent clairement l'état verrouillé, pour éviter toute confusion.
- Hors scope volontaire : l'écran Équipes (gestion des effectifs) n'est pas verrouillé par ce mode — c'est une préoccupation de configuration d'avant-match, pas de saisie en direct pendant le match.

## Notes d'implémentation (rétroactif)
- Garde `if(S.readOnly) return;` ajoutée en tête de chaque fonction/handler d'écriture : `clickTeam`, `clickActionMap`, `startTimer`, `stopTimer`, `resetTimer`, `recordTM`, `validateActionPanel`, `validateAndClose`, `recordEvent`, `undoLast`, `deleteEvent`, `editEvent`, le handler `per-btn` (bascule mi-temps), le handler `[data-gk-sel]` (sélection gardien), les handlers du widget PD (`pd-btn`, `data-pick-pd`, `pd-remove`), et `[data-badge]` (ouverture du menu sanction).
- Verrou visuel via classe `.match-layout.is-readonly` (CSS `opacity:.35;pointer-events:none;` sur les contrôles d'écriture) + `.feed-panel.is-readonly` pour le bouton supprimer du fil, + bandeau `.readonly-banner`.
- Le panneau Réglages lui-même (et son propre bouton de bascule) reste toujours cliquable, pour ne jamais s'auto-verrouiller hors d'atteinte.
