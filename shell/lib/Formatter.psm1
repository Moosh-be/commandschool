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
        $titleWidth = Get-DisplayWidth $Title
        if ($titleWidth -gt $Width - 4) {
            $visibleWidth = $Width - 6
            $result = ""
            $enm = $Title.GetEnumerator()
            while ($enm.MoveNext()) {
                $cp = [int]$enm.Current
                $charWidth = if ($cp -gt 0x1100 -and ($cp -le 0x115f -or $cp -eq 0x2329 -or $cp -eq 0x232a -or ($cp -ge 0x2e80 -and $cp -le 0xa4cf -and $cp -ne 0x309b -and $cp -ne 0x309c) -or ($cp -ge 0xac00 -and $cp -le 0xd7af) -or ($cp -ge 0xf900 -and $cp -le 0xfaff) -or ($cp -ge 0xfe10 -and $cp -le 0xfe19) -or ($cp -ge 0xfe30 -and $cp -le 0xfe6f) -or ($cp -ge 0xff00 -and $cp -le 0xff60) -or ($cp -ge 0xffe0 -and $cp -le 0xffe6) -or ($cp -ge 0x20000 -and $cp -le 0x2fffd) -or ($cp -ge 0x30000 -and $cp -le 0x3fffd))) { 2 } else { 1 }
                if ($result.Length + $charWidth -gt $visibleWidth) { break }
                $result += $enm.Current
            }
            Write-Host "| $result..." -ForegroundColor $TitleColor
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

function Write-ChapterHeader {
    param(
        [int]$PageNum,
        [int]$ChapterNum,
        [string]$Title,
        [int]$Width,
        [int]$TotalPages
    )
    $pageStr = "$PageNum / $TotalPages"
    $chapterStr = "Chapitre $ChapterNum : $Title"
    $contentWidth = $pageStr.Length + $chapterStr.Length + 1
    $pad = if ($Width - 2 - $contentWidth -gt 0) { $Width - 2 - $contentWidth } else { 1 }
    $line = "| $pageStr  $chapterStr$('-' * $pad) |"
    Write-Host "+$('-' * ($Width - 2))+" -ForegroundColor DarkGray
    Write-Host $line -ForegroundColor DarkGray
    Write-Host "+$('-' * ($Width - 2))+" -ForegroundColor DarkGray
}

function Show-ContinuePrompt {
    param(
        [bool]$IsLastPage
    )

    Write-Host ""
    if ($IsLastPage) {
        Write-Host "  Appuyez sur Echap pour quitter." -ForegroundColor DarkCyan
    } else {
        Write-Host "  Appuyez sur Enter pour continuer..." -ForegroundColor DarkGray
    }

    $key = $null
    do {
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } while ($null -eq $key -or ($key.VirtualKeyCode -ne 27 -and $key.VirtualKeyCode -ne 13 -and $key.VirtualKeyCode -ne 37 -and $key.VirtualKeyCode -ne 39))

    return $key.VirtualKeyCode
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

    Clear-Host

    $consoleWidth = if ($host.UI.RawUI.WindowSize) { $host.UI.RawUI.WindowSize.Width } else { 120 }
    $frameWidth = [Math]::Min(78, [Math]::Max(40, $consoleWidth - 4))
    $totalPages = 9

    $currentPage = 0
    while ($currentPage -lt $totalPages) {
        Clear-Host
        switch ($currentPage) {
            0 {
                # Page 0: En-tête
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
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
            }
            1 {
                # Page 1: La commande
                Write-ChapterHeader 1 1 "Commande" $frameWidth $totalPages
                Write-Host ""
                Write-Host "  $($Discovery.command)" -ForegroundColor Green
                Write-Host ""
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
            }
            2 {
                # Page 2: Ce que tu vois
                Write-ChapterHeader 2 2 "Ce que tu vois" $frameWidth $totalPages
                if ($Discovery.what_you_see) {
                    Write-MultiLineText $Discovery.what_you_see -ForegroundColor DarkYellow
                }
                Write-Host ""
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
            }
            3 {
                # Page 3: Ce que ton ordinateur dit
                Write-ChapterHeader 3 3 "Commande sortie" $frameWidth $totalPages
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
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
            }
            4 {
                # Page 4: Ce que cela signifie
                Write-ChapterHeader 4 4 "Interprétation" $frameWidth $totalPages
                if ($Discovery.explanation) {
                    Write-MultiLineText $Discovery.explanation -ForegroundColor White
                }
                Write-Host ""
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
            }
            5 {
                # Page 5: Quand cela t'aide
                Write-ChapterHeader 5 5 "Cas pratiques" $frameWidth $totalPages
                Write-Host ""

                if ($Discovery.real_world_use_cases -and $Discovery.real_world_use_cases.Count -gt 0) {
                    for ($i = 0; $i -lt $Discovery.real_world_use_cases.Count; $i++) {
                        $useCase = $Discovery.real_world_use_cases[$i]
                        $pad = " " * (1 - ($i + 1).ToString().Length)
                        Write-Host "  $($pad)$($i + 1)." -ForegroundColor DarkCyan -NoNewline
                        Write-Host " " -NoNewline

                        if ($useCase -is [hashtable]) {
                            if ($useCase.text) {
                                Write-MultiLineText $useCase.text -ForegroundColor White
                            }
                            if ($useCase.example) {
                                Write-Host "     Exemple : " -ForegroundColor DarkCyan -NoNewline
                                Write-Host "$($useCase.example)" -ForegroundColor Green
                            }
                        } else {
                            Write-MultiLineText $useCase -ForegroundColor White
                        }
                        Write-Host ""
                    }
                }

                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
            }
            6 {
                # Page 6: Pour aller plus loin
                Write-ChapterHeader 6 6 "Aller plus loin" $frameWidth $totalPages
                Write-Host ""

                if ($Discovery.go_deeper -and $Discovery.go_deeper.Count -gt 0) {
                    for ($i = 0; $i -lt $Discovery.go_deeper.Count; $i++) {
                        $item = $Discovery.go_deeper[$i]
                        $pad = " " * (1 - ($i + 1).ToString().Length)
                        Write-Host "  $($pad)$($i + 1). " -ForegroundColor DarkCyan -NoNewline
                        Write-Host "$item" -ForegroundColor DarkGray
                    }
                }

                Write-Host ""
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
            }
            7 {
                # Page 7: Commandes liées
                Write-ChapterHeader 7 7 "Commandes liées" $frameWidth $totalPages
                Write-Host ""

                if ($Discovery.related_commands -and $Discovery.related_commands.Count -gt 0) {
                    for ($i = 0; $i -lt $Discovery.related_commands.Count; $i++) {
                        $pad = " " * (1 - ($i + 1).ToString().Length)
                        Write-Host "  $($pad)$($i + 1). " -ForegroundColor DarkCyan -NoNewline
                        Write-Host "$($Discovery.related_commands[$i])" -ForegroundColor Green
                    }
                }

                Write-Host ""
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
            }
            8 {
                # Page 8: Pied de page
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host "| $($('- Fin de la découverte.').PadRight($frameWidth - 4))|" -ForegroundColor DarkCyan
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
                Write-Host "  Pour continuer :" -ForegroundColor DarkCyan
                Write-Host "    .\cmdschool.ps1 random        --> Découverte aléatoire" -ForegroundColor DarkGray
                Write-Host "    .\cmdschool.ps1 list          --> Toutes les découvertes" -ForegroundColor DarkGray
                Write-Host ""
                Write-Host "+$('-' * ($frameWidth - 2))+" -ForegroundColor DarkGray
                Write-Host ""
            }
        }

        # Navigate based on key press
        $key = Show-ContinuePrompt ($currentPage -eq ($totalPages - 1))
        if ($key -eq 27) { exit }
        elseif ($key -eq 37 -and $currentPage -gt 0) { $currentPage-- }
        else { $currentPage++ }
    }
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

function Get-DisplayWidth {
    param([string]$String)
    if ([string]::IsNullOrEmpty($String)) { return 0 }
    $count = 0
    $enm = $String.GetEnumerator()
    while ($enm.MoveNext()) {
        $cp = [int]$enm.Current
        if ($cp -gt 0x1100 -and (
            $cp -le 0x115f -or
            $cp -eq 0x2329 -or $cp -eq 0x232a -or
            ($cp -ge 0x2e80 -and $cp -le 0xa4cf -and $cp -ne 0x309b -and $cp -ne 0x309c) -or
            ($cp -ge 0xac00 -and $cp -le 0xd7af) -or
            ($cp -ge 0xf900 -and $cp -le 0xfaff) -or
            ($cp -ge 0xfe10 -and $cp -le 0xfe19) -or
            ($cp -ge 0xfe30 -and $cp -le 0xfe6f) -or
            ($cp -ge 0xff00 -and $cp -le 0xff60) -or
            ($cp -ge 0xffe0 -and $cp -le 0xffe6) -or
            ($cp -ge 0x20000 -and $cp -le 0x2fffd) -or
            ($cp -ge 0x30000 -and $cp -le 0x3fffd)
        )) { $count += 2 }
        else { $count += 1 }
    }
    return $count
}

function Get-Padding {
    param(
        [string]$Text,
        [int]$TargetWidth,
        [string]$BorderChar = "|"
    )
    $currentWidth = Get-DisplayWidth $Text
    $needed = $TargetWidth - 2 - $currentWidth
    if ($needed -lt 0) { $needed = 0 }
    return "$BorderChar$(' ' * $needed)"
}

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
