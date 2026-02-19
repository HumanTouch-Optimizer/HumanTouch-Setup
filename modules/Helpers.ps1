# =====================================================================
# HELPERS.PS1 - Utility Functions
# =====================================================================

function Test-InternetConnection {
    try {
        $req = [System.Net.WebRequest]::Create("http://www.msftconnecttest.com/connecttest.txt")
        $req.Timeout = 3000
        $req.Method = "HEAD"
        $resp = $req.GetResponse()
        $resp.Close()
        return $true
    } catch {
        return $false
    }
}

function Write-Log {
    param([string]$Message)
    $ts   = Get-Date -Format "HH:mm:ss"
    $line = "[$ts]  $Message"
    $script:Window.Dispatcher.Invoke([action]{
        $script:LogBox.AppendText("$line`r`n")
        $script:LogBox.ScrollToEnd()
    })
}

function Set-Status {
    param([string]$Message)
    $script:Window.Dispatcher.Invoke([action]{
        $script:StatusLabel.Text = $Message
    })
}

function Set-Progress {
    param([int]$Current, [int]$Total)
    $script:Window.Dispatcher.Invoke([action]{
        $script:ProgressLabel.Text = "$Current / $Total"
        if ($Total -gt 0) {
            $pw = $script:ProgressFill.Parent.ActualWidth
            if ($pw -le 0) { $pw = 200 }
            $fw = [Math]::Round(($Current / $Total) * $pw, 1)
            $script:ProgressFill.Width = $fw
            $script:ProgressGlow.Width = $fw
        }
    })
}

function Set-UIEnabled {
    param([bool]$State)
    $script:Window.Dispatcher.Invoke([action]{
        $script:BtnInstall.IsEnabled      = $State
        $script:BtnCheckUpdates.IsEnabled = $State
        $script:BtnClear.IsEnabled        = $State
        foreach ($btn in $script:PresetButtons) {
            $btn.IsEnabled = $State
        }
    })
}

function Update-Counter {
    $count = 0
    foreach ($id in $script:CheckBoxMap.Keys) {
        if ($script:CheckBoxMap[$id].IsChecked -eq $true) { $count++ }
    }
    $script:SelectedCounter.Text = "$count"
    $script:BtnInstall.IsEnabled = ($count -gt 0)
}

function Set-AppCardInstalled {
    param([string]$AppId)
    $script:Window.Dispatcher.Invoke([action]{
        $card = $script:AppCardMap[$AppId]
        if ($card) {
            # Animate opacity to full
            $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $anim.From     = $card.Opacity
            $anim.To       = 1.0
            $anim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(600))
            $anim.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
            $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)

            # Add green check indicator
            $indicator = $card.FindName("InstallIndicator_$($AppId.Replace('.','_'))")
            if ($indicator) {
                $indicator.Visibility = [System.Windows.Visibility]::Visible
            }
        }
    })
}

function Show-NoInternetOverlay {
    $script:Window.Dispatcher.Invoke([action]{
        $script:NoInternetOverlay.Visibility = [System.Windows.Visibility]::Visible
    })
}

function Hide-NoInternetOverlay {
    $script:Window.Dispatcher.Invoke([action]{
        $script:NoInternetOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    })
}
