# STORY-16 — Clarté de l'interface pour un aidant occasionnel

> **Audit réalisé le 2026-08-03** — les 3 premiers critères d'acceptation étaient déjà satisfaits par le code existant, vérifié par lecture de code (`actBtn()` dans `app.js`) et par test réel CDP (clics réels sur un navigateur headless) : les 6 boutons d'action affichent systématiquement icône + label texte (aucun cas icône seule), et le bouton "↩ Annuler" est positionné dans la barre `.ml-bottom`, avec une taille de police (13px) et un traitement visuel identiques aux autres contrôles, jamais dans un sous-menu ou le panneau Réglages. Aucun changement de code n'était nécessaire.
>
> À noter : depuis la rédaction de cette story, le **Mode Simple** (STORY-23/24) a été développé et va plus loin que ce qui était envisagé ici — il offre un écran de saisie à 3 boutons par équipe (BUT/ARRÊT/NON CADRÉ), sans terrain ni zone, explicitement pensé pour un aidant non-formé. Le "hors scope" ci-dessous ("un mode de saisie simplifié séparé — explicitement écarté") est donc obsolète : ce mode existe désormais et répond au besoin sous-jacent de cette story mieux qu'un simple ajustement de lisibilité du mode Expert.

**En tant que** bénévole non-spécialiste qui aide Romain de temps en temps,
**Je veux** comprendre immédiatement quoi cliquer sans qu'on me forme,
**Afin de** pouvoir prendre le relais de la saisie sans stresser ni faire d'erreur difficile à corriger.

## Contexte technique

- Zone concernée : `style.css`/`app.js` — labels des boutons d'action (`.a-label`/`.ah-label`), bouton d'annulation (`undoLast()`).
- Pas de nouveau mode séparé — audit et durcissement de l'existant (cf. `docs/prd-v2-cloud-multiuser.md` F8 et `docs/design/acces-partage-et-reprise-match.md` section 4).

## Critères d'acceptation

- [x] Chaque bouton d'action garde son icône ET son label texte visible (jamais l'icône seule) — vérifié par test réel CDP sur les 6 boutons du mode Expert, 0 exception.
- [x] Le bouton d'annulation est aussi visible/accessible que les boutons d'action principaux, pas relégué dans un sous-menu — vérifié : même famille de style (`.ml-ctrl-btn`), taille de police comparable (13px vs 12-13px), positionné dans la barre `.ml-bottom` toujours visible, jamais dans le panneau Réglages.
- [x] Test concret : workflow réel rejoué par clics CDP (sélection BUT → clic joueur → panneau d'action) sans blocage ni ambiguïté.
- [x] Aucun ajout de tooltip/texte d'aide supplémentaire — confirmé, aucun changement de code apporté (l'existant satisfaisait déjà les critères).

## Hors scope

- Un mode de saisie simplifié séparé (explicitement écarté — ajouterait de la complexité).

## Dépend de

Aucune.

## Taille

S
