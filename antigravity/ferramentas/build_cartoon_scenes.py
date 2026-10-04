"""
Scene assembler for sessao.v2 Cartoon:
Composes full 2.5D demonstration maps for each of the 3 cartoon sessions using the generated cartoon tiles and sprites.
"""

import math
import os
import random
from pixel_art_tool import Canvas, hex_to_rgba

BASE_DIR = r"c:\Users\pattr\pixel-chess\antigravity\entregas\sessao.v2"


def build_scene_s1():
    s1_dir = os.path.join(BASE_DIR, "sessao-01-floresta-nordica")
    # Load spritesheet
    # Canvas size: 384x216 (16:9)
    scene = Canvas(384, 216)

    # 1. Fill ground with vibrant emerald grass (tilted 2.5D rows)
    from generate_sessoes_cartoon import PAL_S1_GRASS, PAL_S1_PINE, PAL_S1_COBBLE, PAL_S1_WOOD, OUTLINE_S1, draw_cartoon_lobe, draw_cartoon_trunk
    for y in range(216):
        for x in range(384):
            # Subtle gradient towards top (distance haze)
            base_col = PAL_S1_GRASS[1] if (x + y * 2) % 7 in [0, 1] else PAL_S1_GRASS[2]
            scene.set_pixel(x, y, base_col)

    # 2. Draw river at top-right
    for y in range(0, 70):
        river_x = int(300 + math.sin(y * 0.08) * 20 - y * 0.3)
        for x in range(river_x, 384):
            c_water = hex_to_rgba('#3B6E8C') if x % 4 != 0 else hex_to_rgba('#62A4C8')
            scene.set_pixel(x, y, c_water)
        # Bank edge
        scene.set_pixel(river_x - 1, y, OUTLINE_S1)
        scene.set_pixel(river_x - 2, y, PAL_S1_COBBLE[2])

    # 3. Winding Pebble Cobblestone Road (from bottom-left to top-center)
    # Road curve: x(y) = 60 + (216 - y) * 0.6 + sin(y*0.05)*15
    for y in range(216):
        rx = int(70 + (216 - y) * 0.6 + math.sin(y * 0.05) * 16)
        rw = 24
        for x in range(rx, rx + rw):
            # Cobblestone pattern
            is_mortar = (x % 7 == 0) or (y % 6 == 0)
            col = PAL_S1_COBBLE[0] if is_mortar else (PAL_S1_COBBLE[4] if (x + y) % 6 == 1 else PAL_S1_COBBLE[2])
            scene.set_pixel(x, y, col)
        # Grass fringe on road edge
        scene.set_pixel(rx - 1, y, PAL_S1_GRASS[4])
        scene.set_pixel(rx + rw, y, OUTLINE_S1)

    # 4. Arena Battle Clearing in center (around x=180, y=120, radius x=65, y=40)
    # Distinct central pavers
    for dy in range(-35, 36):
        for dx in range(-60, 61):
            if (dx*dx)/3600.0 + (dy*dy)/1225.0 <= 1.0:
                # Ring border of smooth river stones
                dist = (dx*dx)/3600.0 + (dy*dy)/1225.0
                if dist > 0.85:
                    scene.set_pixel(180 + dx, 120 + dy, PAL_S1_COBBLE[3] if dx < 0 else PAL_S1_COBBLE[1])
                elif (dx // 12 + dy // 8) % 2 == 0:
                    scene.set_pixel(180 + dx, 120 + dy, PAL_S1_GRASS[3])

    # 5. Place vertical 2.5D Trees around the clearing perimeter
    # Background pines (smaller, higher up)
    for tx, ty in [(40, 45), (100, 35), (160, 30), (220, 25), (280, 20)]:
        # Pine tree (width 32, height 50)
        draw_cartoon_trunk(scene, tx, ty + 25, 6, 14, PAL_S1_WOOD, OUTLINE_S1)
        for i, cy_off in enumerate([24, 14, 4]):
            draw_cartoon_lobe(scene, tx, ty + cy_off, 14 - i * 3, 9 - i * 2, PAL_S1_PINE, OUTLINE_S1)

    # Foreground & Midground Trees (large, on left and right)
    # Left flank: 2 big pines, 1 birch
    draw_cartoon_trunk(scene, 35, 120, 10, 26, PAL_S1_WOOD, OUTLINE_S1)
    for i, cy in enumerate([115, 95, 78, 62]):
        draw_cartoon_lobe(scene, 35, cy, 26 - i * 4, 15 - i * 2, PAL_S1_PINE, OUTLINE_S1)

    draw_cartoon_trunk(scene, 55, 175, 11, 28, PAL_S1_WOOD, OUTLINE_S1)
    for i, cy in enumerate([170, 150, 132, 115]):
        draw_cartoon_lobe(scene, 55, cy, 28 - i * 4, 16 - i * 2, PAL_S1_PINE, OUTLINE_S1)

    # Right flank: grand deciduous oak + pine
    draw_cartoon_trunk(scene, 330, 130, 12, 26, PAL_S1_WOOD, OUTLINE_S1)
    for cx_o, cy_o in [(-18, -6), (18, -4), (-22, -22), (20, -20), (0, -28), (0, -42)]:
        draw_cartoon_lobe(scene, 330 + cx_o, 130 + cy_o, 18, 14, PAL_S1_GRASS, OUTLINE_S1)

    draw_cartoon_trunk(scene, 345, 185, 10, 26, PAL_S1_WOOD, OUTLINE_S1)
    for i, cy in enumerate([180, 160, 142, 126]):
        draw_cartoon_lobe(scene, 345, cy, 26 - i * 4, 15 - i * 2, PAL_S1_PINE, OUTLINE_S1)

    # 6. Ferns, Flower clusters, and river pebbles along path
    for fx, fy in [(110, 160), (130, 95), (255, 150), (270, 110), (195, 75)]:
        draw_cartoon_lobe(scene, fx, fy, 7, 5, PAL_S1_PINE, OUTLINE_S1)
        scene.set_pixel(fx + 2, fy - 2, PAL_S1_GRASS[4])

    for dx, dy in [(125, 170), (245, 165), (210, 80)]:
        scene.draw_circle(dx, dy, 2, hex_to_rgba('#F6DE4C'))
        scene.draw_circle(dx + 4, dy + 2, 2, hex_to_rgba('#FFFFFF'))

    scene.save_png(os.path.join(s1_dir, "mapa_demo_cartoon_25d.png"))


def build_scene_s2():
    s2_dir = os.path.join(BASE_DIR, "sessao-02-campina-solar")
    scene = Canvas(384, 216)

    from generate_sessoes_cartoon import PAL_S2_GRASS, PAL_S2_OAK, PAL_S2_COBBLE, PAL_S2_WOOD, OUTLINE_S2, draw_cartoon_lobe, draw_cartoon_trunk

    # 1. Vibrant sunlit meadow grass (golden-green)
    for y in range(216):
        for x in range(384):
            val = PAL_S2_GRASS[2] if (x + y) % 4 in [0, 1] else PAL_S2_GRASS[3]
            scene.set_pixel(x, y, val)

    # 2. Straight diagonal cobblestone village road
    # y = x * 0.45 + 50
    for x in range(384):
        mid_y = int(x * 0.42 + 45)
        for dy in range(-12, 13):
            y = mid_y + dy
            if 0 <= y < 216:
                is_mort = (x % 8 == 0) or (dy in [-12, 0, 12])
                c = PAL_S2_COBBLE[0] if is_mort else (PAL_S2_COBBLE[4] if (x + y) % 7 == 1 else PAL_S2_COBBLE[2])
                scene.set_pixel(x, y, c)
        if 0 <= mid_y - 13 < 216:
            scene.set_pixel(x, mid_y - 13, OUTLINE_S2)
        if 0 <= mid_y + 13 < 216:
            scene.set_pixel(x, mid_y + 13, OUTLINE_S2)

    # 3. Circular sunlit arena boundary (low drystone wall + benches)
    cx, cy = 192, 125
    rx, ry = 75, 45
    for dy in range(-ry, ry + 1):
        for dx in range(-rx, rx + 1):
            dist = (dx*dx)/float(rx*rx) + (dy*dy)/float(ry*ry)
            if 0.90 <= dist <= 1.05:
                # Drystone curb
                scene.set_pixel(cx + dx, cy + dy, PAL_S2_COBBLE[3] if dx < 0 else PAL_S2_COBBLE[1])
            elif dist < 0.90:
                # Arena floor with daisy circles
                if int(math.sqrt(dx*dx + dy*dy)) in [15, 30]:
                    scene.set_pixel(cx + dx, cy + dy, hex_to_rgba('#FFFFFF'))

    # Benches along perimeter
    for bx, by in [(140, 85), (240, 85), (135, 160), (245, 160)]:
        scene.draw_rect(bx - 12, by - 3, 24, 6, PAL_S2_WOOD[2])
        scene.draw_rect(bx - 12, by - 4, 24, 1, PAL_S2_WOOD[3])
        scene.draw_rect(bx - 13, by - 5, 26, 1, OUTLINE_S2)
        scene.draw_rect(bx - 13, by + 3, 26, 1, OUTLINE_S2)

    # 4. Big Sunny Oaks & Pines surrounding clearing
    # Back line
    for tx in [60, 130, 260, 330]:
        draw_cartoon_trunk(scene, tx, 45, 8, 18, PAL_S2_WOOD, OUTLINE_S2)
        draw_cartoon_lobe(scene, tx, 35, 18, 13, PAL_S2_OAK, OUTLINE_S2)
        draw_cartoon_lobe(scene, tx - 8, 25, 14, 11, PAL_S2_OAK, OUTLINE_S2)
        draw_cartoon_lobe(scene, tx + 8, 25, 14, 11, PAL_S2_OAK, OUTLINE_S2)

    # Flanks
    draw_cartoon_trunk(scene, 40, 135, 14, 28, PAL_S2_WOOD, OUTLINE_S2)
    for ox, oy in [(-20, -10), (20, -8), (0, -25), (-12, -38), (12, -38)]:
        draw_cartoon_lobe(scene, 40 + ox, 135 + oy, 22, 16, PAL_S2_OAK, OUTLINE_S2)

    draw_cartoon_trunk(scene, 345, 140, 10, 26, PAL_S2_WOOD, OUTLINE_S2)
    for i, py in enumerate([135, 115, 98, 82]):
        draw_cartoon_lobe(scene, 345, py, 26 - i * 4, 15 - i * 2, PAL_S2_OAK, OUTLINE_S2)

    scene.save_png(os.path.join(s2_dir, "mapa_demo_cartoon_25d.png"))


def build_scene_s3():
    s3_dir = os.path.join(BASE_DIR, "sessao-03-terraco-rochoso")
    scene = Canvas(384, 216)

    from generate_sessoes_cartoon import PAL_S3_GRASS, PAL_S3_TREE, PAL_S3_STONE, PAL_S1_WOOD, OUTLINE_S3, draw_cartoon_lobe, draw_cartoon_trunk

    # 1. Highland mossy grass
    for y in range(216):
        for x in range(384):
            val = PAL_S3_GRASS[1] if (x + y) % 5 == 0 else PAL_S3_GRASS[2]
            scene.set_pixel(x, y, val)

    # 2. Elevated rock terrace steps in center (amphitheater levels)
    # Tier 1 (outer)
    cx, cy = 192, 115
    for dy in range(-45, 46):
        for dx in range(-75, 76):
            d = (dx*dx)/5625.0 + (dy*dy)/2025.0
            if 0.90 <= d <= 1.0:
                scene.set_pixel(cx + dx, cy + dy, PAL_S3_STONE[3] if dy < 0 else PAL_S3_STONE[1])

    # Tier 2 (inner)
    for dy in range(-30, 31):
        for dx in range(-50, 51):
            d = (dx*dx)/2500.0 + (dy*dy)/900.0
            if 0.88 <= d <= 1.0:
                scene.set_pixel(cx + dx, cy + dy, PAL_S3_STONE[4] if dy < 0 else PAL_S3_STONE[2])
            elif d < 0.88:
                scene.set_pixel(cx + dx, cy + dy, PAL_S3_GRASS[3])

    # 3. Winding granite slab trail to bottom-left
    for y in range(115, 216):
        tx = int(192 - (y - 115) * 1.1 + math.sin(y * 0.06) * 12)
        for dx in range(-10, 11):
            c_slab = PAL_S3_STONE[2] if (tx + dx + y) % 8 != 0 else PAL_S3_STONE[0]
            scene.set_pixel(tx + dx, y, c_slab)

    # 4. Highland Pines & Gnarled Trees
    for tx, ty in [(50, 60), (330, 65), (55, 170), (335, 165)]:
        draw_cartoon_trunk(scene, tx, ty, 10, 24, PAL_S1_WOOD, OUTLINE_S3)
        for i, cy_off in enumerate([ty - 5, ty - 22, ty - 38, ty - 52]):
            draw_cartoon_lobe(scene, tx, cy_off, 24 - i * 3, 14 - i * 2, PAL_S3_TREE, OUTLINE_S3)

    scene.save_png(os.path.join(s3_dir, "mapa_demo_cartoon_25d.png"))


if __name__ == '__main__':
    print("Building full 2.5D demonstration scenes for all 3 cartoon sessions...")
    build_scene_s1()
    build_scene_s2()
    build_scene_s3()
    print("All demonstration scenes built successfully!")
