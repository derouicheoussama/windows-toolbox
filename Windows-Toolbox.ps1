#Requires -Version 5.1
<#
  ================================================================
   Windows 11 Toolbox — Commandes, SSD & Diagnostics
   ∞ Infinity Coder — Derouiche Oussama
   Site    : https://www.derouicheoussama.com
   GitHub  : https://github.com/derouicheoussama
  ================================================================
   Usage :
     .\Windows-Toolbox.ps1            → Interface graphique
     .\Windows-Toolbox.ps1 -Admin     → Relance en administrateur (UAC)
     .\Windows-Toolbox.ps1 -List      → Inventaire console (sans interface)
     Lancer-Toolbox.cmd               → Double-clic (aucun réglage requis)
  ================================================================
#>

param(
    [switch]$Admin,
    [switch]$List
)

$script:ToolboxVersion = '2.3.0'
# ----------------------------------------------------------------
# Liens de l'auteur — personnalise ton lien de don ci-dessous
# ----------------------------------------------------------------
$script:DonationUrl  = 'https://www.paypal.com/donate'   # ← METTRE TON LIEN PAYPAL ICI
$script:AuthorSite   = 'https://www.derouicheoussama.com'
$script:AuthorGitHub = 'https://github.com/derouicheoussama'
$script:AuthorInsta  = 'https://www.instagram.com/derouiche.oussama/'
$script:AuthorFb     = 'https://www.facebook.com/derouiche.oussama'
$script:AuthorTikTok = 'https://www.tiktok.com/@derouiche.oussama'
# ----------------------------------------------------------------
# Mises à jour à distance — héberge version.json + Windows-Toolbox.ps1
# sur le dépôt GitHub ci-dessous (voir README, section « Mises à jour »)
# ----------------------------------------------------------------
$script:UpdateManifestUrl = 'https://raw.githubusercontent.com/derouicheoussama/windows-toolbox/main/version.json'
$script:ScriptDir      = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$script:ToolsDir       = Join-Path $script:ScriptDir 'tools'

# ----------------------------------------------------------------
# Raccourci global & options persistantes (v2.0)
# ----------------------------------------------------------------
if (-not ('WindowsToolbox.HotkeyForm' -as [type])) {
    Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;
namespace WindowsToolbox {
    public class HotkeyForm : Form {
        public event EventHandler GlobalHotkey;
        protected override void WndProc(ref Message m) {
            base.WndProc(ref m);
            if (m.Msg == 0x0312) { var h = GlobalHotkey; if (h != null) h(this, EventArgs.Empty); }
        }
    }
    public static class Win32Hot {
        [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint fsModifiers, uint vk);
        [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
    }
}
'@
}

if (-not ('WindowsToolbox.DisplayUtil' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
namespace WindowsToolbox {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
        public int dmICMMethod;
        public int dmICMIntent;
        public int dmMediaType;
        public int dmDitherType;
        public int dmReserved1;
        public int dmReserved2;
        public int dmPanningWidth;
        public int dmPanningHeight;
    }
    public static class DisplayUtil {
        [DllImport("user32.dll", CharSet = CharSet.Ansi)]
        public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);
        public static List<string> ListModes() {
            var results = new List<string>();
            var dm = new DEVMODE();
            dm.dmSize = (short)Marshal.SizeOf(typeof(DEVMODE));
            for (int i = 0; EnumDisplaySettings(null, i, ref dm); i++) {
                results.Add(dm.dmPelsWidth + "x" + dm.dmPelsHeight + "@" + dm.dmDisplayFrequency);
            }
            return results;
        }
    }
}
'@
}

$script:RegKey = 'HKCU:\Software\WindowsToolbox'
$script:HotkeyId = 1
$script:HotkeyMods = 3      # MOD_CONTROL | MOD_ALT
$script:HotkeyVk = 0x54     # touche T

function Get-ToolboxSetting {
    param([string]$Name, $Default)
    try {
        $v = (Get-ItemProperty -Path $script:RegKey -ErrorAction Stop).$Name
        if ($null -eq $v) { return $Default }
        return $v
    } catch { return $Default }
}

function Set-ToolboxSetting {
    param([string]$Name, $Value)
    if (-not (Test-Path -LiteralPath $script:RegKey)) { New-Item -Path $script:RegKey -Force | Out-Null }
    Set-ItemProperty -Path $script:RegKey -Name $Name -Value $Value
}

# ----------------------------------------------------------------
# Élévation
# ----------------------------------------------------------------
function Test-IsAdmin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if ($Admin -and -not (Test-IsAdmin)) {
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Admin')
        exit 0
    } catch {
        Write-Warning "Élévation refusée : $($_.Exception.Message)"
        exit 1
    }
}

# ----------------------------------------------------------------
# Catalogue des outils tiers recommandés (détection + liens officiels)
# ----------------------------------------------------------------
$script:ThirdPartyCatalog = @(
    @{ Name='CrystalDiskInfo';        Desc='Santé SMART & température (SSD/HDD)';         Paths=@("$env:ProgramFiles\CrystalDiskInfo*\DiskInfo*.exe", "${env:ProgramFiles(x86)}\CrystalDiskInfo*\DiskInfo*.exe"); Url='https://crystalmark.info/en/software/crystaldiskinfo/' }
    @{ Name='CrystalDiskMark';        Desc='Benchmark vitesse disque (lecture/écriture)'; Paths=@("$env:ProgramFiles\CrystalDiskMark*\DiskMark*.exe", "${env:ProgramFiles(x86)}\CrystalDiskMark*\DiskMark*.exe"); Url='https://crystalmark.info/en/software/crystaldiskmark/' }
    @{ Name='Victoria';               Desc='Test de surface & diagnostic avancé HDD/SSD'; Paths=@("$script:ToolsDir\Victoria*.exe"); Url='https://hdd.by/victoria/' }
    @{ Name='HD Tune';                Desc='Benchmark & test d''erreurs disque';          Paths=@("${env:ProgramFiles(x86)}\HD Tune\HDTune.exe"); Url='http://www.hdtune.com/' }
    @{ Name='HWiNFO';                 Desc='Capteurs matériels les plus complets';        Paths=@("$env:ProgramFiles\HWiNFO*\HWiNFO*.EXE", "${env:ProgramFiles(x86)}\HWiNFO*\HWiNFO*.EXE"); Url='https://www.hwinfo.com/' }
    @{ Name='HWMonitor';              Desc='Températures / tensions / ventilateurs';      Paths=@("$env:ProgramFiles\CPUID\HWMonitor*\HWMonitor*.exe", "${env:ProgramFiles(x86)}\CPUID\HWMonitor*\HWMonitor*.exe"); Url='https://www.cpuid.com/softwares/hwmonitor.html' }
    @{ Name='Libre Hardware Monitor'; Desc='Capteurs matériels (open source)';            Paths=@("$env:ProgramFiles\Libre Hardware Monitor\LibreHardwareMonitor.exe", "$script:ToolsDir\LibreHardwareMonitor*.exe"); Url='https://librehardwaremonitor.github.io/' }
    @{ Name='Core Temp';              Desc='Température CPU par cœur';                    Paths=@("$env:ProgramFiles\Core Temp\CoreTemp.exe", "${env:ProgramFiles(x86)}\Core Temp\CoreTemp.exe"); Url='https://www.alcpu.com/CoreTemp/' }
    @{ Name='CPU-Z';                  Desc='Identité CPU / RAM / carte mère';             Paths=@("$env:ProgramFiles\CPUID\CPU-Z\cpuz*.exe", "${env:ProgramFiles(x86)}\CPUID\CPU-Z\cpuz*.exe"); Url='https://www.cpuid.com/softwares/cpu-z.html' }
    @{ Name='GPU-Z';                  Desc='Identité & capteurs carte graphique';         Paths=@("${env:ProgramFiles(x86)}\GPU-Z\GPU-Z.exe", "$script:ToolsDir\GPU-Z*.exe"); Url='https://www.techpowerup.com/gpu-z/' }
    @{ Name='Speccy';                 Desc='Résumé matériel complet';                     Paths=@("$env:ProgramFiles\Speccy\Speccy*.exe", "${env:ProgramFiles(x86)}\Speccy\Speccy*.exe"); Url='https://www.ccleaner.com/speccy' }
    @{ Name='MemTest86';              Desc='Test RAM approfondi (clé USB bootable)';      Paths=@(); Url='https://www.memtest86.com/' }
    @{ Name='TestMem5';               Desc='Stress test RAM poussé';                      Paths=@("$script:ToolsDir\TM5*.exe", "$script:ToolsDir\TestMem*.exe"); Url='https://testmem.cz/' }
    @{ Name='AIDA64';                 Desc='Suite diagnostic & bench (payant, essai)';    Paths=@("${env:ProgramFiles(x86)}\AIDA64*\aida64*.exe"); Url='https://www.aida64.com/' }
    @{ Name='ATTO Disk Benchmark';    Desc='Benchmark disque (petits blocs)';             Paths=@("$script:ToolsDir\ATTODiskBenchmark*.exe"); Url='https://www.atto.com/disk-benchmark/' }
    @{ Name='SeaTools (Seagate)';     Desc='Diagnostic disques Seagate';                  Paths=@("${env:ProgramFiles(x86)}\Seagate\SeaTools*\SeaTools*.exe"); Url='https://www.seagate.com/fr/fr/support/software/seatools/' }
    @{ Name='Samsung Magician';       Desc='Diagnostic & firmware SSD Samsung';           Paths=@("${env:ProgramFiles(x86)}\Samsung\Samsung Magician\SamsungMagician.exe", "$env:ProgramFiles\Samsung\Samsung Magician\SamsungMagician.exe"); Url='https://semiconductor.samsung.com/consumer-storage/magician/' }
    @{ Name='WD Dashboard';           Desc='Diagnostic & firmware SSD Western Digital';   Paths=@("${env:ProgramFiles(x86)}\Western Digital\WD SSD Dashboard\*.exe"); Url='https://support.wdc.com/downloads.aspx?p=279' }
    @{ Name='OCCT';                   Desc='Stress test CPU / GPU / alimentation';        Paths=@("${env:ProgramFiles(x86)}\OCCT\occt.exe", "$env:ProgramFiles\OCCT\occt.exe", "$script:ToolsDir\OCCT*.exe"); Url='https://www.ocbase.com/' }
    @{ Name='FurMark';                Desc='Stress thermique carte graphique';            Paths=@("$script:ToolsDir\FurMark*.exe", "$env:ProgramFiles\FurMark*\FurMark*.exe"); Url='https://geeks3d.com/furmark/' }
    @{ Name='Process Explorer';       Desc='Gestionnaire des tâches avancé (Microsoft)';  Paths=@("$script:ToolsDir\procexp*.exe"); Url='https://learn.microsoft.com/sysinternals/' }
    @{ Name='BlueScreenView';         Desc='Analyse des écrans bleus (BSOD)';             Paths=@("$script:ToolsDir\BlueScreenView*.exe"); Url='https://www.nirsoft.net/utils/blue_screen_view.html' }
    @{ Name='WhoCrashed';             Desc='Cause des crashs en langage clair';           Paths=@(); Url='https://www.resplendence.com/whocrashed' }
    @{ Name='Wireshark';              Desc='Analyse du trafic réseau';                    Paths=@("$env:ProgramFiles\Wireshark\Wireshark.exe"); Url='https://www.wireshark.org/' }
    @{ Name='Everything';             Desc='Recherche de fichiers instantanée';           Paths=@("$env:ProgramFiles\Everything\Everything.exe", "${env:ProgramFiles(x86)}\Everything\Everything.exe"); Url='https://www.voidtools.com/' }
    @{ Name='Revo Uninstaller';       Desc='Désinstallation propre des programmes';       Paths=@("${env:ProgramFiles(x86)}\VS Revo Group\Revo Uninstaller*\revouninstaller*.exe", "$env:ProgramFiles\VS Revo Group\Revo Uninstaller Pro\revouninstallerpro.exe"); Url='https://www.revouninstaller.com/' }
    @{ Name='Malwarebytes';           Desc='Antimalware complémentaire';                  Paths=@("$env:ProgramFiles\Malwarebytes\Anti-Malware\mbam.exe"); Url='https://www.malwarebytes.com/' }
)

function Find-ThirdPartyTools {
    $script:DetectedTools = @{}
    foreach ($tool in $script:ThirdPartyCatalog) {
        $found = $null
        foreach ($pattern in $tool.Paths) {
            $hit = Resolve-Path -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { $found = $hit.Path; break }
        }
        if ($found) { $script:DetectedTools[$tool.Name] = $found }
    }
    $script:PortableTools = @()
    if (Test-Path -LiteralPath $script:ToolsDir) {
        $script:PortableTools = @(Get-ChildItem -LiteralPath $script:ToolsDir -Filter '*.exe' -File -ErrorAction SilentlyContinue)
    }
    $script:SmartCtl = ''
    foreach ($pattern in @("$env:ProgramFiles\smartmontools\bin\smartctl.exe", "$script:ToolsDir\smartctl.exe")) {
        $hit = Resolve-Path -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { $script:SmartCtl = $hit.Path; break }
    }
}

Find-ThirdPartyTools

# ----------------------------------------------------------------
# Mode console (-List)
# ----------------------------------------------------------------
if ($List) {
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
    $bar = '=' * 66
    Write-Host $bar -ForegroundColor DarkCyan
    Write-Host " WINDOWS 11 TOOLBOX v$script:ToolboxVersion — INVENTAIRE" -ForegroundColor Cyan
    Write-Host $bar -ForegroundColor DarkCyan
    Write-Host (" Date       : {0:yyyy-MM-dd HH:mm}" -f (Get-Date))
    Write-Host (" Ordinateur : {0}" -f $env:COMPUTERNAME)
    Write-Host (" Windows    : {0} (build {1})" -f (Get-CimInstance Win32_OperatingSystem).Caption, (Get-CimInstance Win32_OperatingSystem).BuildNumber)
    Write-Host (" Droits     : {0}" -f $(if (Test-IsAdmin) { 'Administrateur' } else { 'Utilisateur standard' }))
    Write-Host ''
    Write-Host ' --- Disques physiques ---' -ForegroundColor Cyan
    try {
        Get-PhysicalDisk | Sort-Object DeviceId | Format-Table DeviceId, FriendlyName, MediaType, BusType, HealthStatus, @{n='Go';e={ [math]::Round($_.Size / 1GB) }} -AutoSize | Out-String | Write-Host
    } catch { Write-Host (" indisponible : " + $_.Exception.Message) }
    Write-Host ' --- Volumes ---' -ForegroundColor Cyan
    try {
        Get-Volume | Sort-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, FileSystem, HealthStatus, @{n='Taille Go';e={ [math]::Round($_.Size / 1GB, 1) }}, @{n='Libre Go';e={ [math]::Round($_.SizeRemaining / 1GB, 1) }} -AutoSize | Out-String | Write-Host
    } catch { Write-Host (" indisponible : " + $_.Exception.Message) }
    Write-Host ' --- Outils tiers détectés ---' -ForegroundColor Cyan
    if ($script:DetectedTools.Count -gt 0) {
        $script:DetectedTools.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Host ("  [OK] {0,-22} → {1}" -f $_.Key, $_.Value) }
    } else {
        Write-Host '  (aucun) — voir README.md pour la liste des outils recommandés'
    }
    Write-Host ' --- Dossier tools\ (outils portables) ---' -ForegroundColor Cyan
    if ($script:PortableTools.Count -gt 0) {
        $script:PortableTools | ForEach-Object { Write-Host ("  [OK] " + $_.Name) }
    } else {
        Write-Host "  (vide) — place tes .exe portables dans : $script:ToolsDir"
    }
    if ($script:SmartCtl) { Write-Host (" smartctl détecté : " + $script:SmartCtl) }
    exit 0
}

# ----------------------------------------------------------------
# Interface graphique
# ----------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$sync = [hashtable]::Synchronized(@{})
$sync.Queue = [System.Collections.Queue]::Synchronized((New-Object System.Collections.Queue))

function Append-Console {
    param([string]$Text)
    $script:ConsoleBox.SelectionStart = $script:ConsoleBox.TextLength
    $script:ConsoleBox.AppendText($Text + "`r`n")
    $script:ConsoleBox.SelectionStart = $script:ConsoleBox.TextLength
    $script:ConsoleBox.ScrollToCaret()
}

function Set-Status {
    param([string]$Text)
    if ($script:StatusLabel) { $script:StatusLabel.Text = $Text }
}

function Start-GuiTarget {
    param([string]$Target, [string]$TargetArgs = '', [switch]$Elevated)
    try {
        if ($TargetArgs) { $null = Start-Process -FilePath $Target -ArgumentList $TargetArgs }
        elseif ($Elevated) { $null = Start-Process -FilePath $Target -Verb RunAs }
        else { $null = Start-Process -FilePath $Target }
    } catch {
        Append-Console ("[ERREUR] Impossible d'ouvrir « {0} » : {1}" -f $Target, $_.Exception.Message)
    }
}

function Start-InlineCommand {
    param([string]$Title, [string]$Script)
    if ($script:Busy) { Set-Status '⏳ Une commande est déjà en cours, patiente…'; return }
    $script:Busy = $true
    Set-Status ("⏳ Exécution : {0} …" -f $Title)
    Append-Console ''
    Append-Console ('===== {0} =====' -f $Title)
    $ps = [powershell]::Create()
    $ps.Runspace.SessionStateProxy.SetVariable('q', $sync.Queue)
    $ps.Runspace.SessionStateProxy.SetVariable('sc', $script:SmartCtl)
    $ps.Runspace.SessionStateProxy.SetVariable('sd', $script:ScriptDir)
    $null = $ps.AddScript('param($code) try { $out = Invoke-Expression -Command $code 2>&1 | Out-String -Width 200; if (-not [string]::IsNullOrWhiteSpace($out)) { $out.TrimEnd() -split "`r?`n" | ForEach-Object { $q.Enqueue($_) } } else { $q.Enqueue("(aucune sortie)") } } catch { $q.Enqueue("[ERREUR] " + $_.Exception.Message) }')
    $null = $ps.AddArgument($Script)
    $script:PS     = $ps
    $script:Handle = $ps.BeginInvoke()
}

