@echo off
title Installation - Windows 11 Toolbox
echo.
echo  ==================================================
echo   INSTALLATION - Windows 11 Toolbox
echo   Telechargement depuis GitHub puis installation
echo   ∞ Infinity Coder - Derouiche Oussama
echo  ==================================================
echo.
echo Telechargement de l'installateur (1-2 Mo)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/derouicheoussama/windows-toolbox/main/Setup-Toolbox.ps1' -OutFile \"$env:TEMP\Setup-Toolbox.ps1\" -UseBasicParsing"
if not exist "%TEMP%\Setup-Toolbox.ps1" (
  echo.
  echo  Echec du telechargement - verifie ta connexion Internet.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\Setup-Toolbox.ps1"
del "%TEMP%\Setup-Toolbox.ps1" >nul 2>&1
