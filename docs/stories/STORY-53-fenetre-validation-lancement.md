# STORY-53 — Fenêtre de validation au lancement du match

**En tant que** Romain,
**Je veux** être averti (sans être bloqué) si un GB ou un effectif manque au lancement du match,
**Afin de** ne jamais démarrer une saisie sans savoir qu'une info est incomplète.

Référence complète : `docs/design/retours-premier-match-reel.md`, `docs/arch/retours-premier-match-reel.md` (section M5), `docs/risks/retours-premier-match-reel.md` (R5).

> **Mode "équipe générale" abandonné** — Romain a demandé de laisser tomber cette piste après lecture du résumé du cycle. Cette story se limite à l'alerte, aucun bypass de saisie sans joueur n'est développé.

## Contexte technique
Nouvel état `S.launchWarningsCollapsed:false`, `S.launchWarningsDismissed:false` (reset par `newMatch()`). Nouvelle fonction pure `launchWarnings()` (aucun effet de bord — lecture seule de `S.home`/`S.away`/`S.trackGK`).

## Critères d'acceptation
- [ ] Au lancement du match (après M1/STORY-52), si GB manquant (`S.trackGK` actif) et/ou effectif vide pour une équipe, un bandeau non bloquant apparaît en haut de l'écran Match listant chaque manque (ex. "GB non sélectionné pour IVRY", "Aucun effectif sélectionné pour FENIX Toulouse")
- [ ] `[–]` réduit le bandeau vers une pastille discrète (près du bouton Réglages), ré-ouvrable
- [ ] `[✕]` ferme définitivement pour cette session de match, pas de réapparition automatique
- [ ] Le match reste utilisable normalement peu importe l'état de ce bandeau (jamais bloquant, aucune dégradation du flux de saisie existant)
- [ ] Ne réapparaît jamais après un `newMatch()` sans nouveau manque détecté
- [ ] Vérifié en Mode Simple ET Mode Expert (le bandeau est indépendant du mode de saisie)

## Cas limites à tester
- Effectif partiellement sélectionné pour une équipe (quelques joueurs, pas zéro) : pas de warning pour cette équipe (seul le cas "zéro joueur sélectionné" est signalé)
- Match rechargé/repris (STORY-14) : le bandeau doit pouvoir apparaître normalement si le manque existe toujours, pas seulement sur un match démarré dans la session courante

## Hors scope
Mode équipe générale / saisie sans joueur attribué (abandonné). Corrections de STORY-52 (dépendance de contexte, pas de blocage technique entre les deux).

## Dépend de
Aucune dépendance technique stricte avec STORY-52, mais développable après pour un contexte plus complet (chrono déjà auto-démarré au moment où ce bandeau apparaît).

## Taille
S — un bandeau d'affichage en lecture seule, aucune modification du flux de saisie.
