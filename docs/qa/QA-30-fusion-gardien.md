# QA — STORY-30 : Fusionner la carte gardien (terrain + chiffres) en une "feuille" par équipe

## Méthode de test

Tests réels via CDP (Chrome headless dédié `--headless=new`, profil temporaire isolé, port **9733** — libre parmi ceux déjà utilisés cette session), vrais clics (`Input.dispatchMouseEvent` à des coordonnées calculées via `getBoundingClientRect()`) pour tous les boutons (⛶, fermeture plein écran, filtre type de tir, nav Stats). Écran d'accès contourné via injection `S.authOk=true` conformément à la consigne. Client CDP écrit à la main en Node (WebSocket natif Node 24, pas de dépendance externe), scripts dans le scratchpad de session.

Données de test réalistes injectées directement dans `S` (équivalent à une saisie réelle, sans passer par les formulaires de composition d'équipe qui ne font pas partie du périmètre de cette story) :
- **FENIX (home)** : 2 GB sélectionnés (#1 Dupont, #12 Martin) + 7 tirs adverses répartis sur les deux (3 arrêts + 1 but pour Dupont, 1 arrêt + 1 hors cadre + 1 but pour Martin).
- **Adversaire (away)** : 1 seul GB sélectionné (#16 Petit) + 4 tirs (2 arrêts, 1 but, 1 hors cadre).
- Vérifié par recoupement manuel que les valeurs affichées (ratio, %, chips, table de détail) correspondent exactement au calcul attendu de `gkStats()`/`gkStatsCombined()` — aucune de ces fonctions n'a été modifiée par la story, seul le calage visuel a été revérifié.

Pour le `<select>` GB (élément natif dont le menu déroulant n'est pas une surface DOM/CDP-rendable en headless), le geste utilisateur a été simulé par l'équivalent fonctionnel exact d'une sélection réelle : `select.value = "..."` puis `dispatchEvent(new Event('change', {bubbles:true}))` — c'est strictement ce que le navigateur déclenche lui-même une fois la liste native refermée, et c'est le binding réel du handler `onchange` qui est exercé, pas un appel direct à une fonction interne.

**Point méthodologique notable** : `R()` est différé par `requestAnimationFrame` (double-buffer anti-flicker, convention documentée dans `CLAUDE.md`). Une première vérification synchrone juste après un `dispatchEvent`/clic a montré à tort un "non-changement" — corrigé en attendant deux frames (`requestAnimationFrame` imbriqués) avant de relire le DOM. Mentionné ici pour traçabilité, ce n'est pas un bug de la story.

## Critères d'acceptation — validation

| # | Critère | Statut | Détail |
|---|---|---|---|
| 1 | Une seule carte par équipe (2 au total), terrain+chiffres visibles ensemble sans scroll | ✅ | `document.querySelectorAll('.stat-courts > .card.gk-sheet').length === 2`. À 1280×900, les deux cartes ont `top:141 / bottom:629` — entièrement dans le viewport (900px de haut), aucun scroll nécessaire pour voir les deux à la fois. |
| 2 | Le dropdown GB change à la fois les chiffres ET les tirs sur le terrain, en un seul `change` | ✅ | Avant (tous GB) : `4/6`, `67%`, `2 encaissés`/`1 hors cadre`, 7 points sur le terrain. Après sélection réelle de `#1 Dupont` seul (un seul événement `change` dispatché) : `3/4`, `75%`, `1 encaissés`/`0 hors cadre`, **4** points sur le terrain (les 3 tirs de Martin ont disparu) — chiffres et terrain changent ensemble, dans le même passage de rendu, aucune désynchronisation. |
| 3 | Label statique (pas de dropdown) quand un seul GB, avec la couleur d'équipe | ✅ | Côté adverse (1 seul GB) : aucun `<select>` (`hasSelect:false`), `<div>` statique `"#16 Petit"`, `font-weight:700`, `color: rgb(232, 70, 90)` = `var(--red)` (couleur équipe adverse), position identique à celle du dropdown. |
| 4 | État vide "Aucun gardien sélectionné" quand 0 GB, sans `0/0` | ✅ | GB adverse désélectionné → `.gk-col-empty` avec `🧤` + `"Aucun gardien sélectionné"` remplace intégralement `.gk-sheet-nums`. Vérifié explicitement : `nums.textContent.indexOf('0/0') === -1`. Header sans select ni label (`headerChildCount:1`, seulement le nom d'équipe). Le terrain reste affiché (SVG présent, 0 point). |
| 5 | Responsive : X positions réelles, pas de chevauchement ni débordement | ✅ | **Desktop (1280px)** : terrain `left:7→396`, chiffres `left:412→621` — terrain strictement à gauche des chiffres, aucun chevauchement, sur les DEUX feuilles. **Mobile (390px)** : chiffres `top:209→337`, terrain `top:353→732` — chiffres strictement au-dessus du terrain, empilement vertical confirmé par les coordonnées Y réelles (pas seulement par la classe CSS). Aucun débordement horizontal imputable à `.gk-sheet`/`.stat-courts` : audit exhaustif de tous les éléments de `#app` à 390px, les 4 seuls éléments dépassant le viewport sont `.nav-b`/`.st-tab` (nav header + sous-onglets Stats), un scroll horizontal **intentionnel et pré-existant** (STORY-18), aucun rapport avec cette story. Voir note sous "Points non-bloquants" pour une nuance sur le seuil exact de 700px. |
| 6 | Plein écran (⛶) fonctionne sans erreur, colonne chiffres garde son alignement vertical | ✅ | Testé en réel (clic sur ⛶ puis sur ✕ Fermer) sur les DEUX feuilles (FENIX et adverse), en **portrait** (834×1194) et **paysage** (1194×834) façon iPad. Aucune exception JS levée (`Runtime.exceptionThrown` écouté explicitement, 0 occurrence sur l'ensemble des 3 passages). `fs-btn` bien retiré du clone (0 restant), 1 seul SVG `viewBox="0 0 350 208"`. Colonne chiffres dans l'overlay : `display:flex`, `flex-direction:column`, `flex-basis:35%` conservés dans les deux orientations — **jamais écrasée à `width:50%`** (la règle CSS `@media(orientation:landscape) … div[style*="grid-template-columns"]{width:50%}` ne cible que la heatmap, confirmé par l'absence totale de `grid-template-columns` dans `.gk-sheet-nums`, voir point 7 ci-dessous). |
| 7 | Non-régression `renderGkDetailTables()` + filtre type de tir | ✅ | Table de détail visible sans clic supplémentaire, juste sous les 2 feuilles, valeurs exactement conformes au calcul attendu : Dupont `3/4 75%`, Martin `1/2 50%`, Petit `2/3 67%` (recoupement manuel avec les événements injectés). Filtre "● Encaissés" désactivé par clic réel : `S.gkShotFilter.goals` passe à `false` (état global partagé, pas dupliqué par équipe), le nombre de points sur le terrain FENIX passe de 7 à 5 (les 2 buts disparaissent), bouton visuellement atténué (`opacity:.4`) — comportement identique à avant la story. |
| 8 | Reset de `S.gkFilter`/`S.gkShotFilter` par `newMatch()` | ✅ | Filtré sur un GB spécifique (`S.gkFilter={home:"gk_h1",away:"gk_a1"}`, `S.gkShotFilter.goals=false`), puis `newMatch()` appelée avec confirmation simulée (`window.confirm` forcé à retourner `true`, équivalent fonctionnel de l'acceptation de la boîte de dialogue). Résultat : `S.gkFilter` revient exactement à `{home:"all",away:"all"}`, `S.gkShotFilter` à `{goals:true,saves:true,offs:true}`, `S.events` vidé. Le handler `[data-load-match]` (`app.js` l.3912) a été vérifié par lecture directe du code source (même reset, même emplacement) — cohérent avec la confirmation du Code Reviewer. |
| 9 | Onglet Stats atterrit par défaut sur "Comparaison" (pas "Gardiens") | ✅ | Rechargement complet réel de la page (`Page.reload`, état `S` totalement neuf) : `S.statsTab === "compare"` avant même la première visite de l'onglet Stats. Clic réel sur le nav "📊 Stats" → onglet actif affiché est bien `"📊 Comparaison"` (contenu comparatif visible, `0` feuille gardien rendue). |

## Vérifications complémentaires (au-delà des 9 scénarios demandés)

- **Cas `0/0` réel (GB sélectionné, 0 tir enregistré)** — distinct de l'état vide (section F) : `38px`/`font-weight:800`/couleur cyan identique au cas rempli, `%` affiché `"-"`. Pas de réduction ni de grisage. Conforme.
- **Audit `grid-template-columns` à l'exécution** (pas seulement sur le code source) : exactement **1** occurrence par feuille dans le HTML réellement rendu, **0** occurrence à l'intérieur de `.gk-sheet-nums` — confirme mécaniquement le contrat plein écran (section G) sur le DOM final, pas seulement par grep statique.
- **Direction des chips niveau 3** : `flex-direction:column` à 1280px (empilées), `row` à 390px (côte à côte) — conforme à la spec C.
- **Captures d'écran** (desktop 1280px et mobile 390px) : rendu visuel cohérent avec `docs/design/stats-gardiens.md` — dropdown/label en haut à droite du header, hiérarchie ratio/%/chips bien démarquée visuellement, ordre terrain-gauche/chiffres-droite en desktop et chiffres-haut/terrain-bas en mobile.

## Points non-bloquants (informatifs, pas des bugs)

1. **Seuil de 700px inclusif, pas exclusif.** Le CSS utilise `@media(max-width:700px)` (repris tel quel de `.stat-courts`, comme demandé pour ne pas introduire un nouveau nombre de breakpoint) — à **exactement** 700px de large, la mise en page est déjà en colonne (empilée), pas en `row-reverse`. Le texte de la story dit littéralement "row-reverse ≥700px / column <700px", ce qui suggérerait que 700px pile devrait être en ligne. Comportement identique à toutes les autres media queries déjà en place dans le projet (`.stat-courts`, détection Mode Simple `innerWidth<700`) — ce n'est pas une déviation introduite par cette story, juste une nuance d'un pixel sans impact réel (aucun appareil cible n'a exactement 700px de large). Ne bloque pas le verdict.
2. **Débordement horizontal pré-existant du nav/sous-onglets à 390px** — confirmé sans rapport avec cette story (voir critère 5), comportement intentionnel de STORY-18. Mentionné uniquement parce que la consigne demandait explicitement de vérifier l'absence de débordement.
3. **Divergence possible encaissés/hors-cadre avec des tirs pénalty** (point "Recommandé" #4 du Code Reviewer) — comportement hérité du code existant (`gkStats()` exclut les pénaltys des chips, les compteurs sous le terrain non). Non testé en profondeur ici : le Code Reviewer l'a explicitement classé non-bloquant et non introduit par cette story (aucune des fonctions de calcul n'a été modifiée). Signalé pour traçabilité si une story de polish future veut l'adresser.

## Bugs trouvés

Aucun.

## Régressions détectées

Aucune :
- `renderGkDetailTables()` intacte, valeurs identiques à ce qu'elles seraient sans la story.
- Filtre type de tir (Encaissés/Arrêtés/Hors cadre) toujours fonctionnel, toujours un état global partagé.
- `gkStats()`/`gkStatsCombined()`/`selectedGbs()` non modifiées, valeurs recalculées manuellement et confirmées identiques à l'affichage.
- Onglet Stats par défaut sur "Comparaison" confirmé après rechargement réel de la page (changement fait dans la même session, re-confirmé indépendamment ici).
- Aucune exception JS observée sur l'ensemble de la session de test (setup, changement de filtre, plein écran ×3, clics de filtre, reset, reload).

## Verdict

**PASSED**

Les 9 critères d'acceptation demandés sont satisfaits, avec vérification mécanique réelle (positions X/Y, comptage runtime de `grid-template-columns`, exceptions JS écoutées explicitement) plutôt qu'une simple relecture du code. Le point bloquant historique (chevauchement/débordement du header lors du `row-reverse`, déjà corrigé par le Developer via `.gk-sheet-body`) a été retesté indépendamment et ne se reproduit pas, sur les deux feuilles et aux deux extrémités du breakpoint. Aucun bug, aucune régression. Feu vert pour la suite du pipeline (Regression Guardian).
