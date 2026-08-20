@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Quality Of Life - installer

rem ============================================================================
rem  Quality Of Life (zm_qol) - Plutonium T6 installer
rem
rem  One script. Every question is a plain yes/no. Nothing is left running in
rem  the background afterwards, and NO game files are ever touched - everything
rem  this installer writes lives under %LOCALAPPDATA%\Plutonium.
rem
rem  Hidden switch for testing:   "Install Quality Of Life.bat" /dryrun
rem  ...prints every action and writes nothing at all.
rem ============================================================================

set "REPO=DavidHiFi/zm_qol"
set "MODID=zm_qol"
set "MODNAME=Quality Of Life"

set "DRYRUN=0"
if /i "%~1"=="/dryrun"   set "DRYRUN=1"
if /i "%~1"=="--dry-run" set "DRYRUN=1"

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "PLUTO=%LOCALAPPDATA%\Plutonium"
set "T6=%PLUTO%\storage\t6"
set "MODDIR=%T6%\mods\%MODID%"
set "IMGDIR=%T6%\images"
set "ZONEDIR=%T6%\zone"
set "BINDIR=%PLUTO%\bin"
set "TMPDIR=%TEMP%\zm_qol_installer"

rem --- the five files the mod is made of, and nothing else --------------------
set "MODFILES=mod.ff mod.iwd mod.json mod.all.sabl mod.all.sabs"

set "PS=powershell -NoProfile -ExecutionPolicy Bypass -Command"

cls
echo.
echo  ============================================================
echo    %MODNAME%  -  installer for Plutonium T6 (Black Ops II)
echo  ============================================================
echo.
if "%DRYRUN%"=="1" echo    *** DRY RUN - nothing will be written ***
if "%DRYRUN%"=="1" echo.

rem ---------------------------------------------------------------- checks ---
if not exist "%PLUTO%" (
  echo    Plutonium was not found here:
  echo      %PLUTO%
  echo.
  echo    Install Plutonium and run it once, then run this again.
  goto :bail
)
echo    Plutonium found:  %PLUTO%

tasklist /fi "imagename eq plutonium-launcher-win32.exe" 2>nul | find /i "plutonium" >nul
if not errorlevel 1 goto :running
tasklist /fi "imagename eq plutonium-bootstrapper-win32.exe" 2>nul | find /i "plutonium" >nul
if not errorlevel 1 goto :running
tasklist /fi "imagename eq t6zm.exe" 2>nul | find /i "t6zm" >nul
if not errorlevel 1 goto :running
goto :notrunning
:running
echo.
echo    *** Plutonium or the game is RUNNING. Close it first, or the files
echo        cannot be replaced. ***
echo.
:notrunning
echo.

rem ------------------------------------------------------ find the payloads --
call :findmod
call :findpayload images  IMAGESRC
call :findpayload zone    ZONESRC
call :findpayload reshade RESHADESRC

rem ------------------------------------------------------------ questions ----
echo   ------------------------------------------------------------
echo    Answer each question with Y or N.
echo   ------------------------------------------------------------
echo.

set "DO_UPDATE=N"
echo    [1] Check GitHub for a newer version of the mod?
echo        If there is one it is downloaded and installed instead of the
echo        copy in this folder.
call :ask "        Check for updates" N DO_UPDATE
echo.

set "DO_MOD=Y"
if not defined MODSRC (
  echo    [2] The mod files are not in this folder, so there is nothing to
  echo        install from disk. Answer Y to question 1 to download them.
  set "DO_MOD=N"
) else (
  echo    [2] Install / update the mod itself?
  echo        Goes to: %MODDIR%
  call :ask "        Install the mod" Y DO_MOD
)
echo.

set "DO_CLEAN=N"
if /i "%DO_MOD%"=="Y" if exist "%MODDIR%\mod.json" (
  echo    [3] Delete the old version first, for a clean install?
  echo        Removes the old mod files from %MODDIR%
  echo        Your saved settings are NOT in there and are never touched, and
  echo        neither are your other mods, your logs, or the game itself.
  call :ask "        Clean install" Y DO_CLEAN
  echo.
)

