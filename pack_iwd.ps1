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
    #
    # 'fx' is how the T5 wonder weapons get their effects, and it is the ONLY way
    # they can. OpenAssetTools cannot link an FxEffectDef, so a raw .efx is
    # invisible to the Linker and no fx entry for them can go in the zone - and
    # 23 of their 27 effects exist in no Black Ops II fastfile at all, so there is
    # nothing for a zone entry to resolve against either. Plutonium loads raw .efx
    # straight out of mod.iwd at runtime instead.
    #
    # 🌟 That is measured, not inferred. The creators' own shipped mod
    # (H:\Claude\T6-Declassified-Public) carries ZERO fx assets in its mod.ff and
    # 30 raw .efx inside its mod.iwd, and the upstream open-source zone
    # (Wonder_Weapons-T6ZM) declares no fx either. Drop this folder from the list
    # and the guns fire with no lightning, no freeze and no impacts.
    #
    # 🛑 'xanim' IS THE SAME STORY AS 'fx' AND LEAVING IT OUT IS A HARD CRASH, not a
    # missing animation. v1.56.0 shipped the wonder weapons' modified animtrees
    # (animtrees\zm_<map>_basic.atr) while their 43 ai_zombie_thundergun_* xanims
    # existed nowhere the game could reach - the .atr referenced 18 animations that
    # were not in mod.ff, not in zm_transit.ff and not in mod.iwd - and Plutonium
    # died on map load.
    #
    # The upstream README says the per-map scripts\zm\<map>\anims_*.gsc make the
    # LINKER pull each xanim in as an animtree dependency. That is true of a
    # pipeline that COMPILES scripts. OAT stores a T6 script as raw text and never
    # parses it, so nothing is extracted and the xanims silently do not arrive -
    # the zone links clean and the game still crashes.
    #
    # 🌟 Measured: the creators' shipped mod.iwd carries 43 thundergun xanims and
    # their mod.ff, mod_load.ff and mod_patch.ff carry ZERO. Raw out of the iwd is
    # how they are meant to travel.
    $folders  = @('attachmentunique','character','fx','images','maps','scripts','ui_mp','weapons','xanim')
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
                $entry = $zip.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
                $es    = $entry.Open()
                $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
                $es.Write($bytes, 0, $bytes.Length)
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
