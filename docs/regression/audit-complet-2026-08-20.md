# Audit complet — FENIX Stats CF — 2026-08-20

*Regression Guardian + E2E Tester — `/verifie-complet`, hors cycle d'une story précise.*
*Environnement testé : production réelle — `https://romainternel.github.io/stat-terrain/`, vrai compte Supabase partagé (`romain.ternel@fenix-toulouse.fr`), identifiants fournis par Romain pour cette session.*
*Outil : Playwright MCP, navigateur réel, clics réels (pas de simulation). Captures dans `docs/regression/screenshots-audit-2026-08-20/`.*

## 1. Périmètre testé

Toutes les features **Critique** et **Important** de `docs/regression/checklist.md` (Secondaire exclu, conformément au périmètre par défaut). Sur ~60 lignes Critique/Important, la quasi-totalité a été revérifiée par clic réel ; le détail par ligne est au §2.

## 2. Résultat par feature

### ✅ Re-testées intégralement par clic réel (conformes)

| Feature | Preuve |
|---|---|
| Écran d'accès partagé (mauvais code → erreur claire, bon code → accès) | `01-login-mauvais-mdp.png` |
| Choix d'équipe -18/CF au premier lancement | `02-choix-equipe-premier-lancement.png` |
| Fondation Supabase (connexion réelle réussie) | login effectif, network 200 |
| Rosters par défaut FENIX CF (22, accents corrects) + Adversaire (7 postes) | `03-equipes-rosters-auto.png` |
| Navigation 5 onglets | multiples clics Équipes/Match/Stats/Bilan/Matchs |
| Stats (Comparaison/Gardiens/Joueurs/Analyse/PDF) sans match actif — pas de crash | `04-06` |
| Historique Matchs (liste réelle, 3 matchs) | `07-matchs-historique.png` |
| Bilan → Match / Analyse / PDF, sur un vrai match archivé (Rodez) | `08-09.png` |
| Raccourci PDF Bilan — texte de confirmation **quantifié exact** ("14 événement(s) non sauvegardé(s)") | capture dialog |
| Export PDF réel — téléchargement `.pdf` confirmé, 0 erreur console | `FENIX_J1_..._vs_Rodez.pdf` téléchargé |
| Écran de lancement dédié (`▶ Lancer le match`), jamais affiché sur un match chargé | `10-11.png` |
| Chrono auto-démarré + période=1 immédiat au lancement | `S.running/period` vérifiés |
| Mode Expert — BUT (terrain réel + 9 zones de but) | `14-15.png`, event GOAL avec x/y/goalZone réels |
| PB — tap terrain, coordonnées réelles, pas de zone de but | event TURNOVER x:50,y:50 |
| Jet franc — idem PB | event FREEKICK x:50,y:50 |
| PO → encart pénalty (tireur pré-désigné, BUT/ARRÊT/HC, zone d'impact réelle si Suivi GB actif) | `16.png`, event PEN_GOAL avec goalZone |
| 2min (sélecteur joueur dédié) | event TWO_MIN |
| Carton Rouge (sélecteur joueur dédié) | `17.png` (picker 2min), event RED |
| TM | event TM |
| Undo (↩ Annuler) — retire bien le dernier événement | vérifié avant/après |
| Mode Simple ↔ Expert — confirmation bloquante Expert→Simple, aucune confirmation Simple→Expert | dialogs capturés |
| **Mode Simple à équipe unique (STORY-65)** — un seul bloc, auto-validation, bascule possession | `19.png` |
| Alertes Mode Simple — "3 buts→TM conseillé", "4 buts→TM conseillé", "5 buts→Changez de GB !", + règle "3 attaques sans marquer" | `20.png`, `S.alertHistory` |
| Historique des alertes (plafond 3, collapse→pastille 🔔N) | `20.png` + vérif DOM |
| Mode lecteur — bandeau visuel + **blocage réel du clic** (pointer-events bloqués, 0 événement ajouté) | `21.png` |
| Rappel de mi-temps — badge `.due` pulsant à 30:00, reset après bascule MT1→MT2 | `22-23.png` + vérif classe DOM |
| Timeline GB — filtres MT1/MT2, "SÉRIE" et bannière "5 buts de suite ! Changez de GB" cohérents avec les vrais événements | `27-28.png` |
| Layout Match iPad paysage (1024×768) | `24.png` |
| Layout Match iPhone portrait (390×844) | `25.png` |
| Layout Match iPhone paysage (844×390) | `26.png` |
| Raccourcis en-tête Mode/Suivi GB — clic réel, icônes compactes sur iPhone | captures viewports |
| Deux équipes -18/CF — écran de choix, effectif -18 vide par défaut, **isolation réelle vérifiée** (joueur ajouté côté -18 absent du profil CF) | `29.png` + inspection `localStorage` |
| Suppression Supabase (`deleteSupabaseMatch`) | utilisé pour le nettoyage, 0 ligne restante vérifiée par requête directe |
| Synchronisation sortante temps réel | 10+ `POST /match_events` (201) + `POST /matches` (201) observés au réseau |
| Proposition de reprise de match (STORY-14) | match réel "Yoshi" trouvé et proposé au login (voir alerte §3) |

### ⚠️ Non re-vérifiées ce cycle (pas de régression suspectée — smoke-test uniquement, dernière vérif. récente conservée)

Mode hors-ligne PWA (aucun outil d'émulation offline dans le serveur Playwright MCP fourni — inchangé depuis les cycles précédents, toujours "jamais re-testé en conditions réelles sans réseau"), reprise de match à 2 appareils simultanés, rapatriement automatique de l'historique, sync entrante temps réel (2e canal), sauvegarde idempotente (évité volontairement pour ne pas dupliquer l'historique local de test), import CSV effectifs, export/import "Tout" l'historique, bascule points/zones terrain, détail joueur en modale, garde-fou volume Analyse, scroll préservé, bandeau de validation au lancement (non apparu car effectif+GB déjà correctement configurés), protection Stats→Gardiens contre les zones pénalty, disposition terrain à effectif variable (grille DC — déjà vérifiée le jour même par STORY-67/68).

### ⚠️ Ligne de checklist obsolète à corriger

**"Verrou de possession en Mode Simple" (STORY-59)** — ce critère décrit un bouton grisé par équipe quand elle n'a pas la possession. Depuis **STORY-65** (Mode Simple à équipe unique, le jour même), un seul bloc de boutons est affiché (celui de l'équipe en possession) : le scénario "cliquer sur le bouton de l'équipe sans possession" ne peut structurellement plus se produire. La checklist documente encore l'ancien mécanisme comme actif — à mettre à jour pour refléter que ce cas est devenu sans objet (déjà noté dans `docs/regression/checklist.md` à la ligne STORY-65 elle-même, mais la ligne STORY-59 n'a pas été mise à jour en conséquence).

## 3. Régressions / bugs détectés

### ❌ [MAJEUR] "📂 Charger" un match archivé écrase l'effectif CF actuel dans le stockage local

**Où** : `loadMatchAsCurrent()`, `app.js` (~ligne 1730-1764), utilisée par le bouton "📂 Charger" (écran Matchs) **et** le raccourci PDF de Bilan ("⚠️ Charger ce match & générer son PDF", STORY-36).

**Ce qui se passe** : la fonction remplace `S.home`/`S.away` par l'instantané des effectifs *tels qu'ils étaient au moment de ce match archivé précis*, puis appelle `saveTeams()` — qui **persiste cet instantané dans `localStorage` comme effectif courant** de l'équipe active, écrasant silencieusement l'effectif à jour.

**Reproduit en conditions réelles** : effectif FENIX CF chargé automatiquement à 22 joueurs (STORY-56) → clic sur "📂 Charger" un match archivé (Rodez) → effectif CF retombé à 13 joueurs (l'effectif qui avait joué ce match-là). Confirmé par lecture directe de `localStorage.hb2_teams_cf` avant/après.

**Impact réel** : un coach qui recharge un ancien match (pour le consulter, ou régénérer son PDF via le raccourci Bilan) voit son effectif *actuel* remplacé par l'effectif *de l'époque* de ce match — perte silencieuse de joueurs ajoutés depuis, de renommages, ou de sélections faites pour le match du jour. Le texte de confirmation affiché ("Le match en cours sera remplacé") ne mentionne jamais l'effectif, seulement les événements en cours — rien n'alerte le coach que son roster va aussi changer.

**Pourquoi ce n'est jamais remonté avant** : les cycles QA/E2E de STORY-14 et STORY-36 ont vérifié la restauration des événements/chrono/période et le correctif de sécurité P0 (coupure Realtime), mais jamais l'effet de bord sur `localStorage` des effectifs.

### ❌ [MAJEUR] Le bouton "🎯 PD" (passe décisive) reste actif après n'importe quel type d'événement, pas seulement après un but

**Où** : `app.js` — condition d'affichage du bouton (ligne 2247 : `S.mode==="expert"&&S.events.length>0&&!S.actionPanel`, sans vérifier `ACTIONS[ev.type]?.isGoal`) et `renderPdSelect()`/handler de clic (lignes 5110-5121, écrit `assistId`/`assistName` sur `S.events[0]` quel que soit son type).

**Reproduit en conditions réelles** : après un Carton Rouge sur Leni, le bouton "🎯 PD" était toujours cliquable → ouverture d'un sélecteur "Passe décisive — 🟥 Carton R de Leni — Qui a fait la passe ?" (capture `18.png`, avant annulation). Un clic sur un joueur y aurait attribué une "passe décisive" à un carton rouge.

**Impact** : ce bug touche la donnée "PD" dans **7+ sites d'agrégation distincts** (Stats→Comparaison, Stats→Joueurs, export PDF, Bilan→Analyse export texte, tous vérifiés dans le code) — tous filtrent uniquement sur `e.assistId` sans jamais vérifier `isGoal`. La corruption serait donc invisible en croisant Stats/PDF entre eux (tous auraient le même chiffre faux), et pourrait fausser durablement le comptage des passes décisives d'un joueur si un coach clique ce bouton par réflexe juste après une exclusion/un carton (positionné au même endroit que juste après un vrai but).

### ⚠️ Donnée résiduelle trouvée sur Supabase (pas un bug de code)

Un match "en cours" **FENIX Toulouse vs Yoshi** (0 événement, créé 2026-08-20 17:41) traîne sur le projet Supabase de production — proposé au login comme match reprenable. "Yoshi" n'est manifestement pas un vrai adversaire (déjà visible dans l'historique local comme 3e match sauvegardé, 0-0, 0 événement). Probablement un reliquat d'une session de test antérieure non nettoyée. Non supprimé par prudence (pas de certitude sur son origine) — à faire par Romain via le bouton 🗑 sur l'écran Matchs, ou à confirmer si le nettoyage automatique de fin de session a un trou.

### Divers mineurs (non bloquants)

- `<meta name="apple-mobile-web-app-capable">` signalé déprécié par Safari/Chrome (warning console) — `<meta name="mobile-web-app-capable">` recommandé en complément. Cosmétique, aucun impact fonctionnel observé.

## 4. Nettoyage effectué

- Match de test (id `69245e9a-...`) créé pour cette session : **jamais sauvegardé en local** (aucun clic sur "💾 Sauvegarder"), et **supprimé de Supabase** (`matches` + `match_events`) via `deleteSupabaseMatch()` — vérifié 0 ligne restante par requête directe.
- Joueur de test ("TestPrenom") ajouté au profil -18 pour vérifier l'isolation : supprimé immédiatement après vérification.
- Les 2 vrais matchs de Romain (Rodez ×2) et son effectif réel n'ont subi aucune modification volontaire — seul l'effet de bord du bug §3 a modifié l'effectif CF de **cette session de test locale** (navigateur Playwright, profil jetable, jamais synchronisé vers Supabase — les effectifs sont strictement locaux par appareil, donc **aucun impact sur les vrais appareils de Romain**).
- 0 erreur console inattendue sur l'intégralité de la session (~90 minutes de tests réels), à l'exception de l'unique tentative volontaire de mauvais mot de passe en tout début de session.

## 5. Verdict global

**RÉGRESSIONS DÉTECTÉES** :
1. [Majeur] "📂 Charger" un match archivé écrase l'effectif courant en local (`loadMatchAsCurrent()` + `saveTeams()`)
2. [Majeur] Le bouton "🎯 PD" permet d'attribuer une passe décisive à un événement non-but, corrompant la stat PD partout où elle est calculée

Aucune des deux n'est bloquante pour un usage immédiat (le premier bug ne se déclenche qu'en rechargeant un ancien match ; le second nécessite un clic malencontreux sur un bouton secondaire) — mais toutes deux méritent une story de correction avant la prochaine fois qu'un ancien match sera rechargé en vrai match, ou avant une saison complète d'usage du bouton PD.

Le reste du périmètre Critique + Important testé (~55 features) est conforme, y compris sous stress réel (workflow complet d'un match simulé, alertes automatiques déclenchées en vrai, 4 viewports différents, isolation -18/CF vérifiée en écriture réelle).
