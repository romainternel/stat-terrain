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

- [x] Un écran avec un seul champ (mot de passe) et un bouton "Entrer" s'affiche avant d'accéder à l'app.
- [x] Un mauvais mot de passe affiche une erreur claire ("Code d'accès incorrect.") — pas d'ambiguïté possible sur "email ou mot de passe" puisque l'email n'est ni visible ni saisissable (un seul champ existe).
- [ ] **Non vérifié dans cette story** : "une fois connecté, l'app ne redemande pas le mot de passe à chaque ouverture", testé concrètement sur iPad/iPhone Safari (fermeture complète puis réouverture). Nécessite les vrais identifiants du compte partagé (connus seulement de Romain) — à valider par Romain lui-même une fois déployé, cf. section dédiée ci-dessous.
- [x] Un moyen de se déconnecter explicitement existe (panneau Réglages du Match, bouton "🔒 Se déconnecter", visible uniquement si Supabase est configuré) — testé, ramène bien à l'écran d'accès.

## Hors scope

- Réinitialisation de mot de passe (gérée manuellement par Romain via le dashboard Supabase si besoin).
- Comptes multiples.

## Dépend de

STORY-10.

## Taille

S

## Notes Developer
- `SUPABASE_AUTH_EMAIL` ajoutée à `config.js` (email fixe du compte partagé), aux côtés de `SUPABASE_URL`/`SUPABASE_ANON_KEY`.
- Nouvel état `S.authOk` : `null` (vérification en cours) / `false` (écran d'accès affiché) / `true` (accès autorisé). `R()` branche dessus tout en haut, avant même `renderHeader()` — l'écran d'accès remplace entièrement l'app, pas une superposition.
- **Fail-open volontaire** : si Supabase n'est pas configuré/joignable (`sbClient` null, ou erreur réseau lors de `getSession()`), `S.authOk` passe directement à `true` — l'app reste utilisable normalement en local. La saisie de match ne doit jamais dépendre de la disponibilité de Supabase, conformément au principe déjà posé par l'Architecture ("jamais bloquant, best-effort"). Ce n'est pas un contournement de sécurité : les données protégées sont sur Supabase, s'il est injoignable il n'y a de toute façon rien à synchroniser à ce moment-là.
- Démarrage de l'app changé : `checkAuthSession()` (async) remplace l'appel direct à `R()` — celle-ci appelle `R()` elle-même une fois la vérification de session terminée.
- Bouton "Se déconnecter" conditionné à `sbClient` (n'apparaît pas si Supabase n'est pas configuré, ce qui n'aurait aucun sens).
- Testé fonctionnellement via CDP : écran d'accès affiché sans session, mauvais mot de passe → erreur claire affichée, bascule vers l'app normale une fois authentifié (simulée), bouton de déconnexion fonctionnel (retour à l'écran d'accès). Vérifié visuellement sur iPad et iPhone portrait.
- **Non testable par mes soins** : connexion réussie avec les vrais identifiants, et persistance de session après fermeture complète de Safari sur iPad/iPhone (nécessite un vrai appareil et le vrai mot de passe, connu seulement de Romain). `supabase-js` persiste la session dans `localStorage` par défaut (comportement standard de la librairie, pas de configuration supplémentaire nécessaire) — mécanisme attendu pour fonctionner, mais le test réel sur device reste à faire par Romain avant de considérer ce critère définitivement validé.
