# ============================================================
#  pack_iwd.ps1  -  builds mod.iwd from the raw source folders
# ------------------------------------------------------------
#  Pure .NET - needs only Windows + .NET 4.5+ (built into Win 8+).
#  Produces a spec-compliant ZIP (forward-slash paths) so Plutonium
#  T6 reads the raw script paths correctly. Called by build.bat.
# ============================================================
param(
    [string]$Root = $PSScriptRoot,
    [string]$Out  = "mod.iwd"
)

$ErrorActionPreference = 'Stop'

# Load .NET compression (ZipArchive). Clear message if it isn't available.
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName System.IO.Compression
}
catch {
    Write-Host "  ERROR: .NET compression is unavailable (needs Windows 8+ / .NET 4.5+)."
    exit 1
}

try {
    # 'character' holds stock scripts the GAME fails to ship in every gametype's
    # fastfile set - see character\c_buried_player_reporter_dam.gsc for the case
    # that made this necessary (Buried survival could not load without it).
    # 'ui' is the OTHER LUI root. T6 resolves a "T6.Menus.X" require against both
    # ui\ and ui_mp\ - stock keeps privateonlinegamelobby.lua under ui\ and
    # privategamelobby_project.lua under ui_mp\ - so a mod that overrides a ui\
    # file needs that folder packed too, or the override never reaches the game.
    # 'fx' carries the wonder weapons' 63 raw .efx. OpenAssetTools cannot read or
    # write FxEffectDef, so they can never enter mod.ff - Plutonium loads them
    # straight out of mod.iwd at runtime.
    #
    # 🌟 ALL 63 ARE BYTE-IDENTICAL TO Wonder_Weapons-T6ZM\wonder_wepons_zm\, a
    # SHIPPED WORKING BUILD whose own mod.iwd carries the same 63 and does not
    # crash. Do not hand-edit them. Two earlier attempts to "fix" these files -
    # converting them to CRLF, then substituting 22 materials - were both wrong
    # theories and neither stopped the crash. The real gap was in mod.ff:
    # THIRTEEN TECHNIQUESETS, seven of them effect_* / distortion_*, the shaders
    # particles draw with. See zone_source\mod_wonderweapons.zone.
    $folders  = @('attachmentunique','character','fx','images','maps','scripts','ui','ui_mp','weapons')
    $rootPath = (Resolve-Path -LiteralPath $Root).Path
    $outPath  = Join-Path $rootPath $Out

    if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force }

    $fs  = [System.IO.File]::Open($outPath, [System.IO.FileMode]::CreateNew)
    $zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
    $count = 0
    try {
        foreach ($folder in $folders) {
            $folderPath = Join-Path $rootPath $folder
            if (-not (Test-Path -LiteralPath $folderPath)) { continue }
            Get-ChildItem -Path $folderPath -Recurse -File | ForEach-Object {
                # entry path relative to project root, forward slashes
                $rel   = $_.FullName.Substring($rootPath.Length + 1) -replace '\\','/'

                # .iwi is ALREADY a compressed texture (DXT/BC blocks). Deflating it
                # again buys almost nothing and costs a great deal of time - images\
                # is ~2.1 GB since the upscaled texture pack landed, and running that
                # through Optimal turns every build into a multi-minute wait for a
                # couple of percent. Store them instead; the game reads stored and
                # deflated entries identically.
                $level = if ($_.Extension -ieq '.iwi') {
                    [System.IO.Compression.CompressionLevel]::NoCompression
                } else {
                    [System.IO.Compression.CompressionLevel]::Optimal
                }

                $entry = $zip.CreateEntry($rel, $level)
                $es    = $entry.Open()
                $fsIn  = [System.IO.File]::OpenRead($_.FullName)
                try { $fsIn.CopyTo($es) } finally { $fsIn.Dispose() }
                $es.Dispose()
                $count++
            }
        }
    }
    finally {
        if ($zip) { $zip.Dispose() }
        if ($fs)  { $fs.Dispose() }
    }

    Write-Host ("  mod.iwd packed: {0:N0} files, {1:N0} bytes" -f $count, (Get-Item -LiteralPath $outPath).Length)
    exit 0
}
catch {
    Write-Host ("  ERROR packing mod.iwd: " + $_.Exception.Message)
    exit 1
}
