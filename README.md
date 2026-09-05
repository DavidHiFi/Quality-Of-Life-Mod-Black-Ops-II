<div align="center">

<img width="3840" height="2160" alt="image" src="https://github.com/user-attachments/assets/32a1cfbd-7ece-4a91-9690-82691bed24b1" />

# Quality Of Life

**An overhaul mod for Black Ops II Zombies on [Plutonium T6](https://plutonium.pw).**

More guns in the box, the BO1 wonder weapons, the cut Survival maps, and a settings menu you can actually reach in game.

<a href="https://github.com/DavidHiFi/T6-QoL/releases/latest">
<img src="https://img.shields.io/badge/%E2%AC%87%EF%B8%8F%20DOWNLOAD%20LATEST%20RELEASE-2EA043?style=for-the-badge&labelColor=161B22" alt="Download the latest release" height="42">
</a>

<br><br>

<img src="https://img.shields.io/github/v/release/DavidHiFi/T6-QoL?style=flat-square&label=version&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/github/downloads/DavidHiFi/T6-QoL/total?style=flat-square&label=downloads&color=5865F2&labelColor=161B22">
<img src="https://img.shields.io/badge/platform-Windows-5865F2?style=flat-square&labelColor=161B22">

</div>

---

## Weapons

**Campaign and Multiplayer guns in the box.** SWAT-556, FAL OSW, Mk 48, QBB LSW, MP7, Vector K10, MSMC, Peacekeeper, Crossbow, XPR-50, Titus-6 and Tac-45, all with working Pack-a-Punch, camos and stats.

**Campaign SPAS-12 and Dragunov.** The SPAS packs into the *SPAZ-24* with BO1 ammo balancing; the Dragunov becomes the *D115 Disassembler*.

**BO1 wonder weapons.** The Wave Gun, Thundergun, Wunderwaffe DG-2 and Winter's Howl, each with Pack-a-Punch support. On Mob of the Dead they handle Brutus properly — first hit takes the helmet, second kills.

**Bouncing Betties.** Added to the box with proper viewmodels and deploy animations. They take the Claymore's place rather than sitting beside it, they answer on the Claymore's button, and Max Ammo refills them.

**Jet Gun clean-up.** It's carried as a normal primary that cycles with your other guns instead of living in an equipment slot, so it costs a real weapon slot and respects Mule Kick. Still overheats, never breaks.

---

## Maps and perks

**Cut Survival maps.** Eight standalone Survival starts: Diner, Power Station and Tunnel on Green Run; Shopping Mall, Dragon Rooftop and Sweatshop on Die Rise; Cell Block on Mob of the Dead; Borough on Buried.

**Der Wunderfizz everywhere.** The random perk machine is available on every map, not just Origins.

**No perk limit.** Carry as many as you like by default, or set a cap of 1–12 from the pre-game lobby.

**Instant Pack-a-Punch.** No upgrade wait. Switch it back to the stock machine if you prefer.

**Bonfire Sale.** BO1's Pack-a-Punch power-up, from *Five*. Pick it up and Pack-a-Punch costs 1,000 points instead of 5,000 for thirty seconds. Part of the **Custom Power-Ups** option, on every map except Mob of the Dead and Buried.

---

## Presentation

**Animated Pack-a-Punch camo.** Every Pack-a-Punched gun gets the *ZM Dark Matter* animated camo on all six maps; switch it off and each map uses its own stock camo. The textures ship in the [HD Texture Pack](#standalone-downloads), so install that for the option to do anything.

**Timers and counters.** Game and round timers with configurable colours, plus a Cold War style round counter.

**Hitmarkers.** Selectable hit, kill, crit and downed sounds, or off.

**In-game menu.** Mechanics, gameplay rules, HUD and audio options are all toggleable in game — no console commands. That includes a **VOICE LINES** switch for your character's spoken lines.

**Extras.** Native "Tap to Interact" controller support under the standard Gamepad menu, and a tailored *Cinematic Colour Grading* ReShade preset.

---

## Installation

Install Plutonium and run it once so its folders exist, then close it.

1. [Download the latest release](https://github.com/DavidHiFi/T6-QoL/releases/latest) and unzip it anywhere.
2. Run **`Windows Install.bat`**.
3. Choose **INSTALL → The mod** and confirm.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

Arrow keys to move, **Enter** to choose, **Q** to quit. No admin rights, nothing left running, and no game file is touched — everything goes inside Plutonium's own folder. The installer can also fetch the optional extras: the HD texture and custom sound packs, controller icons, ReShade, backups, and a full uninstaller.

### Standalone downloads

Neither needs the mod installed:

| Download | Size | What it is |
|---|---|---|
| [**HD Texture Pack**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/HD.Texture.Pack.zip) | 525 MB | 1,029 textures — 1,020 upscales plus the nine animated Pack-a-Punch camo textures. Unzip and drop the `images` folder into `%LOCALAPPDATA%\Plutonium\storage\t6\`. |
| [**Controller Icons**](https://github.com/DavidHiFi/T6-QoL/releases/latest/download/Controller.Icons.Pack.zip) | 184 KB | PlayStation 5, Nintendo Switch and Xbox One button prompts. Pick one of the three folders inside and copy the `.iwi` files into `%LOCALAPPDATA%\Plutonium\storage\t6\images\`. |

<details>
<summary><b>Install by hand (and Linux)</b></summary>

<br>

On **Linux** (Wine, Proton, Lutris, Bottles) there is no automated installer — install by hand; it works like any other Plutonium mod.

1. Download the release zip and open the **`Mod Files`** folder inside it.
2. Create a folder called `zm_qol` in `%LOCALAPPDATA%\Plutonium\storage\t6\mods\` *(on Linux, the same path inside your Plutonium prefix).*
3. Copy these five files into it: `mod.ff`, `mod.iwd`, `mod.json`, `mod.all.sabl`, `mod.all.sabs`. Nothing else is needed.
4. Launch Plutonium T6 → **Zombies → Mods → Quality Of Life**.

</details>

---

## Notes

> [!IMPORTANT]
> **Plutonium deletes ReShade every time it starts** — it clears anything it doesn't recognise out of its own `bin` folder. Launch with **`Play BO2 with ReShade.bat`** and leave its window open while you play; it puts ReShade back each time. Closing the window uninstalls nothing.

> [!NOTE]
> **Still in beta.** Some of the newest features haven't had a full play-through yet. Anything that turns out broken gets fixed or pulled.

> [!NOTE]
> **Cloning the repo does not give you a playable mod** — `mod.iwd` is a build output and isn't tracked in git. Use the release.

---

<details>
<summary><b>In-game chat commands</b></summary>

<br>

Use a `.`, `!` or `/` prefix, or bind them to keys. Type `.help` in game for the current list.

```text
.help                     Show / hide the in-game command list
.give <weapon> [pap]      Give any weapon ('.give list' shows what's available)
.round <n> / .endround    Set or skip the current round
.god / .ghost / .fly      Invincibility, noclip, flight
.infammo / .infsprint     Infinite ammo and sprint
.pack / .unpack           Pack-a-Punch or unpack the held weapon
.giveperks / .removeperks Grant or remove perks
.pay <player> <amount>    Send points to another player
.shield / .staff <elem>   Spawn a shield or an Origins elemental staff
```

</details>

---

## Credits

**Made by DavidHiFi & Synarxis.**

| Who | What |
|---|---|
| **sehteria** — *T6-ZM-Expanded* | The mod this one grew out of — BO4 Max Ammo, instant Pack-a-Punch, the high-round fix, no perk limit, animated camos, hitmarkers, the area notifier, the Cold War round HUD and secret song survival. |
| **SadSlothXL** | The Death Machine power-up — the drop, the weapon swap and its sounds. |
| **Logo2K** — [Zombies Declassified](https://github.com/Logo-2K/zombies-declassified) | The native T6 Wave Gun package — Treyarch's DLC5 models, animations, effects, weapon defs, sounds and script. |
| *ZM Dark Matter* (Plutonium forums) | The animated Pack-a-Punch camo textures. |
| **Jbleezy** — [BO2-Reimagined](https://github.com/Jbleezy/BO2-Reimagined) | The extra Survival locations and the Bouncing Betty carry animations. |
| **5and5** — [BO2-Remix](https://github.com/5and5/BO2-Remix) | The Die Rise weapon changes — the Sliquifier's pre-nerf behaviour and the Semtex wall buy. |
| **Fraaagaaa** — [Strat Tester](https://github.com/Fraaagaaa/Strat-Tester-BO2) | Every destination in the teleport list except Nuketown's three, which are the map's own respawn points. |
| **B2ORG** — [T6-B2OP-PATCH](https://github.com/B2ORG/T6-B2OP-PATCH)<br><sub>built with **Astrox** and **NoMoleMan**</sub> | The basis for most of the patches — rebuilt against the game's own scripts rather than copied wholesale. |

Built on [**Plutonium**](https://plutonium.pw), with **OpenAssetTools** and **xensik**'s **gsc-tool**. The optional ReShade install ships unmodified work by **crosire** ([ReShade](https://reshade.me)), **Barbatos Bachiko**, **Alex Tuduran**, **Marot Satil** and the **GShade** project, **Ioxa**, **Lord of Lunacy**, **prod80**, and **NVIDIA**.

> Missing or wrong credit? Open an issue and it'll be fixed.

<div align="center">
<br>
<sub>Not affiliated with Activision or Treyarch. Requires a legitimate copy of Black Ops II and <a href="https://plutonium.pw">Plutonium</a>.</sub>
</div>
