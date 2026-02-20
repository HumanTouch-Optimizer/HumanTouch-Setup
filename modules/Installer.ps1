# =====================================================================
# INSTALLER.PS1 - Background Installation Engine
# =====================================================================

function Show-InstallOverlay {
    param([string]$Action, [string]$AppName, [string]$SubText, [string]$IconChar, [string]$ProgressText,
          [switch]$ShowProgressBar)

    $script:Window.Dispatcher.Invoke([action]{
        $script:InstallOverlay.Opacity = 0
        $script:InstallOverlay.Visibility = [System.Windows.Visibility]::Visible
        $script:OverlayAction.Text = $Action
        $script:OverlayAppName.Text = $AppName
        $script:OverlayProgress.Text = $ProgressText
        $script:OverlaySubStatus.Text = $SubText
        $script:OverlayIcon.Text = $IconChar

        # Reset overlay progress bar
        $script:OverlayProgressFill.Width = 0
        $script:OverlayProgressGlow.Width = 0

        # Show/hide progress bar based on mode
        $pbParent = $script:OverlayProgressFill.Parent.Parent  # Border containing Grid
        if ($ShowProgressBar) {
            $pbParent.Visibility = [System.Windows.Visibility]::Visible
            $script:OverlayProgress.Visibility = [System.Windows.Visibility]::Visible
        } else {
            $pbParent.Visibility = [System.Windows.Visibility]::Collapsed
            $script:OverlayProgress.Visibility = [System.Windows.Visibility]::Collapsed
        }

        # Fade in animation
        $fadeIn = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeIn.From = 0; $fadeIn.To = 1.0
        $fadeIn.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(400))
        $fadeIn.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
        $script:InstallOverlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeIn)
    })

    # Start pulse animation timer for the ring
    if ($script:OverlayPulseTimer) {
        try { $script:OverlayPulseTimer.Stop() } catch {}
    }
    $script:OverlayPulseTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:OverlayPulseTimer.Interval = [TimeSpan]::FromMilliseconds(1200)
    $script:OverlayPulseDirection = $true
    $script:OverlayPulseTimer.Add_Tick({
        $ring = $script:OverlayPulseRing
        if ($ring) {
            $toOpacity = if ($script:OverlayPulseDirection) { 0.8 } else { 0.25 }
            $toScale = if ($script:OverlayPulseDirection) { 110 } else { 100 }
            $script:OverlayPulseDirection = -not $script:OverlayPulseDirection

            $opAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $opAnim.To = $toOpacity
            $opAnim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1100))
            $opAnim.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
            $ring.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $opAnim)

            $wAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $wAnim.To = $toScale
            $wAnim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1100))
            $wAnim.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
            $ring.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $wAnim)

            $hAnim = New-Object System.Windows.Media.Animation.DoubleAnimation
            $hAnim.To = $toScale
            $hAnim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(1100))
            $hAnim.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
            $ring.BeginAnimation([System.Windows.FrameworkElement]::HeightProperty, $hAnim)
        }
    })
    $script:OverlayPulseTimer.Start()
}

function Start-OverlayDotsAnimation {
    param([string]$BaseText)
    $script:OverlayDotsBase = $BaseText
    $script:OverlayDotsCount = 0
    if ($script:OverlayDotsTimer) {
        try { $script:OverlayDotsTimer.Stop() } catch {}
    }
    $script:OverlayDotsTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:OverlayDotsTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $script:OverlayDotsTimer.Add_Tick({
        $script:OverlayDotsCount = ($script:OverlayDotsCount % 3) + 1
        $dots = "." * $script:OverlayDotsCount
        $script:OverlaySubStatus.Text = "$($script:OverlayDotsBase)$dots"
    })
    $script:OverlayDotsTimer.Start()
}

function Stop-OverlayDotsAnimation {
    if ($script:OverlayDotsTimer) {
        try { $script:OverlayDotsTimer.Stop() } catch {}
    }
}

