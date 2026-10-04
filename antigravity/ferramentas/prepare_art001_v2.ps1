Add-Type -AssemblyName System.Drawing

function Resize-ImageNearest($src, $dst, $w, $h) {
    $img = [System.Drawing.Image]::FromFile($src)
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $g.DrawImage($img, 0, 0, $w, $h)
    $g.Dispose()
    $img.Dispose()
    $dstDir = [System.IO.Path]::GetDirectoryName($dst)
    if (!(Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Resized to $dst ($w x $h)"
}

$raw1 = 'C:\Users\pattr\.gemini\antigravity-ide\brain\5ec5b6cf-d32c-4977-a5f6-da356f68afa0\mockup_mapa_25d_arena_1791139212965.jpg'
$raw2 = 'C:\Users\pattr\.gemini\antigravity-ide\brain\5ec5b6cf-d32c-4977-a5f6-da356f68afa0\mockup_mapa_25d_variante_1791139260218.jpg'

$outDir = 'c:\Users\pattr\pixel-chess\antigravity\entregas\ART-001\v2'

Resize-ImageNearest $raw1 "$outDir\art-001_mockup-mapa.png" 640 360
Resize-ImageNearest $raw2 "$outDir\art-001_mockup-mapa_variante.png" 640 360

$img1 = [System.Drawing.Image]::FromFile($raw1)
$img1.Save("$outDir\art-001_mockup-mapa_raw.png", [System.Drawing.Imaging.ImageFormat]::Png)
$img1.Dispose()

$img2 = [System.Drawing.Image]::FromFile($raw2)
$img2.Save("$outDir\art-001_mockup-mapa_variante_raw.png", [System.Drawing.Imaging.ImageFormat]::Png)
$img2.Dispose()

Write-Host "ART-001 v2 (2.5D) images prepared successfully!"