function Start-ElevatedCommand {
    param([string]$Title, [string]$Script)
    Append-Console ''
    Append-Console ('===== [admin] {0} — ouverture d''une console élevée (UAC) =====' -f $Title)
    $tmp  = Join-Path $env:TEMP ("wtoolbox_{0}.ps1" -f [guid]::NewGuid().ToString('N'))
    $escT = $Title -replace "'", "''"
    $escS = $script:SmartCtl -replace "'", "''"
    $escF = $tmp -replace "'", "''"
    $parts = @(
        "`$host.UI.RawUI.WindowTitle = 'Windows Toolbox — console admin'",
        "Write-Host ('=' * 66) -ForegroundColor DarkGray",
        "Write-Host '  $escT' -ForegroundColor Cyan",
        "Write-Host ('=' * 66) -ForegroundColor DarkGray",
        "Write-Host ''",
        "`$sc = '$escS'",
        'try {',
        $Script,
        '} catch { Write-Host (''[ERREUR] '' + $_.Exception.Message) -ForegroundColor Red }',
        "Write-Host ''",
        "Read-Host '  [Terminé] Appuyez sur Entrée pour fermer'",
        "Remove-Item -LiteralPath '$escF' -Force -ErrorAction SilentlyContinue"
    )
    Set-Content -LiteralPath $tmp -Value $parts -Encoding UTF8
    try {
        $null = Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$tmp`"")
        Append-Console "(la sortie s'affiche dans la fenêtre admin qui vient de s'ouvrir)"
    } catch {
        Append-Console ('[ERREUR] UAC refusé ou échec de l''élévation : ' + $_.Exception.Message)
    }
}

# ----------------------------------------------------------------
# Intégrité & mises à jour à distance
# ----------------------------------------------------------------
function Test-ToolboxIntegrity {
    # Protège le logiciel : si checksums.txt (généré par Build-Toolbox.ps1) est présent
    # à côté du script, vérifie que le programme n'a pas été modifié ou corrompu.
    if ($PSCommandPath -notlike '*.ps1') { return }
    $sumFile = Join-Path $script:ScriptDir 'checksums.txt'
    if (-not (Test-Path -LiteralPath $sumFile)) { return }
    try {
        $expected = ((Get-Content -LiteralPath $sumFile -ErrorAction Stop | Select-String -Pattern 'Windows-Toolbox\.ps1' | Select-Object -First 1).Line -split '\s+') | Select-Object -Index 1
        $actual = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
        if ($expected -and ($actual -ne $expected)) {
            Append-Console '[INTÉGRITÉ] ATTENTION : empreinte du programme différente de checksums.txt — fichier modifié ou corrompu. Retélécharge depuis la source officielle.'
        }
    } catch { }
}

function Start-UpdateCheck {
    param([switch]$Manual)
    if ($script:Busy) { Set-Status '⏳ Une commande est déjà en cours…'; return }
    $script:Busy = $true
    $script:UpdateIsManual = [bool]$Manual
    if ($Manual) { Set-Status '⏳ Recherche de mise à jour…' }
    $ps = [powershell]::Create()
    $ps.Runspace.SessionStateProxy.SetVariable('q', $sync.Queue)
    $ps.Runspace.SessionStateProxy.SetVariable('manifestUrl', $script:UpdateManifestUrl)
    $ps.Runspace.SessionStateProxy.SetVariable('localVer', $script:ToolboxVersion)
    $ps.Runspace.SessionStateProxy.SetVariable('manual', [bool]$Manual)
    $null = $ps.AddScript(@'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
  $m = Invoke-RestMethod -Uri $manifestUrl -TimeoutSec 15
  $rv = $null; $lv = $null
  try { $rv = [version]$m.version } catch { }
  try { $lv = [version]$localVer } catch { }
  if ($rv -and $lv -and $rv -gt $lv) { $q.Enqueue("UPDATE|$($m.version)|$($m.url)|$($m.sha256)|$($m.notes)") }
  else { $q.Enqueue("UPDOK|$localVer") }
} catch {
  if ($manual) { $q.Enqueue("UPDERR|$($_.Exception.Message)") }
}
'@)
    $script:PS     = $ps
    $script:Handle = $ps.BeginInvoke()
}

function Start-UpdateInstall {
    param([string]$Version, [string]$Url, [string]$Hash)
    if ($script:Busy) { return }
    $script:Busy = $true
    Set-Status ("⏳ Téléchargement de la version {0}…" -f $Version)
    Append-Console ("[MAJ] Téléchargement de la version {0}…" -f $Version)
    $ps = [powershell]::Create()
    $ps.Runspace.SessionStateProxy.SetVariable('q', $sync.Queue)
    $ps.Runspace.SessionStateProxy.SetVariable('dlUrl', $Url)
    $ps.Runspace.SessionStateProxy.SetVariable('dlHash', $Hash)
    $ps.Runspace.SessionStateProxy.SetVariable('dest', $PSCommandPath)
    $ps.Runspace.SessionStateProxy.SetVariable('isExe', ($PSCommandPath -like '*.exe'))
    $ps.Runspace.SessionStateProxy.SetVariable('newVer', $Version)
    $null = $ps.AddScript(@'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
  if ($isExe) {
    $tmp = "$dest.$newVer.exe"
    Invoke-WebRequest -Uri $dlUrl -OutFile $tmp -TimeoutSec 300 -UseBasicParsing
    $q.Enqueue("UPDDONE-EXE|$newVer|$tmp")
  } else {
    $tmp = "$dest.new"
    Invoke-WebRequest -Uri $dlUrl -OutFile $tmp -TimeoutSec 300 -UseBasicParsing
    if ($dlHash) {
      $h = (Get-FileHash $tmp -Algorithm SHA256).Hash
      if ($h -ne $dlHash) {
        $q.Enqueue('UPDFAIL|Empreinte SHA256 différente du manifeste — mise à jour refusée par sécurité.')
        Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        return
      }
      $q.Enqueue('[MAJ] Empreinte SHA256 du téléchargement vérifiée OK')
    }
    $errs = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile($tmp, [ref]$null, [ref]$errs)
    if ($errs -and $errs.Count -gt 0) {
      $q.Enqueue('UPDFAIL|Fichier téléchargé invalide (erreur de syntaxe) — installation annulée.')
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
      return
    }
    Move-Item -Force -Path $tmp -Destination $dest
    $q.Enqueue("UPDDONE|$newVer")
  }
} catch { $q.Enqueue('UPDFAIL|' + $_.Exception.Message) }
'@)
    $script:PS     = $ps
    $script:Handle = $ps.BeginInvoke()
}

function Show-UpdateOffer {
    param([string]$Version, [string]$Url, [string]$Hash, [string]$Notes)
    Append-Console ("[MAJ] Nouvelle version disponible : {0} (actuelle : {1})" -f $Version, $script:ToolboxVersion)
    if ($Notes) { Append-Console ('[MAJ] ' + $Notes) }
    $msg = "Nouvelle version $Version disponible (tu as la $($script:ToolboxVersion)).`r`n`r`n" + $(if ($Notes) { $Notes + "`r`n`r`n" }) + "Télécharger et installer maintenant ?"
    $r = [Windows.Forms.MessageBox]::Show($script:Form, $msg, 'Mise à jour — Windows Toolbox', 'YesNo', 'Question')
    if ($r -eq [Windows.Forms.DialogResult]::Yes) { Start-UpdateInstall -Version $Version -Url $Url -Hash $Hash }
    else { Append-Console '[MAJ] Reportée — bouton « Vérifier les mises à jour » dans l''onglet À propos.' }
}

# ----------------------------------------------------------------
# Systray & raccourcis (v2.0)
# ----------------------------------------------------------------
function Register-ToolboxHotkey {
    param($Form)
    if ((Get-ToolboxSetting 'GlobalHotkey' 1) -ne 1) { return }
    $ok = [WindowsToolbox.Win32Hot]::RegisterHotKey($Form.Handle, $script:HotkeyId, $script:HotkeyMods, $script:HotkeyVk)
    if (-not $ok) { Append-Console '[RAPIDE] Raccourci global Ctrl+Alt+T indisponible (déjà utilisé par un autre programme).' }
}

function Unregister-ToolboxHotkey {
    param($Form)
    try { [void][WindowsToolbox.Win32Hot]::UnregisterHotKey($Form.Handle, $script:HotkeyId) } catch { }
}

function Show-ToolboxWindow {
    $script:Form.WindowState = 'Normal'
    $script:Form.Show()
    $script:Form.Activate()
}

function Hide-Toolbox {
    $script:Form.Hide()
    if (-not $script:BalloonShown) {
        $script:BalloonShown = $true
        try { $script:TrayIcon.ShowBalloonTip(3000, 'Windows 11 Toolbox', 'Réduite dans la zone de notification — Ctrl+Alt+T ou clic sur l''icône pour la rappeler.', 'Info') } catch { }
    }
}

function Toggle-ToolboxVisible {
    if ($script:Form.Visible) { Hide-Toolbox } else { Show-ToolboxWindow }
}

function Set-StartupWithWindows {
    param([bool]$On)
    $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (-not (Test-Path -LiteralPath $runKey)) { New-Item -Path $runKey -Force | Out-Null }
    if ($On) {
        $val = if ($PSCommandPath -like '*.exe') { "`"$PSCommandPath`"" }
               else { "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`"" }
        Set-ItemProperty -Path $runKey -Name 'WindowsToolbox' -Value $val
        Append-Console '[OPTIONS] La toolbox démarrera avec Windows ✓'
    } else {
        Remove-ItemProperty -Path $runKey -Name 'WindowsToolbox' -ErrorAction SilentlyContinue
        Append-Console '[OPTIONS] Démarrage avec Windows désactivé.'
    }
}

# ----------------------------------------------------------------
# Commandes (scripts PowerShell exécutés par les boutons)
# ----------------------------------------------------------------
$script:CmdSummary = @'
$os  = Get-CimInstance Win32_OperatingSystem
$cs  = Get-CimInstance Win32_ComputerSystem
$bio = Get-CimInstance Win32_BIOS
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
'Machine      : {0} {1}' -f $cs.Manufacturer, $cs.Model
'Bios         : {0}' -f $bio.SMBIOSBIOSVersion
'Windows      : {0} — build {1} ({2})' -f $os.Caption, $os.BuildNumber, $os.OSArchitecture
'Processeur   : {0} ({1} cœurs logiques)' -f $cpu.Name.Trim(), $cpu.NumberOfLogicalProcessors
'Carte graph. : {0}' -f $gpu.Name
'RAM          : {0:N1} Go (libre : {1:N1} Go)' -f ($cs.TotalPhysicalMemory/1GB), ($os.FreePhysicalMemory*1KB/1GB)
$up = (Get-Date) - $os.LastBootUpTime
'Allumé depuis : {0} j {1} h {2} min' -f $up.Days, $up.Hours, $up.Minutes
'Utilisateur  : {0}' -f $env:USERNAME
'@

$script:CmdDiskHealth = @'
$disks = Get-PhysicalDisk | Sort-Object DeviceId
if (-not $disks) { 'Aucun disque physique détecté (Get-PhysicalDisk indisponible ?)' }
else {
  $disks | ForEach-Object {
    '{0} | {1} | {2} | {3:N0} Go | Santé : {4} | État : {5}' -f $_.DeviceId, $_.FriendlyName, $_.MediaType, ($_.Size/1GB), $_.HealthStatus, ($_.OperationalStatus -join ', ')
  }
  ''
  'Total : {0} disque(s) — {1} en bonne santé (Healthy)' -f @($disks).Count, @($disks | Where-Object { $_.HealthStatus -eq 'Healthy' }).Count
}
'@

$script:CmdDiskSmart = @'
$smarts = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
if (-not $smarts) {
  'Aucune donnée SMART classique exposée (fréquent sur les SSD NVMe).'
  '→ Utilise CrystalDiskInfo (onglet Outils tiers) ou le bouton admin « SMART détaillé ».'
}
else {
  $smarts | ForEach-Object { '{0} | Panne prédite : {1} | Code : {2}' -f $_.InstanceName, $_.PredictFailure, $_.Reason }
  ''
  'Si « Panne prédite : False » partout → aucun signalement SMART.'
}
'@

$script:CmdDiskDetail = @'
Get-Disk | Format-Table Number, FriendlyName, BusType, HealthStatus, @{n='Taille Go';e={[math]::Round($_.Size/1GB)}} -AutoSize
''
Get-PhysicalDisk | Format-Table DeviceId, FriendlyName, MediaType, FirmwareVersion, SerialNumber, HealthStatus -AutoSize
'@

$script:CmdVolumes = @'
Get-Volume | Sort-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel, FileSystem, HealthStatus, @{n='Taille Go';e={[math]::Round($_.Size/1GB,1)}}, @{n='Libre Go';e={[math]::Round($_.SizeRemaining/1GB,1)}} -AutoSize
'@

$script:CmdIpconfig = @'
ipconfig /all
'@

$script:CmdNetAdapter = @'
Get-NetAdapter | Format-Table Name, InterfaceDescription, Status, LinkSpeed, MacAddress -AutoSize
'@

$script:CmdPingInet = @'
ping -n 4 8.8.8.8
'@

$script:CmdPingGw = @'
$gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).NextHop
if ($gw) { "Passerelle : $gw"; '' ; ping -n 4 $gw } else { 'Passerelle par défaut introuvable.' }
'@

$script:CmdNsLookup = @'
nslookup google.com
'@

$script:CmdTracert = @'
tracert -d -h 15 1.1.1.1
'@

$script:CmdPorts = @'
Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Sort-Object LocalPort | ForEach-Object {
  $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
  '{0,-28}:{1,-6} PID {2,-7} {3}' -f $_.LocalAddress, $_.LocalPort, $_.OwningProcess, $p.ProcessName
}
'@

$script:CmdWinget = @'
if (Get-Command winget -ErrorAction SilentlyContinue) { winget upgrade --accept-source-agreements --disable-interactivity }
else { 'winget introuvable — installe « App Installer » depuis le Microsoft Store.' }
'@

$script:CmdBattery = @'
$out = Join-Path $env:TEMP 'toolbox-rapport-batterie.html'
powercfg /batteryreport /output $out | Out-Null
if (Test-Path $out) { Start-Process $out; "Rapport batterie généré : $out" } else { 'Échec de génération du rapport batterie.' }
'@

$script:CmdLicense = @'
cscript //nologo "$env:SystemRoot\System32\slmgr.vbs" /xpr
'@

$script:CmdW32Time = @'
w32tm /resync
'@

$script:CmdRareBattery = @'
$bat = Get-CimInstance Win32_Battery
if (-not $bat) {
  'Aucune batterie détectée — ce PC est un fixe.'
}
else {
  '=== État instantané ==='
  'Charge          : {0} %' -f $bat.EstimatedChargeRemaining
  'Statut batterie : {0}  (2 = OK / sur secteur)' -f $bat.BatteryStatus
  $rt = $bat.EstimatedRunTime
  if ($rt -gt 0 -and $rt -lt 14400) { 'Autonomie estim.: {0} h {1:D2} min' -f [int][math]::Floor($rt/60), ($rt % 60) } else { 'Autonomie estim.: non calculable (sur secteur ?)' }
  'Tension         : {0:N2} V' -f ($bat.DesignVoltage/1000)
  ''
  '=== Usure (capacité d''origine vs actuelle) ==='
  $design = (Get-CimInstance -Namespace root\wmi -Class BatteryStaticData -ErrorAction SilentlyContinue).DesignedCapacity
  $full   = (Get-CimInstance -Namespace root\wmi -Class BatteryFullChargedCapacity -ErrorAction SilentlyContinue).FullChargedCapacity
  $cycles = (Get-CimInstance -Namespace root\wmi -Class BatteryCycleCount -ErrorAction SilentlyContinue).CycleCount
  if ($design -and $full) {
    'Capacité d''origine : {0} mWh' -f $design
    'Capacité actuelle  : {0} mWh' -f $full
    'Usure              : {0} %' -f [math]::Round(100 - (100.0 * $full / $design), 1)
  } else { 'Capacités non exposées par ce modèle de batterie.' }
  if ($cycles) { 'Cycles de charge   : {0}' -f $cycles }
  ''
  '=== Débit instantané ==='
  $st = Get-CimInstance -Namespace root\wmi -Class BatteryStatus -ErrorAction SilentlyContinue
  if ($st) {
    if ($st.PowerOnline) { 'Alimentation : sur secteur' } else { 'Alimentation : sur batterie' }
    if ($st.DischargeRate -gt 0) { 'Consommation actuelle : {0} mW ({1:N1} W)' -f $st.DischargeRate, ($st.DischargeRate/1000) }
    if ($st.ChargingRate -gt 0) { 'Charge en cours : {0} mW' -f $st.ChargingRate }
  }
}
'@

$script:CmdRareEnergy = @'
powercfg /energy /output "$env:TEMP\toolbox-energy.html"
if (Test-Path "$env:TEMP\toolbox-energy.html") { Start-Process "$env:TEMP\toolbox-energy.html" }
'@

$script:CmdRareSleep = @'
powercfg /sleepstudy /output "$env:TEMP\toolbox-sleepstudy.html"
if (Test-Path "$env:TEMP\toolbox-sleepstudy.html") { Start-Process "$env:TEMP\toolbox-sleepstudy.html" } else { 'SleepStudy non disponible (nécessite Modern Standby).' }
'@

$script:CmdRareRam = @'
Get-CimInstance Win32_PhysicalMemory | ForEach-Object {
  'Slot {0} : {1} Go — {2} — {3} MT/s — {4}' -f $_.DeviceLocator, ($_.Capacity/1GB), $_.Manufacturer, $_.ConfiguredClockSpeed, $_.PartNumber.Trim()
}
''
'Total barrettes installées : {0}' -f @(Get-CimInstance Win32_PhysicalMemory).Count
'@

$script:CmdRareTopProc = @'
'=== Top 15 CPU ==='
Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 | Format-Table Name, Id, @{n='CPU (s)';e={ [math]::Round($_.CPU, 1) }}, @{n='RAM (Mo)';e={ [math]::Round($_.WS/1MB) }} -AutoSize
''
'=== Top 15 RAM ==='
Get-Process | Sort-Object WS -Descending | Select-Object -First 15 | Format-Table Name, Id, @{n='RAM (Mo)';e={ [math]::Round($_.WS/1MB) }} -AutoSize
'@

$script:CmdRareInstalled = @'
$paths = @(
  'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
Get-ItemProperty $paths -ErrorAction SilentlyContinue |
  Where-Object { $_.DisplayName } |
  Sort-Object DisplayName -Unique |
  ForEach-Object { '{0}  —  {1}' -f $_.DisplayName, $_.DisplayVersion }
'@

$script:CmdRareLicense = @'
$key = (Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey
if ($key) { 'Clé BIOS/UEFI (OA3) : {0}' -f $key } else { 'Pas de clé OA3 dans le BIOS (licence numérique liée au compte ?)' }
''
cscript //nologo "$env:SystemRoot\System32\slmgr.vbs" /dli
'@

$script:CmdRarePnp = @'
$bad = Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne 'OK' }
if ($bad) { $bad | Format-Table Status, Class, FriendlyName, InstanceId -AutoSize } else { 'Tous les périphériques présents sont OK.' }
'@

$script:CmdRareDiskUsage = @'
'Taille des dossiers racine de C: (lecture seule, peut prendre 2-5 min — certains dossiers système sont exclus sans admin) :'
''
$rows = @()
foreach ($d in (Get-ChildItem C:\ -Directory -Force -ErrorAction SilentlyContinue)) {
  $sum = (Get-ChildItem -LiteralPath $d.FullName -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
  $rows += [pscustomobject]@{ Dossier = $d.Name; 'Go' = [math]::Round($sum/1GB, 1) }
}
$rows | Sort-Object Go -Descending | Where-Object { $_.Go -gt 0 } | Format-Table -AutoSize
''
'Fichiers à la racine de C: (10 plus gros) :'
Get-ChildItem C:\ -File -Force -ErrorAction SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 10 | ForEach-Object { '{0,8:N1} Go  {1}' -f ($_.Length/1GB), $_.Name }
'@

$script:CmdRareWei = @'
$s = Get-CimInstance Win32_WinSAT
if ($s -and $s.FormalAssessment -eq 'Formal') {
  'Score global (le plus bas des 4) : {0}' -f $s.WinSPR
  'Processeur  : {0}' -f $s.CPUScore
  'Mémoire     : {0}' -f $s.MemoryScore
  'Graphiques  : {0}' -f $s.GraphicsScore
  'Disque      : {0}' -f $s.DiskScore
} else { 'Pas d''évaluation récente — lance « Benchmark système complet (winsat formal) » puis relance ce test.' }
'@

$script:CmdRareWlan = @'
netsh wlan show interfaces
''
netsh wlan show profiles
''
netsh wlan show drivers
'@

$script:CmdRareWlanReport = @'
netsh wlan show wlanreport report=write
$p = Join-Path $env:ProgramData 'Microsoft\Windows\WlanReport\wlan-report-latest.html'
if (Test-Path $p) { Start-Process $p } else { 'Rapport WiFi introuvable.' }
'@

$script:CmdRareTnc = @'
'Test : connexion HTTPS vers google.com (port 443) :'
Test-NetConnection -ComputerName google.com -Port 443 -WarningAction SilentlyContinue | Format-List ComputerName, RemoteAddress, TcpTestSucceeded, PingSucceeded
''
'Test : DNS vers 1.1.1.1 (port 53) — TcpTestSucceeded :'
(Test-NetConnection -ComputerName 1.1.1.1 -Port 53 -WarningAction SilentlyContinue).TcpTestSucceeded
'@

$script:CmdRareEvents = @'
'Derniers événements Système — critiques, erreurs, avertissements (25 derniers) :'
''
Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2, 3 } -MaxEvents 25 -ErrorAction SilentlyContinue |
  ForEach-Object { '[{0:yyyy-MM-dd HH:mm}] {1} | ID {2} | {3} | {4}' -f $_.TimeCreated, $_.LevelDisplayName, $_.Id, $_.ProviderName, ($_.Message -split "`r?`n")[0] }
'@

$script:CmdRareCrashes = @'
$boot = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 41, 6008, 1074 } -MaxEvents 15 -ErrorAction SilentlyContinue
if ($boot) {
  $boot | ForEach-Object {
    $what = switch ($_.Id) {
      41   { 'Arrêt inattendu (perte alim / blocage / BSOD)' }
      6008 { 'Arrêt brutal (sans arrêt propre)' }
      1074 { 'Redémarrage/arrêt demandé par un programme ou un utilisateur' }
      default { 'Autre' }
    }
    '[{0:yyyy-MM-dd HH:mm}] ID {1} — {2}' -f $_.TimeCreated, $_.Id, $what
  }
} else { 'Aucun événement d''arrêt inattendu récent.' }
''
'--- Minidumps BSOD (C:\Windows\Minidump) ---'
$dumps = Get-ChildItem $env:SystemRoot\Minidump -ErrorAction SilentlyContinue
if ($dumps) {
  $dumps | Sort-Object LastWriteTime -Descending | ForEach-Object { '{0:yyyy-MM-dd HH:mm}  {1}  ({2:N0} Ko)' -f $_.LastWriteTime, $_.Name, ($_.Length/1KB) }
  '→ Pour analyser : BlueScreenView ou WhoCrashed (onglet Outils tiers).'
} else { 'Aucun minidump — pas d''écran bleu enregistré.' }
'@