function Hide-InstallOverlay {
    # Stop all overlay timers
    Stop-OverlayDotsAnimation

    $script:Window.Dispatcher.Invoke([action]{
        # Stop pulse timer
        if ($script:OverlayPulseTimer) {
            try { $script:OverlayPulseTimer.Stop() } catch {}
        }

        # Fade out
        $fadeOut = New-Object System.Windows.Media.Animation.DoubleAnimation
        $fadeOut.To = 0
        $fadeOut.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(500))
        $fadeOut.EasingFunction = New-Object System.Windows.Media.Animation.QuadraticEase
        $script:InstallOverlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $fadeOut)
    })

    # Use a DispatcherTimer to hide after the animation completes (500ms)
    $hideTimer = New-Object System.Windows.Threading.DispatcherTimer
    $hideTimer.Interval = [TimeSpan]::FromMilliseconds(550)
    $hideTimer.Add_Tick({
        $script:InstallOverlay.Visibility = [System.Windows.Visibility]::Collapsed
        $script:InstallOverlay.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $null)
        $this.Stop()
    })
    $hideTimer.Start()
}

function Start-Installation {
    $selectedApps = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($id in $script:CheckBoxMap.Keys) {
        if ($script:CheckBoxMap[$id].IsChecked -eq $true) {
            foreach ($cat in $script:AppCategories.Keys) {
                foreach ($a in $script:AppCategories[$cat]) {
                    if ($a.Id -eq $id) {
                        $selectedApps.Add($a)
                        break
                    }
                }
            }
        }
    }

    if ($selectedApps.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "Please select at least one application to install.",
            "No Selection",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    # Check internet before starting
    if (-not (Test-InternetConnection)) {
        Show-NoInternetOverlay
        return
    }

    Set-UIEnabled -State $false
    Set-Progress -Current 0 -Total $selectedApps.Count
    Write-Log "Starting installation of $($selectedApps.Count) app(s)..."

    # Show the splash overlay with progress bar
    Show-InstallOverlay -Action "I N S T A L L I N G" -AppName "Preparing..." `
        -SubText "Please wait" -IconChar "$([char]0xE896)" `
        -ProgressText "0 / $($selectedApps.Count)" -ShowProgressBar
    Start-OverlayDotsAnimation -BaseText "Please wait"

    # Highlight all selected app cards and show 'Queued'
    $script:Window.Dispatcher.Invoke([action]{
        foreach ($app in $selectedApps) {
            $card = $script:AppCardMap[$app.Id]
            if ($card) { $card.Opacity = 0.8 }

            $sBadge = $script:StatusBadgeMap[$app.Id]
            if ($sBadge) {
                $sBadge.Visibility = [System.Windows.Visibility]::Visible
                $sBadge.Child.Text = "Queued"
                $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#A0ABC0"))
                $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#333A4560"))
                $sBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#553A4560"))
            }
        }
    })

    $dispRef    = $script:Window.Dispatcher
    $logRef     = $script:LogBox
    $statRef    = $script:StatusLabel
    $pbFill     = $script:ProgressFill
    $pbGlow     = $script:ProgressGlow
    $pbLbl      = $script:ProgressLabel
    $btnInst    = $script:BtnInstall
    $btnClr     = $script:BtnClear
    $cardMap    = $script:AppCardMap
    $appArray   = $selectedApps.ToArray()
    $presBtns   = $script:PresetButtons
    $statusMap  = $script:StatusBadgeMap

    # Overlay refs
    $ovAppName      = $script:OverlayAppName
    $ovAction       = $script:OverlayAction
    $ovProgressFill = $script:OverlayProgressFill
    $ovProgressGlow = $script:OverlayProgressGlow
    $ovProgress     = $script:OverlayProgress
    $ovSubStatus    = $script:OverlaySubStatus
    $ovIcon         = $script:OverlayIcon

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.ThreadOptions  = [System.Management.Automation.Runspaces.PSThreadOptions]::ReuseThread
    $rs.Open()

    $rs.SessionStateProxy.SetVariable("dispRef",   $dispRef)
    $rs.SessionStateProxy.SetVariable("logRef",    $logRef)
    $rs.SessionStateProxy.SetVariable("statRef",   $statRef)
    $rs.SessionStateProxy.SetVariable("pbFill",    $pbFill)
    $rs.SessionStateProxy.SetVariable("pbGlow",    $pbGlow)
    $rs.SessionStateProxy.SetVariable("pbLbl",     $pbLbl)
    $rs.SessionStateProxy.SetVariable("btnInst",   $btnInst)
    $rs.SessionStateProxy.SetVariable("btnClr",    $btnClr)
    $rs.SessionStateProxy.SetVariable("cardMap",   $cardMap)
    $rs.SessionStateProxy.SetVariable("appArray",  $appArray)
    $rs.SessionStateProxy.SetVariable("presBtns",  $presBtns)
    $rs.SessionStateProxy.SetVariable("statusMap", $statusMap)
    $rs.SessionStateProxy.SetVariable("ovAppName",      $ovAppName)
    $rs.SessionStateProxy.SetVariable("ovAction",       $ovAction)
    $rs.SessionStateProxy.SetVariable("ovProgressFill", $ovProgressFill)
    $rs.SessionStateProxy.SetVariable("ovProgressGlow", $ovProgressGlow)
    $rs.SessionStateProxy.SetVariable("ovProgress",     $ovProgress)
    $rs.SessionStateProxy.SetVariable("ovSubStatus",    $ovSubStatus)
    $rs.SessionStateProxy.SetVariable("ovIcon",         $ovIcon)

    $psCode = {
        function Write-RSLog {
            param([string]$Msg)
            $ts = Get-Date -Format "HH:mm:ss"
            $line = "[$ts]  $Msg"
            $dispRef.Invoke([action]{
                $logRef.AppendText("$line`r`n")
                $logRef.ScrollToEnd()
            })
        }

        function Set-RSStatus {
            param([string]$Msg)
            $dispRef.Invoke([action]{ $statRef.Text = $Msg })
        }

        function Set-RSProgress {
            param([int]$Cur, [int]$Tot)
            $dispRef.Invoke([action]{
                $pbLbl.Text = "$Cur / $Tot"
                if ($Tot -gt 0) {
                    $pw = $pbFill.Parent.ActualWidth
                    if ($pw -le 0) { $pw = 200 }
                    $fw = [Math]::Round(($Cur / $Tot) * $pw, 1)
                    $pbFill.Width = $fw
                    $pbGlow.Width = $fw
                }
            })
        }

        function Set-OverlayProgress {
            param([int]$Cur, [int]$Tot)
            $dispRef.Invoke([action]{
                $ovProgress.Text = "$Cur / $Tot"
                if ($Tot -gt 0) {
                    $fw = [Math]::Round(($Cur / $Tot) * 278, 1)
                    $ovProgressFill.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $null)
                    $ovProgressGlow.BeginAnimation([System.Windows.FrameworkElement]::WidthProperty, $null)
                    $ovProgressFill.Width = $fw
                    $ovProgressGlow.Width = $fw
                }
            })
        }

        function Set-OverlayApp {
            param([string]$Name, [string]$SubText)
            $dispRef.Invoke([action]{
                $ovAppName.Text = $Name
                $ovSubStatus.Text = $SubText
            })
        }

        function Invoke-RSCardAnimation {
            param([string]$Id)
            $dispRef.Invoke([action]{
                $card = $cardMap[$Id]
                if ($card) {
                    $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
                    $anim.From     = $card.Opacity
                    $anim.To       = 1.0
                    $anim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(800))
                    $ease = New-Object System.Windows.Media.Animation.QuadraticEase
                    $ease.EasingMode = [System.Windows.Media.Animation.EasingMode]::EaseOut
                    $anim.EasingFunction = $ease
                    $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
                }
            })
        }

        function Set-RSStatusBadge {
            param([string]$Id, [string]$Text, [string]$Color, [bool]$Visible = $true)
            $dispRef.Invoke([action]{
                $badge = $statusMap[$Id]
                if ($badge) {
                    if ($Visible) {
                        $badge.Visibility = [System.Windows.Visibility]::Visible
                        $badge.Child.Text = $Text
                        $badge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString($Color))
                        $badge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("$($Color.Substring(0,1))33$($Color.Substring(1))"))
                        $badge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("$($Color.Substring(0,1))55$($Color.Substring(1))"))
                    } else {
                        $badge.Visibility = [System.Windows.Visibility]::Collapsed
                    }
                }
            })
        }

        function Test-RSInstalled {
            param([string]$Id)
            try {
                $out = & winget list --id $Id --accept-source-agreements 2>&1
                foreach ($line in $out) {
                    if ($line -is [string] -and $line -match [regex]::Escape($Id)) {
                        return $true
                    }
                }
            } catch { }
            return $false
        }

        $total   = $appArray.Count
        $current = 0
        $successCount = 0
        $failCount = 0
        $skipCount = 0

        foreach ($app in $appArray) {
            Set-RSProgress -Cur $current -Tot $total
            Set-OverlayProgress -Cur $current -Tot $total
            Set-OverlayApp -Name $app.Name -SubText "Checking installation status..."
            Write-RSLog "Checking: $($app.Name)..."
            Set-RSStatus "[$($current+1)/$total] Checking: $($app.Name)"

            if (Test-RSInstalled -Id $app.Id) {
                Write-RSLog "Already installed: $($app.Name)"
                Set-RSStatusBadge -Id $app.Id -Text "`u{2713} Installed" -Color "#22C55E"
                Set-OverlayApp -Name $app.Name -SubText "Already installed, skipping..."
                Invoke-RSCardAnimation -Id $app.Id
                $skipCount++
                Start-Sleep -Milliseconds 300
            } else {
                Write-RSLog "Installing: $($app.Name) [$($app.Id)]"
                Set-RSStatus "[$($current+1)/$total] Installing: $($app.Name)..."
                Set-RSStatusBadge -Id $app.Id -Text "Installing..." -Color "#7B8CFF"
                Set-OverlayApp -Name $app.Name -SubText "Downloading and installing via winget..."

                try {
                    $proc = Start-Process -FilePath "winget" `
                        -ArgumentList "install --id $($app.Id) -e --silent --accept-package-agreements --accept-source-agreements" `
                        -Wait -PassThru -WindowStyle Hidden

                    $code = $proc.ExitCode
                    if ($code -eq 0) {
                        Write-RSLog "$([char]0x2713) Successfully installed: $($app.Name)"
                        Set-RSStatusBadge -Id $app.Id -Text "$([char]0x2713) Installed" -Color "#22C55E"
                        Set-OverlayApp -Name $app.Name -SubText "Successfully installed!"
                        $successCount++
                    } elseif ($code -eq -1978335189) {
                        Write-RSLog "Already up to date: $($app.Name)"
                        Set-RSStatusBadge -Id $app.Id -Text "$([char]0x2713) Up to date" -Color "#22C55E"
                        Set-OverlayApp -Name $app.Name -SubText "Already up to date."
                        $skipCount++
                    } else {
                        Write-RSLog "$([char]0x2717) Exit code $code : $($app.Name)"
                        Set-RSStatusBadge -Id $app.Id -Text "$([char]0x2717) Failed ($code)" -Color "#EF4444"
                        Set-OverlayApp -Name $app.Name -SubText "Installation failed (exit code: $code)"
                        $failCount++
                    }
                } catch {
                    Write-RSLog "`u{2717} Error: $($app.Name) - $($_.Exception.Message)"
                    Set-RSStatusBadge -Id $app.Id -Text "`u{2717} Error" -Color "#EF4444"
                    Set-OverlayApp -Name $app.Name -SubText "Error: $($_.Exception.Message)"
                    $failCount++
                }
                Invoke-RSCardAnimation -Id $app.Id
                Start-Sleep -Milliseconds 500
            }

            $current++
            Set-RSProgress -Cur $current -Tot $total
            Set-OverlayProgress -Cur $current -Tot $total
        }

        $summary = "Done: $successCount installed, $skipCount skipped"
        if ($failCount -gt 0) { $summary += ", $failCount failed" }
        Write-RSLog $summary
        Set-RSStatus $summary

        # Show completion on overlay
        $dispRef.Invoke([action]{
            $ovAppName.Text = "All Done!"
            $ovAction.Text = "C O M P L E T E"
            $ovSubStatus.Text = $summary
            $ovIcon.Text = "$([char]0xE73E)"
        })

        Start-Sleep -Milliseconds 2000

        # Re-enable UI from runspace
        $dispRef.Invoke([action]{
            $btnInst.IsEnabled = $true
            $btnClr.IsEnabled  = $true
            foreach ($b in $presBtns) { $b.IsEnabled = $true }
        })
    }

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    $ps.AddScript($psCode) | Out-Null
    $ps.BeginInvoke() | Out-Null

    # Schedule overlay hide after a delay using a DispatcherTimer
    # We estimate completion will trigger the hide from a separate timer
    # that checks if the runspace has finished
    $checkTimer = New-Object System.Windows.Threading.DispatcherTimer
    $checkTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $script:InstallPS = $ps
    $checkTimer.Add_Tick({
        if ($script:InstallPS.InvocationStateInfo.State -ne 'Running') {
            Hide-InstallOverlay
            $this.Stop()
        }
    })
    $checkTimer.Start()
}

