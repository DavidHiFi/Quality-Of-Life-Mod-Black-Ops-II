#!/usr/bin/env python3
"""
preflight.py - offline pre-flight checks for zm_qol.

DRAFTED BY THE ARENA AGENT. UNVERIFIED ON THE REAL MACHINE.
It has been run against this repo in the Arena sandbox (results in HANDOFF.md),
but it has never run on the user's PC and has never gated a real build.

WHAT THIS IS FOR
    gsc-tool -m parse is syntax only. It passes files that kill every map at
    load. This checks a handful of things that are decidable from the source
    text alone, and it is deliberately narrow: every check here either reports
    a fact or says nothing.

WHAT THIS IS NOT
    Not a substitute for gsc-tool, build.bat, or booting the game. It cannot
    see clientfield bit budgets (needs the per-map dumps), cannot know whether
    a stock function name is real (needs the gsc-dump), and cannot validate
    LUI. Those need the real workspace; see HANDOFF.md.

EXIT CODES
    0  no ERRORs (warnings and notes may still be printed)
    1  at least one ERROR
    2  bad usage / repo root not found

USAGE
    python preflight.py                 # check the repo this file sits in
    python preflight.py --root <path>
    python preflight.py --quiet         # errors only
"""

import argparse
import os
import re
import sys

# --------------------------------------------------------------------------
# Comment stripping.
#
# 🛑 THIS IS THE MOST IMPORTANT FUNCTION IN THE FILE AND IT IS WHY THE
# NAIVE VERSION OF THIS TOOL IS USELESS.
#
# Measured in this repo, 2026-08-23: a grep for map-scoped externals that did
# not strip comments reported scripts/zm/replaced/_zm.gsc and
# scripts/zm/replaced/_zm_buildables_pooled.gsc as referenced files. Neither
# file exists. Both "references" are inside // comments - one is a line of
# example code in a note, the other describes what BO2-Reimagined does.
#
# This project's GSC is heavily commented with real code samples in the prose,
# so any checker that does not strip comments first will cry wolf constantly
# and get ignored. Which is the same as not having it.
# --------------------------------------------------------------------------

def strip_comments(src):
    """Remove // and /* */ comments, preserving newlines and string literals.

    Character-by-character scan rather than a regex, because a regex cannot
    tell a // inside a string from a real comment. Newlines are preserved so
    that reported line numbers still match the original file.
    """
    out = []
    i = 0
    n = len(src)
    in_line_comment = False
    in_block_comment = False
    in_string = False
    while i < n:
        c = src[i]
        nxt = src[i + 1] if i + 1 < n else ''
        if in_line_comment:
            if c == '\n':
                in_line_comment = False
                out.append(c)
            else:
                out.append(' ')
        elif in_block_comment:
            if c == '*' and nxt == '/':
                in_block_comment = False
                out.append('  ')
                i += 2
                continue
            out.append('\n' if c == '\n' else ' ')
        elif in_string:
            out.append(c)
            if c == '\\':
                # Escape: consume the next char verbatim so \" does not end it.
                if i + 1 < n:
                    out.append(nxt)
                    i += 2
                    continue
            elif c == '"':
                in_string = False
        else:
            if c == '/' and nxt == '/':
                in_line_comment = True
                out.append('  ')
                i += 2
                continue
            if c == '/' and nxt == '*':
                in_block_comment = True
                out.append('  ')
                i += 2
                continue
            if c == '"':
                in_string = True
            out.append(c)
        i += 1
    return ''.join(out)


def read(path):
    with open(path, 'rb') as fh:
        raw = fh.read()
    return raw.decode('utf-8', errors='replace')


def line_of(text, idx):
    return text.count('\n', 0, idx) + 1


# --------------------------------------------------------------------------
# Findings
# --------------------------------------------------------------------------

class Report:
    def __init__(self, quiet=False):
        self.errors = []
        self.warnings = []
        self.notes = []
        self.quiet = quiet

    def error(self, check, msg):
        self.errors.append((check, msg))

    def warn(self, check, msg):
        self.warnings.append((check, msg))

    def note(self, check, msg):
        self.notes.append((check, msg))

    def dump(self):
        def block(title, items, symbol):
            if not items:
                return
            print(f"\n{symbol} {title} ({len(items)})")
            for check, msg in items:
                print(f"    [{check}] {msg}")
        block("ERROR", self.errors, "X")
        if not self.quiet:
            block("WARNING", self.warnings, "!")
            block("NOTE", self.notes, "-")


