# =====================================================================
# BUILDER.PS1 - Dynamic UI Construction (Responsive App Cards)
# =====================================================================

function Initialize-AppList {
    $catIcons = @{
        "BROWSERS"       = [char]0xE774
        "COMMUNICATION"  = [char]0xE8BD
        "GAMING"         = [char]0xE7FC
        "SYSTEM TOOLS"   = [char]0xE912
        "MEDIA"          = [char]0xE714
        "DEVELOPMENT"    = [char]0xE943
    }

    foreach ($category in $script:AppCategories.Keys) {
        # Each category = vertical card containing header + apps
        $card                  = New-Object System.Windows.Controls.Border
        $card.CornerRadius     = New-Object System.Windows.CornerRadius(12)
        $card.MinWidth         = 220
        $card.MaxWidth         = 260
        $card.Margin           = New-Object System.Windows.Thickness(0, 0, 10, 10)
        $card.Padding          = New-Object System.Windows.Thickness(0, 0, 0, 6)
        $card.BorderThickness  = New-Object System.Windows.Thickness(1)
        $card.BorderBrush      = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#1E2858"))
        $card.VerticalAlignment = [System.Windows.VerticalAlignment]::Stretch

        $cardBg             = New-Object System.Windows.Media.LinearGradientBrush
        $cardBg.StartPoint  = New-Object System.Windows.Point(0, 0)
        $cardBg.EndPoint    = New-Object System.Windows.Point(0, 1)
        $s1 = New-Object System.Windows.Media.GradientStop
        $s1.Color  = [System.Windows.Media.ColorConverter]::ConvertFromString("#CC161B30")
        $s1.Offset = 0
        $s2 = New-Object System.Windows.Media.GradientStop
        $s2.Color  = [System.Windows.Media.ColorConverter]::ConvertFromString("#CC111628")
        $s2.Offset = 1
        $cardBg.GradientStops.Add($s1) | Out-Null
        $cardBg.GradientStops.Add($s2) | Out-Null
        $card.Background = $cardBg

        $shadow              = New-Object System.Windows.Media.Effects.DropShadowEffect
        $shadow.BlurRadius   = 12
        $shadow.ShadowDepth  = 2
        $shadow.Direction    = 270
        $shadow.Color        = [System.Windows.Media.Colors]::Black
        $shadow.Opacity      = 0.3
        $card.Effect         = $shadow

        $innerStack = New-Object System.Windows.Controls.StackPanel

        # â”€â”€ Category Header â”€â”€
        $headerBorder = New-Object System.Windows.Controls.Border
        $headerBorder.Padding = New-Object System.Windows.Thickness(12, 8, 12, 8)
        $headerBorder.BorderThickness = New-Object System.Windows.Thickness(0, 0, 0, 1)
        $headerBorder.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#141828"))
        $hBg = New-Object System.Windows.Media.LinearGradientBrush
        $hBg.StartPoint = New-Object System.Windows.Point(0, 0)
        $hBg.EndPoint   = New-Object System.Windows.Point(1, 0)
        $hs1 = New-Object System.Windows.Media.GradientStop
        $hs1.Color  = [System.Windows.Media.ColorConverter]::ConvertFromString("#13182E")
        $hs1.Offset = 0
        $hs2 = New-Object System.Windows.Media.GradientStop
        $hs2.Color  = [System.Windows.Media.ColorConverter]::ConvertFromString("#0F1424")
        $hs2.Offset = 1
        $hBg.GradientStops.Add($hs1) | Out-Null
        $hBg.GradientStops.Add($hs2) | Out-Null
        $headerBorder.Background = $hBg

        $hGrid = New-Object System.Windows.Controls.Grid
        $c1 = New-Object System.Windows.Controls.ColumnDefinition
        $c1.Width = [System.Windows.GridLength]::Auto
        $c2 = New-Object System.Windows.Controls.ColumnDefinition
        $c2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $c3 = New-Object System.Windows.Controls.ColumnDefinition
        $c3.Width = [System.Windows.GridLength]::Auto
        $hGrid.ColumnDefinitions.Add($c1) | Out-Null
        $hGrid.ColumnDefinitions.Add($c2) | Out-Null
        $hGrid.ColumnDefinitions.Add($c3) | Out-Null

        # Icon
        $icon = New-Object System.Windows.Controls.TextBlock
        $icon.Text = if ($catIcons.ContainsKey($category)) { "$($catIcons[$category])" } else { "â—" }
        $icon.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
        $icon.FontSize = 14
        $icon.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#5B6CF9"))
        $icon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $icon.Margin = New-Object System.Windows.Thickness(0, 0, 8, 0)
        [System.Windows.Controls.Grid]::SetColumn($icon, 0)

        $catTitle = New-Object System.Windows.Controls.TextBlock
        $catTitle.Text = $category
        $catTitle.FontSize = 10
        $catTitle.FontWeight = [System.Windows.FontWeights]::SemiBold
        $catTitle.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#8090C8"))
        $catTitle.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        [System.Windows.Controls.Grid]::SetColumn($catTitle, 1)

        $badge = New-Object System.Windows.Controls.Border
        $badge.CornerRadius = New-Object System.Windows.CornerRadius(8)
        $badge.Padding = New-Object System.Windows.Thickness(6, 1, 6, 1)
        $badge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#141C3C"))
        $badgeTxt = New-Object System.Windows.Controls.TextBlock
        $badgeTxt.Text = "$($script:AppCategories[$category].Count)"
        $badgeTxt.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#4A5888"))
        $badgeTxt.FontSize = 9
        $badge.Child = $badgeTxt
        [System.Windows.Controls.Grid]::SetColumn($badge, 2)

        $hGrid.Children.Add($icon)     | Out-Null
        $hGrid.Children.Add($catTitle) | Out-Null
        $hGrid.Children.Add($badge)    | Out-Null
        $headerBorder.Child = $hGrid
        $innerStack.Children.Add($headerBorder) | Out-Null

        # â”€â”€ App Checkboxes â”€â”€
        $appsScroll = New-Object System.Windows.Controls.ScrollViewer
        $appsScroll.VerticalScrollBarVisibility = "Auto"
        $appsScroll.HorizontalScrollBarVisibility = "Disabled"

        $appsPanel = New-Object System.Windows.Controls.StackPanel
        $appsPanel.Margin = New-Object System.Windows.Thickness(6, 4, 6, 0)

        foreach ($app in $script:AppCategories[$category]) {
            # Wrap each checkbox in a border for opacity animation
            $appCard = New-Object System.Windows.Controls.Border
            $appCard.Opacity = 1.0

            # Grid row: checkbox + status badge + installed badge + update badge
            $appGrid = New-Object System.Windows.Controls.Grid
            $col1 = New-Object System.Windows.Controls.ColumnDefinition
            $col1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
            $colStatus = New-Object System.Windows.Controls.ColumnDefinition
            $colStatus.Width = [System.Windows.GridLength]::Auto
            $col2 = New-Object System.Windows.Controls.ColumnDefinition
            $col2.Width = [System.Windows.GridLength]::Auto
            $col3 = New-Object System.Windows.Controls.ColumnDefinition
            $col3.Width = [System.Windows.GridLength]::Auto
            $appGrid.ColumnDefinitions.Add($col1) | Out-Null
            $appGrid.ColumnDefinitions.Add($colStatus) | Out-Null
            $appGrid.ColumnDefinitions.Add($col2) | Out-Null
            $appGrid.ColumnDefinitions.Add($col3) | Out-Null

            $cb = New-Object System.Windows.Controls.CheckBox
            $cb.Content = $app.Name
            $cb.Tag     = $app.Id
            $cb.Style   = $script:Window.Resources["ToggleCheckBox"]
            $cb.Add_Checked({ Update-Counter })
            $cb.Add_Unchecked({ Update-Counter })
            [System.Windows.Controls.Grid]::SetColumn($cb, 0)

            # Status badge (shows "Installing...", "Updating...", "✓ Done" etc.)
            $statusBadge = New-Object System.Windows.Controls.Border
            $statusBadge.CornerRadius = New-Object System.Windows.CornerRadius(6)
            $statusBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
            $statusBadge.Margin = New-Object System.Windows.Thickness(2, 0, 2, 0)
            $statusBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $statusBadge.Visibility = [System.Windows.Visibility]::Collapsed
            $statusBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#335B6CF9"))
            $statusBadge.BorderThickness = New-Object System.Windows.Thickness(1)
            $statusBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#555B6CF9"))

            $statusText = New-Object System.Windows.Controls.TextBlock
            $statusText.Text = ""
            $statusText.FontSize = 9
            $statusText.FontWeight = [System.Windows.FontWeights]::SemiBold
            $statusText.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#7B8CFF"))
            $statusText.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $statusBadge.Child = $statusText
            [System.Windows.Controls.Grid]::SetColumn($statusBadge, 1)

            # Installed indicator (hidden by default)
            $installedBadge = New-Object System.Windows.Controls.Border
            $installedBadge.CornerRadius = New-Object System.Windows.CornerRadius(6)
            $installedBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
            $installedBadge.Margin = New-Object System.Windows.Thickness(4, 0, 6, 0)
            $installedBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $installedBadge.Visibility = [System.Windows.Visibility]::Collapsed
            $installedBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#3322C55E"))

            $badgeStack = New-Object System.Windows.Controls.StackPanel
            $badgeStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal

            $checkIcon = New-Object System.Windows.Controls.TextBlock
            $checkIcon.Text = "$([char]0xE73E)"
            $checkIcon.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
            $checkIcon.FontSize = 9
            $checkIcon.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#22C55E"))
            $checkIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $checkIcon.Margin = New-Object System.Windows.Thickness(0, 0, 3, 0)

            $badgeText = New-Object System.Windows.Controls.TextBlock
            $badgeText.Text = "Installed"
            $badgeText.FontSize = 9
            $badgeText.FontWeight = [System.Windows.FontWeights]::SemiBold
            $badgeText.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#22C55E"))
            $badgeText.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

            $badgeStack.Children.Add($checkIcon) | Out-Null
            $badgeStack.Children.Add($badgeText) | Out-Null
            $installedBadge.Child = $badgeStack
            [System.Windows.Controls.Grid]::SetColumn($installedBadge, 2)

            # Update available indicator (hidden by default) — prominent orange
            $updateBadge = New-Object System.Windows.Controls.Border
            $updateBadge.CornerRadius = New-Object System.Windows.CornerRadius(6)
            $updateBadge.Padding = New-Object System.Windows.Thickness(6, 2, 6, 2)
            $updateBadge.Margin = New-Object System.Windows.Thickness(2, 0, 6, 0)
            $updateBadge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $updateBadge.Visibility = [System.Windows.Visibility]::Collapsed
            $updateBadge.Background = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#66F59E0B"))
            $updateBadge.BorderThickness = New-Object System.Windows.Thickness(1)
            $updateBadge.BorderBrush = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#99F59E0B"))
            $updateBadge.Cursor = [System.Windows.Input.Cursors]::Hand
            $updateBadge.ToolTip = "Click to update this application"

            $updStack = New-Object System.Windows.Controls.StackPanel
            $updStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal

            $updIcon = New-Object System.Windows.Controls.TextBlock
            $updIcon.Text = "$([char]0xE72C)"
            $updIcon.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
            $updIcon.FontSize = 9
            $updIcon.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#F59E0B"))
            $updIcon.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $updIcon.Margin = New-Object System.Windows.Thickness(0, 0, 3, 0)

            $updText = New-Object System.Windows.Controls.TextBlock
            $updText.Text = "Update"
            $updText.FontSize = 9
            $updText.FontWeight = [System.Windows.FontWeights]::SemiBold
            $updText.Foreground = [System.Windows.Media.SolidColorBrush]([System.Windows.Media.ColorConverter]::ConvertFromString("#F59E0B"))
            $updText.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

            $updStack.Children.Add($updIcon) | Out-Null
            $updStack.Children.Add($updText) | Out-Null
            $updateBadge.Child = $updStack
            $updateBadge.Tag = $app.Id
            $updateBadge.Add_MouseLeftButtonDown({
                param($s, $e)
                $appObj = $null
                foreach ($cat in $script:AppCategories.Keys) {
                    foreach ($a in $script:AppCategories[$cat]) {
                        if ($a.Id -eq $s.Tag) { $appObj = $a; break }
                    }
                }
                if ($appObj) { Update-App -Id $appObj.Id -Name $appObj.Name }
            })
            [System.Windows.Controls.Grid]::SetColumn($updateBadge, 3)

            $appGrid.Children.Add($cb) | Out-Null
            $appGrid.Children.Add($statusBadge) | Out-Null
            $appGrid.Children.Add($installedBadge) | Out-Null
            $appGrid.Children.Add($updateBadge) | Out-Null

            $script:CheckBoxMap[$app.Id] = $cb
            $script:AppCardMap[$app.Id]  = $appCard
            $script:InstalledBadgeMap[$app.Id] = $installedBadge
            $script:UpdateBadgeMap[$app.Id] = $updateBadge
            $script:StatusBadgeMap[$app.Id] = $statusBadge

            $appCard.Child = $appGrid
            $appsPanel.Children.Add($appCard) | Out-Null
        }

        $appsScroll.Content = $appsPanel
        $innerStack.Children.Add($appsScroll) | Out-Null

        $card.Child = $innerStack
        $script:AppListPanel.Children.Add($card) | Out-Null
    }
}
