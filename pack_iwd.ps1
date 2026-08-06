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
    $folders  = @('attachmentunique','character','fx','images','maps','scripts','ui_mp','weapons')
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
