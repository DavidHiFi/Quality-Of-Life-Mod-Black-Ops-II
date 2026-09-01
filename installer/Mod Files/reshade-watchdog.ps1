<#
================================================================================
  Quality Of Life (zm_qol) - ReShade watchdog for Plutonium T6

  Added 2026-08-26. Launched by "..\Play BO2 with ReShade.bat", which sits next
  to "Windows Install.bat". Leave that window open for as long as you want
  ReShade active, then start Plutonium and play as normal.

  WHY THIS EXISTS: Plutonium's own launcher clears any file out of its "bin"
  folder that it does not recognise, every time it starts - and ReShade's
  dxgi.dll and its presets are exactly that kind of file. Copying them in once
  (which is all the installer's own "ReShade" option can do) does not survive
  the next time Plutonium opens. This script watches for Plutonium, and the
  moment it appears, puts back anything ReShade that is now missing.

  It NEVER overwrites a file that is already there - only files Plutonium
  actually deleted are restored - so your in-game ReShade tweaks and whichever
  preset you last picked (Ctrl+Shift+PgUp / PgDn) are never touched.

  Its source of truth is the "reshade-vault" folder the installer's ReShade
  option fills in under Plutonium's own storage, NOT the downloaded zip - so
  this keeps working even if that zip is long deleted. See qol-installer.ps1's
  Act-InstallReShade for the matching path; the two must agree or this has
  nothing to restore from.

  Closing this window (or Ctrl+C) does not uninstall anything. It just stops
  watching - ReShade stays until Plutonium next clears it.
================================================================================
#>

param(
    [string] $PlutoRoot   = (Join-Path $env:LOCALAPPDATA 'Plutonium'),
    [int]    $PollSeconds = 2
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$BinDir   = Join-Path $PlutoRoot 'bin'
# 🛑 Must match $RESHADE_VAULT in qol-installer.ps1 exactly - see that file's
# Act-InstallReShade for the writer side of this path.
$VaultDir = Join-Path $PlutoRoot 'storage\t6\_zm_qol_installer\reshade-vault'

# Every executable Plutonium can put a game process behind, taken from a
# separate resident ReShade helper's own process-detection list -
# already proven correct across real sessions, not guessed here. One shared
# bin folder serves all of them.
$ProcNames = @('plutonium-bootstrapper-win32','t6zm','t6mp','t6sp','t5mp','t5sp','t4mp','t4sp','iw5mp')

function Test-AnyProcess {
    param([string[]] $Names)
    foreach ($n in $Names) {
        if (Get-Process -Name $n -ErrorAction SilentlyContinue) { return $true }
    }
    return $false
}

# Copies from the vault only what is not currently in bin. Never overwrites -
# a file that exists there is either untouched-by-Plutonium or a live edit,
# and either way it is not this script's to replace.
# ---------------------------------------------------------------------------
#  v2.10.3 - NEVER PUT BACK A SECOND COPY OF A SHADER (user, 2026-09-02:
#  "levels.fx reshade shader is being doubled, and i have to keep disabling it
#  after restarting the game").
#
#  Measured on the user's PC: bin\reshade-shaders is ALSO written by
#  RenoDXCommander ("Managed by RDXC.txt" in the folder), which lays the
#  SweetFX pack out as Shaders\SweetFX\SweetFX\*.fx - one level deeper than
#  this mod's payload puts the same files. ReShade.ini searches
#  Shaders\** recursively, so two Levels.fx files become two "Levels"
#  techniques, the preset's Levels@Levels.fx enables both, and the effect runs
#  twice. Disabling one in-game only lasted until this watchdog restored the
#  mod's copy again. Rule now: a .fx from the vault is restored only when NO
#  file of that name exists anywhere under Shaders\. Everything else
#  (dxgi.dll, presets, .fxh includes, textures) restores exactly as before.
# ---------------------------------------------------------------------------
function Get-ShaderNameIndex {
    $idx = @{}
    $shaders = Join-Path $BinDir 'reshade-shaders\Shaders'
    if (Test-Path -LiteralPath $shaders) {
        Get-ChildItem -LiteralPath $shaders -Recurse -File -Filter *.fx -ErrorAction SilentlyContinue | ForEach-Object {
            $idx[$_.Name.ToLower()] = $true
        }
    }
    return $idx
}

function Restore-MissingReShade {
    if (-not (Test-Path -LiteralPath $VaultDir)) {
        Write-Host "  No ReShade vault at $VaultDir yet." -ForegroundColor Yellow
        Write-Host "  Run the installer's ReShade option first, then start this again." -ForegroundColor Yellow
        return -1
    }
    if (-not (Test-Path -LiteralPath $BinDir)) { return 0 }

    $restored = 0
    $shaderNames = $null
    Get-ChildItem -LiteralPath $VaultDir -Recurse -File | ForEach-Object {
        $rel    = $_.FullName.Substring($VaultDir.Length).TrimStart('\')
        $target = Join-Path $BinDir $rel
        if (-not (Test-Path -LiteralPath $target)) {
            if ($_.Extension -eq '.fx' -and $rel -like 'reshade-shaders\Shaders\*') {
                if ($null -eq $shaderNames) { $shaderNames = Get-ShaderNameIndex }
                if ($shaderNames.ContainsKey($_.Name.ToLower())) { return }   # already here under another path - see the note above
                $shaderNames[$_.Name.ToLower()] = $true
            }
            $targetDir = Split-Path -Parent $target
            if (-not (Test-Path -LiteralPath $targetDir)) {
                New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
            }
            Copy-Item -LiteralPath $_.FullName -Destination $target -Force
            $restored++
        }
    }
    return $restored
}

# -----------------------------------------------------------------------------
#  v2.9.3 - THE OTHER HALF: LIVE EDITS NOW GO BACK INTO THE VAULT.
#
#  User, 2026-08-30: they edited "Cinematic Colour Grading.ini" from ReShade's
#  own overlay, saved it, and asked that the mod always start on that preset
#  WITH those edits.
#
#  Restore-MissingReShade alone could not promise that. The vault was written
#  once by the installer and never again, so every in-game tweak lived only in
#  Plutonium's bin - and bin is exactly the folder Plutonium wipes. One wipe and
#  the watchdog faithfully restored the INSTALLER's copy over the top, silently
#  undoing the edit. That is not a hypothetical: the vault copy on this machine
#  was 37 minutes older than the live one when this was written.
#
#  So the sync is now two-way for the settings files only:
#      vault -> bin   anything Plutonium cleared          (Restore-MissingReShade)
#      bin -> vault   any *.ini edited more recently      (Save-LiveEdits)
#
#  🛑 TOP-LEVEL *.ini ONLY, and deliberately so. Those are ReShade.ini and the
#  presets - the only files a player ever edits. Shaders, textures and dxgi.dll
#  are shipped content: copying those back would let a corrupted or
#  half-restored bin overwrite the known-good vault, which is the one copy that
#  can put things right again.
#
#  🛑 A FILE IS ONLY COPIED ONCE IT HAS SETTLED. ReShade writes the preset the
#  instant a slider moves (AutoSavePreset=1), so a poll can easily land
#  mid-write; requiring 3 seconds of no further writes means the vault only ever
#  receives a finished file. Nothing is lost by waiting - the next poll takes it.
# -----------------------------------------------------------------------------
$SettleSeconds = 3

function Save-LiveEdits {
    if (-not (Test-Path -LiteralPath $VaultDir)) { return 0 }
    if (-not (Test-Path -LiteralPath $BinDir))   { return 0 }

    $saved = 0
    Get-ChildItem -LiteralPath $BinDir -File -Filter *.ini | ForEach-Object {
        $vaultCopy = Join-Path $VaultDir $_.Name

        # Only files the vault already knows about. A stray .ini in bin is not
        # ours to adopt.
        if (-not (Test-Path -LiteralPath $vaultCopy)) { return }

        if (((Get-Date) - $_.LastWriteTime).TotalSeconds -lt $SettleSeconds) { return }
        if ($_.LastWriteTime -le (Get-Item -LiteralPath $vaultCopy).LastWriteTime) { return }

        Copy-Item -LiteralPath $_.FullName -Destination $vaultCopy -Force
        Write-Host ("  [{0}] Saved your edit to {1} into the vault - it will survive the next wipe." -f (Get-Date -Format 'HH:mm:ss'), $_.Name) -ForegroundColor Green
        $saved++
    }
    return $saved
}

Write-Host ''
Write-Host '  Quality Of Life - ReShade watchdog' -ForegroundColor Cyan
Write-Host '  ------------------------------------------------------------------' -ForegroundColor Cyan
Write-Host '  Leave this window open the whole time you want ReShade to work.' -ForegroundColor Cyan
Write-Host '  Plutonium clears ReShade out of its own folder every time it starts,' -ForegroundColor Cyan
Write-Host '  and this is what puts it back. Start Plutonium normally now.' -ForegroundColor Cyan
Write-Host '  Closing this window (or Ctrl+C) does not uninstall anything.' -ForegroundColor Cyan
Write-Host '  ------------------------------------------------------------------' -ForegroundColor Cyan
Write-Host ''

if (-not (Test-Path -LiteralPath $VaultDir)) {
    Write-Host "  No ReShade vault found yet at:" -ForegroundColor Red
    Write-Host "    $VaultDir" -ForegroundColor Red
    Write-Host "  Run Windows Install.bat -> ReShade first, then start this again." -ForegroundColor Red
    Write-Host ''
}

# -----------------------------------------------------------------------------
#  v2.3.2 - THE WINDOW SHOWED NOTHING WHILE IT WAS WORKING.
#
#  User, 2026-08-25: "make it include logs in the open window, so you can see
#  what it's actually doing." Before this it only ever wrote a line when it
#  restored a file - which for most of a session is never, since Plutonium only
#  clears bin on its own startup. An open window that prints nothing for an
#  hour reads as frozen or wrong, not as "working correctly and idle".
#
#  Two additions, neither changing what the watchdog DOES:
#    - a state-change line the instant Plutonium/game is first seen or is no
#      longer seen, so the moment that matters is never buried between polls
#    - a heartbeat line every $HeartbeatSeconds while a process IS running,
#      so a long play session still shows the loop is alive and what its last
#      check found, without printing every single 2-second poll.
#  Nothing is printed on a quiet poll before the game has even started -
#  that state already has its own message above, and repeating it every
#  2 seconds would be the same noise problem from the other direction.
# -----------------------------------------------------------------------------
$lastProcState  = $null
$lastHeartbeat  = Get-Date -Year 1970
$HeartbeatSeconds = 15

while ($true) {
    $running = Test-AnyProcess $ProcNames

    if ($running -ne $lastProcState) {
        if ($running) {
            Write-Host ("  [{0}] Plutonium/game process detected - watching bin for cleared files." -f (Get-Date -Format 'HH:mm:ss')) -ForegroundColor Cyan
        } else {
            Write-Host ("  [{0}] No Plutonium/game process running - standing by." -f (Get-Date -Format 'HH:mm:ss')) -ForegroundColor DarkGray
        }
        $lastProcState = $running
        $lastHeartbeat = Get-Date   # the state line above already says this - don't also heartbeat immediately
    }

    if ($running) {
        Save-LiveEdits | Out-Null
        $n = Restore-MissingReShade
        if ($n -gt 0) {
            Write-Host ("  [{0}] Restored {1} ReShade file(s) Plutonium had cleared." -f (Get-Date -Format 'HH:mm:ss'), $n) -ForegroundColor Green
            $lastHeartbeat = Get-Date
        } elseif (((Get-Date) - $lastHeartbeat).TotalSeconds -ge $HeartbeatSeconds) {
            Write-Host ("  [{0}] Watching - bin is intact, nothing to restore." -f (Get-Date -Format 'HH:mm:ss')) -ForegroundColor DarkGray
            $lastHeartbeat = Get-Date
        }
    }

    Start-Sleep -Seconds $PollSeconds
}
