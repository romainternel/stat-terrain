# PRD v3 — Terrain et affichage des joueurs

*Produit par le Product Manager — squad build BMAD*
*S'appuie sur `docs/brief-v3-terrain-joueurs.md`*

## 1. Objectif

Faire en sorte que le terrain affiché en match (et sur les cartes de tir Stats) inspire confiance visuellement et n'affiche jamais que ce que Romain a explicitement choisi.

## 2. Features

### F10 — Refonte visuelle du terrain
Remplacer ou retravailler `COURT_IMG` (image raster générique, actuellement partagée entre `.court-pick` en Match et les SVG de tir en Stats) par un rendu cohérent avec la charte graphique de l'app (dark theme, couleurs FENIX). Décision technique du type de rendu (SVG vectoriel dessiné à la main, ou image retravaillée) laissée au Designer/Visual Crafter/Architect.

### F11 — Terrain vide si aucune sélection
Corriger le comportement de repli `if(roster.length===0) roster = S[team].players` dans les 3 fonctions concernées (`renderMatchPanel`, `renderPdSelect`, `renderPlayerSelect`) : plus aucun joueur ne doit apparaître sur le terrain tant que Romain n'a pas explicitement sélectionné son effectif pour le match. Un message d'état vide explicite plutôt qu'un silence total (à préciser par le Designer).

### F13 — Numéro de maillot manquant
Revoir l'affichage `dn(p)` ("?" actuellement) pour un joueur sans numéro, sans perdre le repère existant "cliquer pour modifier" (`renderTeamSetup` utilise déjà un "?" comme nom de joueur non renseigné, avec un ✏️ à côté — à ne pas confondre avec le "?" de `dn()` qui concerne le numéro sur le terrain, contexte différent).

## 3. Priorités

| Feature | Priorité | Justification |
|---|---|---|
| F11 — Terrain vide si aucune sélection | **Must Have** | Bug de comportement explicitement signalé par Romain, cause confusion réelle en usage. |
| F13 — Numéro manquant | **Must Have** | Signalé explicitement, petit correctif ciblé. |
| F10 — Refonte visuelle du terrain | **Must Have** | Demande explicite ("pas très joli"), mais plus gros chantier — à ne pas bâcler, le Designer/Visual Crafter doivent proposer un vrai traitement avant de coder. |

## 4. Critères d'acceptation

**F10**
- [ ] Le terrain (Match et Stats) a un rendu visuellement cohérent avec le reste de l'app — validé par Romain après livraison.
- [ ] Les lignes réglementaires (zone 6m, ligne 9m, point de penalty 7m, ligne des 4m) restent toutes présentes et correctes (pas de perte d'information réglementaire en simplifiant le visuel).

**F11**
- [ ] Terrain vide (Match, sélection PD, sélection 2min/carton) tant qu'aucun joueur n'est sélectionné pour l'équipe concernée.
- [ ] Un état vide explicite informe Romain quoi faire (aller sélectionner son effectif), plutôt qu'un vide silencieux qui ressemble à un bug.

**F13**
- [ ] Un joueur sans numéro affiche quelque chose de clair sur le terrain (pas un "?" qui laisse penser à un bug), distinct du marqueur d'édition existant sur l'écran Équipes.

## 5. Hors scope

- Le système de sélection de roster lui-même (case à cocher "selected" par match) — reste inchangé.
- Toute nouvelle fonctionnalité de gestion d'équipe/joueur.

## 6. Dépendances

- F10 dépend des décisions du Designer/Visual Crafter (maquette + spec visuelle) avant tout développement.
- F11 et F13 sont indépendantes de F10, peuvent être livrées en premier (bugs de comportement, correctifs rapides).

## 7. Risques

Voir `docs/risks/terrain-joueurs.md` (Risk Analyst) — notamment l'impact de F11 sur les 3 emplacements identifiés (cohérence à vérifier partout) et l'impact de F10 sur l'écran Stats (image partagée).
