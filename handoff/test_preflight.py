#!/usr/bin/env python3
"""
test_preflight.py - self-test for preflight.py.

Run:  python test_preflight.py
Exit: 0 all pass, 1 any fail.

WHY THIS EXISTS
    A checker that has only ever been run against a clean tree has not been
    shown to catch anything. Every KNOWN-BAD case below is a real bug this
    project actually shipped, reconstructed in miniature; every KNOWN-GOOD
    case is a shape that must NOT be flagged, including the exact false
    positive the first draft of preflight.py produced.

    No fixture here is invented. Sources are cited per case.
"""

import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PREFLIGHT = os.path.join(HERE, 'preflight.py')

# (filename, content) fixtures
CASES = []


def case(name, expect_check, expect_flagged, files, why):
    CASES.append({
        'name': name,
        'check': expect_check,
        'flagged': expect_flagged,
        'files': files,
        'why': why,
    })


# -------------------------------------------------------------------------
# KNOWN-BAD - each is a real shipped bug
# -------------------------------------------------------------------------

case(
    'hudsmall font', 'font-name', True,
    {'scripts/zm/a.gsc':
     'init()\n{\n    self.h = createfontstring( "hudsmall", 1.5 );\n}\n'},
    'MOD_CATALOGUE 13 / commit cb6776c: "hudsmall" is not a T6 font. The engine '
    'rejected it on every call since the lines were written, leaving five HUD '
    'elements on the default font. Found in a crashdump, not the console.'
)

case(
    'map-scoped external in root script', 'root-scope', True,
    {'scripts/zm/a.gsc':
     'main()\n{\n    if ( level.script == "zm_tomb" )\n'
     '        maps\\mp\\zm_tomb_dig::swap_weapon();\n}\n'},
    'ERROR_CATALOGUE 3 / AI_CONTEXT rule 2: resolves at LOAD time, so this '
    'crashes every OTHER map. The runtime level.script guard does NOT help - '
    'that is the whole trap.'
)

case(
    'fake builtin array_slice', 'fake-builtin', True,
    {'scripts/zm/a.gsc': 'init()\n{\n    a = array_slice( x, 0, 3 );\n}\n'},
    'qol_options.gsc header: an earlier draft of the .help fix used array_slice, '
    'which has zero uses in the stock dump and would have failed at runtime.'
)

case(
    'clientfield width mismatch', 'clientfield', True,
    {'scripts/zm/a.gsc':
     'main()\n{\n    registerclientfield( "toplayer", "t", 9000, 5, "int" );\n}\n',
     'scripts/zm/a.csc':
     'main()\n{\n    registerclientfield( "toplayer", "t", 9000, 4, "int" );\n}\n'},
    'ERROR_CATALOGUE 1: a bit-width disagreement prints [CLIENT: 4 SERVER: 5] '
    'and drops every player before the map starts.'
)

case(
    'LF line endings on a raw .efx', 'efx-crlf', True,
    {'fx/maps/zombie/fx_a.efx': 'iwfx 2\n\nstuff\n'},
    'ERROR_CATALOGUE 22: loadfx() returns undefined on an LF .efx with no error '
    'and no log line. 36 files sat broken for a year.'
)

# -------------------------------------------------------------------------
# KNOWN-GOOD - must NOT be flagged
# -------------------------------------------------------------------------

case(
    'map ref inside a map subfolder script', 'root-scope', False,
    {'scripts/zm/zm_tomb/zm_tomb.gsc':
     'main()\n{\n    maps\\mp\\zm_tomb_dig::swap_weapon();\n}\n'},
    'A map subfolder script loads only on that map, so the reference is legal. '
    'This is where the project deliberately puts such refs.'
)

