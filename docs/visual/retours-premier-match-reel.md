# Visual Crafter — Retours du premier match réel

## Bandeau de validation (M5)
Réutilise le langage visuel déjà établi pour `.readonly-banner` (bandeau plein-largeur, fond teinté, texte clair) plutôt qu'un nouveau style de carte flottante — cohérent avec "petite fenêtre" de Romain, pas une modale intrusive :
```css
.launch-warning-banner{ background:rgba(240,199,94,.10); border:1px solid rgba(240,199,94,.35);
  border-radius:8px; padding:8px 12px; margin:6px 8px; font-size:12px; }
.launch-warning-banner ul{ margin:4px 0 0; padding-left:18px; }
```
Icône ⚠️ en jaune (`--yellow`), pas rouge — c'est un rappel, pas une erreur bloquante ; réserver le rouge à ce qu'il signifie déjà ailleurs (encaissé, hors cadre).

## Pastille de rappel réduit
Petit point jaune (`.warn-dot`, même famille que `.dirty-chip`/`.gk-pill-dot` déjà utilisés — pas un nouveau composant) sur le bouton Réglages quand le bandeau a été réduit — discret mais toujours visible en périphérie, cohérent avec les indicateurs d'état déjà présents ailleurs (indicateur de sync).

## `per-btn` en état "attention"
```css
.per-btn.due{ border-color:var(--yellow); color:var(--yellow); animation:per-btn-pulse 1.6s ease-in-out infinite; }
@keyframes per-btn-pulse{ 0%,100%{box-shadow:0 0 0 rgba(240,199,94,0);} 50%{box-shadow:0 0 8px rgba(240,199,94,.5);} }
@media(prefers-reduced-motion:reduce){ .per-btn.due{ animation:none; } }
```
Pulsation douce, pas clignotante/agressive — un signal "à traiter quand tu as un instant", pas une alarme. S'arrête net dès le clic (classe retirée avec le changement de période).

## Highlight de sélection d'action (M2)
Le fix est purement la valeur de 2 variables CSS déjà référencées par du code existant (`.act-h.selected`) — aucun nouveau style à créer, juste vérifier au montage que le glow (`box-shadow`) et la bordure sont bien visibles sur fond sombre une fois les variables définies (contraste suffisant, pas à re-régler).
