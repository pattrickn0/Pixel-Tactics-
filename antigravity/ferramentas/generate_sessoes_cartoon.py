"""
Generator for sessao.v2: Versões Cartonizadas 2.5D (Estilo Cel-Shaded / Vibrant Indie)
Replaces gritty realistic textures with clean, charming, colorful cartoon pixel art:
- Bold rounded volumes and cloud-like foliage clusters
- Smooth chunky cobblestones (paralelepípedos almofadados)
- Vibrant saturated palettes (clean cell shading, zero noise)
- Crisp dark-colored outlines
"""

import math
import os
import random
from pixel_art_tool import Canvas, hex_to_rgba

BASE_DIR = r"c:\Users\pattr\pixel-chess\antigravity\entregas\sessao.v2"
os.makedirs(BASE_DIR, exist_ok=True)

C_TRANSP = (0, 0, 0, 0)

# ==============================================================================
# SESSÃO 1 CARTOON: FLORESTA NÓRDICA & RIO (Vibrante / Sea of Stars Style)
# ==============================================================================
PAL_S1_GRASS = [
    hex_to_rgba('#1A4A28'), # 0: Sombra
    hex_to_rgba('#2D7A3E'), # 1: Base
    hex_to_rgba('#4EAE58'), # 2: Luz
    hex_to_rgba('#84DE72'), # 3: Highlight
    hex_to_rgba('#B8FFA2'), # 4: Brilho de ponta
]

PAL_S1_PINE = [
    hex_to_rgba('#123824'), # 0: Sombra profunda
    hex_to_rgba('#1E5638'), # 1: Base
    hex_to_rgba('#328250'), # 2: Luz
    hex_to_rgba('#56B472'), # 3: Highlight macio
    hex_to_rgba('#8EF0AA'), # 4: Ponta cel-shaded
]

PAL_S1_COBBLE = [
    hex_to_rgba('#262D38'), # 0: Rejunte escuro
    hex_to_rgba('#485468'), # 1: Sombra pedra
    hex_to_rgba('#6C7C96'), # 2: Base pedra azulada
    hex_to_rgba('#98A8C4'), # 3: Luz pedra
    hex_to_rgba('#C8D6EC'), # 4: Highlight arredondado
]

PAL_S1_WOOD = [
    hex_to_rgba('#341E14'), # 0
    hex_to_rgba('#5A3422'), # 1
    hex_to_rgba('#885034'), # 2
    hex_to_rgba('#B6744C'), # 3
]

OUTLINE_S1 = hex_to_rgba('#101D16')


# ==============================================================================
# SESSÃO 2 CARTOON: CAMPINA SOLAR (Vila Alegre / Minish Cap Style)
# ==============================================================================
PAL_S2_GRASS = [
    hex_to_rgba('#2E5C1E'), # 0: Sombra
    hex_to_rgba('#4E8C28'), # 1: Base
    hex_to_rgba('#78C438'), # 2: Luz dourada
    hex_to_rgba('#AEE84C'), # 3: Highlight solar
    hex_to_rgba('#E4FF76'), # 4: Brilho
]

PAL_S2_OAK = [
    hex_to_rgba('#224E1E'), # 0
    hex_to_rgba('#3E7A2A'), # 1
    hex_to_rgba('#66AE3A'), # 2
    hex_to_rgba('#98DE4E'), # 3
    hex_to_rgba('#D2FF74'), # 4
]

PAL_S2_COBBLE = [
    hex_to_rgba('#3E3832'), # 0: Rejunte
    hex_to_rgba('#685E52'), # 1: Sombra
    hex_to_rgba('#9C8E7E'), # 2: Base pedra areia
    hex_to_rgba('#C8BAAA'), # 3: Luz
    hex_to_rgba('#EAE0D2'), # 4: Highlight fofo
]

PAL_S2_WOOD = [
    hex_to_rgba('#4A2C14'), # 0
    hex_to_rgba('#7E4C22'), # 1
    hex_to_rgba('#BA7436'), # 2
    hex_to_rgba('#E89E52'), # 3: Mel
]

