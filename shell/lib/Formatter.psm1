# =============================================================================
# Formatter.psm1
# Rendu console du Markdown de CommandSchool
# =============================================================================

function Format-DiscoveryOutput {
    <#
    .SYNOPSIS
        Affiche une découverte formatée dans la console
    .DESCRIPTION
        Prend un objet discovery et un résultat de commande,
        et affiche le contenu formaté avec des couleurs et
        une mise en page lisible.
    .PARAMETER Discovery
        L'objet discovery (table de hachage)
    .PARAMETER CommandResult
        Le résultat de la commande (objet Invoke-CommandSchoolCommand)
    .PARAMETER ShowRawOutput
        Afficher le résultat brut de la commande ou non
    #>
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Discovery,

        [Parameter(Mandatory = $true)]
        [object]$CommandResult,

        [switch]$ShowRawOutput
    )

    # =====================================================================
    # En-tête
    # =====================================================================
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor DarkCyan
    Write-Host "                   CommandSchool                           " -ForegroundColor DarkCyan
    Write-Host "==============================================================" -ForegroundColor DarkCyan
    Write-Host ""

    # Titre de la découverte
    Write-Host "  $($Discovery.title)" -ForegroundColor Cyan
    Write-Host ""

    # Métadonnées
    $levelName = GetLevelName $Discovery.level
    Write-Host "  Catégorie : $($Discovery.category)" -ForegroundColor DarkGray
    Write-Host "  Niveau    : $levelName" -ForegroundColor DarkGray
    Write-Host ""

    # =====================================================================
    # Commande
    # =====================================================================
    Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  $($Discovery.command_title)" -ForegroundColor Yellow
    Write-Host "  $($Discovery.command)" -ForegroundColor Green
    Write-Host ""

    # =====================================================================
    # Ce que l'utilisateur voit
    # =====================================================================
    if ($Discovery.what_you_see) {
        Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Ce que tu vois :" -ForegroundColor Yellow
        Write-Host ""
        Write-MultiLineText $Discovery.what_you_see -ForegroundColor DarkYellow
        Write-Host ""
    }

    # =====================================================================
    # Résultat de la commande
    # =====================================================================
    Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Ce que ton ordinateur dit :" -ForegroundColor Yellow
    Write-Host ""

    if ($CommandResult.Success) {
        $outputLines = $CommandResult.Output -split "`r?`n"
        foreach ($line in $outputLines) {
            if ([string]::IsNullOrWhiteSpace($line)) {
                Write-Host "  "
            } else {
                Write-Host "  $line" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  $($CommandResult.Error -replace '\r?\n', '`r`n  ')" -ForegroundColor Red
        Write-Host ""
        Write-Host "  (La commande n'a pas pu être exécutée. Vérifie qu'elle est disponible sur ton système.)" -ForegroundColor DarkYellow
    }

    Write-Host ""

    # =====================================================================
    # Interprétation
    # =====================================================================
    if ($Discovery.explanation) {
        Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Ce que cela signifie :" -ForegroundColor Yellow
        Write-Host ""
        Write-MultiLineText $Discovery.explanation -ForegroundColor White
        Write-Host ""
    }

    # =====================================================================
    # Cas d'usage réels
    # =====================================================================
    if ($Discovery.real_world_use_cases -and $Discovery.real_world_use_cases.Count -gt 0) {
        Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Quand cela t'aide :" -ForegroundColor Yellow
        Write-Host ""

        for ($i = 0; $i -lt $Discovery.real_world_use_cases.Count; $i++) {
            $useCase = $Discovery.real_world_use_cases[$i]
            $pad = " " * (2 - ($i + 1).ToString().Length)
            Write-Host "  $($pad)$($i + 1)." -ForegroundColor DarkCyan
            Write-MultiLineText $useCase -ForegroundColor White
            Write-Host ""
        }
    }

    # =====================================================================
    # Pour aller plus loin
    # =====================================================================
    if ($Discovery.go_deeper -and $Discovery.go_deeper.Count -gt 0) {
        Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Pour aller plus loin :" -ForegroundColor Yellow
        Write-Host ""

        for ($i = 0; $i -lt $Discovery.go_deeper.Count; $i++) {
            $item = $Discovery.go_deeper[$i]
            $pad = " " * (2 - ($i + 1).ToString().Length)
            Write-Host "  $($pad)$($i + 1). " -ForegroundColor DarkCyan -NoNewline
            Write-Host "$item" -ForegroundColor DarkGray
        }

        Write-Host ""
    }

    # =====================================================================
    # Commandes liées
    # =====================================================================
    if ($Discovery.related_commands -and $Discovery.related_commands.Count -gt 0) {
        Write-Host "  --------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Autres commandes de cette famille :" -ForegroundColor Yellow
        Write-Host ""

        for ($i = 0; $i -lt $Discovery.related_commands.Count; $i++) {
            $pad = " " * (2 - ($i + 1).ToString().Length)
            Write-Host "  $($pad)$($i + 1). " -ForegroundColor DarkCyan -NoNewline
            Write-Host "$($Discovery.related_commands[$i])" -ForegroundColor Green
        }

        Write-Host ""
    }

    # =====================================================================
    # Pied de page
    # =====================================================================
    Write-Host ""
    Write-Host "  Pour continuer à explorer :" -ForegroundColor DarkCyan
    Write-Host "    pwsh ./shell/cmdschool.ps1 random        --> Découverte aléatoire" -ForegroundColor DarkGray
    Write-Host "    pwsh ./shell/cmdschool.ps1 list          --> Toutes les découvertes" -ForegroundColor DarkGray
    Write-Host "    pwsh ./shell/cmdschool.ps1 help          --> Toutes les commandes" -ForegroundColor DarkGray
    Write-Host ""
}

function Format-DiscoveryList {
    <#
    .SYNOPSIS
        Affiche une liste de toutes les discoveries disponibles
    .DESCRIPTION
        Liste toutes les discoveries avec leur titre, catégorie et niveau.
    .PARAMETER Discoveries
        Tableau de discoveries à afficher
    .PARAMETER CategoryFilter
        Filtre par catégorie (optionnel)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [array]$Discoveries,

        [string]$CategoryFilter = ""
    )

    $count = ($Discoveries | Measure-Object).Count

    if ($count -eq 0) {
        Write-Host ""
        Write-Host "  Aucune découverte trouvée." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    Write-Host ""
    if ($CategoryFilter) {
        Write-Host "  Découvertes dans '$CategoryFilter' ($count) :" -ForegroundColor Cyan
    } else {
        Write-Host "  Toutes les découvertes ($count) :" -ForegroundColor Cyan
    }
    Write-Host ""

    $discoveries | Sort-Object { $_.category }, { $_.level } | ForEach-Object {
        $pad = " " * (1 - $_.level.ToString().Length)
        $levelBar = "*" * $_.level
        Write-Host "  $pad$levelBar  $($_.title)"
        Write-Host "         Catégorie : $($_.category)" -ForegroundColor DarkGray
        Write-Host ""
    }
}

function Format-DiscoveryHelp {
    <#
    .SYNOPSIS
        Affiche l'aide de la ligne de commande
    #>
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor DarkCyan
    Write-Host "              CommandSchool - Aide                          " -ForegroundColor DarkCyan
    Write-Host "==============================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  Utilisation : cmdschool.ps1 [commande] [arguments]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Commandes :" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    discover [nom]          Découverte aléatoire ou spécifique" -ForegroundColor White
    Write-Host "                          Ex: cmdschool discover vaultcmd" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    categories              Lister les catégories disponibles" -ForegroundColor White
    Write-Host ""
    Write-Host "    list                    Lister toutes les découvertes" -ForegroundColor White
    Write-Host "                          Ex: cmdschool list" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    history [nombre]        Voir l'historique des découvertes" -ForegroundColor White
    Write-Host "                          Ex: cmdschool history 5" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    random                  Découverte aléatoire" -ForegroundColor White
    Write-Host ""
    Write-Host "    about                   Afficher le sujet de CommandSchool" -ForegroundColor White
    Write-Host ""
}

function Format-About {
    <#
    .SYNOPSIS
        Affiche les informations sur CommandSchool
    #>
    Write-Host ""
    Write-Host "==============================================================" -ForegroundColor DarkCyan
    Write-Host "              CommandSchool                                 " -ForegroundColor DarkCyan
    Write-Host "==============================================================" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  CommandSchool est un outil de sensibilisation à la culture" -ForegroundColor White
    Write-Host "  numérique pour Windows." -ForegroundColor White
    Write-Host ""
    Write-Host "  Il révèle les mécanismes invisibles de ton ordinateur et" -ForegroundColor White
    Write-Host "  explique pourquoi ils sont utiles dans ta vie quotidienne." -ForegroundColor White
    Write-Host ""
    Write-Host "  Le projet est open source." -ForegroundColor DarkGray
    Write-Host ""
}

# =====================================================================
# Fonctions auxiliaires privées
# =====================================================================

function Write-MultiLineText {
    param(
        [string]$Text,
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    )

    $lines = $Text -split "`r?`n"
    foreach ($line in $lines) {
        if ([string]::IsNullOrWhiteSpace($line)) {
            Write-Host "  "
        } else {
            # Remplacer ** texte ** par du formatage
            $formattedLine = $line -replace '\*\*(.+?)\*\*', '$1'
            Write-Host "  $formattedLine" -ForegroundColor $ForegroundColor
        }
    }
}

function GetLevelName {
    param([int]$Level)
    switch ($Level) {
        1 { return "Débutant" }
        2 { return "Intermédiaire" }
        3 { return "Avancé" }
        default { return "Niveau $Level" }
    }
}

function Get-CommandSchoolPrompt {
    return 'cmdschool discover <nom>  |  cmdschool list  |  cmdschool random  |  cmdschool history  |  cmdschool help'
}

Export-ModuleMember -Function Format-DiscoveryOutput, Format-DiscoveryList, Format-DiscoveryHelp, Format-About, GetLevelName
