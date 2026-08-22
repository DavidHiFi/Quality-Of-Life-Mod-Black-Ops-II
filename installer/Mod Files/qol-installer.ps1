<#
================================================================================
  Quality Of Life (zm_qol) - installer for Plutonium T6 (Black Ops II)

  Launched by "Install Quality Of Life.bat". Windows PowerShell 5.1, which every
  Windows 10/11 machine already has - nothing to install.

  Nothing here touches a game file. Everything is written under
  %LOCALAPPDATA%\Plutonium, and every destructive step asks first.

  Hidden switches, for testing only:
    -DryRun              print what would happen, write nothing
    -Action <name>       run one action headlessly (no menu)
    -Choice <n>          which option that action should take (0 = first)
    -Extra <kind>        images | zone | reshade | mod, for -Action backup/restore
    -Root <path>         pretend Plutonium lives here
================================================================================
#>

[CmdletBinding()]
param(
    [switch] $DryRun,
    [string] $Action,
    [int]    $Choice = 0,
    [string] $Extra,
    [string] $Root
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

# ------------------------------------------------------------------ context --
$REPO    = 'DavidHiFi/zm_qol'
$MODID   = 'zm_qol'
$MODNAME = 'Quality Of Life'
$MODFILES = @('mod.ff','mod.iwd','mod.json','mod.all.sabl','mod.all.sabs')
$SOUNDFILES = @('cmn_root.all.sabl','zmb_code_post_gfx.all.sabs','zmb_common.english.sabs')

$HERE = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($Root) { $PLUTO = $Root } else { $PLUTO = Join-Path $env:LOCALAPPDATA 'Plutonium' }
$T6       = Join-Path $PLUTO 'storage\t6'
$MODDIR   = Join-Path $T6 "mods\$MODID"
$IMGDIR   = Join-Path $T6 'images'
$ZONEDIR  = Join-Path $T6 'zone'
$CFGDIR   = Join-Path $T6 "players\mods\$MODID"
$BINDIR   = Join-Path $PLUTO 'bin'
$STATE    = Join-Path $T6 '_zm_qol_installer'
# Backups sit in plain sight at storage\t6\backups\<thing>\, not buried in the
# installer's own state folder, because they are the PLAYER'S files - their
# textures, their sounds, their ReShade - and they must be findable and
# copyable by hand without this script.
$BACKUPS    = Join-Path $T6 'backups'
$OLDBACKUPS = Join-Path $STATE 'backups'
$LOGFILE  = Join-Path $HERE 'installer.log'

$script:Log = New-Object System.Collections.Generic.List[string]
$script:Headless = [bool]$Action

# ------------------------------------------------------------------- colours -
$C = @{
    Frame  = 'DarkCyan'
    Title  = 'Cyan'
    Dim    = 'DarkGray'
    Text   = 'Gray'
    Pick   = 'White'
    On     = 'Green'
    Off    = 'DarkGray'
    Warn   = 'Yellow'
    Bad    = 'Red'
    Good   = 'Green'
}

function Write-Log {
    param([string] $Text, [string] $Level = 'info')
    $line = '{0}  {1,-5}  {2}' -f (Get-Date -Format 'HH:mm:ss'), $Level, $Text
    $script:Log.Add($line) | Out-Null
    try { Add-Content -LiteralPath $LOGFILE -Value $line -Encoding UTF8 } catch { }
}

function Say {
    param([string] $Text, [string] $Colour = $C.Text, [switch] $NoLog)
    # A caller that passes an undefined colour must never be able to abort the
    # install - the message just comes out in the default colour instead. See
    # the note in Set-ReShadeFont for the $C/$c shadowing bug that made this
    # necessary; the shadowing is fixed, but nothing here is worth a crash.
    if ([string]::IsNullOrWhiteSpace($Colour)) { $Colour = 'Gray' }
    Write-Host ('     ' + $Text) -ForegroundColor $Colour
    if (-not $NoLog) { Write-Log $Text }
}

# --------------------------------------------------------------------- chrome -
# ---------------------------------------------------------------------------
#  $script:Quiet is set only while ALL-IN-ONE is running four installs back to
#  back. It turns the screen into a transcript: no clear between steps, and no
#  "press any key" after each one, so the four results stay on screen together
#  and there is a single pause at the end instead of four.
# ---------------------------------------------------------------------------
$script:Quiet = $false

<#
  🛑 THE REST OF THE FLICKER, MEASURED - v2.0.5.

  v2.0.1 stopped Show-Menu clearing the screen on every keypress, but only when
  the whole frame fits inside the window: `if ($frameHeight -lt WindowHeight)`.
  The MAIN menu is exactly 30 lines tall -
        6 header + 12 items + (4 sections x 2) + 3 tail + 1 spare = 30
  - and a default Windows console is exactly 30 rows. `30 -lt 30` is FALSE, so
  the main menu has been on the OLD full-redraw path the whole time, clearing
  and repainting on every arrow key. That is the flash the user still sees, and
  it is why it looks worst on the first screen. Adding the ALL-IN-ONE row would
  have made it 31 and no better.

  So the window is grown to fit before the decision is taken. Nothing is
  reformatted and no row is removed - the frame the user sees is unchanged.
  If the console refuses to resize (a fixed-size host, or already at the
  monitor's limit) the old path still works exactly as it did.
#>
function Fit-Console {
    param([int] $Rows)
    if ($script:Headless -or $script:NoKeys) { return $false }
    try {
        if ([Console]::WindowHeight -ge $Rows) { return $true }
        $want = $Rows
        $max  = [Console]::LargestWindowHeight
        if ($max -gt 0 -and $want -gt $max) { $want = $max }
        # The buffer must be at least as tall as the window or the set throws.
        if ([Console]::BufferHeight -lt $want) { [Console]::BufferHeight = $want }
        [Console]::WindowHeight = $want
        return ([Console]::WindowHeight -ge $Rows)
    } catch { return $false }
}

function Draw-Header {
    param([string] $Sub)
    if (-not $script:Headless -and -not $script:Quiet) { Clear-Host }
    Write-Host ''
    Write-Host '   ╔══════════════════════════════════════════════════════════════════╗' -ForegroundColor $C.Frame
    Write-Host '   ║' -ForegroundColor $C.Frame -NoNewline
    Write-Host ('   QUALITY OF LIFE'.PadRight(66)) -ForegroundColor $C.Title -NoNewline
    Write-Host '║' -ForegroundColor $C.Frame
    Write-Host '   ║' -ForegroundColor $C.Frame -NoNewline
    $s = '   ' + $Sub
    Write-Host ($s.PadRight(66)) -ForegroundColor $C.Dim -NoNewline
    Write-Host '║' -ForegroundColor $C.Frame
    Write-Host '   ╚══════════════════════════════════════════════════════════════════╝' -ForegroundColor $C.Frame
    Write-Host ''
}

function Draw-Rule {
    Write-Host '   ────────────────────────────────────────────────────────────────────' -ForegroundColor $C.Frame
}


<#
  One menu, driven by the arrow keys.
  Items: @{ Label; Status; StatusColour; Section; Key; Disabled }
  Returns the chosen item, or $null if the user backed out.

  🛑 THE DRAWING WAS REWRITTEN IN v2.1.1, AND THE OLD APPROACH IS THE BUG.
  User screenshot, 2026-08-21: every section heading had its own first row
  printed over the top of it - "INSTALLTHING - the whole package",
  "REMOVEve the HD textures", "MOREeck for a newer version". The overlay starts
  at column 10, which is exactly the width of "   INSTALL", so the row was being
  written onto the heading's line instead of the one below it.

  The cause is the design, not one off-by-one: v2.0.1 painted the frame once and
  then rewrote only the item rows in place, from a remembered row number
  ($itemTop) captured on the first paint. Every one of those remembered numbers
  is a BUFFER row, and anything that scrolls the buffer - a newline emitted on
  the last line, a resize, a console host reflowing on startup - silently shifts
  the whole block while the remembered number stays put. There is no way to make
  that safe by adjusting an offset.

  🌟 WHAT IT DOES NOW: the whole frame is rebuilt as a list of lines every time,
  and each line is drawn at an ABSOLUTE position with no newline ever emitted -
  SetCursorPosition( 0, top + i ) then the segments, then spaces out to the
  window width. Three properties fall out of that, and together they are the fix:
    * nothing can scroll, because no newline is ever written;
    * every line is padded to full width, so no remnant of a previous frame can
      survive underneath;
    * a line always lands where it was computed to land, because it is placed
      rather than flowed.
  Redrawing all ~30 lines per keypress is far cheaper than it sounds and there is
  no clear between frames, so there is nothing to flicker either.

  It falls back to a plain sequential print whenever positioning cannot be
  trusted: no real console, input redirected, or a frame taller than the window.
#>
function Show-Menu {
    param(
        [string] $Sub,
        [array]  $Items,
        [string] $Footer = '   ↑ ↓  move      ENTER  choose      ESC  back',
        [string[]] $Intro = @()
    )

    #  🛑 HEADLESS MEANS NO MENUS AT ALL. -Action drives the installer from the
    #  command line and every Act-* takes a -Pick for exactly that, but a couple
    #  of them fall through to a submenu when a pick does not resolve. Reaching
    #  here with a redirected stdin used to hang: ReadKey throws, NoKeys is set,
    #  the loop retries with Read-Host, and NonInteractive refuses that forever.
    #  Backing straight out is both the correct answer and the safe one.
    if ($script:Headless) { return $null }

    $pickable = @()
    for ($i = 0; $i -lt $Items.Count; $i++) { if (-not $Items[$i].Disabled) { $pickable += $i } }
    if ($pickable.Count -eq 0) { return $null }
    $cur = $pickable[0]

    #  Builds the ENTIRE frame, top to bottom, for the current selection.
    #  Rebuilt per keypress so there is only ever one description of the screen.
    function Build-Frame {
        param([int] $Sel, [int] $Width)
        $L = @()
        $inner = 66

        $L += ,@( @{ t = ''; c = $C.Text } )
        $L += ,@( @{ t = '   ╔' + ('═' * $inner) + '╗'; c = $C.Frame } )
        $L += ,@( @{ t = '   ║'; c = $C.Frame }, @{ t = ('   QUALITY OF LIFE'.PadRight($inner)); c = $C.Title }, @{ t = '║'; c = $C.Frame } )
        $s = '   ' + $Sub
        if ($s.Length -gt $inner) { $s = $s.Substring(0, $inner) }
        $L += ,@( @{ t = '   ║'; c = $C.Frame }, @{ t = $s.PadRight($inner); c = $C.Dim }, @{ t = '║'; c = $C.Frame } )
        $L += ,@( @{ t = '   ╚' + ('═' * $inner) + '╝'; c = $C.Frame } )
        $L += ,@( @{ t = ''; c = $C.Text } )

        foreach ($line in $Intro) {
            if ($line -eq '')                 { $L += ,@( @{ t = ''; c = $C.Text } ) }
            elseif ($line.StartsWith('!'))    { $L += ,@( @{ t = '   ' + $line.Substring(1); c = $C.Warn } ) }
            elseif ($line.StartsWith('~'))    { $L += ,@( @{ t = '   ' + $line.Substring(1); c = $C.Dim } ) }
            else                              { $L += ,@( @{ t = '   ' + $line; c = $C.Text } ) }
        }
        if ($Intro.Count -gt 0) { $L += ,@( @{ t = ''; c = $C.Text } ) }

        $lastSection = $null
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $it = $Items[$i]
            if ($it.Section -and $it.Section -ne $lastSection) {
                $L += ,@( @{ t = ''; c = $C.Text } )
                $L += ,@( @{ t = '   ' + $it.Section; c = $C.Dim } )
                $lastSection = $it.Section
            }

            $marker = '     '
            if ($i -eq $Sel) { $marker = '   ❯ ' }
            $label = $it.Label.PadRight(38)
            $status = ''
            if ($it.Status) { $status = [string]$it.Status }
            $colour = $C.Text
            if ($it.Disabled) { $colour = $C.Off }
            if ($i -eq $Sel)  { $colour = $C.Pick }
            $sc = $C.Dim
            if ($it.StatusColour) { $sc = $it.StatusColour }

            # A row must never wrap: a wrapped row is two rows, and every line
            # below it would then be drawn one place too high.
            $room = ($Width - 1) - $marker.Length - $label.Length
            if ($room -lt 0) { $room = 0 }
            if ($status.Length -gt $room) {
                if ($room -ge 1) { $status = $status.Substring(0, $room - 1) + '…' } else { $status = '' }
            }
            $L += ,@( @{ t = $marker; c = $C.Title }, @{ t = $label; c = $colour }, @{ t = $status; c = $sc } )
        }

        $L += ,@( @{ t = ''; c = $C.Text } )
        $L += ,@( @{ t = '   ' + ('─' * 68); c = $C.Frame } )
        $L += ,@( @{ t = $Footer; c = $C.Dim } )
        return ,$L
    }

    $cursorWas = $true
    try { $cursorWas = [Console]::CursorVisible } catch { }

    try {
    $placed  = $false     # has the frame been given a home row yet
    $top     = 0
    $drawnW  = 0
    $drawnH  = 0
    $lastLen = 0

    while ($true) {
        $w = 100; $h = 40
        try { $w = [Console]::WindowWidth; $h = [Console]::WindowHeight } catch { }

        $frame = Build-Frame $cur $w

        # Grow the window to fit before deciding anything, so a frame one or two
        # rows too tall does not fall back to a worse drawing mode.
        [void](Fit-Console ($frame.Count + 2))
        try { $h = [Console]::WindowHeight } catch { }

        $canPlace = (-not $script:Headless) -and (-not $script:NoKeys) -and ($frame.Count -lt $h)

        if (-not $canPlace) {
            # --- plain sequential fallback -----------------------------------
            if (-not $script:Headless) { Clear-Host }
            foreach ($line in $frame) {
                foreach ($seg in $line) { Write-Host $seg.t -ForegroundColor $seg.c -NoNewline }
                Write-Host ''
            }
            if ($script:NoKeys) {
                Write-Host '   Type the number of what you want, then ENTER. 0 to go back.' -ForegroundColor $C.Dim
                $typed = Read-Host '   Number'
                if ($typed -eq '0' -or $typed -eq '') { return $null }
                $n = 0
                if ([int]::TryParse($typed, [ref]$n)) {
                    $n = $n - 1
                    if ($n -ge 0 -and $n -lt $pickable.Count) { return $Items[$pickable[$n]] }
                }
                continue
            }
        }
        else {
            # A resize, or a frame that changed height, invalidates the home row.
            if ($placed -and ($w -ne $drawnW -or $h -ne $drawnH -or $frame.Count -ne $lastLen)) { $placed = $false }

            if (-not $placed) {
                Clear-Host                     # cursor home, buffer clean
                try { $top = [Console]::CursorTop } catch { $top = 0 }
                $placed  = $true
                $drawnW  = $w
                $drawnH  = $h
                $lastLen = $frame.Count
                try { [Console]::CursorVisible = $false } catch { }
            }

            #  🛑 NO NEWLINE IS EVER WRITTEN. Every line is placed absolutely and
            #  padded to the window width, so nothing scrolls and nothing of the
            #  previous frame can show through.
            for ($i = 0; $i -lt $frame.Count; $i++) {
                $row = $top + $i
                if ($row -ge ($top + $h)) { break }
                try { [Console]::SetCursorPosition(0, $row) } catch { $placed = $false; break }
                $used = 0
                foreach ($seg in $frame[$i]) {
                    if ($seg.t -eq '') { continue }
                    Write-Host $seg.t -ForegroundColor $seg.c -NoNewline
                    $used += $seg.t.Length
                }
                if ($used -lt ($w - 1)) { Write-Host (' ' * (($w - 1) - $used)) -NoNewline }
            }
            if (-not $placed) { continue }
        }

        try { $key = [Console]::ReadKey($true) }
        catch { $script:NoKeys = $true; $placed = $false; continue }
        switch ($key.Key) {
            'UpArrow' {
                $p = [array]::IndexOf($pickable, $cur)
                if ($p -le 0) { $cur = $pickable[$pickable.Count - 1] } else { $cur = $pickable[$p - 1] }
            }
            'DownArrow' {
                $p = [array]::IndexOf($pickable, $cur)
                if ($p -ge $pickable.Count - 1) { $cur = $pickable[0] } else { $cur = $pickable[$p + 1] }
            }
            'Home'   { $cur = $pickable[0] }
            'End'    { $cur = $pickable[$pickable.Count - 1] }
            'Enter'  { return $Items[$cur] }
            'Spacebar' { return $Items[$cur] }
            'Escape' { return $null }
            'Q'      { return $null }
            default {
                $ch = $key.KeyChar
                if ($ch -match '[1-9]') {
                    $n = [int]::Parse($ch) - 1
                    if ($n -lt $pickable.Count) { return $Items[$pickable[$n]] }
                }
            }
        }
    }
    }
    finally {
        try { [Console]::CursorVisible = $cursorWas } catch { }
        #  Park the cursor under the frame so whatever prints next does not land
        #  on top of it.
        try { if ($placed) { [Console]::SetCursorPosition(0, [Math]::Min($top + $lastLen, [Console]::BufferHeight - 1)) } } catch { }
    }
}

function Pause-Key {
    param([string] $Text = '   Press any key to go back')
    Write-Host ''
    Draw-Rule
    Write-Host $Text -ForegroundColor $C.Dim
    if ($script:Headless -or $script:Quiet) { return }
    if ($script:NoKeys) { [void](Read-Host '   ENTER'); return }
    try { [void][Console]::ReadKey($true) } catch { $script:NoKeys = $true; [void](Read-Host '   ENTER') }
}

# -------------------------------------------------------------- discovery ----
function Find-ModSource {
    foreach ($p in @((Join-Path $HERE $MODID), $HERE, (Split-Path -Parent $HERE), (Split-Path -Parent (Split-Path -Parent $HERE)))) {
        if ($p -and (Test-Path (Join-Path $p 'mod.json'))) { return (Resolve-Path $p).Path }
    }
    return $null
}

function Find-Payload {
    param([string] $Name)
    $parent = Split-Path -Parent $HERE
    $gran   = Split-Path -Parent $parent
    $cand = @(
        (Join-Path $HERE       $Name),
        (Join-Path $HERE       "Optional\$Name"),
        (Join-Path $HERE       "Optionals\$Name"),
        (Join-Path $parent     "Optional\$Name"),
        (Join-Path $parent     "Optionals\$Name"),
        (Join-Path $gran       "Optional\$Name"),
        (Join-Path $gran       "Optionals\$Name")
    )
    foreach ($p in $cand) {
        if (Test-Path $p) {
            if ((Get-ChildItem -LiteralPath $p -Force -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
                return (Resolve-Path $p).Path
            }
        }
    }
    return $null
}

function Get-ModVersion {
    param([string] $JsonPath)
    if (-not (Test-Path $JsonPath)) { return $null }
    try {
        $raw = Get-Content -LiteralPath $JsonPath -Raw
        $m = [regex]::Match($raw, '"version"\s*:\s*"([^"]+)"')
        if (-not $m.Success) { return $null }
        # Plutonium colour-codes these strings: "name" starts ^5, "version"
        # starts ^3. Strip the caret AND the colour digit it carries - not just
        # the caret, and never by special-casing one version number.
        $v = $m.Groups[1].Value
        if ($v -match '^\^\d') { $v = $v.Substring(2) }
        return $v
    } catch { return $null }
}

function Read-Manifest {
    param([string] $Name)
    $f = Join-Path $STATE "installed-$Name.txt"
    if (-not (Test-Path $f)) { return @() }
    return @(Get-Content -LiteralPath $f | Where-Object { $_ -ne '' })
}

function Write-Manifest {
    param([string] $Name, [string[]] $Files)
    if ($DryRun) { return }
    if (-not (Test-Path $STATE)) { New-Item -ItemType Directory -Force -Path $STATE | Out-Null }
    Set-Content -LiteralPath (Join-Path $STATE "installed-$Name.txt") -Value $Files -Encoding UTF8
}

function Format-Size {
    param([long] $Bytes)
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N0} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N0} KB' -f ($Bytes / 1KB)) }
    return ('{0:N0} bytes' -f $Bytes)
}

