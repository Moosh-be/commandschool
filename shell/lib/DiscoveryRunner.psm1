# =============================================================================
# DiscoveryRunner.psm1
# Exécute une commande Windows et capture son résultat
# =============================================================================

function Invoke-CommandSchoolCommand {
    <#
    .SYNOPSIS
        Exécute une commande Windows et capture le résultat
    .DESCRIPTION
        Lance une commande (CLI, PowerShell, ou cmd) et retourne
        le stdout, le stderr, le code de sortie et les erreurs.
        
        Gère les erreurs gracieusement : si la commande échoue,
        le résultat contient un message d'erreur lisible.
    .PARAMETER CommandLine
        La commande à exécuter (ex: "whoami", "VaultCmd /list")
    .PARAMETER CommandShell
        Le shell à utiliser : "auto", "pwsh", "cmd", "powershell"
    .PARAMETER TimeoutSeconds
        Timeout en secondes avant abort (défaut : 30)
    .EXAMPLE
        Invoke-CommandSchoolCommand -CommandLine "whoami"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandLine,

        [ValidateSet("auto", "pwsh", "cmd", "powershell")]
        [string]$CommandShell = "auto",

        [int]$TimeoutSeconds = 30
    )

    $result = @{
        Command = $CommandLine
        Success = $false
        Output = ""
        Error = ""
        ExitCode = -1
        ExecutedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Shell = ""
    }

    # Déterminer le shell à utiliser
    if ($CommandShell -eq "auto") {
        # Essayer pwsh (PowerShell 7), fallback sur powershell (Windows PowerShell)
        if (Get-Command pwsh -ErrorAction SilentlyContinue) {
            $CommandShell = "pwsh"
        } else {
            $CommandShell = "powershell"
        }
    }
    $result.Shell = $CommandShell

    # Construire la commande à exécuter selon le shell
    $scriptToRun = ""
    $shellExe = ""
    $shellArgs = ""

    switch ($CommandShell) {
        "pwsh" {
            $shellExe = "pwsh"
            $shellArgs = "-NoProfile -NonInteractive -NoLogo -Command `" & { try { `$output = `$($CommandLine) 2>`1; if (`$output) { Write-Output `$output } else { Write-Output '(Aucun résultat)' } ; exit 0 } catch { Write-Error `$_.Exception.Message; exit 1 } }`""
        }
        "powershell" {
            $shellExe = "powershell"
            $shellArgs = "-NoProfile -NonInteractive -NoLogo -Command `"& { try { `$output = `$($CommandLine) 2>`1; if (`$output) { Write-Output `$output } else { Write-Output '(Aucun résultat)' } ; exit 0 } catch { Write-Error `$_.Exception.Message; exit 1 } }`""
        }
        "cmd" {
            $shellExe = "cmd"
            $shellArgs = "/c `$CommandLine"
        }
    }

    try {
        $process = Start-Process -FilePath $shellExe -ArgumentList $shellArgs `
            -NoNewWindow -Wait -PassThru -RedirectStandardOutput "$env:TEMP\cmdschool_output_$((Get-Random).ToString().PadLeft(10, '0')).txt" `
            -RedirectStandardError "$env:TEMP\cmdschool_error_$((Get-Random).ToString().PadLeft(10, '0')).txt" `
            -ErrorAction Stop

        $result.ExitCode = $process.ExitCode

        if ($result.ExitCode -eq 0) {
            $result.Success = $true
        }

        # Lire les fichiers de sortie
        $outputFile = Get-ChildItem "$env:TEMP\cmdschool_output_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $errorFile = Get-ChildItem "$env:TEMP\cmdschool_error_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

        if ($outputFile -and (Test-Path $outputFile.FullName)) {
            $result.Output = Get-Content $outputFile.FullName -Raw
            Remove-Item $outputFile.FullName -ErrorAction SilentlyContinue
        }

        if ($errorFile -and (Test-Path $errorFile.FullName)) {
            $result.Error = Get-Content $errorFile.FullName -Raw
            Remove-Item $errorFile.FullName -ErrorAction SilentlyContinue
        }

        # Si pas de sortie et succès, indiquer "aucun résultat"
        if ($result.Success -and [string]::IsNullOrWhiteSpace($result.Output)) {
            $result.Output = "(Aucun résultat)"
        }
    }
    catch {
        $result.Error = "Erreur lors de l'exécution de '$CommandLine' : $_"
        $result.Success = $false
        $result.ExitCode = -1
    }

    # Nettoyage des fichiers temporaires
    Remove-Item "$env:TEMP\cmdschool_*.txt" -ErrorAction SilentlyContinue

    return $result
}

function Test-CommandSchoolCommandAvailable {
    <#
    .SYNOPSIS
        Vérifie si une commande existe sur le système
    .DESCRIPTION
        Vérifie si la commande peut être trouvée avant de l'exécuter.
        Retourne true si la commande est disponible.
    .PARAMETER CommandName
        Le nom de la commande à vérifier
    .OUTPUTS
        Booléen
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    # Extraire le nom de la commande (sans arguments)
    $baseCommand = ($CommandName -split '\s')[0]

    # Vérifier si c'est un alias PowerShell
    $alias = Get-Alias | Where-Object { $_.Name -eq $baseCommand -or $_.Replacement -eq $baseCommand }
    if ($alias) { return $true }

    # Vérifier si c'est une cmdlet PowerShell
    $cmdlet = Get-Command $baseCommand -ErrorAction SilentlyContinue
    if ($cmdlet) { return $true }

    # Vérifier si c'est un exécutable (CLI, .exe, .bat, .com)
    $exe = Get-Command $baseCommand -CommandType Application -ErrorAction SilentlyContinue
    if ($exe) { return $true }

    return $false
}

Export-ModuleMember -Function Invoke-CommandSchoolCommand, Test-CommandSchoolCommandAvailable
