# Checkpoint 22 — v1.62.0. Perk row reverted, Tombstone icon fixed, solo half-fixed.

Written 2026-08-08. Supersedes checkpoint 21 (v1.61.1), 8 commits ago.
Keep 21 for §2 (the Origins Wunderfizz) and §3 (Origins clientfield ceiling).
Keep 20 §1–§2, 19, 18 §5, 15 §2 as before.

**Read §0 and §4. §4 is the one that changes how the next session works.**

---

## 0. THE SINGLE NEXT ACTION

**Boot Mob of the Dead and try to pick up two plane parts at once.**
That is v1.62.0 — deployed, never booted. The log line will say:

```
[zm_qol] solo status: expected=N connected=N is_forever_solo_game=N
```

If `is_forever_solo_game=1` and parts still don't share, the cause is
downstream of the flag and the log has already narrowed it.

Then `.agents\QUEUE.md` top down. §0g names the next feature step.

---

## 1. CONFIRMED IN GAME THIS SESSION

| version | change | user's words |
|---|---|---|
| v1.61.2 | **stock perk row restored** (my v1.61.0/.1 reverted in full) | "phd bug seems to be gone" |
| v1.61.3 | **Tombstone HUD icon no longer upside down** | "the tombstone icon looks perfect" |

🛑 **"phd bug seems to be gone" is NOT "fixed".** The revert put stock's Lua
back, and stock's off-by-one is still in it. It only fires after owning **all
12 perks and then losing them** (`.giveperks` then a down). Dormant, not gone.
Root cause and the one-line fix are in QUEUE.md §0c.

**Deployed, NOT verified:** v1.62.0 solo flag.

---

## 2. 🌟 THE PhD ROOT CAUSE — and checkpoint 21 §5 WAS WRONG

Checkpoint 21 said the perk row was drawn by "engine code bound by
`setupclientfieldcodecallbacks`" that "no GSC change can inspect or correct".
**False. The row is LUI.**

`setupclientfieldcodecallbacks` only makes the engine **dispatch a LUI event**
named after the clientfield. `CoD.Perks.Update` in `hudperkszombie.lua`
handles it.

The bug is an off-by-one in stock's own `CoD.Perks.RemovePerkIcon`: removing a
perk shifts every icon down a slot, but on the **last** index `NextPerkWidget`
still points at slot 12 from the previous iteration, so slot 12 copies itself
and never clears. Own ≤11 perks and slot 12 is empty, so stock never sees it.
**Own all 12 — which only this mod does — and the row collapses to twelve
copies of the last-acquired perk, permanently.**

Fix is one `else NextPerkWidget = nil;` branch. Full detail in QUEUE.md §0c.

---

## 3. THE SESSION'S OWN LESSON — I SHIPPED SCOPE NOBODY ASKED FOR

v1.61.0 replaced the game's perk row with a GSC-drawn one to dodge a bug I had
wrongly declared unreachable. It cost the icon size (twice) and the purchase
pulse animation. The user: *"that's all I wanted you to fix originally but you
went and changed a bunch of other stuff."*

📝 **When a fix requires replacing a whole subsystem, that is the signal the
diagnosis is incomplete — not a licence to widen scope.** The real cause was
readable the whole time, in a file sitting in the workspace.

📝 **Render the intermediate before shipping it.** The Tombstone icon was asked
for as "flip it 180 degrees". Rotating it and *looking* at the result showed
"RIP" upside down. Reimagined had re-composited, not rotated. One render
prevented shipping something worse than stock.

---

## 4. 🛑 T6 LUI IS A MODIFIED LUA — AND REIMAGINED IS THE WAY IN

`ui_mp\**\*.lua` are compiled Lua 5.1 in a **Treyarch-modified format**:
format byte **13**, a 13-entry type table after the header ending at offset
**242**, constant type ids **shifted +1** (TSTRING=5 not 4), and **4-byte float
numbers** instead of doubles.

unluac is installed at **`H:\Claude\unluac\`** (v1.2.3.569 jar + official hg
source + `README_T6.md`). **It cannot read T6 files**, and patching it is not
small: splicing a standard header and brute-forcing **every** offset 236–274
still fails, so the function/constant encoding deviates too.

🌟 **You very likely do not need it.** `H:\Claude\BO2-Reimagined\` ships **35
LUI files as plain readable source**, including everything currently blocked:

| file | covers |
|---|---|
| `ui\t6\menus\privateonlinegamelobby.lua` (112 lines) | **line 10 `Engine.Localize("MPUI_CUSTOM_GAMES_CAPS")` → `addTitle` line 16 — the "CUSTOM GAMES" header** |
| `ui_mp\t6\hud\loading.lua` | the loading screen |
| `ui_mp\t6\zombie\hudperkszombie.lua` | the perk row / PhD bug |

🛑 They are stock **plus Reimagined's own changes** — reconcile, never paste
blind. Stock numeric constants are readable straight out of the bytecode with
no decompiler: that is how stock's `TopStart` (**-180 on DLC3 maps, -140
otherwise**), `IconSize` **36** and `Spacing` **8** were recovered.

🛑 `ui_mp\` overrides are **whole-file replacements**. There is no way to ship
a small patch that redefines one function. A bad LUI file **hard-crashes the
game**, so any LUI change ships alone.

---

## 5. SOLO IS THREE PROBLEMS, ONE IS FIXED

The user wants solo to be solo, keeping instant start and Diner selection.

**Fixed (v1.62.0):** `qol_check_solo_status` tested
`getnumexpectedplayers() == 1`. The engine reports **0** on Mods-menu launches
— this project had already measured that in `onallplayersready_instant` and
never connected it here. Now `<= 1`, in both Mob's and Origins' copies.
Origins only ever looked fine because its call site runs later in the load.

**Not started, and not GSC:** the intro cutscene and the menu header. **There
is no cinematic code anywhere in the 2,093-file stock dump** — the intro plays
from the menu system before the map loads. Both trace to one root: the mod
launches through the private-game (Custom Games) lobby, which is exactly what
provides Diner selection and instant start.

📝 Stock's solo gate is **only** `check_solo_status` on Mob and Origins —
every `sessionmodeisonlinegame`/`sessionmodeisprivate` use in the stock dump
was checked; the rest are banking, weapon locker, achievements, leaderboards.

---

## 6. THE TOMBSTONE ICON — the fastfile lesson worth keeping

Shipping Reimagined's 64x64 `.iwi` into `images\` alone would have rendered
garbage: `mod.ff` owned a **32x32 header** for that image, and a loose `.iwi`
read through a mismatched header is the measured purple/green m1911 failure.

The fix: put the file in `zone_assets\images\` and relink. A raw file on the
Linker's search path makes it **compile from disk** rather than copy the
donor's — the link log says `(src: disk)`, which is the proof to look for.
Header and pixels then come from the same file.

Verified after: `Unlinker --list` asset list **identical**, 3813 lines, so
nothing was re-owned.

---

## 7. STILL OPEN

`.agents\QUEUE.md` is the authority. Headline items:

- **Solo parts 1 & 2** — intro cutscene, "CUSTOM GAMES" header (§0g has the step)
- **PhD off-by-one** — one `else` branch in `hudperkszombie.lua`
- **God mode drops after Mob's afterlife**
- **Mob Wunderfizz overlaps the shield part spawn**
- **Custom texture packs conflict** — 776 header-only images in `mod.ff`
- Stray **254 MB `cmn_root.all.sabl`** in `build\zm_qol\` — not one of the 6
  mod files, do not zip it to anyone
