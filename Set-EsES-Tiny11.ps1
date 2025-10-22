<# =====================================================================
File: Set-EsES-Tiny11.ps1
Created: 2025-10-22 13:00 (Europe/Madrid)
Brief: Convierte Tiny11/Windows 11 a Español (España) con UI, teclado,
       formatos, voz/TTS, OCR y escritura a mano. Soporta modo online
       (DISM capabilities) y offline (carpeta con .cab Language Pack/FOD).
Deps: Requiere privilegios de Administrador. Para uso offline, colocar
      los .cab (LP + FOD: Speech, TextToSpeech, OCR, Handwriting) en un
      mismo directorio.
===================================================================== #>

# --- Configuración ---
$LangTag = "es-ES"
$FODs = @(
  "Language.Basic~~~es-ES~0.0.1.0",
  "Language.Speech~~~es-ES~0.0.1.0",
  "Language.TextToSpeech~~~es-ES~0.0.1.0",
  "Language.OCR~~~es-ES~0.0.1.0",
  "Language.Handwriting~~~es-ES~0.0.1.0"
)

$TranscriptPath = Join-Path $env:USERPROFILE "Desktop\Set-EsES-Tiny11.log"
Start-Transcript -Path $TranscriptPath -Append | Out-Null

# --- Helpers ---
function Write-Info($msg){ Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg){ Write-Host "[ OK ] $msg" -ForegroundColor Green }
function Write-Warn($msg){ Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg){ Write-Host "[ERR ] $msg" -ForegroundColor Red }

function Require-Admin {
  if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Err "Ejecuta este script como Administrador."
    Stop-Transcript | Out-Null
    exit 1
  }
}

function Test-Internet {
  try {
    $r = Test-NetConnection "download.windowsupdate.com" -Port 80 -WarningAction SilentlyContinue
    return ($r.TcpTestSucceeded -eq $true)
  } catch { return $false }
}

function Ensure-WU-Services {
  $svcs = "wuauserv","bits","cryptsvc"
  foreach($s in $svcs){
    try {
      Set-Service -Name $s -StartupType Manual -ErrorAction SilentlyContinue
      Start-Service -Name $s -ErrorAction SilentlyContinue
    } catch { Write-Warn "No se pudo iniciar servicio $s (seguimos)"; }
  }
}

function Install-Online {
  Write-Info "Modo ONLINE: instalando capacidades de idioma vía DISM…"
  Ensure-WU-Services
  foreach($cap in $FODs){
    Write-Info "Instalando $cap"
    $res = dism /online /add-capability /capabilityname:$cap
    if ($LASTEXITCODE -ne 0) {
      Write-Err "Fallo instalando $cap (código $LASTEXITCODE)."
      return $false
    }
  }
  return $true
}

function Ask-CabFolder {
  Write-Info "Introduce ruta de carpeta con los .cab es-ES (LP + FOD)."
  $path = Read-Host "Ruta (ej. D:\es-ES-cab)"
  if (-not (Test-Path $path)) {
    Write-Err "Carpeta no existe: $path"
    return $null
  }
  return (Resolve-Path $path).Path
}

function Install-Offline {
  $cabDir = Ask-CabFolder
  if (-not $cabDir) { return $false }

  $cabs = Get-ChildItem -Path $cabDir -Recurse -Filter *.cab
  if (-not $cabs) {
    Write-Err "No se encontraron .cab en $cabDir"
    return $false
  }

  # 1) LP base primero (suele contener 'Language-Pack' o 'Client-Language-Pack')
  $lp = $cabs | Where-Object { $_.Name -match "(Language-Pack|Client-Language-Pack).*es-ES" } | Select-Object -First 1
  if ($lp) {
    Write-Info "Instalando LP base: $($lp.Name)"
    dism /online /add-package /packagepath:"$($lp.FullName)"
    if ($LASTEXITCODE -ne 0) { Write-Err "Fallo instalando LP base."; return $false }
  } else {
    Write-Warn "No se localizó un 'Language-Pack' claro; se intentará instalar todos los .cab."
  }

  # 2) Resto de FOD es-ES (Speech, TTS, OCR, Handwriting, etc.)
  foreach($cab in $cabs){
    Write-Info "Añadiendo paquete: $($cab.Name)"
    dism /online /add-package /packagepath:"$($cab.FullName)"
    if ($LASTEXITCODE -ne 0) { Write-Warn "Fallo al añadir $($cab.Name). Continuamos."; }
  }
  return $true
}

function Apply-Region {
  Write-Info "Aplicando configuración regional $LangTag…"
  try {
    # Idioma UI y usuario
    Set-WinSystemLocale $LangTag
    $list = New-Object -TypeName System.Collections.Generic.List[Microsoft.Globalization.CultureInfo]
    $list.Add((New-WinUserLanguageList $LangTag)[0].LanguageTag) | Out-Null

    # Usamos cmdlets nativos
    $ul = New-WinUserLanguageList $LangTag
    Set-WinUserLanguageList $ul -Force

    Set-WinUILanguageOverride $LangTag
    Set-Culture $LangTag
    Set-WinHomeLocation 10   # 10 = Spain

    Write-Ok "Región e idioma establecidos a $LangTag."
  } catch {
    Write-Err "Error aplicando configuración regional: $($_.Exception.Message)"
    return $false
  }
  return $true
}

function Set-KeyboardES {
  Write-Info "Configurando distribución de teclado Español (España) - ISO…"
  try {
    $ul = Get-WinUserLanguageList
    # Añadir ES si no está
    if (-not ($ul.LanguageTag -contains $LangTag)) {
      $ul.Add($LangTag) | Out-Null
    }
    # Eliminar EN-US si existe
    $en = $ul | Where-Object { $_.LanguageTag -eq "en-US" }
    if ($en) { $ul.Remove($en) | Out-Null }

    Set-WinUserLanguageList $ul -Force
    Write-Ok "Teclado ajustado. Si persistiera EN-US, quítalo en Configuración → Idioma."
  } catch {
    Write-Warn "No se pudo ajustar el teclado por cmdlets. Hazlo manualmente en Configuración."
  }
}

function Cleanup-OldContent {
  Write-Info "Limpieza ligera de paquetes pendientes…"
  try {
    Dism /Online /Cleanup-Image /StartComponentCleanup | Out-Null
  } catch { Write-Warn "No se pudo limpiar componentes (ok)."}
}

# --- Ejecución ---
Require-Admin

Write-Info "Detección de conectividad a Windows Update…"
$online = Test-Internet
if ($online) {
  Write-Ok "Conectividad OK. Intentando instalación ONLINE."
  $ok = Install-Online
  if (-not $ok) {
    Write-Warn "Fallo en modo online. Pasamos a modo OFFLINE (.cab)."
    $ok = Install-Offline
  }
} else {
  Write-Warn "Sin conectividad. Usaremos modo OFFLINE (.cab)."
  $ok = Install-Offline
}

if (-not $ok) {
  Write-Err "No se pudieron instalar paquetes de idioma. Revisa conectividad o cabecera de .cab."
  Stop-Transcript | Out-Null
  exit 2
}

if (-not (Apply-Region)) { Stop-Transcript | Out-Null; exit 3 }
Set-KeyboardES
Cleanup-OldContent

Write-Ok "Conversión a Español (España) completada."
Write-Info "Reinicia el equipo para aplicar la interfaz de usuario en español."
Stop-Transcript | Out-Null
