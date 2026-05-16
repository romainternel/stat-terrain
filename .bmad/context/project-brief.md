# Project Brief — CF FENIX STAT

## Contexte
Application de statistiques handball en direct pour le **Centre de Formation du FENIX Toulouse** (Starligue). Utilisée pendant les matchs de **Nationale 1** sur **iPad en bord de terrain**.

## Stack technique
- Single-file HTML (~4000 lignes) — CSS + JS + assets base64 dans `index.html`
- Vanilla JS, pas de framework
- État global : objet `S` (State)
- Rendu : fonction `R()` via `innerHTML` complet (double-buffer anti-flicker)
- Stockage : IndexedDB (`dbSaveMatch`, `dbGetAll`, `dbDelete`)
- PWA : `sw.js` (cache v25) + `manifest.json`
- PDF : jsPDF via CDN
- Déployé sur **Netlify** : fenix-statscf.netlify.app

## Utilisateurs cibles
- **Romain** (responsable CF) — utilisateur principal, iPad en match
- Staff technique FENIX — consultation des stats après match

## Contraintes critiques
1. **Single-file** — tout doit rester dans `index.html`
2. **iPad Safari** — touch, viewport 100dvh, safe-area, scrolling webkit
3. **Hors-ligne** — SW cache, pas de dépendance réseau en match
4. **Zéro crash** — fiabilité absolue pendant les 60 minutes de match
5. **JS valide** — toujours vérifier avec `new Function()` avant livraison

## Métriques de qualité actuelles
- Version SW : v25 (indique ~25 itérations de déploiement)
- Lignes de code : ~4000
- Fonctionnalités : match live, stats, bilan, gestion équipes, alertes auto, PDF

## Zones de risque identifiées
- Taille du fichier (4000L) → lisibilité et maintenance
- Render via `innerHTML` complet → potentiel re-render inutile
- jsPDF via CDN → dépendance réseau pour export PDF
- Pas de tests automatisés → régression possible à chaque itération
