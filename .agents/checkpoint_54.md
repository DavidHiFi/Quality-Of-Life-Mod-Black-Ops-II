# Checkpoint 54 — v1.99.5. Power-up timers CONFIRMED and closed. The Death Machine icon was a corrupt texture, twice. Riser probe shipped.

Written 2026-08-16. **Supersedes 53 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

---

## 0. STATE — v1.99.5 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | **Power-up timers** — incl. the Death Machine | ✅ **CONFIRMED IN GAME** (v1.99.3). Queue #1 struck |
| 2 | **Death Machine icon** — the user's own artwork, rebuilt from their PNG | 🟡 v1.99.4, never booted |
| 3 | **Riser origin probe** — print-only, queue #7 | 🟡 v1.99.5, never booted. **Its log line is the deliverable** |
| 4 | **Bleedout bar toggle** (queue #2) | 🟡 still never booted — see §4, the user's "the toggle works" was never tied to a row |
| 5 | **Origins Death Machine ammo counter** (queue #3) | 🟡 still never booted |
| 6 | Titus-6 reload · Winter's Howl fx · `.character` · `mod.ff` stale script | 🔴 unchanged from 53 — queue #9, #8, #13, #12 |

### ✅ CONFIRMED WORKING (cumulative — 🛑 do not disturb)
`.infammo`, perk pop-up toggle, health bar, Origins generator progress overlay, Death Machine on
every map, **and now the power-up timers with the Death Machine included**.

### 🌟 THE ONE THING TO DO ON THE NEXT BOOT
Let a zombie dig out of the ground on Diner and read `console_zm.log` for
`[zm_qol] RISER PROBE`. That single line decides B-RISERSOUND either way — see §3.

---

## 1. POWER-UP TIMERS — closed, after three rounds and three distinct causes

Worth recording because each round's cause was in a different layer, and none of them needed a boot
to find once the right thing was read.

| version | cause | layer |
|---|---|---|
| v1.99.0 | `replaceFunc` on a **synchronous same-file call** (`_zm_powerups.gsc:257`) — dead on arrival | GSC hook |
| v1.99.0 | LUI read `w.powerupId`; the live field is `powerUpId` (stock writes a dead lowercase one at construction) | Lua |
| v1.99.2 | the Death Machine was **never in the loop** — see §2 | GSC data |
| v1.99.3 | the icon's `.iwi` was invalid — see §2 | asset |

**The pattern to carry forward:** at every round the previous round's *comment* asserted the thing
that turned out false. The v1.99.1 banner claimed the Death Machine was covered "with no extra
work"; it was written from what `add_zombie_powerup` ought to do, not from the call site.

---

## 2. 🛑 THE DEATH MACHINE ICON — A CORRUPT TEXTURE, FOUND TWICE, TWO DIFFERENT ORIGINS

### 2a. v1.99.2 — the power-up was not in the timer loop at all

`add_zombie_powerup( "deathmachine", ... )` is called with **seven** arguments;
`client_field_name` / `time_name` / `on_name` are arguments **9, 10 and 11**
(`_zm_powerups.gsc:414`, stored at `:447-452`). So `.client_field_name` was undefined and stock's
own loop — and ours, which mirrors it — hit `continue` every tick.

Fixed **without** a new clientfield: the icon is dvar-driven
(`deathmachine_powerup_state` → `DeathMachineDvarUpdate` → the `deathmachine_powerup` event), so the
client already matched on `powerUpId`. The pickup stamps an end time, the loop appends it, gated on
`.deathmachine_active` **and** remaining > 0.

### 2b. v1.99.3 — the icon file itself was invalid

The timer drew and the icon did not. That combination is itself the diagnosis: `UpdateState` sets
`powerUpId`, `setImage()` and `setAlpha(1)` on three consecutive lines with no branch between them,
so anything proving `powerUpId` is set also proves the icon element is live — and the search moves
to the asset.

`images/ui_powerup_deathmachine.iwi` was 262,228 bytes with **format byte 0**. OAT:
`ERROR: Unknown IWI format: 0`. 400 real T6 `.iwi` sampled across the workspace are version 27,
format 11 / 12 / 13 only. Git held a valid 64×64 DXT5 icon the whole time, identical to the upstream
`t6-ports\...\t6_deathmachine` port; restored with `git checkout`.

### 2c. v1.99.4 — the user's replacement was the SAME broken file, and now we know why

The `.iwi` they supplied was SHA256-identical to the one removed in 2b — which also answers "who
overwrote it": **they installed their own icon**, and it never rendered.

Their source `.dds` is `fourCC = DX10`, **`dxgiFormat = 98` = `DXGI_FORMAT_BC7_UNORM`**. **T6 has no
BC7.** The converter had no format code to emit and wrote 0. That also explains the odd 84-byte
header and 20-byte tail, and why the payload decoded as garbage under every DXT variant at every
offset — it was never DXT at all. The pack's other 64 icons are all valid DXT1; theirs was the only
format-0 file in it.

Rebuilt down the chain `png2dds.ps1` already documents (its own header names this exact trap):
PNG → A8B8G8R8 DDS → `ImageConverter --t6` → **v27, format 1, 512×512**. The finished file was
decoded back to a PNG and **visually confirmed to be their artwork** before shipping.

🌟 **Rule for next time:** BC7 / DX10 DDS cannot ship to T6. Check any incoming texture with
`xxd -l 12 <file>.iwi` — byte 4 must be 1, 11, 12 or 13, never 0.

---

## 3. B-RISERSOUND (queue #7) — the probe, and how to read it

Everything asset-side and script-side is eliminated by measurement (see QUEUE.md): the alias exists,
its bank is loaded, its payload is in `zmb_common.all`, the registration is line-for-line stock, the
clientfield fires, the handler runs, the sound plays twice, and it is inaudible.

The remaining mechanism is **where** it is emitted. `zmb_zombie_spawn` is `DistMin 250 /
DistMaxDry 1000`, so a sound thrown past ~1000 units is silent by design and reports nothing.

`zm_expanded.csc::zmqol_handle_zombie_risers` now prints, once per match:

    [zm_qol] RISER PROBE  riser=(x y z)  player=(x y z)  dist=N  bnewent=0/1  binitialsnap=0/1

| result | verdict |
|---|---|
| `dist` well under 1000 | origin theory **dead** — look at mix / occlusion instead |
| `dist` huge, or `riser=UNDEFINED` / `(0 0 0)` | **confirmed** — fix by emitting once the origin is valid, **not** by moving the sound onto the player |
| `bnewent=1` / `binitialsnap=1` with a bad origin | names the exact cause, which is what makes the fix safe to write |

🛑 It **only prints.** Both `playsound` calls and the chain into stock's handler are untouched, so
this boot cannot regress the risers.

---

## 4. 📝 ONE THING DELIBERATELY LEFT UNRESOLVED

The user said *"the power up timer works, and the toggle works"*. **"The toggle" was never tied to a
row**, and it is either the power-up timers' own HUD toggle or queue #2, the bleedout bar toggle.
Neither was struck on that basis; #2 is still listed as unbooted. Ask, do not assume.

---

## 5. TOOLING — two traps that cost real time this round, both now in ERROR_CATALOGUE §13/§14

1. **`cmd /c ".\build.bat" | Select-Object -First N` KILLS THE BUILD.** PowerShell stops the
   upstream pipeline at N objects and terminates the batch file. It ended a build after step [3/6]:
   `mod.iwd` was packed but **never deployed**, so the verification read the *previous* build and a
   working fix looked broken. Use `-Last N`, or capture to a variable first. The tell is the absence
   of `[5/6] Installing to Plutonium` and `Done.`.
2. **A corrupt `.iwi` reads exactly like a script bug** — the icon is simply absent, and the
   in-game `Could not load material "X"` line is **not** proof on its own, because stock's own
   `zm_hud_icon_battery` and `zom_icon_minigun` print it whenever a menu file parses before their
   fastfile loads, and they render fine.

Also re-learned: to unlink a fastfile it must keep the filename **`mod.ff`** (zone name must match),
and scripts live under asset class **`script`**, not `rawfile` —
`Unlinker --include-assets script` is how `RISER PROBE` was confirmed inside the deployed `mod.ff`.

---

## 6. `/queue` WAS REBUILT THIS SESSION — read this before touching the list

At the user's request (2026-08-16) `/queue` now prints **one flat numbered list and nothing else**:
no Parts, no tables, no IDs, no versions, no status words. The only marking that may ever appear is
`~~strikethrough~~` = *finished, confirmed in game*.

- Strike the **text only**: `1. ~~item~~`, never `~~1. item~~` — the second form stops the line
  being a list item and markdown renumbers everything below it.
- The user then **closed eleven items** as resolved or no longer needed. They are in
  `QUEUE_LIST.md`'s *Closed* section with their old numbers and the old→new map. 🛑 **A closed item
  is history, not a to-do** — do not re-probe or "improve" any of them unless the user names it.
- The remaining 23 were renumbered with no gaps, so **any note citing a queue number from before
  2026-08-16 must be read against that map**.
