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
    [string]$SignCert,
    [string]$CertPassword
)

$ErrorActionPreference = 'Stop'
$scriptFile = Join-Path $PSScriptRoot 'Windows-Toolbox.ps1'

if (-not (Test-Path -LiteralPath $scriptFile)) {
    Write-Host "Fichier introuvable : $scriptFile" -ForegroundColor Red
    exit 1
}

function Invoke-SignFile {
    param([string]$File, [string]$Pfx, [string]$Password)
    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Pfx, $Password)
    $sig = Set-AuthenticodeSignature -FilePath $File -Certificate $cert -TimestampServer 'http://timestamp.digicert.com'
    Write-Host ("  Signature {0} : {1}" -f (Split-Path $File -Leaf), $sig.Status)
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
    Write-Host ''
    Write-Host " Compilation en EXE (version $ver)…" -ForegroundColor Cyan
    Invoke-PS2EXE -inputFile $scriptFile -outputFile $exe -noConsole `
        -title 'Windows 11 Toolbox' `
        -description 'Commandes Windows, tests SSD et diagnostics — ∞ Infinity Coder' `
        -company 'Derouiche Oussama' `
        -product 'Windows 11 Toolbox' `
        -copyright '(c) Derouiche Oussama — ∞ Infinity Coder' `
        -version $ver
    if (Test-Path -LiteralPath $exe) {
        Write-Host (" EXE créé : " + $exe) -ForegroundColor Green
        if ($SignCert) { Invoke-SignFile -File $exe -Pfx $SignCert -Password $CertPassword }
    }
}

# ---------- 3) Signature du script ----------
if ($SignPs1 -and $SignCert) {
    $didSomething = $true
    Invoke-SignFile -File $scriptFile -Pfx $SignCert -Password $CertPassword
}

Write-Host ''
Write-Host ' TERMINÉ. Rappels protection :' -ForegroundColor DarkCyan
Write-Host ' • Publie le .ps1 en dépôt PRIVÉ si tu veux garder le code pour toi ; distribue l''EXE.'
Write-Host ' • L''EXE non signé peut déclencher SmartScreen/antivirus : signe-le (certificat de signature de code) pour une distribution propre.'
Write-Host ' • La mise à jour à distance vérifie le SHA256 du manifeste avant d''installer — remplis-le à chaque version.'
