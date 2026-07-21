# DiscoveryRunner.Tests.ps1
Describe "DiscoveryRunner" {
    BeforeAll {
        Import-Module "./shell/lib/DiscoveryRunner.psm1" -Force
    }

    Context "Command Validation" {
        It "rejects commands starting with --" {
            $result = Invoke-CommandSchoolCommand -CommandLine "--tab-size-preference: 4"
            $result.Success | Should -BeFalse
            $result.Error | Should -Match "Commande invalide"
            $result.ExitCode | Should -Be -1
        }

        It "rejects commands starting with single -" {
            $result = Invoke-CommandSchoolCommand -CommandLine "-invalid"
            $result.Success | Should -BeFalse
            $result.Error | Should -Match "Commande invalide"
        }

        It "accepts normal commands" -Skip:(-not (Get-Command whoami -ErrorAction SilentlyContinue)) {
            $result = Invoke-CommandSchoolCommand -CommandLine "whoami"
            $result.Success | Should -BeTrue
            $result.Output | Should -Not -BeNullOrEmpty
        }

        It "handles missing commands gracefully" {
            $result = Invoke-CommandSchoolCommand -CommandLine "nonexistent_command_xyz_123"
            $result.Success | Should -BeFalse
        }
    }

    Context "Test-CommandSchoolCommandAvailable" {
        It "identifies available commands" {
            Test-CommandSchoolCommandAvailable -CommandName "whoami" | Should -BeTrue
            Test-CommandSchoolCommandAvailable -CommandName "ipconfig" | Should -BeTrue
        }

        It "identifies unavailable commands" {
            Test-CommandSchoolCommandAvailable -CommandName "nonexistent_cmd_xyz" | Should -BeFalse
        }
    }
}
