# Visual Spec — Analyse / Notes coach / PDF dans Bilan

*Produit par le Visual Crafter — squad build BMAD*
*S'appuie sur `docs/prd-v7-analyse-pdf-bilan.md` et la proposition informelle du Designer (sélecteur remonté au-dessus de `S.bilanTab`, bandeau "MATCH ARCHIVÉ" sticky, bordure jaune, onglet Analyse qui réutilise le style de carte existant, onglet PDF séparé avec bouton orange d'avertissement, confirmation bloquante sur note non sauvegardée — non encore formalisée en fichier `docs/design/`).*
*Ne modifie aucune décision UX du Designer (position du sélecteur, découpage des 4 onglets, comportement de la confirmation bloquante, flux "Charger ce match") — uniquement la couche visuelle : couleurs exactes, ombres, transitions, typographie, texture.*

## 0. Cadrage chromatique — pourquoi pas une 4e palette

Avant de dessiner quoi que ce soit, un inventaire des familles de couleurs déjà en production, pour vérifier qu'aucune n'a besoin d'être réinventée :

| Famille déjà en place | Rôle sémantique | Où |
|---|---|---|
| `--green`/`--red` (accent d'équipe, `--accent-rgb`) | "à qui appartient cette donnée" (FENIX vs adversaire) | Scoreboard, terrain, comparatif Bilan, `.match-layout` |
| `--gk-goal`/`--gk-save`/`--gk-off` (STORY-30) | "quel type de tir sur un gardien" (but encaissé / arrêt / hors cadre) | `renderGkSheet()`, encart pénalty, heatmap |
| `--yellow` | "un état non-défaut est actif, à noter" (mode lecteur, MODE PENALTY, MODE SIMPLE ACTIF, sélection PD) | `.readonly-banner`, badges de mode |
| `--orange` (`#E88A4E`) / `.btn-o` | "action générique orange" (tir non cadré dans la barre d'action normale, boutons secondaires) | `.ml-actions`, `.btn-o` |

Cette feature n'a besoin d'aucune 5e ou 6e teinte. Elle réutilise strictement les familles 3 et 4 :
- Le bandeau "MATCH ARCHIVÉ" et l'indicateur "notes non sauvegardées" **réutilisent la famille jaune** — cohérent avec sa sémantique déjà établie ("un état non-défaut mérite d'être signalé"), différenciés entre eux par le poids/la forme/la position, jamais par la teinte (détail §3 et §7).
- Le bouton PDF d'avertissement **réutilise `--orange`/`#E88A4E` exactement**, pas `--gk-off` (`#E89A4E`, différence d'1 chiffre hex). C'est délibéré : `--gk-off` est réservé sémantiquement à "hors cadre" dans la palette tirs (STORY-30) — le réutiliser ici pour un bouton d'action destructrice brouillerait cette limite déjà posée par `docs/visual/stats-gardiens.md` et `docs/visual/encart-penalty.md`. `--orange` est la bonne référence : c'est déjà la couleur d'un bouton d'action générique (`.btn-o`) dans cette app, pas un type de tir. La différenciation avec un bouton d'action normal ne se fait donc pas par la teinte (détail §6) mais par le traitement : texture, poids de bordure, permanence de l'avertissement.

Aucun nouveau token de couleur n'est introduit par cette spec — seulement des RGB triplets dérivés des hex existants, nécessaires pour les glows/textures.

## 1. Palette de tokens

```css
/* Aucun nouveau — dérivés RGB des tokens existants, pour glows/textures */
--pdf-warn-rgb: 232,138,78;   /* = var(--orange), PAS --gk-off malgré la proximité visuelle, cf. §0 */
--yellow-rgb:   240,199,94;   /* = var(--yellow), déjà utilisé en dur ailleurs (readonly-banner, badges) — juste nommé ici pour cette spec */
```

## 2. Typographie

| Élément | Taille | Poids | Couleur | Cas |
|---|---|---|---|---|
| Sélecteur de match — option affichée | `13px` | `600` | `var(--text)` | inchangé (déjà en place) |
| Bandeau archivé — label "MATCH ARCHIVÉ" | `12px` | `800` | `var(--yellow)` | `letter-spacing:.05em`, uppercase |
| Bandeau archivé — nom du match | `12px` | `800` | `var(--text)` | pas de letter-spacing (nom propre, pas un label) |
| Bouton PDF warning | `14px` | `800` | `var(--orange)` | pas d'uppercase forcé (phrase complète avec icône, l'uppercase la rendrait illisible) |
| Note d'avertissement permanente (PDF) | `11px` | `500` | `var(--t2)` | `line-height:1.5` |
| Chip "Non sauvegardé" / "Sauvegardé" | `10px` | `700` | `var(--yellow)` / `var(--gk-goal)` | `letter-spacing:.04em`, jamais uppercase (le point + le texte suffisent, cf. `.gk-pill`) |

