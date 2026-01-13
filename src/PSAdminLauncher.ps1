<# 
    .SYNOPSIS
        Launcher for administrative tools on Windows Server (MMC, CPL, God Mode, and MS-Settings).
    .DESCRIPTION
        Includes a dynamic scanner for 'ms-settings:' URIs extracted from system binaries.
#>

[CmdletBinding()]
param()

# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase | Out-Null

# --- Integrated High-performance URI Scanner (C#) ---
$scannerSource = @"
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

public static class MsSettingsScanner
{
    static readonly byte[] AsciiPrefix = Encoding.ASCII.GetBytes("ms-settings:");
    static readonly byte[] Utf16Prefix = Encoding.Unicode.GetBytes("ms-settings:");

    public static List<string> ExtractAll(string filePath)
    {
        if (!File.Exists(filePath)) return new List<string>();
        byte[] data = File.ReadAllBytes(filePath);
        var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var s in FindAscii(data)) set.Add(s);
        foreach (var s in FindUtf16(data)) set.Add(s);

        var list = new List<string>(set);
        list.Sort(StringComparer.OrdinalIgnoreCase);
        return list;
    }

    static IEnumerable<string> FindAscii(byte[] data)
    {
        foreach (int idx in FindAll(data, AsciiPrefix))
        {
            int i = idx + AsciiPrefix.Length;
            var sb = new StringBuilder("ms-settings:");
            while (i < data.Length)
            {
                char c = (char)data[i];
                if (!IsValidUriChar(c)) break;
                sb.Append(c);
                i++;
            }
            yield return sb.ToString();
        }
    }

    static IEnumerable<string> FindUtf16(byte[] data)
    {
        foreach (int idx in FindAll(data, Utf16Prefix))
        {
            int pos = idx + Utf16Prefix.Length;
            var sb = new StringBuilder("ms-settings:");
            while (pos + 1 < data.Length)
            {
                byte lo = data[pos];
                byte hi = data[pos + 1];
                if (hi != 0) break;
                char c = (char)lo;
                if (!IsValidUriChar(c)) break;
                sb.Append(c);
                pos += 2;
            }
            yield return sb.ToString();
        }
    }

    static IEnumerable<int> FindAll(byte[] haystack, byte[] needle)
    {
        int n = haystack.Length, m = needle.Length;
        if (m == 0 || n < m) yield break;
        int[] skip = new int[256];
        for (int i = 0; i < skip.Length; i++) skip[i] = m;
        for (int i = 0; i < m - 1; i++) skip[needle[i]] = m - 1 - i;
        int pos = 0;
        while (pos <= n - m)
        {
            int j = m - 1;
            while (j >= 0 && haystack[pos + j] == needle[j]) j--;
            if (j < 0) { yield return pos; pos += m; }
            else { pos += skip[haystack[pos + m - 1]]; }
        }
    }

    static bool IsValidUriChar(char c)
    {
        return (char.IsLetterOrDigit(c) || "-_.:/;?&=#%+,@".Contains(c.ToString()));
    }
}
"@
Add-Type -TypeDefinition $scannerSource -Language CSharp -IgnoreWarnings

# Helper function to create tool items
function New-ToolItem {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$FilePath,
        [string]$Argument = "",
        [bool]$NeedsAdmin = $false,
        $ShellItem = $null
    )
    return [PSCustomObject]@{
        Name          = $Name
        FilePath      = $FilePath
        Argument      = $Argument
        NeedsAdmin    = $NeedsAdmin
        ElevationText = if ($NeedsAdmin) { "Recommended" } else { "" }
        ShellItem     = $ShellItem
    }
}

$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent().Name

