# =====================================================================
# BUILDER.PS1 - Standalone Bundler for HumanTouch Setup (V2 - Safe Mode)
# =====================================================================
# Bu versiyon Literal String Replacement kullanarak kod bozulmasını önler.
# =====================================================================

$ProjectRoot = $PSScriptRoot
$MainFile    = Join-Path $ProjectRoot "HumanTouch-Setup.ps1"
$ModuleDir   = Join-Path $ProjectRoot "modules"
$OutputFile  = Join-Path $ProjectRoot "HumanTouch-Setup-Standalone.ps1"

Write-Host "--- Bundling HumanTouch Setup Standalone (Safe Mode) ---" -ForegroundColor Cyan

# Helper to read UTF8 regardless of BOM (Safe for PS 5.1)
$Utf8Encoding = New-Object System.Text.UTF8Encoding($false)

# 1. Ana dosyayı oku
if (-not (Test-Path $MainFile)) {
    Write-Error "Main file not found: $MainFile"
    exit 1
}

$Content = [System.IO.File]::ReadAllText($MainFile, $Utf8Encoding)

# 2. Modül yükleme satırlarını bul
$Pattern = '\. \(Join-Path \$moduleRoot "(.+?\.ps1)"\)'
$Matches = [regex]::Matches($Content, $Pattern)

foreach ($m in $Matches) {
    $Token = $m.Value
    $FileName = $m.Groups[1].Value
    $ModulePath = Join-Path $ModuleDir $FileName
    
    if (Test-Path $ModulePath) {
        Write-Host "[+] Safely Embedding: $FileName" -ForegroundColor Green
        $ModuleContent = [System.IO.File]::ReadAllText($ModulePath, $Utf8Encoding)
        
        $Injected = "`r`n# --- MODULE: $FileName START ---`r`n" + $ModuleContent + "`r`n# --- MODULE: $FileName END ---`r`n"
        $Content = $Content.Replace($Token, $Injected)
    } else {
        Write-Warning "[-] Module not found: $FileName"
    }
}

# 3. Klasör yolunu temizle
$TokenRoot = '$moduleRoot = Join-Path $PSScriptRoot "modules"'
$Content = $Content.Replace($TokenRoot, '# Standalone Mode Activated')

# 4. Çıktıyı kaydet
# UTF-8 Without BOM (PowerShell 5.1 iex / remote execution için en temiz yoldur)
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutputFile, $Content, $Utf8NoBom)

Write-Host "`n--- Success! ---" -ForegroundColor Green
Write-Host "Output: $OutputFile" -ForegroundColor Yellow
Write-Host "PowerShell 5.1 Standalone build is ready."