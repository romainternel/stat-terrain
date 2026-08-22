# E2E — STORY-71 : confirmation et garde-fous au changement de mi-temps

*Produit par le E2E Tester — squad de contrôle BMAD*
*S'appuie sur `docs/qa/QA-71-confirmation-changement-mi-temps.md` (PASSED) et `docs/code-review/STORY-71.md` (réserve : distinction par le texte du message, pas les boutons)*

## Environnement de test
Même dispositif que STORY-70 : serveur statique Node local temporaire (port 8846) substituant un `config.js` factice en mémoire pour le fail-open documenté dans `CLAUDE.md`, **jamais** de modification du vrai `config.js` sur disque, aucun accès au vrai projet Supabase. Serveur arrêté en fin de session, vérifié.

## Parcours testés
1. Match lancé (Mode Expert), TM FENIX tagué à `rawTime=18` (00:18) pour disposer d'un point de restauration MT1 connu et distinguable, chrono relancé et laissé avancer au-delà (jusqu'à 00:40).
2. Clic "MT 1" → dialogue → **Annuler**.
3. Clic "MT 1" → dialogue → **Confirmer**.
4. Clic "MT 2" → dialogue → **Annuler**.
5. Clic "MT 2" → dialogue → **Confirmer**.
6. Bascule Mode Simple, clic "MT 1" → dialogue → **Confirmer** (spot-check de parité de mode, pas la matrice complète — le composant partagé était déjà établi lors de STORY-70).
7. Vérification console (0 erreur) sur l'ensemble de la session.

## Résultat par parcours
- ✅ **Parcours 2** (Annuler MT1→MT2) : `period` reste `1`, `running` reste `true`, le chrono continue d'avancer naturellement (40s au moment du clic annulé) — aucun effet de bord du clic annulé.
- ✅ **Parcours 3** (Confirmer MT1→MT2) : dialogue natif intercepté, **texte exact lu** : *"La mi-temps 1 est-elle terminée ?\n\nLe chrono va repasser à 0:00 et redémarrer automatiquement en mi-temps 2."* Après confirmation : bouton devient "MT 2", chrono à `00:04` **et déjà en cours d'exécution** (`▶`/`⏸ Stop` visible), `S.tmUsed` inchangé (`{mt1:1,mt2:0}`), toast "🧤 Pense à vérifier les gardiens pour la 2e mi-temps !" affiché **et** tracé dans le bandeau "🔔 Dernières alertes". Capture : `e2e-story71-mt2-confirmed-running-gk-alert.png`.
- ✅ **Parcours 4** (Annuler MT2→MT1) : dialogue lu — *"Revenir à la mi-temps 1 ?\n\nLe chrono va reprendre à 00:18 et rester en pause."* (le temps `00:18` correspond exactement au tag TM du parcours 1, calculé dynamiquement, pas un texte figé). Annulé : `period` reste `2`, `running` reste `true`, chrono continue d'avancer (31s) — aucun effet de bord.
- ✅ **Parcours 5** (Confirmer MT2→MT1) : même dialogue relu à l'identique. Après confirmation, **relu après 2s d'attente réelle** (pas seulement juste après le clic) : `S.time===18`, `S.running===false`, `S.period===1` — le chrono est réellement figé à la valeur annoncée dans le message, pas seulement affiché ainsi un instant. `S.tmUsed` toujours inchangé. Bandeau d'alertes toujours limité à 1 entrée (la GK du parcours 3) — **aucune alerte gardien déclenchée dans ce sens**, conforme au critère. Capture : `e2e-story71-mt1-restored-paused.png`.
- ✅ **Parcours 6** (Mode Simple) : bascule confirmée via un vrai `window.confirm()` (Expert→Simple, mécanisme préexistant), badge "⚡ MODE SIMPLE ACTIF" visible, bouton MT identique dans le même bloc scoreboard partagé. Clic "MT 1" → même dialogue exact, confirmé → `S.period===2`, `S.running===true`, `S.mode==="simple"` — comportement strictement identique au Mode Expert.
- ✅ **Parcours 7** : 0 erreur console sur l'ensemble de la session (7 interactions de dialogue, 2 modes, 1 bascule de mode).

## Vérification du point signalé par le Code Reviewer
Les deux dialogues, lus mot pour mot en conditions réelles (pas dans le code), sont sans ambiguïté dès la première phrase : l'un demande si la mi-temps 1 est *terminée* (ton prospectif), l'autre demande de *revenir* à la mi-temps 1 avec un horodatage précis affiché. Même sans distinction possible sur les boutons (contrainte native de `window.confirm()`, confirmée), la lecture du corps du message suffit à distinguer les deux sens sans confusion possible dans ce test. Risque #1 considéré comme correctement mitigé par le texte du message.

## Écarts avec le verdict QA
Aucun.

## Verdict
**CONFIRMÉ**

Les 5 comportements critiques (confirmation bloquante dans les deux sens, reset+redémarrage auto MT1→MT2, restauration au dernier tag+pause MT2→MT1, alerte gardien uniquement à l'aller, compteur TM préservé) fonctionnent tous en conditions réelles, dans les deux modes de saisie, avec des valeurs de chrono vérifiées précisément (pas seulement "un nombre a changé").