case(
    'map ref inside comments only', 'root-scope', False,
    {'scripts/zm/a.gsc':
     '//  replaceFunc(maps\\mp\\zm_tomb_dig::swap_weapon, ::mine);\n'
     '/* also maps\\mp\\zm_transit_classic::main here */\n'
     'main()\n{\n    x = 1;\n}\n'},
    '🛑 THIS IS THE FALSE POSITIVE THE FIRST DRAFT PRODUCED. Measured in the '
    'live repo: a non-comment-stripping grep reported replaced/_zm.gsc and '
    'replaced/_zm_buildables_pooled.gsc as referenced. Neither file exists; '
    'both hits were prose. This project comments heavily with real code '
    'samples, so a checker that cries wolf here gets ignored.'
)

case(
    'CRLF .efx', 'efx-crlf', False,
    {'fx/maps/zombie/fx_a.efx': 'iwfx 2\r\n\r\nstuff\r\n'},
    'Correct line endings; must pass silently.'
)

case(
    'globally-safe external from a root script', 'root-scope', False,
    {'scripts/zm/a.gsc':
     'main()\n{\n    maps\\mp\\zombies\\_zm_perks::give_perk( "x" );\n'
     '    maps\\mp\\gametypes_zm\\_hud_util::createicon();\n}\n'},
    'AI_CONTEXT rule 2 lists maps\\mp\\zombies\\_zm* and '
    'maps\\mp\\gametypes_zm\\_* as safe from a root script.'
)

case(
    'valid font names', 'font-name', False,
    {'scripts/zm/a.gsc':
     'init()\n{\n    a = createfontstring( "small", 1.5 );\n'
     '    b = createfontstring( "default", 1.5 );\n}\n'},
    'The five sites fixed in v2.2.5 now use "small"; must not regress into '
    'flagging the fix.'
)


def run_case(c):
    tmp = tempfile.mkdtemp(prefix='pf_')
    try:
        os.makedirs(os.path.join(tmp, 'scripts'), exist_ok=True)
        for rel, content in c['files'].items():
            path = os.path.join(tmp, rel)
            os.makedirs(os.path.dirname(path), exist_ok=True)
            # newline='' so \r\n in a fixture survives verbatim
            with open(path, 'w', newline='') as fh:
                fh.write(content)
        proc = subprocess.run(
            [sys.executable, PREFLIGHT, '--root', tmp],
            capture_output=True, text=True)
        out = proc.stdout
        # A check "fired" only if its tag appears under the ERROR or WARNING
        # heading. NOTE lines are informational inventory ("2 .efx checked,
        # 0 bad", "1 x small") and must never count as a finding - an earlier
        # version of this test did count them and produced two false FAILs
        # against a linter that was behaving correctly.
        fired = False
        section = None
        for line in out.splitlines():
            if line.startswith('X ERROR'):
                section = 'error'
                continue
            if line.startswith('! WARNING'):
                section = 'warning'
                continue
            if line.startswith('- NOTE'):
                section = 'note'
                continue
            stripped = line.strip()
            if not stripped.startswith('[') or section not in ('error', 'warning'):
                continue
            tag = stripped.split(']')[0].lstrip('[')
            if tag == c['check']:
                fired = True
                break
        return fired == c['flagged'], fired, out
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    if not os.path.isfile(PREFLIGHT):
        print(f'ERROR: preflight.py not found next to this file ({PREFLIGHT})')
        return 1

    print('test_preflight.py - self-test\n')
    passed = failed = 0
    for c in CASES:
        ok, fired, out = run_case(c)
        want = 'FLAG' if c['flagged'] else 'pass'
        got = 'FLAG' if fired else 'pass'
        if ok:
            print(f'  ok    {c["name"]:<42} [{c["check"]}] {got}')
            passed += 1
        else:
            print(f'  FAIL  {c["name"]:<42} [{c["check"]}] want={want} got={got}')
            print(f'        why it matters: {c["why"]}')
            print('        --- output ---')
            for line in out.splitlines():
                print(f'        {line}')
            failed += 1

    print(f'\n{passed} passed, {failed} failed.')
    return 1 if failed else 0


if __name__ == '__main__':
    sys.exit(main())
