# Workflow — Roadmap & Progression

## Quand l'utiliser
- En début de saison (planification)
- Quand Romain a plusieurs idées à prioriser
- Après un audit complet

## Étapes

### 1. Collecte des inputs
Sources :
- Rapport SCOUT (dette technique)
- Rapport TERRAIN (frictions UX)
- Idées de Romain
- Retours staff FENIX

### 2. COACH — Scoring de chaque item

Pour chaque item, COACH applique la matrice :

```
Impact (1-5) × Effort inversé (1-5) = Score priorité
```

**Impact** :
- 5 = Améliore la fiabilité en match
- 4 = Améliore la qualité des données
- 3 = Améliore le confort d'utilisation
- 2 = Améliore l'analyse post-match
- 1 = Cosmétique / nice-to-have

**Effort inversé** (moins d'effort = score plus élevé) :
- 5 = <30 min dev
- 4 = 30min-2h dev
- 3 = 2h-4h dev
- 2 = 4h-1j dev
- 1 = >1 jour dev

### 3. FENIX — Roadmap consolidée

Grouper par cycles :
- **Cycle Immédiat** (score ≥20) : à faire dans les 2 semaines
- **Cycle Court** (score 12-19) : dans le mois
- **Cycle Moyen** (score 6-11) : dans la saison
- **Backlog** (score <6) : à réévaluer plus tard

## Backlog actuel (à compléter avec les audits)

| ID | Feature | Impact | Effort inv. | Score | Cycle |
|----|---------|--------|-------------|-------|-------|
| F01 | Undo dernière action (1 tap) | 4 | 4 | 16 | Court |
| F02 | jsPDF bundlé (hors-ligne) | 3 | 3 | 9 | Moyen |
| F03 | Export CSV complet | 3 | 4 | 12 | Court |
| F04 | Mode lecture seule (partage QR) | 2 | 2 | 4 | Backlog |
| F05 | Comparaison matchs multi-saison | 3 | 2 | 6 | Backlog |
| F06 | Raccourci TM (1 tap direct) | 4 | 5 | 20 | Immédiat |
| F07 | Indicateur tirs par zone (heatmap) | 3 | 3 | 9 | Moyen |
| F08 | Sauvegarde auto cloud (backup) | 5 | 2 | 10 | Moyen |
| F09 | Notes vocales par action | 2 | 1 | 2 | Backlog |
| F10 | Vibration haptic sur validation | 3 | 5 | 15 | Court |

## Règles de la roadmap
1. Max **3 items P1** simultanés (éviter la dispersion)
2. Chaque item a des **critères d'acceptation** clairs avant dev
3. Aucun item P2+ n'entre en dev sans être passé par SCOUT (faisabilité single-file)
4. La roadmap est **revue après chaque match de saison**

## Commande de mise à jour
```
COACH roadmap → affiche le tableau complet
COACH prioriser [description] → analyse un nouvel item
FENIX status → état d'avancement global
```
