"""
Generator for ART-002: Tiles de terreno (32x32)
Creates seamless tiles for grass arena, grass forest, dirt path, decals sheet, and grass-dirt transition autotile.
"""

import os
import random
from pixel_art_tool import (
    Canvas, GRASS_ARENA, GRASS_FOREST, DIRT_PATH, STONE,
    FLOWER_YELLOW, FLOWER_WHITE, FLOWER_PINK, C_TRANSPARENT,
    hex_to_rgba, OUTLINE_DARK
)

OUT_DIR = r"c:\Users\pattr\pixel-chess\antigravity\entregas\ART-002\v1"
os.makedirs(OUT_DIR, exist_ok=True)

# Helper for pseudo-random deterministic noise with toroidal wrap
def make_noise_grid(w, h, seed):
    rng = random.Random(seed)
    return [[rng.random() for _ in range(w)] for _ in range(h)]

def sample_smooth_noise(grid, x, y, w, h):
    # Bilinear interpolation with toroidal wrap
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

def generate_seamless_texture(palette, base_idx, seed, detail_type='grass', contrast=1.0):
    c = Canvas(32, 32)
    w, h = 32, 32
    g_coarse = make_noise_grid(8, 8, seed)
    g_fine = make_noise_grid(16, 16, seed + 101)
    g_micro = make_noise_grid(32, 32, seed + 202)

    for y in range(h):
        for x in range(w):
            nc = sample_smooth_noise(g_coarse, x / 4.0, y / 4.0, 8, 8)
            nf = sample_smooth_noise(g_fine, x / 2.0, y / 2.0, 16, 16)
            nm = g_micro[y][x]

            # Combine noise
            val = (nc * 0.5 + nf * 0.35 + nm * 0.15 - 0.5) * contrast + 0.5

            if detail_type == 'arena_grass':
                # Light grass: mostly palette[2] with patches of palette[1] and highlights palette[3]
                if val < 0.28:
                    col = palette[0] # Darkest accent/shade
                elif val < 0.52:
                    col = palette[1] # Mid base
                elif val < 0.82:
                    col = palette[2] # Bright base
                else:
                    col = palette[3] # Highlight blade

            elif detail_type == 'forest_grass':
                # Darker forest grass: palette 0, 1, 2, 3
                if val < 0.25:
                    col = palette[0]
                elif val < 0.55:
                    col = palette[1]
                elif val < 0.82:
                    col = palette[2]
                else:
                    col = palette[3]

            elif detail_type == 'dirt':
                # Sand / dirt path
                if val < 0.22:
                    col = palette[0]
                elif val < 0.58:
                    col = palette[1]
                elif val < 0.85:
                    col = palette[2]
                else:
                    col = palette[3]

            c.set_pixel(x, y, col)

    return c

# Add subtle pixel blades (seamless)
def add_grass_blades(canvas, palette, seed, density=12, highlight_color=None, shadow_color=None):
    rng = random.Random(seed)
    w, h = canvas.width, canvas.height
    hl = highlight_color or palette[-1]
    sh = shadow_color or palette[0]

    for _ in range(density):
        x = rng.randint(0, w - 1)
        y = rng.randint(0, h - 1)
        blade_type = rng.choice(['single', 'tuft', 'diagonal'])

        if blade_type == 'single':
            # Light top, shadow bottom
            canvas.set_pixel(x, y, hl)
            canvas.set_pixel(x, (y + 1) % h, sh)
        elif blade_type == 'diagonal':
            canvas.set_pixel(x, y, hl)
            canvas.set_pixel((x + 1) % w, (y + 1) % h, sh)
        elif blade_type == 'tuft':
            canvas.set_pixel(x, y, hl)
            canvas.set_pixel((x - 1) % w, (y + 1) % h, hl)
            canvas.set_pixel(x, (y + 1) % h, sh)
            canvas.set_pixel((x + 1) % w, (y + 2) % h, sh)

