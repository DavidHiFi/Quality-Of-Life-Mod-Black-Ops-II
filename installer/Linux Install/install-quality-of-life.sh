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
SOUND_FILES=(cmn_root.all.sabl zmb_code_post_gfx.all.sabs zmb_common.english.sabs zmb_alcatraz.all.sabl zmb_tomb.all.sabl)

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
    --kind)    CHOICE_KIND="${2:-}"; shift ;;
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
BACKUPS="$T6/backups"
OLDBACKUPS="$STATE/backups"

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

# ---------------------------------------------------------------------------
#  CONTROLLER ICON PACKS - three of them, one slot.  v2.2.1
#
#  Each pack keeps its .iwi files at a different depth, measured from the
#  payload:  Dualsense Icons/Images  ·  Nintendo Switch Icons/t6/images  ·
#  Xbox One Buttons/t6r/data/images.  Plutonium wants them FLAT in
#  storage/t6/images, so the copy must start at the folder that actually holds
#  them - copying the pack root would recreate "t6/images/" inside the images
#  folder and the game would see nothing.
# ---------------------------------------------------------------------------
controller_folder() {
  case "$1" in
    ps5)    printf 'Dualsense Icons' ;;
    switch) printf 'Nintendo Switch Icons' ;;
    xbox)   printf 'Xbox One Buttons' ;;
  esac
}
controller_name() {
  case "$1" in
    ps5)    printf 'PlayStation 5 (DualSense)' ;;
    switch) printf 'Nintendo Switch' ;;
    xbox)   printf 'Xbox One' ;;
  esac
}
controller_short() {
  case "$1" in ps5) printf 'PS5' ;; switch) printf 'Switch' ;; xbox) printf 'Xbox' ;; esac
}
controller_keys() { printf '%s\n' ps5 switch xbox; }

# The one directory inside a pack that holds the .iwi files.
icon_source() {
  local root d
  root="$(find_payload "$(controller_folder "$1")")" || return 1
  d="$(find "$root" -type f -name '*.iwi' -printf '%h\n' 2>/dev/null | sort | uniq -c | sort -rn | head -1 | sed 's/^ *[0-9]* *//')"
  [ -n "$d" ] || return 1
  printf '%s\n' "$d"
}

# Every filename any pack can overwrite. Also the list the HD texture pack is
# forbidden to install, and the list the icon backup captures.
#
# 🛑 IT STARTS FROM A CONSTANT ON PURPOSE. The packs live in Optionals/, the
# release ZIP does not carry Optionals/, and this list is what stops the texture
# pack shipping controller art - deriving it only from the payloads would make it
# empty for exactly the people who install from the release. The 20 constants are
# the names the HD texture pack actually contains; the payloads are unioned in on
# top so a pack that grows a file is covered without editing this.
ICON_FILES="xenon_controller_top.iwi \
xenonbutton_a.iwi xenonbutton_b.iwi xenonbutton_x.iwi xenonbutton_y.iwi \
xenonbutton_back.iwi xenonbutton_start.iwi \
xenonbutton_lb.iwi xenonbutton_rb.iwi xenonbutton_lt.iwi xenonbutton_rt.iwi \
xenonbutton_ls.iwi xenonbutton_rs.iwi \
xenonbutton_dpad_all.iwi xenonbutton_dpad_up.iwi xenonbutton_dpad_down.iwi \
xenonbutton_dpad_left.iwi xenonbutton_dpad_right.iwi \
xenonbutton_dpad_ud.iwi xenonbutton_dpad_rl.iwi"
for _k in ps5 switch xbox; do
  _d="$(icon_source "$_k" 2>/dev/null || true)"
  [ -n "$_d" ] && ICON_FILES="$ICON_FILES $(cd "$_d" && ls -A ./*.iwi 2>/dev/null | sed 's|^\./||' | tr '\n' ' ')"
done
ICON_FILES="$(printf '%s\n' $ICON_FILES | sort -u | tr '\n' ' ')"

controller_pack() {
  [ -f "$STATE/installed-controller.txt" ] || return 1
  if [ -f "$STATE/controller-pack.txt" ]; then
    head -1 "$STATE/controller-pack.txt" | tr -d ' \r\n'
  else
    printf 'ps5'    # pre-v2.2.1 installs were always PS5
  fi
}
set_controller_pack() {
  [ "$DRYRUN" -eq 1 ] && return 0
  mkdir -p "$STATE"
  printf '%s\n' "$1" > "$STATE/controller-pack.txt"
}