# --------------------------------------------------------------------------
# CHECK 1 - map-scoped externals reachable from a root script
#
# Rule: scripts/zm/NAME.gsc loads on EVERY map. A qualified reference like
# maps\mp\zm_tomb_dig::swap_weapon resolves at script LOAD time, so one sitting
# in a root script throws "Unresolved external" on every OTHER map. A runtime
# if (level.script == "...") guard does NOT prevent this.
#
# 🛑 SCOPE, MEASURED IN THIS REPO - the naive form of this check is WRONG.
# scripts/zm/replaced/ and scripts/zm/locs/ are subfolders, and pack_iwd.ps1
# packs scripts/ recursively, so their files ship. But they are NOT auto-run
# root scripts: replaced/zm_transit_gamemodes.gsc holds 17 map-scoped refs and
# is reached only through a replaceFunc from scripts/zm/zm_transit/zm_transit.gsc,
# which is TranZit-only. Flagging those 17 would be a false positive.
#
# Only files DIRECTLY in scripts/zm/ are treated as root scripts here. That is
# the set Plutonium auto-runs main()/init() on.
#
# ⚠️ UNVERIFIED ASSUMPTION, stated rather than hidden: this check assumes a
# file under a subfolder is only loaded when something on that map's path
# references it. That is what the project's own docs say and what the shipped
# build's behaviour is consistent with, but the Arena agent cannot boot the
# game to prove it. If a subfolder script is in fact auto-run, this check is
# scoped too narrowly.
# --------------------------------------------------------------------------

MAP_PREFIXES = (
    'zm_transit', 'zm_nuked', 'zm_highrise', 'zm_prison', 'zm_buried', 'zm_tomb',
)

# Globally safe roots per the project's own rule 2.
SAFE_RE = re.compile(r'maps\\mp\\(_utility|zombies\\|gametypes_zm\\|animscripts\\|_visionset_mgr|_demo)')

MAPSCOPED_RE = re.compile(r'maps\\mp\\(zm_[a-z_0-9]+)::([a-z_0-9]+)', re.IGNORECASE)


def check_root_scope(root, rep):
    zm_dir = os.path.join(root, 'scripts', 'zm')
    if not os.path.isdir(zm_dir):
        rep.warn('root-scope', 'scripts/zm not found; check skipped')
        return
    root_scripts = sorted(
        f for f in os.listdir(zm_dir)
        if f.endswith(('.gsc', '.csc')) and os.path.isfile(os.path.join(zm_dir, f))
    )
    for name in root_scripts:
        path = os.path.join(zm_dir, name)
        src = strip_comments(read(path))
        for m in MAPSCOPED_RE.finditer(src):
            script = m.group(1)
            if not script.startswith(MAP_PREFIXES):
                continue
            if SAFE_RE.match(m.group(0)):
                continue
            rep.error(
                'root-scope',
                f'scripts/zm/{name}:{line_of(src, m.start())} references '
                f'{m.group(0)} - map-scoped external in a root script '
                f'(loads on every map). Move it to scripts/zm/{script}/{script}.gsc.'
            )


# --------------------------------------------------------------------------
# CHECK 2 - dvars read but never registered
#
# getdvarintdefault()/getdvarfloatdefault() return the default WITHOUT creating
# the dvar. An unregistered dvar does not exist until something creates it, so
# typing its name at the console is an unknown command that silently does
# nothing. This cost this project two boots on zmqol_minimal (qol_options.gsc
# header records it).
#
# A dvar is considered registered if any .gsc/.csc calls qol_opt_dvar("name")
# or setdvar("name"), or any .lua writes it (a menu row creates the dvar).
# Engine dvars the mod only reads are excluded by an explicit allowlist below -
# adding a name there is a deliberate act, not a silent pass.
# --------------------------------------------------------------------------

# Engine-owned dvars: created by the engine, read-only from the mod's side.
# Every entry is a dvar that appears in the game's own boot-time dvar dump,
# or (createfx) is a stock dvar read by stock client scripts this mod ships.
ENGINE_DVARS = {
    'developer', 'g_gametype', 'mapname', 'ui_gametype', 'ui_zm_mapstartlocation',
    'r_aaSamplesMax', 'r_exposureValue', 'r_lightTweakSunLight',
    'scr_tesla_arc_delay', 'scr_tesla_idle_loop', 'createfx',
}

