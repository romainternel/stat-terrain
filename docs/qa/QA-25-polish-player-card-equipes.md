# QA — STORY-25 : Polish visuel de la carte joueur (Équipes)

## Méthode de test
Comparaison visuelle avant/après via CDP (Chrome DevTools Protocol) sur iPad (1024×768) et iPhone portrait réel (390×844), avec un effectif de test réaliste (joueurs sélectionnés/non sélectionnés, gardien, numéro manquant). Interactions vérifiées par vrais clics simulés (`Input.dispatchMouseEvent`), pas de simulation d'état.

## Critères d'acceptation — validation

| Critère | Statut | Détail |
|---|---|---|
| Badge numéro de maillot distinct | ✅ | Médaillon arrondi 34×34, bien visible, remplace le texte inline "#7" |
| État sélectionné visuellement fort | ✅ | Bordure d'accent latérale (4px) + glow sur le badge + fond éclairci — net changement par rapport à l'ancien style (juste une bordure sur le petit carré) |
| État non-sélectionné lisible | ✅ | Comparé avant/après : le texte reste net (pas d'opacité réduite sur le texte), seul le badge/accent est "éteint" — Nathan (non sélectionné) reste parfaitement lisible sur les deux captures |
| Couleur d'accent correcte par équipe | ✅ | Vérifié en lisant le CSS généré : `--pc-accent` vaut bien le triplet RGB attendu selon `side` ; corrige au passage une incohérence préexistante (`.sel-toggle.on` était câblé en dur sur le bleu FENIX même pour l'adversaire) |
| Badge GB plus visible | ✅ | Icône 🧤 ajoutée, contraste/taille augmentés |
| Bouton supprimer plus visible | ✅ | Repositionné en flex (fin de ligne, ne chevauche plus le contenu), taille et contraste augmentés |
| Aucune régression fonctionnelle | ✅ | Testé par vrais clics : toggle de sélection (Nathan, false→true confirmé), suppression d'un joueur (Martin supprimé, compteur 4→3 confirmé) |
| Testé iPad + iPhone portrait | ✅ | Captures des deux tailles, aucun débordement, touch targets confortables |

## Cas limites testés
- Joueur sans numéro (`Nathan`, `number:""`) : badge affiche "–" (tiret, cohérent avec `displayNumber()` de STORY-21), pas de "?" ni de case vide moche.
- Joueur au nom "?" (en attente de saisie) : icône ✏️ toujours affichée normalement, non affectée par le changement.
- Effectif vide (équipe adverse) : aucun rendu de `.player-card`, pas d'erreur.

## Bugs trouvés
Aucun.

## Régressions détectées
Aucune. Sélection, désélection, suppression, ajout de joueur (non re-testé directement mais code non touché), édition nom/poste (code non touché) — tous fonctionnels ou non affectés.

## Verdict
**PASSED**

Tous les critères d'acceptation sont satisfaits. Amélioration visuelle nette et vérifiée concrètement (pas juste supposée), conformément à la leçon retenue depuis STORY-04.
