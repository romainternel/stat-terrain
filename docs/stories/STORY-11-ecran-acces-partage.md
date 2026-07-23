# STORY-11 — Écran d'accès partagé

**En tant que** Romain (ou quiconque m'aide ce jour-là),
**Je veux** entrer un seul mot de passe pour ouvrir l'app,
**Afin de** protéger les données de match sans avoir à gérer un compte par personne.

## Contexte technique

- Zone concernée : nouvel écran d'accueil avant l'app actuelle, `app.js`.
- Email fixe (stocké dans `config.js`), seul le mot de passe est demandé à l'utilisateur (maquette `docs/design/acces-partage-et-reprise-match.md`).
- Utilise `supabase.auth.signInWithPassword()` avec l'email fixe + le mot de passe saisi.
- Session persistée automatiquement par `supabase-js` (localStorage) — pas de redemande systématique.

## Critères d'acceptation

- [ ] Un écran avec un seul champ (mot de passe) et un bouton "Entrer" s'affiche avant d'accéder à l'app.
- [ ] Un mauvais mot de passe affiche une erreur claire, sans révéler si c'est l'email ou le mot de passe qui est en cause.
- [ ] Une fois connecté, l'app ne redemande pas le mot de passe à chaque ouverture — **testé concrètement sur iPad et iPhone Safari** (fermeture complète de l'app puis réouverture), pas seulement sur un navigateur desktop (cf. risque #5, `docs/risks/supabase-multiuser.md`).
- [ ] Un moyen (dans les réglages) de se déconnecter explicitement existe, pour le cas où l'appareil change de "propriétaire" de fait.

## Hors scope

- Réinitialisation de mot de passe (gérée manuellement par Romain via le dashboard Supabase si besoin).
- Comptes multiples.

## Dépend de

STORY-10.

## Taille

S