# --- XAML UI (4 Columns) ---
$xaml = @"
<Window xmlns='http://schemas.microsoft.com/winfx/2006/xaml/presentation'
        xmlns:x='http://schemas.microsoft.com/winfx/2006/xaml'
        Title='Admin Tools Launcher' Height='850' Width='1500'
        WindowStartupLocation='CenterScreen' ResizeMode='CanResize'
        Background='#1E1E1E' Foreground='#F0F0F0' FontFamily='Segoe UI' FontSize='12'>

    <Window.Resources>
        <SolidColorBrush x:Key='AccentBrush' Color='#0E639C'/>
        <SolidColorBrush x:Key='ListItemBg' Color='#2D2D30'/>
        <SolidColorBrush x:Key='ListItemSel' Color='#094771'/>
        <SolidColorBrush x:Key='BorderBrush' Color='#3C3C3C'/>

        <Style x:Key='DarkListViewItemStyle' TargetType='ListViewItem'>
            <Setter Property='Background' Value='{StaticResource ListItemBg}'/>
            <Setter Property='Foreground' Value='#F0F0F0'/>
            <Setter Property='BorderBrush' Value='{StaticResource BorderBrush}'/>
            <Setter Property='BorderThickness' Value='0,0,0,1'/>
            <Setter Property='HorizontalContentAlignment' Value='Stretch'/>
            <Style.Triggers>
                <Trigger Property='IsSelected' Value='True'><Setter Property='Background' Value='{StaticResource ListItemSel}'/></Trigger>
                <Trigger Property='IsMouseOver' Value='True'><Setter Property='Background' Value='#3E3E42'/></Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType='GroupBox'>
            <Setter Property='Foreground' Value='White'/>
            <Setter Property='Margin' Value='2'/>
            <Setter Property='BorderBrush' Value='#3C3C3C'/>
            <Setter Property='FontWeight' Value='SemiBold'/>
        </Style>
    </Window.Resources>

    <Grid Margin='10'>
        <Grid.RowDefinitions>
            <RowDefinition Height='*'/>
            <RowDefinition Height='Auto'/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width='1*'/>
            <ColumnDefinition Width='1*'/>
            <ColumnDefinition Width='1.2*'/>
            <ColumnDefinition Width='1.2*'/>
        </Grid.ColumnDefinitions>

        <GroupBox Grid.Row='0' Grid.Column='0' Header='MMC Snap-ins (.msc)'>
            <ListView x:Name='MmcList' ItemContainerStyle='{StaticResource DarkListViewItemStyle}' Background='#252526' SelectionMode='Single'>
                <ListView.View><GridView><GridViewColumn Header='Name' DisplayMemberBinding='{Binding Name}' Width='220'/></GridView></ListView.View>
            </ListView>
        </GroupBox>

        <GroupBox Grid.Row='0' Grid.Column='1' Header='Control Panel (.cpl)'>
            <ListView x:Name='ControlList' ItemContainerStyle='{StaticResource DarkListViewItemStyle}' Background='#252526' SelectionMode='Single'>
                <ListView.View><GridView><GridViewColumn Header='Applet' DisplayMemberBinding='{Binding Name}' Width='220'/></GridView></ListView.View>
            </ListView>
        </GroupBox>

        <GroupBox Grid.Row='0' Grid.Column='2' Header='Deep Tasks (God Mode)'>
            <ListView x:Name='GodList' ItemContainerStyle='{StaticResource DarkListViewItemStyle}' Background='#252526' SelectionMode='Single'>
                <ListView.View><GridView><GridViewColumn Header='Task' DisplayMemberBinding='{Binding Name}' Width='330'/></GridView></ListView.View>
            </ListView>
        </GroupBox>

        <GroupBox Grid.Row='0' Grid.Column='3' Header='Modern Settings (ms-settings)'>
            <ListView x:Name='SettingsList' ItemContainerStyle='{StaticResource DarkListViewItemStyle}' Background='#252526' SelectionMode='Single'>
                <ListView.View><GridView><GridViewColumn Header='URI Path' DisplayMemberBinding='{Binding Name}' Width='330'/></GridView></ListView.View>
            </ListView>
        </GroupBox>

        <Border Grid.Row='1' Grid.ColumnSpan='4' BorderBrush='#3C3C3C' BorderThickness='0,1,0,0' Margin='0,10,0,0' Padding='0,10,0,0'>
            <Grid>
                <StackPanel Orientation='Horizontal' HorizontalAlignment='Left' VerticalAlignment='Center'>
                    <TextBlock Text='Filter:' VerticalAlignment='Center' Margin='0,0,10,0' FontWeight='SemiBold'/>
                    <TextBox x:Name='SearchBox' Width='300' Height='28' Background='#252526' Foreground='White' BorderBrush='#3C3C3C' Padding='5,2,5,0'/>
                    <CheckBox x:Name='AdminCheck' Content='Force Admin' Margin='15,0,0,0' VerticalAlignment='Center' IsChecked='True' Foreground='White'/>
                </StackPanel>

                <StackPanel Orientation='Horizontal' HorizontalAlignment='Center' VerticalAlignment='Center'>
                    <TextBlock Text='Context:' Foreground='#AAAAAA' VerticalAlignment='Center' Margin='0,0,5,0'/>
                    <TextBlock Text='$currentIdentity' Foreground='#00FF00' FontWeight='Bold' VerticalAlignment='Center'/>
                </StackPanel>

                <StackPanel Orientation='Horizontal' HorizontalAlignment='Right'>
                    <Button x:Name='AuthPsBtn' Content='Launch PowerShell' Width='130' Height='32' Background='#444444' Foreground='White' Margin='0,0,10,0'/>
                    <Button x:Name='LaunchBtn' Content='Launch Selected' Width='130' Height='32' Background='#0E639C' Foreground='White' FontWeight='Bold' Margin='0,0,10,0'/>
                    <Button x:Name='CloseBtn' Content='Exit' Width='70' Height='32' Background='#3E3E42' Foreground='White'/>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

