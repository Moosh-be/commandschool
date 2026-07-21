# CommandSchool

**Ce que ton ordinateur sait que tu ne sais pas.**

---

## Le concept

CommandSchool est un outil CLI de sensibilisation à la culture numérique pour Windows.

Chaque fois que tu lances la commande, ton ordinateur révèle un mécanisme invisible qui tourne en permanence — et t'explique ce que cette information peut t'apprendre sur ton environnement professionnel.

La phrase qu'on veut provoquer :

> *"Je ne savais pas que mon ordinateur savait ça."*

## Démarrage rapide

En quelques secondes, commence à explorer :

```cmd
cmdschool random
```

```powershell
.\cmdschool.ps1 random
```

Ensuite :

```powershell
.\cmdschool.ps1 list        # Voir toutes les découvertes
.\cmdschool.ps1 categories   # Explorer par catégorie
.\cmdschool.ps1 discover whoami  # Découverte spécifique
```

## Utilisation

### Depuis CMD (recommandé)

```cmd
shell\cmdschool.cmd random
shell\cmdschool.cmd discover vaultcmd
shell\cmdschool.cmd list
shell\cmdschool.cmd categories
shell\cmdschool.cmd history
```

### Depuis PowerShell

```powershell
# Découverte aléatoire
pwsh ./shell/cmdschool.ps1 random

# Découverte spécifique
pwsh ./shell/cmdschool.ps1 discover vaultcmd

# Parcourir toutes les découvertes
pwsh ./shell/cmdschool.ps1 list

# Explorer par catégorie
pwsh ./shell/cmdschool.ps1 categories

# Voir ton historique
pwsh ./shell/cmdschool.ps1 history
```

## Les découvertes

| Commande | Catégorie | Ce que tu découvres |
|---|---|---|
| `whoami` | Identité | Ton identité numérique réelle (pas juste un nom) |
| `hostname` | Identité | L'identité de ton ordinateur sur le réseau |
| `vaultcmd /list` | Authentification | Les identifiants que Windows garde pour toi |
| `klist tickets` | Authentification | Les tickets Kerberos, invisibles mais quotidiens |
| `ipconfig` | Réseau | Ta carte réseau : IP, passerelle, DNS |
| `net use` | Réseau & Partages | Les connexions réseau actives |
| `Get-ChildItem` | Fichiers & Registre | L'explorateur que tu ne vois jamais |
| `tasklist` | Processus | Tous les programmes cachés dans ta session |
| `systeminfo` | Système | L'identité complète de ton PC |

## Pourquoi ce projet ?

La culture numérique, ce n'est pas savoir taper des commandes. C'est comprendre que ton ordinateur *sait* des choses — et que tu peux les lui demander.

CommandSchool part du principe que chaque utilisateur Windows découvre des mécanismes invisibles qui deviennent utiles dès qu'un problème survient : Teams qui plante, OneDrive qui sync plus, un partage réseau inaccessible.

Pas d'administration système. Pas de scripts complexes. Juste de la curiosité satisfaite.

## Architecture

```
CommandSchool/
├── cmdschool.ps1           ← Point d'entrée racine (PowerShell)
├── cmdschool.cmd           ← Point d'entrée racine (CMD)
├── shell/
│   ├── cmdschool.ps1       ← Script principal
│   └── lib/
│       ├── DiscoveryStore.psm1 ← Parseur YAML maison
│       ├── DiscoveryRunner.psm1← Exécution de commandes
│       ├── StateManager.psm1  ← Historique des découvertes
│       └── Formatter.psm1     ← Rendu console coloré
├── discoveries/                ← Ajoute une discovery en créant un .yaml
│   └── vaultcmd.yaml
├── state/
│   └── state.json              ← Historique local (ignoré dans git)
├── DREAMLIST.md                ← Idées futures (pas implémentées)
├── FIRST_IMPRESSIONS.md        ← Retours du premier test
└── README.md
```

## Contribuer

### Signaler un bug

Tu as rencontré un problème ? Ouvre une issue sur le repo. Indique :
- Ta version Windows
- La commande qui pose problème
- Le message d'erreur si tu en as un

### Suggérer une commande

Tu veux une nouvelle découverte ? Ouvre une issue avec :
- Le nom de la commande Windows
- Ce que l'utilisateur voit
- Ce que ça signifie pour lui
- Exemples concrets d'utilisation

### Ajouter une découverte toi-même

1. Crée un fichier `discoveries/moncommand.yaml`
2. Remplis : `title`, `category`, `level`, `command`, `explanation`, `real_world_use_cases`
3. Relance `pwsh ./shell/cmdschool.ps1 list` pour vérifier

Le modèle complet est dans `discoveries/vaultcmd.yaml`.

## Feuille de route

### V1 — Windows (current)

Découvertes de commandes shell Windows (`cmd`, PowerShell, et exécutables natifs).

### Prochaines étapes

| Plateforme | Mode | Statut |
|---|---|---|
| Windows | Exécution + Lecture seule | ✅ V1 |
| macOS | Lecture seule | 🔜 |
| Linux | Lecture seule | 🔜 |
| NAS (Synology, QNAP) | Lecture seule | 🔜 |
| Raspberry Pi | Lecture seule | 🔜 |

### Les deux modes

**Mode Exécution** : la commande est réellement lancée sur le système. L'utilisateur voit le résultat en temps réel. Disponible sur Windows.

**Mode Lecture seule** : la découverte s'affiche avec des exemples et explications, sans exécuter de commande. C'est le mode par défaut sur les plateformes qui ne permettent pas l'exécution directe (iOS, Android, NAS, etc.).

## Technologies

- PowerShell (compatible PS 5.1 et PS 7)
- YAML pour les discoveries
- 0 dépendance externe

## Licence

MIT
