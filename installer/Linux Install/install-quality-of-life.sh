#!/usr/bin/env bash
# =============================================================================
#  Quality Of Life (zm_qol) - installer for Plutonium T6 on Linux
#
#  Same job as the Windows "Install Quality Of Life.bat", for people running
#  Plutonium through Wine, Proton, Lutris or Bottles.
#
#  Nothing here touches a game file. Everything is written inside your Wine
#  prefix, under AppData/Local/Plutonium, and every destructive step asks first.
#
#  Run it:      bash "install-quality-of-life.sh"
#  Point it at a prefix by hand:
#               WINEPREFIX=~/Games/plutonium bash "install-quality-of-life.sh"
#
#  Hidden switches, for testing only:
#    --dry-run              print what would happen, write nothing
#    --root <path>          pretend Plutonium lives here
#    --action <name> [n]    run one action headlessly, taking option n
# =============================================================================

set -uo pipefail

REPO="DavidHiFi/zm_qol"
MODID="zm_qol"
MODNAME="Quality Of Life"
MOD_FILES=(mod.ff mod.iwd mod.json mod.all.sabl mod.all.sabs)
SOUND_FILES=(cmn_root.all.sabl zmb_code_post_gfx.all.sabs zmb_common.english.sabs)

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG="$(dirname "$HERE")"          # the package root: the .bat lives there
LOGFILE="$HERE/installer.log"

DRYRUN=0
ROOT_OVERRIDE=""
ACTION=""
CHOICE=0
HEADLESS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRYRUN=1 ;;
    --root)    ROOT_OVERRIDE="${2:-}"; shift ;;
    --action)  ACTION="${2:-}"; HEADLESS=1; shift ;;
    --choice)  CHOICE="${2:-0}"; shift ;;
    *)         [[ "$1" =~ ^[0-9]+$ ]] && CHOICE="$1" ;;
  esac
  shift
done

# ------------------------------------------------------------------ colours --
if [ -t 1 ] && [ "$HEADLESS" -eq 0 ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; R=$'\033[0m'
  CY=$'\033[36m'; GN=$'\033[32m'; YE=$'\033[33m'; RD=$'\033[31m'; WH=$'\033[97m'
else
  B=""; DIM=""; R=""; CY=""; GN=""; YE=""; RD=""; WH=""
fi

log() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$1" >> "$LOGFILE" 2>/dev/null || true; }
say() { printf '     %s%s%s\n' "${2:-}" "$1" "$R"; log "$1"; }

header() {
  [ "$HEADLESS" -eq 0 ] && clear
  printf '\n'
  printf '   %s╔══════════════════════════════════════════════════════════════════╗%s\n' "$CY" "$R"
  printf '   %s║%s   %sQUALITY OF LIFE%s%*s%s║%s\n' "$CY" "$R" "$B$WH" "$R" 48 "" "$CY" "$R"
  printf '   %s║%s   %s%-63s%s%s║%s\n' "$CY" "$R" "$DIM" "$1" "$R" "$CY" "$R"
  printf '   %s╚══════════════════════════════════════════════════════════════════╝%s\n' "$CY" "$R"
  printf '\n'
}

rule() { printf '   %s────────────────────────────────────────────────────────────────────%s\n' "$CY" "$R"; }

pause_key() {
  printf '\n'; rule
  printf '   %sPress any key to go back%s\n' "$DIM" "$R"
  [ "$HEADLESS" -eq 1 ] && return 0
  read -rsn1 _ || true
}

# ------------------------------------------------------- find the Plutonium --
# Plutonium is a Windows program, so on Linux it lives inside a Wine prefix.
# These are the places people actually keep one.
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
T6="$PLUTO/storage/t6"
MODDIR="$T6/mods/$MODID"
IMGDIR="$T6/images"
ZONEDIR="$T6/zone"
CFGDIR="$T6/players/mods/$MODID"
BINDIR="$PLUTO/bin"
STATE="$T6/_zm_qol_installer"
BACKUPS="$STATE/backups"

# ------------------------------------------------------------------- helpers -
find_mod_source() {
  local p
  for p in "$PKG/Mod Files/$MODID" "$PKG/Mod Files" "$PKG/$MODID" "$PKG" "$HERE" "$PKG/.." "$PKG/../$MODID"; do
    [ -f "$p/mod.json" ] && { printf '%s\n' "$p"; return 0; }
  done
  return 1
}

find_payload() {
  local name="$1" p
  for p in "$PKG/Mod Files/$name" "$PKG/Optional/$name" "$PKG/Optionals/$name" "$PKG/$name" "$HERE/$name" "$PKG/../Optional/$name" "$PKG/../Optionals/$name" "$PKG/../../Optional/$name" "$PKG/../../Optionals/$name"; do
    if [ -d "$p" ] && [ -n "$(ls -A "$p" 2>/dev/null)" ]; then printf '%s\n' "$p"; return 0; fi
  done
  return 1
}

mod_version() {
  local f="$1"
  [ -f "$f" ] || return 1
  local v
  v="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -1)"
  [ -z "$v" ] && return 1
  # Plutonium colour-codes these strings ("name" is ^5, "version" is ^3), so
  # strip the caret AND the colour digit, never a specific version number.
  case "$v" in ^[0-9]*) v="${v:2}" ;; esac
  printf '%s\n' "$v"
}