# --------------------------------------------------------------------------
# Dvars the project's OWN DOCUMENTATION tells the user to type at the console.
#
# 🛑 THIS LIST IS THE WHOLE POINT OF THE CHECK, AND IT IS NOT GUESSWORK.
# Every name is transcribed from MOD_CATALOGUE.md section 2b ("Console dvars")
# and sections 11b / 2a, which the project maintains as its user-facing
# reference. If a name here is unregistered, a user following the project's own
# docs types it and gets "Unknown cmd" - the exact zmqol_minimal failure that
# cost this project two boots.
#
# An unregistered dvar that is NOT in this list is usually an internal tuning
# knob read once at init with a sensible default. Those are reported as notes,
# not warnings, because nothing tells a user to set them.
#
# ⚠️ MAINTENANCE: when MOD_CATALOGUE section 2b changes, change this too. The
# doc is the source of truth; this is a transcription of it.
# --------------------------------------------------------------------------
DOCUMENTED_CONSOLE_DVARS = {
    # section 2b, the main list
    'fly', 'night_mode', 'rapid_fire', 'character', 'coop_pause', 'no_power',
    'lod_fix', 'hud_master', 'hud_all', 'hud_timers', 'hud_health_bar',
    'hud_remaining', 'hud_zone', 'hud_round_left', 'hud_color',
    'hud_color_health', 'hud_color_timer', 'hud_color_round_timer',
    'zmqol_ring_hud_hide', 'zmqol_ring_hud_delay',
    'sv_deathmachine_duration', 'sv_deathmachine_powerup', 'redhitmarkers',
    'disable_player_quotes', 'r_sky_intensity_factor0',
    'anim_pap_camo_buried', 'anim_pap_camo_mob', 'anim_pap_camo_origins',
    # Wunderfizz tuning, section 2b
    'zmqol_wf_fx', 'zmqol_wf_fx_ug', 'zmqol_wf_fx_range', 'zmqol_wf_yaw_off',
    'zmqol_wf_wall_gap', 'zmqol_wf_axis_snap',
    # Diner tuning, section 2b
    'zmqol_pap_diner_x', 'zmqol_pap_diner_y', 'zmqol_pap_diner_z',
    'zmqol_pap_diner_yaw', 'zmqol_diner_hatch_clip', 'zmqol_diner_hatch_ladder',
    # section 2a / 11b
    'zmqol_testsound', 'zmqol_mp_weapons', 'zmqol_ww', 'zmqol_box_ww_rarity',
}

GETDVAR_RE = re.compile(r'getdvar(?:int|float|)?default?\s*\(\s*"([A-Za-z_0-9]+)"', re.IGNORECASE)
GETDVAR_PLAIN_RE = re.compile(r'getdvar\s*\(\s*"([A-Za-z_0-9]+)"', re.IGNORECASE)
QOL_OPT_RE = re.compile(r'qol_opt_dvar\s*\(\s*"([A-Za-z_0-9]+)"')
SETDVAR_RE = re.compile(r'set(?:client)?dvar\s*\(\s*"([A-Za-z_0-9]+)"', re.IGNORECASE)


def gather_scripts(root):
    out = []
    for base, dirs, files in os.walk(root):
        if '.git' in base.split(os.sep):
            continue
        for f in files:
            if f.endswith(('.gsc', '.csc')):
                out.append(os.path.join(base, f))
    return sorted(out)


def gather_lua(root):
    out = []
    for base, dirs, files in os.walk(root):
        if '.git' in base.split(os.sep):
            continue
        for f in files:
            if f.endswith('.lua'):
                out.append(os.path.join(base, f))
    return sorted(out)


def check_dvar_registration(root, rep):
    scripts = gather_scripts(root)
    registered = set()
    read_at = {}

    for path in scripts:
        src = strip_comments(read(path))
        for m in QOL_OPT_RE.finditer(src):
            registered.add(m.group(1))
        for m in SETDVAR_RE.finditer(src):
            registered.add(m.group(1))
        for rx in (GETDVAR_RE, GETDVAR_PLAIN_RE):
            for m in rx.finditer(src):
                read_at.setdefault(m.group(1), []).append(
                    f'{os.path.relpath(path, root)}:{line_of(src, m.start())}'
                )

    lua_text = ''
    for path in gather_lua(root):
        lua_text += read(path)

    for name in sorted(read_at):
        if name in registered or name in ENGINE_DVARS:
            continue
        if re.search(r'\b' + re.escape(name) + r'\b', lua_text):
            # A LUI row writes it, so the dvar is created when the menu loads.
            continue
        where = read_at[name][0]
        count = len(read_at[name])
        if name in DOCUMENTED_CONSOLE_DVARS:
            rep.warn(
                'dvar-undocumented-silent',
                f'"{name}" is documented in MOD_CATALOGUE as console-settable, '
                f'is read {count}x (first at {where}), and is registered '
                f'NOWHERE. getdvar*default() returns the default without '
                f'creating the dvar, so typing "{name} 1" at the console is an '
                f'unknown command that silently does nothing. '
                f'Fix: qol_opt_dvar( "{name}", "<current default>" ); in '
                f'qol_options.gsc::init().'
            )
        else:
            rep.note(
                'dvar-internal',
                f'"{name}" read {count}x (first at {where}), never registered. '
                f'Not in MOD_CATALOGUE section 2b, so presumed an internal knob '
                f'- harmless unless it is meant to be user-settable.'
            )