function Start-UpdateCheck {
    Set-UIEnabled -State $false
    Set-Status "Checking for updates..."
    Write-Log "Searching for available updates using winget..."

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.Open()

    $rs.SessionStateProxy.SetVariable("dispRef",    $script:Window.Dispatcher)
    $rs.SessionStateProxy.SetVariable("updMap",     $script:UpdateBadgeMap)
    $rs.SessionStateProxy.SetVariable("cardMap",    $script:AppCardMap)
    $rs.SessionStateProxy.SetVariable("logRef",     $script:LogBox)
    $rs.SessionStateProxy.SetVariable("statRef",    $script:StatusLabel)
    $rs.SessionStateProxy.SetVariable("btnInst",    $script:BtnInstall)
    $rs.SessionStateProxy.SetVariable("btnUpd",     $script:BtnCheckUpdates)
    $rs.SessionStateProxy.SetVariable("btnClr",     $script:BtnClear)
    $rs.SessionStateProxy.SetVariable("presBtns",   $script:PresetButtons)
    $rs.SessionStateProxy.SetVariable("appCategories", $script:AppCategories)

    $checkCode = {
        function Write-RSLog {
            param([string]$Msg)
            $ts = Get-Date -Format "HH:mm:ss"
            $line = "[$ts]  $Msg"
            $dispRef.Invoke([action]{
                $logRef.AppendText("$line`r`n")
                $logRef.ScrollToEnd()
            })
        }

        $out = ""
        try {
            $tmpFile = New-TemporaryFile
            $proc = Start-Process -FilePath "winget" -ArgumentList "list --upgrade-available --accept-source-agreements" -Wait -WindowStyle Hidden -PassThru -RedirectStandardOutput $tmpFile.FullName
            $out = Get-Content $tmpFile.FullName -Raw
            Remove-Item $tmpFile.FullName -Force -ErrorAction SilentlyContinue
        } catch {}

        $foundAny = $false
        $updIds = [System.Collections.Generic.List[string]]::new()
        foreach ($cat in $appCategories.Keys) {
            foreach ($app in $appCategories[$cat]) {
                if ($out -match [regex]::Escape($app.Id)) {
                    $foundAny = $true
                    $updIds.Add($app.Id)
                }
            }
        }

        if ($updIds.Count -gt 0) {
            $dispRef.Invoke([action]{
                foreach ($id in $updIds) {
                    # Show update badge
                    if ($updMap[$id]) {
                        $updMap[$id].Visibility = [System.Windows.Visibility]::Visible
                    }
                    # Highlight card with orange background
                    $card = $cardMap[$id]
                    if ($card) {
                        $card.Background = [System.Windows.Media.SolidColorBrush](
                            [System.Windows.Media.ColorConverter]::ConvertFromString("#18F59E0B"))
                        $card.BorderThickness = New-Object System.Windows.Thickness(2, 0, 0, 0)
                        $card.BorderBrush = [System.Windows.Media.SolidColorBrush](
                            [System.Windows.Media.ColorConverter]::ConvertFromString("#55F59E0B"))
                        $card.CornerRadius = New-Object System.Windows.CornerRadius(4)
                        $card.Padding = New-Object System.Windows.Thickness(6, 2, 4, 2)
                        $card.Margin = New-Object System.Windows.Thickness(0, 1, 0, 1)
                    }
                }
            })
        }

        if ($foundAny) {
            Write-RSLog "Updates found! Look for the orange 'Update' badges next to apps."
        } else {
            Write-RSLog "No updates found for your selected apps."
        }

        $dispRef.Invoke([action]{
            $statRef.Text = "Update check complete."
            $btnInst.IsEnabled = $true
            $btnUpd.IsEnabled  = $true
            $btnClr.IsEnabled  = $true
            foreach ($b in $presBtns) { $b.IsEnabled = $true }
        })
    }

    $ps = [System.Management.Automation.PowerShell]::Create().AddScript($checkCode)
    $ps.Runspace = $rs
    $ps.BeginInvoke() | Out-Null
}

