# Risques — Stockage Supabase + saisie partagée

*Produit par le Risk Analyst — squad build BMAD*
*S'appuie sur `docs/architecture-supabase.md`*

## Tableau des risques

| # | Risque | Probabilité | Impact | Recommandation |
|---|---|---|---|---|
| 1 | **Événements jamais synchronisés si l'appareil est perdu/cassé avant le premier retour réseau.** L'outbox persiste en IndexedDB et se rattrape au retour du réseau, mais si l'appareil est détruit avant ça, les événements en attente sont perdus définitivement (le local restait la seule copie). | Faible à moyenne | Élevé (perte partielle d'un match) | Déclencher `flushOutbox()` le plus tôt possible (à chaque événement + toutes les 15s), pas seulement en fin de match. Envisager un bouton "forcer la sync" visible en cas de doute, dans la continuité de F3 du cycle 1 (rappel de sauvegarde). |
| 2 | **RLS mal configurée sur le canal Realtime** (Supabase applique les policies RLS aux souscriptions `postgres_changes`, mais ça doit être vérifié explicitement à l'implémentation — un oubli rend la synchronisation silencieusement inopérante plutôt que de lever une erreur claire). | Moyenne | Élevé (F6 ne fonctionne pas alors qu'il semble configuré) | Test explicite obligatoire avant livraison : ouvrir le même match sur deux appareils/onglets et vérifier qu'un événement saisi sur l'un apparaît bien sur l'autre en quelques secondes. Ne pas se fier uniquement à un test en local (localhost) — tester avec le vrai déploiement. |
| 3 | **Mot de passe partagé trop largement diffusé** (transmis verbalement à des bénévoles occasionnels au fil des matchs) → n'importe qui le connaissant a un accès total lecture/écriture, sans granularité (cohérent avec D2, mais ça reste un risque réel si le mot de passe circule au-delà des personnes de confiance). | Moyenne | Moyen (modification/suppression accidentelle, pas de fuite de données sensibles au sens propre — ce sont des stats de handball) | Garder la possibilité de changer le mot de passe facilement depuis le dashboard Supabase si besoin. S'appuyer sur les confirmations de suppression déjà existantes dans l'app (suppression d'événement avec confirmation) comme filet contre les erreurs de manipulation. |
| 4 | **Double saisie réelle** (pas un doublon technique, mais deux personnes qui saisissent la même action réelle sur leurs appareils respectifs en même temps) → stat faussée (ex : un but compté deux fois). | Faible à moyenne (l'usage réel reste "une personne active à la fois" la plupart du temps, mais Romain confirme que ça peut arriver) | Moyen (faussé mais visible et corrigible) | Aucune UI de résolution de conflit à construire spécifiquement — le fil d'événements déjà éditable/supprimable (existant dans l'app) suffit à corriger a posteriori. Ne pas sur-ingénierer ce cas rare. |
| 5 | **Friction ajoutée à l'ouverture de l'app** par l'écran d'accès (F7), alors qu'aujourd'hui l'app s'ouvre instantanément. | Élevée (c'est un changement direct et systématique) | Faible (gênant, pas bloquant) | Session persistée pour ne redemander le mot de passe que rarement (cf. décision Architecte) — vérifier concrètement que la session survit à une fermeture complète de Safari sur iPad/iPhone, pas seulement à un simple changement d'onglet. |
| 6 | **Clé anon Supabase visible côté client** (normal pour toute app Supabase sans backend serveur) combiné à une RLS plate (n'importe quel compte authentifié a accès total). | Faible (attaque ciblée improbable sur une app de stats d'un club amateur) | Faible à moyen si ça arrivait | Risque accepté explicitement (cohérent avec le choix architecture "un seul tenant, pas de données sensibles type identité/paiement") — à ne pas complexifier davantage pour ce projet. |
| 7 | **Dépassement de quota Supabase** (plan gratuit) sur plusieurs saisons d'accumulation d'événements. | Faible à court terme | Faible | Simple point de vigilance à surveiller dans le dashboard Supabase après une saison complète, pas une action à prendre maintenant. |

## Classement

- **P0** : aucun — rien ici ne doit bloquer le démarrage du développement, à condition que les P1 deviennent des critères d'acceptation explicites (pas juste des bonnes intentions).
- **P1 (critères d'acceptation obligatoires avant livraison)** : #1 (fréquence de flush + bouton de sync manuelle), #2 (test réel multi-appareils avant de considérer F6 "fait"), #5 (test réel de persistance de session sur iPad/iPhone Safari).
- **P2** : #3 (mot de passe partagé — vigilance opérationnelle, pas de dev supplémentaire), #4 (double saisie réelle — accepté, corrigible via l'existant).
- **P3** : #6 (clé anon exposée — accepté par design), #7 (quota — à surveiller, pas à traiter maintenant).

## Stories de mitigation recommandées

- **#1 → critère d'acceptation** ajouté à la story de synchronisation (pas une story séparée) : fréquence de flush + bouton "forcer la sync" si le PM valide son utilité.
- **#2 → critère d'acceptation obligatoire** de la story F6 : test explicite deux-appareils avant clôture.
- **#5 → critère d'acceptation** de la story F7 : test explicite de persistance de session sur device réel, pas seulement en navigateur desktop.
- **#3, #4, #6, #7** : aucune story dédiée, juste des points de vigilance documentés (opérationnels ou acceptés par design).