human() {
  local b="$1"
  if   [ "$b" -ge 1073741824 ]; then awk -v b="$b" 'BEGIN{printf "%.2f GB", b/1073741824}'
  elif [ "$b" -ge 1048576 ];    then awk -v b="$b" 'BEGIN{printf "%.0f MB", b/1048576}'
  elif [ "$b" -ge 1024 ];       then awk -v b="$b" 'BEGIN{printf "%.0f KB", b/1024}'
  else printf '%s bytes' "$b"; fi
}

dir_bytes() { du -sb "$1" 2>/dev/null | cut -f1 || echo 0; }
dir_files() { find "$1" -type f 2>/dev/null | wc -l | tr -d ' '; }

copy_tree() {
  local src="$1" dst="$2"
  if [ "$DRYRUN" -eq 1 ]; then say "(dry run - not copied)" "$DIM"; return 0; fi
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then rsync -a "$src"/ "$dst"/ || return 1
  else cp -a "$src"/. "$dst"/ || return 1; fi
  return 0
}

write_manifest() {
  local kind="$1" src="$2"
  [ "$DRYRUN" -eq 1 ] && return 0
  mkdir -p "$STATE"
  ( cd "$src" && find . -type f -printf '%P\n' ) > "$STATE/installed-$kind.txt"
}

remove_by_manifest() {
  local kind="$1" dst="$2" f n=0
  local man="$STATE/installed-$kind.txt"
  if [ ! -f "$man" ]; then
    say "No record of anything installed by this installer, so nothing was removed." "$YE"
    say "Files that were already in that folder are never touched." "$DIM"
    return 1
  fi
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [ -e "$dst/$f" ]; then
      [ "$DRYRUN" -eq 0 ] && rm -f "$dst/$f"
      n=$((n+1))
    fi
  done < "$man"
  say "Removed $n file(s)." "$GN"
  if [ "$DRYRUN" -eq 0 ]; then
    rm -f "$man"
    find "$dst" -mindepth 1 -type d -empty -delete 2>/dev/null || true
  fi
  return 0
}

backup_folder() {
  local kind="$1" src="$2"
  local dst="$BACKUPS/$kind"
  local n; n="$(dir_files "$src")"
  if [ "$n" -eq 0 ]; then say "Nothing to back up - that folder is empty." "$DIM"; return 0; fi
  if [ -d "$dst" ]; then
    say "A backup already exists - keeping it, it is the older one." "$DIM"
    return 0
  fi
  say "Backing up $n file(s), $(human "$(dir_bytes "$src")") ..."
  [ "$DRYRUN" -eq 1 ] && { say "(dry run - not copied)" "$DIM"; return 0; }
  mkdir -p "$dst"
  copy_tree "$src" "$dst" || { say "Backup FAILED - stopping, nothing was changed." "$RD"; return 1; }
  say "Backup saved." "$GN"
  return 0
}

restore_folder() {
  local kind="$1" dst="$2"
  local src="$BACKUPS/$kind"
  [ -d "$src" ] || { say "There is no backup to restore." "$YE"; return 1; }
  say "Restoring your original files ..."
  copy_tree "$src" "$dst" || { say "Restore FAILED." "$RD"; return 1; }
  say "Your original files are back." "$GN"
  return 0
}

has_backup() { [ -d "$BACKUPS/$1" ]; }

