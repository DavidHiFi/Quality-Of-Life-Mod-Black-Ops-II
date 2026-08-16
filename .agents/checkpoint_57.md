# Checkpoint 57 — v1.99.8. B-RISERSOUND: the whole chain is now verified end to end, and `.testsound` asks the one question no file can answer.

Written 2026-08-16. **Supersedes 56 for status.** 48 §1–§4 and 50 §1–§4 remain unbooted.

🛑 **The user authorised skipping ahead:** *"do the next task in the queue, i'll test both when i
launch next."* So **queue #7 (Winter's Howl, v1.99.7) is deployed and STILL UNVERIFIED**, and #6 was
opened on top of it. Both land in the same boot.

---

## 0. STATE — v1.99.8 deployed, bytes verified, never booted

| # | item | state |
|---|---|---|
| 1 | Bleedout bar live toggle (queue #1) | ✅ **CONFIRMED IN GAME** at v1.99.6 |
| 2 | **Winter's Howl firing fx** (queue #7) | 🟡 root-caused + fixed in **v1.99.7**, **never booted** — checkpoint 56 §1 |
| 3 | **Riser sound** (queue #6, B-RISERSOUND) | 🟡 **chain fully verified, cause NOT found.** `.testsound` shipped in **v1.99.8** to settle it — see §1 |
| 4 | Origins Death Machine ammo counter (queue #2) | 🔴 still never booted |
| 5 | Titus-6 reload · `.character` · `mod.ff` stale script | 🔴 unchanged — queue #8, #12, #11 |

### 🌟 THE TWO THINGS TO DO ON THE NEXT BOOT (one Diner survival game covers both)
1. `.wintershowl`, **fire it** — expect a real flash, not the heat-shimmer smear. Then Pack-a-Punch
   and fire again.
2. `.testsound` — listen for **three** sounds about a second apart, and say **which of the three you
   heard**. That is the whole test.

---

## 1. B-RISERSOUND — EVERY LINK VERIFIED, AND IT IS STILL SILENT

Checkpoint 55 left this at *"what remains is the mix"*. This round closed the last asset-side gaps
rather than guessing at the mix. **Nothing was found wrong.** That is a result, not a failure — it
is what makes the probe the correct next move instead of a fifth theory.

| link | verified how | result |
|---|---|---|
| server sets `zombie_riser_fx` | v1.99.0 probe line in the log | ✅ |
| the client handler runs | same | ✅ |
| the actor origin is valid | v1.99.5 probe — `dist=513`, `bnewent=0`, `binitialsnap=0` | ✅ inside the 1000-unit range |
| `zmb_zombie_spawn` is defined | 2 rows in `zmb_survival_transit.all`, which loads (`console_zm.log:1011`) | ✅ |
| the alias row is sane | **dumped and read in full this round**: `VolMin/Max 86`, `Probability 1`, `PanType 3d`, `DistMin 250 / DistMaxDry 1000`, `Storage loaded`, `Bus bus_hdrfx` — the same bus as **3,130** other aliases in that bank | ✅ nothing unusual |
| the payload exists | audio dumper `Identifiers\zmb_common.all.txt` → `AAF96C0F` / `77818910` | ✅ |
| 🌟 the payload is in the **right kind** of bank | **byte-scanned both files**: both hashes appear **once in `zmb_common.all.SABL`** (the loaded bank `Storage=loaded` demands) and **zero times in the `.sabs`** | ✅ **new this round** |
| that bank is loaded | `console_zm.log:349-353` | ✅ |
| does `mod.all` shadow the alias? | checked the **BUILT** 2,280-row table (`zone_assets\soundbank\mod.all.aliases.csv`), not just the 589-row additions file | ❌ **no** — and only 3 rows in the whole mod carry a stock `zmb_` name (`zmb_buildable_piece_add` / `_complete` / `_loop`) |
| our registration vs stock | line-for-line, all four fields | ✅ |
| the sound is played | **twice** — our wrapper, then stock's | ✅ |

📝 The `mod.all` check is worth keeping as a method note: the obvious file to grep is
`soundbank\mod.all.aliases.additions.csv` (589 rows, ours). The bank that actually **ships** is the
donor's cached table with ours merged on top — 2,280 rows. Checking only the additions would have
been a real false negative.

### 🌟 v1.99.8 — `.testsound`, and why the control matters more than the probe

```
console :  zmqol_testsound zmb_zombie_spawn        (a CLIENT dvar - needs no server)
chat    :  .testsound [alias]                      (defaults to zmb_zombie_spawn)
```

It plays three things, ~1.2 s apart, printing each:

| | what | tests |
|---|---|---|
| 1/3 | `playsound( 0, alias )` — **2D**, no distance model at all | does this alias produce audio, period |
| 2/3 | `playsound( 0, alias, player.origin )` — **3D at your own feet** | the positional path |
| 3/3 | `zmb_powerup_grabbed` at the player — **the control** | that the probe itself reaches audio |

🌟 **The control is a matched pair, not an arbitrary loud noise.** `zmb_powerup_grabbed` sits in the
**same alias bank**, on the **same bus** (`bus_hdrfx`), with the **same `Storage`** (loaded), the
**same `DistMin`** (250), and its payload is in the **same `.sabl`** (`zmb_common.all`). The only
material differences are `VolMin 76` vs `86` and `DistMaxDry 2000` vs `1000`. It is the closest
comparison the game contains, and the user hears it every match.

**Reading the result — this is the point of the whole thing:**

| heard | conclusion |
|---|---|
| all three | the alias is fine → the fault is the riser **wiring or its timing**, not the audio asset |
| control only | **this alias produces no audio**, and the next step is the payload bytes |
| 2D yes, 3D no | positional attenuation, not the asset |
| nothing at all | the probe never reached audio — say so; it does **not** mean the alias is dead |

### Pre-mortem — four ways this probe fails, and what was done about each

1. **`setclientdvar` on a name the engine has never seen is rejected.** Plausible; the mod only ever
   `setclientdvar`s **stock** dvar names. 🌟 **Mitigated by design: the console route does not use the
   server at all.** `zmqol_testsound <alias>` typed into the console is read directly by the client
   script — the same `getdvar` mechanism `freeze.csc`'s `zmqol_ww` gate already uses in shipped code.
   Two independent routes to the same dvar; if one is dead the other still answers.
2. **Asking for the same alias twice does nothing** — the watcher fires on a *change*. The server
   route appends a counter (`zmb_zombie_spawn 3`) and the client takes token 0.
3. **It runs before there is a local player.** Every play is guarded by a fresh
   `getlocalplayer(0)` + `.origin` check, re-taken after each `wait`.
4. **It costs something when unused.** One `getdvar` every 0.25 s on the client — a local hash
   lookup. **No reliable commands, no clientfields, no server work** unless invoked. ERROR_CATALOGUE
   §7b is about sustained emitters; this emits nothing.

📝 Builtins confirmed to exist client-side before use, in the stock dump's own `.csc` files:
`strtok`, `getdvar`, `println`, and the **two-argument** `playsound( localclientnum, alias )` form
(`_helicopter_sounds.csc:611`, `:54`). Nothing here was assumed.

### 🛑 What was deliberately NOT done

**The sound was not moved onto the player as a fix.** Checkpoint 55 ruled that out explicitly and the
origin theory is dead anyway (`dist=513`). `.testsound` plays *at* the player, but it is a
diagnostic command the user invokes — the riser path is untouched.

---

## 2. DEPLOYMENT

`mod.json` 1.99.8. A `.csc` changed, so **`build_ff.bat` first, then `build.bat`** — the order the
workflow requires.

- `gsc-tool -m parse` clean on both edited files (`-i client` for the `.csc`).
- `mod.ff` relinked: **0 errors**, asset classes unchanged (fx 151, script 29, weapon 99,
  soundbank 2, material 864, image 1128, xmodel 310). Nothing lost, nothing changed owner.
- The `.csc` inside `mod.ff` is **hash-identical to source** (92,347 bytes) — it shipped from disk,
  not the donor's stale copy.
- Confirmed inside the **deployed** files: `zmqol_testsound_watch` in `mod.ff`'s `zm_expanded.csc`;
  `.testsound` in `mod.iwd`'s `quality_of_life.gsc`; and **v1.99.7's Winter's Howl fix is still
  intact** (`fx_freezegun_view.efx` 46,883 bytes, `drawWithViewModel` ×7).

🛑 **Deployed, NOT yet verified in game. Two unverified changes are now in flight at the user's
explicit request.**
