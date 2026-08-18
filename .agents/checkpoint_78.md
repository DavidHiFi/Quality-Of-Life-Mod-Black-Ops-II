# Checkpoint 78 — v1.99.60. A long, productive session: seven versions, six confirmed in game.

Written 2026-08-18. **Supersedes 77 for status.**

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. One tiny change is deployed and unbooted; everything else is confirmed.**

| shipped this session | version | state |
|---|---|---|
| Graphics rows → stock **ADVANCED** tab; DOF gains **DISABLED** | v1.99.54 | 🟢 **CONFIRMED** (screenshot) |
| `deathmachine_zm.all.sabl` **merged into `mod.all`** — the mod is now **5 files** | v1.99.55 | 🟢 **CONFIRMED** — *"no longer chopping/cutting out"* |
| **M16** in the mystery box, every map | v1.99.56 | 🟢 **CONFIRMED** — *"i saw it pop up in the box"* |
| `.bloodmoney` / `!bloodmoney` + console twin | v1.99.57 | 🟡 **deployed, not explicitly tested** |
| **Olympia + M1911** in the box; **map-aware CHARACTER picker** in the lobby | v1.99.58 | 🟢 **CONFIRMED** — Olympia from the box; picker tested on *"all maps' crews + survivals"* |
| Picker fix: team maps use `should_use_cia`, not `characterindex` | v1.99.59 | 🟢 **CONFIRMED** |
| Non-default **red cross** on the CHARACTER row | **v1.99.60** | 🟡 **DEPLOYED, NOT BOOTED** — the only outstanding item |

**Next action:** the user's call. The queue is 18 items; nothing is mid-flight.

---

## 1. 🛑 THE ONE THING THE USER BELIEVES THAT IS NOT TRUE

They asked for the **M14** to be crossed off, reasoning *"i got the olympia so there's no reason that
you didn't implement the m14 as well or the m1911"*. **The M1911 is done. The M14 is NOT**, and they
were told so when v1.99.58 shipped. Do not let it quietly disappear from the list.

🌟 **THE DIVIDING LINE FOR EVERY REMAINING WEAPON REQUEST, and it explains all of them:**

> The M16, Olympia and M1911 took minutes **only because their assets were already in `mod.ff`**.
> Treyarch had simply registered them with `include_weapon( name, 0 )` — one flag, copied once onto
> `struct.is_in_box` — so flipping it was the entire job.
>
> The **M14**, **MM1** and **Bouncing Betty** have **no def and no art in this mod at all**. They need
> a real asset port first. Check `grep -E '^weapon,' zone_source\mod_base.zone` BEFORE promising.

The Bouncing Betty is worse still: there is **no `bouncingbetty_zm`** anywhere in the stock dump (only
`bouncingbetty_mp`, all of it shared MP-equipment plumbing), and it is **equipment, not a gun**, so it
occupies the lethal slot and cannot go through `add_zombie_weapon`.

---

## 2. WHAT WAS LEARNED THAT WILL SAVE TIME LATER

**🌟 `include_weapon( name, 0 )` is why stock wall-buys never spin.** `_zm_weapons.gsc` reads the flag
ONCE, when `add_zombie_weapon` builds the struct, and copies it to `struct.is_in_box`. So on a map that
already registered the gun the whole fix is that one field; elsewhere, register it with the map
script's own hint/cost/vox. `zmqol_wallbuy_box_init()` is the worked example.

**🛑 THE OLYMPIA IS `rottweil72_zm`.** Its art is called olympia (`t6_wpn_shotty_olympia_view`,
`viewmodel_olympia_*`) and its wall-buy fx is literally `fx_zmb_wall_buy_olympia` (`_zm.gsc:1221`).
Searching the weapon list for "olympia" finds nothing; searching the art for "rottweil" finds nothing.

