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
    $folders  = @('attachmentunique','character','images','maps','scripts','ui_mp','weapons')
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