# ------------------------------------------------------------------ backups --
#  Four things can be backed up, each into its own subfolder of
#  storage\t6\backups\. A "part" is one folder, or a named handful of loose
#  files, and a thing can be made of more than one part - the mod is its files
#  plus your saved menu settings, ReShade is three loose files plus its shader
#  library. Each part lands in its own named subfolder so a restore knows
#  exactly where to put it back and a human can read the tree.
#
#  🛑 reshade deliberately does NOT back up the whole bin folder. That folder is
#  Plutonium's own program directory; the only things in it this installer ever
#  writes are the three files and the one folder listed here, so they are the
#  only things it has any business copying or putting back.
#  v2.2.0 - the 20 filenames the PS5 icon pack replaces, read from the payload
#  itself so this list can never drift from what is actually overwritten. Empty
#  if the pack is not in the package, which simply means that backup set has
#  nothing to copy.
$DSFILES = @()
$dsSrcForList = Find-Payload 'Dualsense IconsImages'
if (-not $dsSrcForList) { $dsSrcForList = Find-Payload 'Dualsense Icons' }
if ($dsSrcForList) { $DSFILES = @(Get-ChildItem -LiteralPath $dsSrcForList -File -Recurse | ForEach-Object { $_.Name }) }

$BACKUPSETS = [ordered]@{
    images  = @{ Title = 'your textures';      Parts = @( @{ Sub='images';          Path=$IMGDIR;  Type='folder' } ) }
    zone    = @{ Title = 'your sounds';        Parts = @( @{ Sub='zone';            Path=$ZONEDIR; Type='folder' } ) }
    #  v2.2.0 - the PS5 icon set backs up ONLY the 20 filenames it will replace,
    #  not the whole images folder: the HD texture pack already backs that up as
    #  a whole and two folder-wide copies of the same 1GB would be absurd. The
    #  list is read from the payload itself at load time, so it can never drift
    #  from what actually gets overwritten.
    dualsense = @{ Title = 'your controller icons'; Parts = @( @{ Sub='dualsense'; Path=$IMGDIR; Type='files'; Items=$DSFILES } ) }
    reshade = @{ Title = 'your ReShade setup'; Parts = @(
                    @{ Sub='bin';             Path=$BINDIR; Type='files'; Items=@('ReShade.ini','BO2.ini','dxgi.dll') },
                    @{ Sub='reshade-shaders'; Path=(Join-Path $BINDIR 'reshade-shaders'); Type='folder' } ) }
    mod     = @{ Title = 'the mod';            Parts = @(
                    @{ Sub='files';           Path=$MODDIR; Type='folder' },
                    @{ Sub='settings';        Path=$CFGDIR; Type='folder' } ) }
}

