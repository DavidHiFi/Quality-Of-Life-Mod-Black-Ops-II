# Vulture Aid — image pixel data

> ## 🛑 v1.62.3 — THE `.dds` DUMP LIES ABOUT ALPHA. USE THE `.png` SOURCES.
>
> **Reported 2026-08-08, with a screenshot:** Vulture Aid's see-through-wall markers (mystery
> box, perk machines, wall buys) drew as *"a coloured sort of blur effect, not the actual
> icons"*.
>
> All 11 `fxt_zmb_*` icon textures had shipped as **IWI format `0x02` (RGB24) — no alpha
> channel at all.** Measured, not guessed: 128×128×3 + 64 = 49216 bytes, exactly the file size
> on disk.
>
> **Why, and this is the part that will catch the next person.** In
> `H:\Claude\All .DDS Files for Zombies\All .DDS'\`, those 11 files declare
> `DDPF_RGB` with **`Amask = 0x00000000`** — no alpha — yet the 4th byte of every pixel really
> does vary 0–255. **The alpha is present in the bytes and absent from the header.**
> ImageConverter believes the header, writes RGB24, and throws the shape away. An fx particle
> keeps its silhouette in alpha, so what is left is a full 128×128 coloured quad: the blur.
>
> 🌟 **The `.png` copies in
> `H:\Claude\BO2 Files Organized By Volkz\Files\zm\Hud\Buried\Vulture Icons\` are intact** —
> `Format32bppArgb`, alpha 0–255, same dimensions. Convert from those:
>
> ```
> png2dds.ps1 -In <name>.png -Out <name>.dds      # A8B8G8R8
> ImageConverter.exe --t6 <name>.dds              # -> IWI format 0x01
> copy <name>.iwi zone_assets\images\ ; build_ff.bat ; build.bat
> ```
>
> **Format `0x01` is right here, not `0x0d`.** Uncompressed ARGB32 is already the most common
> format in this mod (30 of 65 shipped images, including the working Wunderfizz textures). No
> block compressor exists on this machine, and at 64 KB per icon the size is irrelevant.
>
> 🛑 **`build_ff.bat` is NOT optional for this.** `mod.ff` held format-`0x02` *headers* built
> from the old files. Swapping only the `.iwi` leaves header and pixels disagreeing, which is
> the measured purple/green m1911 failure — worse than the blur. Relinking makes both come from
> the same file; the proof is `Loaded image "fxt_zmb_..." (src: disk)` in the link log.
> Asset list verified identical afterwards (3813 lines, nothing re-owned).
>
> **Verify a converted icon before shipping it:** paint the alpha channel as greyscale and look
> at it. Correct output is a *shape mask* — the perk badge silhouette, crossed rifles, a skull,
> a "?" — with the artwork living in RGB. An all-white alpha means it was lost again.
>
> ### ✅ NOTHING ELSE IS MISSING — and the earlier note here was WRONG
>
> This file briefly claimed `fxt_zmb_question_mark` + `gfx_fxt_zmb_question_mark` still needed
> adding, because they are in `zm_buried.ff` and not in `mod.ff`. **Retracted — they are not
> Vulture's.** Two independent checks:
>
> 1. **The Linker resolves fx dependencies by itself.** `mod_locations.zone` and
>    `mod_base.zone` between them list **zero** `gfx_fxt_perk_*` materials and **zero**
>    `fxt_zmb_*` images (`grep -c` → 0 in both), yet `mod.ff` carries all 11 images and all 22
>    materials. They arrive purely as dependencies of the `fx,` lines. So a listed fx pulls in
>    everything it needs — and `fx,maps/zombie/fx_zm_vulture_glow_question` **is** listed
>    (`mod_locations.zone:332`), links with 0 errors, and pulls in no question_mark.
> 2. **In `zm_buried.ff`, question_mark belongs to a different effect.** Its image and material
>    sit immediately before `fx, maps/zombie/fx_zmb_wall_buy_question` — Buried's own wall-buy
>    marker, which `_zm_perk_vulture.csc` never loads.
>
> 🛑 **CORRECTED v1.99.71 — this paragraph used to say `fx_zm_vulture_glow_question` draws
> `fxt_zmb_perk_magic_box` (a "?" and a hook). IT DRAWS `fxt_zmb_perk_rifle` — CROSSED RIFLES.**
> That was an inference from the contact sheet, never a measurement, and the user's screenshot
> settled it: with Vulture Aid held, the PhD Flopper machine (code 10, so `glow_question`) carries a
> white/blue **crossed-rifles** icon, while the mystery box in the same frame carries the yellow
> **?-and-hook** — which is `vulture_perk_mystery_box_glow` and `fxt_zmb_perk_magic_box`. Two
> different effects, two different textures, both visible at once. The wall-buy "?" marker claim
> above is therefore wrong too: `glow_question` is the marker for a wall WEAPON, which is why its
> texture is a weapon. Both textures are still among the 11 fixed in v1.62.3, so nothing is missing
> — only the name-to-texture mapping was wrong.
>
> 📝 Adding question_mark would have been pure cost: `mod.ff` would then **own** a Buried asset
> it has no use for, which is the ownership trap that has broken maps here before.

## Original note — 14 images still shipping with no pixel data

> **v1.42.0 — `specialty_vulture_zombies_glow` is done**, and it was not on either list below
> because nothing had noticed it was pulled in at all. It is not referenced by a script or by
> `mod_locations.zone`; the Linker drags it in as the image behind `zm_hud_stink_perk_glow`, the
> third stink-HUD material. The link log is where that shows up —
> `Loaded image "specialty_vulture_zombies_glow" (src: zm_buried)`, a header out of a fastfile with
> no matching `(src: disk)` line for its pixels. **Read the `Loaded image` lines after a link:
> anything sourced from a stock zone rather than from disk is a header with nothing behind it.**
> Its DDS was in the workspace dump all along and converted cleanly at 64×64 DXT5.

**The rule:** an image declared in `zone_source\` is only a **header**. T6 loads the actual pixels
at runtime from a loose `.iwi` inside `mod.iwd`. A header with no `.iwi` draws as a **blue/grey
checkerboard** — which is exactly what the Vulture Aid HUD icon did in v1.40.0.

`build.bat` copies `zone_assets\images\*.iwi` → `images\` → `mod.iwd`, so dropping a correct `.iwi`
in this folder is the whole fix.

## Done (22 of 37)

Converted from `H:\Claude\All .DDS Files for Zombies\All .DDS'\` with:

```
ImageConverter.exe --t6 <name>.dds
```

Sanity check the result: `IWi` magic, version `0x1b`, **format `0x0d`** (DXT5).
🛑 Format `0x00` means the source was A8R8G8B8 — it converts *without error* and is then rejected.

## Not done (15)

### 4 normal maps — source is `.tga`, which ImageConverter will not read
```
eb_dec_dirt_splotch_n
mtl_p6_zm_vending_vultureaid_n
p6_zm_bu_zombie_ammocan_n
p_glo_bullet_n
```

### 11 generated colour maps — exist in the workspace only as PNG
In `H:\Claude\BO2 Files Organized By Volkz\Files\zm\...` (Perks\Bottles, Perks\Machines\Vulture, …)
```
zm_afterlife_alcatraz_vignette_noise      zm_al_concrete_bare_g
~-geb_dec_dirt_splotch_c                  ~-gmtl_p6_zm_vending_vultureaid_c
~-gmtl_t6_zmb_perk_bottle_vulture_col     ~-gp6_zm_bu_zombie_ammo_bullet_c
~-gp6_zm_bu_zombie_ammocan_c              ~~-gmtl_p6_zm_vending_vulture~068843fb
~~-gmtl_p6_zm_vending_vulture~2f65ad8f    ~~-gp6_zm_bu_zombie_ammo_bull~d50536dc
~~-gp6_zm_bu_zombie_ammocan_s~bfb6eefc
```

Both sets need a PNG/TGA → DDS step first. **`png2dds.ps1` in the project root is that step** as of
v1.41.1 — it writes uncompressed A8B8G8R8, which is the format ImageConverter will accept (A8R8G8B8
converts without error to IWI format `0x00` and is then rejected). The 11 PNG-only maps are
unblocked; the 4 `.tga` normal maps still are not.

## What this actually costs in game

| asset | visible on the five added maps? |
|---|---|
| `specialty_vulture_zombies` (HUD icon) | **yes** — fixed, this was the reported bug |
| `~-gmtl_t6_zmb_perk_bottle_vulture_col` (bottle) | **yes** — Wunderfizz dispenses it, and you drink it |
| ammo / points pickup colour maps | **yes** — they drop from zombies |
| `p6_zm_vending_vultureaid*` (machine albedo) | **no** — these maps have no physical Vulture Aid machine |
| normal maps | subtle; lighting detail only |

So the remaining priority is the **bottle** and the **two pickups**. The machine textures can stay
missing indefinitely without anyone seeing them.
