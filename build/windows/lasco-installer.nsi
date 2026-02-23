; Lasco Windows Installer — NSIS Script
; Produces a single .exe installer for Lasco (VSCodium fork)

!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "WordFunc.nsh"

; ─── App metadata ───────────────────────────────────────────────
!define APP_NAME        "Lasco"
!define APP_EXE         "Lasco.exe"
!define APP_VERSION     "1.109.31290"
!define APP_PUBLISHER   "Lasco"
!define APP_DIR_NAME    "Lasco"
!define APP_REG_KEY     "Software\${APP_NAME}"
!define UNINSTALL_KEY   "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

; ─── Source directory (the built Electron app) ──────────────────
; Pass /DSOURCE_DIR=... on the makensis command line
!ifndef SOURCE_DIR
  !define SOURCE_DIR "/Users/Work-Abdullah/Desktop/vscodium/VSCode-win32-x64"
!endif

; ─── Icon ───────────────────────────────────────────────────────
!ifndef ICON_PATH
  !define ICON_PATH "/Users/Work-Abdullah/Desktop/vscodium/vscode/resources/win32/code.ico"
!endif

; ─── Output ─────────────────────────────────────────────────────
OutFile "/Users/Work-Abdullah/Desktop/vscodium/installer-output/LascoSetup-${APP_VERSION}-x64.exe"

; ─── Installer settings ────────────────────────────────────────
Name "${APP_NAME}"
InstallDir "$LOCALAPPDATA\Programs\${APP_DIR_NAME}"
InstallDirRegKey HKCU "${APP_REG_KEY}" "InstallPath"
RequestExecutionLevel user
SetCompressor /SOLID lzma
SetCompressorDictSize 64
BrandingText "${APP_NAME} ${APP_VERSION}"

; ─── Modern UI configuration ───────────────────────────────────
!define MUI_ICON "${ICON_PATH}"
!define MUI_UNICON "${ICON_PATH}"
!define MUI_ABORTWARNING

; ─── Pages ──────────────────────────────────────────────────────
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY

; Custom options page
Var CheckboxDesktop
Var CheckboxPath
Var CheckboxContextMenu

Page custom OptionsPageCreate OptionsPageLeave

!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APP_NAME}"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; ─── Language ───────────────────────────────────────────────────
!insertmacro MUI_LANGUAGE "English"

; ─── Custom options page ────────────────────────────────────────
Function OptionsPageCreate
  !insertmacro MUI_HEADER_TEXT "Installation Options" "Choose additional tasks."
  nsDialogs::Create 1018
  Pop $0
  ${If} $0 == error
    Abort
  ${EndIf}

  ${NSD_CreateCheckbox} 0 0 100% 12u "Create a desktop shortcut"
  Pop $CheckboxDesktop
  ${NSD_Check} $CheckboxDesktop

  ${NSD_CreateCheckbox} 0 20u 100% 12u "Add ${APP_NAME} to PATH"
  Pop $CheckboxPath
  ${NSD_Check} $CheckboxPath

  ${NSD_CreateCheckbox} 0 40u 100% 12u 'Add "Open with ${APP_NAME}" to Explorer context menu'
  Pop $CheckboxContextMenu

  nsDialogs::Show
FunctionEnd

Function OptionsPageLeave
FunctionEnd

