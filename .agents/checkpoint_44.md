# Checkpoint 44 — v1.90.5 shipped (weapon foley); the XPR-50 asset closure fully measured, NOT built.

Written 2026-08-14. **Supersedes 43 for status.** Keep 43 §1 (capture-ring fix), §3 (the foley
research), §4 (black loading screens), §5 (Brutus); and everything 43 itself carries forward.

---

## 0. STATE

🛑 **EIGHT VERSIONS ARE DEPLOYED AND NOT ONE HAS BEEN BOOTED.**

| version | what | state |
|---|---|---|
| v1.89.8 | Electric Cherry fx — Wunderwaffe port was writing stock globals | 🟡 never booted |
| v1.89.9 | Vulture stink overlay yields to Zombie Blood | 🟡 never booted |
| v1.90.0 | Velocity meter — `.velocity on/off` + `velocity` dvar | 🟡 never booted |
| v1.90.1 | `.brutus` / `.panzer` / `.jumpingjacks` + `spawn_*` dvars | 🟡 never booted |
| v1.90.2 | Origins generator capture ring — connect race fixed | 🟡 never booted |
| v1.90.3 | Night-mode clamp was flooding the reliable channel | 🟡 never booted |
| v1.90.4 | `.jumpingjacks` was gated on a zstandard-only array (Die Rise) | 🟡 never booted |
| **v1.90.5** | **Weapon foley — 162 aliases, 258 rows** | 🟡 **never booted** |

Working tree **clean** at `63783bd`. Nothing is half-written.

### v1.90.5 passed its own gate (checkpoint 43 §3 required this)

- Link: **34 warnings, 0 errors — byte-identical warning count to before.** Zero new
  missing-payload warnings.
- Round-trip dump of the **rebuilt** bank: `Finished with 0 warnings, 0 errors`;
  **162 of 162** new alias names present; spot-checked payloads all `extracted=True` with real
  audio (`wpn_as50_fire_plr`, `fly_insas_mag_out`, `fly_mp7_charge`, `fly_crossbow_draw`,
  `fly_sa58_button`, `fly_mk48_mag_in`).
- Bank grew 1.37 MB. Deployed `mod.all.sabl` byte-matches source (58,144,672).

**This is verified-as-built, NOT verified-in-game.** Reload/raise/pickup/dryfire foley on the
ported guns is the thing to listen for.

---

## 1. 🛑 THE SESSION CRASH — a runaway `join` froze the user's PC

Not a game bug; a tooling failure of mine. Recorded so it cannot repeat.

A `kv()` parser with the **key/value phase inverted** produced files whose first column was
weapon *values* (thousands of duplicates/blanks). `join -j1` on that emits the **cartesian
product** of every equal-key run → 267,353 x 269,989. Then `grep -Ff` was pointed at the
51-million-line result **as a pattern file**.

🌟 **The Bash tool reported `Exit code 143 / Command timed out after 2m 0s` and the processes did
NOT die.** The last command ran 18:07:41 UTC; the output file was still growing at 18:11:29 UTC —
**~6 minutes later**, reaching **14.5 GB on C:**. The machine became unusable and the user killed
`grep.exe` / `join.exe` by hand in System Informer.

**The warning that was ignored:** the very next command returned
`Mingw-w64 runtime failure: VirtualProtect failed with code 0x5af` — that is Git Bash failing to
allocate memory. It was read as a fluke and worked around by switching to PowerShell.

**Rules now in effect** (also saved to agent memory as `bash-timeout-does-not-kill`):
- A timeout/exit 143 is **not** a kill. Check for surviving processes before doing anything else.
- `VirtualProtect failed` / `cannot allocate` / `fork: retry` = out of memory. Stop, investigate.
- Before `join`/`comm`: both inputs sorted on the field **and** the field near-unique.
  `cut -f1 F | sort | uniq -d | wc -l` first — a duplicate run of N and M is N*M rows.
