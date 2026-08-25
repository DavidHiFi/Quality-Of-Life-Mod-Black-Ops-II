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
function Restore-MissingReShade {
    if (-not (Test-Path -LiteralPath $VaultDir)) {
        Write-Host "  No ReShade vault at $VaultDir yet." -ForegroundColor Yellow
        Write-Host "  Run the installer's ReShade option first, then start this again." -ForegroundColor Yellow
        return -1
    }
    if (-not (Test-Path -LiteralPath $BinDir)) { return 0 }

    $restored = 0
    Get-ChildItem -LiteralPath $VaultDir -Recurse -File | ForEach-Object {
        $rel    = $_.FullName.Substring($VaultDir.Length).TrimStart('\')
        $target = Join-Path $BinDir $rel
        if (-not (Test-Path -LiteralPath $target)) {
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
