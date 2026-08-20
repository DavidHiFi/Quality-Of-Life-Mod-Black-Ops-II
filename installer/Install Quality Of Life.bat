@echo off
rem ============================================================================
rem  Quality Of Life (zm_qol) - Plutonium T6 installer
rem
rem  This is only a launcher. The installer itself is qol-installer.ps1, next to
rem  this file, because a menu you can move through with the arrow keys is not
rem  something a .bat can do on its own.
rem
rem  Nothing here needs administrator rights, nothing is left running afterwards,
rem  and no game file is ever touched.
rem ============================================================================

chcp 65001 >nul 2>&1
title Quality Of Life - installer

set "PS1=%~dp0qol-installer.ps1"

if not exist "%PS1%" (
  echo.
  echo   qol-installer.ps1 is missing. It must sit next to this file.
  echo   Unzip the whole download, keeping the folder as it came.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
if errorlevel 1 (
  echo.
  echo   The installer stopped with an error. See installer.log next to this file.
  echo.
  pause
)
exit /b 0
