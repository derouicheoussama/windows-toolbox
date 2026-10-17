#Requires -Version 5.1
<#
  ================================================================
   SETUP CLIENT — Windows 11 Toolbox
   ∞ Infinity Coder — Derouiche Oussama
  ================================================================
   Installateur « 1 fichier » : télécharge la dernière version depuis
   GitHub, vérifie son empreinte SHA256, installe raccourcis + désinstalleur,
   puis lance l'application.

   .\Setup-Toolbox.ps1              → installe / met à jour / répare
   .\Setup-Toolbox.ps1 -NoLaunch    → n'ouvre pas l'application à la fin

   Les clients n'ont besoin que de Setup-Toolbox.cmd (double-clic).
  ================================================================
#>
param([switch]$NoLaunch)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base        = 'https://raw.githubusercontent.com/derouicheoussama/windows-toolbox/main'
$appName     = 'Windows 11 Toolbox'
$installDir  = Join-Path $env:LOCALAPPDATA 'Programs\WindowsToolbox'
$startMenu   = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
$desk        = [Environment]::GetFolderPath('Desktop')
$psExe       = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$icon        = "$env:SystemRoot\System32\imageres.dll,-78"
$uninstKey   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\WindowsToolbox'
$psArgs      = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\Windows-Toolbox.ps1`""

function Write-Banner {
    Write-Host ''
    Write-Host '  ==========================================' -ForegroundColor Blue
    Write-Host '   INSTALLATION — Windows 11 Toolbox' -ForegroundColor Blue
    Write-Host '   ∞ Infinity Coder — Derouiche Oussama' -ForegroundColor Gray
    Write-Host '  ==========================================' -ForegroundColor Blue
    Write-Host ''
}

function New-Shortcut {
    param([string]$Path, [string]$Target, [string]$TargetArgs)
    $ws = New-Object -ComObject WScript.Shell
    $sc = $ws.CreateShortcut($Path)
    $sc.TargetPath = $Target
    $sc.Arguments = $TargetArgs
    $sc.IconLocation = $icon
    $sc.WorkingDirectory = $installDir
    $sc.Save()
}

Write-Banner
Write-Host ' 1/4  Lecture du manifeste de version…'
$manifest = Invoke-RestMethod -Uri "$base/version.json" -TimeoutSec 20
Write-Host ("      Dernière version publiée : v" + $manifest.version) -ForegroundColor Cyan

# Déjà installé ?
$localVer = $null
$installed = Join-Path $installDir 'Windows-Toolbox.ps1'
if (Test-Path -LiteralPath $installed) {
    $m = Select-String -LiteralPath $installed -Pattern "ToolboxVersion\s*=\s*'([^']+)'"
    if ($m) { $localVer = $m.Matches[0].Groups[1].Value }
    if ($localVer -eq $manifest.version) {
        Write-Host ''
        Write-Host " ✓ $appName v$localVer est déjà installé et à jour." -ForegroundColor Green
        $r = Read-Host ' Réinstaller/réparer quand même ? [o/N]'
        if ($r -notmatch '^[oO]') { exit 0 }
    } elseif ($localVer) {
        Write-Host ("      Mise à jour détectée : v" + $localVer + " → v" + $manifest.version) -ForegroundColor Yellow
    }
}

Write-Host ' 2/4  Téléchargement et vérification des fichiers…'
$tmpDir = Join-Path $env:TEMP ('toolbox-setup-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null

$ps1Tmp = Join-Path $tmpDir 'Windows-Toolbox.ps1'
Invoke-WebRequest -Uri "$base/Windows-Toolbox.ps1" -OutFile $ps1Tmp -TimeoutSec 300 -UseBasicParsing
$got = (Get-FileHash $ps1Tmp -Algorithm SHA256).Hash
if ($manifest.sha256 -and ($got -ne $manifest.sha256)) {
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host ' ✗ Empreinte SHA256 différente du manifeste — installation refusée (sécurité).' -ForegroundColor Red
    exit 1
}
Write-Host '      ✓ Windows-Toolbox.ps1 (SHA256 vérifié)' -ForegroundColor Green

Invoke-WebRequest -Uri "$base/Uninstall-Toolbox.ps1" -OutFile (Join-Path $tmpDir 'Uninstall-Toolbox.ps1') -TimeoutSec 60 -UseBasicParsing
Invoke-WebRequest -Uri "$base/Lancer-Toolbox.cmd" -OutFile (Join-Path $tmpDir 'Lancer-Toolbox.cmd') -TimeoutSec 60 -UseBasicParsing
Write-Host '      ✓ Uninstall-Toolbox.ps1 · Lancer-Toolbox.cmd' -ForegroundColor Green

Write-Host ' 3/4  Installation…'
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Copy-Item "$tmpDir\*" $installDir -Force
New-Item -ItemType Directory -Force -Path (Join-Path $installDir 'tools') | Out-Null
Set-Content -LiteralPath (Join-Path $installDir 'tools\LISEZMOI.txt') -Value "Place ici tes outils portables (.exe) : ils apparaissent dans l'onglet Outils tiers.`n∞ Infinity Coder" -Encoding UTF8

New-Shortcut -Path (Join-Path $startMenu "$appName.lnk") -Target $psExe -TargetArgs $psArgs
New-Shortcut -Path (Join-Path $desk "$appName.lnk") -Target $psExe -TargetArgs $psArgs
New-Shortcut -Path (Join-Path $startMenu "$appName - Desinstaller.lnk") -Target $psExe -TargetArgs "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\Uninstall-Toolbox.ps1`""

New-Item -Path $uninstKey -Force | Out-Null
Set-ItemProperty $uninstKey 'DisplayName'     $appName
Set-ItemProperty $uninstKey 'DisplayVersion'  $manifest.version
Set-ItemProperty $uninstKey 'Publisher'       'Derouiche Oussama — Infinity Coder'
Set-ItemProperty $uninstKey 'DisplayIcon'     $icon
Set-ItemProperty $uninstKey 'InstallLocation' $installDir
Set-ItemProperty $uninstKey 'UninstallString' "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$installDir\Uninstall-Toolbox.ps1`""
Set-ItemProperty $uninstKey 'URLInfoAbout'    'https://www.derouicheoussama.com'
Set-ItemProperty $uninstKey 'NoModify'        1 -Type DWord
Set-ItemProperty $uninstKey 'NoRepair'        1 -Type DWord

Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ' 4/4  Finalisation…'
Write-Host ''
Write-Host " ✓ $appName v$($manifest.version) installé !" -ForegroundColor Green
Write-Host ("   Emplacement   : " + $installDir)
Write-Host "   Raccourcis    : Menu Démarrer + Bureau"
Write-Host "   Désinstaller  : Applications & fonctionnalités"
Write-Host "   Mises à jour  : automatiques au démarrage de l'application"

if (-not $NoLaunch) {
    Write-Host ''
    $r = Read-Host ' Lancer la toolbox maintenant ? [O/n]'
    if ($r -notmatch '^[nN]') {
        Start-Process -FilePath $psExe -ArgumentList $psArgs
    }
}
Write-Host ''
