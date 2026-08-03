<#
  png2dds.ps1 - PNG/TGA-ish bitmap -> uncompressed A8B8G8R8 .dds

  WHY THIS EXISTS
  OpenAssetTools' ImageConverter reads DDS and nothing else, and several textures
  this mod needs exist in the workspace dumps only as PNG. Nothing on this machine
  converts PNG->DDS headlessly (IntelTextureWorks is a Photoshop plugin), so the
  chain PNG -> DDS -> IWI had one missing link. This is that link.

    .\png2dds.ps1 -In foo.png -Out foo.dds
    ImageConverter.exe --t6 foo.dds        ->  foo.iwi
    copy foo.iwi zone_assets\images\       ->  build.bat packs it into mod.iwd

  🛑 A8B8G8R8, NOT A8R8G8B8. They differ only in the channel masks and both look
  identical in a viewer, but ImageConverter turns A8R8G8B8 into IWI format 0,
  which is rejected downstream. A8B8G8R8 gives format 1 - the same format the
  Wunderfizz textures already in this mod use, so it is known to work here.
  System.Drawing hands back BGRA, so the R and B bytes are swapped below.

  Uncompressed on purpose: no block compressor is available here, and these are
  small HUD textures where the size does not matter.
#>
param(
    [Parameter(Mandatory=$true)][string]$In,
    [string]$Out
)

Add-Type -AssemblyName System.Drawing

if (-not $Out) { $Out = [IO.Path]::ChangeExtension($In, '.dds') }
$In  = (Resolve-Path -LiteralPath $In).Path

$bmp = [System.Drawing.Bitmap]::FromFile($In)
try {
    $w = $bmp.Width; $h = $bmp.Height

    # Force a known layout: 32bpp BGRA, top-down.
    $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
    $data = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
                          [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $bytes = New-Object byte[] ($w * $h * 4)
    try {
        for ($y = 0; $y -lt $h; $y++) {
            [System.Runtime.InteropServices.Marshal]::Copy(
                [IntPtr]::Add($data.Scan0, $y * $data.Stride), $bytes, $y * $w * 4, $w * 4)
        }
    } finally { $bmp.UnlockBits($data) }

    # BGRA -> RGBA (this is the A8B8G8R8 vs A8R8G8B8 point above)
    for ($i = 0; $i -lt $bytes.Length; $i += 4) {
        $b = $bytes[$i]; $bytes[$i] = $bytes[$i+2]; $bytes[$i+2] = $b
    }

    $fs = [IO.File]::Create($Out)
    $bw = New-Object IO.BinaryWriter($fs)
    try {
        $bw.Write([uint32]0x20534444)   # "DDS "
        $bw.Write([uint32]124)          # dwSize
        $bw.Write([uint32]0x0000100F)   # CAPS|HEIGHT|WIDTH|PITCH|PIXELFORMAT
        $bw.Write([uint32]$h)
        $bw.Write([uint32]$w)
        $bw.Write([uint32]($w * 4))     # pitch
        $bw.Write([uint32]0)            # depth
        $bw.Write([uint32]1)            # mip count
        for ($i = 0; $i -lt 11; $i++) { $bw.Write([uint32]0) }   # reserved
        # DDS_PIXELFORMAT
        $bw.Write([uint32]32)           # dwSize
        $bw.Write([uint32]0x41)         # DDPF_RGB | DDPF_ALPHAPIXELS
        $bw.Write([uint32]0)            # fourCC
        $bw.Write([uint32]32)           # bit count
        $bw.Write([uint32]0x000000FF)   # R
        $bw.Write([uint32]0x0000FF00)   # G
        $bw.Write([uint32]0x00FF0000)   # B
        # 0xFF000000 as a literal is a negative Int32 in PowerShell, and the cast
        # to uint32 throws. 4278190080 is the same 32 bits written the long way.
        $bw.Write([uint32]4278190080)   # A
        $bw.Write([uint32]0x1000)       # caps = TEXTURE
        $bw.Write([uint32]0); $bw.Write([uint32]0); $bw.Write([uint32]0); $bw.Write([uint32]0)
        $bw.Write($bytes)
    } finally { $bw.Dispose(); $fs.Dispose() }

    Write-Host ("  {0}  ->  {1}   ({2}x{3}, A8B8G8R8)" -f (Split-Path $In -Leaf), (Split-Path $Out -Leaf), $w, $h)
} finally { $bmp.Dispose() }
