"""
Generator for ART-003 v2: Vegetação e Props 2.5D
Implements authentic 2.5D pixel-art assets based on the Eiyuden / Octopath references:
- Vertical tall pine trees with cascading needle boughs
- Voluminous deciduous trees & birch
- Ferns & lush bushes
- Mossy river boulders & megaliths
- Arena stone retaining walls with pilasters & banners
- 2.5D directional drop shadows
"""

import math
import os
import random
from pixel_art_tool import Canvas, hex_to_rgba

OUT_DIR = r"c:\Users\pattr\pixel-chess\antigravity\entregas\ART-003\v2"
os.makedirs(OUT_DIR, exist_ok=True)

# --- 2.5D Palette ---
C_TRANSPARENT = (0, 0, 0, 0)

# Folhagem de Pinheiro (Deep evergreen needle boughs)
PINE_FOLIAGE = [
    hex_to_rgba('#0F2418'), # 0: Sombra profunda
    hex_to_rgba('#183824'), # 1: Sombra verde-escura
    hex_to_rgba('#275436'), # 2: Tom médio
    hex_to_rgba('#3D784D'), # 3: Luz verde
    hex_to_rgba('#5EAA6E'), # 4: Highlight de agulhas
    hex_to_rgba('#8EDB9F'), # 5: Ponta solar
]

# Folhagem de Carvalho / Decídua (Lush organic clusters)
OAK_FOLIAGE = [
    hex_to_rgba('#1B331A'), # 0
    hex_to_rgba('#2B4D25'), # 1
    hex_to_rgba('#437033'), # 2
    hex_to_rgba('#659B45'), # 3
    hex_to_rgba('#8EC257'), # 4
    hex_to_rgba('#BDE86E'), # 5
]

# Tronco de Madeira Quente (Pine & Oak)
WOOD_TRUNK = [
    hex_to_rgba('#2D1F15'), # 0
    hex_to_rgba('#4A3323'), # 1
    hex_to_rgba('#6E4E37'), # 2
    hex_to_rgba('#966E50'), # 3
]

# Tronco de Bétula (Light bark with dark lenticels)
BIRCH_TRUNK = [
    hex_to_rgba('#383533'), # nós
    hex_to_rgba('#75706B'), # sombra
    hex_to_rgba('#A8A39D'), # corpo
    hex_to_rgba('#D6D2CC'), # luz
    hex_to_rgba('#F2EFE9'), # highlight
]

# Pedra da Arena / Caliço (Limestone & Grey Paver)
STONE_ARENA = [
    hex_to_rgba('#302D2A'), # 0: Sombra
    hex_to_rgba('#524D47'), # 1
    hex_to_rgba('#7A736A'), # 2: Base
    hex_to_rgba('#A8A094'), # 3: Luz
    hex_to_rgba('#D4CCC0'), # 4: Highlight aresta
]

# Estandarte Verde da Arena (matching reference colosseum banner)
BANNER_GREEN = [
    hex_to_rgba('#144726'),
    hex_to_rgba('#277840'),
    hex_to_rgba('#45B865'),
    hex_to_rgba('#F2DE6D'), # franja dourada
]

# Cores de Detalhes
FLOWER_YELLOW = hex_to_rgba('#F6DE4C')
FLOWER_WHITE  = hex_to_rgba('#F2F2EB')
OUTLINE_25D   = hex_to_rgba('#121714')
SHADOW_25D    = hex_to_rgba('#121714', 165)


