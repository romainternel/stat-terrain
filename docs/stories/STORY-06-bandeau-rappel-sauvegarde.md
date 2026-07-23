# STORY-06 — Bandeau de rappel de sauvegarde dans Bilan

> **⚠ Superseded par STORY-15** (cycle 2, stockage Supabase). Avec la synchronisation automatique en continu, ce bandeau perd sa raison d'être — remplacé par l'indicateur de statut de sync. Ne pas développer cette story telle quelle ; le bouton d'export manuel existant reste disponible en secours dans les réglages.

**En tant que** Romain,
**Je veux** un rappel visible (mais discret) de la dernière fois où j'ai exporté mes matchs,
**Afin de** ne pas oublier de sauvegarder mes données en dehors de l'appareil.

## Contexte technique

- Zone concernée : `app.js` — écran/rendu Bilan (fonction de rendu de l'onglet Bilan), `exportAllMatches()` existant.
- Nouvelle clé `localStorage` : `hb2_lastExport` (timestamp), écrite après un export réussi.
- Référence design : `docs/design/data-safety-reminder.md`.
- Le bandeau n'apparaît que dans l'onglet Bilan, jamais pendant la saisie en match.

## Critères d'acceptation

- [ ] Un bandeau discret apparaît en haut de l'onglet Bilan, affichant "Dernière sauvegarde : jamais" ou une date/heure relative.
- [ ] Un bouton "Exporter" dans ce bandeau déclenche `exportAllMatches()` existant, sans nouveau flux technique.
- [ ] Après un export réussi, le bandeau se met à jour ("à l'instant") et la valeur persiste après un rechargement de l'app (via `localStorage`).
- [ ] Le bandeau n'apparaît jamais sur l'écran Match (ne doit pas distraire pendant la saisie).

## Hors scope

- Tout export automatique/silencieux sans action de Romain.
- Sauvegarde cloud (reste un export fichier manuel).

## Dépend de

Aucune.

## Taille

S
