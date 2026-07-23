# Design — Rappel de sauvegarde (F3)

*Produit par le Designer — squad build BMAD*
*S'appuie sur `docs/prd.md` (F3)*

## Contexte

`exportAllMatches()` existe déjà mais rien n'attire l'attention dessus. Objectif : un rappel discret, pas un pop-up intrusif qui casse le flux post-match.

## Maquette ASCII — Onglet Bilan

```
┌─────────────────────────────────────┐
│  BILAN                    [Saison▼] │
├─────────────────────────────────────┤
│  ┌───────────────────────────────┐  │
│  │ 💾 Dernière sauvegarde: jamais │  │  ← bandeau discret, une ligne
│  │              [Exporter →]      │  │
│  └───────────────────────────────┘  │
│                                     │
│  [ liste des matchs / saison ... ] │
└─────────────────────────────────────┘
```

## Interactions

- Le bandeau n'apparaît que dans l'onglet Bilan (pas en plein match — jamais distraire pendant la saisie).
- Au clic sur "Exporter", déclenche `exportAllMatches()` existant (aucun nouveau flux technique).
- Après export réussi, le bandeau affiche "Dernière sauvegarde : à l'instant" (état local, pas besoin de persister au-delà de la session si trop complexe — à trancher avec l'Architect).

## États

- **Jamais exporté** : bandeau ton neutre, incite sans culpabiliser.
- **Exporté récemment** : bandeau discret, presque invisible (ne pas sur-solliciter l'attention une fois le geste fait).

## Composants réutilisés

- Le flux d'export existant (`exportAllMatches`, `showExportModal`/fallback clipboard) — aucun nouveau mécanisme de fichier à créer, seulement l'exposition visuelle.
