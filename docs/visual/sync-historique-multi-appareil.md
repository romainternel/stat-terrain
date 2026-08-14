# Visual Crafter — Synchronisation de l'historique des matchs

Peu de surface visuelle nouvelle — le Design s'appuie volontairement sur `showToast()` et le style texte discret déjà utilisés ailleurs (indicateur de sync STORY-15). Mon rôle : m'assurer que ce nouvel indicateur s'intègre sans créer un 2e vocabulaire visuel pour "quelque chose se synchronise".

## Cohérence avec l'indicateur de sync existant (STORY-15)
`computeSyncStatus()` utilise déjà des icônes `✓`/`↻`/`⚠` avec une palette précise (succès/en cours/hors-ligne). Réutiliser `🔄` pour "recherche en cours" ici est cohérent avec `↻` déjà utilisé pour "envoi…" — même famille d'icône rotative, pas une nouvelle métaphore. Couleur `var(--t3)` (déjà le ton le plus discret de la palette texte) pour ne pas rivaliser visuellement avec le titre de l'écran juste au-dessus.

## Toast "+N match(s) récupéré(s)"
`showToast()` existe déjà avec un paramètre `isAlert` pour le style rouge — ce toast n'est pas une alerte, style par défaut (neutre/informatif). Pas de nouvelle variante de toast à créer.

## Pas d'animation d'apparition pour les nouveaux matchs dans la liste
Volontairement aucun effet (fade-in, highlight) sur les lignes ajoutées après coup — le Design a explicitement choisi de ne pas distinguer visuellement un match rapatrié d'un match local ("un seul historique unifié"), une animation d'apparition créerait la distinction visuelle que le Design cherche justement à éviter. Cohérence entre les deux documents vérifiée avant de conclure.
