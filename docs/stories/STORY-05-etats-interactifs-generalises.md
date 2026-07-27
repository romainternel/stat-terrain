# STORY-05 — États interactifs généralisés (active/focus/disabled)

**En tant que** Romain,
**Je veux** que tous les boutons de l'app (pas seulement ceux de l'écran Match) réagissent de façon cohérente au toucher,
**Afin de** avoir une app qui donne un retour satisfaisant partout, avec la même qualité de finition.

## Contexte technique

- Zone concernée : `style.css` — `.btn`, `.nav-b`, `.st-tab` (Stats), boutons Setup, boutons Bilan.
- Aujourd'hui, l'état `:active` avec `transform:scale()` n'est cohérent que sur les boutons de l'écran Match (`.act-h`, `.btn`) — à généraliser aux onglets Stats (`.st-tab`), à la nav (`.nav-b`), aux boutons Setup.
- Ajout d'un état `focus` visible (`outline:2px solid var(--accent)`) — aujourd'hui `outline:none` global sur `button`/`input` sans remplacement (point d'accessibilité relevé par le Visual Crafter).
- Formalisation d'une classe utilitaire `.is-disabled` (`opacity:.35;pointer-events:none`) réutilisant le pattern déjà vu sur `.player-card.dimmed`.

## Critères d'acceptation

- [x] Tous les boutons cliquables de l'app ont un état `:active` visible (scale + changement de fond) — `.nav-b` et `.st-tab` complétés, `.btn`/`.act-h` déjà en place.
- [x] Un état `focus` visible existe — `:focus-visible` global, vérifié avec de vraies touches Tab (pas juste `.focus()` programmatique, qui ne déclenche pas l'état sous Chromium).
- [x] La classe `.is-disabled` est formalisée et prête à l'emploi — **aucun bouton actuel n'est réellement "désactivé"** dans l'app (le cas envisagé dans la story n'existe pas encore concrètement), donc rien à migrer aujourd'hui sans inventer un nouveau comportement hors scope.
- [x] Aucune régression sur les interactions Match — `.act-h`/`.btn` non touchés (diff confirmé).

## Hors scope

- Les ombres de carte (traitées dans STORY-04).

## Dépend de

STORY-04 (réutilise les mêmes tokens de base pour rester cohérent).

## Taille

S

## Notes du Developer (implémentation livrée le 2026-07-27)

**Vérifié visuellement, pas juste syntaxiquement** (suite au retour de Romain sur STORY-04) : chaque état a été confirmé par mesure DOM réelle, pas seulement en relisant le CSS.
- `.nav-b:active` et `.st-tab:active` : confirmé via `document.querySelector('.nav-b:active')` pendant un `mousePressed` maintenu (sans relâcher) — le sélecteur matche bien et `transform` vaut `matrix(0.94,0,0,0.94,0,0)`. Capture : `docs/design/screenshots/61-story05-navb-active-pressed.png`, `62-story05-sttab-active-pressed.png`.
- `focus-visible` : **piège évité** — un `.focus()` appelé depuis la console ne déclenche PAS `:focus-visible` sous Chromium (heuristique du navigateur : un focus programmatique n'est pas traité comme "d'origine clavier"). Testé une seconde fois avec de **vraies touches Tab simulées** (`Input.dispatchKeyEvent`) → confirmé fonctionnel (`e.matches(':focus-visible')` → `true`, anneau bleu visible, capture `64-story05-realtab-focus.png`). Sans ce deuxième test, j'aurais pu croire à tort que le focus ne marchait pas.
- `.is-disabled` : classe formalisée dans `style.css` comme demandé, mais **aucune application dans `app.js`** — après recherche, aucun bouton de l'app n'est actuellement "désactivé" au sens strict (les boutons de filtre GB à `opacity:.5` sont un pattern différent : "non sélectionné" mais toujours cliquable, pas "désactivé"). Je n'ai pas inventé un nouveau cas d'usage pour justifier la classe — elle est prête à être utilisée dès qu'un vrai bouton désactivable apparaîtra.

**Fichiers modifiés** : `style.css` uniquement (+`.nav-b:active`, +`.st-tab:active`, +`.is-disabled`, +`:focus-visible` global). `sw.js` (v53→v54). `app.js` non touché.

**Non-régression Match** : `.act-h:active`/`.btn:active` déjà en place, non modifiés — vérifié par lecture du diff (aucune ligne touchée sur ces sélecteurs).
