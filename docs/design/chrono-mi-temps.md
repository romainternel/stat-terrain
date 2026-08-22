# Design — Chrono : temps mort et changement de mi-temps

*Produit par le Designer — squad build BMAD*
*S'appuie sur `docs/prd-v17-chrono-mi-temps.md`*

## Contexte
Deux points de contact, tous deux déjà existants dans le timer du Scoreboard : le bouton "⏸ TM" et le bouton "MT {période}" (`per-btn`). Aucun nouvel écran — uniquement le comportement de deux boutons déjà en place, plus des dialogues natifs (`safeConfirm`/`showToast`) déjà utilisés ailleurs dans l'app (bascule Expert→Simple). Contexte d'usage : iPad, en plein match, l'utilisateur regarde autant le terrain que l'écran — les messages doivent être lisibles d'un coup d'œil et sans ambiguïté sur ce qu'on est en train de confirmer.

## F1 — Temps mort : aucun changement visuel
Le bouton "⏸ TM" ne change ni de forme ni d'emplacement. Le seul changement observable : le bouton ▶/⏸ du timer (`t-toggle`) passe visuellement à l'état pause au moment du clic sur TM, exactement comme s'il avait été cliqué manuellement — même état visuel, pas de nouvel indicateur.

## F2+F3 — Passage MT1 → MT2

```
Tap "MT 1" (per-btn)
        │
        ▼
┌───────────────────────────────────────┐
│  Mi-temps 1 terminée ?                 │
│                                         │
│  Le chrono va repasser à 0:00 et       │
│  redémarrer automatiquement en         │
│  mi-temps 2.                           │
│                                         │
│           [ Annuler ]   [ Oui, MT2 ]   │
└───────────────────────────────────────┘
```
- `Annuler` (ou fermeture du dialogue navigateur) : aucun changement — bouton reste "MT 1", chrono inchangé, running inchangé.
- `Oui, MT2` : bouton devient "MT 2", chrono affiche `00:00` et tourne déjà (pas besoin de retoucher ▶). Immédiatement enchaîné (F5) :

```
┌───────────────────────────────────────┐
│  🧤 Pense à vérifier les gardiens !    │
│  Les gardiens sélectionnés sont-ils    │
│  toujours les bons pour la 2e mi-temps?│
└───────────────────────────────────────┘
```
Ce second message est un toast d'alerte (même famille visuelle que "Changez de GB !", "TM conseillé") — pas un `safeConfirm` bloquant, l'utilisateur n'a rien à valider dessus, juste à le voir. Il reste visible via le bandeau/pastille d'historique d'alertes déjà existant (STORY-63) s'il n'a pas eu le temps de le lire tout de suite.

## F4 — Retour MT2 → MT1 (clic accidentel)

```
Tap "MT 2" (per-btn)
        │
        ▼
┌───────────────────────────────────────┐
│  Revenir à la mi-temps 1 ?             │
│                                         │
│  Le chrono va reprendre au dernier     │
│  temps enregistré en mi-temps 1        │
│  (12:34) et rester en pause.           │
│                                         │
│         [ Annuler ]   [ Oui, MT1 ]     │
└───────────────────────────────────────┘
```
- Le temps affiché entre parenthèses dans le message (`12:34` dans l'exemple) est calculé dynamiquement — le dernier tag réel de MT1, pas un texte générique, pour que l'utilisateur sache exactement où il va atterrir avant de confirmer.
- `Annuler` : aucun changement — bouton reste "MT 2", chrono inchangé.
- `Oui, MT1` : bouton redevient "MT 1", chrono affiche le temps restauré et **reste en pause** (bouton ▶/⏸ à l'état pause) — l'utilisateur relance manuellement quand il est prêt, cf. Architecture pour le raisonnement. Aucun message gardiens dans ce sens.
- Un toast bref confirme l'action une fois appliquée : "↩ Retour à la mi-temps 1 — chrono en pause à 12:34".

## Différenciation des deux messages
Les deux confirmations doivent être visuellement/textuellement impossibles à confondre au premier coup d'œil, même en lecture rapide en plein match :
- Icône/ton différent : MT1→MT2 = ton neutre/positif ("on avance"), MT2→MT1 = ton correctif ("on revient en arrière", ex. icône ↩).
- Le texte du bouton de confirmation nomme explicitement la destination ("Oui, MT2" / "Oui, MT1"), jamais un simple "OK"/"Confirmer" générique.

## États
- **Chrono à l'arrêt au moment du clic MT** (ex. pendant un TM) : le comportement de confirmation/reset est identique, indépendant de l'état running au moment du clic — F3 force `running=true` en sortie, F4 force `running=false` en sortie, quel que soit l'état avant.
- **Aucun événement encore tagué en MT1** (mi-temps changée dès le coup d'envoi, avant tout tag) : le message F4 affiche "30:00" (temps réglementaire) au lieu d'un temps de dernier tag inexistant — le texte reste cohérent, pas de "undefined" ni de "0:00" trompeur.

## Responsive
Aucun changement de layout — `safeConfirm`/`showToast` utilisent déjà le rendu natif/toast existant, qui s'adapte tel quel à iPad portrait/paysage et iPhone (déjà éprouvé par la confirmation Expert→Simple).

## Composants réutilisés
- `safeConfirm()` — dialogue bloquant, déjà utilisé pour la bascule Expert→Simple.
- `showToast(msg, isAlert)` — pour le rappel gardiens (F5, `isAlert:true` pour rester dans l'historique d'alertes STORY-63) et le toast de confirmation F4.
- Bouton `per-btn` et `t-toggle` existants — aucun nouvel élément d'interface, seulement leur comportement au clic.
