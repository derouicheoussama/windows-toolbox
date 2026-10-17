#Requires -Version 5.1
<#
  ================================================================
   UPDATER AVANCÉ — Windows 11 Toolbox
   ∞ Infinity Coder — Derouiche Oussama
  ================================================================
   .\Updater-Toolbox.ps1                → vérifie et propose la mise à jour
   .\Updater-Toolbox.ps1 -Check         → vérifie seulement (sans installer)
   .\Updater-Toolbox.ps1 -Silent        → installe sans aucune question
   .\Updater-Toolbox.ps1 -Silent -Launch → installe et relance l'application

   Détecte automatiquement la copie à mettre à jour :
   1. Le dossier d'où l'updater est lancé
   2. La copie installée (%LOCALAPPDATA%\Programs\WindowsToolbox)
   Planification possible (exemple, quotidien 12h00) :
   schtasks /create /tn "ToolboxUpdate" /sc daily /st 12:00 /tr ^
     "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"C:\chemin\Updater-Toolbox.ps1\" -Silent"
  ================================================================
#>
param(
    [switch]$Check,
    [switch]$Silent,
    [switch]$Launch
)

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$manifestUrl = 'https://raw.githubusercontent.com/derouicheoussama/windows-toolbox/main/version.json'

function Write-Banner {
    Write-Host ''
    Write-Host '  ==========================================' -ForegroundColor Blue
    Write-Host '   UPDATER — Windows 11 Toolbox' -ForegroundColor Blue
    Write-Host '   ∞ Infinity Coder — Derouiche Oussama' -ForegroundColor Gray
    Write-Host '  ==========================================' -ForegroundColor Blue
    Write-Host ''
}

# Cible : dossier de l'updater, sinon copie installée
$target = $null
if ($PSScriptRoot -and (Test-Path (Join-Path $PSScriptRoot 'Windows-Toolbox.ps1'))) {
    $target = Join-Path $PSScriptRoot 'Windows-Toolbox.ps1'
} elseif (Test-Path (Join-Path $env:LOCALAPPDATA 'Programs\WindowsToolbox\Windows-Toolbox.ps1')) {
    $target = Join-Path $env:LOCALAPPDATA 'Programs\WindowsToolbox\Windows-Toolbox.ps1'
}
if (-not $target) {
    Write-Host ' Aucune copie de la toolbox trouvée. Utilise Setup-Toolbox.ps1 pour installer.' -ForegroundColor Red
    exit 1
}

Write-Banner
Write-Host (" Cible     : " + $target)

$localVer = 'inconnue'
$m = Select-String -LiteralPath $target -Pattern "ToolboxVersion\s*=\s*'([^']+)'"
if ($m) { $localVer = $m.Matches[0].Groups[1].Value }
Write-Host (" Version locale : " + $localVer)

try {
    $manifest = Invoke-RestMethod -Uri $manifestUrl -TimeoutSec 20
} catch {
    Write-Host (" Manifeste inaccessible : " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}

Write-Host (" Version en ligne : " + $manifest.version)
Write-Host ''

$rv = $null; $lv = $null
try { $rv = [version]$manifest.version } catch { }
try { $lv = [version]$localVer } catch { }

if (-not ($rv -and $lv -and $rv -gt $lv)) {
    Write-Host ' ✓ Tu as déjà la dernière version. Rien à faire.' -ForegroundColor Green
    exit 0
}

Write-Host " ★ MISE À JOUR DISPONIBLE : v$($manifest.version)" -ForegroundColor Yellow
if ($manifest.notes) { Write-Host ("   " + $manifest.notes) -ForegroundColor Gray }
Write-Host ''

if ($Check) { Write-Host ' (mode -Check : rien n''a été installé)'; exit 0 }

if (-not $Silent) {
    $ok = Read-Host ' Télécharger et installer maintenant ? [O/n]'
    if ($ok -match '^[nN]') { Write-Host ' Annulé.'; exit 0 }
}

Write-Host ''
Write-Host ' Téléchargement…'
$tmp = "$target.new"
Invoke-WebRequest -Uri $manifest.url -OutFile $tmp -TimeoutSec 300 -UseBasicParsing

if ($manifest.sha256) {
    $got = (Get-FileHash $tmp -Algorithm SHA256).Hash
    if ($got -ne $manifest.sha256) {
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        Write-Host ' ✗ Empreinte SHA256 différente du manifeste — installation refusée (sécurité).' -ForegroundColor Red
        exit 1
    }
    Write-Host ' ✓ Empreinte SHA256 vérifiée' -ForegroundColor Green
}

$errs = $null
$null = [System.Management.Automation.Language.Parser]::ParseFile($tmp, [ref]$null, [ref]$errs)
if ($errs -and $errs.Count -gt 0) {
    Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    Write-Host ' ✗ Fichier invalide (erreur de syntaxe) — installation annulée.' -ForegroundColor Red
    exit 1
}

Copy-Item $target "$target.bak" -Force
Move-Item -Force -Path $tmp -Destination $target
Write-Host " ✓ Version $($manifest.version) installée (sauvegarde de l'ancienne : .bak)" -ForegroundColor Green

if ($Silent -and -not $Launch) { exit 0 }

$rel = 'o'
if (-not $Silent) { $rel = Read-Host ' Relancer la toolbox maintenant ? [O/n]' }
if ($rel -notmatch '^[nN]') {
    Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$target`"")
}
