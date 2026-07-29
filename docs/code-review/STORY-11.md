# Code Review — STORY-11 : Écran d'accès partagé

## Périmètre revu
- `config.js` : ajout `SUPABASE_AUTH_EMAIL`.
- `app.js` : `S.authOk`/`S.authError` dans `freshState()`, `checkAuthSession()`/`signInShared()`/`signOutShared()`, `renderAccessScreen()`, branchement dans `R()`, bouton déconnexion dans le panneau Réglages, binding dans `bind()`, démarrage change `R()` → `checkAuthSession()`.
- `style.css` : `.access-screen` et enfants.

## Conformité architecture
- Conforme à `docs/architecture-supabase.md` (email fixe dans `config.js`, un seul champ mot de passe, session persistée automatiquement par `supabase-js`) et à la maquette du Designer (`docs/design/acces-partage-et-reprise-match.md`, section 1) — un seul champ, un seul bouton, pas de champ email visible.
- Bonne décision d'architecture non explicitement prescrite mais cohérente avec l'esprit du projet : le **fail-open** quand Supabase est indisponible. J'ai vérifié que ça ne contourne pas la sécurité réelle (RLS reste la vraie barrière pour les données Supabase elles-mêmes) — ça évite seulement qu'une panne réseau transforme un simple outil de saisie locale en app totalement bloquée. Cohérent avec le principe déjà acté "la saisie ne doit jamais attendre Supabase".

## Conventions de code
- Cohérent avec le reste du fichier. Le early-return dans `R()` pour les deux nouveaux cas (`authOk===false`/`null`) est un peu plus de duplication de la logique clone/replaceChild que je n'aurais idéalement aimé (dupliquée 3 fois : accès refusé, en attente, cas normal) — **acceptable pour une story de taille S**, mais si un futur écran plein-écran similaire s'ajoute, factoriser ce pattern deviendrait rentable. Note, pas bloquant.

## Réutilisation vs duplication
- RAS sur le fond. `safeConfirm()` réutilisé pour la confirmation de déconnexion, cohérent avec le reste de l'app.

## Scope
- Diff contenu au périmètre de la story. Aucune touche à la logique de synchronisation (STORY-12/13) ou de reprise de match (STORY-14) — bien seulement l'écran de connexion.

## Gestion d'erreurs
- `signInShared`/`checkAuthSession`/`signOutShared` encapsulent leurs erreurs proprement (try/catch ou vérification `error` du retour Supabase), sans jamais laisser une exception non gérée bloquer le reste de l'app.

## Sécurité basique — signalé au Security Auditor
- Le message d'erreur ("Code d'accès incorrect.") ne distingue pas email/mot de passe — mais l'email n'étant ni visible ni modifiable dans l'UI, la question ne se pose pas vraiment ici (il n'y a qu'un seul champ, donc aucune fuite d'information possible sur lequel des deux est faux).
- Point à faire vérifier explicitement par le Security Auditor (story touchant l'authentification) : le fail-open ne doit jamais permettre un accès aux données Supabase elles-mêmes sans session valide — seulement à l'app locale. À confirmer que RLS (déjà vérifiée en STORY-10) empêche bien toute lecture/écriture Supabase pendant que `authOk=true` en mode fail-open (sans session réelle).

## Verdict
**APPROUVÉ**, sous réserve du passage du Security Auditor (obligatoire, story d'authentification).