# --------------------------------------------------------------------- menu --
# MENU_LABELS / MENU_STATUS / MENU_KEYS / MENU_SECTIONS are filled by the caller.
# Returns the chosen key in MENU_RESULT, or "" if the user backed out.
menu() {
  local title="$1"; shift
  local intro=("$@")
  local n=${#MENU_KEYS[@]}
  local cur=0 i key rest

  if [ "$HEADLESS" -eq 1 ]; then
    MENU_RESULT="${MENU_KEYS[$CHOICE]}"
    return 0
  fi

  while true; do
    header "$title"
    for i in "${!intro[@]}"; do
      local line="${intro[$i]}"
      case "$line" in
        "")  printf '\n' ;;
        !*)  printf '   %s%s%s\n' "$YE" "${line#!}" "$R" ;;
        '~'*) printf '   %s%s%s\n' "$DIM" "${line#\~}" "$R" ;;
        *)   printf '   %s\n' "$line" ;;
      esac
    done
    [ ${#intro[@]} -gt 0 ] && printf '\n'

    local lastsec=""
    for i in $(seq 0 $((n-1))); do
      local sec="${MENU_SECTIONS[$i]}"
      if [ -n "$sec" ] && [ "$sec" != "$lastsec" ]; then
        printf '\n   %s%s%s\n' "$DIM" "$sec" "$R"
        lastsec="$sec"
      fi
      if [ "$i" -eq "$cur" ]; then
        printf '   %s❯ %s%s%-38s%s%s%s\n' "$CY" "$R" "$B$WH" "${MENU_LABELS[$i]}" "$R" "$DIM${MENU_STATUS[$i]}" "$R"
      else
        printf '     %-38s%s%s%s\n' "${MENU_LABELS[$i]}" "$DIM" "${MENU_STATUS[$i]}" "$R"
      fi
    done

    printf '\n'; rule
    printf '   %s↑ ↓  move      ENTER  choose      Q  quit%s\n' "$DIM" "$R"

    IFS= read -rsn1 key || return 1
    case "$key" in
      $'\x1b')
        read -rsn2 -t 0.01 rest || rest=""
        case "$rest" in
          '[A') cur=$(( (cur - 1 + n) % n )) ;;
          '[B') cur=$(( (cur + 1) % n )) ;;
          '')   MENU_RESULT=""; return 0 ;;
        esac
        ;;
      "")   MENU_RESULT="${MENU_KEYS[$cur]}"; return 0 ;;
      q|Q)  MENU_RESULT=""; return 0 ;;
      [1-9])
        local idx=$((key-1))
        [ "$idx" -lt "$n" ] && { MENU_RESULT="${MENU_KEYS[$idx]}"; return 0; }
        ;;
    esac
  done
}

# ------------------------------------------------------------------ actions --
act_mod() {
  local src; src="$(find_mod_source)" || {
    header "Install the mod"
    say "The mod files are not in this package." "$YE"
    say "They should sit next to the Linux Install folder." "$DIM"
    pause_key; return
  }
  local newv curv
  newv="$(mod_version "$src/mod.json")" || newv="unknown"
  curv="$(mod_version "$MODDIR/mod.json")" || curv="nothing"

  MENU_KEYS=(keep wipe back)
  MENU_LABELS=("Update, and keep my settings" "Fresh install, wipe everything" "Cancel")
  MENU_STATUS=("recommended" "forget all my menu settings" "")
  MENU_SECTIONS=("" "" "")
  menu "Install the mod" \
    "This copies the mod into Plutonium so it shows up in the Mods menu." "" \
    "~In this package:  v$newv" "~Installed now:    $curv" "~Goes to:          $MODDIR"
  case "$MENU_RESULT" in ""|back) return ;; esac

  header "Install the mod"
  local f missing=""
  for f in "${MOD_FILES[@]}"; do [ -f "$src/$f" ] || missing="$missing $f"; done
  if [ -n "$missing" ]; then
    say "This package is incomplete - missing:$missing" "$RD"
    say "Nothing was installed. Download the release again." "$DIM"
    pause_key; return
  fi

  # old mod files out - never the logs the game writes into this same folder
  if [ -d "$MODDIR" ]; then
    local removed=0
    while IFS= read -r f; do
      [ "$DRYRUN" -eq 0 ] && rm -f "$f"
      removed=$((removed+1))
    done < <(find "$MODDIR" -maxdepth 1 -type f \( -name '*.ff' -o -name '*.iwd' -o -name '*.json' -o -name '*.sabl' -o -name '*.sabs' \))
    [ "$removed" -gt 0 ] && say "Removed $removed file(s) from the old version." "$DIM"
  fi

  if [ "$MENU_RESULT" = "wipe" ] && [ -d "$CFGDIR" ]; then
    [ "$DRYRUN" -eq 0 ] && rm -rf "$CFGDIR"
    say "Your saved menu settings were wiped, as asked." "$YE"
  elif [ -d "$CFGDIR" ]; then
    say "Your saved menu settings were left alone." "$GN"
  fi

  [ "$DRYRUN" -eq 0 ] && mkdir -p "$MODDIR"
  for f in "${MOD_FILES[@]}"; do
    if [ "$DRYRUN" -eq 1 ]; then say "would copy $f" "$DIM"; continue; fi
    cp -f "$src/$f" "$MODDIR/$f" && say "$f" || say "FAILED to copy $f" "$RD"
  done
  printf '\n'
  say "✅  The mod is installed - version $(mod_version "$MODDIR/mod.json")" "$GN"
  say "Plutonium T6 → Zombies → Mods → $MODNAME" "$DIM"
  pause_key
}

