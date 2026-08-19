# Checkpoint 86 — v1.99.90. Hellhound spawns fixed on Diner, texture pack removed for good.

Written 2026-08-20. **Supersedes 85 for status.** Short by design — the user called out token burn
this session (see §3), so this checkpoint carries only what the next session needs.

---

## 0. STATE — READ THIS FIRST

**Nothing is half-built. v1.99.90 is deployed, hash-verified into Plutonium, committed, NOT booted.**
Everything from checkpoint 85 (v1.99.82 → .89) is ALSO still unbooted.

### 🔴 THE FIRST BOOT — in this order

1. **Diner survival, hellhounds ON.** Watch a full dog round: every dog must appear inside the
   arena. That is this version's whole point.
2. **Mods menu → press U.** Does the mod unload without freezing? (item 26, v1.99.82)
3. **Any map starts** — three LUI overrides from .83/.85/.87 are unbooted.
4. **Esc** → RESUME / **RESTART GAME** / OPTIONS / END GAME / **INSTANT EXIT** / **QUIT TO DESKTOP**.
5. **Options → GAME** = 12 rows, **CHEATS** = 10.
6. **Nuketown** Zombie Blood / Blood Money — the announcer should speak now.
7. **Buried / Mob / Origins** Death Machine — ammo counter gone, not flickering.

---

## 1. 🌟 THE HELLHOUND FIX (user report + screenshot, 2026-08-20)

*"one of the hellhounds spawned outside of the playable area of diner survival"* — dog on the wrecked
truck north of the diner, player at (-4935,-6885).

**Cause, verified end to end:**
- `_zm_zonemgr::zone_init` (`:214-248`) files a struct tagged `dog_location` /
  `screecher_location` / `avogadro_location` into `zone.dog_locations` etc. and **never** into
  `zone.spawn_locations`.
- `zm_transit_loc_diner::disable_zombie_spawn_locations()` only ever walked `spawn_locations`, so
  every spawner it banned stayed live **for hellhounds**.
- `_zm_zonemgr::create_spawner_list` (`:944-976`) rebuilds `level.enemy_dog_locations` every second
  from those arrays, honouring each struct's own `.is_enabled`.
- `zm_transit.gsc:96` sets `level.dog_spawn_func = dog_spawn_transit_logic`, which wants a spot
  **400–1150 units from every player** — so it *prefers* the far ones — and when none qualifies
  falls back to `dog_locs[0]` with no distance check at all.
- `transit_zone_init` (`:1571-1573`) connects `zone_trans_diner` to `zone_roadside_west` / `zone_gas`
  on flag `always_on`, so in Diner survival that zone is enabled and active, donating 6 dog spots
  1,000–1,400 units up the road.

**Fix (v1.99.90, `zm_transit_loc_diner.gsc`):** new
`zmqol_disable_out_of_arena_ai_locations()` runs over `zone.dog_locations`,
`.screecher_locations` and `.avogadro_locations` with the same criteria the zombie pass already
uses — the whole `zone_trans_diner_spawners` / `zone_trans_diner2_spawners` groups, plus three dog
structs measured 127–196 units from a riser the script bans by origin
((-5272,-6400,-35.4), (-4013,-6521,-41.9), (-6550,-7250,-36)). **12 in-arena dog spots remain**, so
`level.enemy_dog_locations` can never empty out — empty would make the picker return undefined and
hang the dog round.

🛑 **Diner-only on purpose.** The tempting general rule *"a zone with no enabled zombie spawners may
not spawn dogs"* was checked against the mapents of every dog-capable map and is **wrong**: 8 of
Nuketown's 16 zones (garage, both alley pairs, truck, start) carry dog locations and no regular
spawner **by design**. Applying it globally would have deleted most of Nuketown's hellhounds.

📝 **Dogs exist on TWO maps only** — measured from mapents: `zombie_dog_spawner` exists in
`zm_transit` (via the `so_zsurvival_zm_transit` addonmapents) and `zm_nuked`. Die Rise, Buried, Mob
and Origins have dog_location structs but no spawner, and `allowdogs` is a `zstandard`-only lobby
row restricted to `zm_transit`.

---

## 2. THE TEXTURE PACK IS CLOSED (queue item 34)

User, 2026-08-20: *"forget about adding any of the textures from that folder… I'll just stick to my
localappdata plutonium t6 images folder instead like normal, and remove that mods folder from the
games' root directory."* They cut the pack into `storage\t6\images\` themselves and deleted
`H:\Claude\ship these to the images of my mod claude`.

Done in v1.99.90:
- 21 remaining pack `.iwi` removed from `images\` (260 → 239). The mod's own images and the two
  `fxt_zmb_perk_*` files that `zone_assets\materials\*.json` reference were **kept** (checked).
- `%LOCALAPPDATA%\Plutonium\storage\t6\mods\zm_qol\images\` (121 files) deleted.
- `<BO2 root>\mods\` deleted — Plutonium never reads it.
- All 125 deleted files were byte-size-identical to files already in the user's own
  `storage\t6\images\`; nothing unique was lost.

**Item 34 can be struck off.** The mechanism knowledge stays in
[[t6-ipak-hash-named-image-overrides]] — a fastfile carries no image pixels, and a loose `.iwi`
only beats the game for images that are in no `.ipak`.

---

## 3. 🛑 TOKEN BURN — A STANDING CONSTRAINT NOW

User, 2026-08-20: *"you've already burnt through nearly half of my usage, that's beyond
unacceptable… Optimize your context & token usage… Make this permanent without affecting your
intelligence during tasks."*

The rule, written into [[zm-qol-token-economy]]: **stop investigating the moment the mechanism is
identified — fix, then report.** This session's cause was proven in ~6 tool calls; the collision-model
GLB dumps, the exe path-builtin hunt and the multi-map audits that followed changed nothing about the
fix. Caps: ≤10 tool calls before the first edit on a known-code bug; no binary/asset dumping unless
nothing cheaper can answer it; no auditing features the user did not mention.

🛑 It still does not outrank [[zm-qol-no-guessing-standard]]. Cut wandering, never evidence.

---

## 4. CARRIED FORWARD (unchanged from 85)

- **Deadshot head lock-on** — shipped, unverified; needs a gamepad and the `deadshot cf:` lines.
- **AIM ASSIST row** (CONTROLS > GAMEPAD) — built, unbooted, needs a gamepad.
- **Jet gun overheat crash test** — overheat it and let it cool. Items 6/7/8 sit on top of it.
- 🛑 **GitHub release `v1.99.21` cannot start a map** and is still downloadable — the user's call.
- Latest release published: **v1.99.89** (147 MB zip). v1.99.90 has no release yet.
