# StateManager.Tests.ps1
Describe "StateManager" {
    BeforeAll {
        $testStateDir = Join-Path $env:TEMP "cmdschool_test_state_$((Get-Random).ToString())"
        if (Test-Path $testStateDir) { Remove-Item $testStateDir -Recurse -Force }
        New-Item -ItemType Directory -Path $testStateDir -Force | Out-Null

        # Le module utilise $global:CommandSchoolBaseDir, pas $env:
        $global:CommandSchoolBaseDir = $testStateDir
        Import-Module "./shell/lib/StateManager.psm1" -Force
    }

    AfterEach {
        # Nettoyage après chaque test
        if (Test-Path $testStateDir) { Remove-Item $testStateDir -Recurse -Force }
    }

    Context "Get-CommandSchoolState" {
        It "returns default state when no file exists" {
            $state = Get-CommandSchoolState
            $state.totaldiscoveries | Should -Be 0
            $state.history.Count | Should -Be 0
        }
    }

    Context "Save-CommandSchoolState & Add-CommandSchoolHistory" {
        It "saves and reads state correctly" {
            $state = @{
                lastdiscovery = "whoami"
                lastdiscoverydate = "2025-01-01 12:00:00"
                history = @()
                totaldiscoveries = 1
            }
            Save-CommandSchoolState -State $state

            $loaded = Get-CommandSchoolState
            $loaded.lastdiscovery | Should -Be "whoami"
            $loaded.totaldiscoveries | Should -Be 1
        }

        It "appends to history correctly" {
            $initial = @{
                lastdiscovery = $null
                lastdiscoverydate = $null
                history = @()
                totaldiscoveries = 0
            }
            Save-CommandSchoolState -State $initial

            $result = Add-CommandSchoolHistory -DiscoveryName "test_discovery"
            $result.history.Count | Should -Be 1
            $result.history[0].name | Should -Be "test_discovery"
            $result.totaldiscoveries | Should -Be 1
        }
    }
}