act_pack() {
  # $1 = images|zone   $2 = pretty name   $3 = destination   $4 = warning line
  local kind="$1" pretty="$2" dest="$3" warn="$4"
  local src
  if ! src="$(find_payload "$kind")"; then
    src="$(download_pack "$kind")" || {
      header "$pretty"
      say "The $pretty is not in this package, and it is not attached to the" "$YE"
      say "latest release on GitHub either, so there is nothing to install." "$YE"
      pause_key; return
    }
  fi

  MENU_KEYS=(backup plain back)
  MENU_LABELS=("Back up what I have first, then install" "Install without a backup" "Cancel")
  MENU_STATUS=("recommended" "" "")
  MENU_SECTIONS=("" "" "")
  menu "$pretty" \
    "$(dir_files "$src") files, $(human "$(dir_bytes "$src")")." "" \
    "~Goes to:  $dest" "" \
    "!⚠️   $warn  ⚠️" \
    "~     Your actual game files are never touched."
  case "$MENU_RESULT" in ""|back) return ;; esac

  header "$pretty"
  if [ "$MENU_RESULT" = "backup" ]; then backup_folder "$kind" "$dest" || { pause_key; return; }; fi
  say "Copying $(dir_files "$src") file(s), $(human "$(dir_bytes "$src")") ..."
  if copy_tree "$src" "$dest"; then
    write_manifest "$kind" "$src"
    printf '\n'; say "✅  $pretty installed." "$GN"
  else
    say "Copy FAILED." "$RD"
  fi
  pause_key
}

keep_ini_value() {
  # Read one key from the live ReShade.ini, falling back to the .backup, and
  # echo it only if it is non-empty and not the shipped placeholder. Lets a
  # user who already had ReShade keep their own screenshot folder and font
  # while still picking up this mod's overlay theme and key binds.
  local key="$1" f v
  for f in "$BINDIR/ReShade.ini" "$BINDIR/ReShade.ini.backup"; do
    [ -f "$f" ] || continue
    v="$(sed -n "s|^${key}=||p" "$f" | head -n 1)"
    if [ -n "$v" ] && [ "$v" != '.\reshade-screenshots' ]; then printf '%s' "$v"; return 0; fi
  done
  return 0
}

set_ini_value() {
  local key="$1" val="$2" ini="$BINDIR/ReShade.ini" tmp
  [ -f "$ini" ] || return 0
  [ "$DRYRUN" -eq 0 ] || return 0
  tmp="$ini.tmp$$"
  awk -v k="$key" -v v="$val" 'index($0, k "=")==1 { print k "=" v; next } { print }' "$ini" > "$tmp" && mv -f "$tmp" "$ini"
}

set_reshade_font() {
  # The shipped ReShade.ini leaves Font= and EditorFont= EMPTY on purpose: the
  # font it was authored with (JetBrains Mono Nerd Font) is a separate
  # third-party download and is not redistributed here. Fill the two lines in
  # only if the file is genuinely there, and write a WINDOWS path, because it
  # is Wine's ReShade that reads it. Not found is not a failure - ReShade uses
  # its own built-in font and every other part of the look is already set.
  local ini="$BINDIR/ReShade.ini"
  [ -f "$ini" ] || return 0
  local name="JetBrainsMonoNerdFont-Regular.ttf"
  local dc="${PLUTO%%/drive_c/*}/drive_c"
  local win=""
  if [ -f "$dc/windows/Fonts/$name" ]; then
    win="C:\\windows\\Fonts\\$name"
  fi
  if [ -z "$win" ]; then
    say "Font not in the prefix - ReShade will use its own. Everything else is set." "$DIM"
    return 0
  fi
  if [ "$DRYRUN" -ne 0 ]; then say "Would point the UI font at $win" "$DIM"; return 0; fi
  local tmp="$ini.tmp$$"
  sed -e "s|^Font=$|Font=$win|" -e "s|^EditorFont=$|EditorFont=$win|" "$ini" > "$tmp" && mv -f "$tmp" "$ini"
  say "UI font found and set." "$DIM"
}