# ---------------------------------------------------------------------------
#  v2.2.1 - "dualsense" became "controller" when the Switch and Xbox packs were
#  added. Carry the v2.2.0 manifest and backup across once, or a PS5 install
#  made under v2.2.0 becomes un-removable and its backup un-restorable.
# ---------------------------------------------------------------------------
migrate_dualsense() {
  [ "$DRYRUN" -eq 1 ] && return 0
  if [ -f "$STATE/installed-dualsense.txt" ] && [ ! -f "$STATE/installed-controller.txt" ]; then
    mv -f "$STATE/installed-dualsense.txt" "$STATE/installed-controller.txt"
    printf 'ps5\n' > "$STATE/controller-pack.txt"
    log "migrated installed-dualsense.txt -> installed-controller.txt (pack=ps5)"
  fi
  if [ -d "$BACKUPS/dualsense" ] && [ ! -d "$BACKUPS/controller" ]; then
    mv -f "$BACKUPS/dualsense" "$BACKUPS/controller"
    log "migrated backups/dualsense -> backups/controller"
  fi
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

# How many files a copy will ACTUALLY write, once $BLOCKED is taken off. The
# count on screen has to be the count on disk.
count_after_block() {
  local src="$1" n f
  n="$(dir_files "$src")"
  for f in $BLOCKED; do
    [ -n "$(find "$src" -type f -name "$f" -print -quit 2>/dev/null)" ] && n=$(( n - 1 ))
  done
  printf '%s' "$n"
}

preset_game() {
  case "$1" in
    BO2.ini) printf 'Black Ops II' ;;
    BO1.ini) printf 'Black Ops' ;;
    MW3.ini) printf 'Modern Warfare 3' ;;
    WAW.ini) printf 'World at War' ;;
    *) printf '%s' "$1" ;;
  esac
}

# ---------------------------------------------------------------------------
#  $BLOCKED is a space-separated list of BASENAMES this copy must not install.
#  Set by the caller for the duration of one copy and cleared afterwards; the
#  copy and the manifest read the same list, so a blocked file can never end up
#  on disk or in the record. See act_pack for what goes in it and why.
# ---------------------------------------------------------------------------
BLOCKED=""

copy_tree() {
  local src="$1" dst="$2" f ex=()
  if [ "$DRYRUN" -eq 1 ]; then say "(dry run - not copied)" "$DIM"; return 0; fi
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    for f in $BLOCKED; do ex+=(--exclude "$f"); done
    rsync -a "${ex[@]+"${ex[@]}"}" "$src"/ "$dst"/ || return 1
  else
    cp -a "$src"/. "$dst"/ || return 1
    for f in $BLOCKED; do rm -f "$dst/$f"; done
  fi
  return 0
}

write_manifest() {
  local kind="$1" src="$2" f
  [ "$DRYRUN" -eq 1 ] && return 0
  mkdir -p "$STATE"
  ( cd "$src" && find . -type f -printf '%P\n' ) > "$STATE/installed-$kind.txt.tmp"
  if [ -n "$BLOCKED" ]; then
    : > "$STATE/installed-$kind.blocked"
    for f in $BLOCKED; do printf '%s\n' "$f" >> "$STATE/installed-$kind.blocked"; done
    grep -vxFf "$STATE/installed-$kind.blocked" "$STATE/installed-$kind.txt.tmp" > "$STATE/installed-$kind.txt" || true
    rm -f "$STATE/installed-$kind.blocked"
  else
    mv -f "$STATE/installed-$kind.txt.tmp" "$STATE/installed-$kind.txt"
  fi
  rm -f "$STATE/installed-$kind.txt.tmp"
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

# ------------------------------------------------------------------ backups --
# Four things can be backed up, each into its own subfolder of
# storage/t6/backups/. A "part" is one folder, or a named handful of loose
# files; a thing can be made of more than one part - the mod is its files plus
# the saved menu settings, ReShade is three loose files plus its shader library.
# Each part goes into its own named subfolder so a restore knows exactly where
# to put it back and a human can read the tree.
#
# reshade deliberately does NOT back up the whole bin folder: that is
# Plutonium's own program directory, and the only things in it this installer
# ever writes are the three files and the one folder named here.
backup_parts() {
  case "$1" in
    images)  printf '%s\n' "images|folder|$IMGDIR" ;;
    # The icons back up ONLY the filenames a pack can replace, not the whole
    # images folder: the texture pack already backs that up whole.
    controller) printf '%s\n' "controller|files|$IMGDIR|$ICON_FILES" ;;
    zone)    printf '%s\n' "zone|folder|$ZONEDIR" ;;
    reshade) printf '%s\n' "bin|files|$BINDIR|ReShade.ini BO2.ini BO1.ini MW3.ini WAW.ini dxgi.dll" \
                           "reshade-shaders|folder|$BINDIR/reshade-shaders" ;;
    mod)     printf '%s\n' "files|folder|$MODDIR" \
                           "settings|folder|$CFGDIR" ;;
  esac
}
backup_kinds() { printf '%s\n' images zone controller reshade mod; }
backup_title() {
  case "$1" in
    images)  printf 'your textures' ;;
    zone)    printf 'your sounds' ;;
    controller) printf 'your controller icons' ;;
    reshade) printf 'your ReShade setup' ;;
    mod)     printf 'the mod' ;;
  esac
}
backup_label() {
  case "$1" in
    images)  printf 'My textures' ;;
    zone)    printf 'My sounds' ;;
    controller) printf 'My controller icons' ;;
    reshade) printf 'My ReShade setup' ;;
    mod)     printf 'The mod + my settings' ;;
  esac
}

# How many of the player's own files exist right now for this thing.
source_files() {
  local kind="$1" line sub type path items n=0 f
  while IFS='|' read -r sub type path items; do
    [ -n "$path" ] || continue
    if [ "$type" = folder ]; then
      [ -d "$path" ] && n=$(( n + $(dir_files "$path") ))
    else
      for f in $items; do [ -f "$path/$f" ] && n=$(( n + 1 )); done
    fi
  done <<EOF
$(backup_parts "$kind")
EOF
  printf '%s' "$n"
}