# --------------------------------------------------------------------------
# CHECK 3 - raw .efx line endings
#
# A raw .efx shipped in mod.iwd\fx\ must be CRLF. On an LF file loadfx()
# returns undefined with no error, no "Could not load fx" line, and no
# "Loaded fx:" line either. ERROR_CATALOGUE 22 records 36 files that sat
# broken for a year because only the two that first exposed it were fixed.
#
# 🛑 grep -c $'\r' is unreliable here (reports CRLF for an LF-only file).
# Count the bytes instead, which is what this does.
# --------------------------------------------------------------------------

def check_efx_line_endings(root, rep):
    fx_dir = os.path.join(root, 'fx')
    if not os.path.isdir(fx_dir):
        rep.note('efx-crlf', 'no fx/ folder; check skipped')
        return
    total = 0
    bad = []
    versions = {}
    for base, dirs, files in os.walk(fx_dir):
        for f in files:
            if not f.endswith('.efx'):
                continue
            path = os.path.join(base, f)
            with open(path, 'rb') as fh:
                data = fh.read()
            total += 1
            if data.count(b'\r') != data.count(b'\n'):
                bad.append(os.path.relpath(path, root))
            head = data[:16].split(b'\r')[0].split(b'\n')[0]
            versions[head.decode('ascii', 'replace')] = versions.get(
                head.decode('ascii', 'replace'), 0) + 1
    for p in bad:
        rep.error('efx-crlf', f'{p} has LF line endings - loadfx() will return '
                              f'undefined silently. Convert to CRLF.')
    rep.note('efx-crlf', f'{total} .efx checked, {len(bad)} bad')
    for ver, count in sorted(versions.items()):
        rep.note('efx-version', f'{count} x header "{ver}"')


# --------------------------------------------------------------------------
# CHECK 4 - font names
#
# createfontstring() takes a real T6 font name. "hudsmall" is not one; the
# engine rejected it silently on every call for months (v2.2.5 fixed 5 sites).
# The valid list below is the engine's own, as printed in the crashdump that
# found the bug - it is quoted in MOD_CATALOGUE 13 and CLAUDE.md.
#
# ⚠️ If a name is flagged that you believe is valid, do NOT just add it here.
# Confirm it against the engine's own list first.
# --------------------------------------------------------------------------

VALID_FONTS = {
    'default', 'bigfixed', 'smallfixed', 'objective', 'big', 'small',
    'hudbig', 'extrabig', 'normal',
}

FONTSTRING_RE = re.compile(r'createfontstring\s*\(\s*"([A-Za-z_0-9]+)"', re.IGNORECASE)


def check_fonts(root, rep):
    seen = {}
    for path in gather_scripts(root):
        src = strip_comments(read(path))
        for m in FONTSTRING_RE.finditer(src):
            name = m.group(1)
            seen[name] = seen.get(name, 0) + 1
            if name.lower() not in VALID_FONTS:
                rep.error(
                    'font-name',
                    f'{os.path.relpath(path, root)}:{line_of(src, m.start())} '
                    f'createfontstring("{name}") - not a known T6 font name. '
                    f'The engine rejects it silently.'
                )
    for name, count in sorted(seen.items()):
        rep.note('font-name', f'{count} x "{name}"')


# --------------------------------------------------------------------------
# CHECK 5 - functions that are not T6 builtins
#
# Names a model is likely to reach for that do not exist in T6. Each one here
# is listed because it has either bitten this project or is a close cousin of
# one that did. array_slice is the recorded case: zero uses in the stock dump,
# would have failed at runtime.
#
# This is a DENYLIST, not a validator. It cannot tell you a name is real -
# only that these specific names are not. Confirming a stock function exists
# needs the 2,093-file gsc-dump, which is on the user's PC.
# --------------------------------------------------------------------------

NOT_T6_BUILTINS = {
    'array_slice': 'not a T6 builtin (0 uses in the stock dump)',
    'array_map': 'not a T6 builtin',
    'array_filter': 'not a T6 builtin',
    'str_split': 'not a T6 builtin - use strTok',
    'string_split': 'not a T6 builtin - use strTok',
    'array_merge_unique': 'not a T6 builtin',
}


