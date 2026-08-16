// ============================================================================
//  audit_weapon_assets.js  -  THE "REVISE" TOOL FOR WEAPONS.
//
//  Written 2026-08-16 after the Tac-45 shipped with a broken Pack-a-Punch
//  viewmodel. Five left-hand dual-wield animations were referenced by the
//  weapon def and declared nowhere, so the left gun drew at its bind pose - an
//  enormous misplaced model filling the screen.
//
//  🛑 THE MISTAKE IT EXISTS TO PREVENT: enumerating a weapon's assets by FIELD
//  NAME. The left-hand fields are idleAnimLeft / fireAnimLeft / lastShotAnimLeft
//  / reloadAnimLeft / reloadEmptyAnimLeft / emptyIdleAnimLeft, and melee has
//  meleeAnimEmpty. A "*Anim" suffix pattern silently drops all of them.
//
//  🌟 THE RULE: ENUMERATE BY VALUE. Every value that looks like an xanim IS an
//  xanim, whatever the field is called. Same for models, materials, fx.
//
//  WHAT IT CHECKS
//    For every weapon def this mod ships raw in mod.iwd (weapons\ and
//    weapons\zm\), every asset it names is resolved against:
//      1. everything mod.ff declares  (zone_source\*.zone)   -> available on all maps
//      2. the fastfiles a given zombies map actually loads
//    Anything found in neither is reported per map. That is the exact class of
//    failure that is SILENT in T6 - no log line, no error, just a missing effect
//    or a bind-pose model.
//
//  INPUT it needs (built once per session, a few minutes):
//    an Unlinker --list index of every .ff in zone\all and zone\english,
//    one <basename>.txt per fastfile. See [[t6-fastfile-full-index]].
//
//  USAGE
//    node .agents\audit_weapon_assets.js <ffindex-dir> [--all]
//    (without --all it audits only the weapons this mod adds, which is the
//     normal case; stock zombies guns ship with their own map.)
// ============================================================================
const fs = require('fs');
const path = require('path');

const PROJ = path.resolve(__dirname, '..');
const IDX = process.argv[2];
const AUDIT_ALL = process.argv.includes('--all');
if (!IDX || !fs.existsSync(IDX)) {
  console.error('usage: node audit_weapon_assets.js <ffindex-dir> [--all]');
  process.exit(2);
}

// ---- which fastfiles are live, per map -------------------------------------
// Ground truth: the "Loading fastfile" lines of a real console_zm.log, minus
// the map-specific ones. Not guessed.
const ALWAYS = ['code_post_gfx_zm', 'common_zm', 'patch_zm', 'patch_ui_zm', 'ui_zm',
  'plutonium_zm', 'ffotd_tu17_zm_147', 'seasonpass_load_zm',
  'dlc0_load_zm', 'dlc0dd_load_zm', 'dlc1_load_zm', 'dlc2_load_zm',
  'dlc3_load_zm', 'dlc4_load_zm', 'dlczm0_load_zm'];

const MAPS = {
  zm_transit: ['zm_transit', 'zm_transit_patch', 'zm_transit_gump_diner', 'so_zsurvival_zm_transit', 'so_zclassic_zm_transit'],
  zm_nuked:   ['zm_nuked', 'zm_nuked_patch'],
  zm_highrise:['zm_highrise', 'zm_highrise_patch'],
  zm_prison:  ['zm_prison', 'zm_prison_patch', 'so_zclassic_zm_prison'],
  zm_buried:  ['zm_buried', 'zm_buried_patch', 'so_zclassic_zm_buried'],
  zm_tomb:    ['zm_tomb', 'zm_tomb_patch'],
};

function loadFF(name) {
  const p = path.join(IDX, name + '.txt');
  const s = new Set();
  if (!fs.existsSync(p)) return s;
  for (const ln of fs.readFileSync(p, 'utf8').split(/\r?\n/)) {
    const m = ln.match(/^([a-z]+),\s*(.+?)\s*$/);
    if (m) s.add(m[1] + '|' + m[2]);
  }
  return s;
}

// ---- what mod.ff declares ---------------------------------------------------
const modff = new Set();
for (const f of fs.readdirSync(path.join(PROJ, 'zone_source'))) {
  if (!f.endsWith('.zone')) continue;
  for (const ln of fs.readFileSync(path.join(PROJ, 'zone_source', f), 'utf8').split(/\r?\n/)) {
    const t = ln.trim();
    if (!t || t.startsWith('//') || t.startsWith('>') || t.startsWith('include')) continue;
    const m = t.match(/^([a-z]+),\s*"?(.+?)"?\s*$/);
    if (m) modff.add(m[1] + '|' + m[2]);
  }
}

// Raw .efx shipped inside mod.iwd resolve at runtime without any zone entry -
// proven in this project - so the fx\ tree counts as a source too.
function walk(dir, base, out) {
  if (!fs.existsSync(dir)) return out;
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) walk(p, base, out);
    else if (e.name.endsWith('.efx')) out.add('fx|' + path.relative(base, p).replace(/\\/g, '/').replace(/\.efx$/, ''));
  }
  return out;
}
const rawFx = walk(path.join(PROJ, 'fx'), path.join(PROJ, 'fx'), new Set());

