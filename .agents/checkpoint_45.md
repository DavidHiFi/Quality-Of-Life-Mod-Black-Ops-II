# Checkpoint 45 — the Origins generator ring is ROOT-CAUSED. No fix shipped, on purpose.

Written 2026-08-14. **Supersedes 44 for status.** Keep 44 §1 (the runaway-`join` incident and its
rules) and §2 (the XPR-50 asset measurements); keep 43 §3 (foley research), §4 (black loading
screens), §5 (Brutus).

---

## 0. STATE — v1.90.11 deployed, tree clean at `b60aa39`

🛑 **NINE VERSIONS ARE DEPLOYED. ONE HAS BEEN PARTLY BOOTED.**

| version | what | state |
|---|---|---|
| v1.89.8 | Electric Cherry fx — Wunderwaffe port was writing stock globals | 🟡 never booted |
| v1.89.9 | Vulture stink overlay yields to Zombie Blood | 🟡 never booted |
| v1.90.0 | Velocity meter — `.velocity on/off` + `velocity` dvar | 🟡 never booted |
| v1.90.1 | `.brutus` / `.panzer` / `.jumpingjacks` + `spawn_*` dvars | 🟡 never booted |
| v1.90.3 | Night-mode clamp was flooding the reliable channel | 🟡 never booted |
| v1.90.4 | `.jumpingjacks` was gated on a zstandard-only array (Die Rise) | 🟡 never booted |
| v1.90.5 | Weapon foley — 162 aliases, 258 rows | 🟡 never booted |
| v1.90.6 | HUD colours — game time yellow, round timer light blue, velocity yellow | 🟡 never booted |
| **v1.90.11** | **Origins capture-ring nudge** | ✅ **booted — ring appears, but it FLASHES** |

The v1.90.5 boot produced the seven-item batch (B1–B7) at the bottom of `QUEUE.md`. Only B7 has
been worked since.

---

## 1. 🌟 B7 — THE GENERATOR RING. Mechanism found; the fix is BLOCKED on one measurement.

Full write-up is the last section of `QUEUE.md`. Condensed:

**The ring's menu is created invisible and only ever un-hides on an incoming HUD event.**

- The ring is `tombcapturezonedisplay.lua`. 🛑 **This is NOT the file v1.90.8 A/B-tested**
  (`hudcraftablestombzombie.lua`) — that test came back clean and misdirected three attempts.
- `CoD.GametypeBase.new()` (`gametypebase.lua:23`) ends `f1_local0:setAlpha(0)`.
- `LUI.createMenu.TombCaptureZoneDisplay` ends `f1_local0.visible = nil`.
- Only `CoD.TCZWaypoint.UpdateVisibility` ever writes alpha 1, and it runs solely on
  `hud_update_bit_*` or on `hud_update_refresh` → `CoD.GametypeBase.Refresh`.

The waypoint child is built correctly by `createObjectiveIfNeeded`. The parent is at alpha 0. That
is the entire bug, and it retroactively explains every earlier failure: the server side was always
perfect, the re-declares (v1.90.2/.7/.9) could never have mattered, and the scoreboard press works
because `BIT_SCOREBOARD_OPEN` → `UpdateVisibility` → `setAlpha(1)`.

### 🛑 There is no script-side fix. Measured, not assumed.

Over the whole `gsc-dump`, stock sets exactly four visibility flags:
`hud_visible` (26), `g_compassShowEnemies` (12), `killcam_nemesis` (6), `radar_client` (5).
The ring's menu registers **only** `BIT_HUD_VISIBLE` of those — the flag that hides the rest of the
HUD. **The flash v1.90.11 causes is unavoidable from GSC.**

📝 `BIT_PLAYER_DEAD` would have been the perfect carrier — registered by 11 zombie HUD menus and
tested in **none** of their visibility conditions, so it wakes every menu while changing no
outcome. There is no script-settable flag name for it.

### 🛑 Reimagined's copy of the file CANNOT be shipped wholesale

Verified against the stock bytecode dumped from
`F:\SteamLibrary\steamapps\common\Call of Duty Black Ops II\zone\all\zm_tomb_patch.ff`:

| check | result |
|---|---|
| string constants | 22/23 match. **`transition_complete_snap_out` ABSENT from stock** — Reimagined ADDED that handler and it calls `setAlpha(0)`, which would fight the fix |
| numeric literals (float32 byte-scan) | 15/17 present. **`74` and `-101` ABSENT** — both in `CoD.TCZRoamingZombies` |

🌟 **Method worth reusing:** dump the stock `.lua` bytecode with
`Unlinker --include-assets rawfile`, then (a) `tr -c '[:print:]' '\n'` it and diff the string set
against the decompile, and (b) byte-scan each numeric literal as a little-endian **float32** (the
header is `1b4c7561 51 0d 01 04 04 04 04 00` — `sizeof_number = 4`, `integral = 0`). Absent bytes
mean the decompile invented the value.

---

## 2. THE BLOCKING MEASUREMENT — never taken in four rounds

**Does VANILLA Origins show the generator ring at match start?**

- **Vanilla also broken** → base-game/Plutonium behaviour, the mod is not at fault. Remove the
  v1.90.11 nudge entirely and leave it. No new file ownership.
- **Vanilla fine** → the mod swallows an early HUD event. Find and remove that. Also no new file
  ownership.

Either way the answer removes the hack; it decides *what replaces it*. **Nothing should ship
before it.**

User instruction that drives this, verbatim: *"just make the ring behave like the stock vanilla
base game so it's not being hidden or modified, my mod shouldn't be doing that i never asked you
for you hide that."*

v1.90.11 was deliberately left deployed so the user keeps a working (if flashing) ring rather than
none while this is settled.

---

## 3. NEXT, in order

1. 🛑 **The vanilla A/B above.** Origins, **mod OFF**, first generator in the spawn bunker, hold F.
   Does the ring appear without touching the scoreboard?
2. Fix B7 per whichever branch that answers, and **delete `zmqol_capture_hud_nudge()`** either way.
3. Once the ring is confirmed, remove the now-pointless re-declare loops
   (`zmqol_capture_objectives_fix` / `_on_connect`) — disproven as load-bearing, and they cost
   solo loading smoothness. Held back only by "one change at a time".
4. 🛑 **BOOT THE OTHER EIGHT VERSIONS.** Listen for v1.90.5 foley (insas, sa58, mk48, qbb95, mp7,
   vector, crossbow) and check v1.90.6's HUD colours.
5. The rest of B1–B6, then checkpoint 44 §3: XPR-50 art (asset-ownership job) · Brutus probe ·
   Titus-6 · perk-icon streaming · black loading screens.