# --- 1. Arena Grass (Clear/Bright) ---
def build_arena_grass():
    # Variant A: clean smooth baseline
    ga = generate_seamless_texture(GRASS_ARENA, 2, seed=42, detail_type='arena_grass', contrast=0.7)
    add_grass_blades(ga, GRASS_ARENA, seed=101, density=8)
    ga.save_png(os.path.join(OUT_DIR, "art-002_grama-arena_a.png"))

    # Variant B: gentle wavy variation
    gb = generate_seamless_texture(GRASS_ARENA, 2, seed=89, detail_type='arena_grass', contrast=0.9)
    add_grass_blades(gb, GRASS_ARENA, seed=202, density=12)
    gb.save_png(os.path.join(OUT_DIR, "art-002_grama-arena_b.png"))

    # Variant C: micro-tuft variation
    gc = generate_seamless_texture(GRASS_ARENA, 2, seed=137, detail_type='arena_grass', contrast=0.8)
    add_grass_blades(gc, GRASS_ARENA, seed=303, density=16)
    gc.save_png(os.path.join(OUT_DIR, "art-002_grama-arena_c.png"))

    # Variant D: lush texture with clover/tiny leaf accents
    gd = generate_seamless_texture(GRASS_ARENA, 2, seed=256, detail_type='arena_grass', contrast=0.85)
    add_grass_blades(gd, GRASS_ARENA, seed=404, density=14)
    # Tiny accents
    rng = random.Random(777)
    for _ in range(4):
        cx = rng.randint(2, 29)
        cy = rng.randint(2, 29)
        gd.set_pixel(cx, cy, GRASS_ARENA[3])
        gd.set_pixel(cx + 1, cy, GRASS_ARENA[3])
        gd.set_pixel(cx, cy + 1, GRASS_ARENA[2])
    gd.save_png(os.path.join(OUT_DIR, "art-002_grama-arena_d.png"))

# --- 2. Forest Grass (Dark) ---
def build_forest_grass():
    # Variant A: Deep shady ground
    fa = generate_seamless_texture(GRASS_FOREST, 1, seed=512, detail_type='forest_grass', contrast=0.8)
    add_grass_blades(fa, GRASS_FOREST, seed=601, density=10)
    fa.save_png(os.path.join(OUT_DIR, "art-002_grama-mata_a.png"))

    # Variant B: Canopy shadow variation with mossy patches
    fb = generate_seamless_texture(GRASS_FOREST, 1, seed=777, detail_type='forest_grass', contrast=1.1)
    add_grass_blades(fb, GRASS_FOREST, seed=702, density=14)
    fb.save_png(os.path.join(OUT_DIR, "art-002_grama-mata_b.png"))

    # Variant C: Fallen pine/leaf needles texture
    fc = generate_seamless_texture(GRASS_FOREST, 1, seed=999, detail_type='forest_grass', contrast=0.9)
    add_grass_blades(fc, GRASS_FOREST, seed=803, density=12)
    # fallen forest detritus (subtle wood/dirt specks)
    rng = random.Random(888)
    for _ in range(5):
        px = rng.randint(0, 31)
        py = rng.randint(0, 31)
        fc.set_pixel(px, py, DIRT_PATH[1])
        fc.set_pixel((px + 1) % 32, py, DIRT_PATH[0])
    fc.save_png(os.path.join(OUT_DIR, "art-002_grama-mata_c.png"))

# --- 3. Dirt Path ---
def build_dirt_path():
    # Variant A: Smooth packed sand/earth
    da = generate_seamless_texture(DIRT_PATH, 1, seed=123, detail_type='dirt', contrast=0.7)
    # Add subtle fine pebbles
    rng = random.Random(321)
    for _ in range(6):
        px = rng.randint(0, 31)
        py = rng.randint(0, 31)
        da.set_pixel(px, py, DIRT_PATH[3]) # light grain
        da.set_pixel((px + 1) % 32, (py + 1) % 32, DIRT_PATH[0]) # micro shadow
    da.save_png(os.path.join(OUT_DIR, "art-002_terra_a.png"))

    # Variant B: Textured path with subtle ruts / soft grain
    db = generate_seamless_texture(DIRT_PATH, 1, seed=456, detail_type='dirt', contrast=0.9)
    rng = random.Random(654)
    for _ in range(8):
        px = rng.randint(0, 31)
        py = rng.randint(0, 31)
        db.set_pixel(px, py, DIRT_PATH[2])
        db.set_pixel((px + 1) % 32, py, DIRT_PATH[0])
    db.save_png(os.path.join(OUT_DIR, "art-002_terra_b.png"))

