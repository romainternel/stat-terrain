# E2E — STORY-69 (corrections des 3 bugs Majeurs de l'audit du 2026-08-20)

## Contexte
Le QA a déjà testé les 3 correctifs par clics réels (`docs/qa/QA-69-corrections-audit-2026-08-20.md`, verdict PASSED) — inhabituel pour ce squad, mais nécessaire ici puisque le site de production n'a pas encore reçu le code corrigé (rien n'est déployé) : impossible de tester "sur le papier" un bug de timing réseau, donc le QA a directement utilisé Playwright contre le vrai backend Supabase via un serveur local. Cette passe E2E apporte un regard indépendant : nouvelle session, nouveau match, re-vérification du point le plus risqué (Fix 3) dans des conditions différentes, plus une découverte annexe sur le périmètre réel du Fix 2.

## Parcours testés (clics réels, session Playwright indépendante de celle du QA)
1. Lancement d'un nouveau match réel (roster réel sélectionné, clic sur "▶ Lancer le match")
2. BUT complet (joueur → terrain → zone) → vérification visuelle du bouton "🎯 PD"
3. Carton Rouge complet (joueur) → vérification visuelle de l'absence du bouton "🎯 PD"
4. "🆕 Nouveau match" avec réseau Supabase artificiellement ralenti à 3,5s (`window.fetch` patché) → mesure de la réactivité locale et de l'état final sur Supabase après résolution du réseau

## Résultat par parcours
- ✅ **Bouton PD après un but** : présent, capture `screenshots-E2E-69-2026-08-20/01-pd-present-apres-but.png`
- ✅ **Bouton PD après un carton rouge** : absent, capture `screenshots-E2E-69-2026-08-20/02-pd-absent-apres-carton.png` (comparaison directe des deux captures : seul le bouton "🎯 PD" a disparu de la barre du bas, tout le reste de l'interface identique)
- ✅ **"Nouveau match" avec réseau à 3,5s** : état local (`currentMatchId:null`, `journee` incrémenté, `view:"match"`) déjà entièrement à jour dès l'appel suivant — capture `03-reset-instantane-reseau-lent.png` prise pendant que la requête réseau tourne encore en arrière-plan
- ✅ **État final sur Supabase, 4,5s plus tard** : `status:'finished'`, `journee` correct (celui du match qui vient de se terminer, pas du suivant) — résultat identique au test du QA, reproduit une seconde fois de façon indépendante

## Découverte annexe (hors régression, pour information)
Le 2ᵉ site patché pour le Fix 2 (`renderGkSelect()`, app.js ~ligne 2494) s'est révélé **ne jamais être appelé nulle part dans le code** (`grep` confirmé) — code mort, dans la même famille que `renderMiniCompare()`/`renderGkBar()` déjà documentés comme tels dans `CLAUDE.md`. Le correctif qui y a été appliqué reste correct mais n'a aucun effet observable en pratique puisque la fonction n'est jamais rendue. N'affecte pas le verdict — le seul site réellement actif (`renderMatch()`, ~ligne 2260) est celui vérifié ci-dessus par clics réels.

## Écarts avec le verdict QA
Aucun. Les deux passes (QA et E2E), bien que toutes deux menées avec de vrais clics Playwright contre le vrai backend, ont été exécutées dans des sessions et des matchs de test totalement distincts et donnent des résultats identiques.

## Console navigateur
0 erreur sur l'ensemble de la passe.

## Nettoyage / impact production
Serveur local (`http-server`, `localhost:8811` servant les fichiers du dépôt tel quel) utilisé pour cette passe — **le site de production `romainternel.github.io/stat-terrain/` n'a reçu aucune requête d'écriture pendant cet E2E**, mais le backend Supabase, lui, est le même en local et en production (mêmes identifiants dans `config.js`). Le match de test créé (`12523ac6-...`) a été supprimé de Supabase après vérification de son état final — 0 ligne restante, vérifié par requête directe. Seuls les 2 vrais matchs de Romain (Rodez ×2) subsistent, confirmé par un dernier inventaire complet de la table `matches` (team_profile=cf).

## Verdict
**CONFIRMÉ** — aucun désaccord avec le QA. Les 3 correctifs se comportent identiquement à l'attendu sur deux passes indépendantes, y compris sous stress réseau simulé pour le fix le plus critique.