act_reshade() {
  local src
  src="$(find_payload reshade)" || {
    header "ReShade"
    say "The ReShade files are not in this package." "$YE"
    pause_key; return
  }
  MENU_KEYS=(go back)
  MENU_LABELS=("Install ReShade with the BO2 preset" "Cancel")
  MENU_STATUS=("read the note below first" "")
  MENU_SECTIONS=("" "")
  menu "ReShade" \
    "ReShade adds a sharpening / colour pass on top of the game, with this" \
    "mod's own BO2 preset already applied. Press END in game to open it." "" \
    "~Goes to:  $BINDIR" "" \
    "!⚠️   ON LINUX THIS NEEDS ONE EXTRA STEP" \
    "~     Wine has to be told to load dxgi.dll. After installing, launch" \
    "~     Plutonium with:   WINEDLLOVERRIDES=\"dxgi=n,b\" <your usual command>" \
    "~     or add dxgi as a native override in Lutris / Bottles / winecfg." \
    "" \
    "~Your existing ReShade.ini and BO2.ini are kept as .backup files."
  case "$MENU_RESULT" in ""|back) return ;; esac

  header "ReShade"
  local keep_shots keep_font
  keep_shots="$(keep_ini_value SavePath)"
  keep_font="$(keep_ini_value Font)"
  local f
  # NEVER overwrite a .backup that already exists - installing twice used to
  # copy the config THIS INSTALLER wrote over the only copy of the original.
  for f in ReShade.ini BO2.ini; do
    if [ -f "$BINDIR/$f" ]; then
      if [ -f "$BINDIR/$f.backup" ]; then
        say "Your original $f.backup is already saved - left untouched." "$DIM"
      else
        [ "$DRYRUN" -eq 0 ] && cp -f "$BINDIR/$f" "$BINDIR/$f.backup"
        say "Your $f was saved as $f.backup" "$DIM"
      fi
    fi
  done
  if copy_tree "$src" "$BINDIR"; then
    write_manifest reshade "$src"
    if [ -n "$keep_shots" ]; then set_ini_value SavePath "$keep_shots"; say "Kept your screenshot folder: $keep_shots" "$DIM"; fi
    if [ -n "$keep_font" ]; then set_ini_value Font "$keep_font"; set_ini_value EditorFont "$keep_font"; say "Kept your overlay font." "$DIM"; else set_reshade_font; fi
    printf '\n'
    say "✅  ReShade installed." "$GN"
    say "Remember the WINEDLLOVERRIDES line above, or it will not load." "$YE"
  else
    say "Copy FAILED." "$RD"
  fi
  pause_key
}

act_remove_pack() {
  local kind="$1" pretty="$2" dest="$3"
  MENU_KEYS=(); MENU_LABELS=(); MENU_STATUS=(); MENU_SECTIONS=()
  if has_backup "$kind"; then
    MENU_KEYS+=(restore); MENU_LABELS+=("Remove them and put my originals back"); MENU_STATUS+=("backup found"); MENU_SECTIONS+=("")
  fi
  MENU_KEYS+=(plain); MENU_LABELS+=("Just remove them"); MENU_STATUS+=(""); MENU_SECTIONS+=("")
  MENU_KEYS+=(back);  MENU_LABELS+=("Cancel");           MENU_STATUS+=(""); MENU_SECTIONS+=("")
  menu "Remove the $pretty" \
    "Removes only the files this installer put there." \
    "~Anything that was already in that folder is left alone."
  case "$MENU_RESULT" in ""|back) return ;; esac

  header "Remove the $pretty"
  remove_by_manifest "$kind" "$dest" || true
  [ "$MENU_RESULT" = "restore" ] && restore_folder "$kind" "$dest"
  printf '\n'; say "✅  Done." "$GN"
  pause_key
}

