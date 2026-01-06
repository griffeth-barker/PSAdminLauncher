$version = "0.1.0"
$name = "PSAdminLauncher"

# Run this script from the root of the project directory
$buildParams = @{
    InputFile        = "$pwd\src\$name.ps1"
    OutputFile       = "$pwd\releases\$name-$version.exe"
    IconFile         = "$pwd\images\$name-icon.ico"
    STA              = $true
    NoConsole        = $true
    NoConfigFile     = $true
    Title            = "PowerShell Admin Launcher"
    EmbedFiles       = "$pwd\src\$name.ps1"
    Description      = "Launcher for admin tools requiring elevation"
    Company          = "griff.systems"
    Version          = "$version"
    RequireAdmin     = $true
    Verbose          = $true
}
Invoke-PS2EXE @buildParams

$fileHash = Get-FileHash -Path "$pwd\releases\$name-$version.exe" | Select-Object -ExpandProperty Hash
New-Item -Path "$pwd\releases" -Type File -Name "$name-$version.exe.sha256"
Set-Content -Path "$pwd\releases\$name-$version.exe.sha256" -Value $fileHash