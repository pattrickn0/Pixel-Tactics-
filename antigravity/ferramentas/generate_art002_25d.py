"""
Generator for ART-002 v2: Terreno 2.5D (32x32)
Blends the readable palette of v1 with the rich 2.5D textured aesthetic of the Eiyuden/Octopath references:
- Cobblestone paving (paralelepípedo) & rustic dirt path
- Textured 2.5D grass with micro-relief & vertical blades
- Decals with 2.5D depth (tufts, flowers, stones, wood stump)
- Seamless 4x4 tiling
"""

import math
import os
import random
from pixel_art_tool import Canvas, hex_to_rgba

OUT_DIR = r"c:\Users\pattr\pixel-chess\antigravity\entregas\ART-002\v2"
os.makedirs(OUT_DIR, exist_ok=True)

# --- Palette: Fusion of v1 charm and 2.5D HD references ---
C_TRANSPARENT = (0, 0, 0, 0)

# Grama Arena (Vibrante, luz dourada suave, relevo de lâminas)
GRASS_ARENA_25D = [
    hex_to_rgba('#345A24'), # 0: Sombra profunda
    hex_to_rgba('#4E7E2C'), # 1: Base média
    hex_to_rgba('#72A838'), # 2: Luz média
    hex_to_rgba('#9DCB48'), # 3: Highlight dourado/verde
    hex_to_rgba('#C4E662'), # 4: Ponta solar da lâmina
]

# Grama Floresta (Mata densa, musgo, agulhas caídas)
GRASS_FOREST_25D = [
    hex_to_rgba('#162B1D'), # 0: Sombra escura
    hex_to_rgba('#22442B'), # 1: Base sombra
    hex_to_rgba('#326338'), # 2: Base média
    hex_to_rgba('#4C8446'), # 3: Luz verde
    hex_to_rgba('#6EA85B'), # 4: Highlight de copa
]

# Caminho de Calçamento / Cobblestone (Referência direta aos screenshots)
COBBLE_PATH_25D = [
    hex_to_rgba('#2A2724'), # 0: Rejunte / sombra entre pedras
    hex_to_rgba('#4A4641'), # 1: Base pedra escura
    hex_to_rgba('#6E6860'), # 2: Corpo da pedra
    hex_to_rgba('#9A9388'), # 3: Luz da pedra
    hex_to_rgba('#C8C2B5'), # 4: Highlight superior da pedra
]

# Terra Batida Rústica
DIRT_25D = [
    hex_to_rgba('#4E3D2C'), # 0: Sombra
    hex_to_rgba('#725B42'), # 1: Base
    hex_to_rgba('#A48762'), # 2: Luz
    hex_to_rgba('#CCB18C'), # 3: Highlight
]

# Madeira / Toco
WOOD_STUMP = [
    hex_to_rgba('#3A2618'),
    hex_to_rgba('#5A3C26'),
    hex_to_rgba('#825B3A'),
    hex_to_rgba('#AD8056'), # anel do topo
]

# Cores de Detalhe
FLOWER_YELLOW = hex_to_rgba('#F6DE4C')
FLOWER_WHITE  = hex_to_rgba('#F2F2EB')
FLOWER_RED    = hex_to_rgba('#E65842')
OUTLINE_DARK  = hex_to_rgba('#18201A')


def make_noise_grid(w, h, seed):
    rng = random.Random(seed)
    return [[rng.random() for _ in range(w)] for _ in range(h)]

def sample_smooth_noise(grid, x, y, w, h):
    x0 = int(x) % w
    y0 = int(y) % h
    x1 = (x0 + 1) % w
    y1 = (y0 + 1) % h
    fx = x - int(x)
    fy = y - int(y)

    v00 = grid[y0][x0]
    v10 = grid[y0][x1]
    v01 = grid[y1][x0]
    v11 = grid[y1][x1]

    top = v00 * (1 - fx) + v10 * fx
    bot = v01 * (1 - fx) + v11 * fx
    return top * (1 - fy) + bot * fy