**🛑 THE TWO `give_team_characters()` ARE DIFFERENT FUNCTIONS.** This cost a boot.
`zm_buried.gsc` switches on `self.characterindex`. **`zm_transit.gsc:1076` checks
`level.should_use_cia` FIRST**, and if it is defined uses that alone, then overwrites
`characterindex` on the way out — the index switch is only the `else`. TranZit's survival init defines
it randomly every match (`:88-92`), so on Diner/Farm/Town setting the index could never work.
Origins' `survival_init()` does the same (`zm_tomb.gsc:72-75`). **Generalising from one map's copy of
a function is exactly the mistake to stop making.**

**🌟 A STOCK LUI BUG, now fixed in our copy.** `AddGameOptionsButtons` declares `MapIsValid` outside
its loop and only ever sets it true — so once one entry matched the map, every later map-filtered
entry passed too. Invisible with the one shipped map-filtered row; fatal with four.

**🛑 `ui_gameType` CANNOT SEPARATE CLASSIC FROM SURVIVAL.** It is `zclassic` on Origins *and* on a
Green Run survival game. Use **`ui_zm_gamemodegroup`** (`zclassic` / `zsurvival` / `zencounter`), which
`selectmaplistzombie.lua` writes next to `ui_mapname`.

**🌟 The lobby's red cross is `CoD.PrivateGameLobby.DvarDefaults`.** Plutonium's
`DvarSelectorSetDvarFunc` walks that table and calls `showStarIcon( value ~= default )` — but only for
a dvar that has an entry. No entry, no icon. It fires on menu open as well as on change, and it is
lost if you pass a custom `addChoice` callback.

**🛑 `zone_assets\sound` IS NOT REPRODUCIBLE — and `build_ff.bat` tells you to wipe it.** Doing that
destroyed 36 payloads (freezegun, thundergun, Wunderfizz, zombie blood) that existed nowhere else.
They were recovered only because a failed link never overwrites `mod.ff`. They are now in the tracked
`sound\` folder. **Never wipe it without dumping the current `mod.ff` to a scratch folder first.**
📝 The dumper appends one extra extension (`x.snd.wav` → `x.snd.wav.wav`), so a `FileSource` copied
from a dump will not link — take it from `zone_assets\soundbank\mod.all.aliases.csv`, the build INPUT.

---

## 3. STILL OPEN, WITH THE DIAGNOSIS ALREADY DONE

**Death Machine ammo counter on Buried / Mob / Origins (item 14).** Measured: those three are the ONLY
fastfiles shipping `ui_mp\t6\zombie\ammoareazombie.lua`, and that widget has **two** visibility paths —
`UpdateVisibility` honours `BIT_AMMO_COUNTER_HIDE` (what `setclientammocounterhide` drives), but
`ShouldHideAmmoCounter( weapon )` sets the digits' alpha from weapon type and a **`hideAmmo`** weapon
property with no reference to the bit. The second path is the suspect and fits the reported flicker.
🛑 **Unknown: what sets `hideAmmo`.** It is not a weapon-def field and `ammoCounterClip` has no
"none" value, so this is NOT a def edit. Settle that first.

**Animated camos (items 11-13).** The toggle is easy — `anim_pap_camo_buried/_mob/_origins` already
exist and default to 1. "All maps" is NOT understood: stock camo assets carry 4 slots on TranZit and
12 on Buried, so camo index 40 is not a plain index into them. The user's custom camos are ignored
almost certainly because **`mod.ff` owns 154 camo images** against their 1,570 loose `.iwi` files.

**Residual, unchanged:** `EXE_ERR_RELIABLE_CYCLED_OUT` on Origins and Mob (oldest live fault); the LUI
`beingAnimation` crash fix still unconfirmed (the jet gun has never been overheated).

---

## 4. VERSIONS THIS SESSION

`v1.99.54` ADVANCED tab + DOF DISABLED · `v1.99.55` sound-bank merge, mod is now **5 files** ·
`v1.99.56` M16 in the box · `v1.99.57` `.bloodmoney` · `v1.99.58` Olympia + M1911 + character picker ·
`v1.99.59` `should_use_cia` fix · `v1.99.60` the non-default cross.
