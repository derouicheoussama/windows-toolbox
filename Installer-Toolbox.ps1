#Requires -Version 5.1
<#
  ================================================================
   INSTALLATEUR — Windows 11 Toolbox
   ∞ Infinity Coder — Derouiche Oussama
  ================================================================
   .\Installer-Toolbox.ps1              → installe (utilisateur, sans admin)
   .\Installer-Toolbox.ps1 -Uninstall   → désinstalle tout proprement

   Ce que fait l'installation :
   • Copie l'application dans %LOCALAPPDATA%\Programs\WindowsToolbox
   • Raccourcis : Menu Démarrer + Bureau (+ raccourci Désinstaller)
   • Entrée « Windows 11 Toolbox » dans Applications & fonctionnalités
   • L'application installée continue de recevoir les mises à jour à distance
  ================================================================
#>
param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$appName    = 'Windows 11 Toolbox'
$installDir = Join-Path $env:LOCALAPPDATA 'Programs\WindowsToolbox'
$startMenu  = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$desk       = [Environment]::GetFolderPath('Desktop')
$psExe      = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$icon       = "$env:SystemRoot\System32\imageres.dll,-78"
$uninstKey  = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WindowsToolbox'
$psArgs     = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\Windows-Toolbox.ps1`""

function New-Shortcut {
    param([string]$Path, [string]$Target, [string]$TargetArgs, [string]$IconLoc)
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($Path)
    $sc.TargetPath = $Target
    $sc.Arguments = $TargetArgs
    $sc.IconLocation = $IconLoc
    $sc.WorkingDirectory = Split-Path $Target
    $sc.Save()
}

function Remove-ToolboxItems {
    Get-Process powershell -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -like 'Windows 11 Toolbox*' } |
        Stop-Process -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $startMenu "$appName.lnk") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $startMenu "$appName - Desinstaller.lnk") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $desk "$appName.lnk") -Force -ErrorAction SilentlyContinue
    Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' -Name 'WindowsToolbox' -ErrorAction SilentlyContinue
    Remove-Item $uninstKey -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Remove-Item $installDir -Recurse -Force -ErrorAction SilentlyContinue
}

if ($Uninstall) {
    Remove-ToolboxItems
    Write-Host ''
    Write-Host " $appName a été désinstallé (fichiers, raccourcis, entrée Applications & fonctionnalités)." -ForegroundColor Green
    exit 0
}

# ---------- INSTALLATION ----------
$srcPs1 = Join-Path $PSScriptRoot 'Windows-Toolbox.ps1'
if (-not (Test-Path -LiteralPath $srcPs1)) {
    Write-Host " Windows-Toolbox.ps1 introuvable à côté de l'installateur." -ForegroundColor Red
    exit 1
}

$ver = '1.0'
$m = Select-String -LiteralPath $srcPs1 -Pattern "ToolboxVersion\s*=\s*'([^']+)'"
if ($m) { $ver = $m.Matches[0].Groups[1].Value }

Write-Host ''
Write-Host " Installation de $appName v$ver…" -ForegroundColor Cyan

New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Copy-Item -LiteralPath $srcPs1 -Destination $installDir -Force
Copy-Item (Join-Path $PSScriptRoot 'Lancer-Toolbox.cmd') $installDir -Force
Copy-Item (Join-Path $PSScriptRoot 'Uninstall-Toolbox.ps1') $installDir -Force
Copy-Item (Join-Path $PSScriptRoot 'Updater-Toolbox.ps1') $installDir -Force
if (Test-Path (Join-Path $PSScriptRoot 'tools')) {
    Copy-Item (Join-Path $PSScriptRoot 'tools') $installDir -Recurse -Force
}

New-Shortcut -Path (Join-Path $startMenu "$appName.lnk") -Target $psExe -TargetArgs $psArgs -IconLoc $icon
New-Shortcut -Path (Join-Path $desk "$appName.lnk") -Target $psExe -TargetArgs $psArgs -IconLoc $icon
New-Shortcut -Path (Join-Path $startMenu "$appName - Desinstaller.lnk") -Target $psExe -TargetArgs "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\Uninstall-Toolbox.ps1`"" -IconLoc $icon

New-Item -Path $uninstKey -Force | Out-Null
Set-ItemProperty $uninstKey 'DisplayName'        $appName
Set-ItemProperty $uninstKey 'DisplayVersion'     $ver
Set-ItemProperty $uninstKey 'Publisher'          'Derouiche Oussama — Infinity Coder'
Set-ItemProperty $uninstKey 'DisplayIcon'        $icon
Set-ItemProperty $uninstKey 'InstallLocation'    $installDir
Set-ItemProperty $uninstKey 'UninstallString'    "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\Uninstall-Toolbox.ps1`""
Set-ItemProperty $uninstKey 'URLInfoAbout'       'https://www.derouicheoussama.com'
Set-ItemProperty $uninstKey 'NoModify'           1 -Type DWord
Set-ItemProperty $uninstKey 'NoRepair'           1 -Type DWord

Write-Host ''
Write-Host " ✓ Installé dans : $installDir" -ForegroundColor Green
Write-Host " ✓ Raccourcis    : Menu Démarrer + Bureau"
Write-Host " ✓ Désinstallation : Applications & fonctionnalités, ou raccourci « Desinstaller »"
Write-Host " ✓ Version       : $ver — les mises à jour à distance continuent de fonctionner"
Write-Host ''
