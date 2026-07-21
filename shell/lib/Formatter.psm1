# =============================================================================
# Formatter.psm1
# Rendu console du Markdown de CommandSchool
# =============================================================================

function Write-Frame {
    param(
        [string]$Text = "",
        [string]$Title = "",
        [string]$Subtitle = "",
        [System.ConsoleColor]$TitleColor = [System.ConsoleColor]::Cyan,
        [int]$Width = 78
    )

    if ($Title) {
        Write-Host "+$('-' * ($Width - 2))+" -ForegroundColor DarkGray
        if ($Title.Length -gt $Width - 4) {
            Write-Host "| $(($Title.Substring(0, $Width - 6)))..." -ForegroundColor $TitleColor
        } else {
            Write-Host "| $($Title.PadRight($Width - 4))|" -ForegroundColor $TitleColor
        }
        if ($Subtitle) {
            Write-Host "| $($Subtitle.PadRight($Width - 4))|" -ForegroundColor DarkGray
        }
        Write-Host "+$('-' * ($Width - 2))+" -ForegroundColor DarkGray
        Write-Host ""
    } else {
        Write-Host "| $Text" -ForegroundColor $TitleColor
    }
}

function Format-DiscoveryOutput {
    <#
    .SYNOPSIS
        Affiche une découverte formatée dans la console
    .DESCRIPTION
        Prend un objet discovery et un résultat de commande,
        et affiche le contenu formaté avec un cadre ASCII,
        des chapitres numérotés et une pagination automatique.
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

    $frameWidth = 78

    # =====================================================================
    # CHAPITRE 0 : En-tête
    # =====================================================================
    Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
    Write-Host "| $($('CommandSchool').PadRight($frameWidth - 4))|" -ForegroundColor DarkCyan
    Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  $($Discovery.title)" -ForegroundColor Cyan
    Write-Host ""
    $levelName = GetLevelName $Discovery.level
    Write-Host "  Catégorie : $($Discovery.category)" -ForegroundColor DarkGray
    Write-Host "  Niveau    : $levelName" -ForegroundColor DarkGray
    Write-Host ""

    # =====================================================================
    # CHAPITRE 1 : La commande
    # =====================================================================
    Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
    Write-Host "| $($('- Chapitre 1 :').PadLeft(20)) Commande............|" -ForegroundColor DarkGray
    Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  $($Discovery.command)" -ForegroundColor Green
    Write-Host ""

    # =====================================================================
    # CHAPITRE 2 : Ce que tu vois
    # =====================================================================
    if ($Discovery.what_you_see) {
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host "| $($('- Chapitre 2 :').PadLeft(20)) Ce que tu vois...   |" -ForegroundColor DarkGray
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host ""
        Write-MultiLineText $Discovery.what_you_see -ForegroundColor DarkYellow
        Write-Host ""
    }

    # =====================================================================
    # CHAPITRE 3 : Ce que ton ordinateur dit
    # =====================================================================
    Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
    Write-Host "| $($('- Chapitre 3 :').PadLeft(20)) Commande sortie...  |" -ForegroundColor DarkGray
    Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
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
    # CHAPITRE 4 : Ce que cela signifie
    # =====================================================================
    if ($Discovery.explanation) {
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host "| $($('- Chapitre 4 :').PadLeft(20)) Interprétation...   |" -ForegroundColor DarkGray
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host ""
        Write-MultiLineText $Discovery.explanation -ForegroundColor White
        Write-Host ""
    }

    # =====================================================================
    # CHAPITRE 5 : Quand cela t'aide
    # =====================================================================
    if ($Discovery.real_world_use_cases -and $Discovery.real_world_use_cases.Count -gt 0) {
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host "| $($('- Chapitre 5 :').PadLeft(20)) Cas pratiques.......|" -ForegroundColor DarkGray
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 0; $i -lt $Discovery.real_world_use_cases.Count; $i++) {
            $useCase = $Discovery.real_world_use_cases[$i]
            $pad = " " * (1 - ($i + 1).ToString().Length)
            Write-Host "  $($pad)$($i + 1)." -ForegroundColor DarkCyan -NoNewline
            Write-Host " " -NoNewline
            Write-MultiLineText $useCase -ForegroundColor White
            Write-Host ""
        }
    }

    # =====================================================================
    # CHAPITRE 6 : Pour aller plus loin
    # =====================================================================
    if ($Discovery.go_deeper -and $Discovery.go_deeper.Count -gt 0) {
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host "| $($('- Chapitre 6 :').PadLeft(20)) Aller plus loin.....|" -ForegroundColor DarkGray
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 0; $i -lt $Discovery.go_deeper.Count; $i++) {
            $item = $Discovery.go_deeper[$i]
            $pad = " " * (1 - ($i + 1).ToString().Length)
            Write-Host "  $($pad)$($i + 1). " -ForegroundColor DarkCyan -NoNewline
            Write-Host "$item" -ForegroundColor DarkGray
        }

        Write-Host ""
    }

    # =====================================================================
    # CHAPITRE 7 : Commandes liées
    # =====================================================================
    if ($Discovery.related_commands -and $Discovery.related_commands.Count -gt 0) {
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host "| $($('- Chapitre 7 :').PadLeft(20)) Commandes liées.....|" -ForegroundColor DarkGray
        Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
        Write-Host ""

        for ($i = 0; $i -lt $Discovery.related_commands.Count; $i++) {
            $pad = " " * (1 - ($i + 1).ToString().Length)
            Write-Host "  $($pad)$($i + 1). " -ForegroundColor DarkCyan -NoNewline
            Write-Host "$($Discovery.related_commands[$i])" -ForegroundColor Green
        }

        Write-Host ""
    }

    # =====================================================================
    # Pied de page
    # =====================================================================
    Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
    Write-Host "| $($('- Fin de la découverte.').PadRight($frameWidth - 4))|" -ForegroundColor DarkCyan
    Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Pour continuer :" -ForegroundColor DarkCyan
    Write-Host "    .\cmdschool.ps1 random        --> Découverte aléatoire" -ForegroundColor DarkGray
    Write-Host "    .\cmdschool.ps1 list          --> Toutes les découvertes" -ForegroundColor DarkGray
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
