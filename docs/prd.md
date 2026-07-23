# PRD — FENIX Stats : iPhone + polish visuel

*Produit par le Product Manager — squad build BMAD*
*S'appuie sur `docs/brief.md`*

## 1. Objectif

Faire de FENIX Stats une app utilisable **au même niveau de rapidité et de confort sur iPhone que sur iPad**, tout en portant le rendu visuel — déjà bien engagé (Inter, thème possession, glow) — à un niveau "premium" cohérent sur tous les écrans. Sans changer la stack, sans dépendance à un autre projet CF.

**Hypothèse retenue** (à confirmer par Romain) : iPhone et iPad sont traités comme deux cibles de **même priorité**, pas iPad = référence / iPhone = secours. Si cette hypothèse est fausse, F1 peut être redimensionnée en "Should Have" plutôt que "Must Have".

## 2. Features

### F1 — Layout Match responsive iPhone
Le layout actuel (`match-layout`, grille `240px 1fr`) est conçu pour un espace large (iPad, desktop). Sur un iPhone en portrait (≤430px de large), la colonne gauche fixe et la barre d'actions horizontale (`ml-actions` avec 5-6 `act-h`) risquent de se tasser ou de dépasser.
- Définir un vrai breakpoint "mobile étroit" (pas juste le `max-width:700px` déjà présent en display, qui ne touche que `setup-grid`/`stat-courts`) pour `.match-layout`.
- Réorganiser en priorité verticale : score + timer toujours visibles, barre d'actions accessible sans scroll, terrain scrollable en dessous.
- Vérifier que chaque zone tactile (boutons d'action, joueurs sur le terrain, zones de but) respecte une taille minimale tactile confortable (~44px) même sur petit écran.

### F2 — Passe de polish visuel (continuité du chantier engagé)
L'app a déjà un thème dark cohérent et un système de possession (accent color dynamique). Cette feature consolide et étend ce travail plutôt que de le refaire :
- Audit des ombres/glow existants pour cohérence (actuellement seulement sur certains éléments : `.ml-team-active`, `.mlt-poss-btn`, `.ml-court .court-pick`).
- Micro-animations manquantes sur les écrans hors-match (Stats, Bilan, Setup) qui n'ont pas reçu le même traitement que l'écran Match.
- Cohérence des états interactifs (hover/active/disabled) sur tous les boutons, pas seulement ceux du match.

### F3 — Filet de sécurité data (export/backup visible)
Les matchs sont stockés uniquement en local (IndexedDB) sur l'appareil utilisé. `exportAllMatches()` existe déjà mais n'est pas mis en avant.
- Rendre le bouton d'export/backup plus visible (ex : rappel discret après sauvegarde d'un match, ou dans l'onglet Bilan).
- Pas de cloud : rester sur export manuel (fichier), cohérent avec la contrainte "indépendant, pas de backend".

### F4 — Audit des frictions du workflow de saisie
Le workflow (sélection action → équipe → joueur → terrain → zone de but → validation) a connu plusieurs correctifs récents (terrain requis, flow 2 étapes strict). Avant d'ajouter du visuel, vérifier qu'il ne reste pas de frictions connues côté usage réel (ex : cas où l'auto-validation surprend, cas PD après but).
- Cette feature est une **investigation** avant tout : elle peut ne déboucher sur aucune story si rien n'est trouvé.

### F5 — Polish de l'expérience PWA (installation)
Vérifier l'expérience "ajouter à l'écran d'accueil" sur iPhone (icône, splash screen, nom affiché) — actuellement pensée pour iPad (`apple-mobile-web-app-title`, `manifest.json`).

## 3. Priorités

| Feature | Priorité | Justification |
|---|---|---|
| F1 — Responsive iPhone | **Must Have** | C'est la demande explicite de Romain ("iPhone ou iPad") — sans ça, l'app ne répond pas au besoin. |
| F2 — Polish visuel | **Must Have** | Demande explicite "graphiquement cool" ; continuité directe d'un chantier déjà commencé. |
| F3 — Filet de sécurité data | **Should Have** | Risque réel (perte de données) mais pas bloquant pour l'usage immédiat. |
| F4 — Audit frictions saisie | **Should Have** | Améliore la fiabilité en match, mais l'essentiel du workflow fonctionne déjà (nombreux fixes récents). |
| F5 — Polish PWA iPhone | **Nice to Have** | Confort d'installation, pas un blocant fonctionnel. |

## 4. Critères d'acceptation

**F1**
- [ ] Sur un iPhone (375–430px de large, portrait et paysage), toutes les zones interactives du match sont utilisables sans zoom ni scroll horizontal.
- [ ] La saisie d'une action (but, tir, etc.) prend le même nombre de taps que sur iPad.
- [ ] Aucune régression du layout iPad existant.

**F2**
- [ ] Les écrans Stats, Bilan et Setup ont un niveau de finition visuelle cohérent avec l'écran Match actuel.
- [ ] Tous les boutons ont un état actif/hover cohérent avec la charte déjà en place.

**F3**
- [ ] Un rappel d'export est visible à un moment clé (fin de match ou onglet Bilan) sans être intrusif.

**F4**
- [ ] Liste documentée des frictions trouvées (ou constat "rien à corriger") avec, si besoin, des stories de correction.

**F5**
- [ ] L'icône et le nom affichés à l'écran d'accueil sont corrects sur iPhone.

## 5. Hors scope

- Compte utilisateur / synchronisation multi-appareils / backend.
- Changement de stack technique (reste vanilla JS, pas de framework, pas de bundler).
- Toute intégration ou dépendance avec l'autre appli web CF (suivi CF) présente sur la machine de Romain.
- Refonte complète du système de couleurs (le thème dark + accent de possession reste la base).

## 6. Dépendances

- F2 dépend de F1 pour les écrans concernés par le responsive (pas de sens à polir un layout qui va encore bouger).
- F4 doit être fait avant ou en parallèle de F1 (une friction de workflow trouvée peut changer la manière de redimensionner pour iPhone).
- F3 et F5 sont indépendantes du reste.

## 7. Risques

- Casser le layout iPad (validé et stable depuis plusieurs itérations) en ajoutant le support iPhone — mitigé par tests explicites sur les deux tailles avant livraison (détaillé par le Risk Analyst).
- Sur-attendre le calibrage exact des tailles d'écran (variantes iPhone SE / Pro Max) sans accès à un vrai device pour tester — nécessite validation manuelle de Romain sur son appareil réel avant de considérer F1 "terminé".
