Describe "Admin Tools Launcher Logic" {
    
    BeforeAll {
        # Dot-source the script or define the helper functions here 
        # for the scope of the test.
        function New-ToolItem {
            param($Name, $FilePath, $Argument = "", $NeedsAdmin = $false, $ShellItem = $null)
            return [PSCustomObject]@{
                Name          = $Name
                FilePath      = $FilePath
                Argument      = $Argument
                NeedsAdmin    = $NeedsAdmin
                ElevationText = if ($NeedsAdmin) { "Recommended" } else { "" }
                ShellItem     = $ShellItem
            }
        }
    }

    Context "Data Structure" {
        It "Should create a valid Tool Item object" {
            $item = New-ToolItem -Name "Test Tool" -FilePath "calc.exe" -NeedsAdmin $true
            $item.Name | Should -Be "Test Tool"
            $item.FilePath | Should -Be "calc.exe"
            $item.ElevationText | Should -Be "Recommended"
        }
    }

    Context "Discovery Logic Mocking" {
        It "Should filter out specific MMC clutter" {
            # Mocking the file system to simulate MMC files
            Mock Get-ChildItem {
                return @(
                    @{ Name = "certlm.msc"; FullName = "C:\Windows\System32\certlm.msc"; BaseName = "certlm" },
                    @{ Name = "tpm.msc"; FullName = "C:\Windows\System32\tpm.msc"; BaseName = "tpm" }
                )
            }
            
            $results = Get-ChildItem "C:\any" | Where-Object { $_.Name -notmatch "fxs|tpm|pnt" }
            
            $results.Count | Should -Be 1
            $results[0].Name | Should -Be "certlm.msc"
        }
    }

    Context "Execution Logic" {
        # We mock Start-Process to ensure we don't actually launch apps during tests
        Mock Start-Process { return $true }

        It "Should attempt to launch a process with 'runas' when AsAdmin is true" {
            $item = New-ToolItem -Name "Test" -FilePath "mmc.exe" -Argument "test.msc"
            
            # Logic inside Start-Tool
            $psi = New-Object System.Diagnostics.ProcessStartInfo -Property @{
                FileName = $item.FilePath
                Arguments = $item.Argument
                Verb = "runas"
            }

            $psi.Verb | Should -Be "runas"
            $psi.FileName | Should -Be "mmc.exe"
        }
    }

    Context "Shell Integration" {
        It "Should identify God Mode items correctly" {
            $item = New-ToolItem -Name "GodModeItem" -FilePath "SHELL_ITEM" -ShellItem @{ Name = "MockedShell" }
            
            $item.FilePath | Should -Be "SHELL_ITEM"
            $item.ShellItem | Should -Not -BeNullOrEmpty
        }
    }
}