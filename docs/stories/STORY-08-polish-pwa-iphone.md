# STORY-08 — Polish PWA à l'installation sur iPhone

**En tant que** Romain,
**Je veux** que l'app ait une icône et un nom corrects quand je l'ajoute à l'écran d'accueil de mon iPhone,
**Afin de** avoir une expérience d'installation aussi soignée que sur iPad.

## Contexte technique

- Zone concernée : `manifest.json`, `index.html` (meta tags `apple-mobile-web-app-title`, `theme-color`, `favicon.png`/`apple-touch-icon`).
- Vérifier le rendu réel sur iPhone (icône, nom sous l'icône, splash screen au lancement) — actuellement pensé/validé pour iPad seulement selon le CLAUDE.md du projet.

## Critères d'acceptation

- [ ] L'icône affichée à l'écran d'accueil iPhone est nette (pas de recadrage/flou dû à une résolution insuffisante).
- [ ] Le nom affiché sous l'icône est court et clair (cohérent avec `apple-mobile-web-app-title` actuel "CF FENIX STAT").
- [ ] Le lancement depuis l'écran d'accueil sur iPhone ouvre l'app en plein écran (pas la barre d'adresse Safari), comme sur iPad.
- [ ] Aucune régression de l'installation existante sur iPad.

## Hors scope

- Notifications push, badges d'icône, ou toute fonctionnalité PWA avancée non présente aujourd'hui.

## Dépend de

Aucune.

## Taille

S
