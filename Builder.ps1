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

# 1. Ana dosyayı oku
if (-not (Test-Path $MainFile)) {
    Write-Error "Main file not found: $MainFile"
    exit 1
}

[string]$Content = Get-Content -Path $MainFile -Raw

# 2. Modül yükleme satırlarını bul
# Desen: . (Join-Path $moduleRoot "Filename.ps1")
$Pattern = '\. \(Join-Path \$moduleRoot "(.+?\.ps1)"\)'
$Matches = [regex]::Matches($Content, $Pattern)

foreach ($m in $Matches) {
    $Token = $m.Value # Bulunan satır: . (Join-Path $moduleRoot "...")
    $FileName = $m.Groups[1].Value
    $ModulePath = Join-Path $ModuleDir $FileName
    
    if (Test-Path $ModulePath) {
        Write-Host "[+] Safely Embedding: $FileName" -ForegroundColor Green
        $ModuleContent = Get-Content -Path $ModulePath -Raw
        
        $Injected = "`r`n# --- MODULE: $FileName START ---`r`n" + $ModuleContent + "`r`n# --- MODULE: $FileName END ---`r`n"
        
        # KRİTİK: Regex (-replace) yerine Literal Replace kullanıyoruz (.Replace)
        # Bu, kodun içindeki $ ve & karakterlerinin bozulmasını %100 engeller.
        $Content = $Content.Replace($Token, $Injected)
    } else {
        Write-Warning "[-] Module not found: $FileName"
    }
}

# 3. Klasör yolunu temizle
$TokenRoot = '$moduleRoot = Join-Path $PSScriptRoot "modules"'
$Content = $Content.Replace($TokenRoot, '# Standalone Mode Activated')

# 4. Çıktıyı kaydet
# UTF8 with BOM (PowerShell 5.1 iex uyumluluğu için en güvenli yoldur)
$Content | Set-Content -Path $OutputFile -Encoding UTF8 -Force

Write-Host "`n--- Success! ---" -ForegroundColor Green
Write-Host "Output: $OutputFile" -ForegroundColor Yellow
Write-Host "PowerShell 5.1 Standalone build is ready."