; Lasco Windows Installer — Inno Setup Script
; Produces a single .exe installer for Lasco (VSCodium fork)
;
; Build:  iscc.exe lasco-installer.iss
;   or:   iscc.exe /DSOURCE_DIR="C:\path\to\VSCode-win32-x64" lasco-installer.iss

; ─── App metadata ────────────────────────────────────────────────
#define AppName        "Lasco"
#define AppExe         "Lasco.exe"
#define AppVersion     "1.109.31290"
#define AppPublisher   "Lasco"
#define AppDirName     "Lasco"

; ─── Paths (override with /D on the iscc command line) ───────────
#ifndef SOURCE_DIR
  #define SOURCE_DIR   "..\..\VSCode-win32-x64"
#endif

#ifndef ICON_PATH
  #define ICON_PATH    "..\..\vscode\resources\win32\code.ico"
#endif

#ifndef OUTPUT_DIR
  #define OUTPUT_DIR   "..\..\installer-output"
#endif

[Setup]
AppId={{LASCO-EDITOR}
AppName={#AppName}
AppVerName={#AppName} {#AppVersion}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={userpf}\{#AppDirName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
OutputDir={#OUTPUT_DIR}
OutputBaseFilename=LascoSetup-{#AppVersion}-x64
Compression=lzma2/ultra64
SolidCompression=yes
SetupIconFile={#ICON_PATH}
UninstallDisplayIcon={app}\{#AppExe}
PrivilegesRequired=lowest
ChangesEnvironment=yes
WizardStyle=modern
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional options:"; Flags: checkedonce
Name: "addtopath"; Description: "Add {#AppName} to PATH"; GroupDescription: "Additional options:"; Flags: checkedonce
Name: "addcontextmenu"; Description: "Add ""Open with {#AppName}"" to Explorer context menu"; GroupDescription: "Additional options:"

[Files]
; VC++ Redistributable — extracted to {tmp}, deleted after install
Source: "vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall
; Main application files
Source: "{#SOURCE_DIR}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; Install path
Root: HKCU; Subkey: "Software\{#AppName}"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"; Flags: uninsdeletekey

; Explorer context menu — files
Root: HKCU; Subkey: "Software\Classes\*\shell\{#AppName}"; ValueType: string; ValueData: "Open with {#AppName}"; Tasks: addcontextmenu; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\*\shell\{#AppName}"; ValueType: string; ValueName: "Icon"; ValueData: """{app}\{#AppExe}"""; Tasks: addcontextmenu
Root: HKCU; Subkey: "Software\Classes\*\shell\{#AppName}\command"; ValueType: string; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: addcontextmenu

; Explorer context menu — directories
Root: HKCU; Subkey: "Software\Classes\Directory\shell\{#AppName}"; ValueType: string; ValueData: "Open with {#AppName}"; Tasks: addcontextmenu; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Directory\shell\{#AppName}"; ValueType: string; ValueName: "Icon"; ValueData: """{app}\{#AppExe}"""; Tasks: addcontextmenu
Root: HKCU; Subkey: "Software\Classes\Directory\shell\{#AppName}\command"; ValueType: string; ValueData: """{app}\{#AppExe}"" ""%1"""; Tasks: addcontextmenu

; Explorer context menu — directory backgrounds
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\{#AppName}"; ValueType: string; ValueData: "Open with {#AppName}"; Tasks: addcontextmenu; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\{#AppName}"; ValueType: string; ValueName: "Icon"; ValueData: """{app}\{#AppExe}"""; Tasks: addcontextmenu
Root: HKCU; Subkey: "Software\Classes\Directory\Background\shell\{#AppName}\command"; ValueType: string; ValueData: """{app}\{#AppExe}"" ""%V"""; Tasks: addcontextmenu

[Run]
; Install VC++ Redistributable silently (safe to re-run if already installed)
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Visual C++ Redistributable..."; Flags: waituntilterminated
; Launch after install (finish page checkbox)
Filename: "{app}\{#AppExe}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Code]
// ─── PATH management ────────────────────────────────────────────
// Appends {app}\bin to user PATH on install, removes it on uninstall.

procedure AddToPath();
var
  CurrentPath, BinDir: string;
begin
  BinDir := ExpandConstant('{app}\bin');
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', CurrentPath) then
    CurrentPath := '';
  // Already present (case-insensitive check)
  if Pos(Uppercase(BinDir), Uppercase(CurrentPath)) > 0 then
    Exit;
  if CurrentPath = '' then
    RegWriteExpandStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', BinDir)
  else
    RegWriteExpandStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', CurrentPath + ';' + BinDir);
end;

procedure RemoveFromPath();
var
  CurrentPath, BinDir: string;
  BeforeStr, AfterStr, NewPath: string;
  StartPos: Integer;
begin
  BinDir := ExpandConstant('{app}\bin');
  if not RegQueryStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', CurrentPath) then
    Exit;
  StartPos := Pos(Uppercase(BinDir), Uppercase(CurrentPath));
  if StartPos = 0 then
    Exit;
  BeforeStr := Copy(CurrentPath, 1, StartPos - 1);
  AfterStr  := Copy(CurrentPath, StartPos + Length(BinDir), MaxInt);
  // Strip dangling semicolons at the join point
  if (Length(BeforeStr) > 0) and (BeforeStr[Length(BeforeStr)] = ';') then
    BeforeStr := Copy(BeforeStr, 1, Length(BeforeStr) - 1);
  if (Length(AfterStr) > 0) and (AfterStr[1] = ';') then
    AfterStr := Copy(AfterStr, 2, MaxInt);
  if BeforeStr = '' then
    NewPath := AfterStr
  else if AfterStr = '' then
    NewPath := BeforeStr
  else
    NewPath := BeforeStr + ';' + AfterStr;
  RegWriteExpandStringValue(HKEY_CURRENT_USER, 'Environment', 'Path', NewPath);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if IsTaskSelected('addtopath') then
      AddToPath();
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RemoveFromPath();
end;