# --- Setup Window ---
try { $window = [Windows.Markup.XamlReader]::Parse($xaml) } catch { return }

$SearchBox = $window.FindName("SearchBox")
$AdminCheck = $window.FindName("AdminCheck")
$MmcList = $window.FindName("MmcList")
$ControlList = $window.FindName("ControlList")
$GodList = $window.FindName("GodList")
$SettingsList = $window.FindName("SettingsList")
$AuthPsBtn = $window.FindName("AuthPsBtn")
$LaunchBtn = $window.FindName("LaunchBtn")
$CloseBtn = $window.FindName("CloseBtn")

# --- Discovery ---
$system32 = [Environment]::GetFolderPath("System")
$mmcMaster = New-Object System.Collections.Generic.List[PSObject]
$controlMaster = New-Object System.Collections.Generic.List[PSObject]
$godMaster = New-Object System.Collections.Generic.List[PSObject]
$settingsMaster = New-Object System.Collections.Generic.List[PSObject]

# 1. MMC
Get-ChildItem (Join-Path $system32 "*.msc") | ForEach-Object {
    if ($_.Name -match "fxs|tpm|pnt") { return }
    $friendly = (Get-Item $_.FullName).VersionInfo.FileDescription
    if (-not $friendly) { $friendly = $_.BaseName }
    $mmcMaster.Add((New-ToolItem -Name $friendly -FilePath "mmc.exe" -Argument $_.FullName))
}

# 2. Control Panel
Get-ChildItem (Join-Path $system32 "*.cpl") | ForEach-Object {
    $friendly = (Get-Item $_.FullName).VersionInfo.FileDescription
    if (-not $friendly) { $friendly = $_.BaseName }
    $controlMaster.Add((New-ToolItem -Name $friendly -FilePath "control.exe" -Argument $_.Name))
}

# 3. God Mode
$shell = New-Object -ComObject Shell.Application
$godFolder = $shell.NameSpace("shell:::{ED7BA470-8E54-465E-825C-99712043E01C}")
foreach ($item in $godFolder.Items()) {
    if ($item.Name) { $godMaster.Add((New-ToolItem -Name $item.Name -FilePath "SHELL_ITEM" -ShellItem $item)) }
}

# 4. Modern Settings (ms-settings)
$settingsDll = Join-Path $env:windir "ImmersiveControlPanel\SystemSettings.dll"
[MsSettingsScanner]::ExtractAll($settingsDll) | ForEach-Object {
    # Strip the prefix for a cleaner display name if desired, but keeping URI for clarity
    $settingsMaster.Add((New-ToolItem -Name $_ -FilePath "ms-settings" -Argument $_))
}

# Initial Sorting/Binding
$MmcList.ItemsSource = @($mmcMaster | Sort-Object Name)
$ControlList.ItemsSource = @($controlMaster | Sort-Object Name)
$GodList.ItemsSource = @($godMaster | Sort-Object Name)
$SettingsList.ItemsSource = @($settingsMaster | Sort-Object Name)

