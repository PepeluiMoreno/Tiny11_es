 <# =====================================================================
File: PostSetup_Tiny11_ES_BloatFree.ps1
Updated: 2025-10-22 14:05 (Europe/Madrid)
Brief: Post-instalación Tiny11/Win11: idioma ES (online/offline con .cab),
       desbloat (Edge/OneDrive/UWP), telemetría mínima, servicios y rendimiento.
Usage:
  - Online (auto):   .\PostSetup_Tiny11_ES_BloatFree.ps1
  - Offline cabs:    .\PostSetup_Tiny11_ES_BloatFree.ps1 -OfflineCabPath "D:\es-ES-cab"
  - Sin ruta y sin WU: abrirá un selector de carpeta para elegir los .cab.
Notes:
  - No toca WebView2 (lo usa Configuración).
  - Reinicia al final para aplicar UI español.
===================================================================== #>

param(
  [string]$OfflineCabPath = ""
)

# -------------------- Configuración --------------------
$LangTag = "es-ES"
$RequiredCabPatterns = @(
  "Client-Language-Pack.*_es-es\.cab",                   # LP base
  "LanguageFeatures-Speech-.*_es-es-.*\.cab",
  "LanguageFeatures-TextToSpeech-.*_es-es-.*\.cab",
  "LanguageFeatures-OCR-.*_es-es-.*\.cab",
  "LanguageFeatures-Handwriting-.*_es-es-.*\.cab"
)
$FOD_Capabilities = @(
  "Language.Basic~~~es-ES~0.0.1.0",
  "Language.Speech~~~es-ES~0.0.1.0",
  "Language.TextToSpeech~~~es-ES~0.0.1.0",
  "Language.OCR~~~es-ES~0.0.1.0",
  "Language.Handwriting~~~es-ES~0.0.1.0"
)
$Log = Join-Path $env:USERPROFILE "Desktop\PostSetup_Tiny11_ES_BloatFree.log"

# -------------------- Utilidades --------------------
Start-Transcript -Path $Log -Append | Out-Null
function Write-Info($m){ Write-Host "[INFO] $m" -ForegroundColor Cyan }
function Write-Ok($m){ Write-Host "[ OK ] $m" -ForegroundColor Green }
function Write-Warn($m){ Write-Host "[WARN] $m" -ForegroundColor Yellow }
function Write-Err($m){ Write-Host "[ERR ] $m" -ForegroundColor Red }

function Require-Admin {
  if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "Ejecuta este script como Administrador."; Stop-Transcript | Out-Null; exit 1
  }
}

function Test-Internet {
  try {
    $r = Test-NetConnection "download.windowsupdate.com" -Port 80 -WarningAction SilentlyContinue
    return ($r.TcpTestSucceeded -eq $true)
  } catch { return $false }
}

function Ensure-WU-Services {
  foreach ($s in @("wuauserv","bits","cryptsvc")){
    try { Set-Service $s -StartupType Manual -ErrorAction SilentlyContinue; Start-Service $s -ErrorAction SilentlyContinue } catch {}
  }
}

function Select-FolderDialog {
  Add-Type -AssemblyName System.Windows.Forms | Out-Null
  $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
  $fbd.Description = "Selecciona la carpeta que contiene los .cab es-ES (LP + FOD)"
  $fbd.ShowNewFolderButton = $false
  if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    return $fbd.SelectedPath
  }
  return $null
}

# -------------------- Idioma: ONLINE u OFFLINE --------------------
function Install-Language-Online {
  Write-Info "Modo ONLINE: instalando capacidades de idioma vía DISM…"
  Ensure-WU-Services
  foreach($cap in $FOD_Capabilities){
    Write-Info "Instalando $cap"
    dism /online /add-capability /capabilityname:$cap
    if ($LASTEXITCODE -ne 0) { Write-Err "Fallo instalando $cap (código $LASTEXITCODE)."; return $false }
  }
  return $true
}

function Resolve-OfflineCabPath {
  # Prioridad: parámetro → .\es-ES-cab → diálogo
  $cabDir = $OfflineCabPath
  if (-not $cabDir -or $cabDir.Trim() -eq "") {
    $localDefault = Join-Path (Get-Location) "es-ES-cab"
    if (Test-Path $localDefault) { $cabDir = $localDefault }
  }
  if (-not $cabDir -or -not (Test-Path $cabDir)) {
    Write-Warn "No se indicó carpeta de .cab. Abriendo selector…"
    $cabDir = Select-FolderDialog
  }
  if (-not $cabDir -or -not (Test-Path $cabDir)) { return $null }
  return (Resolve-Path $cabDir).Path
}

function Validate-RequiredCabs($cabDir){
  $cabs = Get-ChildItem -Path $cabDir -Recurse -Filter *.cab
  if (-not $cabs) { Write-Err "No hay .cab en '$cabDir'"; return $false }
  $missing = @()
  foreach($pat in $RequiredCabPatterns){
    if (-not ($cabs.Name -match $pat)) { $missing += $pat }
  }
  if ($missing.Count -gt 0){
    Write-Err "Faltan paquetes imprescindibles (.cab) en '$cabDir':"
    $missing | ForEach-Object { Write-Err " - $_" }
    Write-Info "Asegura LP base y FOD (Speech, TextToSpeech, OCR, Handwriting) para tu build."
    return $false
  }
  return $true
}

