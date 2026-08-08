# Checkpoint 24 — v1.62.6. The perk row fixed in the LUI itself. Deployed, NOT booted.

Written 2026-08-09. Supersedes checkpoint 23 (v1.62.5), 3 commits ago.
Keep 23 §2 (why GSC ordering could never reach the down) and §3 (one full row,
one safe removal). Keep 22 §4–§5, 21 §2–§3, 20 §1–§2, 19, 18 §5, 15 §2.

**Read §0, §2 and §3.**

---

## 0. THE SINGLE NEXT ACTION

**Boot Diner, get all 12 perks, let a zombie down you. The perk row must NOT
collapse into copies of one icon.**

That is the whole test. v1.62.6 is deployed and verified offline; nothing else
starts until the user confirms it — [[zm-qol-one-at-a-time]].

🔎 **If it still misbehaves, get `zmqol_lui_perkfix` from the console FIRST.**
`1` = the patch installed, so the cause is not this file and the LUI theory is
wrong. Empty/0 = the patch never ran, and the fault is the hook, not the fix.
That one reading splits the next session's search space in half.

⚠️ **Not a bug:** perks retained through a down (Tombstone / Who's Who /
afterlife) never write their clientfield to 0 (`_zm_perks.gsc:2166-2171`), so
those icons legitimately stay on the row.

**Still deployed and NEVER booted, from earlier rounds:**

| version | how to test |
|---|---|
| v1.62.0 | Boot **Mob**, carry two plane parts at once. Log: `[zm_qol] solo status: expected=N connected=N is_forever_solo_game=N` |
| v1.62.3 | Vulture's through-wall icons should have real shapes, not colour blurs |

🛑 v1.62.4 (Vulture perk-machine markers) is **measured broken** — see §4.

---

## 1. WHAT THE USER REPORTED THIS SESSION

Diner survival, solo, one boot, screenshot + `console_zm.log` @ 03:35.

1. **12 perks → killed by a zombie → row collapsed to 12 identical PhD icons.**
   Not the chat commands, not specific to PhD (the friend's run showed Vulture
   Aid). **They are right on both counts**, and this is exactly the case v1.62.2
   and v1.62.5 each recorded in writing as *not covered*.
2. *"the `.giveperks` command doesn't do anything at all"* — **true, and not a
   regression.** See §3.
3. 🆕 **Standing instruction:** every chat command must ALSO be a dvar /console
   command so it can be bound. Saved to memory as
   [[zm-qol-commands-as-dvars]]; queued as QUEUE §0B.

---

## 2. 🌟 WHAT SHIPPED — v1.62.6, and the technique matters more than the fix

Full write-up: `MOD_CATALOGUE.md` §3d and §9d, `STOCK_REFERENCE.md` §4/§4b.

Stock's `CoD.Perks.RemovePerkIcon` shifts every icon down a slot on a removal;
on the last index the `elseif` never reassigns `NextPerkWidget`, so slot 12
copies **itself** and never clears. The fix is the missing
`else NextPerkWidget = nil`, which routes slot 12 down **stock's own**
"no next widget" branch — the branch stock already takes when you remove the
perk sitting *in* slot 12. Nothing is invented.

🌟 **Removal order stops mattering**, which is why this one change covers the
down, `.removeperks`, `.remove<perk>` and the Vulture spam together.

### 2a. 🌟 THE BLOCKER WAS FALSE — you can patch ONE LUI function

Every previous checkpoint said `ui_mp/` overrides are whole-file replacements,
so the fix was blocked on a faithful decompile that no tool can produce. **The
premise is true and the conclusion was wrong.**

LUI globals are plain Lua tables and most functions are looked up **at call
time**. From a file you already override, `CoD.<Thing>.<Func> = <ours>` replaces
that function alone and leaves the rest of the stock file — including branches
no decompiler can read — untouched. Two preconditions, both checkable offline:

1. **The target must not be captured by `registerEventHandler`.** Stock's
   bytecode string table lists what is registered: `Update`, `UpdateVisibility`,
   `IconPulseFinish`, `UpdateVultureDiseaseMeter`. `RemovePerkIcon` is **not**
   among them, and it is its own constant inside `Update` ⇒ runtime lookup.
2. **Your entry point must provably run after the target file loaded.** Stock
   `hud.lua` creates `PerksArea` then `PowerUpsArea` on **adjacent lines**, so
   the top of `LUI.createMenu.PowerUpsArea` always sees a complete `CoD.Perks`.

### 2b. 🛑 WHY NOT REPLACE `hudperkszombie.lua` — this is the part to remember

Stock's `Update` has `STATE_PAUSED` and `STATE_TBD` branches (proved by its own
constants). **No readable source carries them** — Reimagined deleted them and
drives pausing from its own `perks_paused` event. Confirmed Reimagined-only,
0 hits each in stock's bytecode: `UpdatePerksPaused`, `UpdatePerkOrder`,
`SpecialtyToClientFieldNames`, `perks_paused`, `hud_update_perk_order`,
`perk_order`, `DvarString`.

