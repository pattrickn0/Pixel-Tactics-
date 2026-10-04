Add-Type -AssemblyName System.Drawing

function Convert-ToPng($src, $dst) {
    $img = [System.Drawing.Image]::FromFile($src)
    $dstDir = [System.IO.Path]::GetDirectoryName($dst)
    if (!(Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    $img.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
    Write-Host "Saved: $dst"
}

$dirBrain = 'C:\Users\pattr\.gemini\antigravity-ide\brain\5ec5b6cf-d32c-4977-a5f6-da356f68afa0'
$baseEntregas = 'c:\Users\pattr\pixel-chess\antigravity\entregas'

# Sessão 1: Floresta Nórdica & Rio
$s1_dir = "$baseEntregas\sessao-01-floresta-nordica"
Convert-ToPng "$dirBrain\sessao1_floresta_nordica_mapa_1791140052534.jpg" "$s1_dir\mapa_clareira_25d.png"
Convert-ToPng "$dirBrain\sessao1_floresta_nordica_assets_1791140113385.jpg" "$s1_dir\spritesheet_assets_25d.png"

# Sessão 2: Campina Solar Medieval
$s2_dir = "$baseEntregas\sessao-02-campina-solar"
Convert-ToPng "$dirBrain\sessao2_planicie_solar_mapa_1791140181038.jpg" "$s2_dir\mapa_clareira_25d.png"
Convert-ToPng "$dirBrain\sessao2_planicie_solar_assets_1791140250343.jpg" "$s2_dir\spritesheet_assets_25d.png"

# Sessão 3: Terraço de Pedra Natural & Rio
$s3_dir = "$baseEntregas\sessao-03-terraco-rochoso"
Convert-ToPng "$dirBrain\mockup_mapa_25d_variante_1791139260218.jpg" "$s3_dir\mapa_clareira_25d.png"
Convert-ToPng "$dirBrain\sessao1_coliseu_assets_1791139993537.jpg" "$s3_dir\spritesheet_assets_25d.png"

Write-Host "All 3 visual sessions prepared successfully!"