# --- 4. Decals Sheet (16x16 cells, transparent) ---
def build_decals_sheet():
    # 4 columns x 3 rows = 64x48 px
    # Row 0: 4 grass tufts
    # Row 1: 3 flowers + 1 small stone
    # Row 2: 2 stones + 2 spare/variants
    sheet = Canvas(64, 48)

    # Cell 0,0: Grass tuft 1 (delicate 2-blade)
    c0 = Canvas(16, 16)
    # blade 1
    c0.set_pixel(7, 8, GRASS_ARENA[3])
    c0.set_pixel(7, 9, GRASS_ARENA[2])
    c0.set_pixel(7, 10, GRASS_ARENA[1])
    c0.set_pixel(7, 11, GRASS_ARENA[0])
    # blade 2
    c0.set_pixel(8, 7, GRASS_ARENA[3])
    c0.set_pixel(8, 8, GRASS_ARENA[2])
    c0.set_pixel(9, 9, GRASS_ARENA[2])
    c0.set_pixel(8, 10, GRASS_ARENA[1])
    c0.set_pixel(8, 11, GRASS_ARENA[0])
    c0.set_pixel(9, 12, OUTLINE_DARK)
    sheet.blit(c0, 0, 0)

    # Cell 1,0: Grass tuft 2 (wide 3-blade tuft)
    c1 = Canvas(16, 16)
    # center
    for y in range(5, 12):
        c1.set_pixel(8, y, GRASS_ARENA[3] if y < 7 else GRASS_ARENA[2])
    c1.set_pixel(8, 12, GRASS_ARENA[0])
    # left curved
    c1.set_pixel(5, 7, GRASS_ARENA[3])
    c1.set_pixel(6, 8, GRASS_ARENA[2])
    c1.set_pixel(7, 9, GRASS_ARENA[2])
    c1.set_pixel(7, 10, GRASS_ARENA[1])
    c1.set_pixel(7, 11, GRASS_ARENA[0])
    # right curved
    c1.set_pixel(11, 7, GRASS_ARENA[3])
    c1.set_pixel(10, 8, GRASS_ARENA[2])
    c1.set_pixel(9, 9, GRASS_ARENA[2])
    c1.set_pixel(9, 10, GRASS_ARENA[1])
    c1.set_pixel(9, 11, GRASS_ARENA[0])
    # shadow underneath
    c1.set_pixel(8, 13, OUTLINE_DARK)
    c1.set_pixel(9, 12, OUTLINE_DARK)
    sheet.blit(c1, 16, 0)

    # Cell 2,0: Grass tuft 3 (lush double tuft)
    c2 = Canvas(16, 16)
    for dy, col in enumerate([GRASS_ARENA[3], GRASS_ARENA[3], GRASS_ARENA[2], GRASS_ARENA[1], GRASS_ARENA[0]]):
        c2.set_pixel(6, 6 + dy, col)
        c2.set_pixel(7, 7 + dy, col)
        c2.set_pixel(9, 6 + dy, col)
        c2.set_pixel(10, 8 + dy, col)
    c2.set_pixel(8, 12, OUTLINE_DARK)
    c2.set_pixel(9, 12, OUTLINE_DARK)
    sheet.blit(c2, 32, 0)

    # Cell 3,0: Grass tuft 4 (small spread tuft)
    c3 = Canvas(16, 16)
    c3.set_pixel(6, 9, GRASS_ARENA[3])
    c3.set_pixel(7, 10, GRASS_ARENA[2])
    c3.set_pixel(8, 9, GRASS_ARENA[3])
    c3.set_pixel(8, 10, GRASS_ARENA[2])
    c3.set_pixel(9, 10, GRASS_ARENA[2])
    c3.set_pixel(10, 9, GRASS_ARENA[3])
    c3.set_pixel(8, 11, GRASS_ARENA[0])
    c3.set_pixel(9, 11, OUTLINE_DARK)
    sheet.blit(c3, 48, 0)

    # Cell 0,1: Yellow flower
    f0 = Canvas(16, 16)
    # stem
    f0.set_pixel(8, 10, GRASS_ARENA[1])
    f0.set_pixel(8, 11, GRASS_ARENA[0])
    f0.set_pixel(7, 10, GRASS_ARENA[2]) # leaf
    # flower petals
    f0.set_pixel(8, 7, FLOWER_YELLOW)
    f0.set_pixel(7, 8, FLOWER_YELLOW)
    f0.set_pixel(8, 8, hex_to_rgba('#E0CDA0')) # center
    f0.set_pixel(9, 8, FLOWER_YELLOW)
    f0.set_pixel(8, 9, FLOWER_YELLOW)
    f0.set_pixel(9, 12, OUTLINE_DARK)
    sheet.blit(f0, 0, 16)

    # Cell 1,1: White flower
    f1 = Canvas(16, 16)
    f1.set_pixel(8, 10, GRASS_ARENA[1])
    f1.set_pixel(8, 11, GRASS_ARENA[0])
    f1.set_pixel(9, 11, GRASS_ARENA[2])
    f1.set_pixel(8, 7, FLOWER_WHITE)
    f1.set_pixel(7, 8, FLOWER_WHITE)
    f1.set_pixel(8, 8, FLOWER_YELLOW) # yellow center
    f1.set_pixel(9, 8, FLOWER_WHITE)
    f1.set_pixel(8, 9, FLOWER_WHITE)
    sheet.blit(f1, 16, 16)

    # Cell 2,1: Pink flower
    f2 = Canvas(16, 16)
    f2.set_pixel(8, 10, GRASS_ARENA[1])
    f2.set_pixel(8, 11, GRASS_ARENA[0])
    f2.set_pixel(7, 7, FLOWER_PINK)
    f2.set_pixel(9, 7, FLOWER_PINK)
    f2.set_pixel(8, 8, FLOWER_WHITE) # white center
    f2.set_pixel(7, 9, FLOWER_PINK)
    f2.set_pixel(9, 9, FLOWER_PINK)
    f2.set_pixel(8, 12, OUTLINE_DARK)
    sheet.blit(f2, 32, 16)

    # Cell 3,1: Pebble 1 (small smooth pebble)
    p0 = Canvas(16, 16)
    # 4x3 pebble
    p0.set_pixel(6, 9, STONE[4]) # highlight
    p0.set_pixel(7, 9, STONE[3])
    p0.set_pixel(8, 9, STONE[2])
    p0.set_pixel(6, 10, STONE[3])
    p0.set_pixel(7, 10, STONE[2])
    p0.set_pixel(8, 10, STONE[1])
    p0.set_pixel(9, 10, STONE[0])
    p0.set_pixel(7, 11, STONE[1])
    p0.set_pixel(8, 11, STONE[0])
    p0.set_pixel(9, 11, OUTLINE_DARK) # shadow
    p0.set_pixel(10, 11, OUTLINE_DARK)
    sheet.blit(p0, 48, 16)

    # Cell 0,2: Pebble 2 (pair of tiny stones)
    p1 = Canvas(16, 16)
    # stone 1
    p1.set_pixel(5, 9, STONE[3])
    p1.set_pixel(6, 9, STONE[2])
    p1.set_pixel(5, 10, STONE[1])
    p1.set_pixel(6, 10, OUTLINE_DARK)
    # stone 2
    p1.set_pixel(9, 8, STONE[4])
    p1.set_pixel(10, 8, STONE[3])
    p1.set_pixel(9, 9, STONE[2])
    p1.set_pixel(10, 9, STONE[1])
    p1.set_pixel(11, 9, STONE[0])
    p1.set_pixel(10, 10, OUTLINE_DARK)
    p1.set_pixel(11, 10, OUTLINE_DARK)
    sheet.blit(p1, 0, 32)

    # Cell 1,2: Pebble 3 (angular flat stone)
    p2 = Canvas(16, 16)
    for x in range(5, 11):
        p2.set_pixel(x, 8, STONE[4] if x < 7 else STONE[3])
        p2.set_pixel(x, 9, STONE[2] if x < 9 else STONE[1])
        p2.set_pixel(x, 10, STONE[1] if x < 8 else STONE[0])
    p2.set_pixel(8, 11, OUTLINE_DARK)
    p2.set_pixel(9, 11, OUTLINE_DARK)
    p2.set_pixel(10, 11, OUTLINE_DARK)
    sheet.blit(p2, 16, 32)

    # Cell 2,2: Clover patch
    cl = Canvas(16, 16)
    cl.set_pixel(7, 8, GRASS_ARENA[3])
    cl.set_pixel(8, 8, GRASS_ARENA[3])
    cl.set_pixel(6, 9, GRASS_ARENA[3])
    cl.set_pixel(7, 9, GRASS_ARENA[2])
    cl.set_pixel(8, 9, GRASS_ARENA[1])
    cl.set_pixel(7, 10, GRASS_ARENA[0])
    sheet.blit(cl, 32, 32)

    # Cell 3,2: Wildflower cluster
    wf = Canvas(16, 16)
    wf.set_pixel(6, 8, FLOWER_YELLOW)
    wf.set_pixel(6, 9, GRASS_ARENA[1])
    wf.set_pixel(10, 7, FLOWER_WHITE)
    wf.set_pixel(10, 8, GRASS_ARENA[1])
    wf.set_pixel(8, 10, FLOWER_PINK)
    wf.set_pixel(8, 11, GRASS_ARENA[0])
    sheet.blit(wf, 48, 32)

    sheet.save_png(os.path.join(OUT_DIR, "art-002_decals.png"))

