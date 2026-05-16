# BMAD Squad — FENIX Stats CF

Squad multi-agents pour l'évaluation, l'audit et la progression de l'app.

## Démarrage rapide

### Je veux un audit complet
```
Invoke agent FENIX : lance une session audit-complet
```

### Je veux valider un déploiement
```
Invoke agent FENIX : sprint-review — j'ai modifié [ce qui a changé]
```

### J'ai une idée de feature
```
Invoke agent FENIX : idee — [description de l'idée]
```

### Je veux voir la roadmap
```
Invoke agent COACH : roadmap
```

---

## Les 4 agents

```
┌─────────────────────────────────────────────────────────┐
│                    FENIX (Orchestrateur)                  │
│         Coordonne • Synthétise • Décide                   │
└────────────┬──────────────┬──────────────────────────────┘
             │              │              │
      ┌──────▼──────┐ ┌─────▼──────┐ ┌───▼──────────┐
      │    SCOUT    │ │  TERRAIN   │ │    COACH     │
      │  Auditeur   │ │  Analyste  │ │   Product    │
      │  Technique  │ │     UX     │ │    Owner     │
      └─────────────┘ └────────────┘ └──────────────┘
```

## Structure des fichiers

```
.bmad/
├── README.md              ← ce fichier
├── team.md                ← définition du squad
├── agents/
│   ├── fenix.md           ← orchestrateur
│   ├── scout.md           ← audit technique
│   ├── terrain.md         ← audit UX
│   └── coach.md           ← product owner / roadmap
├── workflows/
│   ├── audit-complet.md   ← audit avant déploiement
│   ├── sprint-review.md   ← review post-dev
│   └── roadmap-progression.md ← planification
└── context/
    └── project-brief.md   ← contexte app pour les agents
```

## Utilisation avec Claude Code

Copie-colle l'un de ces prompts dans Claude Code :

**Audit complet :**
> Tu es le squad BMAD de FENIX Stats. Lis `.bmad/team.md` et les agents dans `.bmad/agents/`. Lance le workflow `audit-complet` sur l'état actuel de `index.html`.

**Sprint review :**
> Tu es le squad BMAD de FENIX Stats. Lance un `sprint-review`. J'ai [décris les changements].

**Évaluer une idée :**
> Tu es COACH du squad BMAD FENIX Stats. Évalue cette idée et positionne-la dans la roadmap : [idée].
