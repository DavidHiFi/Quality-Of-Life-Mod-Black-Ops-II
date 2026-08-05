# Vulture Aid — 14 images still shipping with no pixel data

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