## 3. Sélecteur de match partagé — formalisation en classe

Le sélecteur existe déjà (`#bilan-match-sel`, style inline) mais remonte au-dessus de la barre d'onglets et devient le point d'entrée des 3 premiers onglets (Match/Analyse/PDF), pas seulement de Match — il mérite une classe propre plutôt que du style inline dupliqué 3 fois si le Developer doit le réafficher à l'identique dans chaque onglet.

```css
.bilan-match-select{
  background:var(--bg3);
  border:1px solid rgba(95,168,211,.30);   /* accent fenix-sky neutre — ce n'est pas une donnée "équipe" ni une "alerte", c'est de la navigation */
  border-radius:var(--r2);
  color:var(--text);
  font-size:13px; font-weight:600;
  padding:9px 12px;
  min-height:38px;   /* cible tactile pleine, plus généreuse que .gk-filter-select (30px) — ce contrôle est désormais un point d'entrée principal, pas un filtre secondaire */
  transition:border-color .15s ease, background .15s ease;
}
.bilan-match-select:active{ background:rgba(95,168,211,.10); }
```
`:focus-visible` : règle globale déjà posée (`outline:2px solid var(--accent)`), rien à ajouter.

**Position : statique, pas sticky.** Contrairement au bandeau archivé (§4), le sélecteur défile normalement avec le reste de la page. Deux raisons : (1) le Designer n'a demandé le comportement sticky que pour le bandeau ; (2) le bandeau porte déjà le nom du match dans son propre texte — une fois le sélecteur sorti de l'écran au scroll, Romain a toujours "quel match" sous les yeux via le bandeau, sans redondance nécessaire à figer aussi le sélecteur.

Le label "Match :" qui précède (déjà en place, `font-size:12px;font-weight:600;color:var(--t2)`) reste inchangé.

## 4. Bandeau "📁 MATCH ARCHIVÉ — [nom]" — sticky, silhouette dédiée

C'est l'élément qui porte à lui seul la garantie anti-confusion demandée par le PRD ("le pire résultat si mal fait" identifié par le Risk Analyst : confondre match archivé et match en cours). Il doit être *impossible à louper*, y compris en plein scroll dans un fil d'événements ou une liste d'insights longue.

```css
.bilan-archived-banner{
  position:sticky; top:0; z-index:40;
  display:flex; align-items:center; justify-content:center; gap:8px; flex-wrap:wrap;
  background:rgba(240,199,94,.14);
  border:2px solid var(--yellow);
  border-top:none;                          /* pas de bordure sur le bord qui touche le haut du viewport une fois figé — évite une ligne double avec le bord de l'écran */
  border-radius:0 0 var(--r2) var(--r2);     /* coins plats en haut, arrondis en bas — silhouette "accrochée au bord", pas une carte flottante comme le reste de l'app */
  padding:8px 16px;
  margin:0 0 10px;
  box-shadow:0 4px 16px rgba(0,0,0,.45), inset 0 1px 0 rgba(255,255,255,.05);
  font-size:12px; font-weight:700; color:var(--yellow); letter-spacing:.05em;
  text-align:center;
}
.bilan-archived-banner .icon{ font-size:15px; }
.bilan-archived-banner .match-name{ color:var(--text); font-weight:800; letter-spacing:normal; }
```

