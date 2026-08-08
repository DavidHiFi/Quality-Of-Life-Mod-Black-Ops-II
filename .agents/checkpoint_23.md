# Checkpoint 23 — v1.62.5. `.removeperks` empties the perk row. Confirmed.

Written 2026-08-09. Supersedes checkpoint 22 (v1.62.0), 6 commits ago.
Keep 22 §4 (T6 LUI is a modified Lua, and Reimagined is the way in) and §5 (solo
is three problems). Keep 21 §2–§3 (Origins Wunderfizz, Origins clientfield
ceiling), 20 §1–§2, 19, 18 §5, 15 §2 as before.

**Read §0, §2 and §5.**

---

## 0. THE SINGLE NEXT ACTION

**Nothing is in flight — the user picks.** My recommendation, and why:

1. **`.remove<perk>` on a full row** (QUEUE §0ab). The leftover half of what was
   just verified: one perk at a time hits the identical off-by-one. Fix already
   designed — clear the newest perk's clientfield, clear the target's, write the
   newest back to 1. `Update()` refills the first free slot, which is exactly
   where a correct removal would have left it. Same final row, three writes.
2. **The down-with-12-perks case** (QUEUE §A1) — the real root cause, one line
   of LUI, ships alone.
3. **Who's Who visuals** (QUEUE §A2) — 🛑 needs the user's call first, see §4.

**Also still deployed and NEVER booted, from earlier rounds:**

| version | how to test |
|---|---|
| v1.62.0 | Boot **Mob**, try to carry two plane parts at once. Log: `[zm_qol] solo status: expected=N connected=N is_forever_solo_game=N` |
| v1.62.3 + v1.62.4 | Buy **Vulture Aid FIRST, with few other perks**. ⚠️ `.giveperks` HIDES this feature — a machine correctly stops glowing once you own its perk, so 12 perks means nothing lights up. Log: `[zm_qol] CLIENT vulture machines: N of M structs match '<gametype>_perks_<location>'` |

---

## 1. CONFIRMED IN GAME THIS SESSION

| version | change | evidence |
|---|---|---|
| v1.62.5 | **`.removeperks` empties the perk row completely** | Diner survival, solo. Screenshot: row empty. Feed: `gave 12 perk(s)` / `removed 12 perk(s)` |

📝 Open question, not a defect until the user says so: the centre-screen "PhD
Flopper" pop-up was still up in that screenshot. `.giveperks` fires 12 grants
0.1s apart and each pop-up runs several seconds, so the tail of the queue
outliving the command is expected. **Ask whether it faded on its own.**

---

## 2. 🌟 WHY v1.62.2 WASN'T ENOUGH — three findings worth keeping

v1.62.2 removed the newest perk first and the user confirmed it once. It still
failed sometimes (the friend's run showed twelve **Vulture Aid**). All three
reasons are measured, not inferred:

### 2a. A notify is not a write

`"<perk>_stop"` only wakes `perk_think`. What the LUI reacts to is
`perk_think`'s `set_perk_clientfield( perk, 0 )` further down
(`_zm_perks.gsc:2204`) — and `perk_think` **returns early, before that write**,
when `self._retain_perks` or `_retain_perks_array[perk]` is set
(`_zm_perks.gsc:2166-2171`). That is the Tombstone / Who's Who / afterlife state.
A retained perk keeps its icon no matter what order it was notified in.

### 2b. Writes in one frame have no order

Clientfield changes ride **one snapshot per server frame**, so a batch landing in
a single frame reaches the LUI in the engine's field order, not the script's.
Every write must be spaced. 0.1s is the spacing `.giveperks` already uses and the
spacing that produced the user's confirmed 12-distinct-icon screenshot.

🛑 **This is also why the down-with-12 case is unreachable from GSC.** Who's
Who's revive (`_zm_chugabud.gsc:295-335`) and Mob's afterlife
(`_zm_afterlife.gsc:1327-1345`) clear every perk field **in one loop with no
waits**. No script-visible order exists to correct.

### 2c. 🌟 `self.perks_active` IS the LUI's slot array

The old order model sampled `hasperk()` every frame, so **a batch arriving in one
frame was appended in scan order** — the "sometimes", and it matches the friend's
*"he died with whos who"* exactly (the two restore paths above re-hand the whole
loadout through `give_perk()` in one frame).

`give_perk()` appends `self.perks_active` six lines after
`set_perk_clientfield( perk, 1 )` — same function, no wait between
(`_zm_perks.gsc:2045` and `2060`) — and **give_perk is the only place in the
2,093-file stock dump that drives a perk field 0→1** (`2688` is the unpause,
which writes 1 for a perk the row already holds, so it changes no slot). So that
array's append order **is** the order the LUI received the icons.

🛑 **Only the appends are trusted.** `arrayremovevalue( self.perks_active, perk,
0 )`'s third parameter is undocumented — the stock dump has no definition (engine
builtin) and `GSC Documentation.md:3463` lists only the two-argument form — so
whether it preserves the survivors' order is **unknown**. Nothing in the mod
depends on it: `zmqol_order_by_acquisition()` only ever ranks perks appended at
the tail moments earlier.

