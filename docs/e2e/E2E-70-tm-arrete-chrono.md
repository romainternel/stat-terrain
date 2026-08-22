# E2E — STORY-70 : le temps mort arrête le chrono

*Produit par le E2E Tester — squad de contrôle BMAD*
*S'appuie sur `docs/qa/QA-70-tm-arrete-chrono.md` (PASSED)*

## Environnement de test
Serveur MCP Playwright disponible et utilisé. App servie en local (serveur statique Node temporaire, port 8845) plutôt qu'en `file://` pour un comportement réseau/service worker correct. **`config.js` n'a jamais été modifié sur disque** : le serveur local substitue un `config.js` factice (`SUPABASE_URL`/`ANON_KEY`/`AUTH_EMAIL` à `undefined`) uniquement pour la requête HTTP, afin de déclencher le mode fail-open déjà documenté dans `CLAUDE.md` ("si Supabase est indisponible/non configuré, `S.authOk` passe à `true` automatiquement") — pas d'accès ni de tentative sur le vrai projet Supabase de production, aucune donnée réelle touchée. Serveur de test arrêté en fin de session.

## Parcours testés
1. Écran d'accès → fail-open confirmé (pas d'écran mot de passe bloquant avec `config.js` factice) → choix profil "CF" → onglet Match → "▶ Lancer le match" (Mode Expert par défaut) → chrono démarré automatiquement.
2. Clic "⏸ TM" côté FENIX (Mode Expert) pendant que le chrono tourne.
3. Redémarrage manuel (▶ Start), puis clic "⏸ TM" côté Adversaire (Mode Expert).
4. Bascule vers Mode Simple (raccourci en-tête, confirmation `window.confirm()` acceptée), redémarrage manuel, clic "⏸ TM" côté FENIX en Mode Simple.
5. Vérification console (0 erreur).

## Résultat par parcours
- ✅ **Parcours 2** : avant clic, chrono à `00:15`→tourne, bouton `⏸ Stop` affiché. Après clic sur "⏸ TM" : bouton devient `▶ Start`, chrono affiche `00:09` et **reste figé à `00:09` après 3s d'attente réelle** (`document.getElementById('tmr').textContent` relu après un délai, pas seulement l'état du bouton) — le chrono est réellement arrêté, pas juste visuellement. Capture : `e2e-story70-tm-fenix-paused-expert.png`.
- ✅ **Parcours 3** (TM Adversaire) : chrono relancé à `00:15`, tourne jusqu'à `00:20`. Clic "⏸ TM" côté Adversaire → bouton `▶ Start`, chrono figé à `00:20`. Confirme que le correctif s'applique bien indépendamment de l'équipe, pas seulement à FENIX — c'était l'un des critères d'acceptation explicites de la story.
- ✅ **Parcours 4** (Mode Simple) : bascule de mode confirmée via un vrai dialogue `window.confirm()` intercepté et accepté (comportement natif du navigateur observé directement, pas simulé). Bloc scoreboard/timer/TM identique à l'Expert (même composant partagé, cf. note QA). Chrono relancé à `00:26`, tourne jusqu'à `00:30`. Clic "⏸ TM" → `▶ Start`, chrono figé à `00:30`, confirmé après 3s + un aller-retour de snapshot supplémentaire.
- ✅ **Parcours 5** : `browser_console_messages` (niveau warning) → 0 erreur. Seul message : un avertissement de dépréciation sur une balise `<meta apple-mobile-web-app-capable>`, préexistant et sans lien avec cette story.

## Écarts avec le verdict QA
Aucun. Les trois scénarios critiques identifiés par le QA (FENIX/Expert, Adversaire/Expert, FENIX/Simple) se comportent exactement comme prévu en conditions réelles de clic dans un vrai navigateur.

## Verdict
**CONFIRMÉ**

Le correctif fonctionne réellement, dans les deux équipes et les deux modes de saisie, avec vérification explicite que le chrono ne redémarre pas silencieusement (attente réelle + relecture du DOM, pas seulement lecture de l'état du bouton juste après le clic).
