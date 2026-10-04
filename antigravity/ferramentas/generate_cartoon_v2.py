"""
Generator for sessao.v2: Estilo Cartoon 2.5D inspirado na nova referência (Screenshot 2026-10-04 160858.png)
Implements authentic painterly-pixel cartoon art:
- Soft clumpy grass with pastel lime/mint highlights
- Stepped rock cliff ledge with carved stone stairs
- Ancient teal-slate monolith with glowing cyan runic cores
- Towering ancient trees with glowing shelf mushrooms and hollow logs
- Vibrant cobblestones, ferns, and wildflower bushes
"""

import math
import os
import random
from pixel_art_tool import Canvas, hex_to_rgba

BASE_DIR = r"c:\Users\pattr\pixel-chess\antigravity\entregas\sessao.v2"
os.makedirs(BASE_DIR, exist_ok=True)

C_TRANSP = (0, 0, 0, 0)

# --- Paleta Extraída e Harmonizada com Screenshot 2026-10-04 160858.png ---
# Grama Macia Cartoon
GRASS_CARTOON = [
    hex_to_rgba('#284422'), # 0: Sombra profunda
    hex_to_rgba('#426E34'), # 1: Sombra base
    hex_to_rgba('#669C48'), # 2: Tom médio
    hex_to_rgba('#8EC464'), # 3: Luz verde-limão
    hex_to_rgba('#BCE88C'), # 4: Highlight pastel
    hex_to_rgba('#E0FAC2'), # 5: Brilho de topo
]

# Rocha do Barranco / Encosta (Terracota avermelhada)
CLIFF_ROCK = [
    hex_to_rgba('#341E1A'), # 0: Sombra fenda
    hex_to_rgba('#563228'), # 1: Sombra pedra
    hex_to_rgba('#804A3C'), # 2: Base terracota
    hex_to_rgba('#AE6854'), # 3: Luz
    hex_to_rgba('#D88C76'), # 4: Aresta chanfrada
]

# Trilha de Areia Clara
PATH_SAND = [
    hex_to_rgba('#685638'), # 0: Sombra
    hex_to_rgba('#9A8254'), # 1: Base
    hex_to_rgba('#C4AC74'), # 2: Areia média
    hex_to_rgba('#DEC894'), # 3: Luz areia
    hex_to_rgba('#F4E4BA'), # 4: Highlight claro
]

# Monólito Rúnico & Ardósia Azulada (Teal Stone)
RUNIC_STONE = [
    hex_to_rgba('#1E2E34'), # 0: Sombra profunda
    hex_to_rgba('#324B54'), # 1: Sombra média
    hex_to_rgba('#4E727C'), # 2: Base ardósia
    hex_to_rgba('#729FA8'), # 3: Luz
    hex_to_rgba('#A4CCD4'), # 4: Aresta chanfrada
]

# Brilho Rúnico Ciano
CYAN_GLOW = [
    hex_to_rgba('#109898'), # 0
    hex_to_rgba('#20DADA'), # 1
    hex_to_rgba('#66FFFF'), # 2: Núcleo brilhante
]

# Tronco Quente / Madeira
WOOD_WARM = [
    hex_to_rgba('#2E1C14'), # 0
    hex_to_rgba('#4E2E20'), # 1
    hex_to_rgba('#784832'), # 2
    hex_to_rgba('#A86848'), # 3
    hex_to_rgba('#D08C64'), # 4
]

# Cogumelos Bioluminescentes (Teal)
MUSHROOM_GLOW = [
    hex_to_rgba('#149C7E'),
    hex_to_rgba('#2CE2B6'),
    hex_to_rgba('#82FFE2'),
]

# Flores Lilás / Magenta
FLOWER_LILAC = [
    hex_to_rgba('#9C3886'),
    hex_to_rgba('#D05EBA'),
    hex_to_rgba('#F69EE4'),
]

OUTLINE_CARTOON = hex_to_rgba('#181C1A')
SHADOW_SOFT = hex_to_rgba('#18221E', 150)


