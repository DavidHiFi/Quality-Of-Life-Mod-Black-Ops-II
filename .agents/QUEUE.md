# QUEUE.md — one change at a time

**Rule (user, 2026-08-06):** nothing new starts until the item in flight is **confirmed working
in-game by the user**, with no bugs and no compromises. New requests get appended here and
acknowledged, not begun.

**"Deployed" is not "done".** Only a boot moves an item out of §1.

---

## 0. IN FLIGHT — v1.61.3, Tombstone icon (deployed, not booted)

**User, 2026-08-08, with a screenshot:** stock draws the Tombstone perk icon
with its badge frame **upside down relative to every other perk**. Reimagined
fixes it; import that.

🛑 **The literal request would have looked worse than stock.** The ask was
"flip it 180 degrees". Rotated and rendered out to check: the frame does line
up, but **"RIP" ends up upside down and the skull ends up at the bottom**.
Reimagined did not rotate the art — they re-composited it, frame down, text and
skull upright. **Their asset is what shipped.** Rendering the intermediate
before shipping is what caught this.

`zone_assets\images\specialty_tombstone_zombies.iwi` (64x64 DXT5, Reimagined's,
byte-identical). Same pipeline as the 62 `.iwi` already shipping — including
`specialty_vulture_zombies`, another perk HUD icon that works in game. No zone
edit needed: the material already pulled the image, and a raw file on the
search path makes the Linker compile from disk (`src: disk` in the link log).

🛑 It could **not** just be dropped in `images\` — `mod.ff` owned a **32x32**
header for it, and a loose `.iwi` read through a mismatched header renders
garbage (the measured purple/green m1911). The relink makes header and pixels
come from the same file.

Verified: asset list identical before/after (3813 lines, nothing re-owned);
`mod.ff` hash changed `dd18acf3` → `986a498b`; deployed `mod.iwd` carries the
file at 64x64 DXT5, SHA256-identical to Reimagined's.

📝 64x64 where its 11 neighbours are 32x32 — Reimagined's choice. Slightly
crisper. Downscale on request.

**Boot and look at the Tombstone icon.** Frame should point down like the
others, "RIP" upright, skull on top.

---

## 0a. ALSO DEPLOYED, NOT BOOTED — v1.61.2, the stock perk row is back

**User, 2026-08-08:** *"you fucked up the icon size… made them too big, then
too small… the animation is still broken or slow. Revert it but just fix the
PHD being spammed on all the perk slots, that's all I wanted you to fix
originally but you went and changed a bunch of other stuff."*

Fair. v1.61.0 replaced the game's own perk row with a GSC-drawn one — that was
scope the user never asked for, and it cost the icon size and the pulse
animation. **v1.61.2 reverts both perk-HUD commits in full.** `mod.ff` rebuilt
SHA256-identical to `4854411:mod.ff`; 0 `zmqol_perk_hud` in the deployed
`mod.iwd`.

### 🌟 THE PhD ROOT CAUSE — FOUND, and checkpoint 21 §5 was WRONG

Checkpoint 21 concluded the row was drawn by "engine code bound by
`setupclientfieldcodecallbacks`" that "no GSC change can inspect or correct".
**That is false. The row is LUI**, and the file is readable:

| | |
|---|---|
| stock, compiled | `BO2-Raw-files\ui_mp\t6\zombie\hudperkszombie.lua` (Lua 5.1 bytecode) |
| readable source | `BO2-Reimagined\ui_mp\t6\zombie\hudperkszombie.lua` (405 lines, plain text) |

`setupclientfieldcodecallbacks` only makes the engine **dispatch a LUI event**
named after the clientfield. `CoD.Perks.Update` handles it.

**The bug is an off-by-one in `CoD.Perks.RemovePerkIcon`:**

```lua
for PerkIndex = OwnedPerkIndex, #CoD.Perks.ClientFieldNames, 1 do
    PerkWidget = Menu.perks[PerkIndex]
    if not PerkWidget.perkId then break
    elseif PerkIndex ~= #CoD.Perks.ClientFieldNames then
        NextPerkWidget = Menu.perks[PerkIndex + 1]
    end                       -- 🛑 no else - NextPerkWidget keeps slot 12
```

Removing a perk **shifts every icon down one slot**. On the last index there is
no next slot, so `NextPerkWidget` still points at slot 12 from the previous
iteration. Slot 12 then copies **itself** and `break`s without ever clearing.

- **Own ≤11 perks** (every stock map): slot 12 is empty, the loop hits
  `elseif not NextPerkWidget.perkId`, clears correctly. **Stock never sees this.**
- **Own all 12** (only this mod): slot 12 never clears. Each removal duplicates
  the tail, so removing all 12 collapses the row to twelve copies of one icon —
  and it is permanent, because with every `perkId` non-nil `Update` can never
  fill a slot again and `RemovePerkIcon` can never empty one.

Which icon? Whatever landed in slot 12 — the **last** perk acquired. The
v1.60 probe recorded `perk_dive_to_nuke registered exactly ONCE and LAST`
and filed it as an exoneration. It was the answer.

Matches the report exactly: `.giveperks` (fills all 12) → down (removes all 12)
→ every icon PhD, permanently.

### THE FIX — one `else` branch, in one LUI file

```lua
elseif PerkIndex ~= #CoD.Perks.ClientFieldNames then
    NextPerkWidget = Menu.perks[PerkIndex + 1]
