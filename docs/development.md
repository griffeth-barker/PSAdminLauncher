## Development & Compilation

### Application Dependencies
There are no external dependencies for the wrapped application to run, apart from the `PresentationFramework` and `System.Windows.Forms` assemblies, which are theoretically included on all modern Windows systems.

### Build Dependencies
Wrapping the script as an executable is done using the [PS2EXE module](https://github.com/MScholtes/PS2EXE), which can be installed from the PSGallery:
```powershell
Install-Module -Name 'PS2EXE' -Repository PSGallery
```
You can use another method to wrap `PSAdminLauncher.ps1` as `PSAdminLauncher-v0-1-0.exe` if you wish, provided the necessary threading requirements are met.

### Threading Requirements
This application uses the **Windows Presentation Framework (WPF)** and must be run in **Single-Threaded Apartment (STA)** mode. 
* If running via script: `powershell.exe -sta -file .\PSAdminLauncher.ps1`
* If buliding the executable: Be sure to include the `-sta` parameter in your `Invoke-PS2EXE` command.

### Wrapping/Compiling
To generate a standalone executable, use the following command structure:

```powershell
# Modify the values of the InputFile, OutputFile, and IconFile strings as necessary.
$buildParams = @{
    InputFile        = "$pwd\src\PSAdminLauncher.ps1"
    OutputFile       = "$pwd\releases\PSAdminLauncher-0.1.0.exe"
    IconFile         = "$pwd\images\PSAdminLauncher-icon.ico"
    STA              = $true
    NoConsole        = $true
    NoConfigFile     = $true
    Title            = "PowerShell Admin Launcher"
    EmbedFiles       = "$pwd\src\PSAdminLauncher.ps1"
    Description      = "Launcher for admin tools requiring elevation"
    Company          = "griff.systems"
    Version          = 0.1.0
    RequireAdmin     = $true
    Verbose          = $true
}
Invoke-PS2EXE @buildParams
```

### Contributing
Feedback and pull requests are welcome. 

### Functions
The following functions are used in the main script:

#### Core Logic Functions

#### UI & Modal Window Functions