function Get-BackupPart {
    param($Part)
    if ($Part.Type -eq 'folder') {
        return @(Get-ChildItem -LiteralPath $Part.Path -File -Recurse -ErrorAction SilentlyContinue)
    }
    $found = @()
    foreach ($n in $Part.Items) {
        $p = Join-Path $Part.Path $n
        if (Test-Path -LiteralPath $p) { $found += (Get-Item -LiteralPath $p) }
    }
    return $found
}

function Measure-BackupSource {
    param([string] $Kind)
    $n = 0; $b = [long]0
    foreach ($part in $BACKUPSETS[$Kind].Parts) {
        foreach ($f in (Get-BackupPart $part)) { $n++; $b += $f.Length }
    }
    return @{ Count = $n; Bytes = $b }
}

function Has-Backup { param([string] $Kind) return (Test-Path (Join-Path $BACKUPS $Kind)) }

function Get-BackupInfo {
    param([string] $Kind)
    $dir = Join-Path $BACKUPS $Kind
    if (-not (Test-Path $dir)) { return $null }
    $files = @(Get-ChildItem -LiteralPath $dir -File -Recurse -ErrorAction SilentlyContinue)
    $when = (Get-Item $dir).LastWriteTime
    $b = [long]0
    foreach ($f in $files) { $b += $f.Length }
    return @{ Count = $files.Count; Bytes = $b; When = $when }
}

function Copy-Tree {
    param([string] $From, [string] $To)
    if (-not (Test-Path $To)) { New-Item -ItemType Directory -Force -Path $To | Out-Null }
    $null = robocopy $From $To /E /NFL /NDL /NJH /NJS /NP
    # robocopy: 0-7 are success codes, 8 and up are real failures.
    return ($LASTEXITCODE -lt 8)
}

<#
  Back up one thing. Returns $false only on a real copy failure - "nothing
  there to back up" and "you already have one" are both fine outcomes.
  $Replace overwrites an existing backup; without it the OLDER backup is kept,
  because the older one is the one taken before this installer first touched
  anything, and that is the one worth having.
#>
function Backup-Thing {
    param([string] $Kind, [switch] $Replace)
    $set  = $BACKUPSETS[$Kind]
    $dest = Join-Path $BACKUPS $Kind
    $have = Measure-BackupSource $Kind
    if ($have.Count -eq 0) {
        Say "Nothing to back up - there are no files of yours there yet." $C.Dim
        return $true
    }
    if ((Test-Path $dest) -and -not $Replace) {
        $old = Get-BackupInfo $Kind
        Say ("A backup already exists from {0} - keeping it." -f $old.When.ToString('d MMM yyyy HH:mm')) $C.Dim
        Say "That is the older one, so it is the one worth keeping." $C.Dim
        return $true
    }
    Say ("Backing up {0} - {1} file(s), {2} ..." -f $set.Title, $have.Count, (Format-Size $have.Bytes)) $C.Text
    if ($DryRun) { Say "(dry run - nothing copied)" $C.Dim; return $true }
    if ((Test-Path $dest) -and $Replace) { Remove-Item -LiteralPath $dest -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    foreach ($part in $set.Parts) {
        $files = Get-BackupPart $part
        if ($files.Count -eq 0) { continue }
        $to = Join-Path $dest $part.Sub
        if ($part.Type -eq 'folder') {
            if (-not (Copy-Tree $part.Path $to)) { Say "Backup FAILED - nothing was changed." $C.Bad; return $false }
        } else {
            New-Item -ItemType Directory -Force -Path $to | Out-Null
            foreach ($f in $files) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $to $f.Name) -Force }
        }
    }
    Say ("Backup saved to  {0}" -f $dest) $C.Good
    Write-Log "backup: $Kind -> $dest"
    return $true
}

<#
  Put one backup back where it came from. Adds files over what is there; it
  does not wipe the destination first, so anything the player added since is
  left alone and only their own originals come back on top.
#>
function Restore-Thing {
    param([string] $Kind)
    $set = $BACKUPSETS[$Kind]
    $dir = Join-Path $BACKUPS $Kind
    if (-not (Test-Path $dir)) { Say "There is no backup of $($set.Title) to restore." $C.Warn; return $false }
    Say ("Putting {0} back ..." -f $set.Title) $C.Text
    if ($DryRun) { Say "(dry run - nothing copied)" $C.Dim; return $true }
    $did = 0
    foreach ($part in $set.Parts) {
        $from = Join-Path $dir $part.Sub
        if (-not (Test-Path $from)) { continue }
        if ($part.Type -eq 'folder') {
            if (-not (Copy-Tree $from $part.Path)) { Say "Restore FAILED." $C.Bad; return $false }
        } else {
            if (-not (Test-Path $part.Path)) { New-Item -ItemType Directory -Force -Path $part.Path | Out-Null }
            foreach ($f in (Get-ChildItem -LiteralPath $from -File)) {
                Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $part.Path $f.Name) -Force
            }
        }
        $did++
    }
    if ($did -eq 0) { Say "That backup is empty - nothing to put back." $C.Warn; return $false }
    Say "Your own files are back." $C.Good
    Write-Log "restore: $Kind"
    return $true
}

