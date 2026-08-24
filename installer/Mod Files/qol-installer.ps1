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
$SOUNDFILES = @('cmn_root.all.sabl','zmb_code_post_gfx.all.sabs','zmb_common.english.sabs','zmb_alcatraz.all.sabl','zmb_tomb.all.sabl')

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

# ---------------------------------------------------------------------------
#  🛑 v2.2.6 - A RUN WITH NOWHERE TO READ A KEY FROM MUST END, NOT SPIN.
#
#  Measured 2026-08-23: launching this script with stdin redirected and no
#  -Action ran for two minutes without exiting and had to be killed.
#
#  The mechanism: [Console]::KeyAvailable THROWS when console input is
#  redirected ("Cannot see if a key has been pressed when either application
#  does not have a console or when console input has been redirected"). The
#  catch around it sets NoKeys and `continue`s, the next pass takes the plain
#  sequential path, and that path asks Read-Host - which on a stream already at
#  end-of-file answers instantly and forever. Every layer behaved as written;
#  the loop between them had no floor.
#
#  🌟 The floor is one question asked once, at startup: is there a human who
#  could answer a menu at all? -Action already meant no. Redirected input means
#  no for exactly the same reason, so it joins it. Menus then return $null the
#  moment they are opened and the run finishes instead of spinning.
#
#  📝 It is deliberately NOT gated on -NonInteractive: a normal interactive
#  double-click has IsInputRedirected false, and a piped or scheduled run has it
#  true, which is the distinction that actually matters here.
# ---------------------------------------------------------------------------
$script:NoStdin = $false
try { $script:NoStdin = [Console]::IsInputRedirected } catch { $script:NoStdin = $true }
$script:Headless = ([bool]$Action) -or $script:NoStdin

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

