#!/usr/bin/env bash
# =============================================================================
#  Quality Of Life (zm_qol) - ReShade watchdog for Plutonium T6 on Linux
#
#  Added 2026-08-26, porting the Windows watchdog (reshade-watchdog.ps1) to
#  Wine/Proton/Lutris/Bottles. Same job, same mechanism, same vault - just
#  process detection and file copying done the Linux way.
#
#  Run it:      bash "reshade-watchdog.sh"
#  Point it at a prefix by hand, exactly like the installer:
#               WINEPREFIX=~/Games/plutonium bash "reshade-watchdog.sh"
#
#  WHY THIS EXISTS: Plutonium's own launcher clears any file out of its "bin"
#  folder that it does not recognise, every time it starts - dxgi.dll and the
#  presets are exactly that kind of file, on Linux exactly as much as on
#  Windows, because it is the SAME plutonium-bootstrapper-win32.exe doing the
#  clearing, just running under Wine instead of natively. Installing ReShade
#  once (the installer's own "ReShade" row) does not survive the next launch.
#  This script watches for that launcher, and the moment it appears, puts
#  back anything ReShade that is now missing.
#
#  It NEVER overwrites a file that is already there - only files Plutonium
#  actually deleted are restored - so your in-game ReShade tweaks and
#  whichever preset you last picked (Ctrl+Shift+PgUp / PgDn) are never
#  touched.
#
#  Its source of truth is the "reshade-vault" folder the installer's ReShade
#  option fills in under Plutonium's own storage (inside the Wine prefix),
#  NOT the downloaded zip - so this keeps working even after that zip is long
#  gone. See install-quality-of-life.sh's act_reshade for the writer side of
#  this path; the two must agree or this has nothing to restore from.
#
#  Closing this window (or Ctrl+C) does not uninstall anything. It just stops
#  watching - ReShade stays until Plutonium next clears it.
# =============================================================================

set -uo pipefail

POLL_SECONDS=2
ROOT_OVERRIDE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --root)  ROOT_OVERRIDE="${2:-}"; shift ;;
    --poll)  POLL_SECONDS="${2:-2}"; shift ;;
  esac
  shift
done

if [ -t 1 ]; then
  CY=$'\033[36m'; GN=$'\033[32m'; YE=$'\033[33m'; RD=$'\033[31m'; DIM=$'\033[2m'; R=$'\033[0m'
else
  CY=""; GN=""; YE=""; RD=""; DIM=""; R=""
fi