; ─── Install section ────────────────────────────────────────────
Section "Install"
  ; Install Visual C++ 2015-2022 Redistributable (required by Electron)
  DetailPrint "Installing Visual C++ Redistributable..."
  SetOutPath "$TEMP"
  File "vc_redist.x64.exe"
  ExecWait '"$TEMP\vc_redist.x64.exe" /install /quiet /norestart' $0
  DetailPrint "Visual C++ Redistributable installer returned: $0"
  Delete "$TEMP\vc_redist.x64.exe"

  ; Copy the entire app tree
  SetOutPath "$INSTDIR"
  File /r "${SOURCE_DIR}\*.*"

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Registry: install path
  WriteRegStr HKCU "${APP_REG_KEY}" "InstallPath" "$INSTDIR"

  ; Registry: Add/Remove Programs entry
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayName"     "${APP_NAME}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayIcon"     "$INSTDIR\${APP_EXE}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "Publisher"        "${APP_PUBLISHER}"
  WriteRegStr   HKCU "${UNINSTALL_KEY}" "DisplayVersion"   "${APP_VERSION}"
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1

  ; Calculate installed size
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "EstimatedSize" $0

  ; Start Menu shortcut
  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut  "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
  CreateShortCut  "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\uninstall.exe"

  ; Desktop shortcut (if checked)
  ${NSD_GetState} $CheckboxDesktop $0
  ${If} $0 == ${BST_CHECKED}
    CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
  ${EndIf}

  ; Add to PATH (if checked)
  ${NSD_GetState} $CheckboxPath $0
  ${If} $0 == ${BST_CHECKED}
    ; Add bin directory to user PATH
    ReadRegStr $1 HKCU "Environment" "Path"
    ${If} $1 == ""
      WriteRegExpandStr HKCU "Environment" "Path" "$INSTDIR\bin"
    ${Else}
      WriteRegExpandStr HKCU "Environment" "Path" "$1;$INSTDIR\bin"
    ${EndIf}
    ; Notify the system of environment change
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  ${EndIf}

  ; Explorer context menu (if checked)
  ${NSD_GetState} $CheckboxContextMenu $0
  ${If} $0 == ${BST_CHECKED}
    ; "Open with Lasco" for files
    WriteRegStr HKCU "Software\Classes\*\shell\${APP_NAME}" "" "Open with ${APP_NAME}"
    WriteRegStr HKCU "Software\Classes\*\shell\${APP_NAME}" "Icon" '"$INSTDIR\${APP_EXE}"'
    WriteRegStr HKCU "Software\Classes\*\shell\${APP_NAME}\command" "" '"$INSTDIR\${APP_EXE}" "%1"'

    ; "Open with Lasco" for directories
    WriteRegStr HKCU "Software\Classes\Directory\shell\${APP_NAME}" "" "Open with ${APP_NAME}"
    WriteRegStr HKCU "Software\Classes\Directory\shell\${APP_NAME}" "Icon" '"$INSTDIR\${APP_EXE}"'
    WriteRegStr HKCU "Software\Classes\Directory\shell\${APP_NAME}\command" "" '"$INSTDIR\${APP_EXE}" "%1"'

    ; "Open with Lasco" for directory backgrounds
    WriteRegStr HKCU "Software\Classes\Directory\Background\shell\${APP_NAME}" "" "Open with ${APP_NAME}"
    WriteRegStr HKCU "Software\Classes\Directory\Background\shell\${APP_NAME}" "Icon" '"$INSTDIR\${APP_EXE}"'
    WriteRegStr HKCU "Software\Classes\Directory\Background\shell\${APP_NAME}\command" "" '"$INSTDIR\${APP_EXE}" "%V"'
  ${EndIf}

SectionEnd

; ─── Uninstall section ──────────────────────────────────────────
Section "Uninstall"
  ; Close running instance
  ; (NSIS can't easily signal a named mutex, so we just proceed)

  ; Remove files
  RMDir /r "$INSTDIR"

  ; Remove Start Menu shortcuts
  RMDir /r "$SMPROGRAMS\${APP_NAME}"

  ; Remove desktop shortcut
  Delete "$DESKTOP\${APP_NAME}.lnk"

  ; Remove from PATH
  ReadRegStr $0 HKCU "Environment" "Path"
  ${If} $0 != ""
    ; Simple removal — replace ";$INSTDIR\bin" and "$INSTDIR\bin;" with ""
    ${WordReplace} $0 ";$INSTDIR\bin" "" "+" $0
    ${WordReplace} $0 "$INSTDIR\bin;" "" "+" $0
    ${WordReplace} $0 "$INSTDIR\bin"  "" "+" $0
    WriteRegExpandStr HKCU "Environment" "Path" $0
    SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000
  ${EndIf}

  ; Remove context menu entries
  DeleteRegKey HKCU "Software\Classes\*\shell\${APP_NAME}"
  DeleteRegKey HKCU "Software\Classes\Directory\shell\${APP_NAME}"
  DeleteRegKey HKCU "Software\Classes\Directory\Background\shell\${APP_NAME}"

  ; Remove registry keys
  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  DeleteRegKey HKCU "${APP_REG_KEY}"

SectionEnd
