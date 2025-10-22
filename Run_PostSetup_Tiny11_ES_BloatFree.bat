@echo off
title PostSetup Tiny11 ES BloatFree
setlocal
set PS=%~dp0PostSetup_Tiny11_ES_BloatFree.ps1
if not exist "%PS%" (
  echo [ERR] No se encontró %PS%
  pause
  exit /b 1
)
echo.
echo Ejecutando script PowerShell con permisos elevados...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS%"
echo.
echo === Proceso completado. Reinicia el equipo para aplicar el idioma. ===
pause
endlocal

