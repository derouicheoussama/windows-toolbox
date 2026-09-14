@echo off
rem ============================================================
rem  Windows 11 Toolbox - lanceur double-clic
rem  ∞ Infinity Coder - Derouiche Oussama
rem ============================================================
rem  Double-clic sur ce fichier pour lancer la toolbox.
rem  Ajoute "-Admin" en argument pour forcer la elevation (UAC) :
rem     Lancer-Toolbox.cmd -Admin
rem ============================================================
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Windows-Toolbox.ps1" %*
if errorlevel 1 (
  echo.
  echo Une erreur est survenue. Lis le message ci-dessus.
  pause
)