set "DO_IMAGES=N"
echo    [4] Install the HD texture pack?
echo        Goes to: %IMGDIR%
echo        *** WARNING: this OVERWRITES any custom textures you already
echo            have in that folder. The game's own files are not touched. ***
if not defined IMAGESRC echo        ^(not in this folder - it would be downloaded^)
call :ask "        Install textures" N DO_IMAGES
echo.

set "DO_ZONE=N"
echo    [5] Install the custom sound pack?
echo        Goes to: %ZONEDIR%
echo        *** WARNING: this REPLACES any custom sounds you already have in
echo            that folder. The game's own sound files are not touched. ***
if not defined ZONESRC echo        ^(not in this folder - it would be downloaded^)
call :ask "        Install sounds" N DO_ZONE
echo.

set "DO_RESHADE=N"
echo    [6] Install ReShade for Plutonium, with the mod's BO2 preset?
echo        Goes to: %BINDIR%
echo        Press HOME in game to open it. Nothing is left running in the
echo        background, and it can be removed again by deleting dxgi.dll.
if not defined RESHADESRC (
  echo        ^(the ReShade files are not in this package - cannot install^)
) else (
  call :ask "        Install ReShade" N DO_RESHADE
)
echo.

rem -------------------------------------------------------------- summary ----
echo   ------------------------------------------------------------
echo    About to do this:
echo   ------------------------------------------------------------
set "ANY=0"
if /i "%DO_UPDATE%"=="Y"  (echo      - check GitHub for a newer release) & set "ANY=1"
if /i "%DO_CLEAN%"=="Y"   (echo      - delete the old copy of the mod)    & set "ANY=1"
if /i "%DO_MOD%"=="Y"     (echo      - install the mod)                   & set "ANY=1"
if /i "%DO_IMAGES%"=="Y"  (echo      - install the texture pack   [overwrites custom textures]) & set "ANY=1"
if /i "%DO_ZONE%"=="Y"    (echo      - install the sound pack     [replaces custom sounds])     & set "ANY=1"
if /i "%DO_RESHADE%"=="Y" (echo      - install ReShade + the BO2 preset)  & set "ANY=1"
echo.
if "%ANY%"=="0" (
  echo    Nothing selected, so there is nothing to do.
  goto :bail
)
set "GO=N"
call :ask "     Go ahead" Y GO
if /i not "%GO%"=="Y" (
  echo.
  echo    Cancelled. Nothing was changed.
  goto :bail
)
echo.

rem ===========================================================================
rem  DO THE WORK
rem ===========================================================================
if /i "%DO_UPDATE%"=="Y"  call :update
if /i "%DO_CLEAN%"=="Y"   call :cleanmod
if /i "%DO_MOD%"=="Y"     call :installmod
if /i "%DO_IMAGES%"=="Y"  call :installimages
if /i "%DO_ZONE%"=="Y"    call :installzone
if /i "%DO_RESHADE%"=="Y" call :installreshade

echo.
echo  ============================================================
echo    Done.
echo.
echo    Launch Plutonium T6  -  Zombies  -  Mods  -  %MODNAME%
if /i "%DO_RESHADE%"=="Y" echo    ReShade: press HOME in game to open the overlay.
echo  ============================================================
goto :bail


rem ===========================================================================
rem  HELPERS
rem ===========================================================================

:ask
rem  %1 = prompt   %2 = default (Y/N)   %3 = name of variable to set
setlocal
set "P=%~1"
set "D=%~2"
:askagain
if /i "%D%"=="Y" (set "H=[Y/n]") else (set "H=[y/N]")
set "A="
set /p "A=%P% %H%? "
if not defined A set "A=%D%"
if /i "%A%"=="YES" set "A=Y"
if /i "%A%"=="NO"  set "A=N"
if /i "%A%"=="Y" goto :askdone
if /i "%A%"=="N" goto :askdone
echo        Please answer Y or N.
goto :askagain
:askdone
endlocal & set "%~3=%A%"
exit /b 0


:findmod
rem  The five mod files: release layout first, then the source-tree layout.
set "MODSRC="
if exist "%HERE%\%MODID%\mod.json"     set "MODSRC=%HERE%\%MODID%"
if not defined MODSRC if exist "%HERE%\mod.json"       set "MODSRC=%HERE%"
if not defined MODSRC if exist "%HERE%\..\mod.json" for %%I in ("%HERE%\..") do set "MODSRC=%%~fI"
if defined MODSRC echo    Mod files found:  %MODSRC%
exit /b 0


