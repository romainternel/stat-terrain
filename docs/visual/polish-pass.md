# Visual Spec — Passe de polish premium (F2) + composants F1/F3

*Produit par le Visual Crafter — squad build BMAD*
*S'appuie sur `docs/design/match-responsive-iphone.md` et `docs/design/data-safety-reminder.md`*

## Constat de départ

Le chantier visuel déjà mené (Inter, thème par possession `--accent`/`--accent-rgb`, glow sur `.ml-team-active` et `.mlt-poss-btn`) est la bonne direction — cette passe **étend** ce langage aux écrans qui ne l'ont pas encore (Stats, Bilan, Setup), plutôt que d'en inventer un nouveau.

## 1. Palette de tokens (existants, à réutiliser partout — ne pas en créer de nouveaux)

```css
--bg:#0F1923; --bg2:#162030; --bg3:#1C2B40;
--card:rgba(255,255,255,0.04); --border:rgba(255,255,255,0.10);
--green:#5FA8D3; --red:#E8465A; --blue:#5FA8D3; --yellow:#F0C75E;
--orange:#E88A4E; --purple:#9B7ECF; --text:#FFF;
--t2:rgba(210,228,242,0.78); --t3:rgba(255,255,255,0.28); --t4:rgba(255,255,255,0.07);
--fenix-navy:#1C2B40; --fenix-sky:#5FA8D3; --fenix-light:#A8CDE0;
--r1:6px; --r2:10px; --r3:14px;
--accent:var(--fenix-sky); --accent-rgb:95,168,211; /* devient var(--red)/232,70,90 si possession adverse */
```

**Nouveau token à ajouter** (manquant aujourd'hui, nécessaire pour uniformiser les élévations) :
```css
--shadow-card: 0 2px 12px rgba(0,0,0,.25);
--shadow-card-hover: 0 4px 20px rgba(0,0,0,.35);
--shadow-accent: 0 0 16px rgba(var(--accent-rgb),.18);
```

## 2. Typographie

Déjà en place (`Inter`, poids 400 à 900). Règle à généraliser sur tous les écrans (aujourd'hui inégal entre Match et Stats/Setup) :

| Niveau | Taille | Poids | Usage |
|---|---|---|---|
| Score / valeur clé | 44–52px | 900 | `.mlt-score`, gros totaux de stats |
| Titre de carte | 13px | 700, uppercase, letter-spacing .08em | `.card-t` — déjà cohérent, à généraliser aux cartes Stats/Bilan qui ne l'utilisent pas encore |
| Label bouton | 12–14px | 700, uppercase | boutons d'action |
| Texte secondaire | 12–13px | 500–600 | `var(--t2)` |

## 3. Ombres & effets

- **Cartes (`.card`, `.gk-stat`, blocs Stats/Bilan)** : ajouter `box-shadow:var(--shadow-card)` par défaut, `var(--shadow-card-hover)` au survol/tap (desktop only pour hover — sur tactile, l'effet actif suffit).
- **Éléments actifs par possession** (déjà fait pour `.ml-team-active`) : étendre le même principe de glow `var(--shadow-accent)` à tout élément qui représente "l'équipe qui a la possession/priorité" ailleurs dans l'app (ex : ligne surlignée dans un tableau Joueurs si on filtre par équipe).
- **Pas de glassmorphism supplémentaire** : le `--card` actuel (`rgba(255,255,255,.04)` + `backdrop-filter` déjà utilisé sur les overlays) suffit ; ajouter un blur sur des cartes fixes n'apporterait rien et coûterait en perf sur iPhone plus ancien.

## 4. États interactifs (à généraliser — aujourd'hui présents sur Match, absents ailleurs)

| État | Spec |
|---|---|
| `:active` (tap) | `transform:scale(.94–.96)` + `background` légèrement éclairci — déjà standard sur `.btn`, `.act-h`, à copier sur les boutons Stats/Bilan/Setup qui n'ont que `transition:all .15s` sans le `:active` réel |
| `hover` (si souris, ex. test sur desktop) | `box-shadow:var(--shadow-card-hover)`, jamais de changement de layout au hover |
| `focus` (clavier/VoiceOver) | `outline:2px solid var(--accent)` — actuellement `outline:none` global sur `button`/`input` sans remplacement, à corriger pour l'accessibilité |
| `disabled` | `opacity:.35`, `pointer-events:none` — pattern déjà utilisé sur `.player-card.dimmed`, à formaliser en classe utilitaire `.is-disabled` |

## 5. Micro-animations

| Composant | Transition | Durée | Easing |
|---|---|---|---|
| Bouton d'action sélectionné (`.act-h.selected`) | `box-shadow, background, border-color` | 150ms | ease (déjà en place) |
| Bandeau de sauvegarde (F3) | apparition | `opacity, transform:translateY` | 200ms | ease-out — jamais de rebond, ça doit être discret |
| Bascule d'orientation iPhone (F1) | aucune animation de layout — le reflow doit être instantané, une transition CSS sur `grid-template-columns` créerait un flash disgracieux pendant le redimensionnement |
| Toast alertes (`showToast`) | déjà `fadeIn` 250ms — à garder identique, ne pas ralentir un message qui doit attirer l'œil vite |

Règle générale : **rien au-dessus de 250ms**, aucune animation sur les éléments du terrain pendant la saisie (ne jamais ralentir le geste de pointage).

## 6. Checklist contraste WCAG (sur fond `--bg` #0F1923)

| Couleur texte | Ratio approx. sur fond sombre | Statut |
|---|---|---|
| `--text` #FFF | ~18:1 | OK |
| `--t2` rgba(210,228,242,.78) | ~11:1 | OK |
| `--t3` rgba(255,255,255,.28) | ~3.3:1 | ⚠️ limite — à réserver aux textes non essentiels (déjà le cas : labels secondaires), ne jamais l'utiliser pour un texte porteur d'info critique en match |
| `--fenix-sky` #5FA8D3 sur `--bg` | ~5:1 | OK pour texte ≥14px |
| `--yellow` #F0C75E sur `--bg` | ~10:1 | OK |

Point d'attention : `--t3` est déjà utilisé pour des labels de stats (`.gk-v .lbl`) — c'est acceptable car secondaire, mais ne pas l'étendre à des éléments qui portent une décision en direct.