# --- 1. Grass Arena (32x32) ---
def build_arena_grass_25d():
    for var_name, seed, density in [('a', 101, 10), ('b', 202, 14), ('c', 303, 18), ('d', 404, 12)]:
        c = Canvas(32, 32)
        g_c = make_noise_grid(8, 8, seed)
        g_f = make_noise_grid(16, 16, seed + 50)

        for y in range(32):
            for x in range(32):
                val = sample_smooth_noise(g_c, x/4.0, y/4.0, 8, 8)*0.6 + sample_smooth_noise(g_f, x/2.0, y/2.0, 16, 16)*0.4
                if val < 0.28:
                    col = GRASS_ARENA_25D[0]
                elif val < 0.52:
                    col = GRASS_ARENA_25D[1]
                elif val < 0.78:
                    col = GRASS_ARENA_25D[2]
                else:
                    col = GRASS_ARENA_25D[3]
                c.set_pixel(x, y, col)

        # Add vertical 2.5D blades
        rng = random.Random(seed + 1000)
        for _ in range(density):
            bx = rng.randint(0, 31)
            by = rng.randint(1, 31)
            # Tip of blade
            c.set_pixel(bx, by - 1, GRASS_ARENA_25D[4])
            c.set_pixel(bx, by, GRASS_ARENA_25D[3])
            c.set_pixel((bx + 1) % 32, by, GRASS_ARENA_25D[2])
            c.set_pixel(bx, (by + 1) % 32, GRASS_ARENA_25D[0])

        if var_name == 'd':
            # Add subtle clover spots
            for cx, cy in [(10, 12), (24, 20)]:
                c.set_pixel(cx, cy, GRASS_ARENA_25D[4])
                c.set_pixel(cx + 1, cy, GRASS_ARENA_25D[4])
                c.set_pixel(cx, cy + 1, GRASS_ARENA_25D[3])

        c.save_png(os.path.join(OUT_DIR, f"art-002_grama-arena_{var_name}.png"))


# --- 2. Grass Forest (32x32) ---
def build_forest_grass_25d():
    for var_name, seed in [('a', 501), ('b', 602), ('c', 703)]:
        c = Canvas(32, 32)
        g_c = make_noise_grid(8, 8, seed)
        g_f = make_noise_grid(16, 16, seed + 50)

        for y in range(32):
            for x in range(32):
                val = sample_smooth_noise(g_c, x/4.0, y/4.0, 8, 8)*0.6 + sample_smooth_noise(g_f, x/2.0, y/2.0, 16, 16)*0.4
                if val < 0.25:
                    col = GRASS_FOREST_25D[0]
                elif val < 0.50:
                    col = GRASS_FOREST_25D[1]
                elif val < 0.78:
                    col = GRASS_FOREST_25D[2]
                elif val < 0.90:
                    col = GRASS_FOREST_25D[3]
                else:
                    col = GRASS_FOREST_25D[4]
                c.set_pixel(x, y, col)

        # Needle & leaf litter
        rng = random.Random(seed + 2000)
        for _ in range(8):
            px = rng.randint(0, 31)
            py = rng.randint(0, 31)
            c.set_pixel(px, py, DIRT_25D[1])
            c.set_pixel((px + 1) % 32, (py + 1) % 32, OUTLINE_DARK)

        c.save_png(os.path.join(OUT_DIR, f"art-002_grama-mata_{var_name}.png"))