act_remove_reshade() {
  MENU_KEYS=(go back)
  MENU_LABELS=("Remove ReShade" "Cancel")
  MENU_STATUS=("" "")
  MENU_SECTIONS=("" "")
  menu "Remove ReShade" \
    "Removes only the ReShade files this installer put there, and puts back" \
    "any ReShade.ini / BO2.ini it saved as .backup." \
    "~Shader files you added yourself are left alone."
  case "$MENU_RESULT" in ""|back) return ;; esac

  header "Remove ReShade"
  remove_by_manifest reshade "$BINDIR" || true
  local f
  for f in ReShade.ini BO2.ini; do
    if [ -f "$BINDIR/$f.backup" ]; then
      [ "$DRYRUN" -eq 0 ] && mv -f "$BINDIR/$f.backup" "$BINDIR/$f"
      say "Your original $f was put back." "$GN"
    fi
  done
  printf '\n'; say "✅  Done." "$GN"
  pause_key
}

act_remove_mod() {
  MENU_KEYS=(keep wipe back)
  MENU_LABELS=("Remove it, keep my settings" "Remove it and wipe my settings" "Cancel")
  MENU_STATUS=("so a reinstall remembers them" "" "")
  MENU_SECTIONS=("" "" "")
  menu "Remove the mod" \
    "Removes the mod from Plutonium's Mods menu." \
    "~Your other mods, your logs and the game itself are never touched."
  case "$MENU_RESULT" in ""|back) return ;; esac

  header "Remove the mod"
  local n=0 f
  if [ -d "$MODDIR" ]; then
    while IFS= read -r f; do
      [ "$DRYRUN" -eq 0 ] && rm -f "$f"
      n=$((n+1))
    done < <(find "$MODDIR" -maxdepth 1 -type f \( -name '*.ff' -o -name '*.iwd' -o -name '*.json' -o -name '*.sabl' -o -name '*.sabs' \))
    say "Removed $n mod file(s)."
  else
    say "It was not installed." "$DIM"
  fi
  if [ "$MENU_RESULT" = "wipe" ] && [ -d "$CFGDIR" ]; then
    [ "$DRYRUN" -eq 0 ] && rm -rf "$CFGDIR"
    say "Your saved menu settings were wiped." "$YE"
  elif [ -d "$CFGDIR" ]; then
    say "Your saved menu settings were kept." "$GN"
  fi
  printf '\n'; say "✅  Done." "$GN"
  pause_key
}

# ------------------------------------------------------------------ network --
have_net() { command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; }

api_latest() {
  local url="https://api.github.com/repos/$REPO/releases/latest"
  if command -v curl >/dev/null 2>&1; then curl -fsSL -H 'User-Agent: zm_qol-installer' "$url" 2>/dev/null
  else wget -qO- --header='User-Agent: zm_qol-installer' "$url" 2>/dev/null; fi
}

# asset url by exact name, without needing jq
asset_url() {
  local json="$1" name="$2"
  printf '%s' "$json" | tr ',' '\n' | grep -o "https://[^\"]*/$name" | head -1
}

fetch() {
  local url="$1" out="$2"
  if command -v curl >/dev/null 2>&1; then curl -L --fail --progress-bar -o "$out" "$url"
  else wget -O "$out" "$url"; fi
}

unpack() {
  local zip="$1" dir="$2"
  mkdir -p "$dir"
  if command -v unzip >/dev/null 2>&1; then unzip -qo "$zip" -d "$dir"
  elif command -v bsdtar >/dev/null 2>&1; then bsdtar -xf "$zip" -C "$dir"
  else tar -xf "$zip" -C "$dir"; fi
}

download_pack() {
  local kind="$1" asset
  case "$kind" in
    images) asset="zm_qol-textures.zip" ;;
    zone)   asset="zm_qol-sounds.zip" ;;
    *) return 1 ;;
  esac
  have_net || return 1
  local json; json="$(api_latest)" || return 1
  [ -z "$json" ] && return 1
  local url; url="$(asset_url "$json" "$asset")"
  [ -z "$url" ] && return 1
  [ "$DRYRUN" -eq 1 ] && return 1
  local tmp="${TMPDIR:-/tmp}/zm_qol_installer"
  mkdir -p "$tmp"
  fetch "$url" "$tmp/$asset" >&2 || return 1
  rm -rf "${tmp:?}/$kind"; mkdir -p "$tmp/$kind"
  unpack "$tmp/$asset" "$tmp/$kind" >&2 || return 1
  if [ -d "$tmp/$kind/$kind" ]; then printf '%s\n' "$tmp/$kind/$kind"; else printf '%s\n' "$tmp/$kind"; fi
}