---

## 3. 🌟 THE GENERAL RULE THIS PRODUCED — one full row, one safe removal

Stock's off-by-one **needs the row to be full**. With even one free slot the loop
reaches it and takes the clearing branch. Consequences, and they apply to any
future perk-row work:

- **Only the FIRST removal is order-critical.** Spend it on the last occupied
  slot; everything after runs against a row of at most eleven and is safe in any
  order.
- Removing the perk in slot 12 is always safe (`NextPerkWidget` is a fresh nil
  local, so the first pass takes the clear path).
- A phantom in our model — a perk we think is on the row but isn't — is the
  **safe** direction: it only makes the row less full than we believe. The
  dangerous direction (an icon we don't know about) cannot happen, because a
  field only reaches 1 through `give_perk`.

---

## 4. 🛑 WHO'S WHO IS BLOCKED ON A DECISION, NOT ON WORK

Fully mapped in QUEUE §A2: five stock calls are missing, every one
`isdefined`-gated so all five fail **silently**. But Buried's `actor` clientfield
set is **32/32 full** (measured from the per-map dumps), so the downed-body clone
glow **cannot** exist there. The screen filter and audio are `toplayer` and are
unaffected.

Under §5's standard that is a per-map compromise and **needs the user's explicit
sign-off before anything ships** — it is not mine to quietly ship on three maps
out of four.

---

## 5. ⭐ THE STANDARD, HARDENED BY THE USER 2026-08-08

*"If you are adding a perk/weapon or literally anything make sure it's not
missing anything, no missing visual fx/sound fx, functionality etc. If you are
unable to add something due to a certain implementation then just don't add it.
It's either perfect implementation with no compromises, bugs, or disrupting
another aspect of the mod, or don't add it at all. **Ever.**"*

A partial feature is a **defect**. Now written into `H:\Claude\CLAUDE.md`
("Perfectly, or not at all" → THE COMPLETENESS AUDIT) and into memory. Run all
six before every hand-off: **functionality, visual fx, sound fx,
animations/models, the client half, no regressions.**

**Enumerate what the REAL thing does, then confirm each part is present** —
listing what your own implementation does and calling it complete is the failure
mode. The method that finds gaps is a **call-by-call diff against stock**,
because T6 gates nearly everything on `isdefined(...)` and a missing piece fails
silently while the feature looks like it works. Who's Who is the model: perk flag
and HUD icon shipped, four more calls missing, zero errors, no visuals at all.

---

## 6. STILL OPEN

- QUEUE §0ab — `.remove<perk>` on a full row. Fix designed, not written.
- QUEUE §A1 — the down-with-12 case. One `else NextPerkWidget = nil` in
  `CoD.Perks.RemovePerkIcon`. Base on Reimagined's readable copy, restore stock's
  `TopStart` (**-180 on DLC3 maps, -140 otherwise**), add a `STATE_PAUSED` branch
  to `Update`, drop `UpdatePerkOrder`/`SpecialtyToClientFieldNames`. Ships alone —
  a bad LUI file hard-crashes.
- QUEUE §A2 — Who's Who visuals, blocked on §4's decision.
- QUEUE §0 — solo parts 1 and 2 (intro cutscene, "CUSTOM GAMES" header). Not GSC.
- QUEUE §0f — god mode after afterlife, Mob Wunderfizz overlapping the shield
  part, custom texture packs conflicting, the stray 254 MB `cmn_root.all.sabl`
  in `build\zm_qol\`.
