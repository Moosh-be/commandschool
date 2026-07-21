# First Impressions

## Ce que j'ai appris

- Windows stocke des identifiants que je ne savais même pas existaient (Credential Vault)
- `whoami` ne retourne pas juste un nom : derrière il y a un SID, des groupes, des tokens
- `VaultCmd /list` révèle concrètement ce que Windows garde en mémoire
- Les commandes CLI existent pour explorer le système, même si on ne les voit jamais

## Ce qui m'a surpris

- La puissance d'un parser YAML écrit en 200 lignes de PowerShell
- Le fait qu'on puisse créer un outil complet sans aucune dépendance externe
- `klist` existe et révèle les tickets Kerberos — un mécanisme invisible mais quotidien

## Ce qui fonctionne bien

- Le parseur YAML est fiable
- La structure YAML est claire et modifiable par un non-développeur
- Le rendu console est lisible et structuré
- Les cas d'usage réels parlent (Teams, OneDrive, SharePoint, SSO)
- `list` et `categories` donnent une vue d'ensemble immédiatement

## Ce qui manque

- Pagination : il faut remonter dans le terminal pour relire le début
- Un raccourci pour lancer la commande directement (pas juste l'afficher)
- Les discoveries manquent de variété (8 seulement, pas de PowerShell)
- `history` affiche mais sans indication de format clair

## Ce qui m'a donné envie de continuer

- Le sentiment de découverte réelle : "je ne savais pas que mon ordinateur savait cela"
- Voir le résultat concret d'une commande sur MA machine
- La sensation que chaque découverte est un mini-cadeau
- La simplicité d'ajout d'une nouvelle discovery