# Backups used to live in _zm_qol_installer\backups. Move any across, once, so
# nobody loses one to the new layout.
function Move-OldBackups {
    if (-not (Test-Path $OLDBACKUPS)) { return }
    if ($DryRun) { return }
    try {
        New-Item -ItemType Directory -Force -Path $BACKUPS | Out-Null
        foreach ($d in (Get-ChildItem -LiteralPath $OLDBACKUPS -Directory -ErrorAction SilentlyContinue)) {
            $to = Join-Path $BACKUPS $d.Name
            if (Test-Path $to) { continue }
            Move-Item -LiteralPath $d.FullName -Destination $to -Force
            Write-Log "moved old backup: $($d.Name)"
        }
        if (@(Get-ChildItem -LiteralPath $OLDBACKUPS -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item -LiteralPath $OLDBACKUPS -Force -Recurse
        }
    } catch { Write-Log "could not move old backups: $_" 'warn' }
}

# ------------------------------------------------------------------ copying --
function Copy-Payload {
    param([string] $Source, [string] $Dest, [string] $Kind)
    $files = @(Get-ChildItem -LiteralPath $Source -File -Recurse)
    $size = ($files | Measure-Object Length -Sum).Sum
    Say ("Copying {0} file(s), {1} ..." -f $files.Count, (Format-Size $size)) $C.Text
    if ($DryRun) {
        Say "   (dry run - not copied)" $C.Dim
        return $true
    }
    if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Force -Path $Dest | Out-Null }
    $r = robocopy $Source $Dest /E /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) { Say "Copy FAILED - close Plutonium and try again." $C.Bad; return $false }
    $rel = @($files | ForEach-Object { $_.FullName.Substring($Source.Length).TrimStart('\') })

    # -----------------------------------------------------------------------
    #  v2.1.3 - THE BLOCKLIST. One texture in the pack breaks the HUD, and it
    #  has to be dealt with HERE rather than by deleting it from the payload,
    #  because the payload can also arrive as the texture zip attached to the
    #  v2.0.0 GitHub release - a published asset that must never be renamed or
    #  re-uploaded, so it will always still contain the file.
    #
    #  hud_dpad_blood.iwi - the blood splat behind the points and ammo in the
    #  bottom right. User, 2026-08-20, two screenshots: *"the points text on the
    #  hud there is being overlapped by the blood."*
    #
    #  🌟 MEASURED, not judged by eye. Both copies are 256x128 - the pack's is
    #  not an upscale of anything - and decoding both to alpha shows they are
    #  DIFFERENT ARTWORK: stock is a compact blob with scattered droplets, mean
    #  alpha 27.7, while the pack's is one splat filling almost the whole frame
    #  plus two ring droplets at the upper left, mean alpha 31.8. That silhouette
    #  - big mass, two rings - is exactly what both screenshots show around the
    #  points. Every OTHER hud_dpad_* texture in the pack matches stock's alpha
    #  to within 0.5, so they are the same art re-encoded and they stay.
    #  📝 The text is not overlapped, strictly: zooming the screenshot shows the
    #  white glyphs whole and on top. The splat behind them is simply so much
    #  bigger than stock's that it reads as covering them.
    # -----------------------------------------------------------------------
    $blocked = @()
    if ($Kind -eq 'images') { $blocked = @('hud_dpad_blood.iwi') }
    foreach ($b in $blocked) {
        $f = Join-Path $Dest $b
        if (Test-Path $f) {
            if (-not $DryRun) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
            Say "Left out $b - it covers the points number." $C.Dim
        }
        $rel = @($rel | Where-Object { $_ -ne $b })
    }

    # -----------------------------------------------------------------------
    #  v2.1.3 - AN INSTALL IS A SYNC, NOT AN ADD. robocopy /E copies and never
    #  purges, and this function then OVERWRITES the manifest, so before today a
    #  file dropped from the pack stayed on disk forever AND fell out of the
    #  record - "Remove the HD textures" could no longer see it either.
    #  Only files this installer itself put there can be removed, because the old
    #  manifest is the only list consulted; the player's own files were never in
    #  it and are never touched.
    # -----------------------------------------------------------------------
    $now = @{}
    foreach ($r2 in $rel) { $now[$r2.ToLower()] = $true }
    $stale = 0
    foreach ($r2 in (Read-Manifest $Kind)) {
        if (-not $now.ContainsKey($r2.ToLower())) {
            $f = Join-Path $Dest $r2
            if (Test-Path $f) {
                if (-not $DryRun) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
                $stale++
            }
        }
    }
    if ($stale -gt 0) { Say ("Cleared {0} file(s) left over from an older version." -f $stale) $C.Text }

    Write-Manifest $Kind $rel
    Say "Done." $C.Good
    return $true
}

function Remove-ByManifest {
    param([string] $Kind, [string] $Dest)
    $rel = Read-Manifest $Kind
    if ($rel.Count -eq 0) {
        Say "No record of anything installed by this installer, so nothing was removed." $C.Warn
        Say "Files that were already in that folder are never touched." $C.Dim
        return $false
    }
    $gone = 0
    foreach ($r in $rel) {
        $f = Join-Path $Dest $r
        if (Test-Path $f) {
            if (-not $DryRun) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
            $gone++
        }
    }
    Say ("Removed {0} file(s)." -f $gone) $C.Good
    if (-not $DryRun) {
        Remove-Item -LiteralPath (Join-Path $STATE "installed-$Kind.txt") -Force -ErrorAction SilentlyContinue
        Get-ChildItem -LiteralPath $Dest -Directory -Recurse -ErrorAction SilentlyContinue |
            Sort-Object FullName -Descending |
            Where-Object { (Get-ChildItem -LiteralPath $_.FullName -Force | Measure-Object).Count -eq 0 } |
            Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    }
    return $true
}

# ------------------------------------------------------------------- status --
function Get-Status {
    $s = @{}
    $v = Get-ModVersion (Join-Path $MODDIR 'mod.json')
    if ($v) { $s.Mod = "v$v installed"; $s.ModOn = $true } else { $s.Mod = 'not installed'; $s.ModOn = $false }

    $imgMan = Read-Manifest 'images'
    if ($imgMan.Count -gt 0) { $s.Images = "$($imgMan.Count) files installed"; $s.ImagesOn = $true }
    else {
        $n = @(Get-ChildItem -LiteralPath $IMGDIR -File -ErrorAction SilentlyContinue).Count
        if ($n -gt 0) { $word = 'files'; if ($n -eq 1) { $word = 'file' }; $s.Images = "$n $word already there (not mine)" } else { $s.Images = 'not installed' }
        $s.ImagesOn = $false
    }

    $have = 0
    foreach ($f in $SOUNDFILES) { if (Test-Path (Join-Path $ZONEDIR $f)) { $have++ } }
    if ($have -eq $SOUNDFILES.Count) { $s.Sounds = 'installed'; $s.SoundsOn = $true }
    elseif ($have -gt 0) { $s.Sounds = "$have of $($SOUNDFILES.Count) present"; $s.SoundsOn = $false }
    else { $s.Sounds = 'not installed'; $s.SoundsOn = $false }

    $dsMan = Read-Manifest 'dualsense'
    if ($dsMan.Count -gt 0) { $s.Dualsense = "$($dsMan.Count) icons installed"; $s.DualsenseOn = $true }
    else { $s.Dualsense = 'not installed'; $s.DualsenseOn = $false }

    if (Test-Path (Join-Path $BINDIR 'dxgi.dll')) { $s.ReShade = 'installed'; $s.ReShadeOn = $true }
    else { $s.ReShade = 'not installed'; $s.ReShadeOn = $false }

    $s.Settings = (Test-Path $CFGDIR)

    $n = 0
    foreach ($k in $BACKUPSETS.Keys) { if (Has-Backup $k) { $n++ } }
    if ($n -eq 0) { $s.Backups = 'nothing backed up yet'; $s.BackupsColour = $C.Dim }
    else {
        $word = 'things'; if ($n -eq 1) { $word = 'thing' }
        $s.Backups = "$n of $($BACKUPSETS.Count) $word backed up"; $s.BackupsColour = $C.Good
    }
    return $s
}

# ------------------------------------------------------------------ actions --
function Act-InstallMod {
    param([int] $Pick = -1)
    $src = Find-ModSource
    $cur = Get-ModVersion (Join-Path $MODDIR 'mod.json')
    $new = $null
    if ($src) { $new = Get-ModVersion (Join-Path $src 'mod.json') }

    if (-not $src) {
        Draw-Header 'Install the mod'
        Say "The mod files are not in this folder." $C.Warn
        Say "Use  Check for a newer version  to download them instead." $C.Dim
        Pause-Key
        return
    }

    $intro = @(
        "This copies the mod into Plutonium so it shows up in the Mods menu.",
        '',
        "~In this package:  $(if($new){"v$new"}else{'unknown'})",
        "~Installed now:    $(if($cur){"v$cur"}else{'nothing'})",
        "~Goes to:          $MODDIR"
    )
    $items = @(
        @{ Key='keep';  Label='Update, and keep my settings';   Status='recommended'; StatusColour=$C.Good },
        @{ Key='wipe';  Label='Fresh install, wipe everything'; Status='forget all my menu settings'; StatusColour=$C.Warn },
        @{ Key='back';  Label='Cancel' }
    )
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Install the mod' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Install the mod'
    Write-Log "action: install mod ($($sel.Key))"

    $missing = @()
    foreach ($f in $MODFILES) { if (-not (Test-Path (Join-Path $src $f))) { $missing += $f } }
    if ($missing.Count -gt 0) {
        Say "This package is incomplete - missing: $($missing -join ', ')" $C.Bad
        Say "Nothing was installed. Download the release again." $C.Dim
        Pause-Key; return
    }

    # old mod files out (never the logs the game writes into this same folder)
    if (Test-Path $MODDIR) {
        $old = @(Get-ChildItem -LiteralPath $MODDIR -File | Where-Object { $_.Extension -in @('.ff','.iwd','.json','.sabl','.sabs') })
        foreach ($o in $old) {
            if (-not $DryRun) { Remove-Item -LiteralPath $o.FullName -Force -ErrorAction SilentlyContinue }
        }
        if ($old.Count -gt 0) { Say "Removed $($old.Count) file(s) from the old version." $C.Dim }
    }

    if ($sel.Key -eq 'wipe' -and (Test-Path $CFGDIR)) {
        if (-not $DryRun) { Remove-Item -LiteralPath $CFGDIR -Recurse -Force -ErrorAction SilentlyContinue }
        Say "Your saved menu settings were wiped, as asked." $C.Warn
    } elseif (Test-Path $CFGDIR) {
        Say "Your saved menu settings were left alone." $C.Good
    }

    if (-not $DryRun -and -not (Test-Path $MODDIR)) { New-Item -ItemType Directory -Force -Path $MODDIR | Out-Null }
    $ok = $true
    foreach ($f in $MODFILES) {
        if ($DryRun) { Say "would copy $f" $C.Dim; continue }
        try { Copy-Item -LiteralPath (Join-Path $src $f) -Destination (Join-Path $MODDIR $f) -Force; Say $f $C.Text }
        catch { Say "FAILED to copy $f - is Plutonium running?" $C.Bad; $ok = $false }
    }
    if ($ok) {
        $v = Get-ModVersion (Join-Path $MODDIR 'mod.json')
        Write-Host ''
        Say "✅  The mod is installed - version $v" $C.Good
        Say "Plutonium T6 → Zombies → Mods → $MODNAME" $C.Dim
    }
    Pause-Key
}

function Act-InstallImages {
    param([int] $Pick = -1)
    $src = Find-Payload 'images'
    if (-not $src) { $src = Get-RemotePayload 'zm_qol-textures.zip' 'images' }
    if (-not $src) {
        Draw-Header 'HD texture pack'
        Say "The texture pack is not in this folder, and it is not attached to" $C.Warn
        Say "the latest release on GitHub either, so there is nothing to install." $C.Warn
        Pause-Key; return
    }
    $files = @(Get-ChildItem -LiteralPath $src -File -Recurse)
    $size  = ($files | Measure-Object Length -Sum).Sum

    $intro = @(
        "Higher resolution textures for the game.",
        "~$($files.Count) files, $(Format-Size $size).",
        '',
        "~Goes to:  $IMGDIR",
        '',
        "!⚠️   THIS OVERWRITES ANY CUSTOM TEXTURES ALREADY IN THAT FOLDER  ⚠️",
        "~     Your actual game files are never touched - only Plutonium's own",
        "~     images folder, which is where custom textures go."
    )
    $items = @(
        @{ Key='backup'; Label='Back up my textures first, then install'; Status='recommended'; StatusColour=$C.Good },
        @{ Key='plain';  Label='Install without a backup' },
        @{ Key='back';   Label='Cancel' }
    )
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'HD texture pack' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'HD texture pack'
    Write-Log "action: install images ($($sel.Key))"
    if ($sel.Key -eq 'backup') { if (-not (Backup-Thing 'images')) { Pause-Key; return } }
    if (Copy-Payload $src $IMGDIR 'images') { Write-Host ''; Say "✅  Texture pack installed." $C.Good }

    # ------------------------------------------------------------------------
    #  v2.2.0 - PUT THE PS5 ICONS BACK IF THEY WERE INSTALLED.
    #  All 20 filenames in the PS5 pack also exist in the HD texture pack, so the
    #  copy above has just overwritten them with the Xbox glyphs. Re-applying is
    #  the only way "install the textures" does not silently undo "install the
    #  PS5 icons". Nothing happens if the icons were never installed.
    # ------------------------------------------------------------------------
    if ((Read-Manifest 'dualsense').Count -gt 0) {
        $dsSrc = Find-Payload 'Dualsense IconsImages'
        if (-not $dsSrc) { $dsSrc = Find-Payload 'Dualsense Icons' }
        if ($dsSrc) {
            Write-Host ''
            Say "Re-applying your PS5 controller icons ..." $C.Text
            [void](Copy-Payload $dsSrc $IMGDIR 'dualsense')
        } else {
            Write-Host ''
            Say "Your PS5 icons were overwritten and the pack is not in this folder to re-apply." $C.Warn
        }
    }
    Pause-Key
}

function Act-InstallSounds {
    param([int] $Pick = -1)
    $src = Find-Payload 'zone'
    if (-not $src) { $src = Get-RemotePayload 'zm_qol-sounds.zip' 'zone' }
    if (-not $src) {
        Draw-Header 'Custom sounds'
        Say "The sound pack is not in this folder, and it is not attached to the" $C.Warn
        Say "latest release on GitHub either, so there is nothing to install." $C.Warn
        Pause-Key; return
    }
    $files = @(Get-ChildItem -LiteralPath $src -File -Recurse)
    $size  = ($files | Measure-Object Length -Sum).Sum

    $intro = @(
        "Replacement sounds for the game, loaded by Plutonium.",
        "~$($files.Count) files, $(Format-Size $size).",
        '',
        "~Goes to:  $ZONEDIR",
        '',
        "!⚠️   THIS REPLACES ANY CUSTOM SOUNDS ALREADY IN THAT FOLDER  ⚠️",
        "~     Your actual game sound files are never touched."
    )
    $items = @(
        @{ Key='backup'; Label='Back up my sounds first, then install'; Status='recommended'; StatusColour=$C.Good },
        @{ Key='plain';  Label='Install without a backup' },
        @{ Key='back';   Label='Cancel' }
    )
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Custom sounds' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Custom sounds'
    Write-Log "action: install sounds ($($sel.Key))"
    if ($sel.Key -eq 'backup') { if (-not (Backup-Thing 'zone')) { Pause-Key; return } }
    if (Copy-Payload $src $ZONEDIR 'zone') { Write-Host ''; Say "✅  Custom sounds installed." $C.Good }
    Pause-Key
}

# ---------------------------------------------------------------------------
#  The shipped ReShade.ini is the author's own config with two font lines left
#  EMPTY on purpose. The font it names (JetBrains Mono Nerd Font) is a separate
#  third-party download and is not redistributed here, so the path cannot be
#  hard-coded - it differs per machine and on most machines does not exist.
#
#  So: look for it, and only write the two lines if the file is really there.
#  Not found is not a failure - ReShade falls back to its own built-in font and
#  every other part of the look (the colours, the 12px rounding, the key binds)
#  is already in the file. Nothing else in the config depends on this.
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
#  Read one key out of a ReShade .ini, first from the live file and then from
#  the .backup, and return it only if it is non-empty. Used to carry a user's
#  own machine-specific values across an install instead of stomping them.
#  🛑 SavePath is the one that matters: the shipped file says
#  ".\reshade-screenshots" because a hard-coded drive letter is meaningless on
#  anyone else's PC - but somebody who already had ReShade pointed their
#  screenshots somewhere deliberately, and this mod has no business moving them.
#  (AddonPath and IntermediateCachePath are deliberately NOT carried: measured
#  on the author's own config, both held exactly ReShade's own defaults - the
#  module folder and %TEMP%\ReShade - just written out in full.)
# ---------------------------------------------------------------------------
function Get-IniValue {
    param([string] $Key)
    foreach ($f in @((Join-Path $BINDIR 'ReShade.ini'), (Join-Path $BINDIR 'ReShade.ini.backup'))) {
        if (-not (Test-Path -LiteralPath $f)) { continue }
        foreach ($l in [System.IO.File]::ReadAllLines($f)) {
            if ($l -like "$Key=*") {
                $v = $l.Substring($Key.Length + 1)
                if ($v -and $v.Trim() -ne '' -and $v -ne '.\reshade-screenshots') { return $v }
            }
        }
    }
    return $null
}

function Set-ReShadeValue {
    param([string] $Key, [string] $Value)
    $ini = Join-Path $BINDIR 'ReShade.ini'
    if (-not (Test-Path -LiteralPath $ini) -or $DryRun) { return }
    $lines = [System.IO.File]::ReadAllLines($ini)
    for ($i = 0; $i -lt $lines.Count; $i++) { if ($lines[$i] -like "$Key=*") { $lines[$i] = "$Key=$Value" } }
    [System.IO.File]::WriteAllLines($ini, $lines, (New-Object System.Text.UTF8Encoding($false)))
}

function Set-ReShadeFont {
    param([string] $PayloadDir)
    $ini = Join-Path $BINDIR 'ReShade.ini'
    if (-not (Test-Path -LiteralPath $ini)) { return }
    $name = 'JetBrainsMonoNerdFont-Regular.ttf'
    $candidates = @(
        (Join-Path $PayloadDir "fonts\$name"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts\$name"),
        (Join-Path $env:WINDIR "Fonts\$name")
    )
    $font = $null
    # 🛑 THE LOOP VARIABLE MUST NOT BE $c.  PowerShell variable names are
    #    case-INSENSITIVE, so `foreach ($c in ...)` overwrote $C - the colour
    #    table - for the rest of this function. Every Say below then passed
    #    $C.Dim on a plain string, which is $null, and Write-Host threw
    #    "Cannot convert value ''" and killed the installer. Installing ReShade
    #    has ended in that error since v2.0.0: the files copied, then the run
    #    aborted. Fixed by renaming the variable, and Say now refuses to pass an
    #    empty colour through even if something like this happens again.
    foreach ($cand in $candidates) { if ($cand -and (Test-Path -LiteralPath $cand)) { $font = (Resolve-Path -LiteralPath $cand).Path; break } }
    if (-not $font) {
        Say "Font not on this PC - ReShade will use its own. Everything else is set." $C.Dim
        return
    }
    if ($DryRun) { Say "Would point the UI font at $font" $C.Dim; return }
    $lines = [System.IO.File]::ReadAllLines($ini)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -eq 'Font=')       { $lines[$i] = "Font=$font" }
        if ($lines[$i] -eq 'EditorFont=') { $lines[$i] = "EditorFont=$font" }
    }
    [System.IO.File]::WriteAllLines($ini, $lines, (New-Object System.Text.UTF8Encoding($false)))
    Say "UI font found and set." $C.Dim
    Write-Log "reshade font: $font"
}

function Act-InstallReShade {
    param([int] $Pick = -1)
    $src = Find-Payload 'reshade'
    if (-not $src) {
        Draw-Header 'ReShade'
        Say "The ReShade files are not in this package." $C.Warn
        Pause-Key; return
    }
    $intro = @(
        "ReShade adds a sharpening / colour pass on top of the game, with this",
        "mod's own BO2 preset already applied. Press END in game to open it.",
        '',
        "~It also sets up the overlay the way the mod uses it: the dark blue",
        "~theme, rounded corners, and the extra keys - Ctrl+Shift+O for the FPS",
        "~counter, Ctrl+Shift+PgUp / PgDn to step through presets.",
        '',
        "~Goes to:  $BINDIR",
        "~Nothing is left running in the background.",
        '',
        "!⚠️   YOUR EXISTING ReShade.ini AND BO2.ini ARE KEPT AS .backup FILES",
        "~     Shader files you already have are added to, never deleted."
    )
    $items = @(
        @{ Key='go';   Label='Install ReShade with the BO2 preset'; Status='recommended'; StatusColour=$C.Good },
        @{ Key='back'; Label='Cancel' }
    )
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'ReShade' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'ReShade'
    Write-Log 'action: install reshade'
    # Remember the values that belong to THIS PC before the copy replaces them.
    $keepShots = Get-IniValue 'SavePath'
    $keepFont  = Get-IniValue 'Font'

    # 🛑 NEVER overwrite a .backup that already exists. Installing twice used to
    #    copy the config THIS INSTALLER wrote over the top of the .backup, which
    #    destroyed the only copy of the user's original settings. The first
    #    backup is the real one; a later run must leave it alone.
    foreach ($f in @('ReShade.ini','BO2.ini')) {
        $p = Join-Path $BINDIR $f
        if (Test-Path $p) {
            if (Test-Path "$p.backup") {
                Say "Your original $f.backup is already saved - left untouched." $C.Dim
            } else {
                if (-not $DryRun) { Copy-Item -LiteralPath $p -Destination "$p.backup" -Force }
                Say "Your $f was saved as $f.backup" $C.Dim
            }
        }
    }
    if (Copy-Payload $src $BINDIR 'reshade') {
        if ($keepShots) { Set-ReShadeValue 'SavePath' $keepShots; Say "Kept your screenshot folder: $keepShots" $C.Dim }
        if ($keepFont)  { Set-ReShadeValue 'Font' $keepFont; Set-ReShadeValue 'EditorFont' $keepFont; Say "Kept your overlay font." $C.Dim }
        else            { Set-ReShadeFont $src }
        Write-Host ''
        Say "✅  ReShade installed. Press END in game to open it." $C.Good
    }
    Pause-Key
}

# =============================================================================
#  PS5 CONTROLLER ICONS  -  v2.2.0
# -----------------------------------------------------------------------------
#  User, 2026-08-21: *"H:\Claude\Projects Sources\zm_qol\Optionals\Dualsense
#  Icons add an option for the mod installer to install PS5 Controller Icons, or
#  remove them/backup them as well."*
#
#  The payload is 20 .iwi files, all named xenonbutton_* / xenon_controller_top -
#  BO2's Xbox button glyphs - so installing them simply replaces the Xbox prompts
#  with DualSense ones. They go to the SAME folder as the HD texture pack
#  ($IMGDIR), under their own manifest, so removing one never touches the other.
#
#  🛑 THE HD TEXTURE PACK CONTAINS THE SAME 20 FILENAMES. Measured: all 20 names
#  in Optionals\Dualsense Icons\Images also appear in Optionals\images. So
#  installing (or re-installing) the texture pack after the icons would silently
#  put the Xbox glyphs back. Act-InstallImages therefore re-applies the icons at
#  the end whenever their manifest is non-empty - see the marked block there.
# =============================================================================
function Act-InstallDualsense {
    param([int] $Pick = -1)
    $src = Find-Payload 'Dualsense Icons\Images'
    if (-not $src) { $src = Find-Payload 'Dualsense Icons' }
    if (-not $src) {
        Draw-Header 'PS5 controller icons'
        Say "The PS5 icon pack is not in this folder, so there is nothing to install." $C.Warn
        Pause-Key; return
    }
    $files = @(Get-ChildItem -LiteralPath $src -File -Recurse)
    $size  = ($files | Measure-Object Length -Sum).Sum

    $intro = @(
        "Replaces the Xbox button prompts with PlayStation 5 ones.",
        "~$($files.Count) files, $(Format-Size $size).",
        '',
        "~Goes to:  $IMGDIR",
        '',
        "~These are the same $($files.Count) filenames the HD texture pack uses, so if you",
        "~install the texture pack later the icons are re-applied for you."
    )
    $items = @(
        @{ Key='backup'; Label='Back up my current icons first, then install'; Status='recommended'; StatusColour=$C.Good },
        @{ Key='plain';  Label='Install without a backup' },
        @{ Key='back';   Label='Cancel' }
    )
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'PS5 controller icons' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'PS5 controller icons'
    Write-Log "action: install dualsense ($($sel.Key))"
    if ($sel.Key -eq 'backup') { if (-not (Backup-Thing 'dualsense')) { Pause-Key; return } }
    if (Copy-Payload $src $IMGDIR 'dualsense') { Write-Host ''; Say "✅  PS5 controller icons installed." $C.Good }
    Pause-Key
}

function Act-RemoveDualsense {
    param([int] $Pick = -1)
    $hasB = Has-Backup 'dualsense'
    $intro = @(
        "Removes only the PS5 icon files this installer put there.",
        "~Your Xbox icons come back only if you have a backup, or if you",
        "~re-install the HD texture pack."
    )
    $items = @()
    if ($hasB) { $items += @{ Key='restore'; Label='Remove them and put my originals back'; Status='backup found'; StatusColour=$C.Good } }
    $items += @{ Key='plain'; Label='Just remove them' }
    $items += @{ Key='back';  Label='Cancel' }
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Remove the PS5 icons' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Remove the PS5 icons'
    Write-Log "action: remove dualsense ($($sel.Key))"
    $did = Remove-ByManifest 'dualsense' $IMGDIR
    if ($sel.Key -eq 'restore') { [void](Restore-Thing 'dualsense') }
    Write-Host ''
    if ($did) { Say "✅  Done." $C.Good } else { Say "Nothing to do." $C.Dim }
    Pause-Key
}

function Act-RemoveImages {
    param([int] $Pick = -1)
    $hasB = Has-Backup 'images'
    $intro = @(
        "Removes only the texture files this installer put there.",
        "~Anything that was already in your images folder is left alone."
    )
    $items = @()
    if ($hasB) { $items += @{ Key='restore'; Label='Remove them and put my originals back'; Status='backup found'; StatusColour=$C.Good } }
    $items += @{ Key='plain'; Label='Just remove them' }
    $items += @{ Key='back';  Label='Cancel' }
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Remove the HD textures' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Remove the HD textures'
    Write-Log "action: remove images ($($sel.Key))"
    $did = Remove-ByManifest 'images' $IMGDIR
    if ($sel.Key -eq 'restore') { [void](Restore-Thing 'images') }
    Write-Host ''
    if ($did) { Say "✅  Done." $C.Good } else { Say "Nothing to do." $C.Dim }
    Pause-Key
}

function Act-RemoveSounds {
    param([int] $Pick = -1)
    $hasB = Has-Backup 'zone'
    $intro = @(
        "Removes only the sound files this installer put there.",
        "~Plutonium's own files in that folder are left alone."
    )
    $items = @()
    if ($hasB) { $items += @{ Key='restore'; Label='Remove them and put my originals back'; Status='backup found'; StatusColour=$C.Good } }
    $items += @{ Key='plain'; Label='Just remove them' }
    $items += @{ Key='back';  Label='Cancel' }
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Remove the custom sounds' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Remove the custom sounds'
    Write-Log "action: remove sounds ($($sel.Key))"
    $did = Remove-ByManifest 'zone' $ZONEDIR
    if ($sel.Key -eq 'restore') { [void](Restore-Thing 'zone') }
    Write-Host ''
    if ($did) { Say "✅  Done." $C.Good } else { Say "Nothing to do." $C.Dim }
    Pause-Key
}

function Act-RemoveReShade {
    param([int] $Pick = -1)
    $intro = @(
        "Removes only the ReShade files this installer put there, and puts back",
        "any ReShade.ini / BO2.ini it saved as .backup.",
        "~Shader files you added yourself are left alone."
    )
    $items = @(
        @{ Key='go';   Label='Remove ReShade' },
        @{ Key='back'; Label='Cancel' }
    )
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Remove ReShade' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Remove ReShade'
    Write-Log 'action: remove reshade'
    [void](Remove-ByManifest 'reshade' $BINDIR)
    foreach ($f in @('ReShade.ini','BO2.ini')) {
        $b = Join-Path $BINDIR "$f.backup"
        if (Test-Path $b) {
            if (-not $DryRun) { Move-Item -LiteralPath $b -Destination (Join-Path $BINDIR $f) -Force }
            Say "Your original $f was put back." $C.Good
        }
    }
    Write-Host ''
    Say "✅  Done." $C.Good
    Pause-Key
}

function Act-RemoveMod {
    param([int] $Pick = -1)
    $intro = @(
        "Removes the mod from Plutonium's Mods menu.",
        "~Your other mods, your logs and the game itself are never touched."
    )
    $items = @(
        @{ Key='keep'; Label='Remove it, keep my settings'; Status='so a reinstall remembers them'; StatusColour=$C.Good },
        @{ Key='wipe'; Label='Remove it and wipe my settings' },
        @{ Key='back'; Label='Cancel' }
    )
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Remove the mod' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Remove the mod'
    Write-Log "action: remove mod ($($sel.Key))"

    # -----------------------------------------------------------------------
    #  v2.0.8 - THE MOD NOW ACTUALLY DISAPPEARS FROM THE MODS MENU.
    #
    #  User, 2026-08-21: *"when you choose to keep settings for the mod when
    #  uninstalling, because it doesn't fully remove the mods' folder ... it
    #  causes the mod to still show up in-game in the mods options, just without
    #  any functionality."*
    #
    #  🛑 THE CAUSE IS NOT THE SETTINGS, AND THAT MATTERS FOR THE FIX.
    #  Settings live in  storage\t6\players\mods\zm_qol  ($CFGDIR) - a different
    #  tree entirely, which Plutonium never scans for the Mods list. What was
    #  actually keeping  storage\t6\mods\zm_qol  ($MODDIR) alive is that THE GAME
    #  WRITES ITS LOGS INTO IT: a real install of this folder holds
    #  console_zm.log, console_zm.log.000-.003 and games_mp.log next to the five
    #  mod files. The removal loop only ever deleted the five mod extensions - on
    #  purpose, because an earlier version deleted the user's games_mp.log - so
    #  the folder always survived, and Plutonium lists any folder under mods\.
    #  Wiping the settings would not have fixed it either way.
    #
    #  So: keep the logs (they are the only record of past sessions and nothing
    #  else can recreate them), move them out of the way, then remove the folder.
    # -----------------------------------------------------------------------
    if (Test-Path $MODDIR) {
        $old = @(Get-ChildItem -LiteralPath $MODDIR -File | Where-Object { $_.Extension -in @('.ff','.iwd','.json','.sabl','.sabs') })
        foreach ($o in $old) { if (-not $DryRun) { Remove-Item -LiteralPath $o.FullName -Force -ErrorAction SilentlyContinue } }
        Say "Removed $($old.Count) mod file(s)." $C.Text

        $left = @(Get-ChildItem -LiteralPath $MODDIR -Force -ErrorAction SilentlyContinue)
        if ($left.Count -gt 0) {
            $logdest = Join-Path $BACKUPS 'zm_qol-logs'
            if (-not $DryRun) {
                if (-not (Test-Path $logdest)) { New-Item -ItemType Directory -Force -Path $logdest | Out-Null }
                foreach ($f in $left) {
                    try { Move-Item -LiteralPath $f.FullName -Destination (Join-Path $logdest $f.Name) -Force -ErrorAction Stop }
                    catch { }
                }
            }
            Say ("Moved {0} leftover file(s) - your game logs - to:" -f $left.Count) $C.Text
            Say "   $logdest" $C.Dim
        }

        $still = @(Get-ChildItem -LiteralPath $MODDIR -Force -ErrorAction SilentlyContinue)
        if ($DryRun) {
            Say "would remove the now-empty mod folder" $C.Dim
        } elseif ($still.Count -eq 0) {
            try { Remove-Item -LiteralPath $MODDIR -Force -ErrorAction Stop; Say "The mod folder is gone - it will not show in the Mods menu any more." $C.Good }
            catch { Say "Could not remove the mod folder - is Plutonium running?" $C.Warn }
        } else {
            # Something of the player's own is in there. Never delete that.
            Say "Left the folder in place - it still holds $($still.Count) file(s) that are not mine." $C.Warn
            Say "The mod may still appear in the Mods menu until that folder is empty." $C.Dim
        }
    } else { Say "It was not installed." $C.Dim }

    # -----------------------------------------------------------------------
    #  The settings half of the same request: *"maybe move the settings to backup
    #  or something ... but you can import your settings from the previous
    #  install."*  The backup system already has a 'mod' set whose second part IS
    #  $CFGDIR, so KEEP now means "copied into storage\t6\backups\mod\settings\",
    #  and Backups -> the mod -> put back is the import. Nothing new invented.
    # -----------------------------------------------------------------------
    if ($sel.Key -eq 'wipe' -and (Test-Path $CFGDIR)) {
        if (-not $DryRun) { Remove-Item -LiteralPath $CFGDIR -Recurse -Force -ErrorAction SilentlyContinue }
        Say "Your saved menu settings were wiped." $C.Warn
    } elseif (Test-Path $CFGDIR) {
        Write-Host ''
        if (Backup-Thing 'mod' -Replace) {
            Say "Your settings were copied to the backups, then left where they are." $C.Good
            Say "To import them after a reinstall: Backups -> the mod -> put back." $C.Dim
        } else {
            Say "Your saved menu settings were kept where they are." $C.Good
        }
    }
    Write-Host ''
    Say "✅  Done." $C.Good
    Pause-Key
}

# ---------------------------------------------------------------------------
#  REMOVE EVERYTHING - the mirror of Act-InstallEverything.
#
#  User, 2026-08-21: *"add an option to remove everything at the top of remove,
#  similar to how install has everything, simple."*
#
#  🌟 SAME RULE AS THE INSTALL SIDE: NOTHING IS REIMPLEMENTED. Each Act-Remove*
#  already takes a -Pick that selects one of its own rows without drawing the
#  menu, so this is a driver. Whatever those four do interactively is exactly
#  what happens here - the same manifest-only deletion, the same .backup
#  restores, the same log rescue when the mod folder goes.
#
#  Pick indices, read off each function's own $items array:
#     Act-RemoveImages   restore row EXISTS ONLY IF a backup does, so:
#                          backup present -> 0 = 'restore', 1 = 'plain'
#                          no backup      -> 0 = 'plain'
#     Act-RemoveSounds   identical, keyed on the 'zone' backup
#     Act-RemoveReShade  0 = 'go'   (its only non-cancel row)
#     Act-RemoveMod      0 = 'keep' (NEVER 'wipe' - an all-in-one must not be
#                                    the thing that silently forgets the
#                                    player's menu settings; Remove the mod ->
#                                    "wipe my settings" is still there for
#                                    anyone who actually wants that)
#
#  📝 The restore question is asked ONCE here and passed down, for the same
#  reason the install side asks about backups once.
#
#  📝 The mod goes LAST on purpose. Act-RemoveMod is the step that moves the
#  game logs out and deletes storage\t6\mods\zm_qol; doing it first would mean
#  the later steps write their log lines into a folder that is about to vanish.
# ---------------------------------------------------------------------------
function Act-RemoveEverything {
    param([int] $Pick = -1)

    $imgHasB = Has-Backup 'images'
    $sndHasB = Has-Backup 'zone'
    #  v2.2.0 - the PS5 icons go with everything else. Leaving 20 files behind
    #  after "remove everything" is exactly the class of thing the raw LUI leak
    #  turned out to be.
    $dsHasB  = Has-Backup 'dualsense'
    $anyB    = ($imgHasB -or $sndHasB -or $dsHasB)

    $intro = @(
        "Removes every part of this package, one after the other:",
        "~   the HD texture pack  ·  custom sounds  ·  PS5 icons  ·  ReShade  ·  the mod",
        '',
        "~Only files this installer put there are deleted. Anything that was",
        "~already in those folders is left exactly where it is, and your game",
        "~logs are moved to storage\t6\backups\zm_qol-logs rather than deleted.",
        '',
        "~Your saved menu settings are KEPT, and copied to the backups, so a",
        "~reinstall can import them. To wipe them instead, use Remove the mod."
    )
    if ($anyB) {
        $intro += ''
        $intro += "~A backup of your own files was found - the first row puts it back."
    }

    $items = @()
    if ($anyB) { $items += @{ Key='restore'; Label='Remove it all and put my original files back'; Status='backup found'; StatusColour=$C.Good } }
    $items += @{ Key='plain'; Label='Just remove it all' }
    $items += @{ Key='back';  Label='Cancel' }
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Remove everything' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Write-Log "action: remove everything ($($sel.Key))"

    $restore = ($sel.Key -eq 'restore')

    # Index of the row we want inside each pack remover, given that its
    # 'restore' row is only present when that particular backup is.
    $imgPick = 0
    if ($imgHasB -and -not $restore) { $imgPick = 1 }
    $sndPick = 0
    if ($sndHasB -and -not $restore) { $sndPick = 1 }
    $dsPick = 0
    if ($dsHasB -and -not $restore) { $dsPick = 1 }

    $wasQuiet = $script:Quiet
    if (-not $script:Headless) { Clear-Host }
    $script:Quiet = $true
    try {
        Act-RemoveImages  -Pick $imgPick
        Act-RemoveSounds  -Pick $sndPick
        Act-RemoveDualsense -Pick $dsPick
        Act-RemoveReShade -Pick 0
        Act-RemoveMod     -Pick 0
    }
    finally { $script:Quiet = $wasQuiet }

    $st = Get-Status
    Draw-Header 'Remove everything'
    Say 'Where things stand now:' $C.Text -NoLog
    Write-Host ''
    $rows = @(
        @{ n='HD texture pack'; v=$st.Images;  on=$st.ImagesOn },
        @{ n='Custom sounds';   v=$st.Sounds;  on=$st.SoundsOn },
        @{ n='PS5 icons';       v=$st.Dualsense; on=$st.DualsenseOn },
        @{ n='ReShade';         v=$st.ReShade; on=$st.ReShadeOn },
        @{ n='The mod';         v=$st.Mod;     on=$st.ModOn }
    )
    foreach ($r in $rows) {
        # Inverted against the install screen on purpose: here "still on" is the
        # bad news and "not installed" is the result the player asked for.
        $col = $C.Good
        if ($r.on) { $col = $C.Warn }
        Say ($r.n.PadRight(20) + $r.v) $col -NoLog
    }
    Write-Host ''
    if ($st.ModOn) { Say "The mod is still installed - see Details and log." $C.Bad -NoLog }
    else { Say "Your settings were kept. Backups -> the mod -> put back imports them." $C.Dim -NoLog }
    Write-Log "remove everything finished: mod=$($st.ModOn) images=$($st.ImagesOn) sounds=$($st.SoundsOn) reshade=$($st.ReShadeOn)"
    Pause-Key
}

# ------------------------------------------------------------------ updates --
# ---------------------------------------------------------------------------
#  Backups. One screen listing the four things, and one screen per thing with
#  back up / put back / delete. Nothing here is destructive without a second
#  choice on the per-thing screen.
# ---------------------------------------------------------------------------
function Get-BackupStatus {
    param([string] $Kind)
    $b = Get-BackupInfo $Kind
    if ($b -and $b.Count -gt 0) {
        return @{ Text = ("{0} · {1} · {2}" -f $b.When.ToString('d MMM yyyy'), $b.Count, (Format-Size $b.Bytes)); Colour = $C.Good }
    }
    $have = Measure-BackupSource $Kind
    if ($have.Count -eq 0) { return @{ Text = 'nothing there to back up'; Colour = $C.Off } }
    return @{ Text = ("no backup · {0} files, {1}" -f $have.Count, (Format-Size $have.Bytes)); Colour = $C.Dim }
}

function Act-BackupOne {
    param([string] $Kind, [int] $Pick = -1)
    while ($true) {
        $set  = $BACKUPSETS[$Kind]
        $b    = Get-BackupInfo $Kind
        $have = Measure-BackupSource $Kind

        $intro = @("A backup of $($set.Title), kept separately from the mod so this")
        $intro += "installer can never be the reason you lose them."
        $intro += ''
        $intro += "~Backup goes to:  $(Join-Path $BACKUPS $Kind)"
        $intro += "~On this PC now:   $($have.Count) file(s), $(Format-Size $have.Bytes)"
        if ($b -and $b.Count -gt 0) {
            $intro += "~Backed up:        $($b.When.ToString('d MMM yyyy, HH:mm')) - $($b.Count) file(s), $(Format-Size $b.Bytes)"
        } else {
            $intro += "~Backed up:        never"
        }

        $items = @()
        if ($b -and $b.Count -gt 0) {
            $items += @{ Key='replace'; Label='Back up again, replacing that one'; Status='overwrites the backup'; StatusColour=$C.Warn }
            $items += @{ Key='restore'; Label='Put my backup back';                Status='backup found';          StatusColour=$C.Good }
            $items += @{ Key='delete';  Label='Delete this backup' }
        } else {
            $d = @{ Key='make'; Label='Back it up now' }
            if ($have.Count -eq 0) { $d.Status = 'nothing there yet'; $d.StatusColour = $C.Off; $d.Disabled = $true }
            $items += $d
        }
        $items += @{ Key='back'; Label='Back' }

        if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu "Backup - $($set.Title)" $items -Intro $intro }
        if (-not $sel -or $sel.Key -eq 'back') { return }

        Draw-Header "Backup - $($set.Title)"
        Write-Log "action: backup $Kind ($($sel.Key))"
        switch ($sel.Key) {
            'make'    { [void](Backup-Thing $Kind) }
            'replace' { [void](Backup-Thing $Kind -Replace) }
            'restore' { [void](Restore-Thing $Kind) }
            'delete'  {
                $dir = Join-Path $BACKUPS $Kind
                if ($DryRun) { Say "(dry run - not deleted)" $C.Dim }
                elseif (Test-Path $dir) { Remove-Item -LiteralPath $dir -Recurse -Force; Say "Backup deleted. The files on your PC are untouched." $C.Good }
                else { Say "There was no backup to delete." $C.Dim }
            }
        }
        Pause-Key
        if ($Pick -ge 0) { return }
    }
}