has_backup() { [ -d "$BACKUPS/$1" ]; }
backup_files() { [ -d "$BACKUPS/$1" ] && dir_files "$BACKUPS/$1" || printf '0'; }
backup_when()  { [ -d "$BACKUPS/$1" ] && date -r "$BACKUPS/$1" '+%d %b %Y, %H:%M' 2>/dev/null || printf 'never'; }

# $2 = "replace" to overwrite an existing backup. Without it the OLDER backup
# is kept - it is the one taken before this installer first touched anything.
backup_thing() {
  local kind="$1" replace="${2:-}" sub type path items f dst to n
  n="$(source_files "$kind")"
  dst="$BACKUPS/$kind"
  if [ "$n" -eq 0 ]; then say "Nothing to back up - there are no files of yours there yet." "$DIM"; return 0; fi
  if [ -d "$dst" ] && [ "$replace" != replace ]; then
    say "A backup already exists from $(backup_when "$kind") - keeping it." "$DIM"
    say "That is the older one, so it is the one worth keeping." "$DIM"
    return 0
  fi
  say "Backing up $(backup_title "$kind") - $n file(s) ..."
  [ "$DRYRUN" -eq 1 ] && { say "(dry run - nothing copied)" "$DIM"; return 0; }
  [ -d "$dst" ] && rm -rf "$dst"
  mkdir -p "$dst"
  while IFS='|' read -r sub type path items; do
    [ -n "$path" ] || continue
    to="$dst/$sub"
    if [ "$type" = folder ]; then
      [ -d "$path" ] || continue
      [ "$(dir_files "$path")" -eq 0 ] && continue
      mkdir -p "$to"
      copy_tree "$path" "$to" || { say "Backup FAILED - nothing was changed." "$RD"; return 1; }
    else
      mkdir -p "$to"
      for f in $items; do [ -f "$path/$f" ] && cp -f "$path/$f" "$to/$f"; done
    fi
  done <<EOF
$(backup_parts "$kind")
EOF
  say "Backup saved to  $dst" "$GN"
  return 0
}

# Adds the player's own files back over whatever is there; it does not wipe the
# destination first, so anything they added since is left alone.
restore_thing() {
  local kind="$1" sub type path items f from did=0
  [ -d "$BACKUPS/$kind" ] || { say "There is no backup of $(backup_title "$kind") to restore." "$YE"; return 1; }
  say "Putting $(backup_title "$kind") back ..."
  [ "$DRYRUN" -eq 1 ] && { say "(dry run - nothing copied)" "$DIM"; return 0; }
  while IFS='|' read -r sub type path items; do
    [ -n "$path" ] || continue
    from="$BACKUPS/$kind/$sub"
    [ -d "$from" ] || continue
    if [ "$type" = folder ]; then
      mkdir -p "$path"
      copy_tree "$from" "$path" || { say "Restore FAILED." "$RD"; return 1; }
    else
      mkdir -p "$path"
      for f in $items; do [ -f "$from/$f" ] && cp -f "$from/$f" "$path/$f"; done
    fi
    did=$(( did + 1 ))
  done <<EOF
$(backup_parts "$kind")
EOF
  [ "$did" -eq 0 ] && { say "That backup is empty - nothing to put back." "$YE"; return 1; }
  say "Your own files are back." "$GN"
  return 0
}