`STATE_PAUSED` is **reachable in this mod** — perk fields are 2 bits wide
wherever `emp_grenade_zm` is included (stock `zm_transit.gsc:1926`). Shipping
Reimagined's file would silently stop EMP-paused perks dimming: a regression,
and reconstructing the branches would be a guess. Both are disqualifying.

### 2c. 🔧 TWO NEW CAPABILITIES, both reusable

- **Lua syntax CAN be validated offline.** `npm install luaparse` (node is
  installed, there is no Lua interpreter), then
  `luaparse.parse(src, { luaVersion: '5.1' })`. It parses all four of this
  project's LUI files. This removes most of the "a bad LUI file hard-crashes
  the game" risk that has blocked LUI work for several sessions.
- **LUI inside `mod.iwd` provably loads.** `Loaded menu file:
  ui_mp/t6/zombie/hudpowerupszombie.lua` appears in the boot log while that file
  exists in **no other search path**; independently, Reimagined's `build.bat`
  ships `ui`/`ui_mp` by `Compress-Archive` into `mod.iwd` with no `raw\` at all.
  🛑 Plutonium still searches `storage\t6\raw\` first — `build.bat` step 6
  re-syncs any `.lua` present in both.

### 2d. What was verified before hand-off

parses as Lua 5.1 · diffed against Reimagined's readable copy with **exactly two
lines differing** · target not captured by `registerEventHandler` · hook ordering
proven from stock `hud.lua` · file proven to load from `mod.iwd` · deployed
`mod.iwd` entry **byte-identical** to source · only `mod.json` + one `.lua`
changed, `mod.ff` untouched (no `build_ff.bat`) · with any free slot the loop
breaks before index 12, so **ordinary ≤11-perk play cannot reach the new branch**.

---

## 3. 🌟 `.giveperks` WAS NEVER BROKEN — it received a stray `"`

Every chat line in the log is clean except two, and they are the only ones with
a trailing quote:

```
DavidHiFi^7: .giveperks"      <- typed twice, did nothing either time
DavidHiFi^7: .removeperks     <- clean, worked: "cleared 12 perk icon(s)"
```

`quality_of_life.gsc:2585` does `cmd = getsubstr( tokens[0], 1 )` and every
handler is an **exact** `cmd == "..."` compare, so `giveperks"` matches nothing
and falls silently through the whole else-if chain. The `give<perk>` prefix
branch below it also misses (`zmqol_perk_from_alias( "perks\"" )` is undefined).

**Fix: strip quotes before tokenising.** Almost certainly a keybind — a bound
`say` is where stray quotes come from — which is the same root as the
commands-as-dvars request. Ship the two together (QUEUE §0B).

📝 **The general lesson:** an exact-match command dispatcher fails *silently* on
any input noise. The log is the only place that shows what actually arrived —
read the raw chat lines before believing a command is broken.

---

## 4. 🔴 NEW DEFECT FOUND IN THE LOG, not reported by the user

```
[zm_qol] CLIENT vulture machines: 0 of 43 structs match 'zstandard_perks_diner'
```

**Zero of 43.** v1.62.4 has been shipping and doing nothing. The sibling wallbuy
filter succeeded on the *same boot* (`enable_wallbuys - zstandard_diner: tagged
2 of 2`), so the dvars are right and the **`_perks_` infix is wrong**. 🛑 Dump
the real `script_string` values with `Unlinker --include-assets mapents` on
`zm_transit` before changing a single character.

---

## 5. STILL OPEN, in the order the user raised them

- **QUEUE §0B** — every chat command as a dvar/console command, plus the quote
  strip. New standing instruction; ships next unless the user redirects.
- **QUEUE §0A-C** — the Vulture 0-of-43 filter (§4 above).
- **QUEUE §0ab** — `.remove<perk>` on a full row. **v1.62.6 should make this
  moot**; re-test before writing the designed GSC fix, which may now be
  unnecessary.
- **QUEUE §A2** — Who's Who visuals. 🛑 Still blocked on the user's decision:
  Buried's `actor` clientfield set is 32/32, so the downed-body glow cannot
  exist there. Per-map compromise, needs explicit sign-off.
- **QUEUE §0 / §0f** — solo intro cutscene + "CUSTOM GAMES" header (not GSC);
  god mode after Mob's afterlife; Mob Wunderfizz overlapping the shield part;
  custom texture packs; the stray 254 MB `cmn_root.all.sabl` in `build\zm_qol\`.

📝 §2a means the **pause-menu options UI** (QUEUE §2.1) and the CUSTOM-GAMES
title are both cheaper than previously recorded — a single-function patch plus
offline syntax validation, instead of a whole-file reproduction.