:findpayload
rem  %1 = folder name (images / zone / reshade)   %2 = variable to set
rem  Only ever looks inside an "Optional(s)" or "installer" folder, so it can
rem  never pick up a same-named folder that belongs to something else.
set "%~2="
for %%P in (
  "%HERE%\Optional\%~1"
  "%HERE%\Optionals\%~1"
  "%HERE%\installer\%~1"
  "%HERE%\..\Optional\%~1"
  "%HERE%\..\Optionals\%~1"
  "%HERE%\..\installer\%~1"
) do (
  if not defined %~2 if exist "%%~P\*" set "%~2=%%~fP"
)
exit /b 0


:readversion
rem  Reads mod.json's version into VERFOUND.
rem  Plutonium's field looks like   "version": "^31.99.96"
rem  - the leading ^ is Plutonium's marker and the leading 3 is this mod's
rem  major, so the human version (the one the GitHub tags use) is what is left
rem  after both are removed. Done in plain batch: a PowerShell one-liner with
rem  embedded quotes cannot survive a FOR /F command line.
set "VERFOUND="
if not exist "%~1" exit /b 0
set "RAW="
for /f "tokens=2 delims=:" %%V in ('findstr /i "version" "%~1"') do set "RAW=%%V"
if not defined RAW exit /b 0
set RAW=!RAW:"=!
set RAW=!RAW: =!
set RAW=!RAW:,=!
if "!RAW:~0,1!"=="^" set "RAW=!RAW:~1!"
if "!RAW:~0,3!"=="31." set "RAW=!RAW:~1!"
set "VERFOUND=!RAW!"
exit /b 0


:cleanmod
rem  Removes the OLD MOD FILES only - every .ff .iwd .json .sabl .sabs in the
rem  mod's own folder. It deliberately leaves everything else alone, because
rem  the game writes its logs (games_mp.log, console_zm.log) into this same
rem  folder and those are not ours to delete. Your saved settings are not here
rem  at all - they live in storage\t6\players\mods\zm_qol\.
echo   [clean]   Removing the old mod files from %MODDIR%
if not exist "%MODDIR%" exit /b 0
for %%E in (ff iwd json sabl sabs) do (
  for %%X in ("%MODDIR%\*.%%E") do (
    if "%DRYRUN%"=="1" (
      echo             would delete %%~nxX
    ) else (
      del /f /q "%%~fX" >nul 2>&1
    )
  )
)
if "%DRYRUN%"=="0" echo             old mod files removed ^(logs and settings kept^).
exit /b 0


:installmod
echo   [mod]     Installing the mod...
if not defined MODSRC (
  echo             ERROR: the mod files were not found. Nothing installed.
  exit /b 1
)
set "MISSING="
for %%F in (%MODFILES%) do if not exist "%MODSRC%\%%F" set "MISSING=!MISSING! %%F"
if defined MISSING (
  echo             ERROR: the package is incomplete, missing:!MISSING!
  echo             Nothing was installed. Download the release again.
  exit /b 1
)
if "%DRYRUN%"=="1" (
  for %%F in (%MODFILES%) do echo             would copy %%F
  exit /b 0
)
if not exist "%MODDIR%" mkdir "%MODDIR%" >nul 2>&1
set "FAILED="
for %%F in (%MODFILES%) do (
  copy /y "%MODSRC%\%%F" "%MODDIR%\%%F" >nul
  if errorlevel 1 (
    echo             FAILED to copy %%F
    set "FAILED=1"
  ) else (
    echo             %%F
  )
)
if defined FAILED (
  echo             Some files could not be written. Close Plutonium and retry.
  exit /b 1
)
rem  A leftover mod file from an older version - deathmachine_zm.all.sabl is the
rem  real example - would still be loaded, so take it out. Only ever touches the
rem  five extensions the mod itself uses: the game writes its logs into this
rem  same folder and those are not ours to delete.
for %%E in (ff iwd json sabl sabs) do (
  for %%X in ("%MODDIR%\*.%%E") do (
    set "KEEP=0"
    for %%F in (%MODFILES%) do if /i "%%~nxX"=="%%F" set "KEEP=1"
    if "!KEEP!"=="0" (
      echo             removing file left over from an older version: %%~nxX
      del /f /q "%%~fX" >nul 2>&1
    )
  )
)
call :readversion "%MODDIR%\mod.json"
if defined VERFOUND echo             installed version: !VERFOUND!
exit /b 0


