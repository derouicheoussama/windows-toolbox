#Requires -Version 5.1
<#  DÉSINSTALLEUR — Windows 11 Toolbox
    Supprime : fichiers, raccourcis Menu Démarrer/Bureau,
    entrée « Applications & fonctionnalités », démarrage automatique.  #>

$ErrorActionPreference = 'SilentlyContinue'
$appName    = 'Windows 11 Toolbox'
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\WindowsToolbox'
$startMenu  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$desk       = [Environment]::GetFolderPath('Desktop')
$uninstKey  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WindowsToolbox'

# Ferme l'application si elle tourne (ne touche pas à cette console)
Get-Process powershell -ErrorAction SilentlyContinue |
    Where-Object { $_.MainWindowTitle -like 'Windows 11 Toolbox*' } |
    Stop-Process -Force

Remove-Item (Join-Path $startMenu "$appName.lnk") -Force
Remove-Item (Join-Path $startMenu "$appName - Desinstaller.lnk") -Force
Remove-Item (Join-Path $desk "$appName.lnk") -Force
Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'WindowsToolbox'
Remove-Item $uninstKey -Recurse -Force

Start-Sleep -Seconds 1
Remove-Item $installDir -Recurse -Force

Write-Host ''
Write-Host " $appName a été désinstallé." -ForegroundColor Green
Write-Host ''