**Pourquoi ce n'est pas juste `.readonly-banner` recoloré, et pourquoi ça reste volontairement dans la même famille jaune :**

| | `.readonly-banner` (existant) | `.bilan-archived-banner` (nouveau) |
|---|---|---|
| Portée | Verrouillage de l'appareil (mode lecteur) | "Vous consultez un match archivé, pas le match en cours" |
| Position | Statique, dans le flux de `.match-layout` | **Sticky**, reste visible en permanence pendant le scroll |
| Bordure | `1.5px` | `2px` — plus appuyée, cohérent avec un rôle "je dois rester visible même hors contexte immédiat" |
| Silhouette | Coins uniformément arrondis (`border-radius:6px`), contenue dans la grille | Coins plats en haut / arrondis en bas — signale visuellement "je suis collé au bord", personne d'autre dans l'app n'a cette forme |
| Élévation | Aucune (pas besoin, rien ne défile derrière) | Ombre portée dédiée (`0 4px 16px rgba(0,0,0,.45)`) — premier élément sticky de toute l'app, doit se détacher visuellement du contenu qui défile en dessous |

Garder la même teinte jaune pour les deux est un choix délibéré, pas un oubli : dans cette app, "bordure jaune" signifie déjà "un état non-défaut mérite votre attention" (mode lecteur, MODE PENALTY, MODE SIMPLE). Les deux bandeaux ne se chevauchent jamais à l'écran (l'un vit dans Match, l'autre dans Bilan), donc il n'y a pas de risque de confusion directe — et garder le même vocabulaire chromatique plutôt que d'inventer une 5e teinte renforce la cohérence globale du langage visuel de l'app.

**Ce que ce bandeau ne fait PAS** : pas de texture, pas de rayures, pas d'icône ⚠️. Contrairement au bouton PDF (§6), ce bandeau est **informationnel**, pas un avertissement de danger — consulter/éditer Analyse et Notes depuis Bilan est strictement sans risque pour le match en cours (garantie Must Have #7 du PRD). Lui donner un traitement "alarme" identique à celui du bouton PDF laisserait croire, à tort, que la simple consultation est aussi risquée que le raccourci PDF — c'est exactement la confusion de sévérité que le PRD évite explicitement en séparant Must Have (sûr à 100%) et Should Have (pis-aller assumé). Un seul niveau d'alerte par gravité réelle.

**Rendu exact** :
```html
<div class="bilan-archived-banner">
  <span class="icon">📁</span>
  <span>MATCH ARCHIVÉ — <span class="match-name">{home} {scoreH}-{scoreA} {away} ({journée})</span></span>
</div>
```
Affiché uniquement sur les onglets Match/Analyse/PDF quand `S.bilanMatch` est non nul (jamais sur Saison, jamais sur le placeholder "sélectionne un match") — condition déjà tranchée par le Designer, ici seulement confirmée côté rendu visuel.

## 5. Onglet Analyse — réutilisation stricte, la distinction se joue ailleurs

Conforme à la demande du Designer ("réutilise le style de carte existant") et au PRD ("Hors scope : toute refonte visuelle des onglets Stats existants, au-delà du strict nécessaire"). Concrètement :

- Carte insights : `.card` + `.card-t` ("🧠 Analyse automatique") strictement identiques à `renderAnalyse()` — même fond, même padding, mêmes lignes d'insight (icône + texte sur fond `var(--bg)` légèrement surélevé).
- Textarea notes : mêmes dimensions/couleurs que l'actuelle (`min-height:120px`, `border:1px solid var(--border)`, `background:var(--bg)`) — seule addition : le chip dirty-state (§7), exclusif à ce contexte.
- Bouton "📋 Copier le résumé d'analyse" : strictement identique (`.btn.btn-g`, pleine largeur).

