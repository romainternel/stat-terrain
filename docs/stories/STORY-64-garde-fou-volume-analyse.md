# STORY-64 — L'Analyse automatique n'affiche plus de jugements hâtifs sur un match trop court

**En tant que** Romain,
**Je veux** que les insights qualitatifs (PD, pertes de balle, séries, efficacité par tranche) n'apparaissent que sur un volume d'événements représentatif,
**Afin de** ne pas afficher un jugement absurde ("jeu trop individuel") sur un match écourté ou une mi-temps interrompue.

Suggestion de l'Audit Final du 2026-08-20 (`docs/audit-final/AUDIT-2026-08-20.md`), trouvée sur un match de test à seulement 5 tirs.

## Contexte technique
- Zone concernée : `autoAnalysis()` (`app.js:3207`, match en cours, Stats → Analyse) **et** `matchAnalysis(m)` (`app.js:3884`, match archivé, Bilan → Analyse) — deux fonctions dupliquées (cf. `CLAUDE.md`), le garde-fou doit être appliqué **aux deux** pour rester cohérent entre les deux écrans
- Nouvelle constante : `MIN_EVENTS_FOR_INSIGHTS = 10` (tirs cumulés des deux équipes, cf. `docs/arch/audit-corrections-et-mode-simple.md` section F3)
- Impact sur l'existant : aucun changement de structure de données, uniquement un `if(enoughData)` autour des blocs d'insights qualitatifs identifiés

## Critères d'acceptation
- [ ] Sur un match dont le total de tirs cumulés (`hTotal+aTotal`) est inférieur à 10, les insights suivants n'apparaissent plus : efficacité faible, pertes de balle, série de buts encaissés, analyse mi-temps, analyse PD, blocs d'efficacité par tranche de 10 min
- [ ] Le résultat (victoire/défaite/nul) et la ligne "Efficacité FENIX X% vs Adversaire Y%" restent **toujours** affichés, quel que soit le volume
- [ ] Sur un match au-dessus du seuil (≥10 tirs cumulés), le comportement est strictement identique à aujourd'hui — vérifié sur un match existant déjà couvert par un rapport QA (aucune régression)
- [ ] Le même garde-fou est appliqué à `autoAnalysis()` **et** `matchAnalysis(m)` — vérifié en comparant Stats → Analyse (match en cours) et Bilan → Analyse (même match une fois archivé) sur un match sous le seuil : les deux écrans doivent masquer les mêmes insights
- [ ] `new Function()` passe sur `app.js` modifié

## Hors scope
- Seuil personnalisable par l'utilisateur (seuil fixe dans le code)
- Message explicite "pas assez de données" (la liste plus courte est auto-explicite, cf. Design)
- Différencier les insights positifs des insights à charge (tous gérés par le même seuil pour cette itération, cf. `docs/risks/audit-corrections-et-mode-simple.md` R4)

## Dépend de
Aucune

## Taille
S