# --- Helper: Draw Painterly Cartoon Foliage Cloud / Lobe ---
def draw_painterly_lobe(canvas, cx, cy, rx, ry, pal=GRASS_CARTOON, outline_col=OUTLINE_CARTOON):
    for dy in range(-ry, ry + 1):
        for dx in range(-rx, rx + 1):
            if (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry) <= 1.0:
                nx = dx / float(rx)
                ny = dy / float(ry)
                val = - (nx * 0.65 + ny * 0.75)

                if val > 0.45:
                    col = pal[4]
                elif val > 0.05:
                    col = pal[3]
                elif val > -0.35:
                    col = pal[2]
                elif val > -0.70:
                    col = pal[1]
                else:
                    col = pal[0]
                canvas.set_pixel(cx + dx, cy + dy, col)

    # Cloud highlight crest (fluffy puff)
    hl_rx = max(2, rx // 2)
    hl_ry = max(2, ry // 2)
    hl_cx = cx - rx // 3
    hl_cy = cy - ry // 3
    for dy in range(-hl_ry, hl_ry + 1):
        for dx in range(-hl_rx, hl_rx + 1):
            if (dx*dx)/float(hl_rx*hl_rx) + (dy*dy)/float(hl_ry*hl_ry) <= 1.0:
                canvas.set_pixel(hl_cx + dx, hl_cy + dy, pal[5] if len(pal) > 5 else pal[4])

    # Clean dark outline
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


# --- Helper: Draw Ancient Tree Trunk with Mushroom Bracket Shelf ---
def draw_ancient_trunk(canvas, x_base, y_base, width, height, has_mushroom=True):
    for y in range(y_base, y_base + height):
        prog = (y - y_base) / float(height)
        cur_w = int(width * (0.8 + prog * 0.45))
        x0 = x_base - cur_w // 2

        for x in range(x0, x0 + cur_w):
            fx = (x - x0) / float(cur_w)
            if fx < 0.25:
                col = WOOD_WARM[4]
            elif fx < 0.60:
                col = WOOD_WARM[3]
            elif fx < 0.85:
                col = WOOD_WARM[2]
            else:
                col = WOOD_WARM[1]
            canvas.set_pixel(x, y, col)

        canvas.set_pixel(x0 - 1, y, OUTLINE_CARTOON)
        canvas.set_pixel(x0 + cur_w, y, OUTLINE_CARTOON)

    # Base roots branching out
    y_bot = y_base + height
    for i in range(5):
        canvas.set_pixel(x_base - width//2 - i, y_bot - 1 + i//2, WOOD_WARM[3])
        canvas.set_pixel(x_base - width//2 - i, y_bot + i//2, OUTLINE_CARTOON)
        canvas.set_pixel(x_base + width//2 + i, y_bot - 1 + i//2, WOOD_WARM[1])
        canvas.set_pixel(x_base + width//2 + i, y_bot + i//2, OUTLINE_CARTOON)

    # Glowing shelf mushroom attached to trunk (seen on reference trees!)
    if has_mushroom:
        mx = x_base - width // 2 - 2
        my = y_base + height // 2
        for dx in range(-4, 2):
            canvas.set_pixel(mx + dx, my, MUSHROOM_GLOW[2] if dx < -1 else MUSHROOM_GLOW[1])
            canvas.set_pixel(mx + dx, my + 1, MUSHROOM_GLOW[0])
            canvas.set_pixel(mx + dx, my + 2, OUTLINE_CARTOON)


# ==============================================================================
# SESSÃO 1: CLAREIRA DO SANTUÁRIO MÍSTICO (Refletindo a nova referência)
# ==============================================================================
def build_sessao1_ref():
    s1_dir = os.path.join(BASE_DIR, "sessao-01-floresta-nordica")
    os.makedirs(s1_dir, exist_ok=True)

    # 1. Spritesheet de Assets (256x160 px)
    sheet = Canvas(256, 160)

    # Asset 1: Árvore Ancestral com Cogumelos (96x128 em 0..95, 0..127)
    draw_ancient_trunk(sheet, x_base=48, y_base=68, width=14, height=32, has_mushroom=True)
    oak_lobes = [
        (48, 54, 26, 17),
        (26, 46, 20, 16),
        (70, 48, 20, 16),
        (24, 30, 18, 14),
        (72, 32, 18, 14),
        (48, 26, 28, 20),
        (38, 14, 18, 13),
        (58, 15, 17, 13),
    ]
    for cx, cy, rx, ry in oak_lobes:
        draw_painterly_lobe(sheet, cx, cy, rx, ry, GRASS_CARTOON, OUTLINE_CARTOON)

    # Asset 2: Monólito Rúnico com Orbe Ciano Brilhante (96..143, 0..95)
    # Monolith body (width 20, height 56)
    mx, my = 120, 50
    for dy in range(-28, 29):
        # Slightly tapered top
        fy = (dy + 28) / 56.0
        cur_w = 9 if dy < -16 else 11
        for dx in range(-cur_w, cur_w + 1):
            if dx == -cur_w:
                col = RUNIC_STONE[4] # left edge
            elif dx < 0:
                col = RUNIC_STONE[3] # light
            elif dx < cur_w - 2:
                col = RUNIC_STONE[2] # body
            else:
                col = RUNIC_STONE[1] # shadow
            sheet.set_pixel(mx + dx, my + dy, col)

    # Chiseled facet angles
    for dy in range(-28, -16):
        sheet.set_pixel(mx - 8 + (dy + 28)//2, my + dy, RUNIC_STONE[4])
    # Glowing Cyan Rune Orbs
    for orb_y in [my - 14, my + 6]:
        sheet.draw_circle(mx, orb_y, 4, CYAN_GLOW[0])
        sheet.draw_circle(mx, orb_y, 3, CYAN_GLOW[1])
        sheet.draw_circle(mx - 1, orb_y - 1, 2, CYAN_GLOW[2])

    # Outlines for monolith
    for dy in range(-29, 30):
        sheet.set_pixel(mx - 12, my + dy, OUTLINE_CARTOON)
        sheet.set_pixel(mx + 12, my + dy, OUTLINE_CARTOON)
    sheet.draw_rect(mx - 11, my - 29, 23, 1, OUTLINE_CARTOON)
    sheet.draw_rect(mx - 11, my + 29, 23, 1, OUTLINE_CARTOON)

    # Asset 3: Tronco Oco Caído (144..207, 0..47)
    # Hollow log from the screenshot
    lx, ly = 176, 26
    # Outer bark cylinder
    for dy in range(-6, 7):
        for dx in range(-24, 25):
            if (dx*dx)/576.0 + (dy*dy)/36.0 <= 1.0:
                val = - (dx * 0.2 + dy * 0.9)
                col = WOOD_WARM[3] if val > 2 else (WOOD_WARM[2] if val > -2 else WOOD_WARM[1])
                sheet.set_pixel(lx + dx, ly + dy, col)
    # Hollow black cavity on left side
    for dy in range(-4, 5):
        for dx in range(-6, 2):
            if (dx*dx)/16.0 + (dy*dy)/16.0 <= 1.0:
                sheet.set_pixel(lx - 20 + dx, ly + dy, OUTLINE_CARTOON)
    # Pair of cute glowing eyes inside log!
    sheet.set_pixel(lx - 21, ly, hex_to_rgba('#FFFFFF'))
    sheet.set_pixel(lx - 19, ly, hex_to_rgba('#FFFFFF'))

    # Asset 4: Degraus de Pedra do Barranco (144..207, 50..95)
    # Stone steps (4 steps)
    for s in range(4):
        sy = 54 + s * 9
        sw = 42 - s * 4
        sheet.draw_rect(176 - sw//2, sy, sw, 8, CLIFF_ROCK[2])
        sheet.draw_rect(176 - sw//2, sy, sw, 1, CLIFF_ROCK[4]) # step tread highlight
        sheet.draw_rect(176 - sw//2 - 1, sy - 1, sw + 2, 1, OUTLINE_CARTOON)
        sheet.draw_rect(176 - sw//2 - 1, sy + 8, sw + 2, 1, OUTLINE_CARTOON)

    # Asset 5: Cogumelos Brilhantes & Flores Lilás (208..255, 0..63)
    # 2 glowing teal mushrooms
    sheet.draw_circle(224, 20, 5, MUSHROOM_GLOW[1])
    sheet.set_pixel(223, 19, MUSHROOM_GLOW[2])
    sheet.draw_rect(223, 24, 3, 5, hex_to_rgba('#DCF4EE'))
    sheet.draw_rect(222, 29, 5, 1, OUTLINE_CARTOON)
    # Lilac wildflower patch
    for fx, fy in [(238, 38), (246, 42), (232, 44)]:
        sheet.draw_circle(fx, fy, 3, FLOWER_LILAC[1])
        sheet.set_pixel(fx, fy, FLOWER_LILAC[2])
        sheet.set_pixel(fx, fy + 4, GRASS_CARTOON[1])
        sheet.set_pixel(fx, fy + 5, OUTLINE_CARTOON)

    # Asset 6: Pedras arredondadas de Margem (208..255, 64..127)
    draw_painterly_lobe(sheet, 226, 85, 10, 7, RUNIC_STONE, OUTLINE_CARTOON)
    draw_painterly_lobe(sheet, 242, 90, 7, 5, RUNIC_STONE, OUTLINE_CARTOON)

    sheet.save_png(os.path.join(s1_dir, "spritesheet_assets_cartoon_25d.png"))

    # 2. Tiles de Terreno Cartoon (128x64 px: 4 tiles de 32x32)
    # Tile 0: Grama Macia em Tufos Cartoon (Base da clareira)
    # Tile 1: Trilha de Areia Clara Suave (Path)
    # Tile 2: Degrau de Barranco com Rocha Terracota e Grama Caindo
    # Tile 3: Calçamento de Lajes Rúnicas
    tiles = Canvas(128, 64)

    # Tile 0: Grama Cartoon
    for y in range(32):
        for x in range(32):
            col = GRASS_CARTOON[2] if (x + y * 2) % 6 in [0, 1] else GRASS_CARTOON[3]
            tiles.set_pixel(x, y, col)
    # Tufos macios
    tiles.set_pixel(12, 10, GRASS_CARTOON[4])
    tiles.set_pixel(13, 10, GRASS_CARTOON[4])
    tiles.set_pixel(12, 11, GRASS_CARTOON[1])

    # Tile 1: Trilha de Areia Clara (Path)
    for y in range(32):
        for x in range(32):
            col = PATH_SAND[2] if (x + y) % 5 in [0, 1] else PATH_SAND[3]
            tiles.set_pixel(32 + x, y, col)
    tiles.set_pixel(32 + 15, 16, PATH_SAND[4])
    tiles.set_pixel(32 + 16, 16, PATH_SAND[0])

    # Tile 2: Barranco de Rocha com Grama Caindo (Exatamente como na referência!)
    # Top 12 px: grass
    for y in range(12):
        for x in range(32):
            tiles.set_pixel(64 + x, y, GRASS_CARTOON[3])
    # Overhang fringe
    for x in range(32):
        drop = 2 if x % 5 in [1, 2] else 0
        tiles.set_pixel(64 + x, 12 + drop, GRASS_CARTOON[4])
        tiles.set_pixel(64 + x, 13 + drop, OUTLINE_CARTOON)
    # Bottom 18 px: warm terracotta cliff rock
    for y in range(15, 32):
        for x in range(32):
            col = CLIFF_ROCK[2] if (x + y) % 6 != 0 else CLIFF_ROCK[1]
            tiles.set_pixel(64 + x, y, col)

    # Tile 3: Calçamento de Lajes Rúnicas com Grama entre frestas
    tiles.draw_rect(96, 0, 32, 32, GRASS_CARTOON[1]) # grass base
    # 4 stone slabs
    for sx, sy in [(98, 2), (114, 2), (98, 18), (114, 18)]:
        tiles.draw_rect(sx, sy, 12, 12, RUNIC_STONE[2])
        tiles.draw_rect(sx, sy, 12, 1, RUNIC_STONE[4])
        tiles.draw_rect(sx, sy, 1, 12, RUNIC_STONE[3])
        tiles.draw_rect(sx - 1, sy - 1, 14, 1, OUTLINE_CARTOON)
        tiles.draw_rect(sx - 1, sy + 12, 14, 1, OUTLINE_CARTOON)
        tiles.draw_rect(sx - 1, sy - 1, 1, 14, OUTLINE_CARTOON)
        tiles.draw_rect(sx + 12, sy - 1, 1, 14, OUTLINE_CARTOON)

    tiles.save_png(os.path.join(s1_dir, "tiles_terreno_cartoon_25d.png"))


# ==============================================================================
# SESSÃO 2: CAMPINA SOLAR DAS FLORES (Vila & Campina Cartoon)
# ==============================================================================
def build_sessao2_ref():
    s2_dir = os.path.join(BASE_DIR, "sessao-02-campina-solar")
    os.makedirs(s2_dir, exist_ok=True)

    sheet = Canvas(256, 160)

    # Carvalho Solar Cartoon (96x128 em 0..95, 0..127)
    draw_ancient_trunk(sheet, x_base=48, y_base=68, width=14, height=32, has_mushroom=False)
    # Bright sunlit foliage lobes
    lobes_s2 = [
        (48, 54, 26, 17),
        (26, 46, 20, 16),
        (70, 48, 20, 16),
        (22, 30, 18, 14),
        (74, 32, 18, 14),
        (48, 26, 28, 20),
        (38, 14, 18, 13),
        (58, 15, 17, 13),
    ]
    # S2 Grass palette (warm golden green)
    for cx, cy, rx, ry in lobes_s2:
        draw_painterly_lobe(sheet, cx, cy, rx, ry, [
            hex_to_rgba('#2A5220'), hex_to_rgba('#48822A'), hex_to_rgba('#72BE3C'),
            hex_to_rgba('#A6E64E'), hex_to_rgba('#D6FA72'), hex_to_rgba('#F4FFB0')
        ], OUTLINE_CARTOON)

    # Pinheiro Solar Cartoon (96..159, 0..127)
    draw_ancient_trunk(sheet, x_base=96 + 32, y_base=80, width=8, height=26, has_mushroom=False)
    for i, py in enumerate([78, 62, 46, 32, 18]):
        draw_painterly_lobe(sheet, 96 + 32, py, 24 - i * 4, 14 - i * 2, [
            hex_to_rgba('#1E4A28'), hex_to_rgba('#32783E'), hex_to_rgba('#52B05E'),
            hex_to_rgba('#82E28E'), hex_to_rgba('#BEFFA8')
        ], OUTLINE_CARTOON)

    # Mureta de Pedra Seca Arredondada (160..223, 0..31)
    sheet.draw_rect(160 + 2, 10, 58, 15, RUNIC_STONE[2])
    sheet.draw_rect(160 + 2, 9, 58, 2, RUNIC_STONE[4])
    for x in range(160 + 14, 160 + 60, 14):
        sheet.draw_rect(x, 10, 1, 15, OUTLINE_CARTOON)
    sheet.draw_rect(160 + 2, 17, 58, 1, OUTLINE_CARTOON)
    sheet.draw_rect(160 + 1, 8, 60, 1, OUTLINE_CARTOON)
    sheet.draw_rect(160 + 1, 25, 60, 1, OUTLINE_CARTOON)

    # Banco de Madeira e Tocos (160..223, 36..63)
    sheet.draw_rect(160 + 6, 42, 48, 8, WOOD_WARM[3])
    sheet.draw_rect(160 + 6, 41, 48, 1, WOOD_WARM[4])
    sheet.draw_rect(160 + 5, 40, 50, 1, OUTLINE_CARTOON)
    sheet.draw_rect(160 + 5, 50, 50, 1, OUTLINE_CARTOON)
    sheet.draw_rect(160 + 12, 51, 6, 8, WOOD_WARM[2])
    sheet.draw_rect(160 + 42, 51, 6, 8, WOOD_WARM[2])

    # Canteiros de Flores Brancas e Amarelas (160..223, 68..95)
    for fx, fy in [(160 + 16, 76), (160 + 32, 80), (160 + 48, 74)]:
        sheet.draw_circle(fx, fy, 4, hex_to_rgba('#FFFFFF'))
        sheet.set_pixel(fx, fy, hex_to_rgba('#F6DE4C'))
        sheet.set_pixel(fx, fy + 5, GRASS_CARTOON[1])
        sheet.set_pixel(fx, fy + 6, OUTLINE_CARTOON)

    sheet.save_png(os.path.join(s2_dir, "spritesheet_assets_cartoon_25d.png"))

    # Tiles S2
    tiles = Canvas(128, 64)
    # Tile 0: Grama Solar
    for y in range(32):
        for x in range(32):
            col = hex_to_rgba('#72BE3C') if (x + y) % 4 in [0, 1] else hex_to_rgba('#A6E64E')
            tiles.set_pixel(x, y, col)
    # Tile 1: Grama com Flores
    tiles.blit(tiles, 32, 0)
    tiles.draw_circle(32 + 16, 16, 3, hex_to_rgba('#FFFFFF'))
    tiles.set_pixel(32 + 16, 16, hex_to_rgba('#F6DE4C'))
    # Tile 2: Calçamento de Paralelepípedos Almofadados (Pebble Cobble)
    tiles.draw_rect(64, 0, 32, 32, PATH_SAND[0])
    for row in range(4):
        y0 = row * 8
        off = 4 if row % 2 == 1 else 0
        for col in range(5):
            x0 = (col * 8 + off) % 32
            for dy in range(6):
                for dx in range(6):
                    px = (x0 + dx) % 32
                    c_pix = PATH_SAND[4] if (dy == 0 and dx < 5) else (PATH_SAND[3] if dy < 4 else PATH_SAND[1])
                    tiles.set_pixel(64 + px, y0 + dy, c_pix)
    # Tile 3: Mureta seca integrada
    for y in range(32):
        for x in range(32):
            tiles.set_pixel(96 + x, y, hex_to_rgba('#72BE3C'))
    tiles.draw_rect(96, 12, 32, 10, RUNIC_STONE[2])
    tiles.draw_rect(96, 11, 32, 1, RUNIC_STONE[4])
    tiles.draw_rect(96, 10, 32, 1, OUTLINE_CARTOON)
    tiles.draw_rect(96, 22, 32, 1, OUTLINE_CARTOON)

    tiles.save_png(os.path.join(s2_dir, "tiles_terreno_cartoon_25d.png"))


# ==============================================================================
# SESSÃO 3: ENCOSTA DO RIACHO & DESFILADEIRO (Highland / Stream Cartoon)
# ==============================================================================
def build_sessao3_ref():
    s3_dir = os.path.join(BASE_DIR, "sessao-03-terraco-rochoso")
    os.makedirs(s3_dir, exist_ok=True)

    sheet = Canvas(256, 160)

    # Pinheiro em Leque das Encostas (0..95, 0..127)
    draw_ancient_trunk(sheet, x_base=48, y_base=80, width=10, height=28, has_mushroom=True)
    for i, py in enumerate([78, 62, 46, 32, 18]):
        draw_painterly_lobe(sheet, 48, py, 28 - i * 4, 15 - i * 2, [
            hex_to_rgba('#1A3C2A'), hex_to_rgba('#2A6440'), hex_to_rgba('#42945E'),
            hex_to_rgba('#6EC886'), hex_to_rgba('#A6F2B8')
        ], OUTLINE_CARTOON)

    # Árvore Ancestral de Riacho (96..191, 0..127)
    draw_ancient_trunk(sheet, x_base=96 + 48, y_base=64, width=12, height=28, has_mushroom=False)
    for cx_o, cy_o in [(-18, -12), (18, -10), (-20, -26), (20, -24), (0, -32), (0, -46)]:
        draw_painterly_lobe(sheet, 96 + 48 + cx_o, 64 + cy_o, 18, 14, GRASS_CARTOON, OUTLINE_CARTOON)

    # Seixos de Rio e Água (192..255, 0..48)
    draw_painterly_lobe(sheet, 192 + 16, 20, 12, 8, RUNIC_STONE, OUTLINE_CARTOON)
    draw_painterly_lobe(sheet, 192 + 40, 22, 9, 6, RUNIC_STONE, OUTLINE_CARTOON)

    # Samambaia e Tufos (192..255, 60..95)
    draw_painterly_lobe(sheet, 192 + 20, 75, 12, 8, GRASS_CARTOON, OUTLINE_CARTOON)
    draw_painterly_lobe(sheet, 192 + 44, 77, 10, 7, GRASS_CARTOON, OUTLINE_CARTOON)

    sheet.save_png(os.path.join(s3_dir, "spritesheet_assets_cartoon_25d.png"))

    # Tiles S3
    tiles = Canvas(128, 64)
    # Tile 0: Grama das Encostas
    for y in range(32):
        for x in range(32):
            col = hex_to_rgba('#42945E') if (x + y) % 5 == 0 else hex_to_rgba('#6EC886')
            tiles.set_pixel(x, y, col)
    # Tile 1: Grama com Água
    for y in range(32):
        for x in range(32):
            c_water = hex_to_rgba('#3B6E8C') if x > 18 else hex_to_rgba('#6EC886')
            tiles.set_pixel(32 + x, y, c_water)
    for y in range(32):
        tiles.set_pixel(32 + 18, y, OUTLINE_CARTOON)
        tiles.set_pixel(32 + 17, y, RUNIC_STONE[4])
    # Tile 2: Trilha de Lajes de Granito
    tiles.draw_rect(64, 0, 32, 32, WOOD_WARM[0])
    lajes = [(64 + 8, 8, 7, 5), (64 + 22, 10, 6, 5), (64 + 14, 22, 8, 6)]
    for lx, ly, lrx, lry in lajes:
        for dy in range(-lry, lry + 1):
            for dx in range(-lrx, lrx + 1):
                if (dx*dx)/float(lrx*lrx) + (dy*dy)/float(lry*lry) <= 1.0:
                    val = - (dx * 0.7 + dy * 0.7)
                    col = RUNIC_STONE[4] if val > 2 else (RUNIC_STONE[3] if val > 0 else RUNIC_STONE[1])
                    tiles.set_pixel(lx + dx, ly + dy, col)
    # Tile 3: Degrau de Terraço
    for y in range(16):
        for x in range(32):
            tiles.set_pixel(96 + x, y, hex_to_rgba('#6EC886'))
    tiles.draw_rect(96, 16, 32, 16, RUNIC_STONE[2])
    tiles.draw_rect(96, 16, 32, 1, RUNIC_STONE[4])
    tiles.draw_rect(96, 15, 32, 1, OUTLINE_CARTOON)

    tiles.save_png(os.path.join(s3_dir, "tiles_terreno_cartoon_25d.png"))


if __name__ == '__main__':
    print("Generating refined cartoon 2.5D assets inspired by Screenshot 2026-10-04 160858.png...")
    build_sessao1_ref()
    build_sessao2_ref()
    build_sessao3_ref()
    print("All assets refined successfully!")
