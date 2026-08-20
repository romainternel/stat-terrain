# E2E — STORY-55 à STORY-61 (rosters par défaut, scroll, boutons manuels)

## Contexte
Premier passage E2E réel pour ce cycle : lors du précédent `/verifie` (2026-08-18), le serveur MCP Playwright n'était pas disponible et l'étape avait été sautée explicitement. Il est désormais connecté — ce rapport confirme (ou infirme) en conditions réelles de navigateur ce que le QA avait déjà validé sur le papier (`docs/qa/QA-55-61-cycle-rosters-tag-terrain-possession.md`, PASSED).

## Environnement de test
- App servie localement (`npx serve`, `http://localhost:8532/`) à partir des fichiers du dépôt (`app.js`/`style.css`/`index.html`/`config.js` inchangés depuis le commit `63e7b92`, aucune divergence avec la prod GitHub Pages)
- **Vrai backend Supabase de production** (même projet qu'en conditions réelles) — connexion avec le mot de passe partagé réel, fourni explicitement par Romain pour ce passage
- Navigateur piloté par Playwright MCP (Chromium), viewport paysage 1024×700/768 pour reproduire les conditions du bug STORY-57

## Décision de périmètre (validée avec Romain avant exécution)
Aucun match n'a été lancé (`▶ Lancer le match` jamais cliqué) : l'app en production n'a pas d'environnement de test séparé, et lancer un match crée réellement une ligne `matches`/`match_events` synchronisée en temps réel vers les autres appareils connectés (dont celui de Romain). Tous les parcours testés ici se limitent à l'onglet Équipes et à l'écran de lancement (avant clic), qui n'écrivent jamais vers Supabase tant qu'aucun match n'est actif (confirmé par le Code Review : les boutons STORY-61 n'appellent pas `upsertMatchSnapshot()`).
**Conséquence** : STORY-58 (tag terrain PB/Jet franc), STORY-59 (verrou de possession Mode Simple) et le sous-cas "5 buts consécutifs → alerte GB" de STORY-60 nécessitent un match actif — non couverts par ce passage E2E, comme lors du cycle précédent. Ils restent couverts par le QA (vraies interactions CDP, PASSED) et le Regression Guardian (v109, RAS) sur la base de leur propre méthode, non par un vrai navigateur Playwright cette fois-ci non plus.

## Parcours testés

### STORY-56 — Effectif FENIX CF réel chargé automatiquement
✅ Connexion réelle (mot de passe partagé) → choix profil "CF" (premier lancement) → 22 joueurs FENIX CF affichés, noms réels accentués corrects (Isaac.M, Hailé.G, Siméo.R, Mattéo.A... — encodage confirmé sans mojibake), tous non sélectionnés, aucun GB assigné. Capture : `screenshots/e2e-01-equipes-rosters-defaut.png`.

### STORY-55 — Effectif adversaire par défaut
✅ Même écran : 7 postes (GB/ALG/ARG/DC/PVT/ARD/ALD) déjà présents et **présélectionnés** (✓), conforme à la différence volontaire documentée avec FENIX CF (import CSV vs modèle prêt à l'emploi).

### STORY-61 — Bouton "⚡ FENIX CF"
✅ Renommage manuel du premier joueur (Isaac.M → "TEST-RENAME-E2E", via le prompt navigateur réel, accepté) → clic sur "⚡ FENIX CF" → confirmation → alerte "22 joueurs FENIX CF chargés !" → effectif revenu à l'état officiel, "TEST-RENAME-E2E" disparu, "Isaac.M" de retour. Écrase bien un état modifié, pas seulement un état vide.

### STORY-61 (addendum) — Bouton "⚡ Modèle" (Adversaire)
✅ Nom d'équipe modifié ("Adversaire" → "Ivry E2E") + renommage d'un joueur (ALG → "RENAME-ADV-E2E") → clic "⚡ Modèle" → confirmation → alerte "7 postes adversaire chargés !" → effectif revenu aux 7 postes génériques (ALG de retour), **mais "Ivry E2E" préservé** — confirme que `S.away.name` n'est jamais touché par ce bouton, exactement comme documenté.

### STORY-57 — Scroll préservé après sélection en paysage
✅ Viewport 1024×700, confirmé par lecture directe du DOM que `#app{overflow-y:auto}` et `body{overflow:hidden}` (le vrai conteneur de scroll dans ce mode, pas `window`). `#app.scrollTop` positionné à 1096px (bas de la liste des 22 joueurs FENIX CF) → clic réel (`dispatchEvent(MouseEvent)`, sans passer par l'auto-scroll-into-view de Playwright qui aurait faussé le test) sur le dernier joueur (Enzo.D) → sélection bien appliquée (`class="sel-toggle on"`, re-rendu confirmé) → **`#app.scrollTop` toujours à 1096px après le re-rendu**. Pas de régression du bug d'origine (avant le fix, retombait à 0).

### STORY-60 — Rappel GB (sous-cas "banner visible")
✅ Retour à l'onglet Match (aucun match actif) → écran de lancement dédié (STORY-54) affiché avec bandeau "⚠️ À vérifier avant de commencer" → "GB non sélectionné pour FENIX Toulouse" bien présent, alors qu'un joueur est sélectionné (Enzo.D) sans être marqué GB actif — confirme que `hasValidGk()` vérifie la sélection réelle, pas seulement la présence d'un `gkId`. Capture : `screenshots/e2e-02-rappel-gb-banniere.png`.
⚠️ Non testé ici : la disparition du bandeau une fois un GB réellement assigné — l'assignation se fait via le sélecteur `[data-gk-sel]` du scoreboard, uniquement accessible en match actif (hors périmètre de ce passage). Déjà couvert par le QA (CDP).

## Écarts avec le verdict QA
Aucun. Tous les parcours testables dans ce périmètre (sans match actif) se comportent exactement comme le QA les avait décrits — aucune divergence entre le raisonnement/CDP du QA et un vrai navigateur Playwright piloté en conditions réelles (vrai login, vrai Supabase).

## Console navigateur
0 erreur sur l'ensemble de la session (1 seul avertissement bénin, non lié à cette story : dépréciation de la meta `apple-mobile-web-app-capable`, préexistante).

## Nettoyage / impact production
Aucune écriture vers Supabase (`matches`/`match_events`) — vérifié par construction (aucun match lancé) et cohérent avec l'architecture (rosters = `localStorage` uniquement tant qu'aucun match n'est actif). Une lecture Supabase a eu lieu (`syncArchivedMatchesIntoLocal()`, STORY-48, déclenchée à l'ouverture) — read-only, aucun match distant rapatrié pendant ce passage (pas de toast récapitulatif affiché). Les renommages de test (joueurs/équipe) n'existent que dans le `localStorage` du navigateur Playwright éphémère, jamais synchronisés.

## Verdict
**CONFIRMÉ** (dans le périmètre testé) — aucun désaccord avec le QA, aucune régression constatée en conditions réelles de navigateur. Le périmètre non couvert (STORY-58/59/60-alerte, qui nécessitent un match actif) reste une limite assumée de ce passage, pas un échec — cohérent avec la décision prise avec Romain avant exécution pour ne pas polluer les données de production.