- Never hand a machine-generated file to `grep -f` without `wc -l` first.
- Prefer the streaming form: `awk 'NR==FNR{a[$1]=$2;next} $1 in a'`. No blowup possible.

The 14.5 GB file has been deleted; C: is back to 470.8 GB free.

---

## 2. 🌟 THE XPR-50 — the audio is in, the ART IS NOT, and this is the mod.ff ownership trap

The v1.90.5 sound pass already landed the AS50 audio (`wpn_as50_fire_plr` verified in the rebuilt
bank), which was the blocker named in checkpoint 43. **The remaining blocker is art, and it is
bigger than expected.**

Measured with `Unlinker --list` this session:

| asset | owned by | loaded in Zombies? |
|---|---|---|
| `t6_wpn_sniper_xpr50_view` / `_world` / `_scope_view` / `_scope_world` (4 xmodels) | `common_mp.ff` | ❌ |
| `viewmodel_xpr50_*` (**23 xanims**) | `common_mp.ff` | ❌ |
| `menu_mp_weapons_as50` (hudIcon, ammoCounterIcon, killIcon) | **`code_post_gfx_mp.ff`** | ❌ |
| `scope_overlay_xpr50` | `common_mp.ff`, `patch_mp.ff`, **`patch_zm.ff`** | ✅ |
| `hud_mp_firerate_single` | **already in `mod.ff`** | ✅ |
| audio (`wpn_as50_*`, 7x `fly_as50_*`) | **`mod.all.sabl`, v1.90.5** | ✅ |

🛑 **A false negative worth remembering.** The first sweep reported `menu_mp_weapons_as50` as
present in **no** fastfile. Wrong: the Unlinker lists it as `material, ,menu_mp_weapons_as50` —
**a leading comma marks a reference rather than an owned asset** — so an exact-string match on
`material, menu_mp_weapons_as50` missed every occurrence. This is CLAUDE.md §2 corollary 3
("not found is a lead, never a verdict") landing again. **Match on the name, not on the
`class, name` form.**

**What shipping it would cost:** `mod.ff` must take ownership of **4 xmodels + 23 xanims + 1
material**, all sourced from MP fastfiles. That is squarely the
`t6_modff_asset_ownership_trap` / `oat_load_order_decides_asset_copy` class — `mod.ff` loads ahead
of every map, so whatever it owns it ships to **every** map, and a same-named stock asset differs
between fastfiles. This has broken a map before.

📝 Reimagined ships `as50_zm` + `as50_upgraded_zm` and the project's six existing ported guns are
**byte-identical** to Reimagined's (verified with `cmp`), so the def half is settled precedent.
Its `as50_zm` has `altWeapon` empty (no `_mp` alt trap), `attachmentUniques` absent, and
`fireSoundPlayer wpn_as50_fire_plr` — the alias v1.90.5 just shipped. **The def is the easy half.**

📝 The MP→ZM conversion delta was successfully derived from two independent stock sniper pairs
(ballista, svu) before the crash — damage/minDamage to 150 & 550, startAmmo 4→8, locational
multipliers up, aim-assist ranges to 3200, ADS fov 15→50, hudIcon `menu_mp_` → `menu_zm_`.
🛑 Note that last one: **stock's own ZM conversion repoints the hudIcon to a `menu_zm_` material**,
which does not exist for the AS50 — reinforcing that the icon must be authored or imported.

---

## 3. NEXT

1. 🛑 **BOOT.** Eight versions, zero verification. Nothing new should ship first. Listen for the
   v1.90.5 foley (reload/raise/pickup on insas, sa58, mk48, qbb95, mp7, vector, crossbow) and
   check Origins' generator capture ring for v1.90.2.
2. **Decide the XPR-50 on the evidence in §2** — it is a `mod.ff` asset-ownership job, not a
   script job. Per "perfectly, or not at all", the HUD icon has no ZM material and must be
   resolved before the feature can be complete.
3. Then: #3 Brutus probe · #4 Titus-6 · #1 perk-icon streaming · #7 black loading screens.