function Act-Backups {
    param([int] $Pick = -1)
    while ($true) {
        $intro = @(
            'Back up your own textures, sounds, ReShade or mod folder before this',
            'installer writes over them - and put them back whenever you like.',
            '',
            "~Everything is kept in:  $BACKUPS",
            "~One plain folder per thing. Nothing in there is ever deleted by an",
            "~install or an update - only by you, on the screen for that thing."
        )
        $items = @()
        foreach ($k in $BACKUPSETS.Keys) {
            $st = Get-BackupStatus $k
            $label = switch ($k) {
                'images'  { 'My textures' }
                'zone'    { 'My sounds' }
                'reshade' { 'My ReShade setup' }
                'mod'     { 'The mod + my settings' }
            }
            $items += @{ Key=$k; Label=$label; Status=$st.Text; StatusColour=$st.Colour }
        }
        $items += @{ Key='back'; Label='Back' }

        if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Backups' $items -Intro $intro }
        if (-not $sel -or $sel.Key -eq 'back') { return }
        Act-BackupOne $sel.Key
        if ($Pick -ge 0) { return }
    }
}

function Get-Release {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        return Invoke-RestMethod "https://api.github.com/repos/$REPO/releases/latest" -Headers @{ 'User-Agent' = 'zm_qol-installer' }
    } catch { return $null }
}