**Où se joue vraiment la distinction avec Stats → Analyse** (risque central identifié par le PRD) : pas dans le style des cartes elles-mêmes, mais dans ce qui les entoure — le sélecteur de match (§3) et surtout le bandeau sticky (§4), absents de Stats → Analyse par construction (ce dernier n'a pas de notion de "match archivé", c'est toujours le match en cours). La présence/absence de ces deux éléments est un signal plus fiable qu'une variante de couleur sur la carte elle-même : un utilisateur qui changerait la couleur d'une carte pourrait toujours douter s'il ne l'a pas mémorisée avec précision, alors qu'un bandeau sticky jaune avec un nom de match dessus ne laisse aucune ambiguïté, y compris pour quelqu'un qui n'a jamais vu l'écran avant. Retoucher aussi le style des cartes serait redondant, et irait à l'encontre de la consigne explicite du Designer et du PRD de ne pas refaire visuellement ce qui marche déjà.

## 6. Onglet PDF — carte "zone à risque", bouton d'avertissement, note permanente

C'est ici, et uniquement ici, que le vocabulaire "danger/provisoire" doit s'exprimer visuellement — pas de fuite vers les onglets Match/Analyse.

### 6.1 Carte englobante — texture de fond dédiée

```css
.card.bilan-pdf-card{
  background: repeating-linear-gradient(135deg,
      rgba(232,138,78,.045) 0px, rgba(232,138,78,.045) 12px,
      transparent 12px, transparent 24px),
    var(--card-bg);   /* la texture se superpose au gradient de carte existant, ne le remplace pas */
  border-color: rgba(232,138,78,.35);
}
```
Rayures diagonales à très faible opacité (`.045`) — perceptibles sans nuire à la lecture du texte à l'intérieur (paragraphe d'avertissement, bouton). C'est le premier usage d'une texture dans cette app : justifié précisément parce que c'est le seul endroit où le PRD demande explicitement de ne "pas laisser croire à une génération sécurisée à froid" — un signal qui doit se voir avant même de lire une ligne de texte, cohérent avec le principe "la couleur/texture est une information, jamais décorative" : ici, la texture porte l'information "zone provisoire", au même titre que le texte.

### 6.2 Bouton "⚠️ Charger ce match & générer son PDF"

```css
.btn-pdf-warn{
  position:relative;
  width:100%; padding:14px 20px; border-radius:var(--r2);
  border:2px solid rgba(232,138,78,.55);      /* 2px, pas 1.5px comme .btn standard — signale "ce n'est pas un bouton d'action ordinaire" avant même la lecture */
  background: repeating-linear-gradient(135deg,
      rgba(232,138,78,.16) 0px, rgba(232,138,78,.16) 8px,
      rgba(232,138,78,.06) 8px, rgba(232,138,78,.06) 16px);
  color:var(--orange); font-size:14px; font-weight:800; letter-spacing:.02em;
  transition:all .15s ease;
}
.btn-pdf-warn:active{
  transform:scale(.97);
  background: repeating-linear-gradient(135deg,
      rgba(232,138,78,.28) 0px, rgba(232,138,78,.28) 8px,
      rgba(232,138,78,.12) 8px, rgba(232,138,78,.12) 16px);
  box-shadow:0 0 0 1px rgba(232,138,78,.5), 0 0 16px rgba(232,138,78,.3);
}
```
Rayures plus marquées que celles de la carte (`.16`/`.06` contre `.045`) — le bouton est le point d'action, il doit porter le signal le plus fort de tout l'onglet.

