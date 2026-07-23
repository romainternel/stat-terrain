# STORY-16 — Clarté de l'interface pour un aidant occasionnel

**En tant que** bénévole non-spécialiste qui aide Romain de temps en temps,
**Je veux** comprendre immédiatement quoi cliquer sans qu'on me forme,
**Afin de** pouvoir prendre le relais de la saisie sans stresser ni faire d'erreur difficile à corriger.

## Contexte technique

- Zone concernée : `style.css`/`app.js` — labels des boutons d'action (`.a-label`/`.ah-label`), bouton d'annulation (`undoLast()`).
- Pas de nouveau mode séparé — audit et durcissement de l'existant (cf. `docs/prd-v2-cloud-multiuser.md` F8 et `docs/design/acces-partage-et-reprise-match.md` section 4).

## Critères d'acceptation

- [ ] Chaque bouton d'action garde son icône ET son label texte visible (jamais l'icône seule).
- [ ] Le bouton d'annulation est aussi visible/accessible que les boutons d'action principaux, pas relégué dans un sous-menu.
- [ ] Test concret : une personne qui n'a jamais vu l'app arrive à saisir un but puis à l'annuler sans aide extérieure.
- [ ] Aucun ajout de tooltip/texte d'aide supplémentaire (resterait contraire au principe de simplicité) — uniquement des ajustements de lisibilité sur l'existant.

## Hors scope

- Un mode de saisie simplifié séparé (explicitement écarté — ajouterait de la complexité).

## Dépend de

Aucune.

## Taille

S