<#
  Find one release asset by name.

  🛑 It must NOT look only at the latest release. The texture pack is 524 MB
  and the sound pack 641 MB; re-uploading both on every patch release is not
  something anyone will keep doing, so they stay attached to the release they
  were built for. Look in the latest release first, then walk back through the
  recent ones and take the newest copy that exists.
#>
function Find-ReleaseAsset {
    param([string] $AssetName)
    $rel = Get-Release
    if ($rel) {
        $a = $rel.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
        if ($a) { return $a }
    }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $all = Invoke-RestMethod "https://api.github.com/repos/$REPO/releases?per_page=30" -Headers @{ 'User-Agent' = 'zm_qol-installer' }
    } catch { return $null }
    foreach ($r in $all) {
        $a = $r.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
        if ($a) { Write-Log "found $AssetName on release $($r.tag_name)"; return $a }
    }
    return $null
}

function Get-RemotePayload {
    param([string] $AssetName, [string] $FolderName)
    $asset = Find-ReleaseAsset $AssetName
    if (-not $asset) { return $null }

    Draw-Header 'Downloading'
    Say "$AssetName is not in this folder - downloading it ($(Format-Size $asset.size)) ..." $C.Text
    if ($DryRun) { Say '(dry run - not downloaded)' $C.Dim; return $null }
    $tmp = Join-Path $env:TEMP 'zm_qol_installer'
    if (-not (Test-Path $tmp)) { New-Item -ItemType Directory -Force -Path $tmp | Out-Null }
    $zip = Join-Path $tmp $AssetName
    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) { & curl.exe -L --fail --progress-bar -o $zip $asset.browser_download_url }
        else { Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing }
    } catch { Say 'Download failed.' $C.Bad; return $null }
    if (-not (Test-Path $zip)) { return $null }
    $out = Join-Path $tmp $FolderName
    if (Test-Path $out) { Remove-Item -LiteralPath $out -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    Say 'Unpacking ...' $C.Text
    try { Expand-Archive -LiteralPath $zip -DestinationPath $out -Force } catch { Say 'Unpacking failed.' $C.Bad; return $null }
    $inner = Join-Path $out $FolderName
    if (Test-Path $inner) { return $inner }
    return $out
}