# --------------------------------------------------------- find Plutonium --
# 🛑 THIS MUST FIND THE SAME PREFIX install-quality-of-life.sh DOES, or the
# vault it reads and the bin it writes to belong to two different installs.
# Copied on purpose rather than sourced - the installer and this script are
# meant to run as two independent processes (this one keeps running for the
# whole play session while the installer has long since exited), so there is
# nothing to source from by the time this matters.
find_prefixes() {
  local c=()
  [ -n "${WINEPREFIX:-}" ] && c+=("$WINEPREFIX")
  c+=("$HOME/.wine")
  c+=("$HOME/Games/plutonium")
  c+=("$HOME/Games/plutonium-t6")
  while IFS= read -r d; do c+=("$d"); done < <(ls -d "$HOME"/.local/share/lutris/prefixes/*/ 2>/dev/null || true)
  while IFS= read -r d; do c+=("$d"); done < <(ls -d "$HOME"/.var/app/com.usebottles.bottles/data/bottles/bottles/*/ 2>/dev/null || true)
  while IFS= read -r d; do c+=("$d"); done < <(ls -d "$HOME"/.steam/steam/steamapps/compatdata/*/pfx/ 2>/dev/null || true)
  printf '%s\n' "${c[@]}"
}
pluto_from_prefix() {
  local pfx="$1" p
  for p in "$pfx"/drive_c/users/*/AppData/Local/Plutonium; do
    [ -d "$p" ] && { printf '%s\n' "$p"; return 0; }
  done
  return 1
}
resolve_pluto() {
  if [ -n "$ROOT_OVERRIDE" ]; then PLUTO="$ROOT_OVERRIDE"; return 0; fi
  local pfx p
  while IFS= read -r pfx; do
    [ -d "$pfx" ] || continue
    if p="$(pluto_from_prefix "$pfx")"; then PLUTO="$p"; return 0; fi
  done < <(find_prefixes)
  PLUTO=""
  return 1
}
resolve_pluto || true

BIN_DIR="$PLUTO/bin"
# 🛑 Must match $VAULT in install-quality-of-life.sh exactly - see that
# file's act_reshade for the writer side of this path.
VAULT_DIR="$PLUTO/storage/t6/_zm_qol_installer/reshade-vault"

# Every executable Plutonium can put a game process behind. Same list as the
# Windows watchdog's $ProcNames - it is the SAME binaries, just under Wine.
PROC_NAMES=(plutonium-bootstrapper-win32 t6zm t6mp t6sp t5mp t5sp t4mp t4sp iw5mp)

# ---------------------------------------------------------------------------
#  🛑 PROCESS DETECTION IS NOT Get-Process HERE. Wine runs each Windows
#  process as its own Linux process, but what shows up in `ps` for its NAME
#  varies by Wine version and how it was launched (some show "wine64-
#  preloader", some rename via prctl to the module's own basename truncated
#  to 15 chars). Matching the FULL command line (`pgrep -f`, not `-x`) is
#  what is reliable across Wine/Proton/Lutris/Bottles alike, because the
#  .exe name always appears somewhere in argv - either as the wine command's
#  own argument or as the renamed comm.
# ---------------------------------------------------------------------------
#  pgrep (procps) is on essentially every desktop Linux distro, but not
#  guaranteed on a minimal one - fall back to `ps` (POSIX, always present)
#  rather than assume it, same spirit as the installer falling back to `cp`
#  when `rsync` is missing.
if command -v pgrep >/dev/null 2>&1; then
  is_plutonium_running() {
    local n
    for n in "${PROC_NAMES[@]}"; do
      pgrep -fi "$n" >/dev/null 2>&1 && return 0
    done
    return 1
  }
else
  is_plutonium_running() {
    local n
    for n in "${PROC_NAMES[@]}"; do
      ps -eo args 2>/dev/null | grep -qi -- "$n" && return 0
    done
    return 1
  }
fi

# Copies from the vault only what is not currently in bin. Never overwrites -
# a file that exists there is either untouched-by-Plutonium or a live edit,
# and either way it is not this script's to replace.
restore_missing_reshade() {
  if [ ! -d "$VAULT_DIR" ]; then
    printf '  %sNo ReShade vault at %s yet.%s\n' "$YE" "$VAULT_DIR" "$R"
    printf '  %sRun the installer'"'"'s ReShade option first, then start this again.%s\n' "$YE" "$R"
    return 255
  fi
  [ -d "$BIN_DIR" ] || return 0

  local restored=0 f rel target targetdir
  while IFS= read -r -d '' f; do
    rel="${f#"$VAULT_DIR"/}"
    target="$BIN_DIR/$rel"
    if [ ! -e "$target" ]; then
      targetdir="$(dirname "$target")"
      mkdir -p "$targetdir"
      cp -f "$f" "$target"
      restored=$(( restored + 1 ))
    fi
  done < <(find "$VAULT_DIR" -type f -print0)
  printf '%s' "$restored"
}

printf '\n'
printf '  %sQuality Of Life - ReShade watchdog (Linux)%s\n' "$CY" "$R"
printf '  %s------------------------------------------------------------------%s\n' "$CY" "$R"
printf '  %sLeave this terminal open the whole time you want ReShade to work.%s\n' "$CY" "$R"
printf '  %sPlutonium clears ReShade out of its own bin folder every time it%s\n' "$CY" "$R"
printf '  %sstarts, and this is what puts it back. Start Plutonium normally now.%s\n' "$CY" "$R"
printf '  %sClosing this (or Ctrl+C) does not uninstall anything.%s\n' "$CY" "$R"
printf '  %s------------------------------------------------------------------%s\n' "$CY" "$R"
printf '\n'

if [ -z "$PLUTO" ] || [ ! -d "$PLUTO" ]; then
  printf '  %sPlutonium was not found in any Wine prefix on this machine.%s\n' "$RD" "$R"
  printf '  %sRun this with WINEPREFIX=/path/to/your/prefix, or --root <path>.%s\n' "$RD" "$R"
  printf '\n'
fi
if [ ! -d "$VAULT_DIR" ]; then
  printf '  %sNo ReShade vault found yet at:%s\n' "$RD" "$R"
  printf '    %s%s%s\n' "$RD" "$VAULT_DIR" "$R"
  printf '  %sRun install-quality-of-life.sh -> ReShade first, then start this again.%s\n' "$RD" "$R"
  printf '\n'
fi

# Same shape as the Windows watchdog: a state-change line the instant
# Plutonium is first seen or is no longer seen, plus a heartbeat every
# $HEARTBEAT_SECONDS while it IS running, so a long play session still shows
# the loop is alive without printing every single poll.
LAST_STATE=""
LAST_HEARTBEAT=0
HEARTBEAT_SECONDS=15

while true; do
  if is_plutonium_running; then RUNNING=1; else RUNNING=0; fi
  NOW="$(date +%s)"

  if [ "$RUNNING" != "$LAST_STATE" ]; then
    if [ "$RUNNING" -eq 1 ]; then
      printf '  [%s] %sPlutonium/game process detected - watching bin for cleared files.%s\n' "$(date '+%H:%M:%S')" "$CY" "$R"
    else
      printf '  [%s] %sNo Plutonium/game process running - standing by.%s\n' "$(date '+%H:%M:%S')" "$DIM" "$R"
    fi
    LAST_STATE="$RUNNING"
    LAST_HEARTBEAT="$NOW"   # the state line above already says this - don't also heartbeat immediately
  fi

  if [ "$RUNNING" -eq 1 ]; then
    N="$(restore_missing_reshade)"
    if [ "$N" != "255" ] && [ "$N" -gt 0 ] 2>/dev/null; then
      printf '  [%s] %sRestored %s ReShade file(s) Plutonium had cleared.%s\n' "$(date '+%H:%M:%S')" "$GN" "$N" "$R"
      LAST_HEARTBEAT="$NOW"
    elif [ "$N" != "255" ] && [ $(( NOW - LAST_HEARTBEAT )) -ge "$HEARTBEAT_SECONDS" ]; then
      printf '  [%s] %sWatching - bin is intact, nothing to restore.%s\n' "$(date '+%H:%M:%S')" "$DIM" "$R"
      LAST_HEARTBEAT="$NOW"
    fi
  fi

  sleep "$POLL_SECONDS"
done
