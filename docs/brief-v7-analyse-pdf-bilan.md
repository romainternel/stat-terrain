# Brief — Analyse & PDF accessibles depuis Bilan

## Contexte

Romain (responsable du centre de formation, seul utilisateur de l'app) a vu une capture d'écran de l'onglet Stats → Analyse et a réagi spontanément : « Analyse et PDF ne devraient pas être dans Bilan ? Une fois qu'on a enregistré le match ? »

Le constat qu'il fait est juste sur le fond : `Analyse` (auto-détection de patterns + notes coach + export texte) et `PDF` (rapport complet) sont conceptuellement des outils **d'après-match**, pas des outils de suivi en direct — contrairement à `Comparaison`, `Gardiens` et `Joueurs`, qui ont un vrai intérêt pendant que le match se déroule (ajuster la tactique, changer de GB, etc.). `Bilan` est déjà, dans l'app, l'écran dédié à la relecture a posteriori d'un match précis (`renderBilanMatch()`, sélecteur de match dans l'historique) et à l'agrégation saison (`renderBilanSaison()`).

Mais un déplacement pur et simple casserait un usage qui fonctionne déjà : consulter Analyse/PDF juste après avoir arrêté la saisie, pendant que le match est encore l'état actif (`S`), avant même de cliquer sur "Sauvegarder le match". C'est pourquoi la proposition retenue avec Romain (réponse "ok") est un **entre-deux** : garder Analyse/PDF dans Stats comme aujourd'hui, ET les rendre aussi accessibles depuis Bilan une fois un match sélectionné dans l'historique.

Ce Brief ne rouvre pas ce choix produit (déjà validé) — il sert à cadrer précisément ce qu'implique techniquement de rendre ces deux onglets disponibles depuis Bilan, et à isoler les questions qui doivent être tranchées avant le PRD.

## Problème

**Ce que Romain ne peut pas faire aujourd'hui** : consulter l'analyse automatique, ses notes de coach, ou générer un PDF pour un match **qui n'est pas le match actuellement chargé dans l'état live (`S`)** — sans passer par une manipulation destructive.

Concrètement, dans le code (`app.js`) :
- `renderAnalyse()` (~L2674) appelle `autoAnalysis()` (~L2540), qui calcule ses insights exclusivement via `teamScore()`, `teamStat()`, `teamPoss()`, `periodScore()` (L1007-1015, L1890-1893) et un parcours direct de `S.events` — toutes ces fonctions lisent **uniquement** l'état global `S`, jamais un objet de match arbitraire.
- `generatePDF()` (~L4025-4429, ~400 lignes) est bâtie sur le même principe : elle lit `S.season`, `S.journee`, `S.home`, `S.away`, `S.events`, `S.coachNotes`, et rappelle les mêmes helpers `teamScore`/`teamStat`/`periodScore`/`gkStats` — aucun paramètre de match n'est accepté nulle part dans cette fonction.
- Les notes coach suivent le même schéma : la textarea de `renderAnalyse()` lit/écrit `S.coachNotes` en direct (`cnEl.oninput=()=>{S.coachNotes=cnEl.value;}`, L3640) — jamais un match chargé.

