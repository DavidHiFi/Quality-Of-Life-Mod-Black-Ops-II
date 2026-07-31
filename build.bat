@echo off
REM ============================================================
REM  zm_expanded_deathmachine  -  BUILD & DEPLOY
REM ------------------------------------------------------------
REM  Edit any script under scripts\zm\ then double-click this.
REM  Rebuilds mod.iwd and writes all 6 mod files to:
REM    1) a send-ready copy:  <project>\build\zm_expanded_deathmachine\
REM    2) your Plutonium mods folder (skipped if Plutonium isn't installed)
REM  Needs only Windows + PowerShell (both built in) - no other tools.
REM ============================================================
setlocal EnableExtensions
cd /d "%~dp0"
set "MOD_NAME=zm_qol"
set "FILES=mod.ff mod.iwd mod.json mod.all.sabl mod.all.sabs deathmachine_zm.all.sabl"
set "STAMP_FILES=%FILES%"

REM --- find PowerShell (fall back to the full system path if not on PATH) ---
set "PS=powershell.exe"
where powershell.exe >nul 2>nul || set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if /I not "%PS%"=="powershell.exe" if not exist "%PS%" (
    color C & echo. & echo   PowerShell was not found on this PC - cannot build. & pause & exit /b 1
)

REM --- pack_iwd.ps1 must sit next to this .bat ---
if not exist "%~dp0pack_iwd.ps1" (
    color C & echo. & echo   pack_iwd.ps1 is missing next to build.bat - cannot build. & pause & exit /b 1
)

REM --- resolve the project root (parent of this folder) for the send-ready copy ---
for %%I in ("%~dp0..") do set "ROOT=%%~fI"
set "BUILD_DIR=%ROOT%\build\%MOD_NAME%"
set "PLUTO_DIR=%LOCALAPPDATA%\Plutonium\storage\t6\mods\%MOD_NAME%"

echo [1/5] Repacking mod.iwd from raw folders...
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack_iwd.ps1"
if errorlevel 1 goto packfail

echo.
echo [2/5] Verifying all 6 source files are present...
for %%F in (%FILES%) do (
    if exist "%~dp0%%F" ( echo    [ok] %%F ) else ( echo    [MISSING] %%F & goto missing )
)

echo.
echo [3/5] Writing send-ready copy to:
echo        %BUILD_DIR%
call :deploy "%BUILD_DIR%"
if errorlevel 1 goto copyfail

echo.
echo [4/5] Installing to Plutonium (skipped if not installed):
echo        %PLUTO_DIR%
call :deploy "%PLUTO_DIR%"
if errorlevel 1 echo    [skip] couldn't write to Plutonium - the send-ready copy above is still good.

echo.
echo [5/5] Refreshing LUI copies in Plutonium's raw\ folder...
REM  Plutonium searches raw\ BEFORE mod.iwd, so a stale .lua sitting in raw\
REM  silently shadows the one you just packed and your edit appears to do
REM  nothing. Any .lua that exists in BOTH this project and raw\ is refreshed
REM  here. Files only in raw\ are left alone - they are not ours.
set "RAW_DIR=%LOCALAPPDATA%\Plutonium\storage\t6\raw"
set "PROJ_DIR=%~dp0"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$raw=$env:RAW_DIR; $proj=$env:PROJ_DIR; if(-not (Test-Path -LiteralPath $raw)){ Write-Host '    [skip] no raw\ folder - nothing shadows the mod'; exit 0 }; $n=0; Get-ChildItem -LiteralPath (Join-Path $proj 'ui_mp') -Recurse -Filter *.lua -ErrorAction SilentlyContinue | ForEach-Object { $rel=$_.FullName.Substring($proj.Length); $dst=Join-Path $raw $rel; if(Test-Path -LiteralPath $dst){ Copy-Item -LiteralPath $_.FullName -Destination $dst -Force; Write-Host ('    [sync] ' + $rel); $n++ } }; if($n -eq 0){ Write-Host '    [ok] nothing in raw\ shadows this mod' }" 2>nul

echo.
echo Done.
echo   Launch Plutonium T6 ^> Zombies ^> Mods ^> %MOD_NAME%
echo.
pause
exit /b 0

REM ---- copy all 6 files to %1, confirm each landed, stamp build time ----
:deploy
set "DEST=%~1"
if not exist "%DEST%" mkdir "%DEST%" 2>nul
if not exist "%DEST%" ( echo    [FAILED] could not create the folder & exit /b 1 )
for %%F in (%FILES%) do (
    copy /Y "%~dp0%%F" "%DEST%\%%F" >nul 2>nul
    if exist "%DEST%\%%F" ( echo    [ok] %%F ) else ( echo    [FAILED] %%F & exit /b 1 )
)
REM stamp all 6 with the current time - paths passed via env vars so any
REM username/path (spaces, apostrophes, etc.) is safe
set "STAMP_DIR=%DEST%"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$t=Get-Date; foreach($f in $env:STAMP_FILES.Split(' ')){ $p=Join-Path $env:STAMP_DIR $f; if(Test-Path -LiteralPath $p){ (Get-Item -LiteralPath $p).LastWriteTime=$t } }" 2>nul
exit /b 0

:packfail
color C
echo.
echo   FAILED to pack mod.iwd (see the PowerShell error above).
pause
exit /b 1

:missing
color C
echo.
echo   A required mod file is missing from this folder - cannot build.
echo   Expected: %FILES%
pause
exit /b 1

:copyfail
color C
echo.
echo   Could not write the send-ready copy (permissions or disk full?).
pause
exit /b 1
