@echo off
rem ============================================================================
rem  Quality Of Life - one-click LAN launch, mod already loaded
rem
rem  Added 2026-08-26. Double-click this to boot straight into BO2 Zombies
rem  with the mod already running - no MODS menu, no manual pick. LAN /
rem  offline only this session (no online servers or stats); for online play,
rem  start Plutonium normally and pick "Quality Of Life" from Zombies -> Mods
rem  instead.
rem
rem  Needs the installer's "The mod" option to have been run at least once
rem  ("Windows Install.bat" -> The mod). If it hasn't, Plutonium just won't
rem  find anything at mods/zm_qol and will boot without it.
rem ============================================================================

chcp 65001 >nul 2>&1
title Quality Of Life - LAN launch
cd /d "%~dp0"

set "PS1=%~dp0Mod Files\lan-launch.ps1"

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
