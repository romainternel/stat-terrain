# Brief — FENIX Stats : audit & évolution

*Produit par l'Analyst — squad build BMAD*

## 1. Contexte

FENIX Stats existe déjà et est en production (Netlify, `fenix-statscf.netlify.app`). L'historique git montre qu'un chantier visuel important vient d'être mené (police Inter, thème par possession, refonte du layout match en 3 colonnes, glow/bordures dynamiques). L'app n'est donc pas un point de départ vierge : c'est un audit + une passe d'amélioration ciblée sur une base déjà solide.

Romain (responsable du Centre de Formation FENIX Toulouse) déclenche ce cycle pour :
- faire un état des lieux objectif de ce qui existe,
- identifier ce qui manque ou frotte encore à l'usage,
- cadrer une suite de travail qui rende l'app **utilisable aussi bien sur iPhone que sur iPad**, tout en restant simple et en montant encore le niveau visuel ("graphiquement cool").

Contrainte explicite de Romain : ce projet doit rester **indépendant** des autres outils CF (notamment l'appli web de suivi CF présente sur sa machine) — pas de dépendance de code ni de données partagées entre les deux.

## 2. Problème

Aujourd'hui, l'app est documentée et pensée quasi exclusivement pour l'iPad ("Optimisé iPad" dans le CLAUDE.md du projet). Or Romain veut pouvoir prendre des stats **aussi depuis un iPhone**, en bord de terrain, dans les mêmes conditions de pression qu'un match (une main, jet d'œil rapide, pas de temps pour chercher un bouton). Le layout match actuel (grille 3 colonnes avec une colonne fixe de 240px) est pensé pour un écran large — sa dégradation sur un écran iPhone (portrait, plus étroit) n'a pas été validée explicitement.

Par ailleurs, le rendu visuel a déjà été retravaillé récemment, mais sans passage dédié d'un œil "polish premium" (ombres, micro-animations, cohérence des effets) — il y a probablement une marge entre "ça a l'air propre" et "ça a l'air premium".

Enfin, les données de match vivent uniquement en local (IndexedDB) sur l'appareil utilisé pendant le match — un point de vigilance si Romain change d'appareil (iPad ↔ iPhone) ou en cas de perte/casse.

## 3. Utilisateurs

- **Utilisateur principal (et unique aujourd'hui)** : Romain, responsable du Centre de Formation, en bord de terrain pendant les matchs de Nationale 1.
- **Contexte d'usage** : debout ou assis en bord de terrain, sous pression du direct, doit suivre le jeu en même temps qu'il saisit les actions. Zéro tolérance pour un workflow qui demande de réfléchir ou de chercher.
- **Appareil** : iPad aujourd'hui en priorité, iPhone à couvrir en usage équivalent (pas juste "ça s'affiche", mais "ça se saisit aussi vite").
- **Fréquence** : usage récurrent, un match à la fois (pas de multi-match simultané).

## 4. Vision

Une app FENIX Stats qui reste redoutablement simple à utiliser en plein match — sur iPad comme sur iPhone, à une main si besoin — et dont le rendu visuel donne immédiatement une impression premium quand on l'ouvre devant d'autres coachs.

## 5. Scope

**Dans le scope de ce cycle :**
- Audit du responsive existant et adaptation réelle du layout match pour iPhone (pas seulement un reflow, une vraie hiérarchie d'info adaptée au petit écran).
- Passe de polish visuel (Visual Crafter) sur les écrans clés, en continuité avec le chantier déjà engagé (Inter, thème possession), pas une re-refonte.
- Vérification et renforcement de la sécurité des données locales (export/sauvegarde) compte tenu d'un usage potentiel multi-appareils.
- Identification et correction des points de friction UX restants dans le workflow de saisie d'action.

**Hors scope :**
- Compte utilisateur, synchronisation cloud multi-appareils, backend serveur.
- Changement de stack (reste vanilla JS / IndexedDB / PWA — pas de framework).
- Toute dépendance ou partage de code avec l'autre appli web CF (suivi CF).
- Multi-utilisateur simultané sur un même match.

## 6. Critères de succès

- Une action de jeu se saisit en autant de taps sur iPhone que sur iPad, sans zone de clic trop petite ni élément coupé/caché.
- Le rendu est jugé visuellement "premium" (cohérence des ombres, transitions, hiérarchie) et pas seulement "propre".
- Aucune régression sur les fonctionnalités actuelles (alertes auto, stats GB, export PDF, gestion d'équipes).
- Le dossier `fenix/` reste autonome : aucun import ni dépendance vers un autre projet CF.

## 7. Questions en suspens

- Romain est-il le seul utilisateur en saisie, ou un membre du staff peut-il aussi saisir (pertinent pour savoir si on doit prévoir un mode "aide/formation" ou si la simplicité prime toujours sur la pédagogie) ?
- L'iPad reste-t-il l'appareil de référence en match officiel, l'iPhone servant plutôt de solution de secours/mobilité (ex : match à l'extérieur, tournoi) ? Ça change la priorité entre "iPhone parfait" et "iPhone correct en dépannage".
- Un export/sauvegarde régulier (CSV/JSON déjà existant) est-il déjà utilisé comme filet de sécurité, ou faut-il le rendre plus visible/automatique ?
- Remarque annexe (non bloquante) : un ancien dossier `.bmad/` avec des agents spécifiques au projet (coach, design, fenix, scout, stats, terrain) apparaît supprimé dans l'état git local mais toujours suivi par git — à confirmer que c'est un nettoyage volontaire avant de committer.