**Pourquoi ce traitement et pas simplement `.btn-o`** (réponse directe à la question posée) : `.btn-o` (`border-color:rgba(232,138,78,.45);color:var(--orange)`) est déjà utilisé ailleurs dans l'app pour des actions orange *ordinaires*, sans conséquence destructrice. Ce bouton-ci remplace le match en cours — une action à la même famille de gravité que "Charger" dans l'historique (`data-load-match`), qui elle-même n'a aujourd'hui qu'un traitement `.btn-g` (vert, "action positive") **sans aucun signal visuel de risque en dehors de la popup**. Ne pas distinguer ce bouton d'un `.btn-o` classique reproduirait exactement l'angle mort déjà présent sur "📂 Charger" dans l'historique — le PRD demande explicitement d'éviter ça ("ne pas laisser croire... action provisoire assumée"). D'où : même teinte (`--orange`, cf. §0 — pas de nouvelle couleur), mais bordure doublée, texture de rayures, pleine largeur (les autres boutons d'action de cette taille ne le sont pas systématiquement), et surtout la note permanente ci-dessous — quatre renforts cumulés sur la couleur seule, à dessein.

### 6.3 Note d'avertissement permanente — visible en dehors de toute popup

```css
.bilan-pdf-warning-note{
  display:flex; gap:8px; align-items:flex-start;
  margin-top:10px; padding:10px 12px;
  background:rgba(232,138,78,.06);
  border-left:3px solid var(--orange);
  border-radius:0 var(--r1) var(--r1) 0;
  font-size:11px; line-height:1.5; color:var(--t2);
}
.bilan-pdf-warning-note .ic{ font-size:14px; flex-shrink:0; }
```
Placée **au-dessus** du bouton, pas seulement en dessous ni seulement dans la popup `safeConfirm()` (native, non stylable — hors du périmètre de cette spec) : Romain doit pouvoir lire "ce bouton remplace le match en cours" avant même de poser le doigt sur le bouton, pas seulement au moment où la popup l'interrompt. Le texte exact reste au PM/Designer ; le traitement visuel (bordure gauche pleine couleur, fond légèrement teinté, icône ⚠️ à gauche) est cohérent avec le registre "callout d'avertissement" déjà introduit par la carte englobante (§6.1) et le bouton (§6.2) — les trois éléments de l'onglet PDF se lisent comme un seul système cohérent, pas trois traitements différents assemblés au hasard.

## 7. Indicateur "notes non sauvegardées" (dirty state) — Bilan uniquement

**Contrainte non négociable en premier** : ce chip et le changement de bordure de la textarea ne s'appliquent **qu'à l'instance Bilan** de la textarea notes (celle liée à l'édition de `m.coachNotes`). La textarea de Stats → Analyse (liée à `S.coachNotes`) reste strictement inchangée — aucune classe, aucun style ajouté — conforme au Must Have #9 du PRD ("aucune régression... restent strictement identiques à aujourd'hui"). Ajouter ce signal là-bas laisserait croire à une vraie persistance qui n'existe pas dans ce contexte (le bouton y reste un toast cosmétique, décision actée #2 du PRD).

### 7.1 Chip d'état — header de la carte

```css
.bilan-dirty-chip{
  display:inline-flex; align-items:center; gap:5px;
  font-size:10px; font-weight:700; letter-spacing:.04em;
  color:var(--yellow); background:rgba(240,199,94,.10); border:1px solid rgba(240,199,94,.30);
  border-radius:999px; padding:2px 8px 2px 6px;
  animation:fadeIn .2s ease;   /* keyframe déjà existante */
}
.bilan-dirty-chip .dot{ width:6px; height:6px; border-radius:50%; background:var(--yellow); flex-shrink:0; }
.bilan-dirty-chip.saved{
  color:var(--gk-goal); background:rgba(80,200,120,.10); border-color:rgba(80,200,120,.30);
}
.bilan-dirty-chip.saved .dot{ background:var(--gk-goal); }
```
`.card-t` de la carte notes passe en `display:flex;justify-content:space-between;align-items:center` pour loger le chip à droite du titre "📝 Notes du coach", sans changer le style du titre lui-même.

**Machine à états visuelle** (répond directement à la question posée : signaler *avant* la tentative de changement de match, pas seulement à la confirmation) :