def check_fake_builtins(root, rep):
    for path in gather_scripts(root):
        src = strip_comments(read(path))
        for name, why in NOT_T6_BUILTINS.items():
            for m in re.finditer(r'\b' + re.escape(name) + r'\s*\(', src):
                # A local definition makes it legal.
                if re.search(r'^\s*' + re.escape(name) + r'\s*\(', src, re.MULTILINE):
                    continue
                rep.error(
                    'fake-builtin',
                    f'{os.path.relpath(path, root)}:{line_of(src, m.start())} '
                    f'calls {name}() - {why}'
                )


# --------------------------------------------------------------------------
# CHECK 6 - clientfield registration symmetry (REPORTING ONLY)
#
# 🛑 THIS CHECK DELIBERATELY DOES NOT PASS OR FAIL ANYTHING.
#
# A server registerclientfield with no client counterpart is
# EXE_CLIENT_FIELD_MISMATCH, fatal at load. But deciding symmetry from source
# text alone is NOT possible here, for reasons that are documented facts in
# this project:
#
#   - Most of the mod's server registrations are deliberate mirrors of
#     UNCONDITIONAL STOCK client registrations. The client half is in a stock
#     .csc that is not in this repo. Absence here is not absence in the game.
#   - Registration can be list-driven (level.zombie_include_powerups), so the
#     field name never appears in a registerclientfield call at all.
#   - Guards must match on both sides; the three Vulture guards live in two
#     files and six functions must agree.
#
# So this prints an inventory for a human to read against the real dumps. It
# is a worksheet, not a verdict. Anything else would be a guess.
# --------------------------------------------------------------------------

CF_RE = re.compile(
    r'registerclientfield\s*\(\s*"([a-z]+)"\s*,\s*"([A-Za-z_0-9]+)"\s*,\s*([0-9]+)\s*,\s*([0-9]+)',
    re.IGNORECASE)


def check_clientfields(root, rep):
    server = {}
    client = {}
    for path in gather_scripts(root):
        src = strip_comments(read(path))
        target = client if path.endswith('.csc') else server
        for m in CF_RE.finditer(src):
            cset, name, ver, bits = m.groups()
            target.setdefault((cset, name), []).append(
                (os.path.relpath(path, root), line_of(src, m.start()), bits))

    only_server = sorted(set(server) - set(client))
    if only_server:
        rep.note('clientfield',
                 f'{len(only_server)} field(s) registered server-side with no '
                 f'.csc counterpart IN THIS REPO. Most are mirrors of stock '
                 f'client registrations, which are not in this tree. Check each '
                 f'against the stock .csc dump before acting:')
        for cset, name in only_server:
            where = server[(cset, name)][0]
            rep.note('clientfield', f'    [{cset}] {name}  ({where[0]}:{where[1]}, {where[2]} bits)')

    for key in sorted(set(server) & set(client)):
        sbits = {b for _, _, b in server[key]}
        cbits = {b for _, _, b in client[key]}
        if sbits != cbits:
            rep.error(
                'clientfield',
                f'[{key[0]}] {key[1]} bit-width disagrees: server {sorted(sbits)} '
                f'vs client {sorted(cbits)}. This is fatal at load.'
            )


# --------------------------------------------------------------------------

CHECKS = [
    ('root-scope', check_root_scope),
    ('dvar-unregistered', check_dvar_registration),
    ('efx-crlf', check_efx_line_endings),
    ('font-name', check_fonts),
    ('fake-builtin', check_fake_builtins),
    ('clientfield', check_clientfields),
]


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--root', default=None, help='repo root (default: parent of this file)')
    ap.add_argument('--quiet', action='store_true', help='print errors only')
    args = ap.parse_args()

    root = args.root or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    if not os.path.isdir(os.path.join(root, 'scripts')):
        print(f'ERROR: {root} does not look like the zm_qol repo (no scripts/).')
        return 2

    print(f'preflight.py - checking {root}')
    print('DRAFTED BY THE ARENA AGENT, UNVERIFIED ON THE REAL MACHINE.')
    print('Syntax is gsc-tool\'s job. This checks what gsc-tool cannot see.')

    rep = Report(quiet=args.quiet)
    for name, fn in CHECKS:
        try:
            fn(root, rep)
        except Exception as exc:                      # noqa: BLE001
            rep.error(name, f'check crashed: {exc!r}')

    rep.dump()
    print(f'\n{len(rep.errors)} error(s), {len(rep.warnings)} warning(s).')
    return 1 if rep.errors else 0


if __name__ == '__main__':
    sys.exit(main())