# --- 3. Paths: Cobblestone (terra_a) & Packed Earth (terra_b) ---
def build_paths_25d():
    # terra_a: Cobblestone Road (Seamless 32x32 interlocking paving)
    ca = Canvas(32, 32)
    # Fill with mortar
    ca.draw_rect(0, 0, 32, 32, COBBLE_PATH_25D[0])

    # Draw interlocking cobblestones (approx 8x5 px each in staggered rows)
    # 4 rows of height 8
    stone_h = 7
    for row in range(4):
        y0 = row * 8
        offset = 4 if row % 2 == 1 else 0
        for col in range(5):
            x0 = (col * 8 + offset) % 32
            w = 6
            h = 6
            # Draw individual cobblestone
            for dy in range(h):
                for dx in range(w):
                    px = (x0 + dx) % 32
                    py = (y0 + dy) % 32
                    if dy == 0 and dx < w - 1:
                        c_pixel = COBBLE_PATH_25D[4] # Top highlight
                    elif dx == 0 and dy < h - 1:
                        c_pixel = COBBLE_PATH_25D[3] # Left highlight
                    elif dy == h - 1 or dx == w - 1:
                        c_pixel = COBBLE_PATH_25D[1] # Bottom/right shadow
                    else:
                        c_pixel = COBBLE_PATH_25D[2] # Stone body
                    ca.set_pixel(px, py, c_pixel)
    ca.save_png(os.path.join(OUT_DIR, "art-002_terra_a.png"))

    # terra_b: Packed dirt with embedded river cobblestones
    cb = Canvas(32, 32)
    g_c = make_noise_grid(8, 8, 888)
    for y in range(32):
        for x in range(32):
            val = sample_smooth_noise(g_c, x/4.0, y/4.0, 8, 8)
            col = DIRT_25D[1] if val < 0.5 else (DIRT_25D[2] if val < 0.8 else DIRT_25D[3])
            cb.set_pixel(x, y, col)

    # Embedded cobblestones in dirt
    stones_pos = [(6, 6), (20, 8), (14, 18), (26, 24), (4, 26)]
    for sx, sy in stones_pos:
        for dy in range(4):
            for dx in range(5):
                col = COBBLE_PATH_25D[3] if dy == 0 else (COBBLE_PATH_25D[2] if dy < 3 else COBBLE_PATH_25D[1])
                cb.set_pixel((sx + dx) % 32, (sy + dy) % 32, col)
        cb.set_pixel((sx + 5) % 32, (sy + 3) % 32, DIRT_25D[0])
    cb.save_png(os.path.join(OUT_DIR, "art-002_terra_b.png"))


