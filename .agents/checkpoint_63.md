# Checkpoint 63 — v1.99.17. Tac-45 and Winter's Howl CLOSED. Who's Who down to one item, root-caused to the clone's materials.

Written 2026-08-16. **Supersedes 62 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.17 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | ~~Tac-45, incl. dual-wield Pack-a-Punch~~ | ✅ **CONFIRMED IN GAME AND CLOSED.** *"tac 45 is fixed and working, its done"* 🛑 Do not re-open. |
| 2 | ~~Winter's Howl firing fx~~ | ✅ **CONFIRMED IN GAME AND CLOSED.** *"the fx are correct"* 🛑 Do not re-open. |
| 3 | ~~Riser sound~~ | ✅ confirmed (checkpoint 60). 🛑 Do not re-open. |
| 4 | **Who's Who — clone glow** | 🟡 root-caused to the `_g` materials, fixed, **unbooted**. §1 |
| 5 | **Who's Who — red downed screen** | 🟡 night mode suppresses it on *every* down; now driven directly, **unbooted**. §2 |
| 6 | **Who's Who — ghost colour grade** | ✅ landing on screen since v1.99.15 (23 `vc_*`). 🛑 Do not disturb. |
| 7 | **`mod.ff` stale server scripts** | 🔴 **now has hard evidence — the next thing to fix.** §3 |
| 8 | Who's Who description | 🟡 built v1.98.0, never booted |
| 9 | Wunderfizz random first location | 🟡 built v1.97.0, never booted — needs a multi-machine map |
| 10 | Kill-feed icons | 🟡 cause found and fixed v1.99.14, **unbooted** |
| 11 | Titus-6 reload | 🔴 a bank job — checkpoint 58 §3 has the spec |
| 12–18 | `.character` · Galvaknuckles · two GAME toggles · Mob Cherry prone · DM voice line · drop the DM bank | 🔴 unchanged |

### 🌟 THE THREE THINGS TO DO ON THE NEXT BOOT
Go down with Who's Who **on TranZit / Diner** and check, in order:
1. **red screen** while on the floor
2. **washed-out screen** once up as the ghost
3. **the body glowing orange** on the ground

---

## 1. 🌟 THE CLONE GLOW — IT WAS THE MATERIALS, AND I DISMISSED THE ANSWER A ROUND EARLIER

v1.99.16 delivered the clientfield to the corpse — the log proves it
(`[zm_qol] whoswho: clone glow set on a script_model corpse`) — and nothing glowed. **That cleared
the delivery path and pointed at what receives it.**

Stock's glow is a shader constant (`scriptVector3`) written to the corpse. **A shader constant does
nothing unless the model's MATERIAL is authored to read it.** Dumped both clone models and read the
material names out of the GLB:

| model | materials |
|---|---|
| `c_zom_player_reporter_dlc1_fb` (Die Rise) | `..._arm_g`, `..._body_g`, `..._gear_g`, `..._head_g` |
| `c_zom_player_reporter_fb` (TranZit) | `..._arm`, `..._body`, `..._gear`, `..._head` |

🛑 A sweep of all 191 fastfiles finds **every** `mc/mtl_c_zom_player_*_g` material in
`zm_highrise.ff` and nowhere else.

**The fix is stock's own:** Die Rise sets `self.whos_who_shader`, which
`chugabud_spawn_corpse()` passes to `spawn_player_clone()` as `forcemodel`. Nothing outside Die Rise
ever sets it. Set it per `characterindex` (mapping read from **TranZit's own** switch, not Die
Rise's assumed to carry over) and declare the four models; their `_g` materials come along
transitively.

### 🛑 THE LESSON, AND IT IS THE SAME SHAPE AS THE WINTER'S HOWL ONE
**I examined `whos_who_shader` in v1.99.16 and dismissed it** on the grounds that `_fb` is the normal
player model on both maps, so forcing it "changes nothing". True of the model **name**, false of the
**materials**. 🌟 **Comparing asset NAMES is not comparing asset CONTENTS.** Dump the thing and read
what is inside it.

🟡 **Two honest limits, reported not bodged:**
- On TranZit the clone now wears the **Die Rise outfit** — the only glow-capable version of these
  characters that exists.
- `zm_transit` only. Nuketown uses the CIA/CDC agents, Origins the Richtofen crew, and neither has
  `_g` materials anywhere in the game. Those two keep a plain clone rather than a Victis body.

## 2. 🌟 THE RED DOWNED SCREEN WAS NEVER A WHO'S WHO BUG

The session dvar dump records **`night_mode "1"`**. Night mode sets `r_filmUseTweaks 1`, which makes
the renderer use the `vc_*` dvars **instead of** any visionset — including the engine's own
`visionsetlaststand( "zombie_last_stand", 1 )` (`_zm.gsc:2022`). **So the red has been suppressed on
every down, with or without Who's Who, for as long as night mode has existed in this mod.**

The watcher is now three-state: on the floor → `zombie_last_stand`'s 23 `vc_*`; up as the ghost →
`zm_whos_who`'s 23; neither → restore the values captured at map load.

🟡 **Not faked:** that vision file also lists `r_reviveFX_*` entries for the blurred edge vignette,
and **those names do not exist in the shipped engine** — `t6zm.exe`'s string table carries a
different, later set (`edgeAmount`, `edgeContrast`, `edgeSaturation`, `edgeScale`, `edgeOffset`,
`edgeMaskAdjust`, `edgeColorTemp`) with no Treyarch values anywhere to copy onto them, and
`r_reviveFX_edgeAmount` defaults to 0. The colour is exact; the blur is left alone.

## 3. 🔴 `mod.ff` IS RUNNING STALE DAY-ONE SERVER SCRIPTS — EVIDENCE AT LAST

`console_zm.log:4447-4450` — **four** `replaceFunc` collisions, all on the perk path:

```
perks_register_clientfield · init_client_flags · give_perk · default_vending_precaching
   scripts/zm/zm_expanded  (baked into mod.ff)   vs   scripts/zm/quality_of_life
```

`quality_of_life` wins all four, so this is **not** the cause of the Who's Who effects — but the
stale script's `main()` and `init()` still run, doing duplicate work, and `mod.ff` also carries
day-one copies of every per-map `.gsc`. Full list from `Unlinker --include-assets script`:
`zm_expanded.gsc`, the six `zm_<map>/zm_<map>.gsc`, `freeze/teslagun/thundergun.gsc`, and the three
`maps/mp/zombies/_zm_weap_*.gsc`.

▶️ **NEXT: strip the stale `.gsc` declarations from `mod_base.zone`** — keep every `.csc` (client
scripts only load from a fastfile). [[t6-modff-runs-stale-gsc]]

## 4. METHOD NOTES WORTH KEEPING

- 🌟 **Pull the log first.** Two greps this session settled what a previous round spent an hour
  theorising about, and the `[zm_qol] ... : ON` prints are what proved the delivery path was fine and
  moved the search to the materials.
- 🌟 **The executable's string table is the authority on whether a dvar exists** —
  [[t6-dvar-names-from-exe]]. It produced the full `vc_*` set and it is what disproved the
  `r_reviveFX_*` names in the vision file.
- 🌟 **Enumerate by VALUE, never by field name** — [[t6-weapon-asset-enumeration]]. The Tac-45
  regression came from a field-name pattern that silently dropped `*Left` and `*Empty` fields.
  `.agents\audit_weapon_assets.js` encodes the fix; run it whenever a weapon changes.
