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
> ### Still open after this
> `fxt_zmb_question_mark` + `material gfx_fxt_zmb_question_mark` are in `zm_buried.ff` and
> **not** in `mod.ff`. `_zm_perk_vulture.csc` loads `fx_zm_vulture_glow_question` as
> `vulture_perk_wallbuy_dynamic` — the marker for wall buys with no dedicated weapon icon — so
> that one may still be wrong. Not yet confirmed either way in game. The material dumps cleanly
> with `Unlinker --include-assets material zm_buried.ff`, and the PNG is intact, so the fix is
> the documented add-an-asset path plus a `mod_locations.zone` entry.

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
