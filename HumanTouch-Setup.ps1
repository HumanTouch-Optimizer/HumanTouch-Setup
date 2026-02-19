#Requires -Version 5.1
<#
.SYNOPSIS
    HumanTouch Optimizer v2.0 - Modern Windows Application Installer
.DESCRIPTION
    Production-ready modular PowerShell GUI installer using winget.
    Features: Horizontal card layout, 3 icon presets, custom preset
    save/load, install animation feedback, internet check, DPI scaling.
.VERSION
    2.0
#>

# =====================================================================
# AUTO-ELEVATE TO ADMINISTRATOR
# =====================================================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    $scriptPath = $MyInvocation.MyCommand.Definition
    $arguments  = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# =====================================================================
# ASSEMBLIES
# =====================================================================
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# =====================================================================
# WINGET CHECK
# =====================================================================
function Test-Winget {
    $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
    if ($null -eq $wingetCmd) {
        [System.Windows.MessageBox]::Show(
            "winget (Windows Package Manager) was not found.`n`nPlease install App Installer from the Microsoft Store.",
            "winget Not Found",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        exit 1
    }
}
Test-Winget

# =====================================================================
# LOAD MODULES
# =====================================================================
$moduleRoot = Join-Path $PSScriptRoot "modules"

. (Join-Path $moduleRoot "Config.ps1")
. (Join-Path $moduleRoot "XAML.ps1")

# =====================================================================
# INITIALIZE WINDOW
# =====================================================================
$script:Reader = New-Object System.Xml.XmlNodeReader($script:XAML)
try {
    $script:Window = [Windows.Markup.XamlReader]::Load($script:Reader)
} catch {
    [System.Windows.MessageBox]::Show(
        "Failed to load UI:`n$($_.Exception.Message)",
        "UI Load Error",
        [System.Windows.MessageBoxButton]::OK,
        [System.Windows.MessageBoxImage]::Error
    ) | Out-Null
    exit 1
}

# Named control references
$script:AppListPanel      = $script:Window.FindName("AppListPanel")
$script:BtnInstall        = $script:Window.FindName("BtnInstall")
$script:BtnClear          = $script:Window.FindName("BtnClear")
$script:BtnClose          = $script:Window.FindName("BtnClose")
$script:BtnMinimize       = $script:Window.FindName("BtnMinimize")
$script:DragBar           = $script:Window.FindName("DragBar")
$script:StatusLabel       = $script:Window.FindName("StatusLabel")
$script:ProgressFill      = $script:Window.FindName("ProgressFill")
$script:ProgressGlow      = $script:Window.FindName("ProgressGlow")
$script:ProgressLabel     = $script:Window.FindName("ProgressLabel")
$script:LogBox            = $script:Window.FindName("LogBox")
$script:SelectedCounter   = $script:Window.FindName("SelectedCounter")
$script:NoInternetOverlay = $script:Window.FindName("NoInternetOverlay")
$script:BtnRetryInternet  = $script:Window.FindName("BtnRetryInternet")
$script:BtnPresetGaming   = $script:Window.FindName("BtnPresetGaming")
$script:BtnPresetWork     = $script:Window.FindName("BtnPresetWork")
$script:BtnPresetMedia    = $script:Window.FindName("BtnPresetMedia")
$script:BtnSavePreset     = $script:Window.FindName("BtnSavePreset")
$script:BtnLoadPreset     = $script:Window.FindName("BtnLoadPreset")
$script:BtnCheckUpdates  = $script:Window.FindName("BtnCheckUpdates")

# Install/Update overlay references
$script:InstallOverlay      = $script:Window.FindName("InstallOverlay")
$script:OverlayPulseRing    = $script:Window.FindName("OverlayPulseRing")
$script:OverlayIcon         = $script:Window.FindName("OverlayIcon")
$script:OverlayAppName      = $script:Window.FindName("OverlayAppName")
$script:OverlayAction       = $script:Window.FindName("OverlayAction")
$script:OverlayProgressFill = $script:Window.FindName("OverlayProgressFill")
$script:OverlayProgressGlow = $script:Window.FindName("OverlayProgressGlow")
$script:OverlayProgress     = $script:Window.FindName("OverlayProgress")
$script:OverlaySubStatus    = $script:Window.FindName("OverlaySubStatus")

# State maps
$script:CheckBoxMap        = @{}
$script:AppCardMap         = @{}
$script:InstalledBadgeMap  = @{}
$script:UpdateBadgeMap     = @{}
$script:StatusBadgeMap     = @{}
$script:PresetButtons      = @($script:BtnPresetGaming, $script:BtnPresetWork, $script:BtnPresetMedia)

# Load remaining modules (they need Window reference)
. (Join-Path $moduleRoot "Helpers.ps1")
. (Join-Path $moduleRoot "Presets.ps1")
. (Join-Path $moduleRoot "Builder.ps1")
. (Join-Path $moduleRoot "Installer.ps1")

# =====================================================================
# WINDOW CHROME
# =====================================================================
$script:BtnClose.Add_Click({ $script:Window.Close() })
$script:BtnMinimize.Add_Click({ $script:Window.WindowState = [System.Windows.WindowState]::Minimized })
$script:DragBar.Add_MouseLeftButtonDown({ $script:Window.DragMove() })

# =====================================================================
# SET PRESET ICON CONTENT (Segoe MDL2 Assets)
# =====================================================================
$script:BtnPresetGaming.Content = "$([char]0xE7FC)"
$script:BtnPresetWork.Content   = "$([char]0xE821)"
$script:BtnPresetMedia.Content  = "$([char]0xE714)"

# =====================================================================
# BUILD UI
# =====================================================================
Initialize-AppList

# =====================================================================
# PRESET BUTTON HANDLERS
# =====================================================================
$script:BtnPresetGaming.Add_Click({
    Import-PresetById -Ids $script:BuiltInPresets["Gaming"]
    Write-Log "Gaming preset applied."
    Set-Status "Gaming preset loaded."
})

$script:BtnPresetWork.Add_Click({
    Import-PresetById -Ids $script:BuiltInPresets["Work"]
    Write-Log "Work preset applied."
    Set-Status "Work preset loaded."
})

$script:BtnPresetMedia.Add_Click({
    Import-PresetById -Ids $script:BuiltInPresets["Media"]
    Write-Log "Media preset applied."
    Set-Status "Media preset loaded."
})

# =====================================================================
# CUSTOM PRESET HANDLERS
# =====================================================================
$script:BtnSavePreset.Add_Click({ Show-SavePresetDialog })
$script:BtnLoadPreset.Add_Click({ Show-LoadPresetDialog })

# =====================================================================
# CLEAR ALL BUTTON
# =====================================================================
$script:BtnClear.Add_Click({
    foreach ($id in $script:CheckBoxMap.Keys) {
        $script:CheckBoxMap[$id].IsChecked = $false
    }
    Update-Counter
    Write-Log "Selection cleared."
    Set-Status "All selections cleared."
})

# =====================================================================
# INSTALL BUTTON
# =====================================================================
$script:BtnInstall.Add_Click({ Start-Installation })

# =====================================================================
# CHECK UPDATES BUTTON
# =====================================================================
$script:BtnCheckUpdates.Add_Click({ Start-UpdateCheck })

# =====================================================================
# INTERNET RETRY BUTTON
# =====================================================================
$script:BtnRetryInternet.Add_Click({
    if (Test-InternetConnection) {
        Hide-NoInternetOverlay
        Write-Log "Internet connection restored."
        Set-Status "Online. Ready to install."
    } else {
        Write-Log "Still no internet connection."
    }
})

# =====================================================================
# STARTUP: Internet check + initial log
# =====================================================================
$ts = Get-Date -Format 'HH:mm:ss'
$script:LogBox.AppendText("[$ts]  HumanTouch Optimizer v2.0 initialized.`r`n")
$script:LogBox.AppendText("[$ts]  Administrator context confirmed.`r`n")
$script:LogBox.AppendText("[$ts]  winget package manager detected.`r`n")

if (-not (Test-InternetConnection)) {
    $script:NoInternetOverlay.Visibility = [System.Windows.Visibility]::Visible
    $script:LogBox.AppendText("[$ts]  WARNING: No internet connection detected.`r`n")
} else {
    $script:LogBox.AppendText("[$ts]  Internet connection verified.`r`n")
}

$script:LogBox.AppendText("[$ts]  Select applications and click Install Selected.`r`n")
$script:LogBox.AppendText("[$ts]  Scanning installed applications...`r`n")
Set-Status "Scanning installed applications..."

# Background scan for already installed apps
$scanRS = [RunspaceFactory]::CreateRunspace()
$scanRS.ApartmentState = "STA"
$scanRS.Open()
$scanRS.SessionStateProxy.SetVariable("dispRef",   $script:Window.Dispatcher)
$scanRS.SessionStateProxy.SetVariable("badgeMap",   $script:InstalledBadgeMap)
$scanRS.SessionStateProxy.SetVariable("cardMap",    $script:AppCardMap)
$scanRS.SessionStateProxy.SetVariable("statusRef",  $script:StatusLabel)
$scanRS.SessionStateProxy.SetVariable("logRef",     $script:LogBox)
$scanRS.SessionStateProxy.SetVariable("appCategories", $script:AppCategories)

$scanCode = {
    # Single winget call to get ALL installed apps (fast!)
    $dispRef.Invoke([action]{ $statusRef.Text = "Scanning installed applications..." })

    try {
        $allInstalled = & winget list --accept-source-agreements 2>&1 | Out-String
    } catch {
        $allInstalled = ""
    }

    $allApps = @()
    foreach ($cat in $appCategories.Keys) {
        foreach ($app in $appCategories[$cat]) {
            $allApps += $app
        }
    }

    $installedCount = 0

    foreach ($app in $allApps) {
        if ($allInstalled -match [regex]::Escape($app.Id)) {
            $installedCount++
            $dispRef.Invoke([action]{
                # Show badge
                $badge = $badgeMap[$app.Id]
                if ($badge) {
                    $badge.Visibility = [System.Windows.Visibility]::Visible
                }
                # Dim the card row to show it's already installed
                $card = $cardMap[$app.Id]
                if ($card) {
                    $card.Opacity = 0.55
                    $card.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#0A22C55E"))
                }
            }.GetNewClosure())
        }
    }

    $ts = Get-Date -Format 'HH:mm:ss'
    $dispRef.Invoke([action]{
        $logRef.AppendText("[$ts]  Scan complete: $installedCount of $($allApps.Count) app(s) already installed.`r`n")
        $logRef.ScrollToEnd()
        $statusRef.Text = "Ready - $installedCount app(s) already installed."
    })
}

$scanPS = [PowerShell]::Create().AddScript($scanCode)
$scanPS.Runspace = $scanRS
$scanPS.BeginInvoke() | Out-Null

# =====================================================================
# SHOW WINDOW
# =====================================================================
$script:Window.ShowDialog() | Out-Null