$script:CmdRareGpo = @'
gpresult /h "$env:TEMP\toolbox-gpo.html" /f
if (Test-Path "$env:TEMP\toolbox-gpo.html") { Start-Process "$env:TEMP\toolbox-gpo.html"; 'Rapport de stratégies de groupe généré et ouvert.' } else { 'Échec de génération gpresult.' }
'@

# ---------------- Nettoyage & rapidité ----------------

$script:CmdCleanMeasure = @'
function Mesure([string]$p) {
  if (-not (Test-Path -LiteralPath $p)) { return $null }
  $s = (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
  [math]::Round($s/1MB, 1)
}
function Ligne([string]$label, $val) {
  if ($null -eq $val) { '{0,-44} : n/a' -f $label } else { '{0,-44} : {1:N1} Mo' -f $label, $val }
}
Ligne 'Temp utilisateur' (Mesure $env:TEMP)
Ligne 'Temp Windows (admin requis)' (Mesure "$env:SystemRoot\Temp")
Ligne 'Cache Windows Update (admin requis)' (Mesure "$env:SystemRoot\SoftwareDistribution\Download")
Ligne 'Cache Delivery Optimization (admin requis)' (Mesure 'C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache')
Ligne 'Vignettes (thumbcache)' (Mesure "$env:LOCALAPPDATA\Microsoft\Windows\Explorer")
Ligne 'Rapports d''erreurs (WER)' (Mesure "$env:LOCALAPPDATA\Microsoft\Windows\WER")
Ligne 'Cache Chrome (profil par défaut)' (Mesure "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache")
Ligne 'Cache Edge (profil par défaut)' (Mesure "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache")
$rb = (Get-ChildItem 'C:\$Recycle.Bin' -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Ligne 'Corbeille (lecteur C:)' $(if ($null -ne $rb) { [math]::Round($rb/1MB, 1) } else { $null })
''
'Astuce : les lignes « admin requis » se nettoient avec les boutons orange.'
'@

$script:CmdCleanUserTemp = @'
$before = (Get-ChildItem $env:TEMP -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Get-ChildItem $env:TEMP -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$after = (Get-ChildItem $env:TEMP -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
'Temp utilisateur nettoyé : {0:N1} Mo libérés (les fichiers en cours d''utilisation sont ignorés, c''est normal).' -f ([math]::Max(0, $before - $after)/1MB)
'@

$script:CmdCleanWinTemp = @'
$dir = "$env:SystemRoot\Temp"
$before = (Get-ChildItem $dir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Get-ChildItem $dir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$after = (Get-ChildItem $dir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
'Temp Windows nettoyé : {0:N1} Mo libérés.' -f ([math]::Max(0, $before - $after)/1MB)
'@

$script:CmdCleanWU = @'
$dir = "$env:SystemRoot\SoftwareDistribution\Download"
$before = (Get-ChildItem $dir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Stop-Service wuauserv, bits -Force -ErrorAction SilentlyContinue
Get-ChildItem $dir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Start-Service bits, wuauserv -ErrorAction SilentlyContinue
$after = (Get-ChildItem $dir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
'Cache Windows Update vidé : {0:N1} Mo libérés. Les mises à jour nécessaires seront retéléchargées automatiquement.' -f ([math]::Max(0, $before - $after)/1MB)
'@

$script:CmdCleanDO = @'
try { Delete-DeliveryOptimizationCache -Force -ErrorAction Stop; 'Cache Delivery Optimization vidé.' }
catch { 'Cmdlet indisponible sur cette édition : ' + $_.Exception.Message }
'@

$script:CmdCleanThumbs = @'
$dir = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
$before = (Get-ChildItem $dir -Filter 'thumbcache*.db' -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Get-ChildItem $dir -Filter 'thumbcache*.db' -Force -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
$after = (Get-ChildItem $dir -Filter 'thumbcache*.db' -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
'Vignettes : {0:N1} Mo libérés (l''Explorateur les recrée au fur et à mesure).' -f ([math]::Max(0, $before - $after)/1MB)
'Certains fichiers bloqués par l''Explorateur peuvent rester — redémarre d''abord l''Explorateur (bouton dédié) pour tout vider.'
'@

$script:CmdCleanWer = @'
$dir = "$env:LOCALAPPDATA\Microsoft\Windows\WER"
$before = (Get-ChildItem $dir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Get-ChildItem $dir -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
$after = (Get-ChildItem $dir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
'Rapports d''erreurs Windows nettoyés : {0:N1} Mo libérés.' -f ([math]::Max(0, $before - $after)/1MB)
'@

$script:CmdCleanBrowsers = @'
$targets = @(
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
  "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",
  "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
)
$total = 0
foreach ($t in $targets) {
  if (Test-Path $t) {
    $s = (Get-ChildItem $t -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem $t -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    $left = (Get-ChildItem $t -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $total += [math]::Max(0, $s - $left)
    'Nettoyé : {0}  ({1:N1} Mo)' -f $t.Replace($env:LOCALAPPDATA, '~'), ($s/1MB)
  }
}
''
'Total libéré : {0:N1} Mo — favoris et mots de passe conservés.' -f ($total/1MB)
'Un cache de navigateur ouvert reste partiellement verrouillé : ferme Chrome/Edge et relance si besoin.'
'@

$script:CmdCleanBin = @'
$rb = (Get-ChildItem 'C:\$Recycle.Bin' -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
Clear-RecycleBin -DriveLetter C -Force -ErrorAction SilentlyContinue
$rb2 = (Get-ChildItem 'C:\$Recycle.Bin' -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
'Corbeille du lecteur C: vidée : {0:N1} Mo libérés.' -f ([math]::Max(0, $rb - $rb2)/1MB)
'@

$script:CmdRestorePoint = @'
Checkpoint-Computer -Description 'Windows Toolbox' -RestorePointType MODIFY_SETTINGS
$rp = Get-ComputerRestorePoint | Sort-Object CreationTime -Descending | Select-Object -First 1
if ($rp) { 'Point de restauration créé : {0} ({1:yyyy-MM-dd HH:mm})' -f $rp.Description, $rp.CreationTime }
else { 'Échec : active la Protection système (Système → Protection système) puis réessaie. Limite : 1 point par 24 h.' }
'@

$script:CmdHibernateOff = @'
powercfg /h off
'Hibernation désactivée : hiberfil.sys supprimé (souvent 4-16 Go libérés), démarrage rapide désactivé aussi.'
'Inverse avec le bouton « Réactiver l''hibernation ».'
'@

$script:CmdHibernateOn = @'
powercfg /h on
'Hibernation réactivée (hiberfil.sys recréé, démarrage rapide remis).'
'@

$script:CmdBigFiles = @'
'Top 20 des plus gros fichiers de ton profil utilisateur (30-60 s) :'
''
Get-ChildItem $env:USERPROFILE -Recurse -File -Force -ErrorAction SilentlyContinue |
  Sort-Object Length -Descending | Select-Object -First 20 |
  ForEach-Object { '{0,8:N1} Go  {1}' -f ($_.Length/1GB), $_.FullName.Replace($env:USERPROFILE, '~') }
'@

$script:CmdRestartExplorer = @'
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer }
'Explorateur Windows redémarré — bureau et barre des tâches relancés (répare les lenteurs d''affichage).'
'@

$script:CmdStartupList = @'
'=== Applications lancées au démarrage ==='
Get-CimInstance Win32_StartupCommand | ForEach-Object { '{0,-38} {1}' -f $_.Name, $_.Command }
''
'→ Pour en désactiver : Ctrl+Maj+Échap (onglet Démarrer) ou bouton « Applications au démarrage » (onglet Outils Windows).'
'@

$script:CmdHighPerf = @'
$high = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
if (-not (powercfg /list | Select-String $high)) { powercfg /duplicatescheme $high | Out-Null }
powercfg /setactive $high
powercfg /getactivescheme
''
'(Sur un portable ce plan réduit l''autonomie — bouton « Plan Équilibré » pour revenir.)'
'@

$script:CmdBalanced = @'
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e
powercfg /getactivescheme
'@

$script:CmdFixSearch = @'
Stop-Service WSearch -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Get-ChildItem "$env:ProgramData\Microsoft\Search\Data\Applications\Windows" -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
Set-Service WSearch -StartupType Automatic
Start-Service WSearch -ErrorAction SilentlyContinue
'Service de recherche réinitialisé — l''indexation repart de zéro en arrière-plan (laisse le PC tourner un moment).'
'@

$script:CmdFixStoreApps = @'
'Réenregistrement des applications Microsoft Store (2-5 min, laisse tourner)…'
Get-AppxPackage -AllUsers | ForEach-Object {
  $m = Join-Path $_.InstallLocation 'AppXManifest.xml'
  if (Test-Path $m) { Add-AppxPackage -DisableDevelopmentMode -Register $m -ErrorAction SilentlyContinue }
}
'Terminé — redémarre le PC si une application restait cassée.'
'@

$script:CmdTelemetry = @'
New-Item 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Force | Out-Null
Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name AllowTelemetry -Value 1 -Type DWord
Stop-Service DiagTrack -Force -ErrorAction SilentlyContinue
Set-Service DiagTrack -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service dmwappushservice -Force -ErrorAction SilentlyContinue
'Télémétrie au minimum + service de diagnostic DiagTrack désactivé (plus de ressources pour toi).'
'@

$script:CmdAudit = @'
'=== AUDIT EXPRESS WINDOWS TOOLBOX (lecture seule) ==='
''
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
'Windows : {0} (build {1})' -f $os.Caption, $os.BuildNumber
$up = (Get-Date) - $os.LastBootUpTime
'Allumé depuis {0} j {1} h {2} min — dernier démarrage {3:yyyy-MM-dd HH:mm}' -f $up.Days, $up.Hours, $up.Minutes, $os.LastBootUpTime
''
'--- Espace disque ---'
Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' } | ForEach-Object {
  $freePct = if ($_.Size) { [math]::Round(100 * $_.SizeRemaining / $_.Size, 1) } else { 0 }
  $flag = if ($freePct -lt 10) { '!!! PRESQUE PLEIN — onglet Nettoyage !!!' } elseif ($freePct -lt 20) { '!! peu d''espace' } else { 'OK' }
  '{0}: {1:N0} Go au total, {2:N1} Go libres ({3} %) — {4}' -f $_.DriveLetter, ($_.Size/1GB), ($_.SizeRemaining/1GB), $freePct, $flag
}
''
'--- Santé des disques ---'
Get-PhysicalDisk | ForEach-Object { '{0} ({1}) : {2}' -f $_.FriendlyName, $_.MediaType, $_.HealthStatus }
''
'--- RAM ---'
'RAM totale : {0:N1} Go — libre : {1:N1} Go — {2} barrette(s)' -f ($cs.TotalPhysicalMemory/1GB), ($os.FreePhysicalMemory*1KB/1GB), @(Get-CimInstance Win32_PhysicalMemory).Count
''
'--- Erreurs système (7 derniers jours) ---'
$crit = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = (Get-Date).AddDays(-7) } -ErrorAction SilentlyContinue)
if ($crit.Count -gt 0) { '{0} erreur(s)/critique(s) — détail : onglet ⚡ « 25 derniers événements système »' -f $crit.Count } else { 'Aucune erreur critique — OK' }
''
'--- Temps du dernier démarrage ---'
try {
  $b = Get-WinEvent -FilterHashtable @{ LogName = 'Microsoft-Windows-Diagnostics-Performance/Operational'; Id = 100 } -MaxEvents 1 -ErrorAction Stop
  $main = $b.Properties[4].Value
  $post = $b.Properties[5].Value
  if (($main -is [ValueType]) -and ($post -is [ValueType])) { 'Démarrage en {0:N1} s le {1:yyyy-MM-dd HH:mm}' -f (($main + $post)/1000), $b.TimeCreated }
  else { 'Temps de démarrage : non lu (format inattendu).' }
} catch { 'Temps de démarrage : non disponible sur ce PC.' }
''
'--- Démarrage & mises à jour ---'
'Apps au démarrage : {0}' -f @(Get-CimInstance Win32_StartupCommand).Count
$hf = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
if ($hf -and $hf.InstalledOn) { 'Dernière mise à jour installée : {0} le {1:yyyy-MM-dd}' -f $hf.HotFixID, $hf.InstalledOn } else { 'Historique de mises à jour non lisible.' }
$bat = Get-CimInstance Win32_Battery
if ($bat) { 'Batterie : {0} % de charge' -f $bat.EstimatedChargeRemaining }
''
'=== Fin de l''audit — agis via les onglets « Nettoyage & rapidité » et « Disques & SSD » ==='
'@

# ---------------- Achat PC (pré-achat) ----------------

$script:CmdBuySpecs = @'
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
'Windows      : {0} ({1})' -f $os.Caption, $os.OSArchitecture
'Machine      : {0} {1}' -f $cs.Manufacturer, $cs.Model
'Processeur   : {0}' -f $cpu.Name.Trim()
'RAM          : {0:N1} Go — {1} barrette(s)' -f ($cs.TotalPhysicalMemory/1GB), @(Get-CimInstance Win32_PhysicalMemory).Count
Get-CimInstance Win32_VideoController | ForEach-Object { 'Carte graph. : {0}' -f $_.Name }
Get-PhysicalDisk | ForEach-Object { 'Disque       : {0} — {1:N0} Go — {2}' -f $_.FriendlyName, ($_.Size/1GB), $_.MediaType }
''
'→ Compare ces specs avec l''annonce du vendeur.'
'@

$script:CmdBuyDisks = @'
Get-PhysicalDisk | ForEach-Object { '{0} : {1} ({2})' -f $_.FriendlyName, $_.HealthStatus, $_.MediaType }
$p = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
if ($p | Where-Object { $_.PredictFailure }) { '⚠ SMART : PANNE PRÉDITE — n''achète pas sans grosse négociation !' }
else { 'SMART : aucune panne prédite' }
'(Usure SSD détaillée : bouton admin « SMART détaillé » de l''onglet Disques & SSD.)'
'@

$script:CmdBuyCrashes = @'
$since = (Get-Date).AddDays(-90)
$crashes = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 41, 6008; StartTime = $since } -ErrorAction SilentlyContinue)
$bsod = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 1001; StartTime = $since } -ErrorAction SilentlyContinue)
$dumps = @(Get-ChildItem "$env:SystemRoot\Minidump" -ErrorAction SilentlyContinue)
'90 derniers jours : {0} arrêt(s) inattendu(s), {1} BSOD, {2} minidump(s)' -f $crashes.Count, $bsod.Count, $dumps.Count
if ($dumps) { $dumps | Sort-Object LastWriteTime -Descending | Select-Object -First 5 | ForEach-Object { '  {0:yyyy-MM-dd}  {1}' -f $_.LastWriteTime, $_.Name } }
if ($crashes.Count -gt 5) { '⚠ Machine instable — demande une grosse remise ou passe ton chemin.' }
'@

$script:CmdBuyDefender = @'
try {
  $mp = Get-MpComputerStatus -ErrorAction Stop
  'Protection temps réel : {0}' -f $mp.RealTimeProtectionEnabled
  'Signatures antivirus  : {0:yyyy-MM-dd} (âge : {1} jour(s))' -f $mp.AntivirusSignatureLastUpdated, $mp.AntivirusSignatureAge
  if ($mp.AntivirusSignatureAge -gt 7) { '⚠ Signatures anciennes — le PC n''est pas mis à jour depuis longtemps.' }
  if (-not $mp.RealTimeProtectionEnabled) { '⚠ Protection désactivée — méfiance.' }
} catch { 'Statut Defender indisponible : ' + $_.Exception.Message }
'@

$script:CmdBuyInstallDate = @'
$os = Get-CimInstance Win32_OperatingSystem
$up = (Get-Date) - $os.LastBootUpTime
'Windows installé le : {0:yyyy-MM-dd}' -f $os.InstallDate
'Allumé depuis       : {0} j {1} h {2} min (si le vendeur dit « à peine utilisé »…)' -f $up.Days, $up.Hours, $up.Minutes
'Apps au démarrage   : {0}' -f @(Get-CimInstance Win32_StartupCommand).Count
'@

$script:CmdPreBuy = @'
$r = New-Object System.Collections.Generic.List[string]
$flags = New-Object System.Collections.Generic.List[string]
function Add-R([string]$line) { $r.Add($line) }
function Add-Flag([string]$line) { $flags.Add($line) }

$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$up = (Get-Date) - $os.LastBootUpTime

Add-R ('=' * 60)
Add-R '  TEST PRÉ-ACHAT PC — Windows Toolbox (∞ Infinity Coder)'
Add-R ('=' * 60)
Add-R ('Date : {0:yyyy-MM-dd HH:mm} — PC : {1}' -f (Get-Date), $env:COMPUTERNAME)
Add-R ('Modèle : {0} {1}' -f $cs.Manufacturer, $cs.Model)
Add-R ''

Add-R '[1] SPÉCIFICATIONS RÉELLES (compare avec l''annonce)'
Add-R ('  Windows     : {0} ({1})' -f $os.Caption, $os.OSArchitecture)
Add-R ('  Processeur  : {0}' -f $cpu.Name.Trim())
Add-R ('  RAM         : {0:N1} Go — {1} barrette(s)' -f ($cs.TotalPhysicalMemory/1GB), @(Get-CimInstance Win32_PhysicalMemory).Count)
Get-CimInstance Win32_VideoController | ForEach-Object { Add-R ('  Carte graph.: {0}' -f $_.Name) }
Get-PhysicalDisk | ForEach-Object { Add-R ('  Disque      : {0} — {1:N0} Go — {2}' -f $_.FriendlyName, ($_.Size/1GB), $_.MediaType) }
Add-R ''

Add-R '[2] SANTÉ DES DISQUES'
$badDisk = $false
Get-PhysicalDisk | ForEach-Object {
  Add-R ('  {0} : {1} ({2})' -f $_.FriendlyName, $_.HealthStatus, $_.MediaType)
  if ($_.HealthStatus -ne 'Healthy') { $badDisk = $true }
}
if ($badDisk) { Add-Flag 'DISQUE NON SAIN → déconseillé' }
$predict = Get-CimInstance -Namespace root\wmi -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue | Where-Object { $_.PredictFailure }
if ($predict) { Add-R '  ⚠ SMART signale une panne probable' ; Add-Flag 'SMART : panne prédite → déconseillé' }
else { Add-R '  SMART : aucune panne prédite' }
Add-R ''

Add-R '[3] PLANTAGES & ÉCRANS BLEUS (90 jours)'
$since = (Get-Date).AddDays(-90)
$crashes = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 41, 6008; StartTime = $since } -ErrorAction SilentlyContinue)
$bsod = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 1001; StartTime = $since } -ErrorAction SilentlyContinue)
$dumps = @(Get-ChildItem "$env:SystemRoot\Minidump" -ErrorAction SilentlyContinue)
Add-R ('  Arrêts inattendus : {0} — BSOD : {1} — minidumps : {2}' -f $crashes.Count, $bsod.Count, $dumps.Count)
if ($crashes.Count -gt 5 -or $bsod.Count -gt 3) { Add-Flag ('Instabilité : {0} arrêt(s) / {1} BSOD en 90 j' -f $crashes.Count, $bsod.Count) }
Add-R ''

Add-R '[4] ERREURS SYSTÈME (7 jours)'
$crit = @(Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 1, 2; StartTime = (Get-Date).AddDays(-7) } -ErrorAction SilentlyContinue)
Add-R ('  {0} erreur(s)/critique(s)' -f $crit.Count)
if ($crit.Count -gt 50) { Add-Flag ('{0} erreurs système en 7 j — à investiguer' -f $crit.Count) }
Add-R ''

Add-R '[5] WINDOWS & SÉCURITÉ'
Add-R ('  Installé le : {0:yyyy-MM-dd} — allumé depuis {1} j {2} h {3} min' -f $os.InstallDate, $up.Days, $up.Hours, $up.Minutes)
$act = (cscript //nologo "$env:SystemRoot\System32\slmgr.vbs" /xpr 2>&1) -join ' '
Add-R ('  Activation : {0}' -f ($act -replace '\s+', ' ').Trim())
if ($act -match 'not activated|non activé') { Add-Flag 'Windows non activé' }
try {
  $mp = Get-MpComputerStatus -ErrorAction Stop
  Add-R ('  Defender temps réel : {0} — signatures du {1:yyyy-MM-dd} ({2} j)' -f $mp.RealTimeProtectionEnabled, $mp.AntivirusSignatureLastUpdated, $mp.AntivirusSignatureAge)
  if (-not $mp.RealTimeProtectionEnabled) { Add-Flag 'Protection temps réel désactivée' }
} catch { Add-R '  Defender : statut indisponible' }
Add-R ''

Add-R '[6] BATTERIE (portable)'
$bat = Get-CimInstance Win32_Battery
if (-not $bat) { Add-R '  Fixe — pas de batterie.' }
else {
  $design = (Get-CimInstance -Namespace root\wmi -Class BatteryStaticData -ErrorAction SilentlyContinue).DesignedCapacity
  $full = (Get-CimInstance -Namespace root\wmi -Class BatteryFullChargedCapacity -ErrorAction SilentlyContinue).FullChargedCapacity
  Add-R ('  Charge : {0} %' -f $bat.EstimatedChargeRemaining)
  if ($design -and $full) {
    $wear = [math]::Round(100 - (100.0 * $full / $design), 1)
    Add-R ('  Usure batterie : {0} % (orig. {1} / actuelle {2} mWh)' -f $wear, $design, $full)
    if ($wear -gt 30) { Add-Flag ('Batterie usée à {0} %' -f $wear) }
  }
}
Add-R ''

Add-R '[7] PÉRIPHÉRIQUES EN ERREUR'
$bad = @(Get-PnpDevice -PresentOnly | Where-Object { $_.Status -ne 'OK' })
if ($bad.Count) {
  $bad | ForEach-Object { Add-R ('  ⚠ {0} — {1}' -f $_.Status, $_.FriendlyName) }
  Add-Flag ('{0} périphérique(s) en erreur' -f $bad.Count)
} else { Add-R '  Aucun ✓' }
Add-R ''

Add-R ('=' * 60)
if ($flags.Count -eq 0) {
  Add-R '  VERDICT : RIEN DE BLOQUANT côté logiciel ✓'
  Add-R '  Poursuis avec les tests manuels (écran, clavier, USB, son).'
} else {
  Add-R ('  VERDICT : {0} point(s) d''attention :' -f $flags.Count)
  $flags | ForEach-Object { Add-R ('   ⚠ ' + $_) }
  Add-R '  → Négocie le prix ou décline selon la gravité.'
}
Add-R ('=' * 60)

$name = 'verification-achat-PC-{0}-{1:yyyyMMdd-HHmm}.txt' -f $env:COMPUTERNAME, (Get-Date)
$out = $null
try {
  $out = Join-Path $sd $name
  [IO.File]::WriteAllText($out, ($r -join "`r`n"), (New-Object System.Text.UTF8Encoding $true))
} catch {
  try {
    $out = Join-Path (Join-Path $env:USERPROFILE 'Desktop') $name
    [IO.File]::WriteAllText($out, ($r -join "`r`n"), (New-Object System.Text.UTF8Encoding $true))
  } catch { $out = $null }
}
Add-R ''
if ($out) { Add-R ('Rapport enregistré : ' + $out) } else { Add-R 'Rapport non sauvegardé (dossier protégé) — copie le texte de la console.' }
$r
'@

# ---------------- Corrections du registre & BIOS (v2.1) ----------------

$script:CmdRegFixTaskMgr = @'
$d = Join-Path $env:USERPROFILE 'Documents\WindowsToolbox-RegBackup'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" (Join-Path $d "taskmgr-hkcu-$stamp.reg") /y 2>$null
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /f 2>$null
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableTaskMgr /f 2>$null
'Gestionnaire des taches reactive (sauvegarde dans Documents\WindowsToolbox-RegBackup).'
'@

$script:CmdRegFixCmd = @'
$d = Join-Path $env:USERPROFILE 'Documents\WindowsToolbox-RegBackup'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
reg export "HKCU\Software\Policies\Microsoft\Windows\System" (Join-Path $d "cmd-hkcu-$stamp.reg") /y 2>$null
reg delete "HKCU\Software\Policies\Microsoft\Windows\System" /v DisableCMD /f 2>$null
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v DisableCMD /f 2>$null
'Invite de commandes reactive.'
'@

$script:CmdRegFixRegedit = @'
$d = Join-Path $env:USERPROFILE 'Documents\WindowsToolbox-RegBackup'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" (Join-Path $d "regedit-hkcu-$stamp.reg") /y 2>$null
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /f 2>$null
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableRegistryTools /f 2>$null
'Editeur du registre reactive.'
'@

$script:CmdRegFixControl = @'
$d = Join-Path $env:USERPROFILE 'Documents\WindowsToolbox-RegBackup'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" (Join-Path $d "explorer-hkcu-$stamp.reg") /y 2>$null
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f 2>$null
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoControlPanel /f 2>$null
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoSettingsPageVisibility /f 2>$null
'Panneau de configuration et Paramètres réactivés.'
'@

$script:CmdRegFixExe = @'
$d = Join-Path $env:USERPROFILE 'Documents\WindowsToolbox-RegBackup'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
reg export "HKCR\.exe" (Join-Path $d "exe-$stamp.reg") /y 2>$null
reg export "HKCR\exefile\shell\open\command" (Join-Path $d "exefile-$stamp.reg") /y 2>$null
reg add "HKCR\.exe" /ve /d "exefile" /f
reg add "HKCR\exefile" /ve /d "Application" /f
reg add "HKCR\exefile\shell\open\command" /ve /d '"%1" %*' /f
'Association des fichiers .exe reparee.'
'@

$script:CmdRegFixLnk = @'
$d = Join-Path $env:USERPROFILE 'Documents\WindowsToolbox-RegBackup'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.lnk" (Join-Path $d "lnk-$stamp.reg") /y 2>$null
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.lnk\UserChoice" /f 2>$null
reg add "HKCR\.lnk" /ve /d "lnkfile" /f
'Associations de raccourcis .lnk reparees.'
'@

$script:CmdRegResetPolicies = @'
$d = Join-Path $env:USERPROFILE 'Documents\WindowsToolbox-RegBackup'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
reg export "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies" (Join-Path $d "policies-hkcu-$stamp.reg") /y 2>$null
reg export "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies" (Join-Path $d "policies-hklm-$stamp.reg") /y 2>$null
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies" /f 2>$null
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies" /f 2>$null
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Software Restriction Policies" /f 2>$null
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Safer\CodeIdentifiers" /f 2>$null
gpupdate /force 2>$null
'Toutes les strategies ont ete supprimees (restrictions malware, blocages CMD/exe/registre).'
'@

$script:CmdRegFixWU = @'
$d = Join-Path $env:USERPROFILE 'Documents\WindowsToolbox-RegBackup'
New-Item -ItemType Directory -Force -Path $d | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
reg export "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" (Join-Path $d "windowsupdate-$stamp.reg") /y 2>$null
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f 2>$null
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f 2>$null
sc.exe config wuauserv start= demand 2>$null
'Windows Update debloque (strategies de blocage supprimees, service reactif).'
'@

$script:CmdRegFixIcons = @'
ie4uinit.exe -show
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -Force -ErrorAction SilentlyContinue
if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
'Cache d''icones reconstruit (bureau et barre des taches relances).'
'@

$script:CmdBiosInfo = @'
'Mode firmware : ' + $env:firmware_type
try { 'Secure Boot  : ' + (Confirm-SecureBootUEFI) } catch { 'Secure Boot  : non lisible (mode Legacy, ou fonction non geree par ce PC)' }
try {
  $t = Get-Tpm
  'TPM          : present = ' + $t.TpmPresent + ', pret = ' + $t.TpmReady
} catch { 'TPM          : non lisible' }
'@

$script:CmdBiosReset = @'
Write-Host '=== REINITIALISATION DU BIOS/UEFI — GUIDE INTEGRE ===' -ForegroundColor Cyan
''
'Un vrai reset BIOS ne peut pas etre ecrit directement depuis Windows (protege par le'
'firmware) : notre outil te redemarre DANS le BIOS, ou tu appliques les valeurs d''usure :'
''
'  1. Le PC redemarre tout seul dans l''interface BIOS/UEFI (dans ~20 secondes).'
'  2. Cherche « Load Setup Defaults » / « Load Optimized Defaults » / « Reset to Default »'
'     (souvent touche F9, ou dans l''onglet Exit).'
'  3. Confirme, puis « Save & Exit » (souvent F10).'
'  4. Mot de passe BIOS : il se retire dans l''onglet Security SI tu le connais ;'
'     sinon c''est un reset materiel (jumper CLR_CMOS / pile) — impossible depuis Windows.'
''
'ANNULER le redemarrage : tape shutdown /a (Démarrer > taper shutdown /a) avant 20 s.'
''
shutdown /r /fw /t 20 /c "Redemarrage vers le BIOS/UEFI dans 20 s - shutdown /a pour annuler"
'Redemarrage programme dans 20 secondes…'
'@

# ---------------- Tests PC PORTABLE — écran, Hz, batterie (v2.2) ----------------

$script:CmdScreenHz = @'
'=== ÉCRAN ACTUEL ==='
Get-CimInstance Win32_VideoController | ForEach-Object {
  '{0} : {1} x {2} pixels @ {3} Hz' -f $_.Name, $_.CurrentHorizontalResolution, $_.CurrentVerticalResolution, $_.CurrentRefreshRate
}
''
'=== FRÉQUENCES SUPPORTÉES PAR L''ÉCRAN (modes du pilote) ==='
try {
  [WindowsToolbox.DisplayUtil]::ListModes() | ForEach-Object {
    $p = $_ -split '[x@]'
    [pscustomobject]@{ Res = ('{0} x {1}' -f $p[0], $p[1]); Hz = [int]$p[2] }
  } | Group-Object Res | Sort-Object { [int]($_.Name -split ' ')[0] } -Descending | ForEach-Object {
    '{0,-16} : {1} Hz' -f $_.Name, (($_.Group.Hz | Sort-Object -Unique) -join ', ')
  }
  ''
  '→ Vérifie que les Hz annoncés (60/120/144/240) apparaissent dans la liste.'
  '→ Pour changer : bouton « Changer les Hz » ou Paramètres > Système > Affichage > Affichage avancé.'
} catch { 'Énumération indisponible : ' + $_.Exception.Message }
'@

$script:CmdScreenModel = @'
$found = $false
Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID -ErrorAction SilentlyContinue | ForEach-Object {
  $name = (($_.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join '')
  $maker = (($_.ManufacturerName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join '')
  if ($name -or $maker) {
    $found = $true
    'Écran : {0} {1} — année {2}' -f $maker, $name, $_.YearOfManufacture
  }
}
if (-not $found) { 'Aucun écran exposé par WMI (fréquent pour la dalle interne d''un portable).' }
'@

$script:CmdBrightTest = @'
try {
  $m = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBrightnessMethods -ErrorAction Stop
  $cur = (Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBrightness -ErrorAction Stop).CurrentBrightness
  ('Luminosité actuelle : {0} %' -f $cur)
  'Test du rétro-éclairage : 30% → 70% → 100% → restauration (regarde l''écran)…'
  foreach ($v in 30, 70, 100) {
    $m.WmiSetBrightness(1, $v)
    Start-Sleep -Seconds 2
  }
  $m.WmiSetBrightness(1, $cur)
  ''
  ('Rétro-éclairage réactif ✓ — luminosité restaurée à {0} %.' -f $cur)
} catch {
  'Écran sans rétro-éclairage pilotable (écran externe / PC fixe) : ' + $_.Exception.Message
}
'@

$script:CmdBatteryDraw = @'
$bat = Get-CimInstance Win32_Battery
if (-not $bat) { 'Aucune batterie détectée (PC fixe).' }
else {
  'Mesure de la consommation pendant 30 s — DÉBRANCHE le chargeur maintenant !'
  $vals = @()
  1..6 | ForEach-Object {
    $st = Get-CimInstance -Namespace root\wmi -Class BatteryStatus -ErrorAction SilentlyContinue
    if ($st -and $st.DischargeRate -gt 0) { $vals += $st.DischargeRate }
    Start-Sleep -Seconds 5
  }
  if ($vals.Count) {
    $avg = ($vals | Measure-Object -Average).Average
    $min = ($vals | Measure-Object -Minimum).Minimum
    $max = ($vals | Measure-Object -Maximum).Maximum
    'Consommation : moyenne {0:N1} W (min {1:N1} W / max {2:N1} W)' -f ($avg/1000), ($min/1000), ($max/1000)
    '→ Au repos, une consommation stable (~5-15 W) = bonne santé. Des pics instables = à surveiller.'
  } else {
    'Aucune décharge mesurée — le chargeur est branché : débranche-le puis relance ce test.'
  }
}
'@

$script:CmdChargerPower = @'
$st = Get-CimInstance -Namespace root\wmi -Class BatteryStatus -ErrorAction SilentlyContinue
if (-not $st) { 'Batterie non exposée (PC fixe).' }
elseif ($st.PowerOnline) {
  if ($st.ChargingRate -gt 0) { 'Puissance de charge mesurée : {0:N1} W' -f ($st.ChargingRate/1000) }
  else { 'Sur secteur, batterie pas en charge (pleine ou quasi pleine) → chargeur OK.' }
} else { 'Pas branché sur secteur — branche le chargeur puis relance pour mesurer sa puissance.' }
'@

$script:CmdTouchpad = @'
'=== Souris / touchpad ==='
Get-PnpDevice -Class Mouse -PresentOnly -ErrorAction SilentlyContinue | Format-Table Status, FriendlyName -AutoSize
'=== Périphériques tactiles / touchpad (HID) ==='
Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'touch' } | Format-Table Status, FriendlyName -AutoSize
'→ Test manuel : déplacement du curseur, clic gauche/droit, tap, geste à 2 doigts.'
'@

# ---------------- God Mode & dossiers secrets (v2.3) ----------------

$script:GodList = @(
    @{ N = 'God Mode';                    G = '{ED7BA470-8E54-465E-825C-99712043E01C}' }
    @{ N = 'Outils d''administration';    G = '{D20EA4E1-3957-11d2-A40B-0C5020524152}' }
    @{ N = 'Options d''alimentation';     G = '{025A5937-A6BE-4686-A844-36FE4BEC8B6D}' }
    @{ N = 'Son';                         G = '{F2DDFC82-8F12-4CDD-B7DC-D4FE1425AA4D}' }
    @{ N = 'Centre Reseau et partage';    G = '{8E908FC9-BECC-40f6-915B-F4CA0E70D03D}' }
    @{ N = 'Systeme';                     G = '{BB06C0E4-D293-4f75-8A90-CB05528E4291}' }
    @{ N = 'Lecture automatique';         G = '{9C60DE1E-E5FC-40f4-A487-460851A8D915}' }
    @{ N = 'Programmes et fonctionnalites'; G = '{7B81BE6A-CE44-4676-8E77-EE30BCB0F60C}' }
    @{ N = 'Polices';                     G = '{D20EA4E1-3957-11d2-A40B-0C5020524153}' }
    @{ N = 'Zone de notification';        G = '{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}' }
)

$script:CmdGodCreate = @'
$g = Join-Path ([Environment]::GetFolderPath('Desktop')) 'God Mode.{ED7BA470-8E54-465E-825C-99712043E01C}'
New-Item -ItemType Directory -Path $g -Force | Out-Null
'Dossier « God Mode » cree sur le Bureau — ouvre-le : 250+ outils Windows au meme endroit.'
'@

$script:CmdGodRemove = @'
$g = Join-Path ([Environment]::GetFolderPath('Desktop')) 'God Mode.{ED7BA470-8E54-465E-825C-99712043E01C}'
if (Test-Path -LiteralPath $g) { Remove-Item -LiteralPath $g -Force; 'Dossier God Mode supprime du Bureau.' }
else { 'Aucun dossier God Mode sur le Bureau.' }
'@

$script:CmdGodAllCreate = @'
$desk = [Environment]::GetFolderPath('Desktop')
$items = @(
    @{ N = 'God Mode';                    G = '{ED7BA470-8E54-465E-825C-99712043E01C}' }
    @{ N = 'Outils administration';       G = '{D20EA4E1-3957-11d2-A40B-0C5020524152}' }
    @{ N = 'Options alimentation';        G = '{025A5937-A6BE-4686-A844-36FE4BEC8B6D}' }
    @{ N = 'Son';                         G = '{F2DDFC82-8F12-4CDD-B7DC-D4FE1425AA4D}' }
    @{ N = 'Centre Reseau et partage';    G = '{8E908FC9-BECC-40f6-915B-F4CA0E70D03D}' }
    @{ N = 'Systeme';                     G = '{BB06C0E4-D293-4f75-8A90-CB05528E4291}' }
    @{ N = 'Lecture automatique';         G = '{9C60DE1E-E5FC-40f4-A487-460851A8D915}' }
    @{ N = 'Programmes et fonctionnalites'; G = '{7B81BE6A-CE44-4676-8E77-EE30BCB0F60C}' }
    @{ N = 'Polices';                     G = '{D20EA4E1-3957-11d2-A40B-0C5020524153}' }
    @{ N = 'Zone de notification';        G = '{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}' }
)
foreach ($i in $items) {
    $p = Join-Path $desk ($i.N + '.' + $i.G)
    New-Item -ItemType Directory -Path $p -Force | Out-Null
    'Cree : ' + $i.N
}
'→ Regarde ton Bureau : chaque dossier cache une page de reglages Windows.'
'@

$script:CmdGodAllRemove = @'
$desk = [Environment]::GetFolderPath('Desktop')
$items = @(
    @{ N = 'God Mode';                    G = '{ED7BA470-8E54-465E-825C-99712043E01C}' }
    @{ N = 'Outils administration';       G = '{D20EA4E1-3957-11d2-A40B-0C5020524152}' }
    @{ N = 'Options alimentation';        G = '{025A5937-A6BE-4686-A844-36FE4BEC8B6D}' }
    @{ N = 'Son';                         G = '{F2DDFC82-8F12-4CDD-B7DC-D4FE1425AA4D}' }
    @{ N = 'Centre Reseau et partage';    G = '{8E908FC9-BECC-40f6-915B-F4CA0E70D03D}' }
    @{ N = 'Systeme';                     G = '{BB06C0E4-D293-4f75-8A90-CB05528E4291}' }
    @{ N = 'Lecture automatique';         G = '{9C60DE1E-E5FC-40f4-A487-460851A8D915}' }
    @{ N = 'Programmes et fonctionnalites'; G = '{7B81BE6A-CE44-4676-8E77-EE30BCB0F60C}' }
    @{ N = 'Polices';                     G = '{D20EA4E1-3957-11d2-A40B-0C5020524153}' }
    @{ N = 'Zone de notification';        G = '{05d7b0f4-2121-4eff-bf6b-ed3f69b894d9}' }
)
$n = 0
foreach ($i in $items) {
    $p = Join-Path $desk ($i.N + '.' + $i.G)
    if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force; $n++ }
}
"$n dossier(s) secrets supprimes du Bureau."
'@

function Show-ScreenTest {
    $script:PixelColors = @('White', 'Black', 'Red', 'Green', 'Blue', 'Yellow', 'Cyan', 'Magenta', 'Gray')
    $script:PixelIndex = 0
    $f = New-Object Windows.Forms.Form
    $script:PixelForm = $f
    $f.FormBorderStyle = 'None'
    $f.WindowState = 'Maximized'
    $f.TopMost = $true
    $f.KeyPreview = $true
    $f.BackColor = [Drawing.Color]::White
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = 'Clique ou Espace = couleur suivante — cherche les pixels morts/tâches — Échap pour fermer'
    $lbl.Dock = 'Bottom'
    $lbl.Height = 40
    $lbl.TextAlign = 'MiddleCenter'
    $lbl.ForeColor = [Drawing.Color]::FromArgb(120, 120, 120)
    $f.Controls.Add($lbl)
    $f.Add_Click({
        $script:PixelIndex = ($script:PixelIndex + 1) % $script:PixelColors.Count
        $script:PixelForm.BackColor = [Drawing.Color]::FromName($script:PixelColors[$script:PixelIndex])
    })
    $f.Add_KeyDown({
        param($s, $e)
        if ($_.KeyCode -eq 'Escape') { $script:PixelForm.Close() }
        elseif ($_.KeyCode -eq 'Space') {
            $script:PixelIndex = ($script:PixelIndex + 1) % $script:PixelColors.Count
            $script:PixelForm.BackColor = [Drawing.Color]::FromName($script:PixelColors[$script:PixelIndex])
        }
    })
    [void]$f.ShowDialog($script:Form)
    $f.Dispose()
}

function Show-KeyboardTest {
    $f = New-Object Windows.Forms.Form
    $script:KeyTestForm = $f
    $f.Text = 'Test clavier — tape TOUTES les touches, puis Échap pour fermer'
    $f.Size = New-Object Drawing.Size(860, 520)
    $f.StartPosition = 'CenterScreen'
    $f.TopMost = $true
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = "Appuie sur chaque touche (lettres, chiffres, accents, flèches, Entrée, Espace, Maj…). Ce qui s'affiche fonctionne."
    $lbl.Dock = 'Top'
    $lbl.Height = 36
    $lbl.Padding = New-Object Windows.Forms.Padding(8)
    $tb = New-Object Windows.Forms.RichTextBox
    $tb.Dock = 'Fill'
    $tb.Font = New-Object Drawing.Font('Consolas', 14)
    $f.Controls.Add($tb)
    $f.Controls.Add($lbl)
    $tb.Add_KeyDown({
        param($s, $e)
        if ($_.KeyCode -eq 'Escape') { $script:KeyTestForm.Close() }
    })
    [void]$f.ShowDialog($script:Form)
    $tb.Dispose()
    $f.Dispose()
}

function Show-Toolbox {
    $form = New-Object WindowsToolbox.HotkeyForm
    $form.Text          = "Windows 11 Toolbox v$script:ToolboxVersion — Commandes · SSD · Diagnostics"
    $form.Size          = New-Object Drawing.Size(1016, 800)
    $form.MinimumSize   = New-Object Drawing.Size(920, 640)
    $form.StartPosition = 'CenterScreen'
    $form.Font          = New-Object Drawing.Font('Segoe UI', 9.75)
    $form.Icon          = [System.Drawing.SystemIcons]::Shield
    $form.BackColor     = [Drawing.Color]::FromArgb(243, 244, 246)
    $script:Form = $form

    $script:Tooltip = New-Object Windows.Forms.ToolTip
    $script:Tooltip.AutoPopDelay = 8000

    # ---------- Zone haute : titre + badge admin ----------
    $top = New-Object Windows.Forms.Panel
    $top.Dock = 'Top'; $top.Height = 64; $top.BackColor = [Drawing.Color]::White

    $title = New-Object Windows.Forms.Label
    $title.Text     = 'Windows 11 Toolbox'
    $title.AutoSize = $true
    $title.Font     = New-Object Drawing.Font('Segoe UI', 14, [Drawing.FontStyle]::Bold)
    $title.Location = New-Object Drawing.Point(16, 6)
    $top.Controls.Add($title)

    $subtitle = New-Object Windows.Forms.Label
    $subtitle.Text     = 'Commandes Windows · Tests SSD · Diagnostics — ∞ Infinity Coder (Derouiche Oussama)'
    $subtitle.AutoSize = $true
    $subtitle.ForeColor = [Drawing.Color]::Gray
    $subtitle.Location = New-Object Drawing.Point(19, 36)
    $top.Controls.Add($subtitle)

    $btnHide = New-Object Windows.Forms.Button
    $btnHide.Text = 'Masquer'
    $btnHide.Size = New-Object Drawing.Size(110, 32)
    $btnHide.Location = New-Object Drawing.Point(505, 16)
    $btnHide.Anchor = 'Top,Right'
    $btnHide.FlatStyle = 'Flat'
    $btnHide.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(209, 213, 219)
    $btnHide.BackColor = [Drawing.Color]::White
    $btnHide.ForeColor = [Drawing.Color]::FromArgb(60, 60, 70)
    $btnHide.Add_Click({ Hide-Toolbox })
    $script:Tooltip.SetToolTip($btnHide, 'Réduit dans la zone de notification (Ctrl+Alt+T ou Ctrl+H pour rappeler)')
    $top.Controls.Add($btnHide)

    $btnDon = New-Object Windows.Forms.Button
    $btnDon.Text = '♥ Faire un don'
    $btnDon.Size = New-Object Drawing.Size(140, 32)
    $btnDon.Location = New-Object Drawing.Point(630, 16)
    $btnDon.Anchor = 'Top,Right'
    $btnDon.FlatStyle = 'Flat'
    $btnDon.FlatAppearance.BorderSize = 0
    $btnDon.BackColor = [Drawing.Color]::FromArgb(124, 58, 237)
    $btnDon.ForeColor = [Drawing.Color]::White
    $btnDon.Font = New-Object Drawing.Font('Segoe UI', 9.5, [Drawing.FontStyle]::Bold)
    $btnDon.Add_Click({ try { Start-Process $script:DonationUrl } catch { } })
    $top.Controls.Add($btnDon)

    if (Test-IsAdmin) {
        $badge = New-Object Windows.Forms.Label
        $badge.Text     = '✅ Administrateur'
        $badge.AutoSize = $true
        $badge.ForeColor = [Drawing.Color]::FromArgb(21, 128, 61)
        $badge.Font     = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
        $badge.Location = New-Object Drawing.Point(780, 20)
        $badge.Anchor   = 'Top,Right'
        $top.Controls.Add($badge)
    } else {
        $btnAdmin = New-Object Windows.Forms.Button
        $btnAdmin.Text     = '⚡ Relancer en admin'
        $btnAdmin.AutoSize = $true
        $btnAdmin.FlatStyle = 'Flat'
        $btnAdmin.BackColor = [Drawing.Color]::FromArgb(37, 99, 235)
        $btnAdmin.ForeColor = [Drawing.Color]::White
        $btnAdmin.Location = New-Object Drawing.Point(790, 16)
        $btnAdmin.Anchor   = 'Top,Right'
        $btnAdmin.Add_Click({
            try {
                Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"", '-Admin')
                $script:Form.Close()
            } catch { Append-Console ('[ERREUR] Élévation refusée : ' + $_.Exception.Message) }
        })
        $top.Controls.Add($btnAdmin)
    }

    # ---------- Console / rapport (bas) ----------
    $consolePanel = New-Object Windows.Forms.Panel
    $consolePanel.Dock = 'Bottom'; $consolePanel.Height = 260; $consolePanel.BackColor = [Drawing.Color]::White

    $consoleBar = New-Object Windows.Forms.Panel
    $consoleBar.Dock = 'Top'; $consoleBar.Height = 34; $consoleBar.BackColor = [Drawing.Color]::FromArgb(249, 250, 251)

    $clabel = New-Object Windows.Forms.Label
    $clabel.Text = '  Console / rapport des commandes'
    $clabel.AutoSize = $true
    $clabel.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
    $clabel.Location = New-Object Drawing.Point(2, 8)
    $consoleBar.Controls.Add($clabel)

    $btnClear = New-Object Windows.Forms.Button
    $btnClear.Text = 'Effacer'; $btnClear.AutoSize = $true
    $btnClear.Location = New-Object Drawing.Point(700, 4); $btnClear.Anchor = 'Top,Right'
    $btnClear.Add_Click({ $script:ConsoleBox.Clear() })
    $consoleBar.Controls.Add($btnClear)

    $btnCopy = New-Object Windows.Forms.Button
    $btnCopy.Text = 'Copier'; $btnCopy.AutoSize = $true
    $btnCopy.Location = New-Object Drawing.Point(775, 4); $btnCopy.Anchor = 'Top,Right'
    $btnCopy.Add_Click({
        if ($script:ConsoleBox.Text) {
            try { [Windows.Forms.Clipboard]::SetText($script:ConsoleBox.Text); Set-Status '📋 Console copiée dans le presse-papiers.' } catch { }
        }
    })
    $consoleBar.Controls.Add($btnCopy)

    $btnSave = New-Object Windows.Forms.Button
    $btnSave.Text = 'Enregistrer rapport'; $btnSave.AutoSize = $true
    $btnSave.Location = New-Object Drawing.Point(850, 4); $btnSave.Anchor = 'Top,Right'
    $btnSave.Add_Click({
        $dlg = New-Object Windows.Forms.SaveFileDialog
        $dlg.Filter = 'Rapport texte (*.txt)|*.txt'
        $dlg.FileName = 'toolbox-rapport-{0:yyyyMMdd-HHmm}.txt' -f (Get-Date)
        $dlg.InitialDirectory = [Environment]::GetFolderPath('MyDocuments')
        if ($dlg.ShowDialog($script:Form) -eq [Windows.Forms.DialogResult]::OK) {
            [IO.File]::WriteAllText($dlg.FileName, $script:ConsoleBox.Text, (New-Object System.Text.UTF8Encoding $true))
            Append-Console ('Rapport enregistré : ' + $dlg.FileName)
        }
    })
    $consoleBar.Controls.Add($btnSave)

    $console = New-Object Windows.Forms.RichTextBox
    $console.Dock = 'Fill'
    $console.ReadOnly = $true
    $console.BackColor = [Drawing.Color]::FromArgb(30, 30, 40)
    $console.ForeColor = [Drawing.Color]::FromArgb(220, 223, 228)
    $console.Font = New-Object Drawing.Font('Consolas', 9.5)
    $console.ScrollBars = 'Vertical'
    $console.WordWrap = $false
    $console.Text = "Windows 11 Toolbox v$script:ToolboxVersion — console prête.`r`nAstuce : les boutons orange « (admin) » demandent la confirmation UAC et s'ouvrent dans une console séparée.`r`nCe logiciel est gratuit — si tu l'aimes, le bouton « Faire un don » (en haut ou dans À propos) soutient le développement.`r`n"
    Test-ToolboxIntegrity

    $consolePanel.Controls.Add($console)
    $consolePanel.Controls.Add($consoleBar)
    $script:ConsoleBox = $console

    # ---------- Barre de statut ----------
    $statusStrip = New-Object Windows.Forms.StatusStrip
    $statusLabel = New-Object Windows.Forms.ToolStripStatusLabel
    $statusLabel.Text = $(if (Test-IsAdmin) { "Prêt — $env:COMPUTERNAME · Administrateur" } else { "Prêt — $env:COMPUTERNAME · Utilisateur (certains outils demandent admin)" })
    [void]$statusStrip.Items.Add($statusLabel)
    $script:StatusLabel = $statusLabel

    # ---------- Onglets ----------
    $tabs = New-Object Windows.Forms.TabControl
    $tabs.Dock = 'Fill'
    foreach ($spec in @(@('Système', '🖥'), @('Disques & SSD', '💾'), @('Réseau', '🌐'), @('Windows', '🛠'), @('Rares', '⚡'), @('Nettoyage', '🧹'), @('Achat PC', '🛒'), @('Raccourcis', '🚀'), @('Tiers', '🧰'), @('À propos', 'ℹ'))) {
        $page = New-Object Windows.Forms.TabPage
        $page.Text = ("{0} {1}" -f $spec[1], $spec[0])
        $page.UseVisualStyleBackColor = $true
        $flow = New-Object Windows.Forms.FlowLayoutPanel
        $flow.Dock = 'Fill'
        $flow.AutoScroll = $true
        $flow.Padding = New-Object Windows.Forms.Padding(12)
        $page.Controls.Add($flow)
        [void]$tabs.TabPages.Add($page)
    }
    $tabSystem = $tabs.TabPages[0].Controls[0]
    $tabDisks  = $tabs.TabPages[1].Controls[0]
    $tabNet    = $tabs.TabPages[2].Controls[0]
    $tabWin    = $tabs.TabPages[3].Controls[0]
    $tabRare   = $tabs.TabPages[4].Controls[0]
    $tabClean  = $tabs.TabPages[5].Controls[0]
    $tabBuy    = $tabs.TabPages[6].Controls[0]
    $tabQuick  = $tabs.TabPages[7].Controls[0]
    $tabTools  = $tabs.TabPages[8].Controls[0]
    $tabAbout  = $tabs.TabPages[9]

    function Add-Section {
        param($Parent, [string]$Text)
        $l = New-Object Windows.Forms.Label
        $l.Text = $Text.ToUpper()
        $l.AutoSize = $false
        $l.Size = New-Object Drawing.Size(940, 24)
        $l.TextAlign = 'MiddleLeft'
        $l.UseMnemonic = $false
        $l.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
        $l.ForeColor = [Drawing.Color]::FromArgb(37, 99, 235)
        $l.Margin = New-Object Windows.Forms.Padding(4, 14, 4, 4)
        $Parent.Controls.Add($l)
    }

    function Add-CmdButton {
        param($Parent, [string]$Text, [string]$Kind = 'Inline', [string]$Script = '', [string]$Target = '', [string]$TargetArgs = '', [string]$Desc = '')
        $b = New-Object Windows.Forms.Button
        $b.Text = $Text
        $b.Size = New-Object Drawing.Size(460, 42)
        $b.UseMnemonic = $false
        $b.Margin = New-Object Windows.Forms.Padding(6)
        $b.TextAlign = 'MiddleLeft'
        $b.Padding = New-Object Windows.Forms.Padding(10, 0, 0, 0)
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderSize = 1
        switch ($Kind) {
            'Elevated' {
                $b.ForeColor = [Drawing.Color]::FromArgb(180, 83, 9); $b.BackColor = [Drawing.Color]::FromArgb(255, 247, 237)
                $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(251, 191, 36)
            }
            { $_ -in @('Gui', 'ScreenTest', 'KeyboardTest', 'HideApp') } {
                $b.ForeColor = [Drawing.Color]::FromArgb(31, 41, 55); $b.BackColor = [Drawing.Color]::White
                $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(209, 213, 219)
            }
            'GuiElevated' {
                $b.ForeColor = [Drawing.Color]::FromArgb(180, 83, 9); $b.BackColor = [Drawing.Color]::FromArgb(255, 251, 235)
                $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(253, 186, 116)
            }
            'Url' {
                $b.ForeColor = [Drawing.Color]::FromArgb(37, 99, 235); $b.BackColor = [Drawing.Color]::FromArgb(239, 246, 255)
                $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(147, 197, 253)
            }
            default {
                $b.ForeColor = [Drawing.Color]::FromArgb(30, 58, 138); $b.BackColor = [Drawing.Color]::White
                $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(147, 197, 253)
            }
        }
        if ($Desc) { $script:Tooltip.SetToolTip($b, $Desc) }
        $b.Add_Click({
            switch ($Kind) {
                'Inline'      { if ($Script) { Start-InlineCommand -Title $Text -Script $Script } }
                'Elevated'    { if ($Script) { Start-ElevatedCommand -Title $Text -Script $Script } }
                'Gui'         { Start-GuiTarget -Target $Target -TargetArgs $TargetArgs }
                'GuiElevated' { Start-GuiTarget -Target $Target -Elevated }
                'ScreenTest'  { Show-ScreenTest }
                'KeyboardTest' { Show-KeyboardTest }
                'HideApp'     { Hide-Toolbox }
                'Url'         { try { Start-Process $Target } catch { Append-Console ('[ERREUR] ' + $_.Exception.Message) } }
            }
        }.GetNewClosure())
        $Parent.Controls.Add($b)
    }

    # ================= Onglet Système =================
    Add-Section $tabSystem 'Informations'
    Add-CmdButton $tabSystem 'Résumé du PC (OS, CPU, RAM, uptime)' -Script $script:CmdSummary -Desc 'Inventaire matériel et logiciel rapide'
    Add-CmdButton $tabSystem 'Informations système (msinfo32)' -Kind 'Gui' -Target 'msinfo32.exe'
    Add-CmdButton $tabSystem 'Diagnostic DirectX (dxdiag)' -Kind 'Gui' -Target 'dxdiag.exe'
    Add-CmdButton $tabSystem 'Licence & activation Windows (slmgr /xpr)' -Script $script:CmdLicense

    Add-Section $tabSystem 'Réparation & intégrité (admin)'
    Add-CmdButton $tabSystem 'SFC — vérifier les fichiers système (sfc /scannow)' -Kind 'Elevated' -Script 'sfc /scannow' -Desc 'Répare les fichiers système corrompus (~10 min)'
    Add-CmdButton $tabSystem 'DISM — CheckHealth (rapide)' -Kind 'Elevated' -Script 'Dism.exe /Online /Cleanup-Image /CheckHealth'
    Add-CmdButton $tabSystem 'DISM — ScanHealth (analyse complète)' -Kind 'Elevated' -Script 'Dism.exe /Online /Cleanup-Image /ScanHealth' -Desc 'Peut prendre 10-20 minutes'
    Add-CmdButton $tabSystem 'DISM — RestoreHealth (répare depuis Windows Update)' -Kind 'Elevated' -Script 'Dism.exe /Online /Cleanup-Image /RestoreHealth' -Desc 'Répare le magasin de composants (15-30 min)'
    Add-CmdButton $tabSystem 'Nettoyage des composants WinSxS (StartComponentCleanup)' -Kind 'Elevated' -Script 'Dism.exe /Online /Cleanup-Image /StartComponentCleanup'

    Add-Section $tabSystem 'Moniteurs & diagnostic'
    Add-CmdButton $tabSystem 'Gestionnaire des tâches' -Kind 'Gui' -Target 'taskmgr.exe'
    Add-CmdButton $tabSystem 'Moniteur de ressources' -Kind 'Gui' -Target 'resmon.exe'
    Add-CmdButton $tabSystem 'Analyseur de performances' -Kind 'Gui' -Target 'perfmon.exe'
    Add-CmdButton $tabSystem 'Observateur d''événements (erreurs système)' -Kind 'Gui' -Target 'eventvwr.exe'
    Add-CmdButton $tabSystem 'Gestion de l''ordinateur' -Kind 'Gui' -Target 'compmgmt.msc'

    Add-Section $tabSystem 'Maintenance'
    Add-CmdButton $tabSystem 'Nettoyage de disque (choix du lecteur)' -Kind 'Gui' -Target 'cleanmgr.exe'
    Add-CmdButton $tabSystem 'Batterie : état instantané & usure (%)' -Script $script:CmdRareBattery -Desc 'Charge, autonomie, capacité d''origine vs actuelle, cycles'
    Add-CmdButton $tabSystem 'Rapport batterie (portable) — ouvre le HTML' -Script $script:CmdBattery
    Add-CmdButton $tabSystem 'Resynchroniser l''horloge (w32tm /resync)' -Kind 'Elevated' -Script $script:CmdW32Time
    Add-CmdButton $tabSystem 'Windows Update (Paramètres)' -Kind 'Gui' -Target 'ms-settings:windowsupdate'
    Add-CmdButton $tabSystem 'Sécurité Windows (Defender)' -Kind 'Gui' -Target 'windowsdefender:'

    # ================= Onglet Disques & SSD =================
    Add-Section $tabDisks 'Santé & SMART'
    Add-CmdButton $tabDisks 'Santé des disques (Get-PhysicalDisk)' -Script $script:CmdDiskHealth -Desc 'Statut Healthy / Warning / Unhealthy'
    Add-CmdButton $tabDisks 'État SMART (prédiction de panne)' -Script $script:CmdDiskSmart
    Add-CmdButton $tabDisks 'Détails disques (modèle, firmware, série)' -Script $script:CmdDiskDetail
    Add-CmdButton $tabDisks 'Volumes & espace libre' -Script $script:CmdVolumes
    if ($script:SmartCtl) {
        Add-CmdButton $tabDisks 'SMART complet via smartctl (tous disques) (admin)' -Kind 'Elevated' -Script 'if ($sc) { & $sc --scan-open -a } else { ''smartctl introuvable'' }' -Desc ("smartctl détecté : " + $script:SmartCtl)
    }

    Add-Section $tabDisks 'Tests & optimisation (admin)'
    Add-CmdButton $tabDisks 'Optimiser tous les disques (TRIM SSD / défrag)' -Kind 'Elevated' -Script 'Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq "Fixed" } | ForEach-Object { Write-Host ("=== Lecteur " + $_.DriveLetter + ": ==="); Optimize-Volume -DriveLetter $_.DriveLetter -Verbose }' -Desc 'Envoie TRIM aux SSD, défragmente les HDD'
    Add-CmdButton $tabDisks 'chkdsk C: — analyse en lecture seule (/scan)' -Kind 'Elevated' -Script 'chkdsk C: /scan' -Desc 'Vérifie le système de fichiers sans redémarrage'
    Add-CmdButton $tabDisks 'Benchmark disque C: (winsat disk, ~1 min)' -Kind 'Elevated' -Script 'winsat disk -drive c' -Desc 'Mesure débit séquentiel et aléatoire'
    Add-CmdButton $tabDisks 'SMART détaillé (température, heures, usage) (admin)' -Kind 'Elevated' -Script 'if ($sc) { & $sc --scan-open -a } else { Get-PhysicalDisk | ForEach-Object { $d = $_; $c = $d | Get-StorageReliabilityCounter; [pscustomobject]@{ Disque = $d.FriendlyName; TempC = $c.Temperature; Heures = $c.PowerOnHours; ErreursLecture = $c.ReadErrorsTotal; Wear = $c.Wear } } | Format-Table -AutoSize }' -Desc 'Compteurs de fiabilité ou smartctl si installé'

    Add-Section $tabDisks 'Outils disque'
    Add-CmdButton $tabDisks 'Défragmenteur & optimisation des lecteurs' -Kind 'Gui' -Target 'dfrgui.exe'
    Add-CmdButton $tabDisks 'Gestion des disques' -Kind 'Gui' -Target 'diskmgmt.msc'
    Add-CmdButton $tabDisks 'Diagnostic mémoire Windows (redémarre le PC) (admin)' -Kind 'GuiElevated' -Target 'mdsched.exe' -Desc 'Test RAM au prochain redémarrage'

    # ================= Onglet Réseau =================
    Add-Section $tabNet 'Diagnostic'
    Add-CmdButton $tabNet 'Configuration IP complète (ipconfig /all)' -Script $script:CmdIpconfig
    Add-CmdButton $tabNet 'Adaptateurs réseau (Get-NetAdapter)' -Script $script:CmdNetAdapter
    Add-CmdButton $tabNet 'Ping Internet (8.8.8.8)' -Script $script:CmdPingInet
    Add-CmdButton $tabNet 'Ping passerelle (box / routeur)' -Script $script:CmdPingGw
    Add-CmdButton $tabNet 'Test DNS (nslookup google.com)' -Script $script:CmdNsLookup
    Add-CmdButton $tabNet 'Route vers 1.1.1.1 (tracert)' -Script $script:CmdTracert
    Add-CmdButton $tabNet 'Ports en écoute (processus inclus)' -Script $script:CmdPorts
    Add-CmdButton $tabNet 'Test de vitesse (fast.com)' -Kind 'Url' -Target 'https://fast.com'

    Add-Section $tabNet 'Réparation (admin)'
    Add-CmdButton $tabNet 'Vider le cache DNS' -Kind 'Elevated' -Script 'ipconfig /flushdns; Clear-DnsClientCache; ''Cache DNS vidé.'''
    Add-CmdButton $tabNet 'Reset Winsock + pile TCP/IP (redémarrage conseillé)' -Kind 'Elevated' -Script 'netsh winsock reset; netsh int ip reset; ipconfig /flushdns; ''Reset terminé — redémarre le PC.'''

    Add-Section $tabNet 'Accès rapide'
    Add-CmdButton $tabNet 'Connexions réseau (ncpa.cpl)' -Kind 'Gui' -Target 'ncpa.cpl'
    Add-CmdButton $tabNet 'Pare-feu Windows (wf.msc)' -Kind 'Gui' -Target 'wf.msc'
    Add-CmdButton $tabNet 'Paramètres réseau (Windows 11)' -Kind 'Gui' -Target 'ms-settings:network'

    # ================= Onglet Outils Windows =================
    Add-Section $tabWin 'Configuration'
    Add-CmdButton $tabWin 'Paramètres Windows' -Kind 'Gui' -Target 'ms-settings:'
    Add-CmdButton $tabWin 'Panneau de configuration' -Kind 'Gui' -Target 'control.exe'
    Add-CmdButton $tabWin 'Éditeur du registre (admin)' -Kind 'GuiElevated' -Target 'regedit.exe'
    Add-CmdButton $tabWin 'Stratégie de groupe (admin, éditions Pro)' -Kind 'GuiElevated' -Target 'gpedit.msc'
    Add-CmdButton $tabWin 'Configuration système — démarrage (msconfig)' -Kind 'Gui' -Target 'msconfig.exe'
    Add-CmdButton $tabWin 'Services' -Kind 'Gui' -Target 'services.msc'
    Add-CmdButton $tabWin 'Gestionnaire de périphériques' -Kind 'Gui' -Target 'devmgmt.msc'
    Add-CmdButton $tabWin 'Programmes & fonctionnalités' -Kind 'Gui' -Target 'appwiz.cpl'
    Add-CmdButton $tabWin 'Propriétés système' -Kind 'Gui' -Target 'sysdm.cpl'
    Add-CmdButton $tabWin 'Variables d''environnement' -Kind 'Gui' -Target 'rundll32.exe' -TargetArgs 'sysdm.cpl,EditEnvironmentVariables'
    Add-CmdButton $tabWin 'Restauration du système' -Kind 'Gui' -Target 'rstrui.exe'
    Add-CmdButton $tabWin 'Applications au démarrage' -Kind 'Gui' -Target 'ms-settings:startupapps'
    Add-CmdButton $tabWin 'Stockage / Assistant de nettoyage' -Kind 'Gui' -Target 'ms-settings:storagesense'

    Add-Section $tabWin 'Corrections du registre (sauvegarde automatique avant chaque correction)'
    Add-CmdButton $tabWin 'Point de restauration avant corrections (admin)' -Kind 'Elevated' -Script $script:CmdRestorePoint -Desc 'Filet de sécurité supplémentaire (limite : 1 par 24 h)'
    Add-CmdButton $tabWin 'Réactiver le Gestionnaire des tâches (admin)' -Kind 'Elevated' -Script $script:CmdRegFixTaskMgr -Desc 'Fixe « Le Gestionnaire des tâches a été désactivé par votre administrateur »'
    Add-CmdButton $tabWin 'Réactiver l''invite de commandes CMD (admin)' -Kind 'Elevated' -Script $script:CmdRegFixCmd -Desc 'Fixe « L''invite de commandes a été désactivée »'
    Add-CmdButton $tabWin 'Réactiver l''Éditeur du registre (admin)' -Kind 'Elevated' -Script $script:CmdRegFixRegedit -Desc 'Fixe « La modification du registre a été désactivée »'
    Add-CmdButton $tabWin 'Réactiver le Panneau de configuration & Paramètres (admin)' -Kind 'Elevated' -Script $script:CmdRegFixControl
    Add-CmdButton $tabWin 'Réparer l''ouverture des fichiers .exe (admin)' -Kind 'Elevated' -Script $script:CmdRegFixExe -Desc 'Quand « Windows ne peut pas ouvrir ce fichier » pour tous les programmes'
    Add-CmdButton $tabWin 'Réparer les raccourcis .lnk qui ne s''ouvrent plus (admin)' -Kind 'Elevated' -Script $script:CmdRegFixLnk
    Add-CmdButton $tabWin 'Réinitialiser TOUTES les stratégies (restrictions malware) (admin)' -Kind 'Elevated' -Script $script:CmdRegResetPolicies -Desc 'Supprime les blocages imposés par des malwares — retire aussi les stratégies d''entreprise'
    Add-CmdButton $tabWin 'Débloquer Windows Update (admin)' -Kind 'Elevated' -Script $script:CmdRegFixWU -Desc 'Supprime les stratégies qui désactivent les mises à jour'
    Add-CmdButton $tabWin 'Réparer le cache des icônes du bureau' -Script $script:CmdRegFixIcons -Desc 'Icônes blanches ou corrompues — relance l''Explorateur'

    Add-Section $tabWin 'BIOS / UEFI'
    Add-CmdButton $tabWin 'UEFI ou Legacy ? Secure Boot ? TPM ? (admin)' -Kind 'Elevated' -Script $script:CmdBiosInfo
    Add-CmdButton $tabWin 'Redémarrer directement dans le BIOS/UEFI (admin)' -Kind 'GuiElevated' -Target 'shutdown.exe' -TargetArgs '/r /fw /t 0' -Desc 'Sauvegarde tes documents — nécessite un PC démarré en mode UEFI'
    Add-CmdButton $tabWin 'Réinitialiser les réglages BIOS/UEFI — guide + redémarrage (admin)' -Kind 'Elevated' -Script $script:CmdBiosReset -Desc 'Te démarre dans le BIOS et t''affiche le pas-à-pas pour remettre les valeurs d''usine (F9/F10)'
    Add-CmdButton $tabWin 'Effacer la puce TPM — DÉFINITIF (admin)' -Kind 'Elevated' -Script 'Clear-Tpm' -Desc 'Réinitialise la puce de sécurité — attention si BitLocker sans clé sauvegardée !'

    Add-Section $tabWin 'Mises à jour logicielles (winget)'
    Add-CmdButton $tabWin 'Lister les mises à jour disponibles (winget upgrade)' -Script $script:CmdWinget
    Add-CmdButton $tabWin 'Tout mettre à jour (winget upgrade --all) (admin)' -Kind 'Elevated' -Script 'winget upgrade --all --accept-source-agreements --accept-package-agreements --disable-interactivity'

    Add-Section $tabWin 'Terminaux'
    Add-CmdButton $tabWin 'Invite de commandes (cmd)' -Kind 'Gui' -Target 'cmd.exe'
    Add-CmdButton $tabWin 'PowerShell' -Kind 'Gui' -Target 'powershell.exe'
    Add-CmdButton $tabWin 'Terminal Windows (admin)' -Kind 'GuiElevated' -Target 'wt.exe'

    # ================= Onglet Commandes rares =================
    Add-Section $tabRare 'Batterie & énergie'
    Add-CmdButton $tabRare 'Batterie : état instantané, usure & cycles' -Script $script:CmdRareBattery -Desc 'Charge, autonomie, capacité d''origine vs actuelle (% d''usure), consommation en cours'
    Add-CmdButton $tabRare 'Rapport batterie complet HTML (powercfg /batteryreport)' -Script $script:CmdBattery -Desc 'Historique des charges et de la capacité'
    Add-CmdButton $tabRare 'Diagnostic énergie 60 s (powercfg /energy) (admin)' -Kind 'Elevated' -Script $script:CmdRareEnergy -Desc 'Détecte ce qui empêche l''économie d''énergie et la mise en veille'
    Add-CmdButton $tabRare 'Rapport veille moderne (powercfg /sleepstudy) (admin)' -Kind 'Elevated' -Script $script:CmdRareSleep -Desc 'Consommation pendant la veille (Modern Standby)'
    Add-CmdButton $tabRare 'Qu''est-ce qui a réveillé le PC ? (powercfg /lastwake)' -Script 'powercfg /lastwake'
    Add-CmdButton $tabRare 'Qu''est-ce qui empêche la veille ? (powercfg /requests) (admin)' -Kind 'Elevated' -Script 'powercfg /requests'
    Add-CmdButton $tabRare 'Minuteurs de réveil actifs (powercfg /waketimers) (admin)' -Kind 'Elevated' -Script 'powercfg /waketimers'
    Add-CmdButton $tabRare 'Périphériques autorisés à réveiller le PC (admin)' -Kind 'Elevated' -Script 'powercfg /devicequery wake_armed'
    Add-CmdButton $tabRare 'États de veille disponibles (powercfg /a)' -Script 'powercfg /a'
    Add-CmdButton $tabRare 'Schémas d''alimentation (powercfg /list)' -Script 'powercfg /list'

    Add-Section $tabRare 'Système — infos rares'
    Add-CmdButton $tabRare 'À propos de Windows (winver)' -Kind 'Gui' -Target 'winver.exe'
    Add-CmdButton $tabRare 'systeminfo complet (hotfixes, réseau, hyper-V…)' -Script 'systeminfo' -Desc 'Peut prendre 10-20 secondes'
    Add-CmdButton $tabRare 'whoami /all (SID, privilèges, groupes)' -Script 'whoami /all'
    Add-CmdButton $tabRare 'RAM : barrettes, slots, vitesse, référence' -Script $script:CmdRareRam -Desc 'Nombre de slots occupés, MT/s, numéro de série des barrettes'
    Add-CmdButton $tabRare 'Top 15 processus CPU & RAM' -Script $script:CmdRareTopProc
    Add-CmdButton $tabRare 'Programmes installés (registre)' -Script $script:CmdRareInstalled
    Add-CmdButton $tabRare 'Mises à jour Windows installées (Get-HotFix)' -Script 'Get-HotFix | Sort-Object InstalledOn -Descending | Format-Table HotFixID, Description, InstalledOn -AutoSize'
    Add-CmdButton $tabRare 'Clé produit BIOS + détails licence (slmgr /dli)' -Script $script:CmdRareLicense
    Add-CmdButton $tabRare 'Périphériques en erreur (Get-PnpDevice)' -Script $script:CmdRarePnp
    Add-CmdButton $tabRare 'Vérifier le dépôt WMI (winmgmt /verifyrepository)' -Script 'winmgmt /verifyrepository' -Desc 'À lancer si un logiciel dit « WMI indisponible »'
    Add-CmdButton $tabRare 'Réparer le dépôt WMI (winmgmt /resetrepository) (admin)' -Kind 'Elevated' -Script 'winmgmt /resetrepository' -Desc 'Réinitialise le dépôt WMI — seulement si la vérification échoue'

    Add-Section $tabRare 'Disques — commandes rares'
    Add-CmdButton $tabRare 'TRIM activé ? (fsutil DisableDeleteNotify) (admin)' -Kind 'Elevated' -Script 'fsutil behavior query DisableDeleteNotify' -Desc '0 = TRIM activé (bien pour le SSD) ; 1 = TRIM désactivé'
    Add-CmdButton $tabRare 'Bit « disque sale » (chkntfs + fsutil dirty) (admin)' -Kind 'Elevated' -Script 'chkntfs C:; fsutil dirty query C:' -Desc 'dirty = 0 → disque propre ; 1 → chkdsk /f conseillé'
    Add-CmdButton $tabRare 'Analyse du magasin WinSxS (AnalyzeComponentStore) (admin)' -Kind 'Elevated' -Script 'Dism.exe /Online /Cleanup-Image /AnalyzeComponentStore' -Desc 'Dit si le nettoyage WinSxS libère de l''espace'
    Add-CmdButton $tabRare 'CompactOS activé ? (compact /compactos:query)' -Script 'compact /compactos:query'
    Add-CmdButton $tabRare 'Activer CompactOS — gagne ~2 Go sur C: (admin)' -Kind 'Elevated' -Script 'compact /compactos:always' -Desc 'Compresse les fichiers système — quasi aucune perte de perf sur SSD'
    Add-CmdButton $tabRare 'Espace des points de restauration (vssadmin) (admin)' -Kind 'Elevated' -Script 'vssadmin list shadowstorage'
    Add-CmdButton $tabRare 'Taille des dossiers racine de C: (2-5 min)' -Script $script:CmdRareDiskUsage -Desc 'Trouve ce qui remplit ton disque (lecture seule)'
    Add-CmdButton $tabRare 'Analyser C: (fragmentation / TRIM) (admin)' -Kind 'Elevated' -Script 'Optimize-Volume -DriveLetter C -Analyze -Verbose'
    Add-CmdButton $tabRare 'Score Windows Experience Index (Win32_WinSAT)' -Script $script:CmdRareWei
    Add-CmdButton $tabRare 'Benchmark système complet (winsat formal) (admin)' -Kind 'Elevated' -Script 'winsat formal' -Desc 'Évalue CPU, RAM, disque, graphiques (5-10 min)'
    Add-CmdButton $tabRare 'Configuration de démarrage (bcdedit /enum) (admin)' -Kind 'Elevated' -Script 'bcdedit /enum'
    Add-CmdButton $tabRare 'Environnement de récupération WinRE (reagentc /info)' -Script 'reagentc /info'
    Add-CmdButton $tabRare 'Chiffrement BitLocker : statut (manage-bde) (admin)' -Kind 'Elevated' -Script 'manage-bde -status'

    Add-Section $tabRare 'Réseau — commandes rares'
    Add-CmdButton $tabRare 'Table ARP (arp -a)' -Script 'arp -a'
    Add-CmdButton $tabRare 'Table de routage (route print)' -Script 'route print'
    Add-CmdButton $tabRare 'Adresses MAC (getmac /v)' -Script 'getmac /v'
    Add-CmdButton $tabRare 'pathping vers 1.1.1.1 (ping + tracert, ~30 s)' -Script 'pathping -q 4 -p 200 1.1.1.1'
    Add-CmdButton $tabRare 'Test port 443 vers google.com (Test-NetConnection)' -Script $script:CmdRareTnc
    Add-CmdButton $tabRare 'WiFi : interfaces, profils, pilotes' -Script $script:CmdRareWlan
    Add-CmdButton $tabRare 'Rapport WiFi complet HTML (wlanreport) (admin)' -Kind 'Elevated' -Script $script:CmdRareWlanReport -Desc 'Historique des connexions et déconnexions WiFi'
    Add-CmdButton $tabRare 'État du pare-feu par profil (netsh advfirewall)' -Script 'netsh advfirewall show allprofiles'

    Add-Section $tabRare 'Événements & plantages'
    Add-CmdButton $tabRare '25 derniers événements système (erreurs/avertissements)' -Script $script:CmdRareEvents
    Add-CmdButton $tabRare 'Arrêts inattendus & écrans bleus (Id 41/6008 + minidumps)' -Script $script:CmdRareCrashes -Desc 'Historique des plantages et liste des dumps BSOD'

    Add-Section $tabRare 'Stratégie, sécurité & comptes'
    Add-CmdButton $tabRare 'Rapport stratégies de groupe (gpresult /h)' -Script $script:CmdRareGpo
    Add-CmdButton $tabRare 'Stratégie de sécurité locale (éditions Pro)' -Kind 'Gui' -Target 'secpol.msc'
    Add-CmdButton $tabRare 'Utilisateurs et groupes locaux (éditions Pro)' -Kind 'Gui' -Target 'lusrmgr.msc'
    Add-CmdButton $tabRare 'Certificats de l''utilisateur' -Kind 'Gui' -Target 'certmgr.msc'
    Add-CmdButton $tabRare 'Gestion TPM (puce de sécurité)' -Kind 'Gui' -Target 'tpm.msc'
    Add-CmdButton $tabRare 'Planificateur de tâches' -Kind 'Gui' -Target 'taskschd.msc'
    Add-CmdButton $tabRare 'Vérificateur de pilotes — AVANCÉ (verifier) (admin)' -Kind 'GuiElevated' -Target 'verifier.exe' -Desc 'Traque un pilote défaillant — laisser la config par défaut ; verifier /reset pour annuler'

    Add-Section $tabRare 'Outils méconnus de Windows'
    Add-CmdButton $tabRare 'Moniteur de fiabilité (historique des plantages)' -Kind 'Gui' -Target 'perfmon.exe' -TargetArgs '/rel' -Desc 'Graphique jour par jour des erreurs et crashs'
    Add-CmdButton $tabRare 'Rapport de diagnostic système (60 s) (admin)' -Kind 'GuiElevated' -Target 'perfmon.exe' -TargetArgs '/report' -Desc 'Rapport complet : CPU, disque, réseau, erreurs'
    Add-CmdButton $tabRare 'Enregistreur d''étapes du problème (psr)' -Kind 'Gui' -Target 'psr.exe' -Desc 'Enregistre tes clics en captures annotées'
    Add-CmdButton $tabRare 'Outil de suppression des logiciels malveillants (mrt)' -Kind 'Gui' -Target 'mrt.exe'
    Add-CmdButton $tabRare 'Réinitialiser le cache Microsoft Store (wsreset)' -Kind 'Gui' -Target 'wsreset.exe'
    Add-CmdButton $tabRare 'Fonctionnalités Windows (activer/désactiver)' -Kind 'Gui' -Target 'OptionalFeatures.exe'
    Add-CmdButton $tabRare 'Effets visuels & performances' -Kind 'Gui' -Target 'SystemPropertiesPerformance.exe'
    Add-CmdButton $tabRare 'Protection système / points de restauration' -Kind 'Gui' -Target 'SystemPropertiesProtection.exe'
    Add-CmdButton $tabRare 'Dossier Démarrage (shell:startup)' -Kind 'Gui' -Target 'shell:startup'
    Add-CmdButton $tabRare 'Récupération : réinitialiser ce PC (Paramètres)' -Kind 'Gui' -Target 'ms-settings:recovery'
    Add-CmdButton $tabRare '⚠ Redémarrer dans WinRE (avancé) — redémarre MAINTENANT' -Kind 'GuiElevated' -Target 'shutdown.exe' -TargetArgs '/r /o /t 0' -Desc 'Sauvegarde tes documents avant de cliquer ! Menu de récupération au redémarrage'

    # ================= Onglet Nettoyage & rapidité =================
    Add-Section $tabClean 'Analyse — avant de nettoyer'
    Add-CmdButton $tabClean 'AUDIT EXPRESS du PC (lecture seule, ~30 s)' -Script $script:CmdAudit -Desc 'Espace disque, santé SSD, RAM, erreurs, temps de démarrage — verdict en un coup d''œil'
    Add-CmdButton $tabClean 'Mesurer : fichiers temporaires & caches (lecture seule)' -Script $script:CmdCleanMeasure -Desc 'Taille de chaque zone nettoyable avant d''agir'
    Add-CmdButton $tabClean 'Top 20 des plus gros fichiers de ton profil' -Script $script:CmdBigFiles -Desc 'Trouve ce qui remplit le disque (30-60 s)'

    Add-Section $tabClean 'Nettoyage — sans risque'
    Add-CmdButton $tabClean 'Nettoyer les fichiers temporaires utilisateur (%TEMP%)' -Script $script:CmdCleanUserTemp -Desc 'Fichiers en cours d''utilisation ignorés automatiquement'
    Add-CmdButton $tabClean 'Nettoyer les fichiers temporaires Windows (admin)' -Kind 'Elevated' -Script $script:CmdCleanWinTemp
    Add-CmdButton $tabClean 'Vider le cache Windows Update (admin)' -Kind 'Elevated' -Script $script:CmdCleanWU -Desc 'Peut libérer plusieurs Go — retéléchargement auto si besoin'
    Add-CmdButton $tabClean 'Vider le cache Delivery Optimization (admin)' -Kind 'Elevated' -Script $script:CmdCleanDO
    Add-CmdButton $tabClean 'Vider le cache des vignettes (thumbcache)' -Script $script:CmdCleanThumbs
    Add-CmdButton $tabClean 'Vider les rapports d''erreurs Windows (WER)' -Script $script:CmdCleanWer
    Add-CmdButton $tabClean 'Vider le cache Chrome & Edge (mots de passe conservés)' -Script $script:CmdCleanBrowsers -Desc 'Ferme les navigateurs avant pour tout libérer'
    Add-CmdButton $tabClean 'Vider la corbeille (lecteur C:)' -Script $script:CmdCleanBin
    Add-CmdButton $tabClean 'Créer un point de restauration avant nettoyage (admin)' -Kind 'Elevated' -Script $script:CmdRestorePoint -Desc 'Filet de sécurité — limite : 1 par 24 h'

    Add-Section $tabClean 'Accélérer Windows'
    Add-CmdButton $tabClean 'Redémarrer l''Explorateur Windows (bureau lent)' -Script $script:CmdRestartExplorer -Desc 'La barre des tâches clignote puis revient — répare les lenteurs d''affichage'
    Add-CmdButton $tabClean 'Lister les applications au démarrage' -Script $script:CmdStartupList
    Add-CmdButton $tabClean 'Activer le plan Haute performance' -Script $script:CmdHighPerf
    Add-CmdButton $tabClean 'Revenir au plan Équilibré' -Script $script:CmdBalanced
    Add-CmdButton $tabClean 'Désactiver l''hibernation — libère hiberfil.sys (admin)' -Kind 'Elevated' -Script $script:CmdHibernateOff -Desc 'Souvent 4-16 Go récupérés sur C: — parfait sur un PC fixe'
    Add-CmdButton $tabClean 'Réactiver l''hibernation (admin)' -Kind 'Elevated' -Script $script:CmdHibernateOn
    Add-CmdButton $tabClean 'Réparer la recherche Windows — réindexation (admin)' -Kind 'Elevated' -Script $script:CmdFixSearch -Desc 'Si la recherche ne trouve plus rien — l''index repart de zéro'
    Add-CmdButton $tabClean 'Réparer les applications Microsoft Store (admin)' -Kind 'Elevated' -Script $script:CmdFixStoreApps -Desc 'Réenregistre toutes les apps UWP (2-5 min)'
    Add-CmdButton $tabClean 'Réduire la télémétrie + désactiver DiagTrack (admin)' -Kind 'Elevated' -Script $script:CmdTelemetry -Desc 'Moins de tâches de fond, plus de confidentialité'

    # ================= Onglet Achat PC =================
    Add-Section $tabBuy 'Le test complet en un clic'
    Add-CmdButton $tabBuy 'TEST PRÉ-ACHAT COMPLET (lecture seule, 2-3 min)' -Script $script:CmdPreBuy -Desc 'Spécs, disques, plantages, activation, batterie — verdict + rapport .txt enregistré automatiquement'
    Add-CmdButton $tabBuy 'Spécifications réelles (à comparer avec l''annonce)' -Script $script:CmdBuySpecs
    Add-CmdButton $tabBuy 'Santé des disques + SMART' -Script $script:CmdBuyDisks
    Add-CmdButton $tabBuy 'Historique plantages & écrans bleus (90 j)' -Script $script:CmdBuyCrashes
    Add-CmdButton $tabBuy 'Windows activé ? (slmgr /xpr)' -Script $script:CmdLicense
    Add-CmdButton $tabBuy 'Defender actif & à jour ?' -Script $script:CmdBuyDefender
    Add-CmdButton $tabBuy 'Batterie : usure & cycles (portable)' -Script $script:CmdRareBattery
    Add-CmdButton $tabBuy 'RAM : barrettes & slots' -Script $script:CmdRareRam
    Add-CmdButton $tabBuy 'Périphériques en erreur' -Script $script:CmdRarePnp
    Add-CmdButton $tabBuy 'Date d''installation & usage réel' -Script $script:CmdBuyInstallDate

    Add-Section $tabBuy 'Tests matériels guidés'
    Add-CmdButton $tabBuy 'Test écran : pixels morts (plein écran, 9 couleurs)' -Kind 'ScreenTest' -Desc 'Clique ou Espace pour changer de couleur — Échap pour fermer'
    Add-CmdButton $tabBuy 'Test clavier (tape toutes les touches)' -Kind 'KeyboardTest' -Desc 'Une fenêtre ouverte : chaque touche qui s''affiche fonctionne'
    Add-CmdButton $tabBuy 'Test son (deux bips)' -Script '[console]::beep(880,400); Start-Sleep -Milliseconds 200; [console]::beep(660,400); ''Deux bips entendus = le son fonctionne (vérifie les haut-parleurs).'''
    Add-CmdButton $tabBuy 'Tester la webcam (Paramètres Caméra)' -Kind 'Gui' -Target 'ms-settings:camera'
    Add-CmdButton $tabBuy 'Ports USB : branche une clé puis vérifie ici' -Script 'Get-PnpDevice -Class USB -PresentOnly | Format-Table Status, FriendlyName -AutoSize'

    Add-Section $tabBuy 'PC PORTABLE — écran & fréquence (Hz)'
    Add-CmdButton $tabBuy 'Écran : résolution & taux de rafraîchissement (Hz)' -Script $script:CmdScreenHz -Desc 'Hz actuel + toutes les fréquences supportées (60/120/144/240…) — vérifie l''annonce du vendeur'
    Add-CmdButton $tabBuy 'Écran : modèle & fabricant de la dalle' -Script $script:CmdScreenModel
    Add-CmdButton $tabBuy 'Test du rétro-éclairage (30% → 100%)' -Script $script:CmdBrightTest -Desc 'Fait varier la luminosité pour vérifier que le rétro-éclairage répond — puis restaure'
    Add-CmdButton $tabBuy 'Changer les Hz (Paramètres d''affichage avancés)' -Script 'try { Start-Process "ms-settings:displayadvanced" } catch { Start-Process "ms-settings:display" }; ''Sélectionne le taux de rafraîchissement dans « Affichage avancé ».'''

    Add-Section $tabBuy 'PC PORTABLE — batterie & charge'
    Add-CmdButton $tabBuy 'Test de consommation en temps réel (30 s)' -Script $script:CmdBatteryDraw -Desc 'Mesure les watts consommés sur batterie (débranche le chargeur)'
    Add-CmdButton $tabBuy 'Puissance du chargeur mesurée (W)' -Script $script:CmdChargerPower -Desc 'Branche le chargeur puis mesure la puissance de charge réelle'
    Add-CmdButton $tabBuy 'Batterie : état instantané, usure & cycles' -Script $script:CmdRareBattery

    Add-Section $tabBuy 'PC PORTABLE — entrées & son'
    Add-CmdButton $tabBuy 'Touchpad & souris (périphériques de pointage)' -Script $script:CmdTouchpad
    Add-CmdButton $tabBuy 'Tester le micro (Paramètres son — entrée)' -Kind 'Gui' -Target 'ms-settings:sound'

    Add-Section $tabBuy 'Conseils achat'
    $tip = New-Object Windows.Forms.Label
    $tip.Text = ("• Le TEST COMPLET enregistre un rapport .txt : mets le dossier toolbox sur une clé USB — double-clic sur Lancer-Toolbox.cmd, aucune installation, marche sur le PC du vendeur.`r`n" +
                 "• Compare d'abord les spécifications avec l'annonce (processeur, RAM, disque, carte graphique).`r`n" +
                 "• À tester à la main : écran (pixels morts), clavier, ports USB, webcam, son, WiFi, ventilateurs et chauffe après 10 min.`r`n" +
                 "• Décline ou négocie fort si : disque non sain, SMART en échec, dizaines de BSOD, Windows non activé, batterie > 30 % d'usure.")
    $tip.AutoSize = $false
    $tip.Size = New-Object Drawing.Size(940, 110)
    $tip.ForeColor = [Drawing.Color]::FromArgb(60, 60, 70)
    $tip.Margin = New-Object Windows.Forms.Padding(6)
    $tabBuy.Controls.Add($tip)

    # ================= Onglet Raccourcis (v2.0) =================
    Add-Section $tabQuick 'Applications Windows'
    Add-CmdButton $tabQuick 'Calculatrice' -Kind 'Gui' -Target 'calc.exe'
    Add-CmdButton $tabQuick 'Bloc-notes' -Kind 'Gui' -Target 'notepad.exe'
    Add-CmdButton $tabQuick 'Paint' -Kind 'Gui' -Target 'mspaint.exe'
    Add-CmdButton $tabQuick 'Capture d''écran (outil Snipping)' -Kind 'Gui' -Target 'ms-screenclip:' -Desc 'Lance directement une capture'
    Add-CmdButton $tabQuick 'Explorateur de fichiers' -Kind 'Gui' -Target 'explorer.exe'
    Add-CmdButton $tabQuick 'Horloge / minuteur' -Kind 'Gui' -Target 'ms-clock:'
    Add-CmdButton $tabQuick 'Clavier visuel' -Kind 'Gui' -Target 'osk.exe'
    Add-CmdButton $tabQuick 'Loupe' -Kind 'Gui' -Target 'magnify.exe'

    Add-Section $tabQuick 'Réglages rapides (Paramètres)'
    Add-CmdButton $tabQuick 'Bluetooth & appareils' -Kind 'Gui' -Target 'ms-settings:bluetooth'
    Add-CmdButton $tabQuick 'WiFi' -Kind 'Gui' -Target 'ms-settings:network-wifi'
    Add-CmdButton $tabQuick 'Couleurs / thème clair-sombre' -Kind 'Gui' -Target 'ms-settings:colors'
    Add-CmdButton $tabQuick 'Éclairage nocturne' -Kind 'Gui' -Target 'ms-settings:nightlight'
    Add-CmdButton $tabQuick 'Son' -Kind 'Gui' -Target 'ms-settings:sound'
    Add-CmdButton $tabQuick 'Affichage' -Kind 'Gui' -Target 'ms-settings:display'
    Add-CmdButton $tabQuick 'Vos infos de compte' -Kind 'Gui' -Target 'ms-settings:yourinfo'
    Add-CmdButton $tabQuick 'Date & heure' -Kind 'Gui' -Target 'ms-settings:dateandtime'
    Add-CmdButton $tabQuick 'Confidentialité' -Kind 'Gui' -Target 'ms-settings:privacy'
    Add-CmdButton $tabQuick 'Accessibilité' -Kind 'Gui' -Target 'ms-settings:easeofaccess'
    Add-CmdButton $tabQuick 'Barre des tâches' -Kind 'Gui' -Target 'ms-settings:taskbar'

    Add-Section $tabQuick 'Dossiers usuels'
    Add-CmdButton $tabQuick 'Téléchargements' -Kind 'Gui' -Target 'shell:Downloads'
    Add-CmdButton $tabQuick 'Documents' -Kind 'Gui' -Target 'shell:Personal'
    Add-CmdButton $tabQuick 'Images' -Kind 'Gui' -Target 'shell:My Pictures'
    Add-CmdButton $tabQuick 'Bureau' -Kind 'Gui' -Target 'shell:Desktop'
    Add-CmdButton $tabQuick 'Corbeille' -Kind 'Gui' -Target 'shell:RecycleBinFolder'
    Add-CmdButton $tabQuick 'Dossier TEMP utilisateur' -Script 'Start-Process explorer.exe $env:TEMP'
    Add-CmdButton $tabQuick 'Dossier APPDATA (Roaming)' -Script 'Start-Process explorer.exe $env:APPDATA'
    Add-CmdButton $tabQuick 'Dossier LOCALAPPDATA' -Script 'Start-Process explorer.exe $env:LOCALAPPDATA'

    Add-Section $tabQuick 'Actions système'
    Add-CmdButton $tabQuick 'Verrouiller la session' -Kind 'Gui' -Target 'rundll32.exe' -TargetArgs 'user32.dll,LockWorkStation'
    Add-CmdButton $tabQuick 'Afficher le bureau (basculer)' -Kind 'Gui' -Target 'shell:::{3080F90D-D7AD-11D9-BD98-0000947B0257}'
    Add-CmdButton $tabQuick 'Vider le presse-papiers' -Script "'' | Set-Clipboard; 'Presse-papiers vidé.'"
    Add-CmdButton $tabQuick 'Masquer la toolbox (systray)' -Kind 'HideApp' -Desc 'Même effet que le bouton Masquer ou Ctrl+H'
    Add-CmdButton $tabQuick 'Mise en veille' -Kind 'Gui' -Target 'rundll32.exe' -TargetArgs 'powrprof.dll,SetSuspendState 0,1,0' -Desc 'Si l''hibernation est activée, met en hibernation'
    Add-CmdButton $tabQuick '⚠ Redémarrer le PC maintenant' -Kind 'Gui' -Target 'shutdown.exe' -TargetArgs '/r /t 0' -Desc 'Sauvegarde tes documents avant de cliquer !'
    Add-CmdButton $tabQuick '⚠ Éteindre le PC maintenant' -Kind 'Gui' -Target 'shutdown.exe' -TargetArgs '/s /t 0' -Desc 'Sauvegarde tes documents avant de cliquer !'

    Add-Section $tabQuick 'God Mode & dossiers secrets'
    Add-CmdButton $tabQuick 'Ouvrir le GOD MODE maintenant (250+ outils Windows)' -Kind 'Gui' -Target 'shell:::{ED7BA470-8E54-465E-825C-99712043E01C}' -Desc 'Toutes les tâches et réglages de Windows dans une seule liste'
    Add-CmdButton $tabQuick 'Créer le dossier God Mode sur le Bureau' -Script $script:CmdGodCreate -Desc 'Un dossier « God Mode » apparaît sur ton Bureau'
    Add-CmdButton $tabQuick 'Supprimer le dossier God Mode du Bureau' -Script $script:CmdGodRemove
    Add-CmdButton $tabQuick 'Créer les 10 dossiers secrets (God Mode + outils)' -Script $script:CmdGodAllCreate -Desc 'God Mode + administration, alimentation, son, réseau, système… sur le Bureau'
    Add-CmdButton $tabQuick 'Supprimer les 10 dossiers secrets' -Script $script:CmdGodAllRemove
    Add-CmdButton $tabQuick 'Ouvrir : Outils d''administration' -Kind 'Gui' -Target 'shell:::{D20EA4E1-3957-11d2-A40B-0C5020524152}'
    Add-CmdButton $tabQuick 'Ouvrir : Options d''alimentation' -Kind 'Gui' -Target 'shell:::{025A5937-A6BE-4686-A844-36FE4BEC8B6D}'
    Add-CmdButton $tabQuick 'Ouvrir : Son' -Kind 'Gui' -Target 'shell:::{F2DDFC82-8F12-4CDD-B7DC-D4FE1425AA4D}'
    Add-CmdButton $tabQuick 'Ouvrir : Centre Réseau et partage' -Kind 'Gui' -Target 'shell:::{8E908FC9-BECC-40f6-915B-F4CA0E70D03D}'

    Add-Section $tabQuick 'Options de l''application'
    function Add-OptionCheck {
        param($Parent, [string]$Text, [string]$Setting, [scriptblock]$OnChange, [string]$Desc = '')
        $cb = New-Object Windows.Forms.CheckBox
        $cb.Text = $Text
        $cb.AutoSize = $true
        $cb.Size = New-Object Drawing.Size(460, 24)
        $cb.Margin = New-Object Windows.Forms.Padding(6, 4, 6, 4)
        $cb.Checked = ((Get-ToolboxSetting $Setting 0) -eq 1)
        if ($Desc) { $script:Tooltip.SetToolTip($cb, $Desc) }
        $cb.Add_Click({
            Set-ToolboxSetting $setting ([int]$cb.Checked)
            if ($onChange) { & $onChange }
        }.GetNewClosure())
        $Parent.Controls.Add($cb)
    }
    Add-OptionCheck $tabQuick 'Réduire dans la zone de notification (systray) au lieu de la barre des tâches' 'MinimizeToTray'
    Add-OptionCheck $tabQuick 'Raccourci global Ctrl+Alt+T (afficher / masquer depuis n''importe où)' 'GlobalHotkey' -OnChange {
        if ((Get-ToolboxSetting 'GlobalHotkey' 1) -eq 1) { Register-ToolboxHotkey -Form $script:Form }
        else { Unregister-ToolboxHotkey -Form $script:Form }
    }
    Add-OptionCheck $tabQuick 'Démarrer automatiquement avec Windows' 'StartWithWindows' -OnChange {
        Set-StartupWithWindows ((Get-ToolboxSetting 'StartWithWindows' 0) -eq 1)
    }

    $kbd = New-Object Windows.Forms.Label
    $kbd.Text = ("RACCOURCIS CLAVIER`r`n" +
                 " • Ctrl+Alt+T (global, même hors de la fenêtre) : afficher / masquer la toolbox`r`n" +
                 " • Ctrl+1 … Ctrl+9 : changer d'onglet · F1 : À propos`r`n" +
                 " • Ctrl+H : masquer dans le systray · Ctrl+U : vérifier les mises à jour`r`n" +
                 " • Icône systray : clic gauche = afficher/masquer, clic droit = menu (audit, mises à jour, quitter)")
    $kbd.AutoSize = $false
    $kbd.Size = New-Object Drawing.Size(940, 92)
    $kbd.ForeColor = [Drawing.Color]::FromArgb(60, 60, 70)
    $kbd.Margin = New-Object Windows.Forms.Padding(6, 10, 6, 6)
    $tabQuick.Controls.Add($kbd)

    # ================= Onglet Outils tiers =================
    Add-Section $tabTools ('Détectés sur ce PC ({0})' -f ($script:DetectedTools.Count + $script:PortableTools.Count))
    if ($script:PortableTools.Count -gt 0) {
        foreach ($pt in $script:PortableTools) {
            Add-CmdButton $tabTools ("▶  {0}  (portable)" -f $pt.Name) -Kind 'Gui' -Target $pt.FullName
        }
    }
    if ($script:DetectedTools.Count -gt 0) {
        foreach ($kv in ($script:DetectedTools.GetEnumerator() | Sort-Object Name)) {
            $cat = $script:ThirdPartyCatalog | Where-Object { $_.Name -eq $kv.Key } | Select-Object -First 1
            $desc = if ($cat) { $cat.Desc } else { '' }
            Add-CmdButton $tabTools ("▶  {0} — {1}" -f $kv.Key, $desc) -Kind 'Gui' -Target $kv.Value -Desc $kv.Value
        }
    }
    if (($script:DetectedTools.Count + $script:PortableTools.Count) -eq 0) {
        $none = New-Object Windows.Forms.Label
        $none.Text = '  (aucun) — installe-en depuis les liens ci-dessous, ou place tes .exe portables dans le dossier tools\.'
        $none.AutoSize = $true
        $none.ForeColor = [Drawing.Color]::Gray
        $tabTools.Controls.Add($none)
    }

    Add-Section $tabTools 'Recommandés — le bouton ouvre le site officiel'
    foreach ($tool in $script:ThirdPartyCatalog) {
        if (-not $script:DetectedTools.ContainsKey($tool.Name)) {
            Add-CmdButton $tabTools ("→  {0} — {1}" -f $tool.Name, $tool.Desc) -Kind 'Url' -Target $tool.Url
        }
    }

    # ================= Onglet À propos (design v1.4) =================
    # La boucle des onglets a déjà ancré un FlowLayoutPanel sur chaque page : on le réutilise
    # (deux panneaux Fill superposés se masqueraient mutuellement).
    $aboutFlow = $tabAbout.Controls[0]
    if (-not $aboutFlow) {
        $aboutFlow = New-Object Windows.Forms.FlowLayoutPanel
        $aboutFlow.Dock = 'Fill'
        $tabAbout.Controls.Add($aboutFlow)
    }
    $aboutFlow.AutoScroll = $true
    $aboutFlow.Padding = New-Object Windows.Forms.Padding(16)
    $aboutFlow.WrapContents = $true

    # --- Bandeau d'en-tête ---
    $head = New-Object Windows.Forms.Panel
    $head.Size = New-Object Drawing.Size(940, 128)
    $head.BackColor = [Drawing.Color]::FromArgb(37, 99, 235)
    $head.Margin = New-Object Windows.Forms.Padding(0, 0, 0, 14)

    $hTitle = New-Object Windows.Forms.Label
    $hTitle.Text = 'Windows 11 Toolbox'
    $hTitle.Font = New-Object Drawing.Font('Segoe UI', 17, [Drawing.FontStyle]::Bold)
    $hTitle.ForeColor = [Drawing.Color]::White
    $hTitle.AutoSize = $true
    $hTitle.Location = New-Object Drawing.Point(22, 14)
    $head.Controls.Add($hTitle)

    $hSub = New-Object Windows.Forms.Label
    $hSub.Text = "v$script:ToolboxVersion · Windows 10/11 · PowerShell natif — aucune installation, aucun module externe"
    $hSub.ForeColor = [Drawing.Color]::FromArgb(219, 234, 254)
    $hSub.AutoSize = $true
    $hSub.Location = New-Object Drawing.Point(24, 56)
    $head.Controls.Add($hSub)

    $hAuthor = New-Object Windows.Forms.Label
    $hAuthor.Text = '∞ Infinity Coder — Derouiche Oussama'
    $hAuthor.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
    $hAuthor.ForeColor = [Drawing.Color]::White
    $hAuthor.AutoSize = $true
    $hAuthor.Location = New-Object Drawing.Point(24, 86)
    $head.Controls.Add($hAuthor)

    $donBig = New-Object Windows.Forms.Button
    $donBig.Text = '♥ Faire un don'
    $donBig.Size = New-Object Drawing.Size(160, 44)
    $donBig.Location = New-Object Drawing.Point(756, 42)
    $donBig.Anchor = 'Top,Right'
    $donBig.FlatStyle = 'Flat'
    $donBig.FlatAppearance.BorderSize = 0
    $donBig.BackColor = [Drawing.Color]::White
    $donBig.ForeColor = [Drawing.Color]::FromArgb(124, 58, 237)
    $donBig.Font = New-Object Drawing.Font('Segoe UI', 10.5, [Drawing.FontStyle]::Bold)
    $donBig.Add_Click({ try { Start-Process $script:DonationUrl } catch { } })
    $head.Controls.Add($donBig)

    $btnUpd = New-Object Windows.Forms.Button
    $btnUpd.Text = 'Vérifier les mises à jour'
    $btnUpd.Size = New-Object Drawing.Size(196, 44)
    $btnUpd.Location = New-Object Drawing.Point(548, 42)
    $btnUpd.Anchor = 'Top,Right'
    $btnUpd.FlatStyle = 'Flat'
    $btnUpd.FlatAppearance.BorderColor = [Drawing.Color]::White
    $btnUpd.FlatAppearance.BorderSize = 1
    $btnUpd.BackColor = [Drawing.Color]::FromArgb(37, 99, 235)
    $btnUpd.ForeColor = [Drawing.Color]::White
    $btnUpd.Font = New-Object Drawing.Font('Segoe UI', 9.5)
    $btnUpd.Add_Click({ Start-UpdateCheck -Manual })
    $head.Controls.Add($btnUpd)

    $aboutFlow.Controls.Add($head)

    # --- Cartes d'information ---
    function New-AboutCard {
        param([string]$Title, [Drawing.Color]$TitleColor, [string[]]$Lines)
        $card = New-Object Windows.Forms.Panel
        $card.Size = New-Object Drawing.Size(296, 196)
        $card.BackColor = [Drawing.Color]::White
        $card.BorderStyle = 'FixedSingle'
        $card.Margin = New-Object Windows.Forms.Padding(0, 0, 12, 14)
        $t = New-Object Windows.Forms.Label
        $t.Text = $Title
        $t.Font = New-Object Drawing.Font('Segoe UI', 10.5, [Drawing.FontStyle]::Bold)
        $t.ForeColor = $TitleColor
        $t.AutoSize = $false
        $t.Size = New-Object Drawing.Size(276, 26)
        $t.Location = New-Object Drawing.Point(10, 10)
        $card.Controls.Add($t)
        $y = 42
        foreach ($line in $Lines) {
            $li = New-Object Windows.Forms.Label
            $li.Text = $line
            $li.ForeColor = [Drawing.Color]::FromArgb(55, 60, 70)
            $li.AutoSize = $false
            $li.Size = New-Object Drawing.Size(276, 24)
            $li.Location = New-Object Drawing.Point(10, $y)
            $card.Controls.Add($li)
            $y += 27
        }
        return $card
    }

    $aboutFlow.Controls.Add((New-AboutCard 'Ce que fait la toolbox' ([Drawing.Color]::FromArgb(37, 99, 235)) @('9 onglets — plus de 200 commandes prêtes', 'Tests SSD / SMART · benchmark · TRIM', 'Audit express & test pré-achat PC', 'Nettoyage temporaires, caches & rapidité', 'Réparation SFC · DISM · réseau')))
    $aboutFlow.Controls.Add((New-AboutCard 'Code couleur des boutons' ([Drawing.Color]::FromArgb(124, 58, 237)) @('Bordure bleue = commande ici (console)', 'Orange = admin (fenêtre UAC séparée)', 'Blanc = outil Windows intégré', 'Bleu clair = site web officiel', 'Survole un bouton : une infobulle aide')))
    $aboutFlow.Controls.Add((New-AboutCard 'Bon à savoir' ([Drawing.Color]::FromArgb(21, 128, 61)) @('Sur clé USB : parfait pour l''achat PC', '« Enregistrer rapport » exporte en .txt', 'Dossier tools\ = tes .exe portables', 'Mode admin débloque SFC/DISM/TRIM', 'Tout est lecture seule par défaut')))

    # --- Liens officiels de l'auteur ---
    function Add-AboutLink {
        param($Parent, [string]$Text, [string]$Url)
        $b = New-Object Windows.Forms.Button
        $b.Text = $Text
        $b.Size = New-Object Drawing.Size(170, 44)
        $b.Margin = New-Object Windows.Forms.Padding(0, 0, 12, 14)
        $b.FlatStyle = 'Flat'
        $b.UseMnemonic = $false
        $b.FlatAppearance.BorderSize = 1
        $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(147, 197, 253)
        $b.BackColor = [Drawing.Color]::FromArgb(239, 246, 255)
        $b.ForeColor = [Drawing.Color]::FromArgb(37, 99, 235)
        $b.Add_Click({ try { Start-Process $url } catch { Append-Console ('[ERREUR] ' + $_.Exception.Message) } }.GetNewClosure())
        $Parent.Controls.Add($b)
    }

    Add-AboutLink $aboutFlow 'Site web' $script:AuthorSite
    Add-AboutLink $aboutFlow 'GitHub' $script:AuthorGitHub
    Add-AboutLink $aboutFlow 'Instagram' $script:AuthorInsta
    Add-AboutLink $aboutFlow 'Facebook' $script:AuthorFb
    Add-AboutLink $aboutFlow 'TikTok' $script:AuthorTikTok

    $donRow = New-Object Windows.Forms.Button
    $donRow.Text = '♥ Ce logiciel est gratuit — un don soutient le développement'
    $donRow.Size = New-Object Drawing.Size(460, 46)
    $donRow.Margin = New-Object Windows.Forms.Padding(0, 4, 14, 14)
    $donRow.FlatStyle = 'Flat'
    $donRow.FlatAppearance.BorderSize = 0
    $donRow.BackColor = [Drawing.Color]::FromArgb(124, 58, 237)
    $donRow.ForeColor = [Drawing.Color]::White
    $donRow.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
    $donRow.Add_Click({ try { Start-Process $script:DonationUrl } catch { } })
    $aboutFlow.Controls.Add($donRow)

    # ---------- Assemblage ----------
    $form.Controls.Add($tabs)
    $form.Controls.Add($top)
    $form.Controls.Add($consolePanel)
    $form.Controls.Add($statusStrip)

    # ---------- Raccourcis clavier & systray (v2.0) ----------
    $script:Tabs = $tabs
    $script:BalloonShown = $false
    $form.KeyPreview = $true

    $form.Add_KeyDown({
        param($s, $e)
        try {
            if ($e.Control -and ($e.KeyCode -ge 'D1') -and ($e.KeyCode -le 'D9')) {
                $n = [int][char]([string]$e.KeyCode)[1] - [int][char]'1'
                if ($n -lt $script:Tabs.TabPages.Count) { $script:Tabs.SelectedIndex = $n }
                $e.Handled = $true
            }
            elseif ($e.Control -and ($e.KeyCode -eq 'H')) { Hide-Toolbox; $e.Handled = $true }
            elseif ($e.Control -and ($e.KeyCode -eq 'U')) { Start-UpdateCheck -Manual; $e.Handled = $true }
            elseif ($e.KeyCode -eq 'F1') { $script:Tabs.SelectedIndex = $script:Tabs.TabPages.Count - 1; $e.Handled = $true }
        } catch { }
    })

    $form.Add_Resize({
        try {
            if ($script:Form.WindowState -eq 'Minimized' -and (Get-ToolboxSetting 'MinimizeToTray' 1) -eq 1) {
                Hide-Toolbox
                $script:Form.WindowState = 'Normal'
                $script:Form.Hide()
            }
        } catch { }
    })

    $script:TrayIcon = New-Object Windows.Forms.NotifyIcon
    $script:TrayIcon.Icon = $form.Icon
    $script:TrayIcon.Text = 'Windows 11 Toolbox — Ctrl+Alt+T : afficher/masquer'
    $script:TrayIcon.Visible = $true

    $trayMenu = New-Object Windows.Forms.ContextMenuStrip
    [void]$trayMenu.Items.Add('Afficher / Masquer (Ctrl+Alt+T)', $null, { Toggle-ToolboxVisible })
    [void]$trayMenu.Items.Add('Audit express du PC', $null, { Show-ToolboxWindow; Start-InlineCommand -Title 'Audit express' -Script $script:CmdAudit })
    [void]$trayMenu.Items.Add('Vérifier les mises à jour', $null, { Start-UpdateCheck -Manual })
    [void]$trayMenu.Items.Add((New-Object Windows.Forms.ToolStripSeparator))
    [void]$trayMenu.Items.Add('Quitter', $null, { $script:Form.Close() })
    $script:TrayIcon.ContextMenuStrip = $trayMenu

    $script:TrayIcon.Add_MouseUp({
        try { if ($_.Button -eq [Windows.Forms.MouseButtons]::Left) { Toggle-ToolboxVisible } } catch { }
    })

    Register-ToolboxHotkey -Form $form
    $form.Add_GlobalHotkey({ Toggle-ToolboxVisible })

    # ---------- Moteur d'exécution asynchrone ----------
    $script:Busy = $false
    $script:PS = $null
    $script:Handle = $null
    $script:UpdateIsManual = $false
    $script:PendingAutoUpdate = $false

    $timer = New-Object Windows.Forms.Timer
    $script:Timer = $timer
    $timer.Interval = 200
    $timer.Add_Tick({
        try {
            while ($sync.Queue.Count -gt 0) {
                $line = [string]$sync.Queue.Dequeue()
                if ($line -like 'UPDATE|*') {
                    $p = $line -split '\|', 5
                    if ($p.Count -ge 5) { Show-UpdateOffer -Version $p[1] -Url $p[2] -Hash $p[3] -Notes $p[4] }
                }
                elseif ($line -like 'UPDOK|*') {
                    if ($script:UpdateIsManual) { Append-Console '[MAJ] Tu as déjà la dernière version ✓' }
                }
                elseif ($line -like 'UPDERR|*') {
                    if ($script:UpdateIsManual) { Append-Console ('[MAJ] Erreur : ' + $line.Substring(7)) }
                }
                elseif ($line -like 'UPDFAIL|*') {
                    Append-Console ('[MAJ] Échec : ' + $line.Substring(8))
                    [Windows.Forms.MessageBox]::Show($script:Form, $line.Substring(8), 'Mise à jour', 'OK', 'Warning') | Out-Null
                }
                elseif ($line -like 'UPDDONE-EXE|*') {
                    $p = $line -split '\|', 3
                    Append-Console ("[MAJ] Nouvelle version {0} téléchargée : {1} — lance ce nouveau fichier." -f $p[1], $p[2])
                    [Windows.Forms.MessageBox]::Show($script:Form, "Nouvelle version téléchargée :`r`n$($p[2])`r`n`r`nLance ce nouveau fichier pour l'utiliser.", 'Mise à jour installée', 'OK', 'Information') | Out-Null
                }
                elseif ($line -like 'UPDDONE|*') {
                    $p = $line -split '\|', 2
                    Append-Console ("[MAJ] Version {0} installée ✓" -f $p[1])
                    $sumFile = Join-Path $script:ScriptDir 'checksums.txt'
                    if (Test-Path -LiteralPath $sumFile) {
                        try {
                            $h = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
                            Set-Content -LiteralPath $sumFile -Value ("SHA256  {0}  Windows-Toolbox.ps1  {1:yyyy-MM-dd HH:mm}" -f $h, (Get-Date)) -Encoding UTF8
                        } catch { }
                    }
                    $r = [Windows.Forms.MessageBox]::Show($script:Form, "Version $($p[1]) installée !`r`n`r`nRedémarrer la toolbox maintenant ?", 'Mise à jour installée', 'YesNo', 'Information')
                    if ($r -eq [Windows.Forms.DialogResult]::Yes) {
                        Start-Process -FilePath 'powershell.exe' -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
                        $script:Form.Close()
                    }
                }
                else { Append-Console $line }
            }
            if ($script:Handle -and $script:Handle.IsCompleted) {
                try { $null = $script:PS.EndInvoke($script:Handle) }
                catch { Append-Console ('[ERREUR] ' + $_.Exception.Message) }
                try { $script:PS.Dispose() } catch { }
                $script:PS = $null
                $script:Handle = $null
                $script:Busy = $false
                if ($script:PendingAutoUpdate) {
                    $script:PendingAutoUpdate = $false
                    Start-UpdateCheck
                } else {
                    Set-Status $(if (Test-IsAdmin) { "Prêt — $env:COMPUTERNAME · Administrateur" } else { "Prêt — $env:COMPUTERNAME · Utilisateur" })
                }
            }
        } catch { }
    })

    $form.Add_Shown({
        $script:PendingAutoUpdate = $true
        Start-InlineCommand -Title 'Inventaire rapide (automatique)' -Script ($script:CmdSummary + "`r`n" + $script:CmdDiskHealth)
    })

    $form.Add_FormClosed({
        $script:Timer.Stop()
        try { Unregister-ToolboxHotkey -Form $script:Form } catch { }
        try { $script:TrayIcon.Visible = $false; $script:TrayIcon.Dispose() } catch { }
        try { if ($script:PS) { $script:PS.Dispose() } } catch { }
    })

    $timer.Start()
    [void]$form.ShowDialog()
}

try {
    Show-Toolbox
} catch {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    [Windows.Forms.MessageBox]::Show("Erreur : $($_.Exception.Message)`n`n$($_.ScriptStackTrace)", 'Windows Toolbox — erreur', 'OK', 'Error') | Out-Null
    exit 1
}
exit 0
