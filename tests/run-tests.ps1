# run-tests.ps1
# Lance les tests unitaires Pester

$pesterModule = Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1

if (-not $pesterModule) {
    Write-Host "Pester n'est pas installé. Installation..." -ForegroundColor Yellow
    Install-Module Pester -Force -SkipPublisherCheck -Scope CurrentUser -Confirm:$false
    $pesterModule = Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
}

Import-Module $pesterModule.FullName -Force

Write-Host "Lancement des tests unitaires (Pester $($pesterModule.Version))..." -ForegroundColor Cyan

$oldErrorAction = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$configPath = "./tests/test-results.xml"
$ErrorActionPreference = $oldErrorAction

$runResult = Invoke-Pester -Path "./tests" -Output Detailed -PassThru

exit $runResult.FailedCount
