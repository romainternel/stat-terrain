# STORY-29 — Audit de lisibilité global (Designer) + corrections

## Origine
Romain a demandé une vérification globale de lisibilité de l'app ("est-ce que la BMAD a fait une vérification totale que tout était lisible ?"), au-delà de l'audit étroit de STORY-16. Le Designer a été convoqué pour une revue à froid, avec captures d'écran réelles (iPad/iPhone, portrait/paysage, 6 écrans différents).

## Constats retenus (verdict Designer)
1. **Panneau ⚙ Réglages trop plat** — 9 boutons empilés sans hiérarchie visuelle, "Sauvegarder" au même niveau que "Se déconnecter".
2. **Barre d'actions coupée sur iPhone portrait** — PO et Jet franc hors écran ; un scroll horizontal existait déjà (ajouté lors d'un correctif précédent) mais l'indice visuel (ombre discrète 1px) était trop subtil pour être perçu d'un coup d'œil en conditions réelles de match.
3. Reste de l'app (mode lecteur, indicateur de sync, écran Équipes, Stats) : conforme, rien à retirer — le problème n'était pas "trop de fonctions" mais un manque de hiérarchie à ces deux endroits précis.

## Correctifs appliqués
- Panneau Réglages réorganisé en 3 groupes avec labels discrets (`Match` / `Affichage` / `Compte`) séparés par une fine bordure — nouvelle classe CSS `.settings-group-label`.
- Indice de scroll de la barre d'actions (iPhone portrait) remplacé par un dégradé de fondu plus visible (`.ml-actions::after`) au lieu de l'ombre insérée précédente. Vérifié par test réel CDP : la barre reste scrollable, PO et Jet franc redeviennent atteignables après scroll.

## Notes
- Aucun élément n'a été supprimé — le Designer n'a identifié aucun cas de fonctionnalité à retirer pour cause de surcharge.
- Vérification faite directement (captures CDP avant/après), pipeline `/verifie` complet jugé disproportionné pour un changement CSS/markup pur sans logique modifiée (aucun id/attribut de binding touché).

## Taille
S
