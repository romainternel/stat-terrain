# Workflow — Sprint Review

## Quand l'utiliser
Après chaque session de développement / déploiement (même petite)

## Étapes rapides

### 1. FENIX — Contexte du sprint
Lister :
- Quoi a changé ? (fonctionnalité / fix / refacto)
- Combien de lignes modifiées ?
- Version SW incrémentée ?

### 2. SCOUT — Vérification ciblée
Focus sur les zones modifiées uniquement :
- Le JS modifié passe `new Function()` ?
- Des edge cases introduits ?
- Des fonctions existantes cassées ?

### 3. TERRAIN — Test UX du changement
- Le nouveau comportement est intuitif ?
- Le flux modifié est plus rapide qu'avant ?
- Régression UX détectée ?

### 4. COACH — Validation critères
- Les critères d'acceptation du backlog sont remplis ?
- L'item peut être marqué ✅ DONE ?
- Des items connexes débloqués ?

### 5. FENIX — Verdict
```
SHIP ✅    → Déployer sur Netlify
ITERATE 🔄 → Corriger avant déploiement
REVERT ⚠️  → Rollback, analyser root cause
```

## Template sprint review rapide

```markdown
## Sprint Review — [Date]

### Ce qui a changé
- [feature/fix]

### SCOUT (technique)
- Verdict : ✅ / ⚠️ / ❌
- Notes : ...

### TERRAIN (UX)
- Verdict : ✅ / ⚠️ / ❌
- Notes : ...

### COACH (backlog)
- Items validés : [IDs]
- Items débloqués : [IDs]

### FENIX — Décision finale
**SHIP / ITERATE / REVERT**
Raison : ...
```