| État | Déclencheur | Chip | Bordure textarea |
|---|---|---|---|
| Propre (rien tapé, ou revient à la valeur sauvegardée) | Par défaut, ou après sauvegarde réussie + 1.4s | Absent | `1px solid var(--border)` (inchangé) |
| Sale (dirty) | `oninput` dès que la valeur diffère de la dernière valeur sauvegardée de `m` | `● Non sauvegardé`, jaune | `1px solid rgba(240,199,94,.45)` — transition `.15s ease`, jamais de glow, c'est un état ambiant persistant, pas une alerte ponctuelle |
| Sauvegardé (flash) | Juste après un clic sur "💾 Sauvegarder notes" et `dbSaveMatch()` résolu | `✓ Sauvegardé`, vert (`.saved`) pendant **1.4s exactement**, puis disparaît (retour à l'état Propre) | Retourne à `var(--border)` en même temps que le chip repasse propre |

Le chip apparaît **dès la frappe**, avant toute tentative de changer de match — c'est précisément ce qui différencie ce signal de la confirmation bloquante (`safeConfirm()`, native, non stylable, qui n'intervient qu'*a posteriori* si l'utilisateur tente de changer de sélection). Les deux se complètent : le chip est l'alerte ambiante continue, la popup est le garde-fou ponctuel au moment critique.