act_update() {
  header "Check for a newer version"
  say "Asking GitHub ..."
  have_net || { say "Neither curl nor wget is installed, so this cannot check." "$RD"; pause_key; return; }
  local json; json="$(api_latest)"
  if [ -z "$json" ]; then say "Could not reach GitHub." "$RD"; pause_key; return; fi
  local tag; tag="$(printf '%s' "$json" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  local cur; cur="$(mod_version "$MODDIR/mod.json")" || cur=""
  local state="newer"
  if [ -n "$cur" ]; then
    local a="${tag#v}"
    local newest; newest="$(printf '%s\n%s\n' "$a" "$cur" | sort -V | tail -1)"
    if [ "$a" = "$cur" ]; then state="same"
    elif [ "$newest" = "$cur" ]; then state="older"
    fi
  fi

  MENU_KEYS=(); MENU_LABELS=(); MENU_STATUS=(); MENU_SECTIONS=()
  local note=""
  case "$state" in
    same)  note="✅  You are already up to date." ;;
    newer) note="🆕  There is a newer version available." ;;
    older) note="!⚠️   YOUR COPY IS NEWER THAN THE RELEASE - installing it goes backwards." ;;
  esac
  if [ "$state" = "newer" ]; then
    MENU_KEYS+=(go);   MENU_LABELS+=("Download and install $tag"); MENU_STATUS+=("recommended"); MENU_SECTIONS+=("")
    MENU_KEYS+=(back); MENU_LABELS+=("Not now");                   MENU_STATUS+=("");            MENU_SECTIONS+=("")
  else
    MENU_KEYS+=(back); MENU_LABELS+=("Go back");                   MENU_STATUS+=("recommended"); MENU_SECTIONS+=("")
    MENU_KEYS+=(go);   MENU_LABELS+=("Install $tag anyway");       MENU_STATUS+=("takes you backwards"); MENU_SECTIONS+=("")
  fi
  menu "Check for a newer version" "~Latest release:  $tag" "~You have:        ${cur:-nothing installed}" "" "$note"
  case "$MENU_RESULT" in ""|back) return ;; esac

  header "Downloading"
  local url; url="$(printf '%s' "$json" | tr ',' '\n' | grep -o 'https://[^"]*\.zip' | grep -v -e texture -e sound | head -1)"
  [ -z "$url" ] && { say "That release has no mod zip attached." "$RD"; pause_key; return; }
  local tmp="${TMPDIR:-/tmp}/zm_qol_installer"; mkdir -p "$tmp"
  fetch "$url" "$tmp/mod.zip" || { say "Download failed." "$RD"; pause_key; return; }
  rm -rf "$tmp/unpack"; unpack "$tmp/mod.zip" "$tmp/unpack"
  # The release zip is a whole package now, so mod.json sits several folders
  # deep. Find it wherever it is rather than guessing at a layout.
  local found; found="$(find "$tmp/unpack" -type f -name mod.json | head -1)"
  [ -n "$found" ] || { say "That download did not contain the mod." "$RD"; pause_key; return; }
  local src; src="$(dirname "$found")"
  mkdir -p "$MODDIR"
  local f
  for f in "${MOD_FILES[@]}"; do
    [ -f "$src/$f" ] || { say "Incomplete download - missing $f" "$RD"; pause_key; return; }
  done
  for f in "${MOD_FILES[@]}"; do cp -f "$src/$f" "$MODDIR/$f" && say "$f"; done
  printf '\n'; say "✅  $tag installed. Your settings were kept." "$GN"
  pause_key
}

act_details() {
  header "Details and log"
  printf '   %sWHERE THINGS ARE%s\n' "$DIM" "$R"
  say "Plutonium      ${PLUTO:-not found}"
  say "Mod folder     $MODDIR"
  say "Textures       $IMGDIR"
  say "Sounds         $ZONEDIR"
  say "ReShade        $BINDIR"
  say "Your settings  $CFGDIR"
  say "This package   $(find_mod_source 2>/dev/null || echo 'no mod files found')"
  printf '\n   %sWHAT IS INSTALLED%s\n' "$DIM" "$R"
  say "Mod            $(mod_version "$MODDIR/mod.json" 2>/dev/null || echo 'not installed')"
  say "Textures       $( [ -f "$STATE/installed-images.txt" ] && echo "$(wc -l < "$STATE/installed-images.txt" | tr -d ' ') files installed" || echo 'not installed')"
  say "Sounds         $( [ -f "$ZONEDIR/${SOUND_FILES[0]}" ] && echo installed || echo 'not installed')"
  say "ReShade        $( [ -f "$BINDIR/dxgi.dll" ] && echo installed || echo 'not installed')"
  say "Backups        $( [ -d "$BACKUPS" ] && echo "$BACKUPS" || echo 'none taken yet')"
  printf '\n'
  say "Full log: $LOGFILE" "$DIM"
  pause_key
}