function Act-CheckUpdate {
    param([int] $Pick = -1)
    Draw-Header 'Check for a newer version'
    Say 'Asking GitHub ...' $C.Text
    $rel = Get-Release
    if (-not $rel) {
        Say 'Could not reach GitHub. Check your connection and try again.' $C.Bad
        Pause-Key; return
    }
    $tag = $rel.tag_name
    $tagV = $tag.TrimStart('v')
    $cur = Get-ModVersion (Join-Path $MODDIR 'mod.json')

    $state = 'unknown'
    if ($cur) {
        try {
            $a = [version]$tagV; $b = [version]$cur
            if ($a -gt $b) { $state = 'newer' } elseif ($a -eq $b) { $state = 'same' } else { $state = 'older' }
        } catch { $state = 'unknown' }
    } else { $state = 'newer' }

    $intro = @(
        "~Latest release:  $tag",
        "~You have:        $(if($cur){"v$cur"}else{'nothing installed'})",
        ''
    )
    if ($state -eq 'same')  { $intro += "✅  You are already up to date." }
    if ($state -eq 'newer') { $intro += "🆕  There is a newer version available." }
    if ($state -eq 'older') {
        $intro += "!⚠️   YOUR COPY IS NEWER THAN THE RELEASE"
        $intro += "~     Installing it would take you BACKWARDS to $tag."
    }

    $items = @()
    if ($state -eq 'newer') {
        $items += @{ Key='go';   Label="Download and install $tag"; Status='recommended'; StatusColour=$C.Good }
        $items += @{ Key='back'; Label='Not now' }
    } else {
        $items += @{ Key='back'; Label='Go back'; Status='recommended'; StatusColour=$C.Good }
        $items += @{ Key='go';   Label="Install $tag anyway"; Status='takes you backwards'; StatusColour=$C.Warn }
    }
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Check for a newer version' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Downloading'
    $asset = $rel.assets | Where-Object { $_.name -like '*.zip' -and $_.name -notlike '*texture*' -and $_.name -notlike '*sound*' } | Select-Object -First 1
    if (-not $asset) { Say 'That release has no mod zip attached.' $C.Bad; Pause-Key; return }
    Say "Downloading $($asset.name) ($(Format-Size $asset.size)) ..." $C.Text
    if ($DryRun) { Say '(dry run)' $C.Dim; Pause-Key; return }
    $tmp = Join-Path $env:TEMP 'zm_qol_installer'
    if (-not (Test-Path $tmp)) { New-Item -ItemType Directory -Force -Path $tmp | Out-Null }
    $zip = Join-Path $tmp $asset.name
    try {
        if (Get-Command curl.exe -ErrorAction SilentlyContinue) { & curl.exe -L --fail --progress-bar -o $zip $asset.browser_download_url }
        else { Invoke-WebRequest $asset.browser_download_url -OutFile $zip -UseBasicParsing }
    } catch { Say 'Download failed.' $C.Bad; Pause-Key; return }
    $out = Join-Path $tmp 'unpack'
    if (Test-Path $out) { Remove-Item -LiteralPath $out -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    Say 'Unpacking ...' $C.Text
    Expand-Archive -LiteralPath $zip -DestinationPath $out -Force
    # The release zip is a whole package now, so mod.json sits several folders
    # deep (Quality Of Life Mod T6 ZM x.y.z\Mod Files\zm_qol\). Find it wherever
    # it is rather than guessing at a layout.
    $found = Get-ChildItem -LiteralPath $out -Recurse -File -Filter 'mod.json' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $found) { Say 'That download did not contain the mod.' $C.Bad; Pause-Key; return }
    $srcDir = $found.DirectoryName

    foreach ($f in $MODFILES) {
        if (-not (Test-Path (Join-Path $srcDir $f))) { Say "Incomplete download - missing $f" $C.Bad; Pause-Key; return }
    }
    if (-not (Test-Path $MODDIR)) { New-Item -ItemType Directory -Force -Path $MODDIR | Out-Null }
    foreach ($f in $MODFILES) { Copy-Item -LiteralPath (Join-Path $srcDir $f) -Destination (Join-Path $MODDIR $f) -Force; Say $f $C.Text }
    Write-Host ''
    Say "✅  $tag installed. Your settings were kept." $C.Good
    Pause-Key
}