# --- 1. Large Trees (96x96, transparent) ---
def build_large_trees_25d():
    # Tree A: Tall Grand Pine (Pinheiro Real 2.5D - matching reference screenshots)
    ta = Canvas(96, 96)
    # Trunk
    for y in range(60, 88):
        w = 8 if y < 75 else 10
        x0 = 48 - w // 2
        for x in range(x0, x0 + w):
            fx = (x - x0) / float(w)
            col = WOOD_TRUNK[3] if fx < 0.25 else (WOOD_TRUNK[2] if fx < 0.6 else WOOD_TRUNK[0])
            ta.set_pixel(x, y, col)
        ta.set_pixel(x0 - 1, y, OUTLINE_25D)
        ta.set_pixel(x0 + w, y, OUTLINE_25D)
    # Roots
    for i in range(4):
        ta.set_pixel(43 - i, 87 + i//2, WOOD_TRUNK[2])
        ta.set_pixel(43 - i, 88 + i//2, OUTLINE_25D)
        ta.set_pixel(52 + i, 87 + i//2, WOOD_TRUNK[0])
        ta.set_pixel(52 + i, 88 + i//2, OUTLINE_25D)

    # 6 cascading needle branch tiers (from bottom to top)
    tiers = [
        (48, 66, 32, 14, 1), # tier 1 (lowest, widest)
        (48, 54, 28, 13, 2), # tier 2
        (48, 43, 23, 12, 3), # tier 3
        (48, 33, 18, 11, 4), # tier 4
        (48, 23, 13, 10, 5), # tier 5
        (48, 14, 7, 9, 6),   # apex cone
    ]

    for cx, cy, rx, ry, seed in tiers:
        for dy in range(-ry, ry + 1):
            # Triangle/tiered needle shape: wider at bottom
            fy = (dy + ry) / float(max(1, 2 * ry))
            cur_rx = int(rx * (0.3 + fy * 0.7))
            for dx in range(-cur_rx, cur_rx + 1):
                # Needle serration on bottom edge
                if dy == ry and (dx % 2 == 1):
                    continue
                nx = dx / float(max(1, cur_rx))
                ny = dy / float(max(1, ry))
                light = - (nx * 0.6 + ny * 0.7)

                if light > 0.5:
                    col = PINE_FOLIAGE[5] if nx < -0.3 else PINE_FOLIAGE[4]
                elif light > 0.1:
                    col = PINE_FOLIAGE[3]
                elif light > -0.3:
                    col = PINE_FOLIAGE[2]
                elif light > -0.65:
                    col = PINE_FOLIAGE[1]
                else:
                    col = PINE_FOLIAGE[0]
                ta.set_pixel(cx + dx, cy + dy, col)

    # Add outline
    edges = []
    for y in range(96):
        for x in range(96):
            if ta.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if ta.get_pixel(nx, ny)[3] == 0:
                        edges.append((nx, ny))
    for ex, ey in edges:
        ta.set_pixel(ex, ey, OUTLINE_25D)
    ta.save_png(os.path.join(OUT_DIR, "art-003_arvore-grande_a.png"))

    # Tree B: Grand Deciduous Oak 2.5D (Carvalho Frondoso 2.5D)
    tb = Canvas(96, 96)
    # Sturdy gnarled oak trunk
    for y in range(54, 88):
        w = 11 if y < 72 else 14
        x0 = 48 - w // 2
        for x in range(x0, x0 + w):
            fx = (x - x0) / float(w)
            col = WOOD_TRUNK[3] if fx < 0.25 else (WOOD_TRUNK[2] if fx < 0.65 else WOOD_TRUNK[0])
            tb.set_pixel(x, y, col)
        tb.set_pixel(x0 - 1, y, OUTLINE_25D)
        tb.set_pixel(x0 + w, y, OUTLINE_25D)
    # Roots branching
    for i in range(5):
        tb.set_pixel(42 - i, 86 + i//2, WOOD_TRUNK[2])
        tb.set_pixel(42 - i, 87 + i//2, OUTLINE_25D)
        tb.set_pixel(54 + i, 86 + i//2, WOOD_TRUNK[0])
        tb.set_pixel(54 + i, 87 + i//2, OUTLINE_25D)

    # Voluminous rounded 2.5D clusters (overlapping front to back)
    oak_clusters = [
        (48, 48, 24, 16),
        (30, 44, 20, 15),
        (66, 46, 20, 15),
        (26, 30, 19, 15),
        (68, 32, 19, 15),
        (48, 26, 26, 19),
        (40, 15, 18, 14),
        (58, 17, 17, 13),
    ]
    for cx, cy, rx, ry in oak_clusters:
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                if (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry) <= 1.0:
                    nx = dx / float(rx)
                    ny = dy / float(ry)
                    light = - (nx * 0.6 + ny * 0.75)
                    if light > 0.45:
                        col = OAK_FOLIAGE[5] if nx < -0.3 else OAK_FOLIAGE[4]
                    elif light > 0.05:
                        col = OAK_FOLIAGE[3]
                    elif light > -0.35:
                        col = OAK_FOLIAGE[2]
                    elif light > -0.70:
                        col = OAK_FOLIAGE[1]
                    else:
                        col = OAK_FOLIAGE[0]
                    tb.set_pixel(cx + dx, cy + dy, col)

    edges_b = []
    for y in range(96):
        for x in range(96):
            if tb.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if tb.get_pixel(nx, ny)[3] == 0:
                        edges_b.append((nx, ny))
    for ex, ey in edges_b:
        tb.set_pixel(ex, ey, OUTLINE_25D)
    tb.save_png(os.path.join(OUT_DIR, "art-003_arvore-grande_b.png"))

    # Tree C: Nordic Birch 2.5D (Bétula Nórdica 2.5D)
    tc = Canvas(96, 96)
    # Slender birch trunk with lenticels
    for y in range(50, 88):
        w = 7 if y < 70 else 9
        x0 = 48 - w // 2
        for x in range(x0, x0 + w):
            fx = (x - x0) / float(w)
            col = BIRCH_TRUNK[4] if fx < 0.3 else (BIRCH_TRUNK[3] if fx < 0.65 else BIRCH_TRUNK[1])
            tc.set_pixel(x, y, col)
        tc.set_pixel(x0 - 1, y, OUTLINE_25D)
        tc.set_pixel(x0 + w, y, OUTLINE_25D)
    # Dark horizontal notches
    for ny in [56, 62, 68, 74, 80]:
        tc.set_pixel(46, ny, BIRCH_TRUNK[0])
        tc.set_pixel(47, ny, BIRCH_TRUNK[0])
        tc.set_pixel(49, ny + 2, BIRCH_TRUNK[0])

    birch_clusters = [
        (34, 48, 16, 13),
        (64, 46, 17, 14),
        (48, 42, 22, 16),
        (30, 30, 18, 15),
        (66, 28, 18, 14),
        (48, 22, 23, 17),
        (42, 12, 15, 11),
        (56, 14, 14, 11),
    ]
    for cx, cy, rx, ry in birch_clusters:
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                if (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry) <= 1.0:
                    nx = dx / float(rx)
                    ny = dy / float(ry)
                    light = - (nx * 0.6 + ny * 0.75)
                    if light > 0.45:
                        col = OAK_FOLIAGE[4]
                    elif light > 0.05:
                        col = OAK_FOLIAGE[3]
                    elif light > -0.35:
                        col = OAK_FOLIAGE[2]
                    elif light > -0.70:
                        col = OAK_FOLIAGE[1]
                    else:
                        col = OAK_FOLIAGE[0]
                    tc.set_pixel(cx + dx, cy + dy, col)

    edges_c = []
    for y in range(96):
        for x in range(96):
            if tc.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if tc.get_pixel(nx, ny)[3] == 0:
                        edges_c.append((nx, ny))
    for ex, ey in edges_c:
        tc.set_pixel(ex, ey, OUTLINE_25D)
    tc.save_png(os.path.join(OUT_DIR, "art-003_arvore-grande_c.png"))


# --- 2. Small Trees (64x64, transparent) ---
def build_small_trees_25d():
    # Small Tree A: Compact Young Pine (Pinheiro Jovem 2.5D)
    sa = Canvas(64, 64)
    for y in range(38, 58):
        w = 6
        x0 = 32 - w // 2
        for x in range(x0, x0 + w):
            fx = (x - x0) / float(w)
            col = WOOD_TRUNK[3] if fx < 0.3 else (WOOD_TRUNK[2] if fx < 0.7 else WOOD_TRUNK[0])
            sa.set_pixel(x, y, col)
        sa.set_pixel(x0 - 1, y, OUTLINE_25D)
        sa.set_pixel(x0 + w, y, OUTLINE_25D)

    tiers = [
        (32, 42, 20, 11),
        (32, 32, 16, 10),
        (32, 22, 12, 9),
        (32, 13, 6, 7),
    ]
    for cx, cy, rx, ry in tiers:
        for dy in range(-ry, ry + 1):
            fy = (dy + ry) / float(max(1, 2 * ry))
            cur_rx = int(rx * (0.35 + fy * 0.65))
            for dx in range(-cur_rx, cur_rx + 1):
                nx = dx / float(max(1, cur_rx))
                ny = dy / float(max(1, ry))
                light = - (nx * 0.6 + ny * 0.7)
                col = PINE_FOLIAGE[4] if light > 0.4 else (PINE_FOLIAGE[3] if light > 0.0 else (PINE_FOLIAGE[2] if light > -0.4 else PINE_FOLIAGE[1]))
                sa.set_pixel(cx + dx, cy + dy, col)

    edges_sa = []
    for y in range(64):
        for x in range(64):
            if sa.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if sa.get_pixel(nx, ny)[3] == 0:
                        edges_sa.append((nx, ny))
    for ex, ey in edges_sa:
        sa.set_pixel(ex, ey, OUTLINE_25D)
    sa.save_png(os.path.join(OUT_DIR, "art-003_arvore-pequena_a.png"))

    # Small Tree B: Young Deciduous Sapling (Árvore Jovem Frondosa 2.5D)
    sb = Canvas(64, 64)
    for y in range(36, 58):
        w = 5
        x0 = 32 - w // 2
        for x in range(x0, x0 + w):
            fx = (x - x0) / float(w)
            col = WOOD_TRUNK[3] if fx < 0.3 else (WOOD_TRUNK[2] if fx < 0.7 else WOOD_TRUNK[0])
            sb.set_pixel(x, y, col)
        sb.set_pixel(x0 - 1, y, OUTLINE_25D)
        sb.set_pixel(x0 + w, y, OUTLINE_25D)

    clusters_sb = [
        (32, 34, 15, 11),
        (23, 28, 12, 10),
        (41, 28, 12, 10),
        (32, 20, 16, 12),
        (30, 12, 11, 8),
    ]
    for cx, cy, rx, ry in clusters_sb:
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                if (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry) <= 1.0:
                    nx = dx / float(rx)
                    ny = dy / float(ry)
                    light = - (nx * 0.6 + ny * 0.75)
                    col = OAK_FOLIAGE[4] if light > 0.4 else (OAK_FOLIAGE[3] if light > 0.0 else (OAK_FOLIAGE[2] if light > -0.4 else OAK_FOLIAGE[1]))
                    sb.set_pixel(cx + dx, cy + dy, col)

    edges_sb = []
    for y in range(64):
        for x in range(64):
            if sb.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if sb.get_pixel(nx, ny)[3] == 0:
                        edges_sb.append((nx, ny))
    for ex, ey in edges_sb:
        sb.set_pixel(ex, ey, OUTLINE_25D)
    sb.save_png(os.path.join(OUT_DIR, "art-003_arvore-pequena_b.png"))


# --- 3. Bushes (32x32, transparent) ---
def build_bushes_25d():
    # Bush A: Dense Round Bush 2.5D
    ba = Canvas(32, 32)
    clusters = [(16, 18, 12, 9), (12, 13, 8, 7), (20, 14, 8, 6)]
    for cx, cy, rx, ry in clusters:
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                if (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry) <= 1.0:
                    nx = dx / float(rx)
                    ny = dy / float(ry)
                    light = - (nx * 0.6 + ny * 0.75)
                    col = OAK_FOLIAGE[4] if light > 0.4 else (OAK_FOLIAGE[3] if light > 0.0 else (OAK_FOLIAGE[2] if light > -0.4 else OAK_FOLIAGE[1]))
                    ba.set_pixel(cx + dx, cy + dy, col)
    # Outline
    edges_ba = []
    for y in range(32):
        for x in range(32):
            if ba.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if ba.get_pixel(nx, ny)[3] == 0:
                        edges_ba.append((nx, ny))
    for ex, ey in edges_ba:
        ba.set_pixel(ex, ey, OUTLINE_25D)
    ba.save_png(os.path.join(OUT_DIR, "art-003_arbusto_a.png"))

    # Bush B: Spreading Fern Bush 2.5D (Samambaia Frondosa)
    bb = Canvas(32, 32)
    # Fronds radiating outward
    for angle in [-60, -30, 0, 30, 60]:
        rad = math.radians(angle)
        for d in range(4, 14):
            fx = int(16 + d * math.sin(rad))
            fy = int(22 - d * math.cos(rad) * 0.7)
            col = PINE_FOLIAGE[4] if angle < 0 else (PINE_FOLIAGE[3] if angle == 0 else PINE_FOLIAGE[2])
            bb.set_pixel(fx, fy, col)
            bb.set_pixel(fx + 1, fy, col)
            bb.set_pixel(fx, fy + 1, PINE_FOLIAGE[1])
    edges_bb = []
    for y in range(32):
        for x in range(32):
            if bb.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if bb.get_pixel(nx, ny)[3] == 0:
                        edges_bb.append((nx, ny))
    for ex, ey in edges_bb:
        bb.set_pixel(ex, ey, OUTLINE_25D)
    bb.save_png(os.path.join(OUT_DIR, "art-003_arbusto_b.png"))

    # Bush C: Flowering Field Bush 2.5D
    bc = Canvas(32, 32)
    clusters_c = [(16, 18, 11, 8), (14, 13, 8, 6)]
    for cx, cy, rx, ry in clusters_c:
        for dy in range(-ry, ry + 1):
            for dx in range(-rx, rx + 1):
                if (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry) <= 1.0:
                    nx = dx / float(rx)
                    ny = dy / float(ry)
                    light = - (nx * 0.6 + ny * 0.75)
                    col = OAK_FOLIAGE[4] if light > 0.3 else (OAK_FOLIAGE[3] if light > -0.1 else OAK_FOLIAGE[2])
                    bc.set_pixel(cx + dx, cy + dy, col)
    # Flowers
    for fx, fy, col in [(10, 14, FLOWER_YELLOW), (18, 13, FLOWER_WHITE), (12, 19, FLOWER_WHITE), (21, 17, FLOWER_YELLOW)]:
        bc.set_pixel(fx, fy, col)
        bc.set_pixel(fx + 1, fy, col)
        bc.set_pixel(fx, fy + 1, OAK_FOLIAGE[0])
    edges_bc = []
    for y in range(32):
        for x in range(32):
            if bc.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if bc.get_pixel(nx, ny)[3] == 0:
                        edges_bc.append((nx, ny))
    for ex, ey in edges_bc:
        bc.set_pixel(ex, ey, OUTLINE_25D)
    bc.save_png(os.path.join(OUT_DIR, "art-003_arbusto_c.png"))


# --- 4. Stones & Props (32x32, 64x32) ---
def build_stones_25d():
    # Stone A: Mossy River Boulder 2.5D (32x32)
    sa = Canvas(32, 32)
    for dy in range(-7, 8):
        for dx in range(-10, 11):
            if (dx*dx)/100.0 + (dy*dy)/49.0 <= 1.0:
                val = - (dx * 0.6 + dy * 0.8)
                col = STONE_ARENA[4] if val > 4 else (STONE_ARENA[3] if val > 0 else (STONE_ARENA[2] if val > -4 else STONE_ARENA[1]))
                sa.set_pixel(16 + dx, 18 + dy, col)
    # Moss patch on top
    sa.set_pixel(12, 13, OAK_FOLIAGE[4])
    sa.set_pixel(13, 13, OAK_FOLIAGE[4])
    sa.set_pixel(14, 14, OAK_FOLIAGE[3])
    # Outlines
    edges_sa = []
    for y in range(32):
        for x in range(32):
            if sa.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if sa.get_pixel(nx, ny)[3] == 0:
                        edges_sa.append((nx, ny))
    for ex, ey in edges_sa:
        sa.set_pixel(ex, ey, OUTLINE_25D)
    sa.save_png(os.path.join(OUT_DIR, "art-003_pedra_a.png"))

    # Stone B: Twin Angular Rocks 2.5D (32x32)
    sb = Canvas(32, 32)
    for dy in range(-5, 6):
        for dx in range(-7, 8):
            if (dx*dx)/49.0 + (dy*dy)/25.0 <= 1.0:
                val = - (dx * 0.6 + dy * 0.8)
                col = STONE_ARENA[3] if val > 1 else (STONE_ARENA[2] if val > -2 else STONE_ARENA[1])
                sb.set_pixel(13 + dx, 19 + dy, col)
    for dy in range(-4, 5):
        for dx in range(-5, 6):
            if (dx*dx)/25.0 + (dy*dy)/16.0 <= 1.0:
                val = - (dx * 0.6 + dy * 0.8)
                col = STONE_ARENA[4] if val > 1 else (STONE_ARENA[3] if val > -1 else STONE_ARENA[1])
                sb.set_pixel(23 + dx, 21 + dy, col)
    edges_sb = []
    for y in range(32):
        for x in range(32):
            if sb.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if sb.get_pixel(nx, ny)[3] == 0:
                        edges_sb.append((nx, ny))
    for ex, ey in edges_sb:
        sb.set_pixel(ex, ey, OUTLINE_25D)
    sb.save_png(os.path.join(OUT_DIR, "art-003_pedra_b.png"))

    # Stone C: Grand Megalithic Slab / Carved Stone Altar 2.5D (64x32)
    sc = Canvas(64, 32)
    for dy in range(-9, 10):
        for dx in range(-24, 25):
            if (dx*dx)/576.0 + (dy*dy)/81.0 <= 1.0:
                val = - (dx * 0.3 + dy * 0.9)
                col = STONE_ARENA[4] if val > 4 else (STONE_ARENA[3] if val > 0 else (STONE_ARENA[2] if val > -4 else STONE_ARENA[1]))
                sc.set_pixel(32 + dx, 16 + dy, col)
    # Carved horizontal ledge
    for x in range(16, 48):
        sc.set_pixel(x, 15, STONE_ARENA[4])
        sc.set_pixel(x, 16, STONE_ARENA[1])
    # Moss accents
    sc.set_pixel(22, 12, OAK_FOLIAGE[4])
    sc.set_pixel(23, 13, OAK_FOLIAGE[3])
    sc.set_pixel(42, 13, OAK_FOLIAGE[4])

    edges_sc = []
    for y in range(32):
        for x in range(64):
            if sc.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if sc.get_pixel(nx, ny)[3] == 0:
                        edges_sc.append((nx, ny))
    for ex, ey in edges_sc:
        sc.set_pixel(ex, ey, OUTLINE_25D)
    sc.save_png(os.path.join(OUT_DIR, "art-003_pedra_c.png"))


# --- 5. Arena Stone Retaining Wall Sheet (128x32, 4 pieces of 32x32) ---
def build_arena_border_25d():
    sheet = Canvas(128, 32)

    def draw_wall_block(c, x, y, w, h, has_banner=False):
        for cy in range(y, y + h):
            for cx in range(x, x + w):
                # 2.5D stone masonry: top cap is bright, front face has horizontal mortar courses
                if cy == y:
                    col = STONE_ARENA[4] # Stone top coping highlight
                elif cx == x:
                    col = STONE_ARENA[3] # Left bevel
                elif cy == y + h - 1 or cx == x + w - 1:
                    col = STONE_ARENA[1] # Base shadow
                else:
                    # Mortar groove at mid height
                    if cy == y + h // 2:
                        col = STONE_ARENA[0]
                    else:
                        col = STONE_ARENA[2]
                c.set_pixel(cx, cy, col)

        # Draw banner if requested (matching colosseum banner in reference)
        if has_banner:
            bx = x + w // 2 - 2
            # bronze bracket
            for i in range(5):
                c.set_pixel(bx + i, y + 2, hex_to_rgba('#9C7A3C'))
            # cloth
            for by in range(y + 3, y + 11):
                for i in range(5):
                    col = BANNER_GREEN[2] if i in [0, 4] else BANNER_GREEN[1]
                    c.set_pixel(bx + i, by, col)
            # golden fringe
            for i in range(5):
                c.set_pixel(bx + i, y + 11, BANNER_GREEN[3])

        # Border
        for cy in range(y - 1, y + h + 1):
            c.set_pixel(x - 1, cy, OUTLINE_25D)
            c.set_pixel(x + w, cy, OUTLINE_25D)
        for cx in range(x - 1, x + w + 1):
            c.set_pixel(cx, y - 1, OUTLINE_25D)
            c.set_pixel(cx, y + h, OUTLINE_25D)

    # Piece 1: Straight Horizontal Arena Wall (0..31)
    draw_wall_block(sheet, 1, 9, 14, 14, has_banner=False)
    draw_wall_block(sheet, 17, 9, 14, 14, has_banner=False)
    for x in range(0, 32):
        sheet.set_pixel(x, 24, SHADOW_25D)

    # Piece 2: Straight Vertical Arena Wall (32..63)
    draw_wall_block(sheet, 32 + 10, 1, 12, 14, has_banner=False)
    draw_wall_block(sheet, 32 + 10, 17, 12, 14, has_banner=False)
    for y in range(0, 32):
        sheet.set_pixel(32 + 23, y, SHADOW_25D)

    # Piece 3: Arena Corner with Pilaster Pillar Cap (64..95)
    draw_wall_block(sheet, 64 + 8, 7, 16, 17, has_banner=False)
    draw_wall_block(sheet, 64 + 24, 9, 8, 14)
    draw_wall_block(sheet, 64 + 10, 24, 12, 8)
    for i in range(12):
        sheet.set_pixel(64 + 24 + i//2, 24 + i//2, SHADOW_25D)

    # Piece 4: Arena Wall with Hanging Green Banner (96..127)
    draw_wall_block(sheet, 96 + 2, 9, 28, 14, has_banner=True)
    for x in range(96, 128):
        sheet.set_pixel(x, 24, SHADOW_25D)

    sheet.save_png(os.path.join(OUT_DIR, "art-003_borda-arena.png"))


# --- 6. Shadows Sheet (288x160) ---
def build_shadows_25d():
    sheet = Canvas(288, 160)

    def stamp_shadow_25d(c, cx, cy, rx, ry):
        for dy in range(-int(ry), int(ry) + 1):
            for dx in range(-int(rx), int(rx) + 1):
                # 2.5D tilted projection: shifted bottom-right
                dist = (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry)
                if dist <= 1.0:
                    alpha = 180 if dist < 0.65 else 115
                    c.set_pixel(cx + dx, cy + dy, (18, 23, 20, alpha))

    # Large trees (row 0: 3 cells of 96x96)
    stamp_shadow_25d(sheet, 54, 76, 26, 13)
    stamp_shadow_25d(sheet, 96 + 54, 76, 28, 14)
    stamp_shadow_25d(sheet, 192 + 54, 76, 25, 12)

    # Small trees (row 1: 2 cells of 64x64)
    stamp_shadow_25d(sheet, 36, 96 + 50, 16, 9)
    stamp_shadow_25d(sheet, 64 + 36, 96 + 50, 15, 8)

    sheet.save_png(os.path.join(OUT_DIR, "art-003_sombras.png"))


if __name__ == '__main__':
    print("Generating ART-003 v2 (2.5D) vegetation and props...")
    build_large_trees_25d()
    build_small_trees_25d()
    build_bushes_25d()
    build_stones_25d()
    build_arena_border_25d()
    build_shadows_25d()
    print("ART-003 v2 (2.5D) completed successfully!")
