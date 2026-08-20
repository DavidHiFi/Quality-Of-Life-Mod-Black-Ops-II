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
    -Root <path>         pretend Plutonium lives here
================================================================================
#>

[CmdletBinding()]
param(
    [switch] $DryRun,
    [string] $Action,
    [int]    $Choice = 0,
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
$BACKUPS  = Join-Path $STATE 'backups'
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
    Write-Host ('     ' + $Text) -ForegroundColor $Colour
    if (-not $NoLog) { Write-Log $Text }
}

# --------------------------------------------------------------------- chrome -
function Draw-Header {
    param([string] $Sub)
    if (-not $script:Headless) { Clear-Host }
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
#>
function Show-Menu {
    param(
        [string] $Sub,
        [array]  $Items,
        [string] $Footer = '   ↑ ↓  move      ENTER  choose      ESC  back',
        [string[]] $Intro = @()
    )

    $pickable = @()
    for ($i = 0; $i -lt $Items.Count; $i++) { if (-not $Items[$i].Disabled) { $pickable += $i } }
    if ($pickable.Count -eq 0) { return $null }
    $cur = $pickable[0]

    while ($true) {
        Draw-Header $Sub
        foreach ($line in $Intro) {
            if ($line -eq '') { Write-Host '' }
            elseif ($line.StartsWith('!')) { Write-Host ('   ' + $line.Substring(1)) -ForegroundColor $C.Warn }
            elseif ($line.StartsWith('~')) { Write-Host ('   ' + $line.Substring(1)) -ForegroundColor $C.Dim }
            else { Write-Host ('   ' + $line) -ForegroundColor $C.Text }
        }
        if ($Intro.Count -gt 0) { Write-Host '' }

        $lastSection = $null
        for ($i = 0; $i -lt $Items.Count; $i++) {
            $it = $Items[$i]
            if ($it.Section -and $it.Section -ne $lastSection) {
                Write-Host ''
                Write-Host ('   ' + $it.Section) -ForegroundColor $C.Dim
                $lastSection = $it.Section
            }
            $sel = ($i -eq $cur)
            $marker = '     '
            if ($sel) { $marker = '   ❯ ' }
            $label = $it.Label
            $colour = $C.Text
            if ($it.Disabled) { $colour = $C.Off }
            if ($sel) { $colour = $C.Pick }

            Write-Host $marker -ForegroundColor $C.Title -NoNewline
            Write-Host ($label.PadRight(38)) -ForegroundColor $colour -NoNewline
            if ($it.Status) {
                $sc = $C.Dim
                if ($it.StatusColour) { $sc = $it.StatusColour }
                Write-Host $it.Status -ForegroundColor $sc
            } else { Write-Host '' }
        }

        Write-Host ''
        Draw-Rule

        # Arrow keys need a real console. If this is running somewhere that has
        # its input redirected, fall back to typing the number instead of
        # falling over.
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

        Write-Host $Footer -ForegroundColor $C.Dim
        try { $key = [Console]::ReadKey($true) }
        catch { $script:NoKeys = $true; continue }
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

function Pause-Key {
    param([string] $Text = '   Press any key to go back')
    Write-Host ''
    Draw-Rule
    Write-Host $Text -ForegroundColor $C.Dim
    if ($script:Headless) { return }
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
function Backup-Folder {
    param([string] $Kind, [string] $Source)
    $dest = Join-Path $BACKUPS $Kind
    $files = @(Get-ChildItem -LiteralPath $Source -File -Recurse -ErrorAction SilentlyContinue)
    if ($files.Count -eq 0) {
        Say "Nothing to back up - that folder is empty." $C.Dim
        return $true
    }
    if (Test-Path $dest) {
        Say "A backup already exists from $(( Get-Item $dest ).LastWriteTime.ToString('d MMM yyyy')) - keeping it." $C.Dim
        Say "That is the older one, so it is the one worth keeping." $C.Dim
        return $true
    }
    $size = ($files | Measure-Object Length -Sum).Sum
    Say ("Backing up {0} file(s), {1} ..." -f $files.Count, (Format-Size $size)) $C.Text
    if ($DryRun) { Say "   (dry run - not copied)" $C.Dim; return $true }
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    $r = robocopy $Source $dest /E /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) { Say "Backup FAILED - stopping, nothing was changed." $C.Bad; return $false }
    Say "Backup saved." $C.Good
    return $true
}

function Restore-Folder {
    param([string] $Kind, [string] $Dest)
    $src = Join-Path $BACKUPS $Kind
    if (-not (Test-Path $src)) { Say "There is no backup to restore." $C.Warn; return $false }
    Say "Restoring your original files ..." $C.Text
    if ($DryRun) { Say "   (dry run - not copied)" $C.Dim; return $true }
    $r = robocopy $src $Dest /E /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) { Say "Restore FAILED." $C.Bad; return $false }
    Say "Your original files are back." $C.Good
    return $true
}

function Has-Backup { param([string] $Kind) return (Test-Path (Join-Path $BACKUPS $Kind)) }

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
    $rel = $files | ForEach-Object { $_.FullName.Substring($Source.Length).TrimStart('\') }
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

    if (Test-Path (Join-Path $BINDIR 'dxgi.dll')) { $s.ReShade = 'installed'; $s.ReShadeOn = $true }
    else { $s.ReShade = 'not installed'; $s.ReShadeOn = $false }

    $s.Settings = (Test-Path $CFGDIR)
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
    if ($sel.Key -eq 'backup') { if (-not (Backup-Folder 'images' $IMGDIR)) { Pause-Key; return } }
    if (Copy-Payload $src $IMGDIR 'images') { Write-Host ''; Say "✅  Texture pack installed." $C.Good }
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
    if ($sel.Key -eq 'backup') { if (-not (Backup-Folder 'zone' $ZONEDIR)) { Pause-Key; return } }
    if (Copy-Payload $src $ZONEDIR 'zone') { Write-Host ''; Say "✅  Custom sounds installed." $C.Good }
    Pause-Key
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
        "mod's own BO2 preset already applied. Press HOME in game to open it.",
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
    foreach ($f in @('ReShade.ini','BO2.ini')) {
        $p = Join-Path $BINDIR $f
        if (Test-Path $p) {
            if (-not $DryRun) { Copy-Item -LiteralPath $p -Destination "$p.backup" -Force }
            Say "Your $f was saved as $f.backup" $C.Dim
        }
    }
    if (Copy-Payload $src $BINDIR 'reshade') {
        Write-Host ''
        Say "✅  ReShade installed. Press HOME in game to open it." $C.Good
    }
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
    if ($sel.Key -eq 'restore') { [void](Restore-Folder 'images' $IMGDIR) }
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
    if ($sel.Key -eq 'restore') { [void](Restore-Folder 'zone' $ZONEDIR) }
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
    if (Test-Path $MODDIR) {
        $old = @(Get-ChildItem -LiteralPath $MODDIR -File | Where-Object { $_.Extension -in @('.ff','.iwd','.json','.sabl','.sabs') })
        foreach ($o in $old) { if (-not $DryRun) { Remove-Item -LiteralPath $o.FullName -Force -ErrorAction SilentlyContinue } }
        Say "Removed $($old.Count) mod file(s)." $C.Text
    } else { Say "It was not installed." $C.Dim }
    if ($sel.Key -eq 'wipe' -and (Test-Path $CFGDIR)) {
        if (-not $DryRun) { Remove-Item -LiteralPath $CFGDIR -Recurse -Force -ErrorAction SilentlyContinue }
        Say "Your saved menu settings were wiped." $C.Warn
    } elseif (Test-Path $CFGDIR) {
        Say "Your saved menu settings were kept." $C.Good
    }
    Write-Host ''
    Say "✅  Done." $C.Good
    Pause-Key
}

# ------------------------------------------------------------------ updates --
function Get-Release {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        return Invoke-RestMethod "https://api.github.com/repos/$REPO/releases/latest" -Headers @{ 'User-Agent' = 'zm_qol-installer' }
    } catch { return $null }
}

function Get-RemotePayload {
    param([string] $AssetName, [string] $FolderName)
    $rel = Get-Release
    if (-not $rel) { return $null }
    $asset = $rel.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
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
    $srcDir = $out
    if (Test-Path (Join-Path $out "$MODID\mod.json")) { $srcDir = Join-Path $out $MODID }
    if (-not (Test-Path (Join-Path $srcDir 'mod.json'))) { Say 'That download did not contain the mod.' $C.Bad; Pause-Key; return }

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

        $items = @(
            @{ Key='mod';    Section='INSTALL';   Label='The mod';               Status=$st.Mod;     StatusColour=$modColour },
            @{ Key='images'; Section='INSTALL';   Label='HD texture pack';       Status=$st.Images;  StatusColour=$imgColour },
            @{ Key='sounds'; Section='INSTALL';   Label='Custom sounds';         Status=$st.Sounds;  StatusColour=$sndColour },
            @{ Key='reshade';Section='INSTALL';   Label='ReShade + BO2 preset';  Status=$st.ReShade; StatusColour=$rshColour },

            @{ Key='rimages'; Section='REMOVE';   Label='Remove the HD textures' },
            @{ Key='rsounds'; Section='REMOVE';   Label='Remove the custom sounds' },
            @{ Key='rreshade';Section='REMOVE';   Label='Remove ReShade' },
            @{ Key='rmod';    Section='REMOVE';   Label='Remove the mod' },

            @{ Key='update';  Section='MORE';     Label='Check for a newer version' },
            @{ Key='details'; Section='MORE';     Label='Details and log' },
            @{ Key='quit';    Section='MORE';     Label='Quit' }
        )

        $sel = Show-Menu $sub $items -Intro $intro -Footer '   ↑ ↓  move      ENTER  choose      Q  quit'
        if (-not $sel -or $sel.Key -eq 'quit') { return }

        switch ($sel.Key) {
            'mod'      { Act-InstallMod }
            'images'   { Act-InstallImages }
            'sounds'   { Act-InstallSounds }
            'reshade'  { Act-InstallReShade }
            'rimages'  { Act-RemoveImages }
            'rsounds'  { Act-RemoveSounds }
            'rreshade' { Act-RemoveReShade }
            'rmod'     { Act-RemoveMod }
            'update'   { Act-CheckUpdate }
            'details'  { Act-Details }
        }
    }
}

Write-Log "--- installer started (dryrun=$DryRun) ---"

if ($Action) {
    switch ($Action) {
        'mod'      { Act-InstallMod     -Pick $Choice }
        'images'   { Act-InstallImages  -Pick $Choice }
        'sounds'   { Act-InstallSounds  -Pick $Choice }
        'reshade'  { Act-InstallReShade -Pick $Choice }
        'rimages'  { Act-RemoveImages   -Pick $Choice }
        'rsounds'  { Act-RemoveSounds   -Pick $Choice }
        'rreshade' { Act-RemoveReShade  -Pick $Choice }
        'rmod'     { Act-RemoveMod      -Pick $Choice }
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