else
    NextPerkWidget = nil          -- <- the whole fix
end
```

🛑 **BLOCKED ON ONE THING: there is no stock-faithful source for this file.**
LUI overrides in `ui_mp\` are **whole-file replacements** — the mod's three
existing ones are full stock copies (873 / 591 / 362 lines). Reimagined's copy
is stock **plus its own changes** (`SpecialtyToClientFieldNames`,
`UpdatePerksPaused`, `UpdatePerkOrder`, a hardcoded `TopStart`, and stock's
`STATE_PAUSED`/`STATE_TBD` handling removed from `Update`). Shipping it as-is
would silently import Reimagined's perk-pause behaviour.

**Decoded from the stock bytecode so far** (4-byte floats, offsets 1585-1650):

| constant | stock value | Reimagined |
|---|---|---|
| `TopStart` | **-180 on DLC3 maps, -140 otherwise** (two constants + an `IsDLCMap(CoD.DLC3Maps)` test) | -140, hardcoded |
| `IconSize` | 36 | 36 ✅ |
| `Spacing` | 8 | 8 ✅ |
| `STATE_NOTOWNED/OWNED/PAUSED/TBD` | 0 / 1 / 2 / 3 | same ✅ |

🛑 `STATE_PAUSED` **is reachable here** — the mod registers perk fields 2 bits
wide when `emp_grenade_zm` is included, and stock `zm_transit.gsc:1926` includes
it. So the pause path cannot just be dropped.

**Next step, before writing any Lua:** get a faithful stock decompile of
`hudperkszombie.lua` (a Lua 5.1 decompiler — unluac/luadec — on
`BO2-Raw-files\ui_mp\t6\zombie\hudperkszombie.lua`), or find whatever stock LUI
source produced this mod's existing `hudpowerupszombie.lua`. **Do not
hand-reconstruct `Update`'s paused branches from constant order — that is a
guess, and a bad LUI file hard-crashes the game.**

## 0b. NEXT UP, in the order the user raised them

1. **Solo behaves like a custom game** — no intro cutscene on classic maps,
   and the menu header reads "CUSTOM GAMES". Asked for twice. Only the map
   list (Diner survival) and instant-start should differ from stock solo.
2. **God mode drops after Mob's afterlife** — `.god` still reads ON but the
   player can die. Must survive afterlife in/out. Also confirm death barriers
   behave normally when god is OFF and the player is not flying.
3. **Mob Wunderfizz overlaps the shield part spawn** — move that machine.
4. **Custom texture packs conflict** — `mod.ff` declares 776 header-only
   images and loads before the map, so a player's own `.iwi` is read through
   our header (a tester's m1911 rendered purple/green). 🛑 The v1.59.7
   attempt - rewriting `image,<name>` to `image,,<name>` - FAILED and broke
   textures on two maps; OAT produced an asset literally named `,<name>`.
   Needs a different approach entirely.
5. **Stray 254 MB `cmn_root.all.sabl`** in `build\zm_qol\` — not one of the 6
   mod files. Do not zip it to anyone.

---

## 1. DONE — Origins Wunderfizz replacement (shipped v1.58.x, confirmed)

**User, 2026-08-07:** replace Origins' native Wunderfizz machines with the mod's, keeping the
generator-power gating per location and the moving-location behaviour. "Make it seamlessly
replace the origins ones."

🛑 **This reverses an earlier instruction** recorded in `wunderfizz.gsc` ("NO ADDED MACHINE ON
ORIGINS. User, twice: get rid of them, keep the vanilla ones"). The user has been told; proceed.

### 🌟 THE BLOCKER IS DEAD — measured 2026-08-07

The queue said Origins' `scriptmover` set is 32/32 full, and it is (22 fields, 32 bits, from
`clientfields_zm_tomb_zclassic_tomb.txt`). **That only blocks REGISTERING a new field.** Origins
already registers the six the Wunderfizz needs, in `_zm_perk_random.gsc::init()`:

| field | bits |
|---|---|
| `perk_bottle_cycle_state` | 2 |
| `turn_active_perk_light_red` / `_green` | 1 + 1 |
| `turn_on_location_indicator` | 1 |
| `turn_active_perk_ball_light` | 1 |
| `zone_captured` | 1 |

**Drive those instead of registering `clientfield_perk_intro_fx`, and the wall is gone.**

### 🛑 CORRECTION — the above worried about the wrong thing entirely

**`wunderfizz.gsc` makes ZERO `setclientfield` calls** (`grep -c` → 0). It avoids clientfields on
purpose — see its BALL SPIN + EFFECTS note: five registrations from a root script on six maps is
the fastest route to `EXE_CLIENT_FIELD_MISMATCH`, so the fx are spawned server-side with
`playfx`/`playfxontag` instead.

**So the mod's machine needs no registration at all, and Origins' 32/32 wall does not apply to
it.** The wall only ever blocked driving the *native* machine. Strip-and-replace is the cheap path,
not the expensive one.

### THE PLAN — user's design, 2026-08-07

User: *"whenever you tried to modify the vanilla origins wunderfizz machines you just made them
super buggy — duplicate perk bottles for ones i already owned, perk bottles jumping off to the
left. Why not just strip them from origins entirely, then add the wunderfizz machines that you've
added to other maps… so all wunderfizz machines on any map look the same and give all 12 perks."*

Correct call. The mod's machine already carries relocation (`chooseLocation` /
`currentWunderfizzLocation`), ball behaviour and all 12 perks. Only generator gating is
Origins-specific.

1. **Suppress the native machines** — but 🛑 **DO NOT touch `_zm_perk_random::init()`**. Its six
   `registerclientfield` calls must keep running or the server/client register lists diverge and
   every player eats `EXE_CLIENT_FIELD_MISMATCH`. Suppress `init_machines()` / `machines_setup()`
   and hide the entities instead; leave registration alone.
2. **Place the mod's machines at the native locations** — read them at runtime from
   `getentarray( "random_perk_machine", "targetname" )` (origin + angles) and feed `zmqol_wf_add`.
   Exact, and nothing is guessed or hardcoded.
3. **Generator gating** — the native entities stay alive (hidden, no unitrigger), so
   `zm_tomb_capture_zones.gsc::enable_random_perk_machines_in_zone()` /
   `disable_…()` keep setting `.is_locked` on them exactly as stock does. The mod's machine at each
   location reads its paired native entity's `.is_locked`. **Stock's own capture logic drives the
   gating with no reimplementation.**
4. **Ball / relocation** — already the mod's own; verify the two relocation systems do not both run.

📝 Stock `get_perk_weapon_model()` falls back to `level._custom_perks[perk].perk_bottle`, so custom
bottles were supported natively — that was never the bug the user hit.

---

## 1b. PREVIOUS IN FLIGHT — REVERTED, closed

### Diner fog — **REVERTED at v1.57.7**
User: *"still didn't move... forget it for now, just turn the fog back off entirely."* Both files
restored byte-identical to `d7cb7db` (pre-fog). `r_fog 0` is forced again and `.fog` is gone.
What was learned stands: fog **distance** cannot be changed on this build, and the ring did spawn
correctly (12/12) — it just never looked right. **Do not re-open.**

### Texture pack — **REMOVED at v1.57.7**
2,788 `.iwi` deleted, `mod.iwd` 2,210 MB → 53.9 MB. The mod's own 64 images kept (git-tracked was
the keep-list). Pack still at `H:\Claude\Projects Sources\add textures to mod`. The user loads
textures from `%LOCALAPPDATA%\Plutonium\storage\t6\images\` instead. README corrected.

<details><summary>old entry, superseded</summary>

### Diner fog: default OFF + ring stacked two rows high — **v1.57.6**

**Confirmed working already (2026-08-07 boot):** the ring spawns —
`[zm_qol] fog ring: 12 of 12 fog walls spawned around diner`.

Two defects the user's screenshot exposed, both fixed here:

1. **Default was fog ON.** Mode 1 ("pushed back") was the default and is a proven no-op —
   checkpoint 20 §2: fog *distance* cannot be changed on this build, only `r_fog` on/off. So every
   game started on stock fog and the user typed `.fog off` by hand. **Default is now 0 = off.**
   `.fog <number>` no longer claims to have moved anything.
2. **The ring was too short.** 600-tall walls at the boundary hid what sat just past the edge, but
   the distant hillside rose over the top. **Second row stacked at +500 → 24 walls, ~1100 tall.**
   Ring distance deliberately unchanged (user's choice: "raise them where they are").

**What to check:** boot Diner. Fog should be **off from the start with no command typed**, and the
cloud bank should now be tall enough to cover the hillside rather than sitting under it.

**The new log line reports both rows:** `fog ring: 24 of 24 ... (12 per row, 2 rows)`.

Verified offline: both files parse; deployed `mod.iwd` byte-identical to source; vector add and
vector indexing confirmed as stock GSC idioms; stock TranZit already places 587 createfx effects.

Never verified: whether `spawnfx` anchors the effect at its centre or its base.

</details>

---

## 2. QUEUED — in order, not started

1. **Pause-menu UI** — port the Strat Tester options menu (`H:\Claude\Strat-Tester-BO2`), header
   renamed **"Quality Of Life"**, exposing every existing chat command **plus** ones missing from
   the menu (infinite sprint, etc). Chat commands stay. Scoped already: `optionsstrattester.lua`
   881 lines, `options.lua` 560, `menu.gsc` 73; no LUI conflict with this mod's `ui_mp\`.
   🛑 A bad LUI file hard-crashes the game — this one ships alone.
2. **`night_mode 1` is broken** — the screen goes fully black (screenshot 2026-08-06). Came in from
   another script. Either fix it properly or remove it.
3. **`character` command does nothing** — no visible effect at all.
4. ~~Origins Wunderfizz replacement~~ — **moved to §1, in flight.**
5. **Galvaknuckles wallbuy on Bus Depot** — in the Tombstone room. Town, Farm and Diner already
   have one; Bus Depot does not. 🛑 Survival **only** — must NOT appear on TranZit proper, where
   the Diner wallbuy already covers it. Same `!is_classic()` gating as the other survival edits.
6. **Vulture Aid icon on the Wunderfizz** — the machine's perk icon set is missing Vulture.
7. **No prone points at Mob's Electric Cherry machine** — the +100 prone bonus does not fire there.
   Every other machine works, so this is likely a missing `vending_` tag for that machine.
8. **Solo must not behave like a custom game** — two parts:
   - a. Origins first-generator reward chest still gives Zombie Blood instead of double points, on
     the classic maps. NOTE: `qol_check_solo_status` shipped in v1.55.0 and the probe printed
     `expected=1 is_forever_solo_game=1`, so **re-verify before changing anything** — the flag is
     set, so if the chest is still wrong the cause is downstream of it.
   - b. The solo **intro cutscene** does not play — you get the custom-games loading screen instead.
9. **Death Machine pickup voice line** — the BO1 "Death Machine" announcer callout on pickup.
10. **Nuketown perk-machine placement** — Deadshot's icon lands at an angle, Speed Cola drops half
    into the ground in the back yard. Not diagnosed yet.
11. **Diner teddy bears** — the 3-bear secret-song easter egg on Diner survival (garage, diner,
    Juggernog room). **Blocked:** needs three `.where` readings from the user; coordinates will not
    be guessed.
12. **zm_refreshed weapon ports** — MP7 + Vector to all maps, Dragunov + Spas-12 to Nuketown and
    Mob, MGL to Mob, Remington transferable via fridge, B4KED's fixed Jetgun, **Quick Revive on
    Mob** (confirmed absent; `specialty_quickrevive_zombies` is in no zombies fastfile, so it needs
    shipping). ~400 assets into `mod.ff` — do these **one weapon at a time** with an ownership
    audit after each.

---

## 3. PARKED — known-open, not currently requested

- **T5 wonder weapons** (Thundergun / Wunderwaffe / Winter's Howl). Reverted at v1.56.x after three
  byte-identical crashes: `0x80000003` at `0x129F75DB`, an engine assert with no script or asset
  error. Every asset class was checked and resolved. Leading unproven theory: a hard engine ceiling
  — the creators ship **one weapon per mod**, never all three. Work is in git (`bb44073`,
  `0084881`) and reappliable.
- **Vulture on Origins is a compromise** — ships with `vulture_perk_actor` and
  `vulture_perk_scriptmover` dropped, so the stink pile is invisible there (its entity is a bare
  `tag_origin`). Under "perfectly or not at all" this should be revisited: either revert Vulture on
  Origins or free the bits.
- **Origins generator ring** — the v1.55.2 intro-hold change was shipped as a falsifiable test and
  has never been booted. The probe logs objective index / contested state / players-in-zone.
- **Who's Who damage path** — the pointer is fine (probe confirmed). Remaining lead is
  `zm_tomb_tank::tank_ran_me_over` doing `disableinvulnerability()` then `dodamage(health+1000)`,
  which is also the best lead for `.god` dropping out.
- **`.hud` toggles** — `.hud` off/on plus `.hudtimer` / `.hudhealth` / `.hudcounters`. Dvars exist.

---

## 4. DONE — verified in-game by the user

| version | change |
|---|---|
| v1.56.4 | **Wunderfizz: Origins' real FX + bear bottle on every map** — user: *"looks perfect, works perfect, basically identical to the actual wunderfizz in origins"* |
| v1.56.2 | **Tombstone on Nuketown** — all 12 perks confirmed |
| v1.55.x | **Who's Who** confirmed working |
| v1.54.1 | Origins generator progress bar reported fixed |
| — | **Every classic and survival map loads** — confirmed 2026-08-06 |
