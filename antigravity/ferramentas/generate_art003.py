"""
Generator for ART-003: Vegetação e Props
Creates pixel-art trees, bushes, rocks, arena borders, and ground shadows matching docs/direcao-de-arte.md.
"""

import math
import os
import random
from pixel_art_tool import (
    Canvas, GRASS_ARENA, GRASS_FOREST, WOOD, BIRCH, STONE,
    FLOWER_YELLOW, FLOWER_WHITE, OUTLINE_DARK, SHADOW_GROUND, C_TRANSPARENT,
    hex_to_rgba
)

OUT_DIR = r"c:\Users\pattr\pixel-chess\antigravity\entregas\ART-003\v1"
os.makedirs(OUT_DIR, exist_ok=True)

# Helper to draw a shaded pixel-art foliage bubble / cluster
def draw_foliage_cluster(canvas, cx, cy, rx, ry, seed=0, is_birch=False):
    rng = random.Random(seed)
    # Paleta mata: 0: Escuro(#1F3D2B), 1: #2E5A34, 2: #3F7A3A, 3: #5E9A45, 4: #86B84F (Luz)
    # Outline first
    for dy in range(-int(ry) - 2, int(ry) + 3):
        for dx in range(-int(rx) - 2, int(rx) + 3):
            # Ellipse formula with slight jitter
            jitter = (rng.random() - 0.5) * 0.15
            dist = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) + jitter
            if dist <= 1.0:
                # Inside cluster: calculate light from top-left (-rx, -ry)
                # Normalized pos (-1 to 1)
                nx = dx / float(rx)
                ny = dy / float(ry)
                # Dot product with light vector (-0.707, -0.707)
                light = - (nx * 0.65 + ny * 0.75)

                # Shading bands
                if light > 0.45:
                    col = GRASS_FOREST[4] # Bright highlight
                elif light > 0.05:
                    col = GRASS_FOREST[3] # Mid light
                elif light > -0.35:
                    col = GRASS_FOREST[2] # Mid shadow
                elif light > -0.75:
                    col = GRASS_FOREST[1] # Dark shadow
                else:
                    col = GRASS_FOREST[0] # Deep shadow

                canvas.set_pixel(cx + dx, cy + dy, col)

    # Add dark outline border around edge pixels
    edge_pixels = []
    for dy in range(-int(ry) - 3, int(ry) + 4):
        for dx in range(-int(rx) - 3, int(rx) + 4):
            x = cx + dx
            y = cy + dy
            if canvas.get_pixel(x, y)[3] > 0:
                # Check neighbors
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if canvas.get_pixel(nx, ny)[3] == 0:
                        edge_pixels.append((nx, ny))

    for ex, ey in edge_pixels:
        canvas.set_pixel(ex, ey, OUTLINE_DARK)

