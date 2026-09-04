<div align="center">

<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/32a1cfbd-7ece-4a91-9690-82691bed24b1" />

# Quality Of Life

**A comprehensive overhaul mod for Black Ops II Zombies on [Plutonium T6](https://plutonium.pw).**

Expanded weapon pools, legacy wonder weapons, restored survival map variants, perk adjustments, and fully configurable in-game settings.

<a href="https://github.com/DavidHiFi/T6-QoL/releases/latest">
<img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F%20DOWNLOAD%20LATEST%20RELEASE-2EA043?style=for-the-badge&labelColor=161B22" alt="Download the latest release" height="42">
</a>

<br><br>

<img src="https://img.shields.io/github/v/release/DavidHiFi/T6-QoL?style=flat-square&label=version&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/github/downloads/DavidHiFi/T6-QoL/total?style=flat-square&label=downloads&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/badge/platform-Windows-5865F2?style=flat-square&labelColor=161B22">

</div>

---

## Key Features

* **Expanded Mystery Box Arsenal:** Campaign and Multiplayer weapons added directly to the box, complete with working Pack-a-Punch functionality, camos, audio, and proper stats.
* **Classic BO1 Wonder Weapons:** Ported Wonder Weapons integrated across supported maps with balanced ammo pools, authentic visual/audio effects, and boss zombie hit logic.
* **Animated Pack-a-Punch Camo:** Applies the *ZM Dark Matter* animated camo to every Pack-a-Punched gun on **every map** — Green Run, Nuketown, Die Rise, Mob of the Dead, Buried and Origins alike. Switch it off and each map uses its exact stock Pack-a-Punch camo (Mob of the Dead's stock camo is the same material the option animates, so the switch changes nothing there). Green Run, Die Rise and Nuketown used to be impossible here, because a map's own camo tables override the mod's and those three ship tables with no animated entry; 66 weapon variants now point at 48 camo tables no retail map defines, so the mod's copy is the only one and always draws. Audited weapon by weapon across all six maps: **566 of 566** Pack-a-Punchable guns get the animated camo with the option on, and 562 of 566 get their map's stock camo with it off — the four exceptions are Origins' elemental staffs, which have no Pack-a-Punch camo in the stock game either. That audit asked only whether each gun's animated slot was **populated**; it did not check that the slot maps every surface of the gun correctly. A separate surface-level sweep in v2.11.9 found the Campaign SPAS-12's table gave all three of its surfaces the same camo layer and listed each of them twice — the gun came out black in every slot this project authored, with the option on or off — and rebuilt those nine slots to the pattern Treyarch's own two slots for that gun use, which is verified in game. **The animated camo's textures ship inside the HD Texture Pack** — nine files, named exactly as the game's own Mob of the Dead camo textures, dropped loose into `%LOCALAPPDATA%\Plutonium\storage\t6\images`. Plutonium reads that folder by name on every map, so the pack repaints the stock material wherever it is drawn; nothing in the mod's own five files carries or overrides those textures. Install the pack for the option to have any effect; without it the option shows the stock Mob of the Dead camo.
* **Restored Survival Maps:** Playable standalone Survival map variants for Die Rise (Shopping Mall, Dragon Rooftop, Sweatshop), Mob of the Dead (Cell Block), Buried (Borough), and TranZit (Diner, Power Station, Tunnel).
* **Perk & Utility Adjustments:** No perk limit by default (or set one, 1–12, from the pre-game lobby's Perk Limit row or the `perk_limit` dvar), Der Wunderfizz on every map, Bouncing Betties alongside the Claymores, and instant Pack-a-Punch that can be switched back to the stock machine.
* **In-Game Mod Menu & Customisable HUD:** Toggle mechanics, gameplay rules, hitmarkers, timers, and visual options live in-game without console commands.

---

## Expanded Arsenal & Equipment

### Ported Weapons & Wonder Weapons
* **BO1 Wonder Weapons:** the Wave Gun (Moon's Zap Gun pair, and its alt fire combines them into the Wave Gun — Treyarch's own models, animations, effects and sounds as converted for the cancelled DLC5), Thundergun, Wunderwaffe DG-2, and Winter's Howl ported with Pack-a-Punch support and proper hit logic against Brutus on Mob of the Dead — the first hit takes his helmet, the second kills. On these maps the Wave Gun pops zombies on the spot; Moon's swelling death animation needs Moon's own zombie rigs.
* **Campaign & Multiplayer Weapons:** Includes the Campaign SPAS-12 (Packs into the *SPAZ-24* with BO1 ammo balancing), Dragunov (Packs into the *D115 Disassembler*), SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50, Titus-6, and Tac-45.
* **Equipment Overhaul:** Bouncing Betties are added to the Mystery Box with corrected viewmodels and deploy animations. Both Betties and Claymores feature proximity detonation and shootable trigger logic.
* **Jet Gun Clean-Up:** Carried as a normal primary weapon that cycles with your guns instead of sitting in an equipment slot, so there is no equipment icon or hotkey prompt for it. It costs a real weapon slot like any other gun — build it with a full loadout and it takes the weapon in your hands, respecting Mule Kick. It still overheats, but it never breaks.

---

## Quality of Life & HUD Customisation

* **Game Timers & Visuals:** Game and round timers with configurable colours, a Cold War-style round counter, and hitmarkers with selectable hit, kill, crit and downed sounds.
* **FOV & Viewmodel Fixes:** A view-nudge tunable for the Ray Gun's floating left hand at high FOV (`.rayhand` in chat) — it becomes the default once the confirmed value lands.
* **Controls & Interactivity:** Native "Tap to Interact" controller support available under the standard Gamepad controls menu.
* **Custom ReShade Integration:** Bundled with an updated, tailored *Cinematic Colour Grading* ReShade preset.

---

## Installation

Install Plutonium and run it once so its folders exist, then close it.

1. [Download the latest release](https://github.com/DavidHiFi/T6-QoL/releases/latest) and unzip it anywhere.
2. Run **`Windows Install.bat`**.
3. Choose **INSTALL → The mod** and confirm.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

Arrow keys to move, **Enter** to choose, **Q** to quit. No admin rights, nothing left running, and no game file is ever touched — everything is written inside Plutonium's own folder. The installer can also fetch the optional extras: the HD texture and custom sound packs, controller icons (PlayStation 5, Nintendo Switch or Xbox One), ReShade, backups of your own files, and a full uninstaller.

### Standalone downloads

Neither needs the mod installed:

| Download | Size | What it is |
|---|---|---|
| [**HD Texture Pack**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/HD.Texture.Pack.zip) | 525 MB | 1,029 textures — 1,020 upscales plus the nine Dark Matter animated Pack-a-Punch camo textures. Unzip and drop the `images` folder into `%LOCALAPPDATA%\Plutonium\storage\t6\`. |
| [**Controller Icons**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/Controller.Icons.Pack.zip) | 184 KB | PlayStation 5, Nintendo Switch and Xbox One button prompts. Pick one of the three folders inside and copy the `.iwi` files it holds (they sit a folder or two down) into `%LOCALAPPDATA%\Plutonium\storage\t6\images\`. |

<details>
<summary><b>Install by hand (and Linux)</b></summary>

<br>

On **Linux** (Wine, Proton, Lutris, Bottles) there is no automated installer — install by hand; it works the same as any other Plutonium mod.

1. Download the release zip and open the **`Mod Files`** folder inside it.
2. Create a folder called `zm_qol` in `%LOCALAPPDATA%\Plutonium\storage\t6\mods\` *(on Linux, the same path inside your Plutonium prefix).*
3. Copy these five files into it: `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`, `mod.all.sabs`. Nothing else from that folder is needed.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

</details>

---

## Important Notices

> [!IMPORTANT]
> **Plutonium deletes ReShade every time it starts** — it clears anything it does not recognise out of its own `bin` folder. The fix ships with the installer: launch using **`Play BO2 with ReShade.bat`** and leave its window open while you play; it puts ReShade back the moment Plutonium clears it. Closing that window uninstalls nothing — it just stops watching.

> [!NOTE]
> **Cloning this repo does not give you a playable mod** — `mod.iwd` is a build output and is not tracked in git. Use the release.

> [!NOTE]
> **The newest changes are still awaiting a fresh play-through:** the animated Pack-a-Punch camo now reaching every gun on every map (the camo index the mod sends is 40 again — the engine's own lookup table maps 40 to the animated material and 44, sent since v2.10.15, to a plain pattern camo — and 66 weapon variants sit on 48 mod-private camo tables, which is what lifts the Green Run / Die Rise / Nuketown ceiling), the Thundergun, Wunderwaffe and Winter's Howl taking that animated camo on every surface (their secondary surfaces used to come out gold), the Ray Gun's Pack-a-Punch model now being Treyarch's own upgraded one on all six maps, the complete Wave Gun (the Zap Gun pair, its alt-fire combine and split, the pop, the camo and the Moon sounds), the Paralyzer's animated camo and the wider camo coverage (XM8, M27, MSMC, EOTech sight, MG08, C96, Blundergat), its real deploy and trigger sounds, the Ray Gun hand tunable, the Cold War Ray Gun skin and the Ray Gun Mark II rework in the HD Texture Pack, Nuketown's teleport destinations are all in the current build but have not been verified in game since landing. PhD Flopper's dive explosion also stopped using the six-argument call that crashed Origins on a Panzer death — it had been running that call on every dive on all five maps this mod gives PhD out on — but that one has nothing to look at: it verifies only by not crashing. **Confirmed working in game (2026-09-04):** the Campaign SPAS-12's animated Pack-a-Punch camo and its reload, pump and shell-load sounds on Origins; the Bouncing Betty detonating and being shootable (every earlier fix aimed upstream at the plant — the plant, the arm and the zombie trip had all been working, and the explosion was being cut short by the mine deleting itself mid-sequence, which also silently disabled shooting one); and the Panzer's death explosion no longer crashing Origins to desktop (stock's own code passes `radiusdamage` six arguments, and with fewer than seven the engine substitutes weapon index 255 and dereferences a null entry — reproduced twice with byte-identical crash dumps, fixed by supplying the seventh argument; the same short form appears at nine more stock call sites on these maps, in files this mod does not ship, and those have not been touched). Who's Who's pop sounds are confirmed too — the perk plays four sounds when you go down and come back, and every one of them was silent on the maps this mod adds the perk to, because the sounds only ever existed in Die Rise's own audio bank; Treyarch's own two recordings now ship with the mod under names of its own, so nothing a sound pack provides is overridden. Die Rise's bank and its weapon locker make a sound now as well — both are silent in stock, because the two aliases each of them calls live only in Green Run's and Buried's audio banks and Die Rise's own bank carries neither, so the calls named nothing; Treyarch's own recordings ship with the mod under names of its own. Anything that fails will be fixed or pulled, not left broken.

> [!NOTE]
> **Most of this mod was written by [Claude Code](https://claude.com/claude-code)**, Anthropic's AI coding agent, directed and tested in game by me across a long run of sessions. Plenty of people want nothing to do with AI-written code, which is fair — so you should know before you download rather than after.

---

<details>
<summary><b>In-Game Chat Commands Reference</b></summary>

<br>

Commands can be executed using `.`, `!`, or `/` prefix, or bound directly to key bindings. Type `.help` in-game for an up-to-date list.

```text
.help                     Show / hide the in-game command list
.give <weapon> [pap]      Give any weapon (use '.give list' to view available weapons)
.round <n> / .endround    Set or skip the current round
.god / .ghost / .fly      Toggle invincibility, noclip, or flight modes
.infammo / .infsprint     Toggle infinite ammunition and sprint
.pack / .unpack           Pack-a-Punch or unpack the currently held weapon
.giveperks / .removeperks Grant or remove player perks
.pay <player> <amount>    Transfer points to another player
.shield / .staff <elem>   Spawn shield or specific Origins elemental staff
```

</details>

---

## Credits

**Made by DavidHiFi & Synarxis.**

| Who | What |
|---|---|
| **sehteria** — *T6-ZM-Expanded* | The mod this one grew out of — BO4 Max Ammo, instant Pack-a-Punch, the high-round fix, no perk limit, animated camos, hitmarkers, the area notifier, the Cold War round HUD and secret song survival. |
| **SadSlothXL** | The Death Machine power-up — the drop, the weapon swap and its sounds. |
| **Logo2K** — [Zombies Declassified](https://github.com/Logo-2K/zombies-declassified) | The native T6 Wave Gun package — Treyarch's DLC5 models, animations, effects, weapon defs, sounds and script — read out of its Moon zone. |
| *ZM Dark Matter* (Plutonium forums) | The animated Pack-a-Punch camo's textures. |
| **Jbleezy** — [BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) | The extra Survival locations, and the Bouncing Betty's carry animations. |
| **5and5** — [BO2-Remix](https://github.com/5and5/BO2-Remix) | The Die Rise weapon changes — the Sliquifier's pre-nerf behaviour and the Semtex wall buy. |
| **Fraaagaaa** — [Strat Tester](https://github.com/Fraaagaaa/Strat-Tester-BO2) | Every destination in the teleport list, except Nuketown's three, which are the map's own player respawn points. |
| **B2ORG** — [T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH)<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The basis for most of the patches — rebuilt against the game's own scripts, not copied wholesale. |

Built on [**Plutonium**](https://plutonium.pw), with **OpenAssetTools** and **xensik**'s **gsc-tool**. The optional ReShade install ships unmodified work by **crosire** ([ReShade](https://reshade.me)), **Barbatos Bachiko**, **Alex Tuduran**, **Marot Satil** and the **GShade** project, **Ioxa**, **Lord of Lunacy**, **prod80**, and **NVIDIA**.

> Missing or wrong credit? Open an issue and it will be fixed.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