# --------------------------------------------------------------------- main --
main_menu() {
  while true; do
    local modst imgst sndst rshst
    modst="$(mod_version "$MODDIR/mod.json" 2>/dev/null && printf 'installed' || printf 'not installed')"
    modst="$(mod_version "$MODDIR/mod.json" 2>/dev/null | sed 's/^/v/' || true)"
    [ -z "$modst" ] && modst="not installed" || modst="$modst installed"
    if [ -f "$STATE/installed-images.txt" ]; then imgst="$(wc -l < "$STATE/installed-images.txt" | tr -d ' ') files installed"; else imgst="not installed"; fi
    if [ -f "$ZONEDIR/${SOUND_FILES[0]}" ]; then sndst="installed"; else sndst="not installed"; fi
    if [ -f "$BINDIR/dxgi.dll" ]; then rshst="installed"; else rshst="not installed"; fi

    MENU_KEYS=(mod images sounds reshade rimages rsounds rreshade rmod update details quit)
    MENU_LABELS=("The mod" "HD texture pack" "Custom sounds" "ReShade + BO2 preset" \
                 "Remove the HD textures" "Remove the custom sounds" "Remove ReShade" "Remove the mod" \
                 "Check for a newer version" "Details and log" "Quit")
    MENU_STATUS=("$modst" "$imgst" "$sndst" "$rshst" "" "" "" "" "" "" "")
    MENU_SECTIONS=("INSTALL" "INSTALL" "INSTALL" "INSTALL" \
                   "REMOVE" "REMOVE" "REMOVE" "REMOVE" \
                   "MORE" "MORE" "MORE")

    local intro=()
    if [ -z "$PLUTO" ] || [ ! -d "$PLUTO" ]; then
      intro+=("!⚠️   Plutonium was not found in any Wine prefix on this machine.")
      intro+=("~     Run this with WINEPREFIX=/path/to/your/prefix, or use --root.")
      intro+=("")
    fi

    menu "Black Ops II Zombies  ·  Plutonium T6 on Linux" "${intro[@]}"
    case "$MENU_RESULT" in
      ""|quit) return ;;
      mod)      act_mod ;;
      images)   act_pack images "HD texture pack" "$IMGDIR" "THIS OVERWRITES ANY CUSTOM TEXTURES ALREADY IN THAT FOLDER" ;;
      sounds)   act_pack zone   "custom sounds"   "$ZONEDIR" "THIS REPLACES ANY CUSTOM SOUNDS ALREADY IN THAT FOLDER" ;;
      reshade)  act_reshade ;;
      rimages)  act_remove_pack images "HD textures"   "$IMGDIR" ;;
      rsounds)  act_remove_pack zone   "custom sounds" "$ZONEDIR" ;;
      rreshade) act_remove_reshade ;;
      rmod)     act_remove_mod ;;
      update)   act_update ;;
      details)  act_details ;;
    esac
  done
}

log "--- installer started (dryrun=$DRYRUN) ---"

if [ -n "$ACTION" ]; then
  case "$ACTION" in
    mod)      act_mod ;;
    images)   act_pack images "HD texture pack" "$IMGDIR" "THIS OVERWRITES ANY CUSTOM TEXTURES ALREADY IN THAT FOLDER" ;;
    sounds)   act_pack zone   "custom sounds"   "$ZONEDIR" "THIS REPLACES ANY CUSTOM SOUNDS ALREADY IN THAT FOLDER" ;;
    reshade)  act_reshade ;;
    rimages)  act_remove_pack images "HD textures"   "$IMGDIR" ;;
    rsounds)  act_remove_pack zone   "custom sounds" "$ZONEDIR" ;;
    rreshade) act_remove_reshade ;;
    rmod)     act_remove_mod ;;
    update)   act_update ;;
    details)  act_details ;;
    *) echo "unknown action: $ACTION" ;;
  esac
  exit 0
fi

main_menu
header "Bye"
printf '     %sLaunch Plutonium T6  →  Zombies  →  Mods  →  %s%s\n\n' "$GN" "$MODNAME" "$R"
