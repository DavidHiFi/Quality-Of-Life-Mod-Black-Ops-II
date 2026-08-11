@echo off
REM ============================================================
REM  Quality Of Life  -  BUILD & DEPLOY
REM ------------------------------------------------------------
REM  Display name lives in mod.json ("Quality Of Life"); the folder / mod id
REM  stays zm_qol because that is what Plutonium keys the install off.
REM  Edit any script under scripts\zm\ then double-click this.
REM  Rebuilds mod.iwd and writes all 6 mod files to:
REM    1) a send-ready copy:  <project>\build\zm_qol\
REM    2) your Plutonium mods folder (skipped if Plutonium isn't installed)
REM  Needs only Windows + PowerShell (both built in) - no other tools.
REM ============================================================
setlocal EnableExtensions
cd /d "%~dp0"
set "MOD_NAME=zm_qol"
set "FILES=mod.ff mod.iwd mod.json mod.all.sabl mod.all.sabs deathmachine_zm.all.sabl"

REM  OPTFILES is now EMPTY, and cmn_root.all.sabl is deliberately not in it.
REM
REM  The premise was that shipping a stock bank FILE next to the mod would make
REM  Plutonium load the mod's copy. It does not. console_zm.log prints the full
REM  path and MD5 of every bank it opens, and across three separate attempts -
REM  mods\zm_qol\, mods\zm_qol\sound\, storage\t6\sound\ and storage\t6\raw\sound\ -
REM  it loaded the game's own copy every single time:
REM
REM    SOUND Header load success for F:\...\Black Ops II\sound\cmn_root.all.sabl
REM
REM  The rule the log actually shows is ownership, not search order: a bank comes
REM  from the folder of the ZONE THAT DECLARED IT. mod.all and deathmachine_zm.all
REM  load from the mod folder because mod_base.zone declares them; every stock
REM  bank name loads from the game's sound\ folder and nothing else is consulted.
REM  Declaring a stock bank in our zone is the fatal "Attempting to override
REM  asset ... from zone 'mod'" COM_ERROR that made Origins unbootable in v1.21.0.
REM
REM  So there is no mod-contained route for replacement weapon audio, and copying
REM  267 MB into the mod folder on every build achieved nothing. Replacing the
REM  file in the game's own sound\ folder is the only thing that works, and that
REM  is a change to the game install, not to this mod.
set "OPTFILES="
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

echo [1/6] Syncing zone_assets\images -^> images (runtime pixel data)...
REM  T6 keeps image PIXEL DATA in a loose .iwi, not in the fastfile. mod.ff only
REM  carries the material and an image header. An image that is linked but whose
REM  .iwi never reaches mod.iwd draws BLACK - that was the black Diner loading
REM  screen. zone_assets\images\ is the link-time source; images\ is what
REM  pack_iwd.ps1 packs. Copying one to the other here keeps them from drifting.
set "PROJ_DIR=%~dp0"
REM  Keep to PowerShell 2.0-era cmdlets here - build.bat falls back to the system
REM  WindowsPowerShell, which on this machine has no Get-FileHash (that is 4.0+).
REM  These are a handful of small files, so copy unconditionally rather than diff.
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$proj=$env:PROJ_DIR; $src=Join-Path $proj 'zone_assets\images'; $dst=Join-Path $proj 'images'; if(-not (Test-Path -LiteralPath $src)){ Write-Host '    [skip] no zone_assets\images folder'; exit 0 }; if(-not (Test-Path -LiteralPath $dst)){ New-Item -ItemType Directory -Path $dst | Out-Null }; $n=0; Get-ChildItem -LiteralPath $src -Filter *.iwi | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $dst $_.Name) -Force; $n++ }; Write-Host ('    [ok] ' + $n + ' .iwi copied to images\')"
if errorlevel 1 goto packfail

echo.
echo [2/6] Repacking mod.iwd from raw folders...
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack_iwd.ps1"
if errorlevel 1 goto packfail

echo.
echo [3/6] Verifying all 6 source files are present...
for %%F in (%FILES%) do (
    if exist "%~dp0%%F" ( echo    [ok] %%F ) else ( echo    [MISSING] %%F & goto missing )
)

echo.
echo [4/6] Writing send-ready copy to:
echo        %BUILD_DIR%
call :deploy "%BUILD_DIR%"
if errorlevel 1 goto copyfail

echo.
echo [5/6] Installing to Plutonium (skipped if not installed):
echo        %PLUTO_DIR%
call :deploy "%PLUTO_DIR%"
if errorlevel 1 echo    [skip] couldn't write to Plutonium - the send-ready copy above is still good.

echo.
echo [6/6] Refreshing LUI copies in Plutonium's raw\ folder...
REM  Plutonium searches raw\ BEFORE mod.iwd, so a stale .lua sitting in raw\
REM  silently shadows the one you just packed and your edit appears to do
REM  nothing. Any .lua that exists in BOTH this project and raw\ is refreshed
REM  here. Files only in raw\ are left alone - they are not ours.
set "RAW_DIR=%LOCALAPPDATA%\Plutonium\storage\t6\raw"
set "PROJ_DIR=%~dp0"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$raw=$env:RAW_DIR; $proj=$env:PROJ_DIR; if(-not (Test-Path -LiteralPath $raw)){ Write-Host '    [skip] no raw\ folder - nothing shadows the mod'; exit 0 }; $n=0; @('ui_mp','ui') | ForEach-Object { Get-ChildItem -LiteralPath (Join-Path $proj $_) -Recurse -Filter *.lua -ErrorAction SilentlyContinue } | ForEach-Object { $rel=$_.FullName.Substring($proj.Length); $dst=Join-Path $raw $rel; if(Test-Path -LiteralPath $dst){ Copy-Item -LiteralPath $_.FullName -Destination $dst -Force; Write-Host ('    [sync] ' + $rel); $n++ } }; if($n -eq 0){ Write-Host '    [ok] nothing in raw\ shadows this mod' }" 2>nul

echo.
echo [7/7] Reconciling Plutonium's loose scripts\ folder...
REM  🛑 THIS ONE COST SIX BOOTS AND FOUR CRASHES, 2026-08-11.
REM
REM  %%LOCALAPPDATA%%\Plutonium\storage\t6\scripts\ is loaded GLOBALLY and takes
REM  precedence over the .gsc packed in mod.iwd - exactly like raw\ does for
REM  .lua in step [6/6]. Something (the BO2 Mod Manager's Deploy button is the
REM  likely candidate) had left 46 loose copies of this mod's scripts there.
REM  They were HOURS stale, so every script fix deployed into mod.iwd was
REM  silently ignored: a bisect dvar that "did nothing", a set of deleted files
REM  that kept throwing their compile error, and a crash point that never moved
REM  no matter what was changed.
REM
REM  Two rules, and the difference matters:
REM    - a loose script that ALSO exists in this project is REFRESHED, so it can
REM      never be older than what was just packed
REM    - a loose script under scripts\zm\ that this project no longer has is
REM      DELETED, because it can only be a leftover from an earlier deploy of
REM      this same mod, and a deleted source file must not keep running
REM  Anything outside scripts\zm\ is left alone - it is not ours to touch.
set "LOOSE_DIR=%LOCALAPPDATA%\Plutonium\storage\t6\scripts"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$loose=$env:LOOSE_DIR; $proj=$env:PROJ_DIR; if(-not (Test-Path -LiteralPath $loose)){ Write-Host '    [skip] no loose scripts\ folder'; exit 0 }; $s=0; $d=0; Get-ChildItem -LiteralPath $loose -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.gsc','.csc' } | ForEach-Object { $rel=$_.FullName.Substring($loose.Length+1); $src=Join-Path (Join-Path $proj 'scripts') $rel; if(Test-Path -LiteralPath $src){ Copy-Item -LiteralPath $src -Destination $_.FullName -Force; $s++ } elseif($rel -like 'zm\*'){ Remove-Item -LiteralPath $_.FullName -Force; Write-Host ('    [stale] removed ' + $rel); $d++ } }; Write-Host ('    ' + $s + ' refreshed, ' + $d + ' stale removed')" 2>nul

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
REM optional banks: copy when present, stay silent when not
for %%F in (%OPTFILES%) do (
    if exist "%~dp0%%F" (
        copy /Y "%~dp0%%F" "%DEST%\%%F" >nul 2>nul
        if exist "%DEST%\%%F" ( echo    [ok] %%F ^(optional^) ) else ( echo    [FAILED] %%F & exit /b 1 )
    )
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