function Update-App {
    param([string]$Id, [string]$Name)

    Set-UIEnabled -State $false
    Set-Status "Updating: $Name..."
    Write-Log "Starting update for $Name [$Id]..."

    # Show the splash overlay for update (Progress bar hidden, will use dots instead)
    Show-InstallOverlay -Action "U P D A T I N G" -AppName $Name `
        -SubText "Upgrading" -IconChar "$([char]0xE72C)" `
        -ProgressText ""
    Start-OverlayDotsAnimation -BaseText "Upgrading"

    $script:Window.Dispatcher.Invoke([action]{
        # Show status badge on the card
        $sBadge = $script:StatusBadgeMap[$Id]
        if ($sBadge) {
            $sBadge.Visibility = [System.Windows.Visibility]::Visible
            $sBadge.Child.Text = "Updating..."
            $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#F59E0B"))
            $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#33F59E0B"))
            $sBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#55F59E0B"))
        }

        # Hide update badge while updating
        $uBadge = $script:UpdateBadgeMap[$Id]
        if ($uBadge) { $uBadge.Visibility = [System.Windows.Visibility]::Collapsed }

        # Keep card visible (overlay is already covering the screen)
    })

    $rs = [RunspaceFactory]::CreateRunspace()
    $rs.ApartmentState = [System.Threading.ApartmentState]::STA
    $rs.Open()

    $rs.SessionStateProxy.SetVariable("dispRef",    $script:Window.Dispatcher)
    $rs.SessionStateProxy.SetVariable("logRef",     $script:LogBox)
    $rs.SessionStateProxy.SetVariable("statRef",    $script:StatusLabel)
    $rs.SessionStateProxy.SetVariable("updMap",     $script:UpdateBadgeMap)
    $rs.SessionStateProxy.SetVariable("statusMap",  $script:StatusBadgeMap)
    $rs.SessionStateProxy.SetVariable("cardMap",    $script:AppCardMap)
    $rs.SessionStateProxy.SetVariable("id",         $Id)
    $rs.SessionStateProxy.SetVariable("name",       $Name)
    $rs.SessionStateProxy.SetVariable("btnInst",    $script:BtnInstall)
    $rs.SessionStateProxy.SetVariable("btnUpd",     $script:BtnCheckUpdates)
    $rs.SessionStateProxy.SetVariable("btnClr",     $script:BtnClear)
    $rs.SessionStateProxy.SetVariable("presBtns",   $script:PresetButtons)
    $rs.SessionStateProxy.SetVariable("ovAppName",      $script:OverlayAppName)
    $rs.SessionStateProxy.SetVariable("ovAction",       $script:OverlayAction)
    $rs.SessionStateProxy.SetVariable("ovSubStatus",    $script:OverlaySubStatus)
    $rs.SessionStateProxy.SetVariable("ovIcon",         $script:OverlayIcon)
    $rs.SessionStateProxy.SetVariable("ovProgressFill", $script:OverlayProgressFill)
    $rs.SessionStateProxy.SetVariable("ovProgressGlow", $script:OverlayProgressGlow)

    $updCode = {
        function Write-RSLog {
            param([string]$Msg)
            $ts = Get-Date -Format "HH:mm:ss"
            $line = "[$ts]  $Msg"
            $dispRef.Invoke([action]{
                $logRef.AppendText("$line`r`n")
                $logRef.ScrollToEnd()
            })
        }

        try {
            $proc = Start-Process -FilePath "winget" `
                -ArgumentList "upgrade --id $id -e --silent --accept-package-agreements --accept-source-agreements" `
                -Wait -PassThru -WindowStyle Hidden
            
            if ($proc.ExitCode -eq 0) {
                Write-RSLog "$([char]0x2713) Successfully updated: $name"
                $dispRef.Invoke([action]{
                    if ($updMap[$id]) { $updMap[$id].Visibility = [System.Windows.Visibility]::Collapsed }
                    $sBadge = $statusMap[$id]
                    if ($sBadge) {
                        $sBadge.Visibility = [System.Windows.Visibility]::Visible
                        $sBadge.Child.Text = "$([char]0x2713) Updated"
                        $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#22C55E"))
                        $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#3322C55E"))
                        $sBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#5522C55E"))
                    }
                    $card = $cardMap[$id]
                    if ($card) {
                        $card.Opacity = 1.0
                        $card.Background = [System.Windows.Media.Brushes]::Transparent
                        $card.BorderThickness = New-Object System.Windows.Thickness(0)
                        $card.BorderBrush = $null
                        $card.Padding = New-Object System.Windows.Thickness(0)
                        $card.Margin = New-Object System.Windows.Thickness(0)
                    }
                    # Update overlay to show success
                    $ovAppName.Text = $name
                    $ovAction.Text = "C O M P L E T E"
                    $ovSubStatus.Text = "Successfully updated!"
                    $ovIcon.Text = "$([char]0xE73E)"
                    Stop-OverlayDotsAnimation
                })
            } else {
                Write-RSLog "`u{2717} Update failed (exit code $($proc.ExitCode)): ${name}"
                $dispRef.Invoke([action]{
                    $sBadge = $statusMap[$id]
                    if ($sBadge) {
                        $sBadge.Visibility = [System.Windows.Visibility]::Visible
                        $sBadge.Child.Text = "`u{2717} Failed"
                        $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#EF4444"))
                        $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#33EF4444"))
                        $sBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#55EF4444"))
                    }
                    if ($updMap[$id]) { $updMap[$id].Visibility = [System.Windows.Visibility]::Visible }
                    $card = $cardMap[$id]
                    if ($card) {
                        $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
                        $anim.From = $card.Opacity; $anim.To = 1.0
                        $anim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(600))
                        $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
                    }
                    $ovAppName.Text = $name
                    $ovAction.Text = "F A I L E D"
                    $ovSubStatus.Text = "Update failed (exit code: $($proc.ExitCode))"
                    $ovIcon.Text = "$([char]0xE711)"
                    Stop-OverlayDotsAnimation
                })
            }
        } catch {
            Write-RSLog "$([char]0x2717) Error updating ${name}: $($_.Exception.Message)"
            $dispRef.Invoke([action]{
                $sBadge = $statusMap[$id]
                if ($sBadge) {
                    $sBadge.Visibility = [System.Windows.Visibility]::Visible
                    $sBadge.Child.Text = "$([char]0x2717) Error"
                    $sBadge.Child.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#EF4444"))
                    $sBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#33EF4444"))
                }
                if ($updMap[$id]) { $updMap[$id].Visibility = [System.Windows.Visibility]::Visible }
                $card = $cardMap[$id]
                if ($card) {
                    $anim = New-Object System.Windows.Media.Animation.DoubleAnimation
                    $anim.From = $card.Opacity; $anim.To = 1.0
                    $anim.Duration = New-Object System.Windows.Duration([TimeSpan]::FromMilliseconds(600))
                    $card.BeginAnimation([System.Windows.UIElement]::OpacityProperty, $anim)
                }
                $ovAppName.Text = $name
                $ovAction.Text = "E R R O R"
                $ovSubStatus.Text = "An error occurred during update"
                $ovIcon.Text = "$([char]0xE711)"
                Stop-OverlayDotsAnimation
            })
        }

        Start-Sleep -Milliseconds 2000

        $dispRef.Invoke([action]{
            $statRef.Text = "Update complete."
            $btnInst.IsEnabled = $true
            $btnUpd.IsEnabled  = $true
            $btnClr.IsEnabled  = $true
            foreach ($b in $presBtns) { $b.IsEnabled = $true }
        })
    }

    $ps = [System.Management.Automation.PowerShell]::Create().AddScript($updCode)
    $ps.Runspace = $rs
    $ps.BeginInvoke() | Out-Null

    # Monitor runspace completion and hide overlay
    $script:UpdatePS = $ps
    $checkTimer = New-Object System.Windows.Threading.DispatcherTimer
    $checkTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $checkTimer.Add_Tick({
        if ($script:UpdatePS.InvocationStateInfo.State -ne 'Running') {
            Hide-InstallOverlay
            $this.Stop()
        }
    })
    $checkTimer.Start()
}
