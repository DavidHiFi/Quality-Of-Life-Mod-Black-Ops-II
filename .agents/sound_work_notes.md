# Sound work — findings and plan (2026-08-02)

Two requests from the user, neither started. Everything below is **verified**, not assumed.
Written so the investigation does not have to be repeated.

---

## 1. Gun sounds ("Add these sounds to my mod")

Source: `H:\Claude\Add these sounds to my mod\` — "BO2 Weapons Remastered", from GameBanana.
User's goal: have the sounds active **only when the mod is loaded**, so vanilla play is unaffected.

### What the download actually is

Five **complete drop-in replacements** for stock game banks, not add-ons:

| file | modded | stock |
|---|---|---|
| `cmn_root.all.sabl` | 265,072,640 | 266,502,144 |
| `zmb_common.all.sabl` | 91,117,568 | 91,109,376 |
| `zmb_alcatraz.all.sabl` | 65,292,288 | 65,378,304 |
| `zmb_buried.all.sabl` | 76,990,464 | 77,056,000 |
| `zmb_tomb.all.sabl` | 103,741,440 | 103,546,880 |

They sit just under stock size on purpose — the author's `wpn\footnote.txt` says BO2 will not
load if a replacement bank is **larger** than the file it replaces. They are meant to overwrite
`<BO2>\sound\`.

Also included: `bo2_weapons_remastered_-_041722_build_uncompiled\wpn\` — **143 raw .wav files**
plus 4 .flac, organised `wpn\<class>\<weapon>\shot.wav` and `wpn\<class>\reload\*.wav`. This is
the real source and the only viable input for an in-mod port.

### Why "just ship the banks in the mod" is the wrong answer

A mod **can** ship sound banks: `zone_source\mod_base.zone` declares `soundbank,mod.all` and
`soundbank,deathmachine_zm.all`, and Plutonium loads those from the mod folder. That mechanism
is proven — `deathmachine_zm.all.sabl` is how the Death Machine gets its firing sound.

But the zombies-relevant banks total **336 MB** (`zmb_common` + the three map banks), and the
shared weapon sounds in `cmn_root` are another 265 MB. Shipping them would take the mod from
~60 MB to ~600 MB. That is unacceptable for a mod meant to be handed to friends, regardless of
whether it works.

**The only sane in-mod route is the 143 loose .wav files**, rebuilt into the mod's own
`mod.all.sabl` under the stock alias names. That is a plausible 10–30 MB.

### The two blockers

1. **🛑 Unproven: can a mod bank's alias OVERRIDE a stock one?**
   `deathmachine_zm.all` and Reimagined's `mod.all.aliases.csv` (1,480 aliases, e.g.
   `wpn_fnp45_fire_plr`) only prove a mod can **add** aliases for weapons it ports in — those
   names do not exist in the loaded stock set. Nothing here demonstrates *shadowing*
   `cmn_root`'s `wpn_<weapon>_fire_plr`. This must be settled by one in-game test before any
   bulk work; if it fails, the whole in-mod approach is dead and only a game-file swap works.

2. **🛑 No CLI tooling exists.** There is no soundbank builder anywhere in the workspace.
   Reimagined keeps `soundbank\mod.all.aliases.csv` as source but ships a prebuilt bank; its
   `build.bat` only `xcopy`s `*.sabl`. Black Ops II Sound Studio (both versions, at
   `C:\Program Files\BlackOpsII SoundStudio[ Extended]`) is a GUI .NET app. **An agent cannot
   build or edit a .sabl/.sabs.** The user has to do the tool work; the agent's job is to
   determine exactly *what* to change.

3. Alias names are stored **hashed** inside `.sabl`/`.sabs` — grepping a bank for `wpn_`,
   `mus_` or a weapon name returns zero hits, in both the mod's bank and stock `cmn_root`.
   Sound Studio resolves them from its own hash→name dictionary. So bank contents cannot be
   inspected outside the GUI.

### Recommended order

1. Cheap proof first: pick **one** weapon, alias it over its stock name, build a test
   `mod.all.sabl`, load a match, listen. That single test decides everything.
2. Only if it wins: map all 143 .wav files to alias names (the folder layout gives the weapon
   and the event; Reimagined's CSV gives the authoritative field schema), generate the alias
   CSV, import once.
3. If it loses: fall back to a backup-and-swap toggle script for `<BO2>\sound\`. Guaranteed to
   work, no bloat — it just is not literally inside `mod.iwd`.

---

## 2. Main menu music ("Main Menu music replacer")

Source: `H:\Claude\Main Menu music replacer\` — `Damned 8 - Black Ops 7 Zombies.m4a` plus the
user's copy of `zmb_code_post_gfx.all.sabs` (25,309,184 B, byte-identical in size to stock).
Symptom: swapping `damned_100ae.SL65.pc.snd` works, but the track **does not loop**.

### Cause

**Looping is an alias property, not a property of the audio payload.** Confirmed from
`BO2-Reimagined\soundbank\mod.all.aliases.csv`, whose header is the real T6 alias schema —
`Looping` is column 32, alongside `Storage` (4), `IsMusic` (49), `FadeIn` (51), `FadeOut` (52).
Values seen in the wild: `Looping` = `looping` / `nonlooping`, `Storage` = `loaded` / streamed.

Replacing the `.snd` payload leaves the alias row untouched, so whatever the stock alias says
still governs playback. The fix is to edit the **alias**, not the file — and alias fields are
only exposed by **Sound Studio Extended**, not the plain version.

### 🛑 Open question before promising this as a mod feature

Zombies menu music plays in the **front end**, and a Plutonium mod is loaded when a match
starts. If that holds, a mod cannot change menu music at all and this can only ever be a
game-file edit. **Not yet verified** — do not tell the user it works until it is.

---

## Standing constraint

Do **not** modify anything under `F:\SteamLibrary\...\Call of Duty Black Ops II\` without
asking. The user's whole reason for both requests is to keep the vanilla install clean.
