# =============================================================================
# cmdschool.ps1
# Point d'entrée unique de CommandSchool
# =============================================================================
#
# Utilisation :
#   pwsh ./shell/cmdschool.ps1 discover [nom]    Découverte aléatoire ou spécifique
#   pwsh ./shell/cmdschool.ps1 list               Lister toutes les discoveries
#   pwsh ./shell/cmdschool.ps1 random             Découverte aléatoire
#   pwsh ./shell/cmdschool.ps1 categories         Lister les catégories
#   pwsh ./shell/cmdschool.ps1 history [n]        Historique (n dernières)
#   pwsh ./shell/cmdschool.ps1 help               Affiche l'aide
#   pwsh ./shell/cmdschool.ps1 about              Informations sur CommandSchool
#
# Exemples :
#   pwsh ./shell/cmdschool.ps1 discover vaultcmd
#   pwsh ./shell/cmdschool.ps1 discover           # Découverte aléatoire
#   pwsh ./shell/cmdschool.ps1 list               # Toutes les découvertes
#   pwsh ./shell/cmdschool.ps1 categories         # Liste des catégories
#   pwsh ./shell/cmdschool.ps1 random             # Découverte aléatoire
#   pwsh ./shell/cmdschool.ps1 history            # Historique des 10 dernières
#   pwsh ./shell/cmdschool.ps1 history 5          # Historique des 5 dernières
#   pwsh ./shell/cmdschool.ps1 help               # Aide
#   pwsh ./shell/cmdschool.ps1 about              # À propos
# =============================================================================

# Définir le niveau d'erreur
$ErrorActionPreference = "Stop"

# =============================================================================
# Chargement des modules
# =============================================================================

# Déterminer le chemin racine du projet
# PSScriptRoot est toujours défini pour les scripts (pas pour les modules)
$scriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($scriptDir)) {
    $scriptDir = Split-Path (Get-Location).Path -Parent
}
$global:CommandSchoolBaseDir = Split-Path $scriptDir -Parent
$script:CommandSchoolLibDir = Join-Path $scriptDir "lib"

# Vérifier que les modules existent
$requiredModules = @("DiscoveryStore.psm1", "DiscoveryRunner.psm1", "StateManager.psm1", "Formatter.psm1")
foreach ($module in $requiredModules) {
    $modulePath = Join-Path $script:CommandSchoolLibDir $module
    if (-not (Test-Path $modulePath)) {
        Write-Error "Module manquant : $module"
        Write-Error "Le dossier shell/lib/ doit contenir tous les modules nécessaires."
        exit 1
    }
    Import-Module $modulePath -Force -ErrorAction Stop
}

# =============================================================================
# Fonction principale
# =============================================================================

function Main {
    param(
        [Parameter(Position = 0)]
        [string]$Command = "",

        [Parameter(Position = 1)]
        [string]$Argument = ""
    )

    switch ($Command.ToLower()) {
        "" {
            # Pas de commande : afficher l'aide
            Format-DiscoveryHelp
        }

        "discover" {
            # Découverte spécifique ou aléatoire
            if ([string]::IsNullOrWhiteSpace($Argument)) {
                Discover-Random
            } else {
                Discover-ByName $Argument
            }
        }

        "random" {
            # Découverte aléatoire
            Discover-Random
        }

        "list" {
            # Lister toutes les découvertes
            $discoveries = Get-AllDiscoveries
            Format-DiscoveryList -Discoveries $discoveries
        }

        "categories" {
            # Lister les catégories
            $discoveries = Get-AllDiscoveries
            $categories = $discoveries | Select-Object -ExpandProperty category | Sort-Object -Unique

            Write-Host ""
            Write-Host "  Catégories disponibles :`n" -ForegroundColor Cyan

            foreach ($cat in $categories) {
                $count = ($discoveries | Where-Object { $_.category -eq $cat }).Count
                Write-Host "  - $cat ($count découverte(s))" -ForegroundColor Yellow
            }

            Write-Host ""
        }

        "history" {
            # Afficher l'historique
            $count = 10
            if (-not [string]::IsNullOrWhiteSpace($Argument)) {
                $count = [int]$Argument
            }
            Get-CommandSchoolHistory -Count $count
        }

        "about" {
            # Afficher les informations sur CommandSchool
            Format-About
        }

        "help" {
            # Afficher l'aide
            Format-DiscoveryHelp
        }

        default {
            # Commande inconnue : afficher l'aide
            Write-Host ""
            Write-Host "  Commande inconnue : '$Command'" -ForegroundColor Red
            Write-Host ""
            Format-DiscoveryHelp
        }
    }
}