:installimages
echo   [images]  Installing the texture pack...
if not defined IMAGESRC call :getasset "zm_qol-textures.zip" images IMAGESRC
if not defined IMAGESRC (
  echo             Skipped - the texture pack is not in this package and is
  echo             not attached to the latest GitHub release.
  exit /b 1
)
if "%DRYRUN%"=="1" (
  echo             would copy "%IMAGESRC%" into "%IMGDIR%"
  exit /b 0
)
if not exist "%IMGDIR%" mkdir "%IMGDIR%" >nul 2>&1
robocopy "%IMAGESRC%" "%IMGDIR%" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (echo             FAILED - some files could not be copied.) else (echo             done.)
exit /b 0


:installzone
echo   [sounds]  Installing the sound pack...
if not defined ZONESRC call :getasset "zm_qol-sounds.zip" zone ZONESRC
if not defined ZONESRC (
  echo             Skipped - the sound pack is not in this package and is
  echo             not attached to the latest GitHub release.
  exit /b 1
)
if "%DRYRUN%"=="1" (
  echo             would copy "%ZONESRC%" into "%ZONEDIR%"
  exit /b 0
)
if not exist "%ZONEDIR%" mkdir "%ZONEDIR%" >nul 2>&1
robocopy "%ZONESRC%" "%ZONEDIR%" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (echo             FAILED - some files could not be copied.) else (echo             done.)
exit /b 0


:installreshade
echo   [reshade] Installing ReShade into %BINDIR%
if not defined RESHADESRC (
  echo             Skipped - the ReShade files are not in this package.
  exit /b 1
)
if "%DRYRUN%"=="1" (
  echo             would back up any existing ReShade.ini / BO2.ini
  echo             would copy "%RESHADESRC%" into "%BINDIR%"
  exit /b 0
)
for %%F in (ReShade.ini BO2.ini) do (
  if exist "%BINDIR%\%%F" (
    copy /y "%BINDIR%\%%F" "%BINDIR%\%%F.backup" >nul
    echo             your existing %%F was saved as %%F.backup
  )
)
robocopy "%RESHADESRC%" "%BINDIR%" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (
  echo             FAILED - close Plutonium and try again ^(dxgi.dll is in use^).
  exit /b 1
)
echo             done. Press HOME in game to open the ReShade overlay.
exit /b 0


