# =============================================================================
# DiscoveryStore.psm1
# Découvre et lit les fichiers YAML de découvertes
# =============================================================================

$script:DiscoveryStoreBase = Split-Path (Split-Path (Split-Path $PSCommandPath) -Parent) -Parent
$script:DiscoveriesPath = Join-Path $script:DiscoveryStoreBase "discoveries"

function Get-DiscoveryFiles {
    param([string]$DiscoveryPath = $script:DiscoveriesPath)
    if (-not (Test-Path $DiscoveryPath)) {
        Write-Warning "Dossier discoveries non trouvé : $DiscoveryPath"
        return @()
    }
    Get-ChildItem -Path $DiscoveryPath -Filter "*.yaml" -File | Select-Object -ExpandProperty FullName
}

function Get-DiscoveryPath { return $script:DiscoveriesPath }

function Get-DiscoveryByName {
    param([Parameter(Mandatory = $true)][string]$Name)
    $yamlPath = Join-Path (Get-DiscoveryPath) "$Name.yaml"
    if (-not (Test-Path $yamlPath)) {
        Write-Warning "Discovery '$Name' non trouvée dans $yamlPath"
        return $null
    }
    $discovery = ConvertFrom-CommandSchoolYaml -Path $yamlPath
    if ($discovery) { $discovery._file = $yamlPath }
    return $discovery
}

function Get-DiscoveryByCategory {
    param([Parameter(Mandatory = $true)][string]$Category)
    Get-AllDiscoveries | Where-Object { $_.category -ieq $Category }
}

function Get-AllDiscoveries {
    $yamlFiles = Get-DiscoveryFiles
    $discoveries = @()
    foreach ($file in $yamlFiles) {
        $discovery = ConvertFrom-CommandSchoolYaml -Path $file
        if ($discovery) {
            $discovery._file = $file
            $discoveries += $discovery
        }
    }
    return $discoveries
}

function ParseSimpleValue {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    if ($Value -match '^"(.+)"$') { return $Matches[1] }
    if ($Value -match "^'(.+)'$") { return $Matches[1] }
    if ($Value -match '^\d+$') { return [int]$Value }
    if ($Value -match '^\d+\.\d+$') { return [double]$Value }
    if ($Value -eq 'true' -or $Value -eq 'yes') { return $true }
    if ($Value -eq 'false' -or $Value -eq 'no') { return $false }
    if ($Value -eq 'null' -or $Value -eq '~') { return $null }
    return $Value
}

function ConvertFrom-CommandSchoolYaml {
    param([Parameter(Mandatory = $true)][string]$Path)

    $rawLines = Get-Content $Path -Encoding UTF8
    $lines = @()
    foreach ($rawLine in $rawLines) {
        $trimmed = $rawLine.Trim()
        $indent = $rawLine.Length - $rawLine.TrimStart().Length
        if ($indent -eq 0 -and $trimmed -match '^#') { continue }
        $lines += $rawLine
    }

    $result = @{}
    $i = 0

    while ($i -lt $lines.Count) {
        $line = $lines[$i]
        $trimmed = $line.Trim()
        $indent = $line.Length - $line.TrimStart().Length

        # Skip indented lines at root level loop (shouldn't happen, but safe)
        if ($indent -gt 0) { $i++; continue }
        # Skip blank lines at root level
        if ([string]::IsNullOrWhiteSpace($trimmed)) { $i++; continue }

        # ---- Block scalar : key: | ----
        if ($trimmed -match '^(\w[\w_-]+)\s*:\s*\|\s*$') {
            $key = $Matches[1]
            $blockContent = @()
            $blockIndent = $null
            $i++
            while ($i -lt $lines.Count) {
                $bLine = $lines[$i]
                $bTrimmed = $bLine.Trim()
                $bIndent = $bLine.Length - $bLine.TrimStart().Length

                # End of block: non-empty line at indent 0 = new root key
                if ($bIndent -eq 0 -and -not [string]::IsNullOrWhiteSpace($bTrimmed)) { break }

                # End of block: non-empty line with less indent than block content
                if ($blockIndent -ne $null -and $bIndent -lt $blockIndent -and -not [string]::IsNullOrWhiteSpace($bTrimmed)) { break }

                if ($blockIndent -eq $null) {
                    $blockIndent = $bIndent
                }

                # Empty lines at any indent (including indent 0 paragraph separators) are kept as blanks
                if ([string]::IsNullOrWhiteSpace($bTrimmed)) {
                    $blockContent += ""
                } else {
                    $blockContent += $bLine.Substring($blockIndent)
                }
                $i++
            }
            $result[$key] = ($blockContent -join "`n").TrimEnd()
        }
        # ---- Séquence bloc : key: suivi de lignes "- item" ----
        elseif ($trimmed -match '^(\w[\w_-]+)\s*:\s*$') {
            $key = $Matches[1]
            $array = @()
            $i++

            $seqIndent = 2
            if ($i -lt $lines.Count) {
                $seqIndent = $lines[$i].Length - $lines[$i].TrimStart().Length
            }

            while ($i -lt $lines.Count) {
                $sLine = $lines[$i]
                $sTrimmed = $sLine.Trim()
                $sIndent = $sLine.Length - $sLine.TrimStart().Length

                # End of sequence: non-empty line at indent 0 = new root key
                if ($sIndent -eq 0 -and -not [string]::IsNullOrWhiteSpace($sTrimmed)) { break }
                if ($sIndent -lt $seqIndent) { break }

                # Item multi-ligne : "- |"
                if ($sTrimmed -match '^\-\s+\|') {
                    $arrayItem = @()
                    $arrayBlockIndent = $null
                    $i++
                    while ($i -lt $lines.Count) {
                        $bLine = $lines[$i]
                        $bIndent = $bLine.Length - $bLine.TrimStart().Length
                        $bTrimmed = $bLine.Trim()

                        # End of array block: non-empty line at indent 0 = new root key
                        if ($bIndent -eq 0 -and -not [string]::IsNullOrWhiteSpace($bTrimmed)) { break }

                        # End of array block: non-empty line with less indent than array content
                        if ($arrayBlockIndent -ne $null -and $bIndent -lt $arrayBlockIndent -and -not [string]::IsNullOrWhiteSpace($bTrimmed)) { break }

                        if ($arrayBlockIndent -eq $null) {
                            $arrayBlockIndent = $bIndent
                        }

                        # Empty lines at any indent are kept as blanks (paragraph separators)
                        if ([string]::IsNullOrWhiteSpace($bTrimmed)) {
                            $arrayItem += ""
                        } else {
                            $arrayItem += $bLine.Substring($arrayBlockIndent)
                        }
                        $i++
                    }
                    $array += ($arrayItem -join "`n").TrimEnd()
                }
                # Item scalaire : "- value"
                elseif ($sTrimmed -match '^\-\s+(.+)$') {
                    $array += ParseSimpleValue $Matches[1].Trim()
                    $i++
                }
                else { break }
            }
            $result[$key] = $array
        }
        # ---- Clé simple : key: value ----
        elseif ($trimmed -match '^(\w[\w_-]+)\s*:\s*(.+)$') {
            $result[$Matches[1]] = ParseSimpleValue $Matches[2].Trim()
            $i++
        }
        else { $i++ }
    }

    if ($result.ContainsKey('level') -and $result['level'] -is [string]) {
        $result['level'] = [int]$result['level']
    }
    return $result
}

Export-ModuleMember -Function Get-DiscoveryFiles, Get-DiscoveryByName, Get-DiscoveryByCategory, Get-AllDiscoveries, Get-DiscoveryPath