# Backups used to live in _zm_qol_installer/backups. Move any across, once.
move_old_backups() {
  [ -d "$OLDBACKUPS" ] || return 0
  [ "$DRYRUN" -eq 0 ] || return 0
  local d
  mkdir -p "$BACKUPS"
  for d in "$OLDBACKUPS"/*; do
    [ -d "$d" ] || continue
    [ -e "$BACKUPS/$(basename "$d")" ] && continue
    mv "$d" "$BACKUPS/" 2>/dev/null || true
  done
  rmdir "$OLDBACKUPS" 2>/dev/null || true
}

act_backup_one() {
  local kind="$1" title label n
  while true; do
    title="$(backup_title "$kind")"
    n="$(source_files "$kind")"
    MENU_KEYS=(); MENU_LABELS=(); MENU_STATUS=(); MENU_SECTIONS=()
    if has_backup "$kind"; then
      MENU_KEYS+=(replace); MENU_LABELS+=("Back up again, replacing that one"); MENU_STATUS+=("overwrites the backup"); MENU_SECTIONS+=("")
      MENU_KEYS+=(restore); MENU_LABELS+=("Put my backup back");                MENU_STATUS+=("backup found");          MENU_SECTIONS+=("")
      MENU_KEYS+=(delete);  MENU_LABELS+=("Delete this backup");                MENU_STATUS+=("");                      MENU_SECTIONS+=("")
    else
      MENU_KEYS+=(make);    MENU_LABELS+=("Back it up now");                    MENU_STATUS+=("$n file(s) here");       MENU_SECTIONS+=("")
    fi
    MENU_KEYS+=(back); MENU_LABELS+=("Back"); MENU_STATUS+=(""); MENU_SECTIONS+=("")

    menu "Backup - $title" \
      "A backup of $title, kept separately from the mod so this" \
      "installer can never be the reason you lose them." "" \
      "~Backup goes to:  $BACKUPS/$kind" \
      "~On this PC now:  $n file(s)" \
      "~Backed up:       $(backup_when "$kind")"
    case "$MENU_RESULT" in ""|back) return ;; esac

    header "Backup - $title"
    case "$MENU_RESULT" in
      make)    backup_thing "$kind" ;;
      replace) backup_thing "$kind" replace ;;
      restore) restore_thing "$kind" ;;
      delete)
        if [ "$DRYRUN" -eq 1 ]; then say "(dry run - not deleted)" "$DIM"
        elif [ -d "$BACKUPS/$kind" ]; then rm -rf "$BACKUPS/$kind"; say "Backup deleted. The files on your PC are untouched." "$GN"
        else say "There was no backup to delete." "$DIM"; fi ;;
    esac
    pause_key
  done
}

act_backups() {
  local k st
  while true; do
    MENU_KEYS=(); MENU_LABELS=(); MENU_STATUS=(); MENU_SECTIONS=()
    for k in $(backup_kinds); do
      if has_backup "$k"; then st="$(backup_when "$k") · $(backup_files "$k") files"
      else st="no backup · $(source_files "$k") files here"; fi
      MENU_KEYS+=("$k"); MENU_LABELS+=("$(backup_label "$k")"); MENU_STATUS+=("$st"); MENU_SECTIONS+=("")
    done
    MENU_KEYS+=(back); MENU_LABELS+=("Back"); MENU_STATUS+=(""); MENU_SECTIONS+=("")
    menu "Backups" \
      "Back up your own textures, sounds, ReShade or mod folder before this" \
      "installer writes over them - and put them back whenever you like." "" \
      "~Everything is kept in:  $BACKUPS" \
      "~One plain folder per thing. Nothing in there is ever deleted by an" \
      "~install or an update - only by you, on the screen for that thing."
    case "$MENU_RESULT" in ""|back) return ;; esac
    act_backup_one "$MENU_RESULT"
  done
}


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
  repair_bad_aasamples
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

# ---------------------------------------------------------------------------
#  repair_bad_aasamples - take r_aaSamples 16 back out of a saved config.
#
#  Symptom on both platforms: the mod loads from the in-game Mods menu, the
#  screen goes black and the game freezes. console_zm.log ends on
#      Reading stats... / Reading backup stats...
#      COM_ERROR (0) E_INVALIDARG ... @ 0x74C0E0
#
#  Cause: GRAPHICS BOOST used to write r_aaSamples 16. That dvar is LATCHED, so
#  it is applied by the renderer restart that runs as the mod loads, before any
#  script of the mod executes. 16x MSAA is not a sample count the hardware can
#  create, so device creation fails and the frontend dies. The boot-time dvar
#  dump reports r_aaSamplesMax "8"; the game's own menu offers 1 / 2 / 4 / 8.
#
#  The mod no longer writes 16 - it reads r_aaSamplesMax. But a value already
#  saved in plutonium_zm.cfg still kills the next launch by itself, because the
#  config is exec'd long before any script runs. So it has to be taken out of
#  the live config AND out of the settings backup, which a later "put back"
#  would otherwise hand straight back to the player.
#
#  🛑 sed -i in place, ONE line, so every other byte and every line ending is
#  left exactly as it was. Rewriting the whole file is how ReShade.ini lost 150
#  bytes in v2.2.1.
# ---------------------------------------------------------------------------
repair_bad_aasamples() {
  local p v fixed=0
  for p in "$CFGDIR/plutonium_zm.cfg" "$BACKUPS/mod/settings/plutonium_zm.cfg"; do
    [ -f "$p" ] || continue
    v="$(sed -n 's/^[ \t]*seta[ \t]\+r_aaSamples[ \t]\+"\?\(-\?[0-9]\+\)"\?.*$/\1/p' "$p" | head -n1)"
    [ -n "$v" ] || continue
    case "$v" in 1|2|4|8) continue ;; esac

    say "Anti-aliasing was saved as ${v}x, which the game cannot start with." "$YE"
    say "That is what made the mod load to a black screen - setting it back." "$DIM"
    [ "$DRYRUN" -eq 1 ] && { say "(dry run - nothing changed)" "$DIM"; continue; }

    if sed -i 's/^\([ \t]*seta[ \t]\+r_aaSamples[ \t]\+\)"\?-\?[0-9]\+"\?.*$/\1"4"/' "$p"; then
      fixed=$((fixed+1))
      log "repaired r_aaSamples $v -> 4 in $p"
    else
      say "Could not change it - close Plutonium and run this again." "$RD"
      log "could not repair r_aaSamples in $p"
    fi
  done
  [ "$fixed" -gt 0 ] && say "Set back to 4x MSAA in $fixed file(s). The mod picks a safe value itself now." "$GN"
  return 0
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
  if [ "$MENU_RESULT" = "backup" ]; then backup_thing "$kind" || { pause_key; return; }; fi

  # -------------------------------------------------------------------------
  #  v2.2.1 - THE HD TEXTURE PACK NO LONGER SHIPS CONTROLLER ART.
  #  User, 2026-08-22: *"make sure the base mode doesn't install any controller
  #  icons if i did include any in the original texture pack images folder, so
  #  you can choose from 3 options based off what controller the user uses."*
  #  Measured: the pack contains exactly the 20 shared xenonbutton_* /
  #  xenon_controller_top names, so it was silently deciding the button prompts.
  #  Now the base install leaves the game's own icons alone.
  # -------------------------------------------------------------------------
  BLOCKED=""
  [ "$kind" = images ] && BLOCKED="$ICON_FILES"

  say "Copying $(count_after_block "$src") file(s), $(human "$(dir_bytes "$src")") ..."
  if copy_tree "$src" "$dest"; then
    write_manifest "$kind" "$src"
    [ -n "$BLOCKED" ] && say "Left out the controller icons - pick yours under Controller icons." "$DIM"
    BLOCKED=""
    printf '\n'; say "✅  $pretty installed." "$GN"
    # An install is a sync, so the purge can take a pack's icons with it once,
    # on an upgrade from v2.2.0 or earlier. Put them straight back.
    if [ "$kind" = images ]; then
      local pk isrc
      if pk="$(controller_pack)"; then
        if isrc="$(icon_source "$pk")"; then
          printf '\n'; say "Re-applying your $(controller_short "$pk") controller icons ..."
          copy_tree "$isrc" "$IMGDIR" && write_manifest controller "$isrc"
        fi
      fi
    fi
  else
    BLOCKED=""
    say "Copy FAILED." "$RD"
  fi
  pause_key
}

# ---------------------------------------------------------------------------
#  CONTROLLER ICONS - one screen, three packs, one slot.
# ---------------------------------------------------------------------------
act_controller() {
  local k pk n src
  pk="$(controller_pack)" || pk=""

  MENU_KEYS=(); MENU_LABELS=(); MENU_STATUS=(); MENU_SECTIONS=()
  local any=0
  while IFS= read -r k; do
    if src="$(icon_source "$k")"; then
      any=1
      n="$(find "$src" -type f -name '*.iwi' | wc -l | tr -d ' ')"
      MENU_KEYS+=("$k"); MENU_LABELS+=("$(controller_name "$k")")
      if [ "$k" = "$pk" ]; then MENU_STATUS+=("installed"); else MENU_STATUS+=("$n icons"); fi
      MENU_SECTIONS+=("")
    fi
  done < <(controller_keys)
  if [ "$any" -eq 0 ]; then
    header "Controller icons"
    say "No controller icon packs are in this download." "$YE"
    pause_key; return
  fi
  MENU_KEYS+=(back); MENU_LABELS+=("Cancel"); MENU_STATUS+=(""); MENU_SECTIONS+=("")

  local extra=""
  [ -n "$pk" ] && extra="~Installed now:  $(controller_name "$pk"). Picking another swaps it over."
  menu "Controller icons" \
    "Replaces the button prompts the game draws with the ones for your" \
    "controller. Pick one - they all replace the same files." "" \
    "~Goes to:  $IMGDIR" \
    "~The HD texture pack does not touch these, so installing it later will" \
    "~not undo your choice." \
    "$extra"
  case "$MENU_RESULT" in ""|back) return ;; esac

  local key="$MENU_RESULT"
  header "Controller icons - $(controller_name "$key")"
  log "action: install controller ($key)"
  src="$(icon_source "$key")" || { say "That pack is not in this download." "$YE"; pause_key; return; }

  backup_thing controller
  if [ -n "$pk" ] && [ "$pk" != "$key" ]; then
    say "Removing the $(controller_short "$pk") icons first ..."
    remove_by_manifest controller "$IMGDIR" || true
  fi
  say "Copying $(find "$src" -type f | wc -l | tr -d ' ') file(s) ..."
  if copy_tree "$src" "$IMGDIR"; then
    write_manifest controller "$src"
    set_controller_pack "$key"
    printf '\n'; say "✅  $(controller_name "$key") controller icons installed." "$GN"
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
  # -------------------------------------------------------------------------
  #  v2.2.1 - FOUR PRESETS, ONE RESHADE. All four Plutonium games run as the
  #  same executable out of the same bin folder, so ReShade resolves exactly one
  #  ReShade.ini and reads PresetPath from it once, at load: there is no way for
  #  it to pick a different preset per game on its own. All four are installed
  #  side by side, which puts them in ReShade's own preset list, and
  #  Ctrl+Shift+PgUp / PgDn steps between them in game. This picks the one to
  #  START on.
  #  🛑 They are not cosmetic variants: BO1, MW3 and WaW are Direct3D 9 and BO2
  #  is Direct3D 11, so the D3D9 presets use only pixel-shader effects.
  # -------------------------------------------------------------------------
  MENU_KEYS=(BO2.ini BO1.ini MW3.ini WAW.ini back)
  MENU_LABELS=("Install, and start on the Black Ops II preset" \
               "Install, and start on the Black Ops preset" \
               "Install, and start on the Modern Warfare 3 preset" \
               "Install, and start on the World at War preset" \
               "Cancel")
  MENU_STATUS=("recommended" "" "" "" "")
  MENU_SECTIONS=("" "" "" "" "")
  menu "ReShade" \
    "ReShade adds a sharpening / colour pass on top of the game. Press END in" \
    "game to open it. Four presets are installed, one per Plutonium game." "" \
    "~Goes to:  $BINDIR" "" \
    "!⚠️   ON LINUX THIS NEEDS ONE EXTRA STEP" \
    "~     Wine has to be told to load dxgi.dll. After installing, launch" \
    "~     Plutonium with:   WINEDLLOVERRIDES=\"dxgi=n,b\" <your usual command>" \
    "~     or add dxgi as a native override in Lutris / Bottles / winecfg." \
    "" \
    "!⚠️   PLUTONIUM MAY CLEAR THIS OUT AGAIN ON A LATER START" \
    "~     On Windows, Plutonium's launcher deletes any file in its own bin" \
    "~     folder it does not recognise every time it starts, which includes" \
    "~     ReShade - a background helper (Play BO2 with ReShade.bat) fixes" \
    "~     that there. This package has no Linux/Wine equivalent of that" \
    "~     helper yet, so if ReShade stops appearing after a Plutonium" \
    "~     update or restart, run this option again." \
    "" \
    "~Your existing ReShade.ini and BO2.ini are kept as .backup files."
  case "$MENU_RESULT" in ""|back) return ;; esac
  local start_preset="$MENU_RESULT"

  header "ReShade"
  local keep_shots keep_font
  keep_shots="$(keep_ini_value SavePath)"
  keep_font="$(keep_ini_value Font)"
  local f
  # NEVER overwrite a .backup that already exists - installing twice used to
  # copy the config THIS INSTALLER wrote over the only copy of the original.
  for f in ReShade.ini BO2.ini BO1.ini MW3.ini WAW.ini; do
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
    [ "$start_preset" != "BO2.ini" ] && set_ini_value PresetPath ".\\$start_preset"
    printf '\n'
    say "✅  ReShade installed, starting on the $(preset_game "$start_preset") preset." "$GN"
    say "Ctrl+Shift+PgUp / PgDn steps between the four presets in game." "$DIM"
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
  [ "$MENU_RESULT" = "restore" ] && restore_thing "$kind"
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
  for f in ReShade.ini BO2.ini BO1.ini MW3.ini WAW.ini; do
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

# ---------------------------------------------------------------------------
#  EVERYTHING - install, and remove, in one row each.
#
#  v2.1.3, bringing this script level with the Windows one. INSTALL EVERYTHING
#  shipped there in v2.0.6 and REMOVE EVERYTHING was asked for on 2026-08-21
#  (*"add an option to remove everything at the top of remove, similar to how
#  install has everything, simple."*); neither existed here, so the package was
#  offering Linux players a smaller menu than Windows players.
#
#  🌟 NOTHING IS REIMPLEMENTED, exactly as on Windows. menu() already answers
#  from $CHOICE without drawing whenever $HEADLESS is 1 - that is the door the
#  --action switch uses - so zmqol_pick below borrows it for one call and puts
#  both globals back. Whatever each act_* does interactively is precisely what
#  happens here, including every missing-file check, every backup, every
#  GitHub fallback and every manifest.
#
#  Row indices, read off each act_*'s own MENU_KEYS:
#     act_mod              0 = keep     (never wipe - an all-in-one must not be
#                                        the thing that forgets saved settings)
#     act_pack             0 = backup / 1 = plain
#     act_reshade          0 = go
#     act_remove_pack      the restore row EXISTS ONLY IF that backup does:
#                            backup present -> 0 = restore, 1 = plain
#                            no backup      -> 0 = plain
#     act_remove_reshade   0 = go
#     act_remove_mod       0 = keep
#
#  📝 The mod is removed LAST on purpose: act_remove_mod is what deletes the
#  mods/zm_qol folder, and the earlier steps still want to log into it.
# ---------------------------------------------------------------------------
zmqol_pick() {
  local choice="$1"; shift
  local o_headless="$HEADLESS" o_choice="$CHOICE"
  HEADLESS=1; CHOICE="$choice"
  "$@"
  HEADLESS="$o_headless"; CHOICE="$o_choice"
}

act_install_everything() {
  MENU_KEYS=(backup plain back)
  MENU_LABELS=("Back up my files first, then install it all" "Install it all without a backup" "Cancel")
  MENU_STATUS=("recommended" "" "")
  MENU_SECTIONS=("" "" "")
  # v2.3.0, 2026-08-26 - RESHADE PULLED OUT, matching the Windows installer.
  # A plain copy into Plutonium's bin does not survive Plutonium's own
  # launcher wiping unrecognised files out of that folder on every start
  # (verified on Windows via checkpoint 103 §2.3 and the user's own resident
  # helper script; the same plutonium-bootstrapper-win32 binary runs under
  # Wine here too, so the same wipe should apply, though that has not been
  # independently confirmed on Linux). Bundling it into a one-tap EVERYTHING
  # would repeat the exact "says installed, isn't" lie that was just fixed on
  # Windows. Windows now ships a background watchdog (Play BO2 with
  # ReShade.bat); this script does not yet have an equivalent, so ReShade
  # here is still the one-shot copy act_reshade always did - just no longer
  # silently bundled into EVERYTHING.
  menu "Install everything" \
    "Installs every part of this package, one after the other:" \
    "~   the mod  ·  HD texture pack  ·  custom sounds" \
    "" \
    "~ReShade is its own menu row, not part of this - it needs its own step" \
    "~and is not guaranteed to survive Plutonium restarting; see that row." \
    "" \
    "~Any part whose files are not in this download - and cannot be fetched" \
    "~from GitHub - is reported and skipped. Nothing else stops." \
    "" \
    "~Your saved menu settings are always kept." \
    "" \
    "!⚠️   THIS OVERWRITES CUSTOM TEXTURES AND SOUNDS ALREADY IN PLUTONIUM"
  case "$MENU_RESULT" in ""|back) return ;; esac

  local sub=1
  [ "$MENU_RESULT" = "backup" ] && sub=0
  log "action: install everything ($MENU_RESULT)"

  zmqol_pick 0     act_mod
  zmqol_pick "$sub" act_pack images "HD texture pack" "$IMGDIR" "THIS OVERWRITES ANY CUSTOM TEXTURES ALREADY IN THAT FOLDER"
  zmqol_pick "$sub" act_pack zone   "custom sounds"   "$ZONEDIR" "THIS REPLACES ANY CUSTOM SOUNDS ALREADY IN THAT FOLDER"

  header "Install everything"
  say "Where things stand now:"
  printf '\n'
  say "The mod            $(mod_version "$MODDIR/mod.json" 2>/dev/null || echo 'not installed')"
  say "HD texture pack    $( [ -f "$STATE/installed-images.txt" ] && echo installed || echo 'not installed')"
  say "Custom sounds      $( [ -f "$ZONEDIR/${SOUND_FILES[0]}" ] && echo installed || echo 'not installed')"
  printf '\n'
  say "ReShade was not part of this - pick that row if you want it."
  pause_key
}

act_remove_everything() {
  local img_b=0 snd_b=0
  has_backup images && img_b=1
  has_backup zone   && snd_b=1
  # v2.2.0 - the PS5 icons go with everything else.
  local ds_b=0
  has_backup controller && ds_b=1

  MENU_KEYS=(); MENU_LABELS=(); MENU_STATUS=(); MENU_SECTIONS=()
  if [ "$img_b" -eq 1 ] || [ "$snd_b" -eq 1 ]; then
    MENU_KEYS+=(restore); MENU_LABELS+=("Remove it all and put my original files back"); MENU_STATUS+=("backup found"); MENU_SECTIONS+=("")
  fi
  MENU_KEYS+=(plain); MENU_LABELS+=("Just remove it all"); MENU_STATUS+=(""); MENU_SECTIONS+=("")
  MENU_KEYS+=(back);  MENU_LABELS+=("Cancel");            MENU_STATUS+=(""); MENU_SECTIONS+=("")

  menu "Remove everything" \
    "Removes every part of this package, one after the other:" \
    "~   HD textures · custom sounds · controller icons · ReShade · the mod" \
    "" \
    "~Only files this installer put there are deleted. Anything that was" \
    "~already in those folders is left exactly where it is." \
    "" \
    "~Your saved menu settings are KEPT. To wipe them instead, use Remove the mod."
  case "$MENU_RESULT" in ""|back) return ;; esac

  local restore=0
  [ "$MENU_RESULT" = "restore" ] && restore=1
  log "action: remove everything ($MENU_RESULT)"

  # The restore row is only present when that particular backup is, so the
  # index of "plain" moves with it.
  local ip=0 sp=0 dp=0
  [ "$img_b" -eq 1 ] && [ "$restore" -eq 0 ] && ip=1
  [ "$snd_b" -eq 1 ] && [ "$restore" -eq 0 ] && sp=1
  [ "$ds_b"  -eq 1 ] && [ "$restore" -eq 0 ] && dp=1

  zmqol_pick "$ip" act_remove_pack images "HD textures"   "$IMGDIR"
  zmqol_pick "$sp" act_remove_pack zone   "custom sounds" "$ZONEDIR"
  zmqol_pick "$dp" act_remove_pack controller "controller icons" "$IMGDIR"
  zmqol_pick 0     act_remove_reshade
  zmqol_pick 0     act_remove_mod

  header "Remove everything"
  say "Where things stand now:"
  printf '\n'
  say "HD texture pack    $( [ -f "$STATE/installed-images.txt" ] && echo 'still installed' || echo 'removed')"
  say "Custom sounds      $( [ -f "$ZONEDIR/${SOUND_FILES[0]}" ] && echo 'still installed' || echo 'removed')"
  say "Controller icons   $( [ -f "$STATE/installed-controller.txt" ] && echo 'still installed' || echo 'removed')"
  say "ReShade            $( [ -f "$BINDIR/dxgi.dll" ] && echo 'still installed' || echo 'removed')"
  say "The mod            $( [ -f "$MODDIR/mod.json" ] && echo 'still installed' || echo 'removed')"
  pause_key
}

# ------------------------------------------------------------------ network --
have_net() { command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1; }

api_latest() {
  local url="https://api.github.com/repos/$REPO/releases/latest"
  if command -v curl >/dev/null 2>&1; then curl -fsSL -H 'User-Agent: zm_qol-installer' "$url" 2>/dev/null
  else wget -qO- --header='User-Agent: zm_qol-installer' "$url" 2>/dev/null; fi
}

api_releases() {
  local url="https://api.github.com/repos/$REPO/releases?per_page=30"
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
  # Look in the latest release, then fall back to the recent ones. The texture
  # and sound packs are 524 MB and 641 MB, so they stay attached to the release
  # they were built for instead of being re-uploaded on every patch.
  local json url
  json="$(api_latest)" || true
  [ -n "$json" ] && url="$(asset_url "$json" "$asset")"
  if [ -z "${url:-}" ]; then
    json="$(api_releases)" || true
    [ -n "$json" ] && url="$(asset_url "$json" "$asset")"
  fi
  [ -z "${url:-}" ] && return 1
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
    # v2.2.1 - the sounds row is MANIFEST-first, like the textures row, so that
    # "installed" always means "installed by this installer" and can never
    # disagree with what Remove the custom sounds will say. See the long note in
    # the Windows script's Get-Status: restoring your own backup put three files
    # with the same three names back, and the old file-presence test read them
    # as ours.
    if [ -f "$STATE/installed-zone.txt" ]; then
      sndst="installed"
    else
      local nsnd=0 sf
      for sf in "${SOUND_FILES[@]}"; do [ -f "$ZONEDIR/$sf" ] && nsnd=$(( nsnd + 1 )); done
      if [ "$nsnd" -gt 0 ]; then sndst="$nsnd files already there (not mine)"; else sndst="not installed"; fi
    fi
    if [ -f "$BINDIR/dxgi.dll" ]; then rshst="installed"; else rshst="not installed"; fi

    local nbk=0 bk nkinds=0
    for bk in $(backup_kinds); do nkinds=$(( nkinds + 1 )); has_backup "$bk" && nbk=$(( nbk + 1 )); done
    local bkst="nothing backed up yet"
    [ "$nbk" -gt 0 ] && bkst="$nbk of $nkinds backed up"

    # v2.1.3 - the two EVERYTHING rows, one at the top of each section, so this
    # menu matches the Windows one exactly. See act_install_everything and
    # act_remove_everything for why neither reimplements anything.
    # v2.2.1 - one Controller icons row leading to the three packs, mirroring
    # the Windows menu row for row.
    local dsst pkk
    if pkk="$(controller_pack)"; then
      dsst="$(controller_short "$pkk") - $(wc -l < "$STATE/installed-controller.txt" | tr -d ' ') icons installed"
    else
      dsst="none - the game's own"
    fi
    MENU_KEYS=(all mod images sounds reshade controller rall rimages rsounds rreshade rcontroller rmod backups update details quit)
    MENU_LABELS=("EVERYTHING - the whole package" \
                 "The mod" "HD texture pack" "Custom sounds" "ReShade + presets" "Controller icons" \
                 "EVERYTHING - the whole package" \
                 "Remove the HD textures" "Remove the custom sounds" "Remove ReShade" "Remove the controller icons" "Remove the mod" \
                 "Back up / restore my own files" \
                 "Check for a newer version" "Details and log" "Quit")
    MENU_STATUS=("mod + textures + sounds + ReShade" "$modst" "$imgst" "$sndst" "$rshst" "$dsst" \
                 "textures + sounds + icons + ReShade + mod" "" "" "" "" "" \
                 "$bkst" "" "" "")
    MENU_SECTIONS=("INSTALL" "INSTALL" "INSTALL" "INSTALL" "INSTALL" "INSTALL" \
                   "REMOVE" "REMOVE" "REMOVE" "REMOVE" "REMOVE" "REMOVE" \
                   "BACKUP" \
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
      all)      act_install_everything ;;
      rall)     act_remove_everything ;;
      mod)      act_mod ;;
      images)   act_pack images "HD texture pack" "$IMGDIR" "THIS OVERWRITES ANY CUSTOM TEXTURES ALREADY IN THAT FOLDER" ;;
      sounds)   act_pack zone   "custom sounds"   "$ZONEDIR" "THIS REPLACES ANY CUSTOM SOUNDS ALREADY IN THAT FOLDER" ;;
      reshade)  act_reshade ;;
      controller) act_controller ;;
      rcontroller) act_remove_pack controller "controller icons" "$IMGDIR" ;;
      rimages)  act_remove_pack images "HD textures"   "$IMGDIR" ;;
      rsounds)  act_remove_pack zone   "custom sounds" "$ZONEDIR" ;;
      rreshade) act_remove_reshade ;;
      rmod)     act_remove_mod ;;
      backups)  act_backups ;;
      update)   act_update ;;
      details)  act_details ;;
    esac
  done
}

log "--- installer started (dryrun=$DRYRUN) ---"
move_old_backups
migrate_dualsense

if [ -n "$ACTION" ]; then
  case "$ACTION" in
    all)      act_install_everything ;;
    rall)     act_remove_everything ;;
    mod)      act_mod ;;
    images)   act_pack images "HD texture pack" "$IMGDIR" "THIS OVERWRITES ANY CUSTOM TEXTURES ALREADY IN THAT FOLDER" ;;
    sounds)   act_pack zone   "custom sounds"   "$ZONEDIR" "THIS REPLACES ANY CUSTOM SOUNDS ALREADY IN THAT FOLDER" ;;
    reshade)  act_reshade ;;
    controller) act_controller ;;
    rcontroller) act_remove_pack controller "controller icons" "$IMGDIR" ;;
    rimages)  act_remove_pack images "HD textures"   "$IMGDIR" ;;
    rsounds)  act_remove_pack zone   "custom sounds" "$ZONEDIR" ;;
    rreshade) act_remove_reshade ;;
    rmod)     act_remove_mod ;;
    backups)  act_backups ;;
    backup)   backup_thing "${CHOICE_KIND:-images}" ;;
    restore)  restore_thing "${CHOICE_KIND:-images}" ;;
    update)   act_update ;;
    details)  act_details ;;
    *) echo "unknown action: $ACTION" ;;
  esac
  exit 0
fi

main_menu
header "Bye"
printf '     %sLaunch Plutonium T6  →  Zombies  →  Mods  →  %s%s\n\n' "$GN" "$MODNAME" "$R"