# --- 5. Transition Sheet: Grass <-> Dirt (Autotile 3x3 + 4 inner corners, 32x32 grid) ---
def build_transition_sheet():
    # 4 columns x 4 rows = 128x128 px
    # Layout standard autotile:
    # Row 0: Top-Left (NW), Top-Center (N), Top-Right (NE), Inner Corner NW
    # Row 1: Mid-Left (W), Center Dirt, Mid-Right (E), Inner Corner NE
    # Row 2: Bot-Left (SW), Bot-Center (S), Bot-Right (SE), Inner Corner SW
    # Row 3: Isolated/Full Grass, Inner Corner SE, Full Dirt A, Full Dirt B
    sheet = Canvas(128, 128)

    base_grass = generate_seamless_texture(GRASS_ARENA, 2, seed=42, detail_type='arena_grass', contrast=0.7)
    base_dirt = generate_seamless_texture(DIRT_PATH, 1, seed=123, detail_type='dirt', contrast=0.7)

    # Helper to generate organic transition mask
    def make_edge_tile(edge_type):
        t = Canvas(32, 32)
        # copy base dirt as background
        t.blit(base_dirt, 0, 0)

        rng = random.Random(hash(edge_type) & 0xffff)
        for y in range(32):
            for x in range(32):
                is_grass = False
                dist = 0
                # Calculate if pixel is grass based on edge_type
                # Add organic jitter
                jitter = (rng.random() - 0.5) * 4.0

                if edge_type == 'N': # Grass on top
                    is_grass = (y + jitter < 14)
                elif edge_type == 'S': # Grass on bottom
                    is_grass = (y + jitter > 17)
                elif edge_type == 'W': # Grass on left
                    is_grass = (x + jitter < 14)
                elif edge_type == 'E': # Grass on right
                    is_grass = (x + jitter > 17)
                elif edge_type == 'NW': # Grass top-left
                    is_grass = (x + y + jitter < 28)
                elif edge_type == 'NE': # Grass top-right
                    is_grass = ((31 - x) + y + jitter < 28)
                elif edge_type == 'SW': # Grass bot-left
                    is_grass = (x + (31 - y) + jitter < 28)
                elif edge_type == 'SE': # Grass bot-right
                    is_grass = ((31 - x) + (31 - y) + jitter < 28)
                elif edge_type == 'INNER_NW': # Dirt in top-left corner
                    is_grass = (x + y + jitter > 14)
                elif edge_type == 'INNER_NE': # Dirt in top-right corner
                    is_grass = ((31 - x) + y + jitter > 14)
                elif edge_type == 'INNER_SW': # Dirt in bot-left corner
                    is_grass = (x + (31 - y) + jitter > 14)
                elif edge_type == 'INNER_SE': # Dirt in bot-right corner
                    is_grass = ((31 - x) + (31 - y) + jitter > 14)
                elif edge_type == 'CENTER_DIRT':
                    is_grass = False
                elif edge_type == 'FULL_GRASS':
                    is_grass = True

                if is_grass:
                    t.set_pixel(x, y, base_grass.get_pixel(x, y))

        # Add fringe fringe blades along the transition border
        for y in range(1, 31):
            for x in range(1, 31):
                cur = t.get_pixel(x, y)
                # If current is grass and neighbor is dirt, add fringe blade
                if cur in GRASS_ARENA:
                    down = t.get_pixel(x, y + 1)
                    if down in DIRT_PATH:
                        t.set_pixel(x, y, GRASS_ARENA[3]) # edge highlight
                        t.set_pixel(x, y + 1, DIRT_PATH[0]) # dirt shadow fringe

        return t

    tiles_map = [
        ('NW', 0, 0), ('N', 32, 0), ('NE', 64, 0), ('INNER_NW', 96, 0),
        ('W', 0, 32), ('CENTER_DIRT', 32, 32), ('E', 64, 32), ('INNER_NE', 96, 32),
        ('SW', 0, 64), ('S', 32, 64), ('SE', 64, 64), ('INNER_SW', 96, 64),
        ('FULL_GRASS', 0, 96), ('INNER_SE', 32, 96), ('CENTER_DIRT', 64, 96), ('CENTER_DIRT', 96, 96),
    ]

    for etype, tx, ty in tiles_map:
        tile = make_edge_tile(etype)
        sheet.blit(tile, tx, ty)

    sheet.save_png(os.path.join(OUT_DIR, "art-002_transicao-grama-terra.png"))


if __name__ == '__main__':
    print("Generating ART-002 terrain tiles...")
    build_arena_grass()
    build_forest_grass()
    build_dirt_path()
    build_decals_sheet()
    build_transition_sheet()
    print("ART-002 generation completed!")
