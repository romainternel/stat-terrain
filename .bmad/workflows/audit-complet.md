# Workflow — Audit Complet FENIX Stats

## Quand l'utiliser
- Avant un déploiement majeur
- Après une session de dev intense (>200 lignes modifiées)
- En début de saison ou après une pause longue

## Étapes

### Étape 1 — Briefing (FENIX)
**Input** : version SW actuelle, liste des changements depuis dernier audit
**Action** : FENIX brief les agents avec le contexte
**Output** : contexte partagé

---

### Étape 2 — Audit technique (SCOUT)
**Commande** : `SCOUT audit-complet`

**Checklist SCOUT** :
- [ ] Vérifier `new Function(jsCode)` sur tout le JS
- [ ] Identifier les fonctions >100 lignes
- [ ] Contrôler la gestion d'erreurs IndexedDB
- [ ] Tester les edge cases : 0 joueurs, 60+ événements, swap de GB
- [ ] Vérifier que le SW cache est correct (version incrémentée)
- [ ] Analyser les risques de la dépendance jsPDF CDN
- [ ] Comptabiliser les lignes (seuil alerte : >5000 lignes)

**Output** : Rapport SCOUT structuré

---

### Étape 3 — Audit UX (TERRAIN)
**Commande** : `TERRAIN eval-complete`

**Checklist TERRAIN** :
- [ ] Tracer le flux BUT complet (taps + timing)
- [ ] Tracer le flux TM urgence
- [ ] Tracer le flux correction d'erreur
- [ ] Vérifier tailles des zones tactiles (≥44px iOS)
- [ ] Vérifier la lisibilité du score/timer
- [ ] Tester le comportement paysage + portrait
- [ ] Évaluer les alertes automatiques

**Output** : Rapport TERRAIN structuré

---

### Étape 4 — Priorisation (COACH)
**Commande** : `COACH recap-audit`

**Action** : COACH transforme les findings SCOUT + TERRAIN en items backlog
**Output** : Backlog mis à jour avec P0/P1/P2/P3

---

### Étape 5 — Rapport final (FENIX)
**Action** : FENIX consolide et calcule le score de santé
**Output** : Rapport FENIX daté → archivé dans `reports/YYYY-MM-DD-audit.md`

## Durée estimée
- Audit complet avec Claude : ~30-45 minutes
- Audit rapide (SCOUT seul, fiabilité) : ~10 minutes

## Critères de passage (SHIP/HOLD)

| Critère | SHIP | HOLD |
|---------|------|------|
| Score Technique | ≥7/10 | <7/10 |
| Score UX | ≥7/10 | <6/10 |
| Items P0 | 0 | ≥1 |
| JS valid (`new Function`) | ✓ | ✗ |