# ------------------------------------------------------------------ details --
function Act-Details {
    Draw-Header 'Details and log'
    $st = Get-Status
    Write-Host '   WHERE THINGS ARE' -ForegroundColor $C.Dim
    Say "Plutonium      $PLUTO" $C.Text -NoLog
    Say "Mod folder     $MODDIR" $C.Text -NoLog
    Say "Textures       $IMGDIR" $C.Text -NoLog
    Say "Sounds         $ZONEDIR" $C.Text -NoLog
    Say "ReShade        $BINDIR" $C.Text -NoLog
    Say "Your settings  $CFGDIR" $C.Text -NoLog
    $src = Find-ModSource
    Say "This package   $(if($src){$src}else{'no mod files found next to this script'})" $C.Text -NoLog
    Write-Host ''
    Write-Host '   WHAT IS INSTALLED' -ForegroundColor $C.Dim
    Say "Mod            $($st.Mod)" $C.Text -NoLog
    Say "Textures       $($st.Images)" $C.Text -NoLog
    Say "Sounds         $($st.Sounds)" $C.Text -NoLog
    Say "PS5 icons      $($st.Dualsense)" $C.Text -NoLog
    Say "ReShade        $($st.ReShade)" $C.Text -NoLog
    Say "Backups        $(if(Test-Path $BACKUPS){$BACKUPS}else{'none taken yet'})" $C.Text -NoLog
    Write-Host ''
    Write-Host '   THIS SESSION' -ForegroundColor $C.Dim
    if ($script:Log.Count -eq 0) { Say 'nothing yet' $C.Dim -NoLog }
    else { $script:Log | Select-Object -Last 12 | ForEach-Object { Say $_ $C.Dim -NoLog } }
    Write-Host ''
    Say "Full log: $LOGFILE" $C.Dim -NoLog
    Pause-Key
}

# ---------------------------------------------------------------------------
#  ALL-IN-ONE                                                        (v2.0.5)
#
#  User, 2026-08-21: *"add an option aside from the main 4 options, an
#  'all-in-one' option so if you want you can just install the entire mod, or
#  specific parts of the mod package, again with the option to backup
#  everything."*
#
#  🌟 NOTHING IS REIMPLEMENTED. Every Act-Install* already takes a -Pick that
#  selects one of its own menu rows without drawing the menu - the same door the
#  command-line -Action switch uses. So this is a driver, not a fifth installer:
#  whatever those four do interactively is exactly what happens here, including
#  every missing-file check, every backup and every GitHub fallback. If one of
#  them changes, this follows it for free.
#
#  Pick indices, read off each function's own $items array:
#     Act-InstallMod      0 = 'keep'   (update and KEEP the player's settings -
#                                       never 'wipe'; an all-in-one must not be
#                                       the thing that silently forgets them)
#     Act-InstallImages   0 = 'backup' / 1 = 'plain'
#     Act-InstallSounds   0 = 'backup' / 1 = 'plain'
#     Act-InstallReShade  0 = 'go'     (its only non-cancel row; it keeps the
#                                       player's own .ini as .backup regardless)
#
#  📝 The backup question is asked ONCE here and passed down, because being
#  asked it twice in a row is the thing an all-in-one is supposed to remove.
# ---------------------------------------------------------------------------
function Act-InstallEverything {
    param([int] $Pick = -1)

    $st = Get-Status
    $intro = @(
        "Installs every part of this package, one after the other:",
        "~   the mod  ·  HD texture pack  ·  custom sounds  ·  ReShade",
        '',
        "~Any part whose files are not in this download - and cannot be fetched",
        "~from GitHub - is reported and skipped. Nothing else stops.",
        '',
        "~Your saved menu settings are always kept.",
        '',
        "!⚠️   THIS OVERWRITES CUSTOM TEXTURES AND SOUNDS ALREADY IN PLUTONIUM",
        "~     Pick the backup row and your own files are copied into",
        "~     storage\t6\backups first."
    )
    $items = @(
        @{ Key='backup'; Label='Back up my files first, then install it all'; Status='recommended'; StatusColour=$C.Good },
        @{ Key='plain';  Label='Install it all without a backup' },
        @{ Key='back';   Label='Cancel' }
    )
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Install everything' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Write-Log "action: install everything ($($sel.Key))"

    $subPick = 1
    if ($sel.Key -eq 'backup') { $subPick = 0 }

    $wasQuiet = $script:Quiet
    if (-not $script:Headless) { Clear-Host }
    $script:Quiet = $true
    try {
        Act-InstallMod     -Pick 0
        Act-InstallImages  -Pick $subPick
        Act-InstallSounds  -Pick $subPick
        Act-InstallReShade -Pick 0
    }
    finally { $script:Quiet = $wasQuiet }

    $st = Get-Status
    Draw-Header 'Install everything'
    Say 'Where things stand now:' $C.Text -NoLog
    Write-Host ''
    $rows = @(
        @{ n='The mod';         v=$st.Mod;     on=$st.ModOn },
        @{ n='HD texture pack'; v=$st.Images;  on=$st.ImagesOn },
        @{ n='Custom sounds';   v=$st.Sounds;  on=$st.SoundsOn },
        @{ n='PS5 icons';       v=$st.Dualsense; on=$st.DualsenseOn },
        @{ n='ReShade';         v=$st.ReShade; on=$st.ReShadeOn }
    )
    foreach ($r in $rows) {
        $col = $C.Warn
        if ($r.on) { $col = $C.Good }
        Say ($r.n.PadRight(20) + $r.v) $col -NoLog
    }
    Write-Host ''
    if ($st.ModOn) { Say "Plutonium T6 → Zombies → Mods → $MODNAME" $C.Dim -NoLog }
    else { Say "The mod itself did not install - see Details and log." $C.Bad -NoLog }
    Write-Log "install everything finished: mod=$($st.ModOn) images=$($st.ImagesOn) sounds=$($st.SoundsOn) reshade=$($st.ReShadeOn)"
    Pause-Key
}

# --------------------------------------------------------------------- main --
function Test-PlutoRunning {
    foreach ($n in @('plutonium-launcher-win32','plutonium-bootstrapper-win32','t6zm','t6mp')) {
        if (Get-Process -Name $n -ErrorAction SilentlyContinue) { return $true }
    }
    return $false
}

function Main-Menu {
    while ($true) {
        $st = Get-Status
        $sub = 'Black Ops II Zombies  ·  Plutonium T6'
        $intro = @()
        if (-not (Test-Path $PLUTO)) {
            $intro += "!⚠️   Plutonium was not found on this PC."
            $intro += "~     Install it and run it once, then come back."
            $intro += ''
        } elseif (Test-PlutoRunning) {
            $intro += "!⚠️   Plutonium is running right now - close it first, or files"
            $intro += "!     cannot be replaced."
            $intro += ''
        }

        $modColour = $C.Dim; if ($st.ModOn) { $modColour = $C.Good }
        $imgColour = $C.Dim; if ($st.ImagesOn) { $imgColour = $C.Good }
        $sndColour = $C.Dim; if ($st.SoundsOn) { $sndColour = $C.Good }
        $rshColour = $C.Dim; if ($st.ReShadeOn) { $rshColour = $C.Good }
        $dsColour  = $C.Dim; if ($st.DualsenseOn) { $dsColour = $C.Good }

        $items = @(
            @{ Key='all';    Section='INSTALL';   Label='EVERYTHING - the whole package'; Status='mod + textures + sounds + ReShade'; StatusColour=$C.Title },
            @{ Key='mod';    Section='INSTALL';   Label='The mod';               Status=$st.Mod;     StatusColour=$modColour },
            @{ Key='images'; Section='INSTALL';   Label='HD texture pack';       Status=$st.Images;  StatusColour=$imgColour },
            @{ Key='sounds'; Section='INSTALL';   Label='Custom sounds';         Status=$st.Sounds;  StatusColour=$sndColour },
            @{ Key='reshade';Section='INSTALL';   Label='ReShade + BO2 preset';  Status=$st.ReShade; StatusColour=$rshColour },
            @{ Key='dualsense';Section='INSTALL'; Label='PS5 controller icons';  Status=$st.Dualsense; StatusColour=$dsColour },

            @{ Key='rall';    Section='REMOVE';   Label='EVERYTHING - the whole package'; Status='textures + sounds + ReShade + mod'; StatusColour=$C.Title },
            @{ Key='rimages'; Section='REMOVE';   Label='Remove the HD textures' },
            @{ Key='rsounds'; Section='REMOVE';   Label='Remove the custom sounds' },
            @{ Key='rreshade';Section='REMOVE';   Label='Remove ReShade' },
            @{ Key='rdualsense';Section='REMOVE'; Label='Remove the PS5 icons' },
            @{ Key='rmod';    Section='REMOVE';   Label='Remove the mod' },

            @{ Key='backups'; Section='BACKUP';   Label='Back up / restore my own files'; Status=$st.Backups; StatusColour=$st.BackupsColour },

            @{ Key='update';  Section='MORE';     Label='Check for a newer version' },
            @{ Key='details'; Section='MORE';     Label='Details and log' },
            @{ Key='quit';    Section='MORE';     Label='Quit' }
        )

        $sel = Show-Menu $sub $items -Intro $intro -Footer '   ↑ ↓  move      ENTER  choose      Q  quit'
        if (-not $sel -or $sel.Key -eq 'quit') { return }

        switch ($sel.Key) {
            'all'      { Act-InstallEverything }
            'mod'      { Act-InstallMod }
            'images'   { Act-InstallImages }
            'sounds'   { Act-InstallSounds }
            'reshade'  { Act-InstallReShade }
            'dualsense' { Act-InstallDualsense }
            'rall'     { Act-RemoveEverything }
            'rimages'  { Act-RemoveImages }
            'rsounds'  { Act-RemoveSounds }
            'rreshade' { Act-RemoveReShade }
            'rdualsense' { Act-RemoveDualsense }
            'rmod'     { Act-RemoveMod }
            'backups'  { Act-Backups }
            'update'   { Act-CheckUpdate }
            'details'  { Act-Details }
        }
    }
}

Write-Log "--- installer started (dryrun=$DryRun) ---"
Move-OldBackups

if ($Action) {
    switch ($Action) {
        'all'      { Act-InstallEverything -Pick $Choice }
        'mod'      { Act-InstallMod     -Pick $Choice }
        'images'   { Act-InstallImages  -Pick $Choice }
        'sounds'   { Act-InstallSounds  -Pick $Choice }
        'reshade'  { Act-InstallReShade -Pick $Choice }
        'dualsense' { Act-InstallDualsense -Pick $Choice }
        'rall'     { Act-RemoveEverything -Pick $Choice }
        'rimages'  { Act-RemoveImages   -Pick $Choice }
        'rsounds'  { Act-RemoveSounds   -Pick $Choice }
        'rreshade' { Act-RemoveReShade  -Pick $Choice }
        'rdualsense' { Act-RemoveDualsense -Pick $Choice }
        'rmod'     { Act-RemoveMod      -Pick $Choice }
        'backups'  { Act-Backups        -Pick $Choice }
        'backup'   { [void](Backup-Thing $Extra) }
        'restore'  { [void](Restore-Thing $Extra) }
        'update'   { Act-CheckUpdate    -Pick $Choice }
        'details'  { Act-Details }
        default    { Write-Host "unknown action: $Action" }
    }
    exit 0
}

Main-Menu
Draw-Header 'Bye'
Write-Host ''
Write-Host '     Launch Plutonium T6  →  Zombies  →  Mods  →  Quality Of Life' -ForegroundColor $C.Good
Write-Host ''
Start-Sleep -Milliseconds 600
