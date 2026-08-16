# Risques — Retours du premier match réel

## Mode équipe générale — abandonné
Romain a demandé d'abandonner cette piste après lecture du résumé du cycle : pas de bypass de saisie sans joueur, juste l'alerte M5. Les risques R1/R2 initialement identifiés (5 points de contrôle sur `ap.shooterId`, cohérence avec l'agrégation par joueur) n'ont plus d'objet et sont retirés — plus aucun changement touchant `validateAndClose()`/`clickGoalZone()`/`clickCourtPosition()`/`clickActionMap()`/`shotMode`.

## R3 — M4 : deux mécanismes de rappel avec des timestamps distincts, risque de confusion de maintenance
`S.halfTimeLastAlert` (nouveau) et `S.tmLastAlert` (existant) sont volontairement séparés (cf. Architecture) pour ne pas se bloquer mutuellement — mais un futur développeur pourrait être tenté de les fusionner "pour simplifier", cassant l'anti-spam indépendant des deux alertes. Commentaire explicite déjà prévu dans le code pour prévenir ce risque.

## R4 — M4 : le rappel peut arriver pendant une saisie en cours (Mode Expert)
Si `checkHalfTimeReminder()` déclenche un `showToast()` pile pendant qu'un `S.actionPanel` est ouvert (utilisateur en train de placer un tir), le toast ne doit pas interrompre/fermer ce panel — `showToast()` est déjà un composant non intrusif (utilisé pendant `checkTimeoutAdvisor()`/`checkGkConsecutiveAlert()` sans jamais interrompre une saisie en cours), donc pas un risque nouveau, juste à confirmer que ce nouveau point d'appel (le tick du chrono plutôt qu'un point de saisie) n'a pas d'effet de bord différent — peu probable mais à vérifier en QA.

## R5 — M5 : détection de "manque" doit rester lecture seule
`launchWarnings()` (nouvelle fonction) ne doit avoir **aucun effet de bord** (juste une liste calculée) — le Code Reviewer doit confirmer qu'elle ne modifie jamais `S.home`/`S.away`/`S.trackGK`, uniquement les lire. Risque mineur mais facile à vérifier.

## R6 — M1 : double appel possible à `startTimer()` si l'utilisateur clique deux fois rapidement sur "Lancer le match"
Déjà mitigé par la garde existante `if(S.running||S.readOnly)return;` dans `startTimer()` elle-même — pas un risque nouveau introduit par ce changement, juste à confirmer qu'elle protège bien contre ce nouveau point d'appel aussi (elle protège déjà contre le double-clic sur l'ancien bouton "▶ Start" manuel, la même garde s'applique).

## Sécurité
Aucun changement de modèle de données Supabase, aucune nouvelle policy, aucun nouveau rôle — tous les changements sont côté logique de saisie locale et affichage. Security Auditor non convoqué.

## Recommandation de découpage
Deux stories :
- **STORY-52** — Corrections ciblées (M1 chrono auto, M2 highlight CSS, M3 possession Mode Simple, M4 rappel mi-temps) — risque faible à modéré (R3/R4/R6 mineurs), développable et vérifiable rapidement, aucune dépendance avec STORY-53.
- **STORY-53** — Fenêtre de validation au lancement (M5 seul, mode équipe générale abandonné) — risque faible, un bandeau d'affichage en lecture seule (R5), aucune modification du flux de saisie.