function Install-Language-Offline {
  $cabDir = Resolve-OfflineCabPath
  if (-not $cabDir) { Write-Err "No se seleccionó carpeta válida de .cab."; return $false }
  if (-not (Validate-RequiredCabs $cabDir)) { return $false }

  Write-Info "Modo OFFLINE: usando paquetes .cab en '$cabDir'…"
  $cabs = Get-ChildItem -Path $cabDir -Recurse -Filter *.cab

  # 1) LP base primero si está
  $lp = $cabs | Where-Object { $_.Name -match "(Client-Language-Pack|Language-Pack).*_es-es\.cab" } | Select-Object -First 1
  if ($lp) {
    Write-Info "Instalando LP base: $($lp.Name)"
    dism /online /add-package /packagepath:"$($lp.FullName)"
    if ($LASTEXITCODE -ne 0) { Write-Err "Fallo instalando LP base."; return $false }
  } else {
    Write-Warn "No se localizó un 'Language-Pack' claro; se intentará añadir todos los .cab."
  }

  # 2) Resto de paquetes (FOD es-ES)
  foreach($cab in $cabs){
    Write-Info "Añadiendo paquete: $($cab.Name)"
    dism /online /add-package /packagepath:"$($cab.FullName)"
    if ($LASTEXITCODE -ne 0) { Write-Warn "Fallo al añadir $($cab.Name). Continuamos."; }
  }
  return $true
}

function Apply-Region-Keyboard {
  Write-Info "Aplicando configuración regional $LangTag…"
  try {
    Set-WinSystemLocale $LangTag
    $ul = New-WinUserLanguageList $LangTag
    Set-WinUserLanguageList $ul -Force
    Set-WinUILanguageOverride $LangTag
    Set-Culture $LangTag
    Set-WinHomeLocation 10   # Spain
    # Teclado: quitar EN-US si estuviera
    $ul2 = Get-WinUserLanguageList
    $en = $ul2 | Where-Object { $_.LanguageTag -eq "en-US" }
    if ($en) { $ul2.Remove($en) | Out-Null; Set-WinUserLanguageList $ul2 -Force }
    Write-Ok "Idioma/región/teclado listos."
  } catch { Write-Err "Error aplicando idioma: $($_.Exception.Message)"; return $false }
  return $true
}

# -------------------- Desbloat --------------------
function Remove-Edge-And-Block {
  Write-Info "Eliminando Microsoft Edge (sin tocar WebView2)…"
  try {
    Get-AppxPackage *Microsoft.MicrosoftEdge* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*MicrosoftEdge*" | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    if (Test-Path "C:\Program Files (x86)\Microsoft\Edge") { Remove-Item "C:\Program Files (x86)\Microsoft\Edge" -Recurse -Force -ErrorAction SilentlyContinue }
    if (Test-Path "C:\Program Files\Microsoft\Edge") { Remove-Item "C:\Program Files\Microsoft\Edge" -Recurse -Force -ErrorAction SilentlyContinue }
    reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v DoNotUpdateToEdgeWithChromium /t REG_DWORD /d 1 /f | Out-Null
    reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v UpdateDefault /t REG_DWORD /d 0 /f | Out-Null
    Write-Ok "Edge quitado y bloqueada su reinstalación."
  } catch { Write-Warn "No se pudo quitar Edge por completo (ok en Tiny)."}
}

function Remove-UWP-Bloat {
  Write-Info "Eliminando UWP no esenciales…"
  $apps = @(
    "Microsoft.Xbox*", "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
    "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.People",
    "Microsoft.SkypeApp", "Microsoft.BingNews", "Microsoft.BingWeather",
    "Microsoft.BingFinance", "Microsoft.BingSports", "Microsoft.WindowsFeedbackHub",
    "Microsoft.MicrosoftOfficeHub", "Microsoft.YourPhone", "MicrosoftTeams",
    "Microsoft.MicrosoftSolitaireCollection", "*WebExperience*" # Widgets/Copilot
  )
  foreach($a in $apps){
    Get-AppxPackage -AllUsers $a | Remove-AppxPackage -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $a | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
  }
  Write-Ok "UWP sobrantes eliminadas."
}

function Remove-OneDrive {
  Write-Info "Desinstalando OneDrive…"
  try {
    Stop-Process -Name OneDrive -ErrorAction SilentlyContinue
    $od = "$env:SystemRoot\System32\OneDriveSetup.exe"
    if (Test-Path $od) { Start-Process $od "/uninstall" -NoNewWindow -Wait }
    Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\OneDriveTemp" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Ok "OneDrive desinstalado."
  } catch { Write-Warn "No se pudo quitar OneDrive por completo." }
}

function Cut-Telemetry-Ads {
  Write-Info "Reduciendo telemetría y contenido sugerido…"
  reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f | Out-Null
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SubscribedContent-338387Enabled /t REG_DWORD /d 0 /f | Out-Null
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v SilentInstalledA
