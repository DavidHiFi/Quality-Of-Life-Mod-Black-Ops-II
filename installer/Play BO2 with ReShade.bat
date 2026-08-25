@echo off
rem ============================================================================
rem  Quality Of Life - ReShade watchdog launcher
rem
rem  Added 2026-08-26. Double-click this INSTEAD OF opening Plutonium directly
rem  when you want ReShade active. Leave the window it opens running for as
rem  long as you're playing - Plutonium wipes ReShade out of its own folder
rem  every time it starts, and this is what puts it back. Then start Plutonium
rem  and play as normal; you do not need to do anything else here.
rem
rem  Closing this window does not uninstall anything - it just stops watching.
rem
rem  Needs the installer's ReShade option to have been run at least once
rem  ("Windows Install.bat" -> ReShade). If it hasn't, this will say so.
rem ============================================================================

chcp 65001 >nul 2>&1
title Quality Of Life - ReShade watchdog
cd /d "%~dp0"

set "PS1=%~dp0Mod Files\reshade-watchdog.ps1"

if not exist "%PS1%" (
  echo.
  echo   The "Mod Files" folder is missing.
  echo   Unzip the whole download and keep the folders as they came,
  echo   then run this again.
  echo.
  pause
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
if errorlevel 1 pause
exit /b 0