# =============================================================================
# Fonctions de découverte
# =============================================================================

function Discover-Random {
    <#
    .SYNOPSIS
        Affiche une découverte aléatoire
    .DESCRIPTION
        Sélectionne une discovery au hasard parmi toutes celles disponibles,
        exécute sa commande, et affiche le résultat formaté.
    #>
    $discoveries = Get-AllDiscoveries

    if ($discoveries.Count -eq 0) {
        Write-Host ""
        Write-Host "  Aucune découverte disponible dans le dossier discoveries/." -ForegroundColor Red
        Write-Host "  Ajoute des fichiers .yaml pour commencer." -ForegroundColor DarkGray
        Write-Host ""
        return
    }

    # Sélection aléatoire (exclut la dernière découverte si possible)
    $state = Get-CommandSchoolState
    $available = $discoveries
    if ($state.lastdiscovery) {
        $available = $discoveries | Where-Object { $_.title -ne $state.lastdiscovery }
    }
    if ($available.Count -eq 0) {
        $available = $discoveries
    }

    $randomIndex = Get-Random -Minimum 0 -Maximum $available.Count
    $discovery = $available[$randomIndex]
    Discover-Execute $discovery | Out-Null
}

function Discover-ByName {
    <#
    .SYNOPSIS
        Affiche une découverte spécifique par son nom
    .DESCRIPTION
        Charge une discovery par son nom (sans extension), exécute sa commande,
        et affiche le résultat formaté.
    .PARAMETER Name
        Nom de la découverte (ex: "vaultcmd")
    #>
    param([string]$Name)

    $discovery = Get-DiscoveryByName $Name

    if (-not $discovery) {
        Write-Host ""
        Write-Host "  Discovery '$Name' non trouvée." -ForegroundColor Red
        Write-Host ""

        # Suggérer des discoveries disponibles
        Write-Host "  Découvertes disponibles :" -ForegroundColor Yellow
        $discoveries = Get-AllDiscoveries
        foreach ($d in ($discoveries | Sort-Object title)) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($d._file)
            Write-Host "    - $baseName : $($d.title)" -ForegroundColor DarkGray
        }
        Write-Host ""
        return
    }

    Discover-Execute $discovery | Out-Null
}

function Discover-Execute {
    <#
    .SYNOPSIS
        Exécute une discovery et affiche le résultat
    .DESCRIPTION
        1. Exécute la commande de la discovery
    .PARAMETER Discovery
        L'objet discovery à exécuter
    #>
    param([hashtable]$Discovery)

    $command = $Discovery.command
    Write-Host ""
    Write-Host "  Exécution de : $command ..." -ForegroundColor DarkGray

    # Exécuter la commande
    $result = Invoke-CommandSchoolCommand -CommandLine $command

    # Formater et afficher la découverte
    Format-DiscoveryOutput -Discovery $Discovery -CommandResult $result

    # Ajouter à l'historique
    $discoveryName = [System.IO.Path]::GetFileNameWithoutExtension($Discovery._file)
    Add-CommandSchoolHistory -DiscoveryName $discoveryName | Out-Null
}

# =============================================================================
# Exécution
# =============================================================================

# Chemin de base (utile pour les modules)
$script:CommandSchoolBase = Split-Path $script:PSCommandPath -Parent

# Récupérer les arguments depuis $args (compatible PS 5.1 et PS 7)
$argCount = $args.Count
if ($argCount -ge 2) {
    $cmd = $args[0]
    $arg = $args[1]
} elseif ($argCount -ge 1) {
    $cmd = $args[0]
    $arg = ""
} else {
    $cmd = ""
    $arg = ""
}

Main -Command $cmd -Argument $arg
