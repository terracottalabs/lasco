@echo off
setlocal
if defined VSCODE_GIT_ASKPASS_NODE (
  if exist "%VSCODE_GIT_ASKPASS_NODE%" (
    set "ELECTRON_RUN_AS_NODE=1"
    "%VSCODE_GIT_ASKPASS_NODE%" %*
    exit /b %errorlevel%
  )
)
where node >nul 2>nul
if %errorlevel% equ 0 (
  node %*
  exit /b %errorlevel%
)
echo Error: No Node.js runtime found. Open this project in LASCO. >&2
exit /b 1
