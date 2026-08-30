@echo off
rem ============================================================================
rem  Quality Of Life - one-click LAN launch, mod + ReShade watchdog
rem
rem  Added 2026-08-26. Same as "Play BO2 with mod (LAN).bat" but also starts
rem  the ReShade watchdog in its own window first, so ReShade is being
rem  restored the moment Plutonium opens. Leave that second window running
rem  for as long as you're playing. LAN / offline only this session.
rem
rem  Needs the installer's "The mod" AND "ReShade" options to have been run
rem  at least once first.
rem ============================================================================

chcp 65001 >nul 2>&1
title Quality Of Life - LAN launch + ReShade
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

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Watchdog %*
if errorlevel 1 pause
exit /b 0