OUTLINE_S2 = hex_to_rgba('#1C1E14')


# ==============================================================================
# SESSÃO 3 CARTOON: TERRAS ALTAS (Highland / Mario RPG Style)
# ==============================================================================
PAL_S3_GRASS = [
    hex_to_rgba('#22442C'), # 0
    hex_to_rgba('#386E42'), # 1
    hex_to_rgba('#569E5E'), # 2
    hex_to_rgba('#82D288'), # 3
    hex_to_rgba('#BEFFA8'), # 4
]

PAL_S3_TREE = [
    hex_to_rgba('#163A26'), # 0
    hex_to_rgba('#265A38'), # 1
    hex_to_rgba('#3E8652'), # 2
    hex_to_rgba('#66BA7A'), # 3
    hex_to_rgba('#9CE8AA'), # 4
]

PAL_S3_STONE = [
    hex_to_rgba('#282B34'), # 0
    hex_to_rgba('#464B5A'), # 1
    hex_to_rgba('#6E768C'), # 2
    hex_to_rgba('#9AA2B8'), # 3
    hex_to_rgba('#CAD2E4'), # 4
]

OUTLINE_S3 = hex_to_rgba('#12171C')


# --- Helper: Draw Cartoon Cel-Shaded Bubble / Foliage Lobe ---
def draw_cartoon_lobe(canvas, cx, cy, rx, ry, pal, outline_col):
    # 1. Fill solid base with cel-shading bands
    for dy in range(-ry, ry + 1):
        for dx in range(-rx, rx + 1):
            if (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry) <= 1.0:
                nx = dx / float(rx)
                ny = dy / float(ry)
                # Lighting from top-left (-0.6, -0.8)
                val = - (nx * 0.6 + ny * 0.8)
                if val > 0.45:
                    col = pal[3]
                elif val > -0.15:
                    col = pal[2]
                elif val > -0.65:
                    col = pal[1]
                else:
                    col = pal[0]
                canvas.set_pixel(cx + dx, cy + dy, col)

    # 2. Add cute chunky highlight spot on upper-left
    hl_rx = max(2, rx // 3)
    hl_ry = max(2, ry // 3)
    hl_cx = cx - rx // 3
    hl_cy = cy - ry // 3
    for dy in range(-hl_ry, hl_ry + 1):
        for dx in range(-hl_rx, hl_rx + 1):
            if (dx*dx)/float(hl_rx*hl_rx) + (dy*dy)/float(hl_ry*hl_ry) <= 1.0:
                canvas.set_pixel(hl_cx + dx, hl_cy + dy, pal[4])

    # 3. Clean 1-pixel outline
    edges = []
    for dy in range(-ry - 1, ry + 2):
        for dx in range(-rx - 1, rx + 2):
            x = cx + dx
            y = cy + dy
            if canvas.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if canvas.get_pixel(nx, ny)[3] == 0:
                        edges.append((nx, ny))
    for ex, ey in edges:
        canvas.set_pixel(ex, ey, outline_col)


# --- Helper: Draw Cartoon Tree Trunk ---
def draw_cartoon_trunk(canvas, x_base, y_base, width, height, pal_wood, outline_col):
    for y in range(y_base, y_base + height):
        prog = (y - y_base) / float(height)
        cur_w = int(width * (0.85 + prog * 0.35))
        x0 = x_base - cur_w // 2

        for x in range(x0, x0 + cur_w):
            fx = (x - x0) / float(cur_w)
            if fx < 0.28:
                col = pal_wood[3] # Highlight stripe
            elif fx < 0.70:
                col = pal_wood[2] # Mid tone
            elif fx < 0.90:
                col = pal_wood[1] # Shadow
            else:
                col = pal_wood[0] # Dark edge
            canvas.set_pixel(x, y, col)

        canvas.set_pixel(x0 - 1, y, outline_col)
        canvas.set_pixel(x0 + cur_w, y, outline_col)

    # Cartoon Root knobs
    y_bot = y_base + height
    for i in range(4):
        canvas.set_pixel(x_base - width//2 - i, y_bot - 1 + i//2, pal_wood[2])
        canvas.set_pixel(x_base - width//2 - i, y_bot + i//2, outline_col)
        canvas.set_pixel(x_base + width//2 + i, y_bot - 1 + i//2, pal_wood[1])
        canvas.set_pixel(x_base + width//2 + i, y_bot + i//2, outline_col)


# ==============================================================================
# SESSÃO 1: FLORESTA NÓRDICA CARTOON GENERATOR
# ==============================================================================
def generate_sessao1_cartoon():
    s1_dir = os.path.join(BASE_DIR, "sessao-01-floresta-nordica")
    os.makedirs(s1_dir, exist_ok=True)

    # 1. Spritesheet de Assets (256x160 px)
    sheet = Canvas(256, 160)

    # Pinheiro Nórdico Cartoon (96x128 em 0..95, 0..127)
    # Trunk
    draw_cartoon_trunk(sheet, x_base=48, y_base=85, width=10, height=28, pal_wood=PAL_S1_WOOD, outline_col=OUTLINE_S1)
    # Layered chunky cartoon pine tiers (trapezoid/cloud boughs)
    tiers = [
        (48, 88, 30, 15), # tier 1 (bot)
        (48, 72, 26, 14), # tier 2
        (48, 57, 22, 13), # tier 3
        (48, 43, 17, 12), # tier 4
        (48, 30, 12, 10), # tier 5
        (48, 18, 7, 9),   # apex
    ]
    for cx, cy, rx, ry in tiers:
        draw_cartoon_lobe(sheet, cx, cy, rx, ry, PAL_S1_PINE, OUTLINE_S1)

    # Árvore Frondosa Cartoon (96..191, 0..95)
    draw_cartoon_trunk(sheet, x_base=96 + 48, y_base=60, width=11, height=26, pal_wood=PAL_S1_WOOD, outline_col=OUTLINE_S1)
    oak_lobes = [
        (96 + 48, 52, 22, 15),
        (96 + 32, 46, 18, 14),
        (96 + 64, 48, 18, 14),
        (96 + 28, 32, 17, 14),
        (96 + 68, 34, 17, 14),
        (96 + 48, 28, 24, 18),
        (96 + 40, 16, 16, 13),
        (96 + 56, 18, 15, 12),
    ]
    for cx, cy, rx, ry in oak_lobes:
        draw_cartoon_lobe(sheet, cx, cy, rx, ry, PAL_S1_GRASS, OUTLINE_S1)

    # Samambaia Cartoon (192..223, 0..31)
    for ang, length in [(-45, 10), (-15, 12), (15, 12), (45, 10)]:
        rad = math.radians(ang)
        for d in range(2, length):
            px = int(192 + 16 + d * math.sin(rad))
            py = int(24 - d * math.cos(rad) * 0.8)
            col = PAL_S1_GRASS[3] if ang < 0 else PAL_S1_GRASS[2]
            sheet.set_pixel(px, py, col)
            sheet.set_pixel(px + 1, py, col)
            sheet.set_pixel(px, py + 1, PAL_S1_GRASS[0])
    for x in range(192 + 10, 192 + 22):
        sheet.set_pixel(x, 26, OUTLINE_S1)

    # Seixos de Rio Cartoon (Pebble cluster) (224..255, 0..31)
    draw_cartoon_lobe(sheet, 224 + 14, 20, 9, 6, PAL_S1_COBBLE, OUTLINE_S1)
    draw_cartoon_lobe(sheet, 224 + 22, 22, 6, 4, PAL_S1_COBBLE, OUTLINE_S1)

    # Toco de Madeira Cartoon (192..223, 32..63)
    draw_cartoon_trunk(sheet, x_base=192 + 16, y_base=44, width=12, height=12, pal_wood=PAL_S1_WOOD, outline_col=OUTLINE_S1)
    for dy in range(-2, 3):
        for dx in range(-5, 6):
            if (dx*dx)/25.0 + (dy*dy)/4.0 <= 1.0:
                sheet.set_pixel(192 + 16 + dx, 44 + dy, PAL_S1_WOOD[3])
    sheet.set_pixel(192 + 16, 44, PAL_S1_WOOD[1])

    # Flores & Cogumelo (224..255, 32..63)
    # Red cartoon mushroom
    sheet.draw_circle(224 + 16, 46, 6, hex_to_rgba('#E84438'))
    sheet.set_pixel(224 + 14, 44, hex_to_rgba('#FFFFFF'))
    sheet.set_pixel(224 + 18, 45, hex_to_rgba('#FFFFFF'))
    sheet.draw_rect(224 + 15, 50, 3, 5, hex_to_rgba('#F2F2EC'))
    sheet.draw_rect(224 + 14, 55, 5, 1, OUTLINE_S1)

    sheet.save_png(os.path.join(s1_dir, "spritesheet_assets_cartoon_25d.png"))

    # 2. Tiles de Terreno Cartoon (128x64 px: 4 tiles de 32x32)
    # Tile 0: Grama Cartoon Lisa
    # Tile 1: Grama com Tufo
    # Tile 2: Calçamento de Seixos Arredondados Cartoon (Pebble Cobblestone)
    # Tile 3: Ribanceira / Degrau de Rocha com Grama Caindo
    tiles = Canvas(128, 64)

    # Tile 0: Grama Lisa Cartoon
    for y in range(32):
        for x in range(32):
            col = PAL_S1_GRASS[1] if (x + y) % 6 in [0, 1] else PAL_S1_GRASS[2]
            tiles.set_pixel(x, y, col)

    # Tile 1: Grama com Tufos Cartoon
    tiles.blit(Canvas(32, 32, fill=C_TRANSP), 32, 0)
    for y in range(32):
        for x in range(32):
            col = PAL_S1_GRASS[1] if (x + y) % 6 in [0, 1] else PAL_S1_GRASS[2]
            tiles.set_pixel(32 + x, y, col)
    # Cute cartoon blade tufts
    for tx, ty in [(10, 12), (22, 20)]:
        tiles.set_pixel(32 + tx, ty - 2, PAL_S1_GRASS[4])
        tiles.set_pixel(32 + tx - 1, ty - 1, PAL_S1_GRASS[3])
        tiles.set_pixel(32 + tx + 1, ty - 1, PAL_S1_GRASS[3])
        tiles.set_pixel(32 + tx, ty, PAL_S1_GRASS[1])
        tiles.set_pixel(32 + tx, ty + 1, OUTLINE_S1)

    # Tile 2: Calçamento de Seixos Arredondados Cartoon (Chunky River Pebbles)
    tiles.draw_rect(64, 0, 32, 32, PAL_S1_COBBLE[0]) # mortar
    # Draw pillow cobblestones
    pebbles = [
        (64 + 6, 6, 5, 4), (64 + 18, 5, 6, 4), (64 + 27, 6, 4, 4),
        (64 + 4, 15, 4, 4), (64 + 13, 14, 5, 4), (64 + 23, 15, 6, 5),
        (64 + 7, 23, 6, 5), (64 + 18, 22, 5, 4), (64 + 27, 24, 4, 4),
    ]
    for px, py, prx, pry in pebbles:
        for dy in range(-pry, pry + 1):
            for dx in range(-prx, prx + 1):
                if (dx*dx)/float(prx*prx) + (dy*dy)/float(pry*pry) <= 1.0:
                    val = - (dx * 0.7 + dy * 0.7)
                    col = PAL_S1_COBBLE[4] if val > 2 else (PAL_S1_COBBLE[3] if val > 0 else (PAL_S1_COBBLE[2] if val > -2 else PAL_S1_COBBLE[1]))
                    tiles.set_pixel(px + dx, py + dy, col)

    # Tile 3: Ribanceira Cartoon (Grama no topo com terraço de pedra)
    for y in range(14):
        for x in range(32):
            tiles.set_pixel(96 + x, y, PAL_S1_GRASS[2])
    # Drip blades overhang
    for x in range(32):
        drip = 2 if x % 4 in [1, 2] else 0
        tiles.set_pixel(96 + x, 14 + drip, PAL_S1_GRASS[3])
        tiles.set_pixel(96 + x, 15 + drip, OUTLINE_S1)
    # Rock wall below
    for y in range(16, 32):
        for x in range(32):
            tiles.set_pixel(96 + x, y, PAL_S1_COBBLE[2] if y % 6 != 0 else PAL_S1_COBBLE[1])

    tiles.save_png(os.path.join(s1_dir, "tiles_terreno_cartoon_25d.png"))


# ==============================================================================
# SESSÃO 2: CAMPINA SOLAR CARTOON GENERATOR
# ==============================================================================
def generate_sessao2_cartoon():
    s2_dir = os.path.join(BASE_DIR, "sessao-02-campina-solar")
    os.makedirs(s2_dir, exist_ok=True)

    sheet = Canvas(256, 160)

    # Carvalho Majestoso Solar Cartoon (96x128 em 0..95, 0..127)
    draw_cartoon_trunk(sheet, x_base=48, y_base=66, width=14, height=30, pal_wood=PAL_S2_WOOD, outline_col=OUTLINE_S2)
    oak_lobes = [
        (48, 54, 26, 17),
        (26, 48, 20, 16),
        (70, 50, 20, 16),
        (22, 32, 19, 15),
        (74, 34, 19, 15),
        (48, 28, 28, 20),
        (38, 14, 18, 14),
        (60, 16, 17, 13),
    ]
    for cx, cy, rx, ry in oak_lobes:
        draw_cartoon_lobe(sheet, cx, cy, rx, ry, PAL_S2_OAK, OUTLINE_S2)

    # Pinheiro Cônico Solar Cartoon (96..191, 0..127)
    draw_cartoon_trunk(sheet, x_base=96 + 48, y_base=82, width=9, height=26, pal_wood=PAL_S2_WOOD, outline_col=OUTLINE_S2)
    pine_tiers = [
        (96 + 48, 80, 28, 16),
        (96 + 48, 64, 24, 15),
        (96 + 48, 48, 19, 13),
        (96 + 48, 34, 14, 11),
        (96 + 48, 20, 8, 10),
    ]
    for cx, cy, rx, ry in pine_tiers:
        draw_cartoon_lobe(sheet, cx, cy, rx, ry, PAL_S2_OAK, OUTLINE_S2)

    # Mureta de Pedra Seca Cartoon (192..255, 0..31)
    sheet.draw_rect(192 + 2, 10, 58, 16, PAL_S2_COBBLE[2])
    # Stones outlines
    for x in range(192 + 2, 192 + 60, 14):
        sheet.draw_rect(x, 10, 1, 16, OUTLINE_S2)
    sheet.draw_rect(192 + 2, 17, 58, 1, OUTLINE_S2)
    sheet.draw_rect(192 + 2, 9, 58, 2, PAL_S2_COBBLE[4]) # top highlight
    sheet.draw_rect(192 + 1, 8, 60, 1, OUTLINE_S2)
    sheet.draw_rect(192 + 1, 26, 60, 1, OUTLINE_S2)

    # Banco de Taverna Cartoon (192..255, 36..63)
    # Seat plank
    sheet.draw_rect(192 + 6, 42, 48, 8, PAL_S2_WOOD[2])
    sheet.draw_rect(192 + 6, 41, 48, 1, PAL_S2_WOOD[3]) # highlight
    sheet.draw_rect(192 + 5, 40, 50, 1, OUTLINE_S2)
    sheet.draw_rect(192 + 5, 50, 50, 1, OUTLINE_S2)
    # Legs
    sheet.draw_rect(192 + 10, 51, 6, 8, PAL_S2_WOOD[1])
    sheet.draw_rect(192 + 44, 51, 6, 8, PAL_S2_WOOD[1])
    sheet.draw_rect(192 + 9, 59, 8, 1, OUTLINE_S2)
    sheet.draw_rect(192 + 43, 59, 8, 1, OUTLINE_S2)

    # Canteiro de Margaridas Cartoon (192..255, 68..95)
    for fx, fy in [(192 + 14, 76), (192 + 28, 80), (192 + 44, 74)]:
        # flower petals
        sheet.draw_circle(fx, fy, 4, hex_to_rgba('#FFFFFF'))
        sheet.set_pixel(fx, fy, hex_to_rgba('#F6DE4C'))
        sheet.set_pixel(fx, fy + 5, PAL_S2_GRASS[1])
        sheet.set_pixel(fx, fy + 6, OUTLINE_S2)

    sheet.save_png(os.path.join(s2_dir, "spritesheet_assets_cartoon_25d.png"))

    # 2. Tiles de Terreno
    tiles = Canvas(128, 64)
    # Tile 0: Grama Solar
    for y in range(32):
        for x in range(32):
            col = PAL_S2_GRASS[2] if (x + y) % 4 in [0, 1] else PAL_S2_GRASS[3]
            tiles.set_pixel(x, y, col)

    # Tile 1: Grama com Flores
    for y in range(32):
        for x in range(32):
            col = PAL_S2_GRASS[2] if (x + y) % 4 in [0, 1] else PAL_S2_GRASS[3]
            tiles.set_pixel(32 + x, y, col)
    tiles.draw_circle(32 + 16, 16, 3, hex_to_rgba('#FFFFFF'))
    tiles.set_pixel(32 + 16, 16, hex_to_rgba('#F6DE4C'))

    # Tile 2: Calçamento Regular Almofadado Cartoon (Pillow Cobblestone)
    tiles.draw_rect(64, 0, 32, 32, PAL_S2_COBBLE[0])
    for row in range(4):
        y0 = row * 8
        off = 4 if row % 2 == 1 else 0
        for col in range(5):
            x0 = (col * 8 + off) % 32
            for dy in range(6):
                for dx in range(6):
                    px = (x0 + dx) % 32
                    c_pix = PAL_S2_COBBLE[4] if (dy == 0 and dx < 5) else (PAL_S2_COBBLE[3] if dy < 4 else PAL_S2_COBBLE[1])
                    tiles.set_pixel(64 + px, y0 + dy, c_pix)

    # Tile 3: Mureta delimitadora integrada
    for y in range(32):
        for x in range(32):
            tiles.set_pixel(96 + x, y, PAL_S2_GRASS[2])
    tiles.draw_rect(96, 12, 32, 10, PAL_S2_COBBLE[2])
    tiles.draw_rect(96, 11, 32, 1, PAL_S2_COBBLE[4])
    tiles.draw_rect(96, 10, 32, 1, OUTLINE_S2)
    tiles.draw_rect(96, 22, 32, 1, OUTLINE_S2)

    tiles.save_png(os.path.join(s2_dir, "tiles_terreno_cartoon_25d.png"))


# ==============================================================================
# SESSÃO 3: TERRAS ALTAS CARTOON GENERATOR
# ==============================================================================
def generate_sessao3_cartoon():
    s3_dir = os.path.join(BASE_DIR, "sessao-03-terraco-rochoso")
    os.makedirs(s3_dir, exist_ok=True)

    sheet = Canvas(256, 160)

    # Pinheiro em Leque das Terras Altas (96x128 em 0..95, 0..127)
    draw_cartoon_trunk(sheet, x_base=48, y_base=80, width=10, height=28, pal_wood=PAL_S1_WOOD, outline_col=OUTLINE_S3)
    tiers = [
        (48, 80, 32, 16),
        (48, 64, 27, 15),
        (48, 48, 22, 14),
        (48, 34, 16, 12),
        (48, 20, 9, 10),
    ]
    for cx, cy, rx, ry in tiers:
        draw_cartoon_lobe(sheet, cx, cy, rx, ry, PAL_S3_TREE, OUTLINE_S3)

    # Carvalho das Terras Altas (96..191, 0..127)
    draw_cartoon_trunk(sheet, x_base=96 + 48, y_base=64, width=12, height=28, pal_wood=PAL_S1_WOOD, outline_col=OUTLINE_S3)
    lobes = [
        (96 + 48, 52, 24, 16),
        (96 + 28, 44, 20, 15),
        (96 + 68, 46, 20, 15),
        (96 + 48, 28, 26, 19),
        (96 + 38, 14, 18, 13),
        (96 + 58, 15, 17, 13),
    ]
    for cx, cy, rx, ry in lobes:
        draw_cartoon_lobe(sheet, cx, cy, rx, ry, PAL_S3_GRASS, OUTLINE_S3)

    # Degraus de Rocha Granito Cartoon (192..255, 0..48)
    for step in range(3):
        sy = step * 14
        sheet.draw_rect(192 + step * 4, sy + 6, 56 - step * 8, 12, PAL_S3_STONE[2])
        sheet.draw_rect(192 + step * 4, sy + 5, 56 - step * 8, 1, PAL_S3_STONE[4]) # highlight
        sheet.draw_rect(192 + step * 4, sy + 4, 56 - step * 8, 1, OUTLINE_S3)
        sheet.draw_rect(192 + step * 4, sy + 18, 56 - step * 8, 1, OUTLINE_S3)

    # Arbusto e Samambaia Cartoon (192..255, 60..95)
    draw_cartoon_lobe(sheet, 192 + 16, 75, 12, 8, PAL_S3_TREE, OUTLINE_S3)
    draw_cartoon_lobe(sheet, 192 + 42, 77, 10, 7, PAL_S3_GRASS, OUTLINE_S3)

    sheet.save_png(os.path.join(s3_dir, "spritesheet_assets_cartoon_25d.png"))

    # 2. Tiles de Terreno
    tiles = Canvas(128, 64)
    # Tile 0: Grama das Terras Altas
    for y in range(32):
        for x in range(32):
            col = PAL_S3_GRASS[1] if (x + y) % 5 == 0 else PAL_S3_GRASS[2]
            tiles.set_pixel(x, y, col)

    # Tile 1: Grama com Pedra
    for y in range(32):
        for x in range(32):
            col = PAL_S3_GRASS[1] if (x + y) % 5 == 0 else PAL_S3_GRASS[2]
            tiles.set_pixel(32 + x, y, col)
    draw_cartoon_lobe(tiles, 32 + 16, 16, 6, 4, PAL_S3_STONE, OUTLINE_S3)

    # Tile 2: Trilha de Lajes de Granito
    tiles.draw_rect(64, 0, 32, 32, PAL_S1_WOOD[0]) # dirt base
    lajes = [(64 + 8, 8, 7, 5), (64 + 22, 10, 6, 5), (64 + 14, 22, 8, 6)]
    for lx, ly, lrx, lry in lajes:
        for dy in range(-lry, lry + 1):
            for dx in range(-lrx, lrx + 1):
                if (dx*dx)/float(lrx*lrx) + (dy*dy)/float(lry*lry) <= 1.0:
                    val = - (dx * 0.7 + dy * 0.7)
                    col = PAL_S3_STONE[4] if val > 2 else (PAL_S3_STONE[3] if val > 0 else PAL_S3_STONE[1])
                    tiles.set_pixel(lx + dx, ly + dy, col)

    # Tile 3: Degrau de Terraço
    for y in range(16):
        for x in range(32):
            tiles.set_pixel(96 + x, y, PAL_S3_GRASS[2])
    tiles.draw_rect(96, 16, 32, 16, PAL_S3_STONE[2])
    tiles.draw_rect(96, 16, 32, 1, PAL_S3_STONE[4])
    tiles.draw_rect(96, 15, 32, 1, OUTLINE_S3)

    tiles.save_png(os.path.join(s3_dir, "tiles_terreno_cartoon_25d.png"))


if __name__ == '__main__':
    print("Generating sessao.v2 Cartoon 2.5D assets...")
    generate_sessao1_cartoon()
    generate_sessao2_cartoon()
    generate_sessao3_cartoon()
    print("All sessao.v2 Cartoon assets generated successfully!")