# Helper to draw a shaded tree trunk
def draw_trunk(canvas, x_base, y_base, width, height, palette=WOOD, has_roots=True, seed=0):
    rng = random.Random(seed)
    # Palette: 0: shadow, 1: mid, 2: highlight
    for y in range(y_base, y_base + height):
        # Slightly taper upwards
        progress = (y - y_base) / float(height) # 0 at top, 1 at bottom
        w_current = int(width * (0.8 + progress * 0.4))
        x_start = x_base - w_current // 2

        for x in range(x_start, x_start + w_current):
            fx = (x - x_start) / float(w_current)
            if fx < 0.25:
                col = palette[2] # Highlight on left
            elif fx < 0.65:
                col = palette[1] # Mid tone
            else:
                col = palette[0] # Shadow on right

            # Add bark speckle
            if rng.random() < 0.15:
                col = palette[0]

            canvas.set_pixel(x, y, col)

        # Dark outlines
        canvas.set_pixel(x_start - 1, y, OUTLINE_DARK)
        canvas.set_pixel(x_start + w_current, y, OUTLINE_DARK)

    # Base roots branching out
    if has_roots:
        y_bot = y_base + height
        # Left root
        for i in range(4):
            canvas.set_pixel(x_base - width // 2 - i, y_bot - 1 + i // 2, palette[2])
            canvas.set_pixel(x_base - width // 2 - i, y_bot + i // 2, OUTLINE_DARK)
        # Right root
        for i in range(4):
            canvas.set_pixel(x_base + width // 2 + i, y_bot - 1 + i // 2, palette[0])
            canvas.set_pixel(x_base + width // 2 + i, y_bot + i // 2, OUTLINE_DARK)


# --- 1. Large Trees (96x96, transparent) ---
def build_large_trees():
    # Tree A: Classic grand oak (lush, symmetrical rounded lobes)
    ta = Canvas(96, 96)
    # Trunk
    draw_trunk(ta, x_base=48, y_base=56, width=10, height=26, palette=WOOD, has_roots=True, seed=11)

    # Foliage clusters (layered back to front, bottom to top)
    clusters_a = [
        (48, 48, 22, 16, 101), # bottom center lobe
        (32, 44, 18, 15, 102), # bottom left lobe
        (64, 46, 18, 15, 103), # bottom right lobe
        (30, 30, 19, 16, 104), # mid left lobe
        (66, 32, 19, 16, 105), # mid right lobe
        (48, 26, 24, 18, 106), # main central crown
        (46, 16, 18, 14, 107), # top-left highlight crown
    ]
    for cx, cy, rx, ry, s in clusters_a:
        draw_foliage_cluster(ta, cx, cy, rx, ry, seed=s)
    ta.save_png(os.path.join(OUT_DIR, "art-003_arvore-grande_a.png"))

    # Tree B: Asymmetric layered crown with visible branch angle
    tb = Canvas(96, 96)
    draw_trunk(tb, x_base=46, y_base=54, width=9, height=28, palette=WOOD, has_roots=True, seed=22)
    # Branch leaning right
    for i in range(8):
        tb.set_pixel(48 + i, 58 - i // 2, WOOD[1])
        tb.set_pixel(48 + i, 59 - i // 2, WOOD[0])

    clusters_b = [
        (62, 50, 16, 13, 201), # lower right sub-canopy
        (34, 48, 18, 14, 202), # lower left
        (40, 34, 20, 16, 203), # mid left body
        (60, 36, 18, 15, 204), # mid right
        (38, 22, 21, 16, 205), # upper left dome
        (56, 24, 16, 14, 206), # upper right
        (42, 14, 15, 12, 207), # top apex
    ]
    for cx, cy, rx, ry, s in clusters_b:
        draw_foliage_cluster(tb, cx, cy, rx, ry, seed=s)
    tb.save_png(os.path.join(OUT_DIR, "art-003_arvore-grande_b.png"))

    # Tree C: Birch tree with light trunk & wide elegant crown (matching ref-ruinas)
    tc = Canvas(96, 96)
    draw_trunk(tc, x_base=50, y_base=54, width=8, height=30, palette=BIRCH, has_roots=True, seed=33)
    # Distinct birch dark lenticel horizontal notches
    for y_notch in [58, 64, 70, 76]:
        tc.set_pixel(48, y_notch, BIRCH[0])
        tc.set_pixel(49, y_notch, BIRCH[0])
        tc.set_pixel(51, y_notch + 3, BIRCH[0])

    clusters_c = [
        (32, 50, 16, 13, 301),
        (66, 48, 17, 14, 302),
        (48, 44, 22, 16, 303),
        (28, 32, 18, 15, 304),
        (68, 30, 19, 15, 305),
        (48, 24, 24, 18, 306),
        (40, 15, 16, 13, 307),
        (58, 16, 15, 12, 308),
    ]
    for cx, cy, rx, ry, s in clusters_c:
        draw_foliage_cluster(tc, cx, cy, rx, ry, seed=s)
    tc.save_png(os.path.join(OUT_DIR, "art-003_arvore-grande_c.png"))


# --- 2. Small Trees (64x64, transparent) ---
def build_small_trees():
    # Tree Small A: Round youthful tree
    sa = Canvas(64, 64)
    draw_trunk(sa, x_base=32, y_base=38, width=6, height=18, palette=WOOD, has_roots=True, seed=44)

    clusters_sa = [
        (32, 34, 14, 11, 401),
        (22, 28, 12, 10, 402),
        (42, 28, 12, 10, 403),
        (32, 20, 15, 12, 404),
        (28, 13, 11, 9, 405),
    ]
    for cx, cy, rx, ry, s in clusters_sa:
        draw_foliage_cluster(sa, cx, cy, rx, ry, seed=s)
    sa.save_png(os.path.join(OUT_DIR, "art-003_arvore-pequena_a.png"))

    # Tree Small B: Slender tiered tree
    sb = Canvas(64, 64)
    draw_trunk(sb, x_base=32, y_base=36, width=5, height=22, palette=WOOD, has_roots=True, seed=55)

    clusters_sb = [
        (32, 34, 15, 11, 501),
        (24, 32, 10, 8, 502),
        (40, 32, 10, 8, 503),
        (32, 22, 13, 10, 504),
        (32, 12, 10, 8, 505),
    ]
    for cx, cy, rx, ry, s in clusters_sb:
        draw_foliage_cluster(sb, cx, cy, rx, ry, seed=s)
    sb.save_png(os.path.join(OUT_DIR, "art-003_arvore-pequena_b.png"))


# --- 3. Bushes (32x32, transparent) ---
def build_bushes():
    # Bush A: Round fluffy bush
    ba = Canvas(32, 32)
    draw_foliage_cluster(ba, cx=16, cy=18, rx=11, ry=8, seed=601)
    draw_foliage_cluster(ba, cx=12, cy=14, rx=8, ry=6, seed=602)
    draw_foliage_cluster(ba, cx=20, cy=15, rx=7, ry=6, seed=603)
    ba.save_png(os.path.join(OUT_DIR, "art-003_arbusto_a.png"))

    # Bush B: Low wide hedge shrub
    bb = Canvas(32, 32)
    draw_foliage_cluster(bb, cx=16, cy=20, rx=13, ry=7, seed=701)
    draw_foliage_cluster(bb, cx=10, cy=17, rx=8, ry=6, seed=702)
    draw_foliage_cluster(bb, cx=22, cy=18, rx=7, ry=5, seed=703)
    bb.save_png(os.path.join(OUT_DIR, "art-003_arbusto_b.png"))

    # Bush C: Bush with flowers & berries
    bc = Canvas(32, 32)
    draw_foliage_cluster(bc, cx=16, cy=18, rx=10, ry=8, seed=801)
    draw_foliage_cluster(bc, cx=14, cy=13, rx=8, ry=6, seed=802)
    # Flowers dotted on canopy
    flower_dots = [
        (10, 14, FLOWER_YELLOW),
        (18, 12, FLOWER_WHITE),
        (12, 19, FLOWER_WHITE),
        (22, 17, FLOWER_YELLOW),
        (16, 16, FLOWER_YELLOW),
    ]
    for fx, fy, col in flower_dots:
        bc.set_pixel(fx, fy, col)
        bc.set_pixel(fx + 1, fy, col)
        bc.set_pixel(fx, fy + 1, GRASS_FOREST[0])
    bc.save_png(os.path.join(OUT_DIR, "art-003_arbusto_c.png"))


# --- 4. Stones (32x32 and 64x32, transparent) ---
def build_stones():
    # Stone A: Single faceted boulder (32x32)
    sa = Canvas(32, 32)
    # Draw rock body
    # Center (16, 18), radius x=10, y=7
    for dy in range(-7, 8):
        for dx in range(-10, 11):
            if (dx * dx) / 100.0 + (dy * dy) / 49.0 <= 1.0:
                # Directional light from top-left
                val = - (dx * 0.6 + dy * 0.8)
                if val > 4:
                    col = STONE[4] # Highlight
                elif val > 0:
                    col = STONE[3] # Light
                elif val > -4:
                    col = STONE[2] # Base
                elif val > -8:
                    col = STONE[1] # Shadow
                else:
                    col = STONE[0] # Deep shadow
                sa.set_pixel(16 + dx, 18 + dy, col)

    # Add rock crack & moss
    sa.set_pixel(14, 16, STONE[0])
    sa.set_pixel(15, 17, STONE[0])
    sa.set_pixel(16, 18, STONE[0])
    # Moss accent on top
    sa.set_pixel(12, 13, GRASS_FOREST[3])
    sa.set_pixel(13, 13, GRASS_FOREST[4])
    sa.set_pixel(14, 14, GRASS_FOREST[2])

    # Outline
    edge_sa = []
    for y in range(32):
        for x in range(32):
            if sa.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if sa.get_pixel(nx, ny)[3] == 0:
                        edge_sa.append((nx, ny))
    for ex, ey in edge_sa:
        sa.set_pixel(ex, ey, OUTLINE_DARK)
    sa.save_png(os.path.join(OUT_DIR, "art-003_pedra_a.png"))

    # Stone B: Dual stones (32x32)
    sb = Canvas(32, 32)
    # Big stone at (13, 19)
    for dy in range(-5, 6):
        for dx in range(-7, 8):
            if (dx * dx) / 49.0 + (dy * dy) / 25.0 <= 1.0:
                val = - (dx * 0.6 + dy * 0.8)
                col = STONE[3] if val > 2 else (STONE[2] if val > -2 else STONE[1])
                sb.set_pixel(13 + dx, 19 + dy, col)
    # Small stone at (23, 21)
    for dy in range(-4, 5):
        for dx in range(-5, 6):
            if (dx * dx) / 25.0 + (dy * dy) / 16.0 <= 1.0:
                val = - (dx * 0.6 + dy * 0.8)
                col = STONE[4] if val > 2 else (STONE[3] if val > 0 else STONE[1])
                sb.set_pixel(23 + dx, 21 + dy, col)

    edge_sb = []
    for y in range(32):
        for x in range(32):
            if sb.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if sb.get_pixel(nx, ny)[3] == 0:
                        edge_sb.append((nx, ny))
    for ex, ey in edge_sb:
        sb.set_pixel(ex, ey, OUTLINE_DARK)
    sb.save_png(os.path.join(OUT_DIR, "art-003_pedra_b.png"))

    # Stone C: Large prop stone slab (64x32)
    sc = Canvas(64, 32)
    for dy in range(-9, 10):
        for dx in range(-24, 25):
            if (dx * dx) / (24.0 * 24.0) + (dy * dy) / (9.0 * 9.0) <= 1.0:
                val = - (dx * 0.3 + dy * 0.9)
                if val > 4:
                    col = STONE[4]
                elif val > 0:
                    col = STONE[3]
                elif val > -3:
                    col = STONE[2]
                elif val > -7:
                    col = STONE[1]
                else:
                    col = STONE[0]
                sc.set_pixel(32 + dx, 16 + dy, col)

    # Strata fissures
    for x in range(20, 44):
        sc.set_pixel(x, 15 + (x % 3), STONE[0])
        sc.set_pixel(x, 16 + (x % 3), STONE[4]) # ledge highlight

    # Outline
    edge_sc = []
    for y in range(32):
        for x in range(64):
            if sc.get_pixel(x, y)[3] > 0:
                for nx, ny in [(x+1, y), (x-1, y), (x, y+1), (x, y-1)]:
                    if sc.get_pixel(nx, ny)[3] == 0:
                        edge_sc.append((nx, ny))
    for ex, ey in edge_sc:
        sc.set_pixel(ex, ey, OUTLINE_DARK)
    sc.save_png(os.path.join(OUT_DIR, "art-003_pedra_c.png"))


# --- 5. Arena Border Sheet (4 pieces of 32x32 = 128x32, transparent) ---
def build_arena_border():
    # Sheet 128x32
    # Cell 0 (0..31): Straight Horizontal Wall / Paver Curb
    # Cell 1 (32..63): Straight Vertical Wall / Paver Curb
    # Cell 2 (64..95): Corner (Top-Left 90 deg)
    # Cell 3 (96..127): Weathered / Broken Section with fallen paver and moss
    sheet = Canvas(128, 32)

    # Helper to draw a stone brick block
    def draw_stone_block(c, x, y, w, h, is_broken=False):
        for cy in range(y, y + h):
            for cx in range(x, x + w):
                # Highlight top and left, shadow bottom and right
                if cy == y or cx == x:
                    col = STONE[4] if (cy == y and cx == x) else STONE[3]
                elif cy == y + h - 1 or cx == x + w - 1:
                    col = STONE[1]
                else:
                    col = STONE[2]
                c.set_pixel(cx, cy, col)

        # Border
        for cy in range(y - 1, y + h + 1):
            c.set_pixel(x - 1, cy, OUTLINE_DARK)
            c.set_pixel(x + w, cy, OUTLINE_DARK)
        for cx in range(x - 1, x + w + 1):
            c.set_pixel(cx, y - 1, OUTLINE_DARK)
            c.set_pixel(cx, y + h, OUTLINE_DARK)

    # Piece 1: Straight Horizontal (0..31)
    # Two pavers side by side (14x10 each) + foundation shadow
    draw_stone_block(sheet, 1, 10, 14, 12)
    draw_stone_block(sheet, 17, 10, 14, 12)
    # Ground shadow below wall
    for x in range(0, 32):
        sheet.set_pixel(x, 23, SHADOW_GROUND)
        sheet.set_pixel(x, 24, SHADOW_GROUND)

    # Piece 2: Straight Vertical (32..63)
    draw_stone_block(sheet, 32 + 10, 1, 12, 14)
    draw_stone_block(sheet, 32 + 10, 17, 12, 14)
    # Shadow to the right
    for y in range(0, 32):
        sheet.set_pixel(32 + 23, y, SHADOW_GROUND)
        sheet.set_pixel(32 + 24, y, SHADOW_GROUND)

    # Piece 3: Corner (64..95)
    # Horizontal part + Vertical part meeting
    draw_stone_block(sheet, 64 + 9, 9, 14, 14) # corner cap
    draw_stone_block(sheet, 64 + 24, 10, 8, 12) # right branch
    draw_stone_block(sheet, 64 + 10, 24, 12, 8) # down branch
    # Shadow
    for i in range(12):
        sheet.set_pixel(64 + 23 + i // 2, 23 + i // 2, SHADOW_GROUND)

    # Piece 4: Ruined / Weathered Section (96..127)
    draw_stone_block(sheet, 96 + 2, 11, 12, 11)
    # Broken chipped paver leaning
    draw_stone_block(sheet, 96 + 18, 14, 10, 9)
    # Moss in the gap
    sheet.set_pixel(96 + 15, 15, GRASS_ARENA[2])
    sheet.set_pixel(96 + 16, 16, GRASS_ARENA[3])
    sheet.set_pixel(96 + 15, 17, GRASS_ARENA[1])
    # Fallen stone chip
    sheet.set_pixel(96 + 16, 25, STONE[3])
    sheet.set_pixel(96 + 17, 25, STONE[1])
    sheet.set_pixel(96 + 17, 26, OUTLINE_DARK)

    sheet.save_png(os.path.join(OUT_DIR, "art-003_borda-arena.png"))


# --- 6. Shadows Sheet (corresponding to large & small trees) ---
def build_shadows_sheet():
    # Large trees: 3 cells of 96x96
    # Small trees: 2 cells of 64x64
    # Arranged into a clean sheet: 288 x 160 px
    # Row 0: 3 large tree shadows (96x96 each -> width 288, height 96)
    # Row 1: 2 small tree shadows (64x64 each -> width 128, height 64)
    sheet = Canvas(288, 160)

    # Helper to draw smooth elliptical ground shadow (offset bottom-right)
    def stamp_shadow(c, cx, cy, rx, ry):
        for dy in range(-int(ry), int(ry) + 1):
            for dx in range(-int(rx), int(rx) + 1):
                dist = (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry)
                if dist <= 1.0:
                    # Density falls off slightly at very edge
                    alpha = 190 if dist < 0.75 else 120
                    col = (26, 36, 32, alpha) # #1A2420 with alpha
                    c.set_pixel(cx + dx, cy + dy, col)

    # Large tree A shadow (cell 0,0: 0..95, 0..95)
    # Shadow centered at (54, 76), rx=26, ry=13
    stamp_shadow(sheet, 54, 76, 26, 13)

    # Large tree B shadow (cell 1,0: 96..191, 0..95)
    stamp_shadow(sheet, 96 + 56, 76, 25, 12)

    # Large tree C shadow (cell 2,0: 192..287, 0..95)
    stamp_shadow(sheet, 192 + 54, 78, 28, 14)

    # Small tree A shadow (cell 0,1: 0..63, 96..159)
    stamp_shadow(sheet, 36, 96 + 50, 16, 9)

    # Small tree B shadow (cell 1,1: 64..127, 96..159)
    stamp_shadow(sheet, 64 + 36, 96 + 50, 15, 8)

    sheet.save_png(os.path.join(OUT_DIR, "art-003_sombras.png"))


if __name__ == '__main__':
    print("Generating ART-003 vegetation and props...")
    build_large_trees()
    build_small_trees()
    build_bushes()
    build_stones()
    build_arena_border()
    build_shadows_sheet()
    print("ART-003 generation completed!")