Couleur "sauvegardé" en `var(--gk-goal)` (vert de la palette tirs, §0) plutôt qu'en `var(--green)` (bleu ciel FENIX, malgré son nom) : `--gk-goal` porte déjà la sémantique "issue positive" ailleurs dans l'app (but marqué/encaissé, bouton BUT de l'encart pénalty) — cohérent pour signaler "l'écriture a réussi", sans piocher dans une nouvelle teinte ni dans la famille "équipe" qui n'a rien à voir ici.

**Un seul signal supplémentaire, pas trois** : pas de glow sur le bouton "💾 Sauvegarder notes" pendant l'état dirty. Le chip + la bordure suffisent (deux renforts qui pointent vers la même information) ; un troisième signal sur le bouton diluerait l'attention pour un enjeu réel mais faible (une note perdue, pas un tireur mal crédité comme dans `docs/visual/encart-penalty.md`) — cohérent avec le principe déjà appliqué dans cette dernière spec : l'intensité du traitement doit être proportionnelle à la gravité réelle.

## 8. États

- **`S.readOnly` actif** : textarea + bouton "💾 Sauvegarder notes" reçoivent `.is-disabled` (déjà existant, `opacity:.35;pointer-events:none`) — aucune nouvelle règle. Le chip dirty-state ne peut logiquement pas apparaître ici (aucune frappe possible), rien à styler.
- **Aucun match sélectionné** : placeholder déjà existant ("↑ Sélectionne un match pour le revoir") réutilisé à l'identique pour Analyse et PDF, cohérent avec Match — aucun nouveau style d'état vide à concevoir.
- **Changement de match en cours d'édition (note dirty)** : la popup `safeConfirm()` est native, non stylable — hors périmètre. Ce que cette spec garantit en amont : au moment où l'utilisateur ouvre le sélecteur, le chip §7.1 est déjà visible s'il y a une note non sauvegardée, donc la popup ne devrait jamais être une surprise totale.

## 9. Micro-animations — récapitulatif

| Élément | Animation | Durée | Déclencheur |
|---|---|---|---|
| `.bilan-archived-banner` | `fadeIn` (existante) | .25s ease | Apparition à la sélection d'un match |
| `.bilan-dirty-chip` (apparition) | `fadeIn` (existante) | .2s ease | Première frappe qui rend la note "sale" |
| `.bilan-dirty-chip` → `.saved` | aucune transition animée, changement d'état net (cohérent avec le principe déjà posé dans `docs/visual/encart-penalty.md` §4 : un changement d'état sensible doit être net, pas un fondu ambigu) | — | Sauvegarde réussie |
| `.bilan-dirty-chip.saved` → disparition | aucun fondu de sortie (cohérent avec le reste de l'app, jamais de transition de sortie) | 1.4s puis retrait DOM | Timeout après sauvegarde |
| Bordure textarea (propre ↔ sale) | `border-color` | .15s ease | `oninput` / sauvegarde |
| `.btn-pdf-warn:active` | `transform` + `background` + `box-shadow` | .15s ease | Tap |
| `.bilan-match-select` | `border-color`, `background` | .15s ease | Changement de sélection / tap |

Toutes les durées respectent la règle transverse du rôle : jamais au-dessus de 250ms.

## 10. Responsive <700px (iPhone)

| Élément | ≥700px | <700px |
|---|---|---|
| `.bilan-archived-banner` padding | `8px 16px` | `6px 10px`, `font-size:11px` |
| `.bilan-match-select` | `min-height:38px` | inchangé — c'est un point d'entrée principal, ne pas le miniaturiser sous prétexte de largeur réduite |
| `.btn-pdf-warn` | `padding:14px 20px`, `font-size:14px` | `padding:12px 16px`, `font-size:13px` — reste pleine largeur dans les deux cas |
| `.bilan-pdf-warning-note` | `font-size:11px` | inchangé |
| `.bilan-dirty-chip` | `font-size:10px` | inchangé — assez petit pour ne jamais forcer un retour à la ligne du header de carte |

## Checklist contraste WCAG

- `var(--yellow)` (`#F0C75E`) sur `--bg` : ~10:1, déjà validé (`docs/visual/polish-pass.md` §6) — réutilisé tel quel pour le bandeau archivé et le chip dirty.
- `var(--orange)` (`#E88A4E`) sur fond `--card-bg`/texture rayée à faible opacité : contraste équivalent à `--gk-off` déjà validé dans `docs/visual/encart-penalty.md` (~7.8:1) — la texture de fond, à `.045`-`.16` d'opacité, ne fait pas baisser le contraste texte de façon perceptible (les rayures sont sous le texte, pas dessus).
- `var(--gk-goal)` (`#50C878`) sur fond chip `rgba(80,200,120,.10)` : déjà validé dans `docs/visual/stats-gardiens.md` et `docs/visual/encart-penalty.md` — réutilisation stricte, aucun nouveau risque.
- `var(--text)` (blanc) sur `.bilan-archived-banner` (fond `rgba(240,199,94,.14)` composé sur fond sombre) : ~15:1, largement AAA — le nom du match doit rester lisible dans les pires conditions (plein soleil, iPad en bord de terrain).
- `var(--t2)` sur `.bilan-pdf-warning-note` (fond `rgba(232,138,78,.06)`) : `--t2` déjà validé partout comme texte secondaire ; la teinte de fond très faible n'affecte pas le ratio texte/fond de façon significative.
- Aucune combinaison entièrement nouvelle : chaque couleur utilisée est soit déjà en production ailleurs (réutilisation stricte, `--yellow`/`--gk-goal`/`--orange`), soit une texture à opacité contrôlée appliquée en couche séparée du texte.

## Note du Visual Crafter

Le risque identifié par le PRD n'est pas esthétique, il est cognitif : que Romain confonde, sous pression d'un match ou en debrief fatigué, ce qu'il est en train de regarder (match en cours vs archivé) ou ce qu'un bouton orange va réellement faire (générer un PDF proprement vs remplacer le match en cours). La réponse visuelle a donc délibérément deux intensités différentes, pas une seule :

- **Le bandeau archivé (§4) est informationnel** — jaune, sticky, silhouette dédiée, mais calme : consulter un match archivé ne casse rien, il n'a pas à faire peur.
- **L'onglet PDF (§6) est un avertissement** — même teinte orange qu'un bouton d'action ordinaire, mais texture, bordure doublée et note permanente cumulées, parce que cette action-là, elle, remplace réellement le match en cours.

Traiter les deux avec la même intensité aurait fait de l'un du bruit et de l'autre un signal noyé. Cohérent avec le mémo mémoire du projet ("pas de retouche timide, tester l'impact avant de livrer") : le bouton PDF est la première texture jamais introduite dans cette app — un choix volontairement visible, réservé au seul endroit qui le justifie vraiment.