# ---------------------------------------------------------------------------
#  ANSI / virtual-terminal output. The menu draws each frame as one string with
#  colour codes in it and pushes it in a single write, which is what stops the
#  terminal presenting a half-drawn frame. Windows Terminal has VT on always;
#  conhost needs ENABLE_VIRTUAL_TERMINAL_PROCESSING (0x0004) turned on, which is
#  what Enable-Vt does. If either the P/Invoke or the mode set fails, $script:Vt
#  stays $false and the menu uses the old per-segment Write-Host path.
# ---------------------------------------------------------------------------
$script:Vt = $false
$VTMAP = @{
    'Black'='30'; 'DarkRed'='31'; 'DarkGreen'='32'; 'DarkYellow'='33'
    'DarkBlue'='34'; 'DarkMagenta'='35'; 'DarkCyan'='36'; 'Gray'='37'
    'DarkGray'='90'; 'Red'='91'; 'Green'='92'; 'Yellow'='93'
    'Blue'='94'; 'Magenta'='95'; 'Cyan'='96'; 'White'='97'
}
function Vt-Colour {
    param([string] $Name)
    $c = '37'
    if ($Name -and $VTMAP.ContainsKey($Name)) { $c = $VTMAP[$Name] }
    return "$([char]27)[${c}m"
}
function Enable-Vt {
    if ($script:Headless) { return }

    #  🛑 REDIRECTED OUTPUT IS NOT A CONSOLE. Escape codes would land in the file
    #  or pipe as literal bytes, and GetConsoleMode below fails on a pipe handle
    #  anyway. This is also what makes the -Action tests behave.
    try { if ([Console]::IsOutputRedirected) { return } } catch { return }

    #  The host's own answer, and the one that actually holds on this machine:
    #  Windows PowerShell 5.1 reports SupportsVirtualTerminal = True in both
    #  Windows Terminal and a modern conhost. Trust it before reaching for
    #  P/Invoke - it is the supported API and it cannot throw.
    try {
        if ($Host -and $Host.UI -and $Host.UI.SupportsVirtualTerminal) { $script:Vt = $true; return }
    } catch { }

    #  Older host that has not turned VT on for itself: ask Windows directly.
    try {
        if (-not ([System.Management.Automation.PSTypeName]'ZmQolVt').Type) {
            Add-Type -Namespace '' -Name ZmQolVt -MemberDefinition @'
[DllImport("kernel32.dll", SetLastError=true)] public static extern IntPtr GetStdHandle(int n);
[DllImport("kernel32.dll", SetLastError=true)] public static extern bool GetConsoleMode(IntPtr h, out uint m);
[DllImport("kernel32.dll", SetLastError=true)] public static extern bool SetConsoleMode(IntPtr h, uint m);
'@ -ErrorAction Stop
        }
        $h = [ZmQolVt]::GetStdHandle(-11)
        $m = 0
        if (-not [ZmQolVt]::GetConsoleMode($h, [ref]$m)) { return }
        if (($m -band 0x0004) -eq 0) { [void][ZmQolVt]::SetConsoleMode($h, ($m -bor 0x0004)) }
        $m2 = 0
        if ([ZmQolVt]::GetConsoleMode($h, [ref]$m2) -and (($m2 -band 0x0004) -ne 0)) { $script:Vt = $true }
    } catch { $script:Vt = $false }
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
  Items: @{ Label; Status; StatusColour; Section; Key; Disabled; Hint }
  Hint is one plain sentence saying what choosing that row DOES. It is shown for
  the highlighted row only, on a pinned line above the rule.
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

        # Everything above this point is pinned when the frame has to scroll.
        $headCount = $L.Count
        $selLine   = -1

        foreach ($line in $Intro) {
            if ($line -eq '')                 { $L += ,@( @{ t = ''; c = $C.Text } ) }
            elseif ($line.StartsWith('!'))    { $L += ,@( @{ t = '   ' + $line.Substring(1); c = $C.Warn } ) }
            elseif ($line.StartsWith('~'))    { $L += ,@( @{ t = '   ' + $line.Substring(1); c = $C.Dim } ) }
            else                              { $L += ,@( @{ t = '   ' + $line; c = $C.Text } ) }
        }
        if ($Intro.Count -gt 0) { $L += ,@( @{ t = ''; c = $C.Text } ) }

        # -------------------------------------------------------------------
        #  🛑 v2.2.1 - THE STATUS COLUMN IS MEASURED, NOT A FIXED 38.
        #
        #  User screenshot, 2026-08-22, with an arrow drawn at it: *"Back up my
        #  files first, then install it allrecommended"*. The label is 43
        #  characters and PadRight(38) does nothing to a string already longer
        #  than 38, so the green status started in the very next column with no
        #  space at all. Any label over 38 had the same collision waiting.
        #
        #  So the column is the widest label on THIS screen plus two spaces, and
        #  never less than 38 - which leaves every screen that already fitted
        #  looking exactly as it did, and makes a collision impossible rather
        #  than unlikely.
        # -------------------------------------------------------------------
        $labelCol = 38
        foreach ($it in $Items) {
            $n = ([string]$it.Label).Length
            if ($n + 2 -gt $labelCol) { $labelCol = $n + 2 }
        }

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
            #  [string] and not a bare .PadRight: a row whose Label came back
            #  $null used to end the whole installer with InvokeMethodOnNull.
            #  The Label is table-driven now so it cannot be $null, but a menu
            #  must never be the thing that kills the run.
            $label = ([string]$it.Label).PadRight($labelCol)
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
            if ($i -eq $Sel) { $selLine = $L.Count }
            $L += ,@( @{ t = $marker; c = $C.Title }, @{ t = $label; c = $colour }, @{ t = $status; c = $sc } )
        }

        # -------------------------------------------------------------------
        #  v2.2.6 - THE HIGHLIGHTED ROW EXPLAINS ITSELF.
        #
        #  User, 2026-08-23: *"I didn't like some of the descriptions for some of
        #  the options for the script ... make sure that the descriptions make
        #  sense because some of them don't really do a good job of explaining"*.
        #  Until now a row showed a LABEL and a STATUS and nothing that said what
        #  choosing it would do - the explanation only appeared on the screen
        #  AFTER you had already committed to opening it.
        #
        #  So each item may carry a Hint, and the hint for whatever is currently
        #  highlighted is drawn on its own pinned line just above the rule. It is
        #  pinned rather than inline so it cannot scroll out of view, and it is
        #  one line so the frame grows by exactly one row.
        # -------------------------------------------------------------------
        $hint = ''
        if ($Sel -ge 0 -and $Sel -lt $Items.Count -and $Items[$Sel].Hint) { $hint = [string]$Items[$Sel].Hint }
        if ($hint.Length -gt $Width - 6) { $hint = $hint.Substring(0, [Math]::Max(0, $Width - 7)) + '…' }

        $L += ,@( @{ t = ''; c = $C.Text } )
        $L += ,@( @{ t = '   ' + $hint; c = $C.Title } )
        $L += ,@( @{ t = '   ' + ('─' * 68); c = $C.Frame } )
        $L += ,@( @{ t = $Footer; c = $C.Dim } )
        return @{ Lines = $L; Head = $headCount; Tail = 4; Sel = $selLine }
    }

    <#
      🛑 v2.2.1 - THE FRAME IS MADE TO FIT THE WINDOW; THE WINDOW IS NOT MADE TO
      FIT THE FRAME. This is the flicker fix and the missing-Quit fix, and they
      were always the same bug.

      User, 2026-08-22: *"there's still some weird flickering at the bottom of
      the terminal window ... and also I couldn't see the final quit option at
      the bottom of the script unless i made the window bigger"*, with a
      screenshot of the main menu scrolled so its header was off the top.

      v2.0.5 tried to solve it by GROWING the console (Fit-Console). That works
      in conhost and does nothing in Windows Terminal, which does not implement
      the console resize API - and the screenshot is Windows Terminal. When the
      grow fails the frame is taller than the window, $canPlace goes false, and
      the drawing drops to the sequential path that Clear-Hosts on every keypress
      and lets the buffer scroll: exactly the flash at the bottom, and exactly
      the header scrolling off so the last row is out of view.

      🌟 So the frame is now CUT to the window instead. The six title lines and
      the three closing lines (rule + footer) are pinned; the middle - intro and
      rows - scrolls just far enough to keep the selected row in view, with a
      "more above / more below" marker in the pinned rule. Nothing ever leaves
      the absolute-positioned path, so nothing clears and nothing scrolls, at any
      window size. The console itself is never resized - see the v2.2.3 note at
      the call site for why growing it was making the last row unreachable.
    #>
    function Fit-Frame {
        param($F, [int] $Height)
        $lines = $F.Lines
        if ($Height -lt 8) { return ,$lines }              # absurdly small: draw and let it clip
        if ($lines.Count -le $Height) { return ,$lines }

        $head = $F.Head
        $tail = $F.Tail
        $room = $Height - $head - $tail                    # rows left for the middle
        if ($room -lt 1) { return ,($lines[0..($Height - 1)]) }

        $bodyStart = $head
        $bodyEnd   = $lines.Count - $tail - 1
        $bodyLen   = $bodyEnd - $bodyStart + 1

        # Scroll so the selected row sits inside the window, with one row of lead
        # where there is one.
        $off = 0
        if ($F.Sel -ge 0) {
            $selInBody = $F.Sel - $bodyStart
            if ($selInBody -ge $room) { $off = $selInBody - $room + 2 }
            if ($off -gt $bodyLen - $room) { $off = $bodyLen - $room }
            if ($off -lt 0) { $off = 0 }
        }

        $out = @()
        for ($i = 0; $i -lt $head; $i++) { $out += ,$lines[$i] }
        for ($i = 0; $i -lt $room; $i++) {
            $src = $bodyStart + $off + $i
            if ($src -le $bodyEnd) { $out += ,$lines[$src] } else { $out += ,@( @{ t = ''; c = $C.Text } ) }
        }
        # The pinned rule carries the scroll marker, so no row is spent on it.
        $more = ''
        if ($off -gt 0 -and ($off + $room) -lt $bodyLen) { $more = '  ↑ ↓ more  ' }
        elseif ($off -gt 0)                              { $more = '  ↑ more  ' }
        elseif (($off + $room) -lt $bodyLen)             { $more = '  ↓ more  ' }
        for ($i = $lines.Count - $tail; $i -lt $lines.Count; $i++) {
            $ln = $lines[$i]
            if ($more -ne '' -and $ln.Count -eq 1 -and $ln[0].t -like '   ─*') {
                $bar = $ln[0].t
                $keep = $bar.Length - $more.Length
                if ($keep -gt 4) {
                    $ln = @( @{ t = $bar.Substring(0, $keep); c = $C.Frame }, @{ t = $more; c = $C.Title } )
                }
            }
            $out += ,$ln
        }
        return ,$out
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

        $built = Build-Frame $cur $w

        # ---------------------------------------------------------------
        #  🛑 v2.2.3 - Fit-Console IS NOT CALLED ANY MORE, AND REMOVING IT IS THE
        #  FIX FOR THE HIDDEN "QUIT" ROW.
        #
        #  User, 2026-08-22, after v2.2.1 was supposed to have fixed this:
        #  *"i couldn't see the last quit option until i resized and made the
        #  window bigger"*.
        #
        #  Fit-Console grew the console to fit the frame. On a host that will not
        #  resize its WINDOW it could still succeed in growing the BUFFER - the
        #  two are set separately, and the buffer set comes first because the
        #  window may not exceed it. A buffer taller than the viewport is a
        #  SCROLLBACK: the viewport sits at the bottom of it, so a frame drawn at
        #  buffer rows 0..29 of a 34-row buffer has its top rows scrolled off and
        #  its last rows out of view. That is exactly the reported symptom, and
        #  making the window bigger "fixed" it by letting the viewport show the
        #  whole buffer again.
        #
        #  Fit-Frame already cuts the frame to the window, so growing anything is
        #  pointless as well as harmful. The window is left completely alone now
        #  and the frame is fitted to whatever height the window actually is.
        # ---------------------------------------------------------------
        $frame = Fit-Frame $built $h

        $canPlace = (-not $script:Headless) -and (-not $script:NoKeys) -and ($frame.Count -le $h)

        if (-not $canPlace) {
            # --- plain sequential fallback -----------------------------------
            if (-not $script:Headless) { Clear-Host }
            foreach ($line in $frame) {
                foreach ($seg in $line) { Write-Host $seg.t -ForegroundColor $seg.c -NoNewline }
                Write-Host ''
            }
            if ($script:NoKeys) {
                #  v2.2.6 - belt and braces behind the NoStdin gate above: even
                #  with a real stdin, a stream that answers nothing must not be
                #  able to hold the menu open. Ten unusable answers and it backs
                #  out, and a throw backs out at once.
                $script:BadReads = [int]$script:BadReads + 1
                if ($script:BadReads -gt 10) { return $null }
                Write-Host '   Type the number of what you want, then ENTER. 0 to go back.' -ForegroundColor $C.Dim
                $typed = $null
                try { $typed = Read-Host '   Number' } catch { return $null }
                if ($null -eq $typed -or $typed -eq '0' -or $typed -eq '') { return $null }
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

            # ---------------------------------------------------------------
            #  🛑 v2.2.3 - THE WHOLE FRAME GOES OUT IN **ONE** WRITE.
            #
            #  User, 2026-08-22, after v2.2.1 was supposed to have fixed this:
            #  *"there's still visual inconsistencies with the installer script
            #  like flickering weird stuff when moving"*.
            #
            #  v2.2.1 fixed the SCROLLING (the frame is cut to the window now and
            #  nothing clears between keypresses) and that part held. What it did
            #  not fix is the TEARING, because it still drew the frame as roughly
            #  a hundred separate console calls per keypress - a SetCursorPosition
            #  plus one Write-Host per coloured segment per line. Windows Terminal
            #  repaints on its own clock, so it happily presents a half-drawn
            #  frame; that is the flicker, and no amount of "don't clear" removes
            #  it while the frame arrives in a hundred pieces.
            #
            #  🌟 So the frame is now rendered to a SINGLE string - ANSI colour
            #  codes and one absolute cursor move per line - and pushed with one
            #  [Console]::Out.Write(). One write is one repaint: there is no
            #  intermediate state for the terminal to show.
            #
            #  Falls back to the old per-segment path when the host has no VT
            #  support (see Enable-Vt), so nothing is lost on an old console.
            # ---------------------------------------------------------------
            if ($script:Vt) {
                $sb = New-Object System.Text.StringBuilder
                for ($i = 0; $i -lt $frame.Count; $i++) {
                    $row = $top + $i
                    if ($row -ge ($top + $h)) { break }
                    [void]$sb.Append("$([char]27)[$($row + 1);1H")   # absolute, 1-based
                    $used = 0
                    foreach ($seg in $frame[$i]) {
                        if ($seg.t -eq '') { continue }
                        [void]$sb.Append((Vt-Colour $seg.c)).Append($seg.t)
                        $used += $seg.t.Length
                    }
                    [void]$sb.Append("$([char]27)[0m")
                    if ($used -lt ($w - 1)) { [void]$sb.Append(' ' * (($w - 1) - $used)) }
                }
                try { [Console]::Out.Write($sb.ToString()) } catch { $script:Vt = $false; $placed = $false; continue }
            }
            else {
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
        }

        # ---------------------------------------------------------------
        #  🛑 A RESIZE MUST REDRAW WITHOUT A KEYPRESS.
        #  User, 2026-08-22: *"i couldn't see the last quit option until i
        #  resized and made the window bigger AND THEN MOVED AROUND IN THE MENU
        #  TO REFRESH IT"*. The second half of that sentence is the bug: the loop
        #  blocked in ReadKey, so a resize was not noticed until the next
        #  keypress and the frame stayed cut to the old height. Polling instead
        #  means the window is re-measured about ten times a second and the frame
        #  follows the window on its own.
        # ---------------------------------------------------------------
        $key = $null
        try {
            while (-not [Console]::KeyAvailable) {
                Start-Sleep -Milliseconds 90
                $nw = $w; $nh = $h
                try { $nw = [Console]::WindowWidth; $nh = [Console]::WindowHeight } catch { }
                if ($nw -ne $drawnW -or $nh -ne $drawnH) { $placed = $false; break }
            }
            if (-not $placed) { continue }
            $key = [Console]::ReadKey($true)
        }
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
    #  v2.2.6 - a Read-Host on an exhausted stream returns instantly and forever,
    #  so it is only ever asked where a key genuinely cannot be read AND there is
    #  a real stdin to read from. Otherwise this returns and the run moves on.
    if ($script:NoKeys) { if (-not $script:NoStdin) { [void](Read-Host '   ENTER') }; return }
    try { [void][Console]::ReadKey($true) }
    catch {
        $script:NoKeys = $true
        if (-not $script:NoStdin) { [void](Read-Host '   ENTER') }
    }
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
# =============================================================================
#  CONTROLLER ICON PACKS  -  v2.2.1
# -----------------------------------------------------------------------------
#  User, 2026-08-22: *"also give the option to install/remove both nintendo
#  switch controller & xbox one controller icons ... so you can choose from 3
#  options based off what controller the user uses."*
#
#  Three packs, ONE slot. They all overwrite the same xenonbutton_* .iwi names
#  in storage\t6\images, so only one can be installed at a time and picking a
#  new one removes the old one first (by its own manifest, so nothing that was
#  not put there by this installer is ever touched).
#
#  🛑 EACH PACK HAS A DIFFERENT FOLDER SHAPE, measured from the payload:
#       Dualsense Icons\Images\*.iwi                 20 files
#       Nintendo Switch Icons\t6\images\*.iwi        28 files
#       Xbox One Buttons\t6r\data\images\*.iwi       24 files
#  Plutonium wants them FLAT in storage\t6\images, so the copy must start from
#  the folder that actually holds the .iwi files, never from the pack root -
#  robocopy /E would otherwise recreate "t6\images\" inside the images folder
#  and the game would see nothing. Resolve-IconSource finds that folder.
# =============================================================================
$CONTROLLERS = [ordered]@{
    ps5    = @{ Name = 'PlayStation 5 (DualSense)'; Short = 'PS5';    Folder = 'Dualsense Icons' }
    switch = @{ Name = 'Nintendo Switch';           Short = 'Switch'; Folder = 'Nintendo Switch Icons' }
    xbox   = @{ Name = 'Xbox One';                  Short = 'Xbox';   Folder = 'Xbox One Buttons' }
}

# The folder inside a pack that actually holds the .iwi files. Every pack keeps
# them all in one directory; the deepest one with .iwi in it is that directory.
function Resolve-IconSource {
    param([string] $PackKey)
    $root = Find-Payload $CONTROLLERS[$PackKey].Folder
    if (-not $root) { return $null }
    $iwi = @(Get-ChildItem -LiteralPath $root -File -Recurse -Filter '*.iwi' -ErrorAction SilentlyContinue)
    if ($iwi.Count -eq 0) { return $null }
    $dirs = @($iwi | ForEach-Object { $_.DirectoryName } | Sort-Object -Unique)
    # One directory is the normal case. If a pack ever ships two, take the one
    # with the most files rather than silently copying half of it.
    if ($dirs.Count -eq 1) { return $dirs[0] }
    return (($iwi | Group-Object DirectoryName | Sort-Object Count -Descending)[0]).Name
}

# -----------------------------------------------------------------------------
#  Every filename any pack can overwrite. This is the list the HD texture pack is
#  forbidden to install, the list the icon backup captures, and the list a pack
#  swap has to be able to clear.
#
#  🛑 IT STARTS FROM A CONSTANT, AND THAT IS NOT BELT-AND-BRACES - IT IS THE
#  WHOLE POINT. The icon packs live in Optionals\, the release ZIP does not carry
#  Optionals\, and this list is what stops the texture pack shipping controller
#  art. Deriving it ONLY from the payloads would make it empty for exactly the
#  people who install from the release - and the texture pack would go straight
#  back to deciding their button prompts, which is the bug being fixed.
#
#  The 20 constants are the names the HD texture pack actually contains,
#  measured against Optionals\images. The payloads are then unioned in, so a pack
#  that grows a file (Switch's 8 ui_button_crc_*, Xbox's 4 xenon_stick_*) is
#  covered without this list having to be edited.
# -----------------------------------------------------------------------------
$ICONFILES = @(
    'xenon_controller_top.iwi',
    'xenonbutton_a.iwi','xenonbutton_b.iwi','xenonbutton_x.iwi','xenonbutton_y.iwi',
    'xenonbutton_back.iwi','xenonbutton_start.iwi',
    'xenonbutton_lb.iwi','xenonbutton_rb.iwi','xenonbutton_lt.iwi','xenonbutton_rt.iwi',
    'xenonbutton_ls.iwi','xenonbutton_rs.iwi',
    'xenonbutton_dpad_all.iwi','xenonbutton_dpad_up.iwi','xenonbutton_dpad_down.iwi',
    'xenonbutton_dpad_left.iwi','xenonbutton_dpad_right.iwi',
    'xenonbutton_dpad_ud.iwi','xenonbutton_dpad_rl.iwi'
)
foreach ($k in $CONTROLLERS.Keys) {
    $d = Resolve-IconSource $k
    if ($d) { $ICONFILES += @(Get-ChildItem -LiteralPath $d -File -Filter '*.iwi' | ForEach-Object { $_.Name }) }
}
$ICONFILES = @($ICONFILES | Sort-Object -Unique)

# Which pack is installed right now, or $null. Kept next to the manifests.
$PACKFILE = Join-Path $STATE 'controller-pack.txt'
function Get-ControllerPack {
    if ((Read-Manifest 'controller').Count -eq 0) { return $null }
    if (-not (Test-Path -LiteralPath $PACKFILE)) { return 'ps5' }   # pre-v2.2.1 installs were always PS5
    $lines = @(Get-Content -LiteralPath $PACKFILE -ErrorAction SilentlyContinue)
    $v = $null
    if ($lines.Count -gt 0) { $v = ([string]$lines[0]).Trim() }
    if ($v -and $CONTROLLERS.Contains($v)) { return $v }
    return 'ps5'
}
function Set-ControllerPack {
    param([string] $Key)
    if ($DryRun) { return }
    if (-not (Test-Path $STATE)) { New-Item -ItemType Directory -Force -Path $STATE | Out-Null }
    Set-Content -LiteralPath $PACKFILE -Value $Key -Encoding UTF8
}

# =============================================================================
#  RESHADE  -  one install, four games, four presets  -  v2.2.1
# -----------------------------------------------------------------------------
#  User, 2026-08-22: *"make sure the reshade install option works for all
#  plutonium games not just bo2, and make a reshade preset for bo1, mw3, and waw
#  so each game has it's own reshade preset and whenever you load a specific game
#  it uses the games' specified reshade preset automatically."*
#
#  🛑 THE "AUTOMATICALLY" HALF CANNOT BE DONE, AND THAT IS MEASURED, NOT ASSUMED.
#  All four Plutonium games run as the SAME executable in the SAME folder -
#  ReShade.log, this PC, 16:02:21: *"loaded from ...\Plutonium\bin\dxgi.dll into
#  ...\Plutonium\bin\plutonium-bootstrapper-win32.exe"*, and that one process is
#  the one that renders (the SetFullscreenState calls through to 16:20 are in it).
#  ReShade resolves exactly one ReShade.ini from that folder and reads PresetPath
#  out of it once, at load. Its own string table carries PresetPath,
#  StartupPresetPath and PresetShortcutPaths and nothing per-application, so
#  there is no key that could name a different preset per game.
#
#  🌟 WHAT IS SHIPPED INSTEAD: all four presets go in beside each other, so they
#  are all in ReShade's own preset list and Ctrl+Shift+PgUp / PgDn - already bound
#  in ReShade.ini - steps between them in one keypress. The installer asks which
#  one to START on and writes that to PresetPath.
#
#  🛑 AND THEY ARE NOT COSMETIC VARIANTS. Measured off the import tables:
#  BlackOps.exe, CoDWaW.exe and iw5sp.exe all import d3d9.dll; t6zm.exe imports
#  d3d11.dll and dxgi.dll. The BO2 preset uses LocalContrastCS, which is a
#  compute shader with a __RENDERER__ guard - it cannot run on Direct3D 9 at all.
#  So the three D3D9 presets use only pixel-shader effects from the D3D9-era
#  libraries (SweetFX / GShade): LumaSharpen, Clarity2, Vibrance, Curves.
# =============================================================================
$RESHADEPRESETS = [ordered]@{
    'BO2.ini' = @{ Game = 'Black Ops II';    Api = 'DirectX 11' }
    'BO1.ini' = @{ Game = 'Black Ops';       Api = 'DirectX 9'  }
    'MW3.ini' = @{ Game = 'Modern Warfare 3';Api = 'DirectX 9'  }
    'WAW.ini' = @{ Game = 'World at War';    Api = 'DirectX 9'  }
}

#  Read from the shipped DLL itself so this string can never claim a version the
#  package does not actually contain.
$RESHADEVER = 'ReShade'
try {
    $rsPay = Find-Payload 'reshade'
    if ($rsPay) {
        $rsDll = Join-Path $rsPay 'dxgi.dll'
        if (Test-Path -LiteralPath $rsDll) {
            $v = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($rsDll).ProductVersion
            if ($v) { $RESHADEVER = "ReShade $v" }
        }
    }
} catch { }

$BACKUPSETS = [ordered]@{
    images  = @{ Label = 'My textures';           Title = 'your textures'; Parts = @( @{ Sub='images'; Path=$IMGDIR;  Type='folder' } ) }
    zone    = @{ Label = 'My sounds';             Title = 'your sounds';   Parts = @( @{ Sub='zone';   Path=$ZONEDIR; Type='folder' } ) }
    #  The icon set backs up ONLY the filenames a pack can replace, not the whole
    #  images folder: the HD texture pack already backs that up as a whole and two
    #  folder-wide copies of the same 1GB would be absurd.
    controller = @{ Label = 'My controller icons'; Title = 'your controller icons'
                    Parts = @( @{ Sub='controller'; Path=$IMGDIR; Type='files'; Items=$ICONFILES } ) }
    reshade = @{ Label = 'My ReShade setup';      Title = 'your ReShade setup'; Parts = @(
                    @{ Sub='bin';             Path=$BINDIR; Type='files'; Items=@('ReShade.ini','BO2.ini','BO1.ini','MW3.ini','WAW.ini','dxgi.dll') },
                    @{ Sub='reshade-shaders'; Path=(Join-Path $BINDIR 'reshade-shaders'); Type='folder' } ) }
    #  🛑 THE SETTINGS BACKUP CARRIES SETTINGS, NOT STATS. The rule stands; the
    #  reason written here in v2.2.3 did not, and is corrected below.
    #
    #  v2.2.3 said the black screen was caused by this backup carrying a
    #  `badzmdataddl` - a file it called Plutonium's "I rejected this" marker -
    #  back into place on every restore. That was WRONG. Measurement since:
    #  every mod folder on the install has a `badzmdataddl`, all byte-identical
    #  (md5 a31d9ea4), including mods that boot and play perfectly. It is a
    #  fixed per-mod file, not a fault flag, and it never had anything to do
    #  with the crash. The real cause was `r_aaSamples 16` - see
    #  Repair-BadAaSamples below.
    #
    #  🌟 The rule survives its wrong justification, for a better reason. A
    #  backup set must ENUMERATE what it saves, never take "the folder", because
    #  the game writes into that folder too and a folder-wide copy silently
    #  adopts whatever the game left there. Naming the five settings files is
    #  what makes this backup mean one thing. And it is exactly the shape that
    #  lets Repair-BadAaSamples reach into the backup copy of plutonium_zm.cfg
    #  and disarm it, instead of a restore handing the player back the value
    #  that stopped their game starting.
    mod     = @{ Label = 'The mod + my settings'; Title = 'the mod'; Parts = @(
                    @{ Sub='files';           Path=$MODDIR; Type='folder' },
                    @{ Sub='settings';        Path=$CFGDIR; Type='files'
                       Items=@('plutonium_zm.cfg','bindings_zm.bdg','hardware_zm.chp','user_zm.cgp','user_common.cgp') } ) }
}

# ---------------------------------------------------------------------------
#  Stats files the game writes into players\mods\<id>\. NONE of them are ever
#  backed up or restored - see the note in $BACKUPSETS.mod above. That rule is
#  still right, and it is right for the ordinary reason: this installer does not
#  own the player's progress and must not carry copies of it around.
#
#  🛑 CORRECTION, v2.2.4 - `badzmdataddl` IS NOT A REJECT MARKER.
#
#  v2.2.3 shipped a "condemned stats" self-heal built on the belief that this
#  file appears when Plutonium rejects a stats file as corrupt. That belief was
#  wrong, and it was disproved by measurement: EVERY mod folder on the test
#  install carries a `badzmdataddl`, all of them byte-identical (md5 a31d9ea4),
#  including the mods that boot and play perfectly. It is a fixed file the game
#  drops in every per-mod player folder, not a fault flag.
#
#  The self-heal that read it has been REMOVED. It was moving the player's real
#  zmStats and zmdatabk0000 aside on every single install - wiping progress to
#  cure a problem that never existed. The real cause of the black screen is
#  below.
# ---------------------------------------------------------------------------
$STATSFILES  = @('zmStats','zmleaderboards','zmdatabk0000','zmdatabk0001','zmdatabk0002')

<#
  🛑 THE REAL CAUSE OF THE BLACK SCREEN: r_aaSamples.

  Symptom - the mod loads from the in-game Mods menu, the screen goes black and
  the game hard-freezes. console_zm.log ends:

      Reading stats... / Reading backup stats...
      COM_ERROR (0) E_INVALIDARG ... (-2147024809) @ 0x74C0E0

  Cause - GRAPHICS BOOST wrote `r_aaSamples 16`. That dvar is LATCHED, so it is
  applied by the renderer restart that happens as the mod loads, before any of
  the mod's script runs. 16x MSAA is not a sample count the hardware can create,
  so device creation fails with E_INVALIDARG and the frontend dies.

  Measured, not reasoned:
    · the boot-time dvar dump in console_zm.log reports  r_aaSamplesMax "8"
    · the game's own menu offers 1 / 2 / 4 / 8 and nothing above that
    · five mod loads out of five crashed; zm_qol was the only mod on the install
      whose config carried "16" - every mod that booted carried "4"

  The mod itself no longer writes 16 (it reads r_aaSamplesMax now). But a value
  already saved in plutonium_zm.cfg will still kill the next launch on its own,
  because the config is exec'd long before any script runs. So the installer has
  to be able to take it back out - in the live config AND in the settings backup,
  which is otherwise a loaded gun aimed at the next "put back".
#>
$AAVALID    = @(1,2,4,8)
$AAFALLBACK = 4

function Get-CfgAaSamples {
    param([string] $Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try { $raw = [IO.File]::ReadAllText($Path) } catch { return $null }
    $m = [regex]::Match($raw, '(?m)^[ \t]*seta[ \t]+r_aaSamples[ \t]+"?(-?\d+)"?')
    if (-not $m.Success) { return $null }
    return [int] $m.Groups[1].Value
}

function Get-AaCfgTargets {
    return @(
        (Join-Path $CFGDIR 'plutonium_zm.cfg'),
        (Join-Path $BACKUPS 'mod\settings\plutonium_zm.cfg')
    )
}

function Test-BadAaSamples {
    foreach ($p in (Get-AaCfgTargets)) {
        $v = Get-CfgAaSamples $p
        if ($null -ne $v -and -not ($AAVALID -contains $v)) { return $true }
    }
    return $false
}

<#
  Rewrite ONLY the r_aaSamples line, in place, byte-for-byte everywhere else.
  Reading and rewriting the whole file through Get-Content/Set-Content would
  rewrite every line ending too - the mistake that cost 150 bytes of ReShade.ini
  in v2.2.1 (ERROR_CATALOGUE 21). A raw regex on the whole text cannot do that.
#>
function Repair-BadAaSamples {
    $fixed = 0
    foreach ($p in (Get-AaCfgTargets)) {
        $v = Get-CfgAaSamples $p
        if ($null -eq $v -or ($AAVALID -contains $v)) { continue }

        Say ("Anti-aliasing was saved as {0}x, which the game cannot start with." -f $v) $C.Warn
        Say "That is what made the mod load to a black screen - setting it back." $C.Dim
        if ($DryRun) { Say "(dry run - nothing changed)" $C.Dim; continue }

        try {
            $raw = [IO.File]::ReadAllText($p)
            $new = [regex]::Replace($raw,
                                    '(?m)^([ \t]*seta[ \t]+r_aaSamples[ \t]+)"?-?\d+"?',
                                    ('${1}"' + $AAFALLBACK + '"'))
            [IO.File]::WriteAllText($p, $new, (New-Object System.Text.UTF8Encoding($false)))
            $fixed++
            Write-Log "repaired r_aaSamples $v -> $AAFALLBACK in $p"
        } catch {
            Say "Could not change it - close Plutonium and run this again." $C.Bad
            Write-Log "could not repair r_aaSamples in ${p}: $_" 'warn'
        }
    }

    if ($fixed -gt 0) {
        Say ("Set back to {0}x MSAA in {1} file(s). The mod picks a safe value itself now." -f $AAFALLBACK, $fixed) $C.Good
    }
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

# ---------------------------------------------------------------------------
#  v2.2.1 - "dualsense" became "controller" when the Switch and Xbox packs were
#  added. Anyone who installed the PS5 icons under v2.2.0 has an
#  installed-dualsense.txt manifest and possibly a backups\dualsense folder, and
#  both must carry over or their icons become un-removable and their originals
#  un-restorable. Renamed once, in place; nothing is copied twice and nothing is
#  deleted. Safe to run every launch - it does nothing once the old names are
#  gone, and it never overwrites a new-name file that already exists.
# ---------------------------------------------------------------------------
function Move-OldDualsense {
    if ($DryRun) { return }
    try {
        $old = Join-Path $STATE 'installed-dualsense.txt'
        $new = Join-Path $STATE 'installed-controller.txt'
        if ((Test-Path -LiteralPath $old) -and -not (Test-Path -LiteralPath $new)) {
            Move-Item -LiteralPath $old -Destination $new -Force
            Set-Content -LiteralPath $PACKFILE -Value 'ps5' -Encoding UTF8
            Write-Log 'migrated installed-dualsense.txt -> installed-controller.txt (pack=ps5)'
        }
        $ob = Join-Path $BACKUPS 'dualsense'
        $nb = Join-Path $BACKUPS 'controller'
        if ((Test-Path -LiteralPath $ob) -and -not (Test-Path -LiteralPath $nb)) {
            Move-Item -LiteralPath $ob -Destination $nb -Force
            Write-Log 'migrated backups\dualsense -> backups\controller'
        }
    } catch { Write-Log "could not migrate the dualsense names: $_" 'warn' }
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
    # -----------------------------------------------------------------------
    #  THE BLOCKLIST - decided BEFORE the copy, never after.
    #
    #  v2.1.3, hud_dpad_blood.iwi: the blood splat behind the points and ammo in
    #  the bottom right. User, 2026-08-20, two screenshots: *"the points text on
    #  the hud there is being overlapped by the blood."*
    #  🌟 MEASURED, not judged by eye. Both copies are 256x128 - the pack's is
    #  not an upscale of anything - and decoding both to alpha shows they are
    #  DIFFERENT ARTWORK: stock is a compact blob with scattered droplets, mean
    #  alpha 27.7, while the pack's is one splat filling almost the whole frame
    #  plus two ring droplets at the upper left, mean alpha 31.8. Every OTHER
    #  hud_dpad_* texture in the pack matches stock's alpha to within 0.5, so
    #  they are the same art re-encoded and they stay.
    #
    #  v2.2.1, THE CONTROLLER ICONS. User, 2026-08-22: *"make sure the base mode
    #  doesn't install any controller icons if i did include any in the original
    #  texture pack images folder, so you can choose from 3 options based off
    #  what controller the user uses."*  🌟 Measured: the HD texture pack ships
    #  exactly the 20 shared xenonbutton_* / xenon_controller_top names, which is
    #  every name the PS5 pack replaces. Leaving them in meant the texture pack
    #  silently decided your button prompts. Now the base install ships NO
    #  controller art at all - the game falls back to its own - and the three
    #  packs are the only thing that changes it.
    #
    #  🛑 EXCLUDED AT THE ROBOCOPY, not deleted afterwards. The old post-copy
    #  delete would have removed a pack's freshly-installed icons off the disk
    #  and then relied on the re-apply to put them back; not copying them at all
    #  cannot get that wrong, and it is faster.
    # -----------------------------------------------------------------------
    $blocked = @()
    if ($Kind -eq 'images') { $blocked = @('hud_dpad_blood.iwi') + $ICONFILES }
    $blockLower = @{}
    foreach ($b in $blocked) { $blockLower[$b.ToLower()] = $true }

    $files = @(Get-ChildItem -LiteralPath $Source -File -Recurse | Where-Object { -not $blockLower.ContainsKey($_.Name.ToLower()) })
    $size = ($files | Measure-Object Length -Sum).Sum
    Say ("Copying {0} file(s), {1} ..." -f $files.Count, (Format-Size $size)) $C.Text
    if ($DryRun) {
        Say "   (dry run - not copied)" $C.Dim
        return $true
    }
    if (-not (Test-Path $Dest)) { New-Item -ItemType Directory -Force -Path $Dest | Out-Null }
    $xf = @()
    if ($blocked.Count -gt 0) { $xf = @('/XF') + $blocked }
    $r = robocopy $Source $Dest /E /NFL /NDL /NJH /NJS /NP @xf
    if ($LASTEXITCODE -ge 8) { Say "Copy FAILED - close Plutonium and try again." $C.Bad; return $false }
    $rel = @($files | ForEach-Object { $_.FullName.Substring($Source.Length).TrimStart('\') })

    if ($Kind -eq 'images' -and $blocked.Count -gt 0) {
        Say ("Left out {0} file(s): the HUD blood splat, and all controller icons." -f $blocked.Count) $C.Dim
        Say "Pick your button prompts under  Controller icons." $C.Dim
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

    # -----------------------------------------------------------------------
    #  🛑 v2.2.1 - THE SOUNDS ROW IS MANIFEST-FIRST NOW, LIKE THE TEXTURES ROW.
    #
    #  User, 2026-08-22: *"if I for example install the whole mod, then go to
    #  uninstall everything, it'll still say custom sounds are installed, but
    #  then when I choose the option for uninstalling/removing the sounds
    #  specifically it says it's already removed."*
    #
    #  🌟 MEASURED, out of this installer's own log rather than reasoned about:
    #      14:13:30  action: remove sounds (restore)
    #      14:13:30  Removed 3 file(s).
    #      14:13:31  remove everything finished: ... sounds=True ...
    #      14:13:42  action: remove sounds (plain)
    #                No record of anything installed by this installer.
    #  The RESTORE row does exactly what it promises - it deletes our three files
    #  and then copies the player's own three back, under the same three names.
    #  This row was reading FILE PRESENCE, so it saw three files and said
    #  "installed"; removal reads the MANIFEST, which had just been deleted, so it
    #  said "no record". Both were right and the pair was nonsense.
    #
    #  So: the manifest decides whether it is OURS, exactly as the textures row
    #  has always done, and files that are there but not ours say so out loud
    #  instead of claiming the mod installed them.
    # -----------------------------------------------------------------------
    $sndMan = Read-Manifest 'zone'
    if ($sndMan.Count -gt 0) { $s.Sounds = 'installed'; $s.SoundsOn = $true }
    else {
        $have = 0
        foreach ($f in $SOUNDFILES) { if (Test-Path (Join-Path $ZONEDIR $f)) { $have++ } }
        if ($have -gt 0) {
            $word = 'files'; if ($have -eq 1) { $word = 'file' }
            $s.Sounds = "$have $word already there (not mine)"
        } else { $s.Sounds = 'not installed' }
        $s.SoundsOn = $false
    }

    $ctlMan  = Read-Manifest 'controller'
    $ctlPack = Get-ControllerPack
    if ($ctlMan.Count -gt 0 -and $ctlPack) {
        $s.Controller = "$($CONTROLLERS[$ctlPack].Short) - $($ctlMan.Count) icons installed"
        $s.ControllerOn = $true
        $s.ControllerPack = $ctlPack
    } else {
        $s.Controller = "none - the game's own"
        $s.ControllerOn = $false
        $s.ControllerPack = $null
    }

    # -----------------------------------------------------------------------
    #  🛑 v2.2.7 - THE ROW SAID "INSTALLED" WHILE THERE WAS NO RESHADE ON DISK.
    #
    #  User, 2026-08-24: *"It even says 'reshade 6.7.3 installed', you're a liar
    #  i opened the game no reshade anywhere to be found."* They were right, and
    #  it was measured, not argued: the installer copied 862 files at 13:33:37,
    #  the game ran, and %LOCALAPPDATA%\Plutonium\bin then held NO dxgi.dll, no
    #  ReShade.ini and no presets - only the reshade-shaders FOLDER. Every
    #  surviving loose file in there was Plutonium's own.
    #
    #  🌟 THE MECHANISM: Plutonium's launcher clears loose files it does not own
    #  out of bin when it updates itself. Subfolders are left alone, which is
    #  why reshade-shaders survived and dxgi.dll did not.
    #
    #  🛑 SO THE MANIFEST IS NOT EVIDENCE. v2.2.4 made this row manifest-first
    #  to fix the opposite bug (a present ReShade the installer disowned), and
    #  went too far the other way: a record of having installed it is not the
    #  same as it being there. THE ROW REPORTS WHAT IS ON DISK. The manifest is
    #  only used to say whose it is.
    #
    #    manifest + dll   ->  ours, and present
    #    manifest, no dll ->  ours, and Plutonium wiped it. Says so, and says
    #                         what to do, because this is the state the user hit.
    #    dll, no manifest ->  someone else's, left alone
    #    neither          ->  not installed
    # -----------------------------------------------------------------------
    $rshMan = Read-Manifest 'reshade'
    $rshDll = Join-Path $BINDIR 'dxgi.dll'
    $rshHas = Test-Path $rshDll
    $rshVer = $null
    if ($rshHas) {
        try { $rshVer = (Get-Item -LiteralPath $rshDll).VersionInfo.ProductVersion } catch { $rshVer = $null }
    }
    $rshTag = 'ReShade'; if ($rshVer) { $rshTag = "ReShade $rshVer" }

    if ($rshMan.Count -gt 0 -and $rshHas) {
        $s.ReShade = "$rshTag installed"; $s.ReShadeOn = $true
    } elseif ($rshMan.Count -gt 0) {
        $s.ReShade = 'gone from Plutonium - install again'; $s.ReShadeOn = $true; $s.ReShadeGone = $true
    } elseif ($rshHas) {
        $s.ReShade = "$rshTag already there (not mine)"; $s.ReShadeOn = $false
    } else {
        $s.ReShade = 'not installed'; $s.ReShadeOn = $false
    }

    $s.Settings = (Test-Path $CFGDIR)

    $n = 0
    foreach ($k in $BACKUPSETS.Keys) { if (Has-Backup $k) { $n++ } }
    if ($n -eq 0) { $s.Backups = 'nothing backed up yet'; $s.BackupsColour = $C.Dim }
    else {
        $word = 'things'; if ($n -eq 1) { $word = 'thing' }
        $s.Backups = "$n of $($BACKUPSETS.Count) $word backed up"; $s.BackupsColour = $C.Good
    }
    #  v2.2.6 - the one-line status for the collapsed REMOVE row. It has to say
    #  whether there is anything to uninstall at all, because that row no longer
    #  shows the five individual statuses that used to answer it on sight.
    $installed = 0
    foreach ($on in @($s.ModOn, $s.ImagesOn, $s.SoundsOn, $s.ReShadeOn, $s.ControllerOn)) {
        if ($on) { $installed++ }
    }
    if ($installed -eq 0) { $s.RemoveHint = 'nothing installed' }
    elseif ($installed -eq 1) { $s.RemoveHint = '1 part installed' }
    else { $s.RemoveHint = "$installed parts installed" }

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
    Repair-BadAaSamples

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
    #  PUT YOUR CONTROLLER ICONS BACK IF A PACK IS INSTALLED.
    #
    #  🛑 The texture pack no longer CONTAINS any controller art (see the
    #  blocklist in Copy-Payload), so the copy above cannot overwrite them any
    #  more. This is still needed for one reason: an install is a SYNC, and the
    #  purge below deletes anything the PREVIOUS images manifest listed that this
    #  one does not - which, for anyone upgrading from v2.2.0 or earlier, is
    #  exactly those 20 icon filenames. So the purge can still take a pack's
    #  icons with it, once, and this puts them straight back.
    # ------------------------------------------------------------------------
    $pack = Get-ControllerPack
    if ($pack) {
        $iconSrc = Resolve-IconSource $pack
        if ($iconSrc) {
            Write-Host ''
            Say ("Re-applying your {0} controller icons ..." -f $CONTROLLERS[$pack].Short) $C.Text
            [void](Copy-Payload $iconSrc $IMGDIR 'controller')
        } else {
            Write-Host ''
            Say ("Your {0} icons may have been removed and that pack is not in this folder to re-apply." -f $CONTROLLERS[$pack].Short) $C.Warn
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

<#
  🛑 THE RESHADE PAYLOAD IS PINNED TO 6.7.3. DO NOT "UPDATE" IT.

  v2.2.1 moved it to 6.8.0. On this install 6.8.0 NEVER LOADED - not once, in
  any session it was present. That is not an inference; ReShade writes
  ReShade.log next to its own DLL at process attach, and across every launch
  with 6.8.0 in bin no ReShade.log was ever created anywhere on the machine.
  Putting 6.7.3 back produced one immediately:

      20:58:03 | INFO | Initializing crosire's ReShade version '6.7.3.2149'
      (32-bit) loaded from '...\Plutonium\bin\dxgi.dll'
      into '...\Plutonium\bin\plutonium-bootstrapper-win32.exe'

  41 KB of log, zero errors, and the preset files came back modified - so it
  loaded, ran, and saved.

  📝 WHY 6.8.0 does not attach is NOT known. Both DLLs are valid 32-bit builds
  with the same exports (CreateDXGIFactory / 1 / 2, D3D11CreateDeviceAndSwapChain)
  and the same import set; neither the launcher nor the bootstrapper calls
  SetDefaultDllDirectories, and dxgi is not a KnownDLL on this machine, so the
  application-directory copy is reachable either way. Checked, and it explains
  nothing. The version is the only variable that moved.

  So this is pinned by MEASUREMENT, not by preference. If it is ever raised
  again, the test is one launch and one question: is there a ReShade.log in
  Plutonium\bin afterwards?
#>
function Act-InstallReShade {
    param([int] $Pick = -1)
    $src = Find-Payload 'reshade'
    if (-not $src) {
        Draw-Header 'ReShade'
        Say "The ReShade files are not in this package." $C.Warn
        Pause-Key; return
    }
    $intro = @(
        "ReShade adds a sharpening / colour pass on top of the game. Press END in",
        "game to open it. This installs ReShade $RESHADEVER and four presets, one",
        "per Plutonium game.",
        '',
        "~ONE ReShade serves all four games. Plutonium runs Black Ops II, Black",
        "~Ops, MW3 and World at War through the same program folder, so they share",
        "~one ReShade and one settings file - which is why the preset has to be",
        "~picked rather than detected. All four are installed either way and",
        "~Ctrl+Shift+PgUp / PgDn steps between them in game.",
        '',
        "~BO1, MW3 and WaW are DirectX 9 games and BO2 is DirectX 11, so their",
        "~presets use different effects. Do not point a DirectX 9 game at the BO2",
        "~preset - half of it cannot run there.",
        '',
        "~Goes to:  $BINDIR",
        "~Nothing is left running in the background.",
        '',
        "!⚠️   YOUR EXISTING ReShade.ini AND PRESETS ARE KEPT AS .backup FILES",
        "~     Shader files you already have are added to, never deleted."
    )
    $items = @()
    foreach ($g in $RESHADEPRESETS.Keys) {
        $row = @{ Key = $g; Label = "Install, and start on the $($RESHADEPRESETS[$g].Game) preset" }
        if ($g -eq 'BO2.ini') { $row.Status = 'recommended'; $row.StatusColour = $C.Good }
        $items += $row
    }
    $items += @{ Key='back'; Label='Cancel' }
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'ReShade' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }
    $startPreset = $sel.Key

    Draw-Header 'ReShade'
    Write-Log "action: install reshade (start preset $startPreset)"
    # Remember the values that belong to THIS PC before the copy replaces them.
    $keepShots = Get-IniValue 'SavePath'
    $keepFont  = Get-IniValue 'Font'

    # 🛑 NEVER overwrite a .backup that already exists. Installing twice used to
    #    copy the config THIS INSTALLER wrote over the top of the .backup, which
    #    destroyed the only copy of the user's original settings. The first
    #    backup is the real one; a later run must leave it alone.
    foreach ($f in @('ReShade.ini') + @($RESHADEPRESETS.Keys)) {
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
        if ($startPreset -and $startPreset -ne 'BO2.ini') {
            Set-ReShadeValue 'PresetPath' ".\$startPreset"
        }
        Write-Host ''
        Say ("✅  {0} installed, starting on the {1} preset." -f $RESHADEVER, $RESHADEPRESETS[$startPreset].Game) $C.Good
        Say "In game: END opens the ReShade menu, Numpad 0 turns the effects off and on," $C.Dim
        Say "and Ctrl+Shift+PgUp / PgDn steps through the four presets." $C.Dim
        Write-Host ''
        Say "Heads up: Plutonium's launcher clears loose files it does not own out of its" $C.Warn
        Say "bin folder when it updates itself, and ReShade's dxgi.dll is a loose file" $C.Warn
        Say "there. If ReShade stops showing up, run this option again - it is a re-copy," $C.Warn
        Say "not a repair, and it takes a second." $C.Warn
    }
    Pause-Key
}

# =============================================================================
#  CONTROLLER ICONS  -  three packs, one slot  -  v2.2.1
# -----------------------------------------------------------------------------
#  User, 2026-08-22: *"also give the option to install/remove both nintendo
#  switch controller & xbox one controller icons ... so you can choose from 3
#  options based off what controller the user uses."*
#
#  All three packs write the same xenonbutton_* / xenon_controller_top .iwi names
#  into storage\t6\images, so exactly one can be in effect at a time. Picking a
#  pack therefore REMOVES the previous one first, by that pack's own manifest, so
#  nothing this installer did not put there is ever deleted - and the two packs
#  that carry extra files (Switch adds 8 ui_button_crc_* , Xbox adds 4
#  xenon_stick_*) cannot leave strays behind when you switch away from them.
#
#  🌟 The HD texture pack no longer ships controller art at all, so the base
#  install leaves the game's own icons alone and these three are the only thing
#  that changes them. See the blocklist in Copy-Payload.
# =============================================================================
function Show-ControllerStatusLine {
    param([string] $Key)
    $man  = Read-Manifest 'controller'
    $pack = Get-ControllerPack
    if ($pack -eq $Key) { return @{ Text = "installed - $($man.Count) files"; Colour = $C.Good } }
    $src = Resolve-IconSource $Key
    if (-not $src) { return @{ Text = 'not in this download'; Colour = $C.Off; Disabled = $true } }
    $n = @(Get-ChildItem -LiteralPath $src -File -Filter '*.iwi').Count
    return @{ Text = "$n icons"; Colour = $C.Dim }
}

function Act-InstallController {
    param([int] $Pick = -1)

    while ($true) {
        $pack = Get-ControllerPack
        $any  = $false
        foreach ($k in $CONTROLLERS.Keys) { if (Resolve-IconSource $k) { $any = $true } }
        if (-not $any) {
            Draw-Header 'Controller icons'
            Say "No controller icon packs are in this download, so there is nothing to install." $C.Warn
            Pause-Key; return
        }

        $intro = @(
            "Replaces the button prompts the game draws with the ones for your",
            "controller. Pick one - they all replace the same files, so the one you",
            "pick is the one you get.",
            '',
            "~Goes to:  $IMGDIR",
            "~The HD texture pack does not touch these, so installing it later",
            "~will not undo your choice."
        )
        if ($pack) {
            $intro += ''
            $intro += "~Installed now:  $($CONTROLLERS[$pack].Name). Picking another swaps it over."
        }

        $items = @()
        foreach ($k in $CONTROLLERS.Keys) {
            $st = Show-ControllerStatusLine $k
            $row = @{ Key = $k; Label = $CONTROLLERS[$k].Name; Status = $st.Text; StatusColour = $st.Colour }
            if ($st.Disabled) { $row.Disabled = $true }
            $items += $row
        }
        $items += @{ Key='back'; Label='Cancel' }

        if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Controller icons' $items -Intro $intro }
        if (-not $sel -or $sel.Key -eq 'back') { return }

        Install-ControllerPack $sel.Key
        if ($Pick -ge 0) { return }
    }
}

<#
  Install one pack. Backs the player's own icons up first if they have never
  been backed up (Backup-Thing keeps the OLDER backup, which is the one taken
  before this installer first touched the folder), then removes whatever pack
  is currently in place, then copies.
#>
function Install-ControllerPack {
    param([string] $Key)

    $src = Resolve-IconSource $Key
    Draw-Header "Controller icons - $($CONTROLLERS[$Key].Name)"
    Write-Log "action: install controller ($Key)"
    if (-not $src) {
        Say "That pack is not in this download." $C.Warn
        Pause-Key; return
    }

    # The player's ORIGINAL icons, before any pack. Only taken once, ever.
    [void](Backup-Thing 'controller')

    # Swap, not stack: clear the pack that is there so its extra files go too.
    $old = Get-ControllerPack
    if ($old -and $old -ne $Key) {
        Say ("Removing the {0} icons first ..." -f $CONTROLLERS[$old].Short) $C.Text
        [void](Remove-ByManifest 'controller' $IMGDIR)
    }

    if (Copy-Payload $src $IMGDIR 'controller') {
        Set-ControllerPack $Key
        Write-Host ''
        Say ("✅  {0} controller icons installed." -f $CONTROLLERS[$Key].Name) $C.Good
    }
    Pause-Key
}

function Act-RemoveController {
    param([int] $Pick = -1)
    $pack = Get-ControllerPack
    $hasB = Has-Backup 'controller'
    $intro = @(
        "Removes only the controller icon files this installer put there.",
        "~The game goes back to drawing its own button prompts."
    )
    if ($pack) {
        $intro = @("Removes the $($CONTROLLERS[$pack].Name) icons this installer put there.") + $intro[1..($intro.Count - 1)]
    }
    $items = @()
    if ($hasB) { $items += @{ Key='restore'; Label='Remove them and put my originals back'; Status='backup found'; StatusColour=$C.Good } }
    $items += @{ Key='plain'; Label='Just remove them' }
    $items += @{ Key='back';  Label='Cancel' }
    if ($Pick -ge 0) { $sel = $items[$Pick] } else { $sel = Show-Menu 'Remove the controller icons' $items -Intro $intro }
    if (-not $sel -or $sel.Key -eq 'back') { return }

    Draw-Header 'Remove the controller icons'
    Write-Log "action: remove controller ($($sel.Key))"
    $did = Remove-ByManifest 'controller' $IMGDIR
    if (-not $DryRun) { Remove-Item -LiteralPath $PACKFILE -Force -ErrorAction SilentlyContinue }
    if ($sel.Key -eq 'restore') { [void](Restore-Thing 'controller') }
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
    foreach ($f in @('ReShade.ini') + @($RESHADEPRESETS.Keys)) {
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
    #  The controller icons go with everything else. Leaving 20-odd files behind
    #  after "remove everything" is exactly the class of thing the raw LUI leak
    #  turned out to be.
    $dsHasB  = Has-Backup 'controller'
    $anyB    = ($imgHasB -or $sndHasB -or $dsHasB)

    $intro = @(
        "Removes every part of this package, one after the other:",
        "~   HD textures  ·  custom sounds  ·  controller icons  ·  ReShade  ·  the mod",
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
    # Act-RemoveController has no 'restore' row when there is no icon backup, so
    # its pick index shifts exactly the way the other two do.

    $wasQuiet = $script:Quiet
    if (-not $script:Headless) { Clear-Host }
    $script:Quiet = $true
    try {
        Act-RemoveImages  -Pick $imgPick
        Act-RemoveSounds  -Pick $sndPick
        Act-RemoveController -Pick $dsPick
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
        @{ n='Controller icons'; v=$st.Controller; on=$st.ControllerOn },
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
        # -------------------------------------------------------------------
        #  🛑 v2.2.1 - THE LABEL COMES FROM THE TABLE, NOT FROM A switch HERE.
        #
        #  User screenshot, 2026-08-22: opening this screen ended the installer
        #  with "You cannot call a method on a null-valued expression",
        #  InvokeMethodOnNull. v2.2.0 added a FIFTH backup set - dualsense - to
        #  $BACKUPSETS and did not add a fifth arm to the switch that used to
        #  live here, so $label came back $null for that row, and Show-Menu's
        #  $it.Label.PadRight(38) threw on it. The status line even said so:
        #  "4 of 5 things backed up".
        #
        #  A second list of names that has to be kept in step with the first is
        #  the bug. There is only one list now: $BACKUPSETS carries its own
        #  Label, so adding a set cannot leave a row without one.
        # -------------------------------------------------------------------
        $items = @()
        foreach ($k in $BACKUPSETS.Keys) {
            $st = Get-BackupStatus $k
            $items += @{ Key=$k; Label=$BACKUPSETS[$k].Label; Status=$st.Text; StatusColour=$st.Colour }
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
    Say "Controller     $($st.Controller)" $C.Text -NoLog
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
        "Installs these four, one after the other:",
        "~   the mod  ·  HD texture pack  ·  custom sounds  ·  ReShade",
        '',
        "~Controller icons are NOT included - they are a choice between three",
        "~pads, so that row is left for you.",
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
    #  v2.2.6 - Controller icons are NOT one of the four steps this function
    #  runs, so listing them here made a green "installed" look like something
    #  this action had just done - or a grey "not installed" look like it had
    #  failed. They are reported separately, below, as the choice they are.
    $rows = @(
        @{ n='The mod';         v=$st.Mod;     on=$st.ModOn },
        @{ n='HD texture pack'; v=$st.Images;  on=$st.ImagesOn },
        @{ n='Custom sounds';   v=$st.Sounds;  on=$st.SoundsOn },
        @{ n='ReShade';         v=$st.ReShade; on=$st.ReShadeOn }
    )
    foreach ($r in $rows) {
        $col = $C.Warn
        if ($r.on) { $col = $C.Good }
        Say ($r.n.PadRight(20) + $r.v) $col -NoLog
    }
    Write-Host ''
    if (-not $st.ControllerOn) {
        Say 'Controller icons were not part of this - pick that row if you want them.' $C.Dim -NoLog
        Write-Host ''
    }
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

# ---------------------------------------------------------------------------
#  v2.2.6 - THE UNINSTALL LIST MOVED OFF THE FRONT SCREEN.
#
#  User, 2026-08-23: *"i like the way the installer looks but there's a few
#  things that could be adjusted to look a tiny bit better / function slightly
#  more efficiently"*, with a screenshot whose MORE section - Quit included -
#  was below the fold behind a "↓ more" marker.
#
#  🌟 THAT WAS A HEIGHT PROBLEM AND IT IS MEASURABLE. The main menu was 34
#  printed lines: 6 header + (2+6) INSTALL + (2+6) REMOVE + (2+1) BACKUP +
#  (2+3) MORE + 4 tail. The window in the screenshot is 1123x654, which is 30
#  rows in the shipped font - so four rows had nowhere to go, and Quit was one
#  of them. Fit-Frame scrolls rather than clipping, so nothing was ever lost,
#  but you had to drive down to reach the exit.
#
#  Six removal rows collapse to one and the menu is 29 lines, which fits a
#  default console with the new hint line already counted. Nothing is taken
#  away - every one of the six is on this screen, one keypress further in - and
#  uninstalling is the rarest thing anyone comes here to do, so it is the right
#  thing to move.
# ---------------------------------------------------------------------------
function Remove-Menu {
    while ($true) {
        $st = Get-Status

        $modColour = $C.Dim; if ($st.ModOn) { $modColour = $C.Good }
        $imgColour = $C.Dim; if ($st.ImagesOn) { $imgColour = $C.Good }
        $sndColour = $C.Dim; if ($st.SoundsOn) { $sndColour = $C.Good }
        $rshColour = $C.Dim; if ($st.ReShadeOn) { $rshColour = $C.Good }
        if ($st.ReShadeGone) { $rshColour = $C.Warn }   # v2.2.7 - a record with no files is not "installed"
        $dsColour  = $C.Dim; if ($st.ControllerOn) { $dsColour = $C.Good }

        $intro = @(
            'Only what is actually installed can be removed - a greyed status',
            '~means there is nothing there to take off.',
            '',
            '~Removing a pack puts your own files back if a backup was taken.'
        )

        $items = @(
            @{ Key='rall';    Label='EVERYTHING - the whole package'; Status='textures + sounds + ReShade + mod'; StatusColour=$C.Title
               Hint='Takes it all back off and puts your own files back where a backup exists.' },
            @{ Key='rimages'; Label='Remove the HD textures';       Status=$st.Images;  StatusColour=$imgColour
               Hint='Deletes the texture pack only. The game goes back to its own textures.' },
            @{ Key='rsounds'; Label='Remove the custom sounds';     Status=$st.Sounds;  StatusColour=$sndColour
               Hint='Deletes the sound pack only. The game goes back to its own audio.' },
            @{ Key='rreshade';Label='Remove ReShade';               Status=$st.ReShade; StatusColour=$rshColour
               Hint='Deletes ReShade and its presets. Nothing else is affected.' },
            @{ Key='rcontroller'; Label='Remove the controller icons'; Status=$st.Controller; StatusColour=$dsColour
               Hint='Puts the standard Xbox button prompts back.' },
            @{ Key='rmod';    Label='Remove the mod';               Status=$st.Mod;     StatusColour=$modColour
               Hint='Deletes the mod. Your saved menu settings and stats are kept.' },
            @{ Key='back';    Label='Back'
               Hint='Returns to the main menu. Nothing is removed.' }
        )

        $sel = Show-Menu 'Uninstall' $items -Intro $intro
        if (-not $sel -or $sel.Key -eq 'back') { return }

        switch ($sel.Key) {
            'rall'        { Act-RemoveEverything }
            'rimages'     { Act-RemoveImages }
            'rsounds'     { Act-RemoveSounds }
            'rreshade'    { Act-RemoveReShade }
            'rcontroller' { Act-RemoveController }
            'rmod'        { Act-RemoveMod }
        }
    }
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

        #  The black-screen warning. Loud, because the symptom points at the mod
        #  and the cause is one saved graphics value - see Repair-BadAaSamples.
        if (Test-BadAaSamples) {
            $intro += "!⚠️   A SAVED GRAPHICS SETTING WILL BLACK-SCREEN THE GAME."
            $intro += "!     16x anti-aliasing was written by an older build of this mod"
            $intro += "!     and the game cannot start with it. Pick  The mod  below and"
            $intro += "!     it is set back to 4x. Your stats and binds are untouched."
            $intro += ''
        }

        $modColour = $C.Dim; if ($st.ModOn) { $modColour = $C.Good }
        $imgColour = $C.Dim; if ($st.ImagesOn) { $imgColour = $C.Good }
        $sndColour = $C.Dim; if ($st.SoundsOn) { $sndColour = $C.Good }
        $rshColour = $C.Dim; if ($st.ReShadeOn) { $rshColour = $C.Good }
        if ($st.ReShadeGone) { $rshColour = $C.Warn }   # v2.2.7 - a record with no files is not "installed"
        $dsColour  = $C.Dim; if ($st.ControllerOn) { $dsColour = $C.Good }

        # -------------------------------------------------------------------
        #  v2.2.6 - EVERY ROW NOW SAYS WHAT IT DOES, IN ONE PLAIN SENTENCE.
        #
        #  User, 2026-08-23: *"i didn't like some of the descriptions for some of
        #  the options ... make sure that the descriptions make sense because
        #  some of them don't really do a good job of explaining to be honest"*.
        #
        #  Rules the wording follows, so later rows stay consistent:
        #    * the Hint says what HAPPENS, not what the thing is called;
        #    * it names WHERE files land when the answer is "somewhere on your
        #      PC", because that is the question people actually have;
        #    * it says plainly when something overwrites, and when it does not;
        #    * no jargon that is not already on the screen.
        #  🛑 "EVERYTHING" DOES NOT INCLUDE THE CONTROLLER ICONS and never has -
        #  Act-InstallEverything runs mod / textures / sounds / ReShade, four
        #  steps, and the icons are a personal choice between three pads. The row
        #  now says so instead of leaving people to find out.
        # -------------------------------------------------------------------
        $items = @(
            @{ Key='all';    Section='INSTALL';   Label='EVERYTHING - the whole package'; Status='mod + textures + sounds + ReShade'; StatusColour=$C.Title
               Hint='Runs the four installs below in order. Controller icons stay your choice.' },
            @{ Key='mod';    Section='INSTALL';   Label='The mod';               Status=$st.Mod;     StatusColour=$modColour
               Hint='The mod itself - 5 files into Plutonium. This is the only part you actually need.' },
            @{ Key='images'; Section='INSTALL';   Label='HD texture pack';       Status=$st.Images;  StatusColour=$imgColour
               Hint='Sharper weapon, perk and world textures. Optional, and it replaces any you already had.' },
            @{ Key='sounds'; Section='INSTALL';   Label='Custom sounds';         Status=$st.Sounds;  StatusColour=$sndColour
               Hint='Remastered weapon audio. Optional. Your real game files are never touched.' },
            @{ Key='reshade';Section='INSTALL';   Label='ReShade + BO2 preset';  Status=$st.ReShade; StatusColour=$rshColour
               Hint='Post-processing that sharpens the picture and lifts the colour. END opens its menu in game.' },
            @{ Key='controller';Section='INSTALL'; Label='Controller icons';      Status=$st.Controller; StatusColour=$dsColour
               Hint='Swaps the on-screen button prompts to PlayStation, Xbox or Switch. Pick one.' },

            @{ Key='remove';  Section='REMOVE';   Label='Uninstall something'; Status=$st.RemoveHint; StatusColour=$C.Dim
               Hint='Opens the uninstall list: everything at once, or one part on its own.' },

            @{ Key='backups'; Section='BACKUP';   Label='Back up / restore my own files'; Status=$st.Backups; StatusColour=$st.BackupsColour
               Hint='Copies YOUR textures, sounds and ReShade aside first - or puts them back later.' },

            @{ Key='update';  Section='MORE';     Label='Check for a newer version'
               Hint='Asks GitHub whether a newer release exists, and can download it for you.' },
            @{ Key='details'; Section='MORE';     Label='Details and log'
               Hint='Where every file went, what is installed, and what this session did.' },
            @{ Key='quit';    Section='MORE';     Label='Quit'
               Hint='Closes this installer. Nothing is undone.' }
        )

        $sel = Show-Menu $sub $items -Intro $intro -Footer '   ↑ ↓  move      ENTER  choose      Q  quit'
        if (-not $sel -or $sel.Key -eq 'quit') { return }

        switch ($sel.Key) {
            'all'      { Act-InstallEverything }
            'mod'      { Act-InstallMod }
            'images'   { Act-InstallImages }
            'sounds'   { Act-InstallSounds }
            'reshade'  { Act-InstallReShade }
            'controller' { Act-InstallController }
            'remove'   { Remove-Menu }
            'backups'  { Act-Backups }
            'update'   { Act-CheckUpdate }
            'details'  { Act-Details }
        }
    }
}

Write-Log "--- installer started (dryrun=$DryRun) ---"
Enable-Vt
Move-OldBackups
Move-OldDualsense

if ($Action) {
    switch ($Action) {
        'all'      { Act-InstallEverything -Pick $Choice }
        'mod'      { Act-InstallMod     -Pick $Choice }
        'images'   { Act-InstallImages  -Pick $Choice }
        'sounds'   { Act-InstallSounds  -Pick $Choice }
        'reshade'  { Act-InstallReShade -Pick $Choice }
        'controller' { Act-InstallController -Pick $Choice }
        'rall'     { Act-RemoveEverything -Pick $Choice }
        'rimages'  { Act-RemoveImages   -Pick $Choice }
        'rsounds'  { Act-RemoveSounds   -Pick $Choice }
        'rreshade' { Act-RemoveReShade  -Pick $Choice }
        'rcontroller' { Act-RemoveController -Pick $Choice }
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