# --- 4. Decals Sheet (64x48, 16x16 cells, transparent) ---
def build_decals_25d():
    sheet = Canvas(64, 48)

    # (0,0): 2.5D Tall Grass Blade Cluster
    c0 = Canvas(16, 16)
    # blade 1
    for dy in range(7):
        c0.set_pixel(6, 5 + dy, GRASS_ARENA_25D[4] if dy < 2 else GRASS_ARENA_25D[3])
    c0.set_pixel(6, 12, GRASS_ARENA_25D[0])
    # blade 2 (curved)
    c0.set_pixel(8, 3, GRASS_ARENA_25D[4])
    c0.set_pixel(8, 4, GRASS_ARENA_25D[3])
    c0.set_pixel(9, 5, GRASS_ARENA_25D[3])
    c0.set_pixel(9, 6, GRASS_ARENA_25D[2])
    c0.set_pixel(8, 7, GRASS_ARENA_25D[2])
    c0.set_pixel(8, 8, GRASS_ARENA_25D[1])
    c0.set_pixel(8, 9, GRASS_ARENA_25D[0])
    # shadow
    c0.set_pixel(7, 13, OUTLINE_DARK)
    c0.set_pixel(8, 13, OUTLINE_DARK)
    sheet.blit(c0, 0, 0)

    # (1,0): 2.5D Wide Fern Frond
    c1 = Canvas(16, 16)
    c1.set_pixel(8, 4, GRASS_ARENA_25D[4])
    c1.set_pixel(7, 5, GRASS_ARENA_25D[3])
    c1.set_pixel(9, 5, GRASS_ARENA_25D[3])
    c1.set_pixel(6, 6, GRASS_ARENA_25D[3])
    c1.set_pixel(8, 6, GRASS_ARENA_25D[2])
    c1.set_pixel(10, 6, GRASS_ARENA_25D[3])
    c1.set_pixel(5, 7, GRASS_ARENA_25D[3])
    c1.set_pixel(8, 7, GRASS_ARENA_25D[2])
    c1.set_pixel(11, 7, GRASS_ARENA_25D[3])
    c1.set_pixel(8, 8, GRASS_ARENA_25D[1])
    c1.set_pixel(8, 9, GRASS_ARENA_25D[0])
    c1.set_pixel(8, 10, OUTLINE_DARK)
    sheet.blit(c1, 16, 0)

    # (2,0): Double Field Grass
    c2 = Canvas(16, 16)
    for dy in range(6):
        c2.set_pixel(6, 6 + dy, GRASS_ARENA_25D[3] if dy > 1 else GRASS_ARENA_25D[4])
        c2.set_pixel(10, 7 + dy, GRASS_ARENA_25D[3] if dy > 1 else GRASS_ARENA_25D[4])
    c2.set_pixel(7, 12, OUTLINE_DARK)
    c2.set_pixel(11, 13, OUTLINE_DARK)
    sheet.blit(c2, 32, 0)

    # (3,0): Cut Tree Stump (Toco de madeira - seen in reference screenshot!)
    st = Canvas(16, 16)
    # stump top ellipse (8, 9)
    for dy in range(-2, 3):
        for dx in range(-4, 5):
            if (dx*dx)/16.0 + (dy*dy)/4.0 <= 1.0:
                col = WOOD_STUMP[3] if dy < 1 else WOOD_STUMP[2]
                st.set_pixel(8 + dx, 9 + dy, col)
    # annual rings dot
    st.set_pixel(8, 9, WOOD_STUMP[1])
    # stump base cylinder
    for y in range(11, 14):
        for dx in range(-4, 5):
            col = WOOD_STUMP[2] if dx < 0 else (WOOD_STUMP[1] if dx < 3 else WOOD_STUMP[0])
            st.set_pixel(8 + dx, y, col)
    # root base
    st.set_pixel(3, 14, WOOD_STUMP[2])
    st.set_pixel(13, 14, WOOD_STUMP[0])
    for x in range(3, 14):
        st.set_pixel(x, 15, OUTLINE_DARK)
    sheet.blit(st, 48, 0)

    # (0,1): Wildflower Yellow
    f0 = Canvas(16, 16)
    f0.set_pixel(8, 6, FLOWER_YELLOW)
    f0.set_pixel(7, 7, FLOWER_YELLOW)
    f0.set_pixel(9, 7, FLOWER_YELLOW)
    f0.set_pixel(8, 7, hex_to_rgba('#FFFFFF'))
    f0.set_pixel(8, 8, FLOWER_YELLOW)
    f0.set_pixel(8, 9, GRASS_ARENA_25D[1])
    f0.set_pixel(8, 10, GRASS_ARENA_25D[0])
    f0.set_pixel(8, 11, OUTLINE_DARK)
    sheet.blit(f0, 0, 16)

    # (1,1): Wildflower White
    f1 = Canvas(16, 16)
    f1.set_pixel(8, 6, FLOWER_WHITE)
    f1.set_pixel(7, 7, FLOWER_WHITE)
    f1.set_pixel(9, 7, FLOWER_WHITE)
    f1.set_pixel(8, 7, FLOWER_YELLOW)
    f1.set_pixel(8, 8, FLOWER_WHITE)
    f1.set_pixel(8, 9, GRASS_ARENA_25D[1])
    f1.set_pixel(8, 10, OUTLINE_DARK)
    sheet.blit(f1, 16, 16)

    # (2,1): Wildflower Red/Orange
    f2 = Canvas(16, 16)
    f2.set_pixel(8, 6, FLOWER_RED)
    f2.set_pixel(7, 7, FLOWER_RED)
    f2.set_pixel(9, 7, FLOWER_RED)
    f2.set_pixel(8, 7, FLOWER_YELLOW)
    f2.set_pixel(8, 8, FLOWER_RED)
    f2.set_pixel(8, 9, GRASS_ARENA_25D[1])
    f2.set_pixel(8, 10, OUTLINE_DARK)
    sheet.blit(f2, 32, 16)

    # (3,1): River Boulder / Pebble 1
    p0 = Canvas(16, 16)
    for dy in range(-2, 3):
        for dx in range(-3, 4):
            if (dx*dx)/9.0 + (dy*dy)/4.0 <= 1.0:
                col = COBBLE_PATH_25D[4] if (dy < 0 and dx < 0) else (COBBLE_PATH_25D[3] if dy <= 0 else COBBLE_PATH_25D[1])
                p0.set_pixel(8 + dx, 10 + dy, col)
    # Ground shadow
    for dx in range(-2, 4):
        p0.set_pixel(8 + dx, 13, OUTLINE_DARK)
    sheet.blit(p0, 48, 16)

    # (0,2): Twin Cobble Stones
    p1 = Canvas(16, 16)
    # stone 1
    p1.set_pixel(5, 9, COBBLE_PATH_25D[4])
    p1.set_pixel(6, 9, COBBLE_PATH_25D[3])
    p1.set_pixel(5, 10, COBBLE_PATH_25D[2])
    p1.set_pixel(6, 10, COBBLE_PATH_25D[1])
    p1.set_pixel(6, 11, OUTLINE_DARK)
    # stone 2
    p1.set_pixel(10, 8, COBBLE_PATH_25D[4])
    p1.set_pixel(11, 8, COBBLE_PATH_25D[3])
    p1.set_pixel(9, 9, COBBLE_PATH_25D[3])
    p1.set_pixel(10, 9, COBBLE_PATH_25D[2])
    p1.set_pixel(11, 9, COBBLE_PATH_25D[1])
    p1.set_pixel(10, 10, OUTLINE_DARK)
    sheet.blit(p1, 0, 32)

    # (1,2): Flat Slate Step Stone
    p2 = Canvas(16, 16)
    for x in range(4, 12):
        p2.set_pixel(x, 9, COBBLE_PATH_25D[4] if x < 7 else COBBLE_PATH_25D[3])
        p2.set_pixel(x, 10, COBBLE_PATH_25D[2] if x < 10 else COBBLE_PATH_25D[1])
        p2.set_pixel(x, 11, OUTLINE_DARK)
    sheet.blit(p2, 16, 32)

    # (2,2): Red Forest Mushroom
    m0 = Canvas(16, 16)
    # cap
    m0.set_pixel(8, 7, FLOWER_RED)
    m0.set_pixel(7, 8, FLOWER_RED)
    m0.set_pixel(8, 8, FLOWER_WHITE) # spot
    m0.set_pixel(9, 8, FLOWER_RED)
    m0.set_pixel(6, 9, FLOWER_RED)
    m0.set_pixel(7, 9, FLOWER_RED)
    m0.set_pixel(8, 9, FLOWER_RED)
    m0.set_pixel(9, 9, FLOWER_RED)
    m0.set_pixel(10, 9, FLOWER_RED)
    # stem
    m0.set_pixel(8, 10, FLOWER_WHITE)
    m0.set_pixel(8, 11, FLOWER_WHITE)
    m0.set_pixel(8, 12, OUTLINE_DARK)
    sheet.blit(m0, 32, 32)

    # (3,2): Clover & Daisy patch
    cd = Canvas(16, 16)
    cd.set_pixel(6, 8, FLOWER_WHITE)
    cd.set_pixel(6, 9, FLOWER_YELLOW)
    cd.set_pixel(10, 9, GRASS_ARENA_25D[4])
    cd.set_pixel(9, 10, GRASS_ARENA_25D[3])
    cd.set_pixel(11, 10, GRASS_ARENA_25D[3])
    cd.set_pixel(10, 11, GRASS_ARENA_25D[1])
    cd.set_pixel(10, 12, OUTLINE_DARK)
    sheet.blit(cd, 48, 32)

    sheet.save_png(os.path.join(OUT_DIR, "art-002_decals.png"))


