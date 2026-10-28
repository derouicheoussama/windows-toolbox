# Copyright (C) 2026 Derouiche Oussama - Infinity Coder
# Licencie GPL-3.0 : libre, mais toute copie ou modification reste open source et credite l'auteur. Voir LICENSE
#Requires -Version 5.1
<#
  ================================================================
   Build & Protection — Windows 11 Toolbox
   ∞ Infinity Coder — Derouiche Oussama
   https://www.derouicheoussama.com  ·  https://github.com/derouicheoussama
  ================================================================
   PROTEGE LE LOGICIEL ET SON CODE SOURCE :

   1) Empreintes SHA256 (integrite + hash pour les mises a jour)
        .\Build-Toolbox.ps1
   2) Compilation en .EXE autonome (code compile, plus lisible facilement)
        .\Build-Toolbox.ps1 -Exe
   3) Signature Authenticode (prouve l'auteur, bloque la falsification)
        .\Build-Toolbox.ps1 -Exe  -SignCert "moncert.pfx" -CertPassword "mdp"
        .\Build-Toolbox.ps1 -SignPs1 -SignCert "moncert.pfx" -CertPassword "mdp"
  ================================================================
#>

param(
    [switch]$Checksums,
    [switch]$Exe,
    [switch]$SignPs1,
    [switch]$SignSetup,
    [string]$SignCert,
    [string]$CertPassword,
    [string]$SignStore
)

$ErrorActionPreference = 'Stop'
$scriptFile = Join-Path $PSScriptRoot 'Windows-Toolbox.ps1'

if (-not (Test-Path -LiteralPath $scriptFile)) {
    Write-Host "Fichier introuvable : $scriptFile" -ForegroundColor Red
    exit 1
}

function Invoke-SignFile {
    param([string]$File, [string]$Pfx, [string]$Password, [string]$StoreSubject)
    if (-not (Test-Path -LiteralPath $File)) { Write-Host ("  absent : " + $File) -ForegroundColor Red; return }
    if ($StoreSubject) {
        # Certum SimplySign : le certificat est dans le magasin Windows (Cert:\CurrentUser\My)
        $cert = Get-ChildItem Cert:\CurrentUser\My |
            Where-Object { $_.Subject -like "*$StoreSubject*" -and $_.HasPrivateKey } |
            Sort-Object NotAfter -Descending | Select-Object -First 1
        if (-not $cert) { Write-Host ("  certificat '$StoreSubject' introuvable dans le magasin") -ForegroundColor Red; return }
        $sig = Set-AuthenticodeSignature -FilePath $File -Certificate $cert -TimestampServer 'http://timestamp.digicert.com'
    } else {
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Pfx, $Password)
        $sig = Set-AuthenticodeSignature -FilePath $File -Certificate $cert -TimestampServer 'http://timestamp.digicert.com'
    }
    Write-Host ("  Signature {0} : {1}" -f (Split-Path $File -Leaf), $sig.Status)
    if ($sig.Status -ne 'Valid') { Write-Host '  ATTENTION : signature non valide.' -ForegroundColor Yellow }
}

$didSomething = $false

# ---------- 1) Empreintes SHA256 ----------
if ($Checksums -or -not ($Exe -or $SignCert -or $SignPs1)) {
    $didSomething = $true
    $hash = (Get-FileHash -LiteralPath $scriptFile -Algorithm SHA256).Hash
    $out = Join-Path $PSScriptRoot 'checksums.txt'
    Set-Content -LiteralPath $out -Value ("SHA256  {0}  Windows-Toolbox.ps1  {1:yyyy-MM-dd HH:mm}" -f $hash, (Get-Date)) -Encoding UTF8
    Write-Host ''
    Write-Host (" SHA256 : " + $hash) -ForegroundColor Cyan
    Write-Host (" → copie cette empreinte dans version.json (champ sha256) avant de publier une mise à jour")
    Write-Host (" → fichier : " + $out)
}

# ---------- 2) Compilation en EXE (ps2exe) ----------
if ($Exe) {
    $didSomething = $true
    if (-not (Get-Module -ListAvailable -Name ps2exe)) {
        Write-Host ' Installation du module ps2exe depuis la PowerShell Gallery…' -ForegroundColor Yellow
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Install-Module ps2exe -Scope CurrentUser -Force -Repository PSGallery
    }
    Import-Module ps2exe
    $ver = '1.0'
    $m = Select-String -LiteralPath $scriptFile -Pattern "ToolboxVersion\s*=\s*'([^']+)'"
    if ($m) { $ver = $m.Matches[0].Groups[1].Value }
    $exe = Join-Path $PSScriptRoot 'Windows-Toolbox.exe'
    $icoFile = Join-Path $PSScriptRoot 'brand\Windows-Toolbox.ico'
    $icoArg = @()
    if (Test-Path -LiteralPath $icoFile) { $icoArg = @('-iconFile', $icoFile) }
    Write-Host ''
    Write-Host " Compilation en EXE (version $ver)…" -ForegroundColor Cyan
    Invoke-PS2EXE -inputFile $scriptFile -outputFile $exe -noConsole @icoArg -title 'Windows 11 Toolbox' -description 'Commandes Windows, tests SSD et diagnostics - Infinity Coder' -company 'Derouiche Oussama' -product 'Windows 11 Toolbox' -copyright '(c) Derouiche Oussama - Infinity Coder' -version $ver
    if (Test-Path -LiteralPath $exe) {
        Write-Host (" EXE créé : " + $exe) -ForegroundColor Green
        if ($SignCert -or $SignStore) { Invoke-SignFile -File $exe -Pfx $SignCert -Password $CertPassword -StoreSubject $SignStore }
        $setupExe = Join-Path $PSScriptRoot 'Setup-Toolbox.exe'
        if ((Test-Path -LiteralPath $setupExe) -and ($SignCert -or $SignStore)) { Invoke-SignFile -File $setupExe -Pfx $SignCert -Password $CertPassword -StoreSubject $SignStore }
    }
}

# ---------- 3) Signature (PFX ou magasin Certum SimplySign) ----------
if ($SignPs1 -and ($SignCert -or $SignStore)) {
    $didSomething = $true
    Invoke-SignFile -File $scriptFile -Pfx $SignCert -Password $CertPassword -StoreSubject $SignStore
}

if ($SignStore -and -not ($Exe -or $SignPs1)) {
    $didSomething = $true
    $exe = Join-Path $PSScriptRoot 'Windows-Toolbox.exe'
    Invoke-SignFile -File $exe -StoreSubject $SignStore
}

Write-Host ''
Write-Host ' TERMINÉ. Rappels protection :' -ForegroundColor DarkCyan
Write-Host ' • Publie le .ps1 en dépôt PRIVÉ si tu veux garder le code pour toi ; distribue l''EXE.'
Write-Host ' • L''EXE non signé peut déclencher SmartScreen/antivirus : signe-le (certificat de signature de code) pour une distribution propre.'
Write-Host ' • La mise à jour à distance vérifie le SHA256 du manifeste avant d''installer — remplis-le à chaque version.'