# --- Functions ---
function Start-Tool {
    param($Item, [bool]$AsAdmin)
    if (-not $Item) { return }
    try {
        if ($Item.FilePath -eq "SHELL_ITEM") { 
            $Item.ShellItem.InvokeVerb("open") 
        }
        elseif ($Item.FilePath -eq "ms-settings") {
            # Start-Process handles ms-settings: URIs natively via shell
            Start-Process $Item.Name
        }
        else {
            $psi = New-Object System.Diagnostics.ProcessStartInfo -Property @{
                FileName = $Item.FilePath; Arguments = $Item.Argument; UseShellExecute = $true
            }
            if ($AsAdmin) { $psi.Verb = "runas" }
            [System.Diagnostics.Process]::Start($psi) | Out-Null
        }
    }
    catch { [System.Windows.MessageBox]::Show("Launch Failed: $($_.Exception.Message)") }
}

# --- Selection Logic ---
$script:isUpdatingSelection = $false
function Update-ExclusiveSelection {
    param($sourceList)
    if ($script:isUpdatingSelection) { return }
    $script:isUpdatingSelection = $true
    $lists = $MmcList, $ControlList, $GodList, $SettingsList
    foreach ($list in $lists) { if ($list -ne $sourceList) { $list.UnselectAll() } }
    $script:isUpdatingSelection = $false
}

$MmcList.Add_SelectionChanged({ if ($MmcList.SelectedItem) { Update-ExclusiveSelection -sourceList $MmcList } })
$ControlList.Add_SelectionChanged({ if ($ControlList.SelectedItem) { Update-ExclusiveSelection -sourceList $ControlList } })
$GodList.Add_SelectionChanged({ if ($GodList.SelectedItem) { Update-ExclusiveSelection -sourceList $GodList } })
$SettingsList.Add_SelectionChanged({ if ($SettingsList.SelectedItem) { Update-ExclusiveSelection -sourceList $SettingsList } })

# --- Re-Auth Logic ---
$AuthPsBtn.Add_Click({
        try {
            $cred = Get-Credential -Message "Enter credentials for the NEW local session context"
            if ($cred) {
                Start-Process "powershell.exe" -ArgumentList "-NoExit -NoProfile" `
                    -Credential $cred `
                    -WorkingDirectory "$env:windir\System32" `
                    -LoadUserProfile
            }
        }
        catch {
            if ($_.Exception.Message -notmatch "cancelled") {
                [System.Windows.MessageBox]::Show("Auth Error: $($_.Exception.Message)")
            }
        }
    })

# --- UI Events ---
$LaunchBtn.Add_Click({ 
        $sel = ($MmcList.SelectedItem, $ControlList.SelectedItem, $GodList.SelectedItem, $SettingsList.SelectedItem | Where-Object { $_ })[0]
        Start-Tool -Item $sel -AsAdmin ([bool]$AdminCheck.IsChecked) 
    })

$MmcList.Add_MouseDoubleClick({ if ($MmcList.SelectedItem) { Start-Tool -Item $MmcList.SelectedItem -AsAdmin ([bool]$AdminCheck.IsChecked) } })
$ControlList.Add_MouseDoubleClick({ if ($ControlList.SelectedItem) { Start-Tool -Item $ControlList.SelectedItem -AsAdmin ([bool]$AdminCheck.IsChecked) } })
$GodList.Add_MouseDoubleClick({ if ($GodList.SelectedItem) { Start-Tool -Item $GodList.SelectedItem -AsAdmin ([bool]$AdminCheck.IsChecked) } })
$SettingsList.Add_MouseDoubleClick({ if ($SettingsList.SelectedItem) { Start-Tool -Item $SettingsList.SelectedItem -AsAdmin ([bool]$AdminCheck.IsChecked) } })

$SearchBox.Add_TextChanged({
        $t = $SearchBox.Text.ToLower()
        $MmcList.ItemsSource = @($mmcMaster | Where-Object { $_.Name.ToLower().Contains($t) } | Sort-Object Name)
        $ControlList.ItemsSource = @($controlMaster | Where-Object { $_.Name.ToLower().Contains($t) } | Sort-Object Name)
        $GodList.ItemsSource = @($godMaster | Where-Object { $_.Name.ToLower().Contains($t) } | Sort-Object Name)
        $SettingsList.ItemsSource = @($settingsMaster | Where-Object { $_.Name.ToLower().Contains($t) } | Sort-Object Name)
    })

$CloseBtn.Add_Click({ $window.Close() })
if ($window) { $window.ShowDialog() | Out-Null }