:update
echo   [update]  Asking GitHub for the latest release...
set "LATEST="
for /f "usebackq delims=" %%A in (`%PS% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try{(Invoke-RestMethod 'https://api.github.com/repos/%REPO%/releases/latest' -Headers @{'User-Agent'='zm_qol-installer'}).tag_name}catch{''}"`) do set "LATEST=%%A"
if not defined LATEST (
  echo             Could not reach GitHub. Carrying on with the local copy.
  exit /b 1
)
echo             latest release: !LATEST!
call :readversion "%MODDIR%\mod.json"
if defined VERFOUND echo             you have:       !VERFOUND!
set "TAGVER=!LATEST:v=!"
rem  Only take the download if it is actually NEWER. The release can lag behind
rem  the build you already have, and a "check for updates" that quietly puts an
rem  older mod back would be worse than doing nothing.
if defined VERFOUND (
  set "CMP="
  set "V_A=!TAGVER!"
  set "V_B=!VERFOUND!"
  for /f "usebackq delims=" %%C in (`%PS% "try{$a=[version]$env:V_A; $b=[version]$env:V_B; if($a -gt $b){'NEWER'}elseif($a -eq $b){'SAME'}else{'OLDER'}}catch{'UNKNOWN'}"`) do set "CMP=%%C"
  if /i "!CMP!"=="SAME"  echo             You already have the latest release.
  if /i "!CMP!"=="OLDER" echo             Your copy is NEWER than the latest release.
  if /i not "!CMP!"=="NEWER" (
    set "AGAIN=N"
    call :ask "            Download and install the release version anyway" N AGAIN
    if /i not "!AGAIN!"=="Y" exit /b 0
  )
)
if "%DRYRUN%"=="1" (
  echo             would download !LATEST! and install it
  exit /b 0
)
set "URL="
for /f "usebackq delims=" %%A in (`%PS% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try{$r=Invoke-RestMethod 'https://api.github.com/repos/%REPO%/releases/latest' -Headers @{'User-Agent'='zm_qol-installer'}; ($r.assets | Where-Object { $_.name -like '*.zip' -and $_.name -notlike '*texture*' -and $_.name -notlike '*sound*' } | Select-Object -First 1).browser_download_url}catch{''}"`) do set "URL=%%A"
if not defined URL (
  echo             That release has no mod zip attached. Using the local copy.
  exit /b 1
)
if not exist "%TMPDIR%" mkdir "%TMPDIR%" >nul 2>&1
set "ZIP=%TMPDIR%\mod.zip"
if exist "!ZIP!" del /f /q "!ZIP!" >nul 2>&1
echo             downloading...
call :fetch "!URL!" "!ZIP!"
if not exist "!ZIP!" (
  echo             Download failed. Using the local copy.
  exit /b 1
)
echo             unpacking...
if exist "%TMPDIR%\unpack" rd /s /q "%TMPDIR%\unpack" >nul 2>&1
mkdir "%TMPDIR%\unpack" >nul 2>&1
call :unzip "!ZIP!" "%TMPDIR%\unpack"
set "NEWSRC="
if exist "%TMPDIR%\unpack\%MODID%\mod.json" set "NEWSRC=%TMPDIR%\unpack\%MODID%"
if not defined NEWSRC if exist "%TMPDIR%\unpack\mod.json" set "NEWSRC=%TMPDIR%\unpack"
if not defined NEWSRC (
  echo             The download did not contain the mod. Using the local copy.
  exit /b 1
)
set "MODSRC=!NEWSRC!"
set "DO_MOD=Y"
echo             !LATEST! downloaded - this is what will be installed.
exit /b 0


:getasset
rem  %1 = asset file name   %2 = folder name inside it   %3 = variable to set
echo             not in this folder - looking on GitHub...
set "AURL="
for /f "usebackq delims=" %%A in (`%PS% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try{$r=Invoke-RestMethod 'https://api.github.com/repos/%REPO%/releases/latest' -Headers @{'User-Agent'='zm_qol-installer'}; ($r.assets | Where-Object { $_.name -eq '%~1' }).browser_download_url}catch{''}"`) do set "AURL=%%A"
if not defined AURL exit /b 1
if "%DRYRUN%"=="1" (
  echo             would download %~1
  exit /b 1
)
if not exist "%TMPDIR%" mkdir "%TMPDIR%" >nul 2>&1
echo             downloading %~1 ...
call :fetch "!AURL!" "%TMPDIR%\%~1"
if not exist "%TMPDIR%\%~1" exit /b 1
if exist "%TMPDIR%\%~2" rd /s /q "%TMPDIR%\%~2" >nul 2>&1
mkdir "%TMPDIR%\%~2" >nul 2>&1
call :unzip "%TMPDIR%\%~1" "%TMPDIR%\%~2"
if exist "%TMPDIR%\%~2\%~2\*" (set "%~3=%TMPDIR%\%~2\%~2") else (set "%~3=%TMPDIR%\%~2")
exit /b 0


:fetch
rem  %1 = url   %2 = output file
where curl.exe >nul 2>&1
if not errorlevel 1 (
  curl.exe -L --fail --progress-bar -o "%~2" "%~1"
  exit /b %errorlevel%
)
%PS% "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try{Invoke-WebRequest '%~1' -OutFile '%~2' -UseBasicParsing}catch{exit 1}"
exit /b %errorlevel%


:unzip
rem  %1 = zip file   %2 = destination folder
where tar.exe >nul 2>&1
if not errorlevel 1 (
  tar.exe -xf "%~1" -C "%~2"
  if not errorlevel 1 exit /b 0
)
%PS% "try{Expand-Archive -LiteralPath '%~1' -DestinationPath '%~2' -Force}catch{exit 1}"
exit /b %errorlevel%


:bail
echo.
pause
endlocal
exit /b 0
