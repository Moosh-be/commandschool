# DiscoveryStore.Tests.ps1
Describe "DiscoveryStore" {
    BeforeAll {
        Import-Module "./shell/lib/DiscoveryStore.psm1" -Force
    }

    Context "ConvertFrom-CommandSchoolYaml" {
        It "parses vaultcmd.yaml correctly" {
            $yaml = Get-DiscoveryByName -Name "vaultcmd"
            $yaml | Should -Not -BeNullOrEmpty
            $yaml.title | Should -Be "VaultCmd — Tes identifiants stockés dans Windows"
            $yaml.category | Should -Be "Authentification"
            $yaml.level | Should -BeOfType [int]
            $yaml.level | Should -Be 1
            $yaml.command | Should -Be "VaultCmd /list"
            $yaml.explanation | Should -Match "Windows stocke"
            $yaml.real_world_use_cases | Should -Not -BeNullOrEmpty
            $yaml.real_world_use_cases.Count | Should -BeGreaterThan 0
        }

        It "parses ipconfig.yaml correctly" {
            $yaml = Get-DiscoveryByName -Name "ipconfig"
            $yaml.title | Should -Be "ipconfig — Ta carte réseau en temps réel"
            $yaml.command | Should -Be "ipconfig"
            $yaml.category | Should -Be "Réseau"
        }

        It "parses go_deeper array correctly" {
            $yaml = Get-DiscoveryByName -Name "vaultcmd"
            $yaml.go_deeper | Should -Not -BeNullOrEmpty
            $yaml.go_deeper.Count | Should -Be 4
        }
    }

    Context "Get-AllDiscoveries" {
        It "returns all yaml files as discoveries" {
            $discoveries = Get-AllDiscoveries
            $discoveries.Count | Should -BeGreaterThan 0
            $discoveries[0] | Should -Not -BeNullOrEmpty
            $discoveries | ForEach-Object {
                $_.title | Should -Not -BeNullOrEmpty
                $_.command | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Get-DiscoveryByName" {
        It "returns null for non-existent discovery" {
            $result = Get-DiscoveryByName -Name "thisdoesnotexist"
            $result | Should -BeNullOrEmpty
        }

        It "returns discovery when it exists" {
            $result = Get-DiscoveryByName -Name "whoami"
            $result.title | Should -Match "whoami"
        }
    }

    Context "Get-DiscoveryByCategory" {
        It "filters discoveries by category" {
            $results = Get-DiscoveryByCategory -Category "Authentification"
            $results.Count | Should -BeGreaterThan 0
            $results | ForEach-Object {
                $_.category | Should -Be "Authentification"
            }
        }
    }
}