Résultat : dès qu'un nouveau match démarre (`newMatch()`, L1394) ou qu'un autre match est chargé (`data-load-match`, L3901-3924 — qui **remplace** intégralement l'état live après confirmation « Le match en cours sera remplacé »), l'Analyse/le PDF/les notes du match précédent deviennent inaccessibles sans écraser le match en cours. Aujourd'hui, `Bilan` offre déjà une consultation sûre et non destructive de l'historique (`S.bilanMatch`, chargé en lecture seule via le sélecteur `renderBilanMatch()`, L3135) — mais cette vue s'arrête au comparatif chiffré, aux top scoreurs et au fil d'événements : aucune analyse auto, aucune note, aucun PDF n'y sont proposés.

**Le vrai besoin de Romain n'est donc pas seulement "changer d'écran"** — c'est pouvoir revenir, à froid, sur l'analyse et ses notes d'un match déjà joué (le lendemain, avant le match suivant, en préparation de saison), sans avoir à rejouer une manipulation risquée sur l'état live. Le pire résultat si mal fait : une consultation qui a l'air de fonctionner mais affiche silencieusement les données du match en cours plutôt que celles du match sélectionné dans Bilan (confusion dangereuse — un coach qui croit lire l'analyse du match n°8 alors qu'il voit celle du match en cours).

**Bonne nouvelle déjà vérifiée dans le code** : il existe un précédent architectural exact pour ce type de dualité. `matchStats(m)` (~L3109-3133) recalcule volontairement, à partir d'un objet de match **sauvegardé** `m.events`, les mêmes agrégats (buts, tirs, efficacité, PB, PD, pénaltys...) que ceux que `teamScore`/`teamStat` calculent pour le match en cours — mais via son propre code, sans réutiliser ces helpers. C'est ce pattern ("mêmes stats, calculées soit depuis `S` en live, soit depuis un objet `m` sauvegardé, via deux chemins de calcul séparés plutôt qu'un paramètre partagé") qui a déjà permis à `renderBilanMatch()` d'exister. Il n'a en revanche jamais été appliqué à `autoAnalysis()` ni à `generatePDF()`.

## Utilisateurs

Un seul utilisateur : **Romain**. Mais le contexte d'usage est different de celui de la saisie live (cf. brief-v6, saisie pendant le match, urgence de quelques secondes) : ici, c'est une **consultation a posteriori**, sans contrainte de temps — probablement pas debout en bord de terrain mais assis, éventuellement bien après le match (préparation de la semaine suivante, bilan de saison, partage du PDF avec le staff/les joueurs). L'appareil n'est donc pas nécessairement l'iPad de bord de terrain ; ça peut l'être, mais la contrainte "gros boutons, pas d'ambiguïté au clic" est moins critique ici que pendant la saisie.

Point important : l'usage ne concerne pas seulement "le match qu'on vient de finir" — Bilan permet déjà de naviguer dans **tout l'historique** via son sélecteur. Le besoin réel couvre donc aussi bien le dernier match que ceux d'il y a plusieurs semaines, ce qui confirme que la solution ne peut pas se limiter à "afficher Analyse/PDF juste après avoir cliqué Sauvegarder" (ça ne couvrirait que le match du jour) — il faut bien un chemin par le sélecteur d'historique de Bilan.

## Vision

Permettre à Romain de retrouver, dans Bilan, l'analyse automatique, ses notes de coach et l'export PDF de **n'importe quel match sauvegardé** qu'il sélectionne dans l'historique — sans jamais toucher ni risquer d'écraser le match en cours — en plus de la consultation déjà possible dans Stats pour le match actif.

## Scope

**Dedans (a priori, à confirmer par le PM) :**
- Ajout de deux onglets (`🧠 Analyse`, `📄 PDF`) dans la barre `S.bilanTab` de Bilan (aujourd'hui limitée à `🔍 Match` / `🏆 Saison`, L3526-3531), visibles/actifs uniquement quand un match est sélectionné (`S.bilanMatch` non nul) — cohérent avec le comportement déjà en place de `renderBilanMatch()` qui affiche « ↑ Sélectionne un match pour le revoir » tant qu'aucun match n'est choisi.
- Généralisation d'`autoAnalysis()` pour qu'elle puisse produire ses insights soit depuis le match en cours (`S`), soit depuis un match chargé (`S.bilanMatch`) — en s'appuyant sur le pattern déjà établi par `matchStats(m)` plutôt qu'en réinventant un mécanisme.
- Généralisation de `generatePDF()` selon le même principe, pour générer le rapport d'un match sauvegardé plutôt que du match en cours.
- Persistance réelle des notes coach pour un match sauvegardé consulté depuis Bilan (aujourd'hui, `m.coachNotes` existe bien à la sauvegarde — voir Questions en suspens — mais rien ne permet de le relire ni de le ré-écrire depuis Bilan).
- Rester dans Stats : Analyse/PDF pour le match en cours ne changent pas de comportement (décision déjà actée avec Romain, pas un déplacement).

**Dehors (a priori) :**
- Toute refonte visuelle des onglets Stats existants (hors du strict nécessaire pour partager le rendu avec Bilan).
- Le comparatif déjà affiché dans `renderBilanMatch()` (buts, tirs, PD, joueurs, fil du match) — déjà fonctionnel, non concerné.
- Analyse automatique ou PDF **au niveau saison** (agrégé sur plusieurs matchs) — ce Brief ne couvre que l'analyse/le PDF **par match**, cohérent avec le fonctionnement actuel de `autoAnalysis()`/`generatePDF()` qui sont déjà pensées match par match.
- Rattrapage des matchs sauvegardés qui n'auraient pas de champ `coachNotes` (matchs très anciens) — traité en `||""` comme c'est déjà fait ailleurs dans le code (ex. L3912), pas de migration prévue.
- Toute garantie de synchronisation multi-appareil des notes éditées sur un match déjà terminé (un match "finished" n'est plus poussé en continu vers Supabase comme l'est le match en cours via `upsertMatchSnapshot()`) — à traiter comme question ouverte, pas comme scope acquis.

## Critères de succès

- Depuis Bilan, après avoir sélectionné un match dans l'historique, Romain voit une analyse automatique et peut générer un PDF qui correspondent **exactement** à ce match sélectionné (jamais au match en cours), y compris quand un match est activement en cours de saisie en parallèle sur un autre appareil.
- Les notes de coach lues/éditées depuis Bilan sont bien celles du match sélectionné, distinctes de celles d'un autre match et du match en cours — et elles survivent à un rechargement de la page.
- Aucune régression sur Stats → Analyse/PDF pour le match en cours (comportement actuel préservé à l'identique).
- Romain confirme, à l'usage réel, qu'il peut consulter/partager l'analyse et le PDF d'un match passé sans avoir besoin de le "charger" comme match en cours (donc sans le risque de devoir confirmer l'écrasement du match actif).

## Questions en suspens

- **Les notes coach d'un match sauvegardé sont-elles déjà stockées par match ?** Oui, en partie : `saveMatch()` (~L1342-1362) écrit bien `coachNotes:S.coachNotes||""` dans l'objet du match au moment de la sauvegarde (~L1352) — ce n'est donc pas une valeur perdue ou partagée entre matchs comme le laissait supposer l'hypothèse initiale. Mais c'est un **instantané pris une seule fois, à la sauvegarde**. Aujourd'hui, `m.coachNotes` n'est relu dans `S.coachNotes` que dans le flux "Charger" de l'historique (`data-load-match`, L3912), qui **remplace** le match en cours — jamais dans le flux de consultation Bilan (`S.bilanMatch`), qui ne touche `coachNotes` nulle part. Le PM doit trancher : le champ notes affiché dans le nouvel onglet Analyse de Bilan doit-il être éditable, et si oui, où écrit-il ? Un mécanisme existe déjà et est directement réutilisable : `dbSaveMatch()` (L448-456) fait un `put()` IndexedDB keyé sur `match.id` — rappeler `dbSaveMatch(m)` avec un `m.coachNotes` mis à jour suffirait techniquement à persister l'édition sur le bon match, sans toucher à `S`.
- **Le bouton "Sauvegarder notes" actuel ne sauvegarde rien de lui-même** : dans Stats aujourd'hui, la frappe écrit déjà en continu dans `S.coachNotes` (`oninput`, L3640) ; le bouton (L3641-3642) ne fait qu'afficher un toast de confirmation — la persistance réelle sur disque n'arrive que plus tard, quand Romain clique le vrai bouton "Sauvegarder le match" (`saveMatch()`). Pour un match déjà sauvegardé consulté depuis Bilan, il n'existe **aucun** point de sauvegarde globale équivalent qui se déclencherait "plus tard" — le PM doit donc décider si, dans ce contexte précis, le bouton doit devenir un vrai déclencheur d'écriture (`dbSaveMatch(m)` immédiat) plutôt qu'un simple toast cosmétique.
- **Généralisation littérale vs "jumeau" à la `matchStats(m)`** : `autoAnalysis()` et surtout `generatePDF()` (~400 lignes, dessin du terrain et de la zone de but inclus) reposent sur une chaîne d'helpers (`teamScore`, `teamStat`, `teamPoss`, `periodScore`, `countType`, `gkStats`) qui ne lisent QUE `S`. Généraliser "proprement" (ajouter un paramètre `match` et le faire descendre partout) toucherait donc bien plus de fonctions que les trois nommées dans la demande initiale (autoAnalysis, notes, PDF). L'alternative, cohérente avec le seul précédent existant (`matchStats(m)`, qui duplique son propre calcul plutôt que de réutiliser `teamScore`/`teamStat`), est d'écrire des versions "jumelles" scoped-sur-un-match de `autoAnalysis()` et `generatePDF()` — au prix d'une duplication de logique déjà acceptée ailleurs dans ce projet. C'est un arbitrage pour l'Architect, mais il doit être fait consciemment : ce n'est pas un simple ajout de paramètre.
- **Point positif déjà vérifié, à ne pas re-questionner** : l'identité du gardien actif (`S.home.gkId`/`S.away.gkId`, utilisée par `generatePDF()` pour dessiner la zone de but) est déjà correctement conservée dans les matchs sauvegardés (`saveMatch()` fait `home:{...S.home,...}`, donc `m.home.gkId`/`m.away.gkId` existent) — ce sous-bloc du PDF n'a donc pas de trou de données à combler, juste à être rebranché sur `m` plutôt que `S`.
- **Synchronisation Supabase des notes éditées a posteriori** : un match marqué `finished` n'est plus poussé en continu vers Supabase comme l'est le match en cours (`upsertMatchSnapshot()`). Si Romain édite des notes sur un vieux match depuis un appareil, doivent-elles rester purement locales à cet appareil (cohérent avec l'usage actuel, un seul utilisateur réel) ou faut-il un mécanisme de mise à jour explicite côté Supabase ? Cette question dépasse ce Brief mais doit être signalée à l'Architect avant de trancher le mécanisme de sauvegarde des notes.