const always = new Set([...modff, ...rawFx]);
for (const ff of ALWAYS) for (const a of loadFF(ff)) always.add(a);

// ---- enumerate a weapon def's assets BY VALUE --------------------------------
const SEP = String.fromCharCode(92);
function assetsOf(file) {
  const parts = fs.readFileSync(file, 'latin1').split(SEP);
  const out = [];
  const seen = new Set();
  const push = (cls, name) => {
    const k = cls + '|' + name;
    if (!seen.has(k)) { seen.add(k); out.push([cls, name, k]); }
  };
  for (let i = 1; i + 1 < parts.length; i += 2) {
    const key = parts[i];
    const v = (parts[i + 1] || '').trim();
    if (!v || v === 'none' || v === 'None') continue;
    // Numeric / ratio / boolean values are never asset names. Sizes, scales and
    // ratios live on fields whose names look asset-ish (reticleCenterSize,
    // hudIconRatio), so filter on the VALUE.
    if (/^-?[\d.]+$/.test(v) || /^\d+:\d+$/.test(v)) continue;

    // xmodel FIRST: viewmodel_hands* are models, not anims, and would otherwise
    // be swallowed by the anim prefix below.
    if (/^(viewmodel_hands|t\d_|p\d_|projectile_|body_)/.test(v) && /model/i.test(key)) { push('xmodel', v); continue; }
    // xanim: any value that names a viewmodel or player anim.
    if (/^(viewmodel_|pt_|player_|ai_)/.test(v)) { push('xanim', v); continue; }
    // fx: values with a path separator under a known fx root.
    if (/^(weapon|maps|explosions|temp_effects|impacts|misc|fire|smoke|env)\//.test(v)) { push('fx', v); continue; }
    // camo
    if (key === 'camo') { push('camo', v); continue; }
    // materials: icon/reticle/overlay fields, real names only.
    if (!/adsOverlayReticle|activeReticleType/i.test(key) && /(Icon|Reticle|Shader|overlayMaterial)/i.test(key) && /^[a-z][a-z0-9_\/]{2,}$/i.test(v)) { push('material', v); continue; }
    // sound aliases: every *Sound / *SoundPlayer field.
    if (/Sound(Player)?$/.test(key)) { push('sound', v); continue; }
  }
  return out;
}

// ---- sound aliases the mod's own bank provides --------------------------------
const bankAliases = new Set();
for (const f of ['soundbank/mod.all.aliases.additions.csv', 'zone_assets/soundbank/mod.all.aliases.csv']) {
  const p = path.join(PROJ, f);
  if (!fs.existsSync(p)) continue;
  for (const ln of fs.readFileSync(p, 'utf8').split(/\r?\n/)) {
    const n = ln.split(',')[0];
    if (n && n !== 'Name') bankAliases.add(n);
  }
}

// ---- which defs to audit ------------------------------------------------------
// The weapons this mod ADDS. Stock zombies guns come with their own map, so
// auditing them produces noise, not findings.
const ADDED = /^(sig556|sa58|mk48|qbb95|mp7|vector|insas|peacekeeper|crossbow|as50|titus6|mk_titus6|fnp45|fnp45lh|gl_sig556|sf_sa58|freezegun|thundergun|tesla_gun)/;

const defFiles = [];
for (const dir of ['weapons', 'weapons/zm']) {
  const d = path.join(PROJ, dir);
  if (!fs.existsSync(d)) continue;
  for (const f of fs.readdirSync(d)) {
    const full = path.join(d, f);
    if (!fs.statSync(full).isFile()) continue;
    if (!AUDIT_ALL && !ADDED.test(f)) continue;
    defFiles.push(full);
  }
}

// ---- run ----------------------------------------------------------------------
const mapSets = {};
for (const [m, ffs] of Object.entries(MAPS)) {
  const s = new Set(always);
  for (const ff of ffs) for (const a of loadFF(ff)) s.add(a);
  mapSets[m] = s;
}

let findings = 0;
console.log('Auditing ' + defFiles.length + ' weapon defs by VALUE.\n');
for (const file of defFiles) {
  const name = path.basename(file);
  const rows = [];
  for (const [cls, asset, k] of assetsOf(file)) {
    if (cls === 'sound') {
      // A sound alias is fine if the mod's own bank has it. Map banks are not
      // in the fastfile index (they are .sabl payloads), so anything else is
      // reported as "check the map bank" rather than as a hard miss.
      if (!bankAliases.has(asset)) rows.push([cls, asset, 'not in mod.all - check map banks']);
      continue;
    }
    const missingOn = [];
    for (const m of Object.keys(MAPS)) if (!mapSets[m].has(k)) missingOn.push(m);
    if (missingOn.length) rows.push([cls, asset, missingOn.length === 6 ? 'MISSING ON ALL MAPS' : 'missing on ' + missingOn.join(', ')]);
  }
  if (rows.length) {
    console.log('### ' + name);
    for (const [cls, asset, why] of rows) console.log('    ' + cls.padEnd(9) + asset.padEnd(46) + why);
    console.log('');
    findings += rows.length;
  }
}
console.log(findings ? findings + ' finding(s).' : 'No missing assets.');
