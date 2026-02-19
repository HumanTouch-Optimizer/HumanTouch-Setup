# =====================================================================
# PRESETS.PS1 - Save/Load Custom User Presets (File Dialog based)
# =====================================================================

function Import-PresetById {
    param([string[]]$Ids)
    foreach ($id in $script:CheckBoxMap.Keys) {
        $script:CheckBoxMap[$id].IsChecked = ($Ids -contains $id)
    }
    Update-Counter
}

function Show-SavePresetDialog {
    # Check if any apps are selected
    $selectedIds = @()
    foreach ($id in $script:CheckBoxMap.Keys) {
        if ($script:CheckBoxMap[$id].IsChecked -eq $true) {
            $selectedIds += $id
        }
    }

    if ($selectedIds.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "Please select at least one application before saving a preset.",
            "No Selection",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
        return
    }

    # Use Windows SaveFileDialog
    $dlg = New-Object Microsoft.Win32.SaveFileDialog
    $dlg.Title = "Save Preset As"
    $dlg.Filter = "HumanTouch Preset (*.htpreset)|*.htpreset|JSON Files (*.json)|*.json"
    $dlg.DefaultExt = ".htpreset"
    $dlg.FileName = "MyPreset"
    $dlg.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    $result = $dlg.ShowDialog($script:Window)

    if ($result -eq $true) {
        $presetName = [System.IO.Path]::GetFileNameWithoutExtension($dlg.FileName)
        $obj = @{
            Name    = $presetName
            AppIds  = $selectedIds
            Created = (Get-Date -Format "yyyy-MM-dd HH:mm")
            Version = "2.0"
        }
        $obj | ConvertTo-Json | Set-Content -Path $dlg.FileName -Encoding UTF8
        Write-Log "Preset saved: $presetName ($($selectedIds.Count) apps)"
        Set-Status "Preset '$presetName' saved to $($dlg.FileName)"
    }
}

function Show-LoadPresetDialog {
    # Use Windows OpenFileDialog
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Title = "Load Preset"
    $dlg.Filter = "HumanTouch Preset (*.htpreset)|*.htpreset|JSON Files (*.json)|*.json|All Files (*.*)|*.*"
    $dlg.DefaultExt = ".htpreset"
    $dlg.InitialDirectory = [Environment]::GetFolderPath("Desktop")

    $result = $dlg.ShowDialog($script:Window)

    if ($result -eq $true) {
        try {
            $data = Get-Content $dlg.FileName -Raw | ConvertFrom-Json
            $ids = @($data.AppIds)
            $presetName = if ($data.Name) { $data.Name } else { [System.IO.Path]::GetFileNameWithoutExtension($dlg.FileName) }

            Import-PresetById -Ids $ids
            Write-Log "Preset loaded: $presetName ($($ids.Count) apps)"
            Set-Status "Preset '$presetName' loaded from file."
        } catch {
            [System.Windows.MessageBox]::Show(
                "Failed to load preset file.`n`nError: $($_.Exception.Message)",
                "Load Error",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
        }
    }
}
