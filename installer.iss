; ================================================================
;  Windows 11 Toolbox — Installateur Inno Setup
;  ∞ Infinity Coder — Derouiche Oussama — GPL-3.0
;  Compilation : ISCC.exe installer.iss  →  Windows-Toolbox-Setup.exe
; ================================================================

#define AppName "Windows 11 Toolbox"
#define AppPublisher "Derouiche Oussama - Infinity Coder"
#define AppURL "https://github.com/derouicheoussama/windows-toolbox"
#define AppExeName AddBackslash(SourcePath) + "Windows-Toolbox.exe"
#define AppVersion GetFileVersion(AppExeName)

[Setup]
AppId={{8C4F2A96-1D3E-4B7A-9F5C-2E8D6A1B3C7E}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}/releases
DefaultDirName={localappdata}\Programs\WindowsToolbox
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
LicenseFile=LICENSE
OutputDir=.
OutputBaseFilename=Windows-Toolbox-Setup
SetupIconFile=brand\Windows-Toolbox.ico
UninstallDisplayIcon={app}\Windows-Toolbox.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "french"; MessagesFile: compiler:Languages\French.isl

[Tasks]
Name: "desktopicon"; Description: "Créer un raccourci sur le &Bureau"; GroupDescription: "Raccourcis :"

[Files]
Source: "{#AppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "Lancer-Toolbox.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "Uninstall-Toolbox.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "Updater-Toolbox.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "tools\LISEZMOI.txt"; DestDir: "{app}\tools"; Flags: ignoreversion
Source: "brand\Windows-Toolbox.ico"; DestDir: "{app}\brand"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\Windows-Toolbox.exe"
Name: "{group}\{#AppName} - Désinstaller"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\Windows-Toolbox.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Windows-Toolbox.exe"; Description: "Lancer {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "taskkill.exe"; Parameters: "/F /IM Windows-Toolbox.exe"; Flags: runhidden; RunOnceId: "KillApp"

[UninstallDelete]
Type: files; Name: "{app}\*.old"
Type: files; Name: "{app}\*.update"
Type: filesandordirs; Name: "{app}\tools"

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    // Ferme l'application si elle tourne (le fichier EXE ne peut pas être supprimé sinon)
    Exec(ExpandConstant('{cmd}'), '/C taskkill /F /IM Windows-Toolbox.exe >nul 2>&1', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    // Supprime l'option de démarrage automatique si présente
    RegDeleteValue(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Run', 'WindowsToolbox');
  end;
end;
