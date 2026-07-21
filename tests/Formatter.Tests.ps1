# Formatter.Tests.ps1
Describe "Formatter" {
    BeforeAll {
        Import-Module "./shell/lib/Formatter.psm1" -Force
    }

    Context "GetLevelName" {
        It "returns 'Débutant' for level 1" {
            GetLevelName -Level 1 | Should -Be "Débutant"
        }

        It "returns 'Intermédiaire' for level 2" {
            GetLevelName -Level 2 | Should -Be "Intermédiaire"
        }

        It "returns 'Avancé' for level 3" {
            GetLevelName -Level 3 | Should -Be "Avancé"
        }

        It "returns 'Niveau X' for unknown levels" {
            GetLevelName -Level 5 | Should -Be "Niveau 5"
        }
    }
}