# --- 5. Transition Sheet: Grass <-> Cobblestone (128x128 autotile) ---
def build_transition_sheet_25d():
    sheet = Canvas(128, 128)
    base_grass = Canvas(32, 32)
    # load or regenerate clean grass & cobble
    g_c = make_noise_grid(8, 8, 101)
    for y in range(32):
        for x in range(32):
            val = sample_smooth_noise(g_c, x/4.0, y/4.0, 8, 8)
            base_grass.set_pixel(x, y, GRASS_ARENA_25D[2] if val < 0.6 else GRASS_ARENA_25D[3])

    base_path = Canvas(32, 32)
    base_path.draw_rect(0, 0, 32, 32, COBBLE_PATH_25D[0])
    for row in range(4):
        y0 = row * 8
        offset = 4 if row % 2 == 1 else 0
        for col in range(5):
            x0 = (col * 8 + offset) % 32
            for dy in range(6):
                for dx in range(6):
                    c_pix = COBBLE_PATH_25D[4] if dy == 0 else (COBBLE_PATH_25D[2] if dy < 5 else COBBLE_PATH_25D[1])
                    base_path.set_pixel((x0 + dx) % 32, (y0 + dy) % 32, c_pix)

    def make_edge_tile(edge_type):
        t = Canvas(32, 32)
        t.blit(base_path, 0, 0)
        rng = random.Random(hash(edge_type) & 0xffff)

        for y in range(32):
            for x in range(32):
                jitter = (rng.random() - 0.5) * 3.5
                is_grass = False
                if edge_type == 'N':
                    is_grass = (y + jitter < 15)
                elif edge_type == 'S':
                    is_grass = (y + jitter > 16)
                elif edge_type == 'W':
                    is_grass = (x + jitter < 15)
                elif edge_type == 'E':
                    is_grass = (x + jitter > 16)
                elif edge_type == 'NW':
                    is_grass = (x + y + jitter < 28)
                elif edge_type == 'NE':
                    is_grass = ((31 - x) + y + jitter < 28)
                elif edge_type == 'SW':
                    is_grass = (x + (31 - y) + jitter < 28)
                elif edge_type == 'SE':
                    is_grass = ((31 - x) + (31 - y) + jitter < 28)
                elif edge_type == 'INNER_NW':
                    is_grass = (x + y + jitter > 14)
                elif edge_type == 'INNER_NE':
                    is_grass = ((31 - x) + y + jitter > 14)
                elif edge_type == 'INNER_SW':
                    is_grass = (x + (31 - y) + jitter > 14)
                elif edge_type == 'INNER_SE':
                    is_grass = ((31 - x) + (31 - y) + jitter > 14)
                elif edge_type == 'FULL_GRASS':
                    is_grass = True
                elif edge_type == 'CENTER_PATH':
                    is_grass = False

                if is_grass:
                    t.set_pixel(x, y, base_grass.get_pixel(x, y))

        # Vertical 2.5D grass fringe blades along transition
        for y in range(1, 31):
            for x in range(1, 31):
                cur = t.get_pixel(x, y)
                if cur in GRASS_ARENA_25D:
                    down = t.get_pixel(x, y + 1)
                    if down in COBBLE_PATH_25D:
                        t.set_pixel(x, y, GRASS_ARENA_25D[4]) # top blade
                        t.set_pixel(x, y + 1, OUTLINE_DARK)   # drop shadow on stone

        return t

    tiles_map = [
        ('NW', 0, 0), ('N', 32, 0), ('NE', 64, 0), ('INNER_NW', 96, 0),
        ('W', 0, 32), ('CENTER_PATH', 32, 32), ('E', 64, 32), ('INNER_NE', 96, 32),
        ('SW', 0, 64), ('S', 32, 64), ('SE', 64, 64), ('INNER_SW', 96, 64),
        ('FULL_GRASS', 0, 96), ('INNER_SE', 32, 96), ('CENTER_PATH', 64, 96), ('CENTER_PATH', 96, 96),
    ]

    for etype, tx, ty in tiles_map:
        sheet.blit(make_edge_tile(etype), tx, ty)

    sheet.save_png(os.path.join(OUT_DIR, "art-002_transicao-grama-terra.png"))


if __name__ == '__main__':
    print("Generating ART-002 v2 (2.5D) terrain tiles...")
    build_arena_grass_25d()
    build_forest_grass_25d()
    build_paths_25d()
    build_decals_25d()
    build_transition_sheet_25d()
    print("ART-002 v2 (2.5D) generation completed successfully!")
