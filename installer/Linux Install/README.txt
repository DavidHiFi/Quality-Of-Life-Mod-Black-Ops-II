Quality Of Life - Linux install
===============================

Plutonium is a Windows program, so on Linux it runs inside a Wine prefix
(Wine, Proton, Lutris or Bottles). This script installs the mod into that
prefix. It never touches your game files.

Run it from a terminal, in this folder:

    bash "install-quality-of-life.sh"

It looks for Plutonium on its own, in the usual places: $WINEPREFIX, ~/.wine,
~/Games/plutonium, Lutris prefixes, Bottles bottles, and Steam's compatdata
folders. If it cannot find yours, point it at the prefix:

    WINEPREFIX=/path/to/your/prefix bash "install-quality-of-life.sh"

Move with the arrow keys, choose with ENTER, quit with Q.

What it can do
--------------
  install or update the mod          keeping your menu settings, or wiping them
  install the HD texture pack        with a backup of what you had first
  install the custom sound pack      same
  install ReShade + the BO2 preset   see the note below, and it now brings
                                     the FULL shader collection, not only the
                                     shaders the preset happens to use
  start the ReShade watchdog only    for when you launch Plutonium yourself -
                                     see the watchdog note below
  install PS5 controller icons       swaps the Xbox button prompts for DualSense
                                     ones, with a backup of what you had first
  remove any of those again          putting your own files back
  check GitHub for a newer release

One extra step for ReShade
--------------------------
On Windows, Wine is not involved and ReShade just loads. On Linux you have to
tell Wine to use it, by launching Plutonium with:

    WINEDLLOVERRIDES="dxgi=n,b" <your usual launch command>

or by adding "dxgi" as a native DLL override in Lutris, Bottles or winecfg.
Without that, the files are installed but nothing happens in game.

Keeping ReShade working: the watchdog
--------------------------------------
Plutonium clears any file out of its own "bin" folder it does not recognise,
every time it starts - dxgi.dll and the presets are exactly that, so
installing ReShade once does not survive your next Plutonium launch.

reshade-watchdog.sh, next to this script, watches for Plutonium and puts
ReShade straight back the moment it clears it out. Run it yourself:

    bash "reshade-watchdog.sh"

and leave it running for as long as you're playing - or just say yes when
the ReShade install offers to start it for you (it opens in its own
terminal if one can be found - gnome-terminal, konsole, xfce4-terminal,
xterm - otherwise it runs in the background and tells you where its log is).
Closing it doesn't uninstall anything; it just stops watching.

If something needs installing
-----------------------------
The script uses whatever you already have. It needs bash, and for downloads
either curl or wget, plus unzip (or bsdtar) to open a downloaded pack. Copying
uses rsync if you have it and plain cp if you do not.

A log of everything it did is written to installer.log next to this file.
