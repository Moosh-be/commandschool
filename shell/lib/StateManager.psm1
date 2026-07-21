# =============================================================================
# StateManager.psm1
# Gère l'historique et l'état des découvertes
# Stocke l'état dans state/state.json
# =============================================================================

# Chemin racine du projet : fourni par cmdschool.ps1
# Fallback : dossier courant si pas fourni (ex: test unitaire)
$baseDir = if ($null -ne $global:CommandSchoolBaseDir -and $global:CommandSchoolBaseDir -ne "") {
    $global:CommandSchoolBaseDir
} else {
    (Get-Location).Path
}

$script:stateDir = Join-Path $baseDir "state"
$script:stateFile = Join-Path $script:stateDir "state.json"

function Get-CommandSchoolState {
    <#
    .SYNOPSIS
        Lit l'état courant de CommandSchool
    #>
    if (Test-Path $script:stateFile) {
        $json = Get-Content $script:stateFile -Raw
        $obj = $json | ConvertFrom-Json
        return $obj
    } else {
        # Retourner un hashtable au lieu d'un PSCustomObject
        return @{
            lastdiscovery = $null
            lastdiscoverydate = $null
            history = @()
            totaldiscoveries = 0
        }
    }
}

function Save-CommandSchoolState {
    <#
    .SYNOPSIS
        Sauvegarde l'état de CommandSchool
    .PARAMETER State
        L'objet state à sauvegarder (hashtable ou PSCustomObject)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$State
    )

    # Créer le dossier state s'il n'existe pas
    if (-not (Test-Path $script:stateDir)) {
        New-Item -ItemType Directory -Path $script:stateDir -Force | Out-Null
    }

    # Sérialiser un hashtable en JSON propre
    if ($State -is [hashtable]) {
        $json = ConvertTo-JsonSimple $State
    } else {
        # Pour les PSCustomObjects, convertir en hashtable
        $hash = @{}
        foreach ($prop in $State.PSObject.Properties) {
            $hash[$prop.Name] = $prop.Value
        }
        $json = ConvertTo-JsonSimple $hash
    }

    $json | Out-File -FilePath $script:stateFile -Encoding UTF8
}

function ConvertTo-JsonSimple {
    <#
    .SYNOPSIS
        Sérialisation JSON personnalisée pour hashtables imbriquées
    .DESCRIPTION
        Contourne les bugs de ConvertTo-Json avec les arrays de PSCustomObjects.
    #>
    param([object]$Object)

    if ($null -eq $Object) { return '"null"' }

    # Tableau
    if ($Object -is [array]) {
        if ($Object.Count -eq 0) { return '[]' }
        $items = @()
        foreach ($item in $Object) {
            $items += (ConvertTo-JsonSimple $item)
        }
        return '[' + ($items -join ',') + ']'
    }

    # Hashtable
    if ($Object -is [hashtable]) {
        $pairs = @()
        foreach ($key in $Object.Keys) {
            $escapedKey = $key -replace '\\', '\\\\' -replace '"', '\"'
            $value = ConvertTo-JsonSimple $Object[$key]
            $pairs += '"{0}":{1}' -f $escapedKey, $value
        }
        return '{' + ($pairs -join ',') + '}'
    }

    # Chaîne
    if ($Object -is [string]) {
        return '"' + ($Object -replace '\\', '\\\\' -replace '"', '\"') + '"'
    }

    # Booléen
    if ($Object -is [bool]) { return $Object.ToString().ToLower() }

    # Nombre
    if ($Object -is [int] -or $Object -is [double] -or $Object -is [long]) {
        return $Object.ToString()
    }

    # Tout le reste => chaîne
    return '"' + $Object.ToString() + '"'
}

function Add-CommandSchoolHistory {
    <#
    .SYNOPSIS
        Ajoute une entrée à l'historique des découvertes
    .PARAMETER DiscoveryName
        Nom de la découverte ajoutée
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$DiscoveryName
    )

    # Lire l'état courant
    $state = Get-CommandSchoolState

    # Si hashtable vide (pas encore initialisé), créer la structure
    if ($state -is [hashtable] -and $state.Count -eq 0) {
        $state = @{
            lastdiscovery = $null
            lastdiscoverydate = $null
            history = @()
            totaldiscoveries = 0
        }
    }

    $now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Mettre à jour la dernière découverte
    if ($state -is [hashtable]) {
        $state['lastdiscovery'] = $DiscoveryName
        $state['lastdiscoverydate'] = $now
    } else {
        # Pour les PSCustomObjects, on modifie les propriétés directement
        $state.PSObject.Properties['lastdiscovery'].Value = $DiscoveryName
        $state.PSObject.Properties['lastdiscoverydate'].Value = $now
    }

    # Ajouter à l'historique
    $entryJson = '{"name":"' + $DiscoveryName + '","date":"' + $now + '"}'
    $entry = $entryJson | ConvertFrom-Json

    if ($state -is [hashtable]) {
        $history = if ($null -ne $state['history'] -and $state['history'] -is [array]) {
            $state['history']
        } else {
            @()
        }
        $state['history'] = @($history) + $entry
        $state['totaldiscoveries'] = $state['history'].Count
    } else {
        $history = if ($null -ne $state.history -and $state.history -is [array]) {
            $state.history
        } else {
            @()
        }
        $state.history = @($history) + $entry
        $state.totaldiscoveries = $state.history.Count
    }

    Save-CommandSchoolState -State $State
    return $State
}

function Get-CommandSchoolHistory {
    <#
    .SYNOPSIS
        Affiche l'historique des dernières découvertes
    .PARAMETER Count
        Nombre d'entrées (défaut : 10)
    #>
    param([int]$Count = 10)

    $state = Get-CommandSchoolState

    # Déterminer la collection history
    if ($state -is [hashtable]) {
        $history = if ($null -ne $state['history'] -and $state['history'] -is [array]) {
            $state['history']
        } else {
            $null
        }
    } else {
        $history = if ($null -ne $state.history -and $state.history -is [array]) {
            $state.history
        } else {
            $null
        }
    }

    if ($null -eq $history -or $history.Count -eq 0) {
        Write-Host "Aucun historique de découvertes."
        return
    }

    $start = [Math]::Max(0, $history.Count - $Count)
    $recent = $history[$start..($history.Count - 1)]

    Write-Host ""
    Write-Host "=== Dernières découvertes ===" -ForegroundColor Cyan
    Write-Host ""

    for ($i = $recent.Count - 1; $i -ge 0; $i--) {
        $entry = $recent[$i]
        $name = ""
        $date = ""
        if ($entry -is [hashtable]) {
            $name = $entry['name']
            $date = $entry['date']
        } else {
            $name = $entry.name
            $date = $entry.date
        }
        $index = $i + 1
        $pad = " " * (2 - $index.ToString().Length)
        Write-Host "$($pad)$index. $name ($date)"
    }

    Write-Host ""
}

Export-ModuleMember -Function Get-CommandSchoolState, Save-CommandSchoolState, Add-CommandSchoolHistory, Get-CommandSchoolHistory
