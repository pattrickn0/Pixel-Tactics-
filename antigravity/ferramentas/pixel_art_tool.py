"""
Pixel Art Tool & Generator for Pixel Chess
Executes pure Python PNG creation and procedural pixel art generation according to docs/direcao-de-arte.md.
"""

import math
import os
import struct
import zlib

# --- Palette definitions from docs/direcao-de-arte.md ---
def hex_to_rgba(hex_str, alpha=255):
    hex_str = hex_str.lstrip('#')
    r = int(hex_str[0:2], 16)
    g = int(hex_str[2:4], 16)
    b = int(hex_str[4:6], 16)
    return (r, g, b, alpha)

# Palettes
C_TRANSPARENT = (0, 0, 0, 0)

# Grama (planicie/arena)
GRASS_ARENA = [
    hex_to_rgba('#4E7A2A'), # 0: Sombra profunda
    hex_to_rgba('#6B9B37'), # 1: Base média
    hex_to_rgba('#8DB846'), # 2: Luz média
    hex_to_rgba('#B3CF5E'), # 3: Highlight
]

# Mata / copas (floresta)
GRASS_FOREST = [
    hex_to_rgba('#1F3D2B'), # 0
    hex_to_rgba('#2E5A34'), # 1
    hex_to_rgba('#3F7A3A'), # 2
    hex_to_rgba('#5E9A45'), # 3
    hex_to_rgba('#86B84F'), # 4
]

# Terra / trilha
DIRT_PATH = [
    hex_to_rgba('#6E5538'), # 0: Sombra
    hex_to_rgba('#8A6E4B'), # 1: Base
    hex_to_rgba('#C2A57A'), # 2: Luz
    hex_to_rgba('#E0CDA0'), # 3: Highlight
]

# Pedra / ruina
STONE = [
    hex_to_rgba('#3A4048'), # 0: Sombra escura
    hex_to_rgba('#4A5058'), # 1: Sombra media
    hex_to_rgba('#6E7680'), # 2: Base
    hex_to_rgba('#9AA3AC'), # 3: Luz
    hex_to_rgba('#C8CFD4'), # 4: Highlight
]

# Madeira / tronco
WOOD = [
    hex_to_rgba('#3B2A1E'), # 0
    hex_to_rgba('#5C3F2A'), # 1
    hex_to_rgba('#7E5A3A'), # 2
]

# Tronco claro / bétula (ref-ruinas)
BIRCH = [
    hex_to_rgba('#4A5058'), # nós escuros
    hex_to_rgba('#9AA3AC'), # sombra
    hex_to_rgba('#C8CFD4'), # base
    hex_to_rgba('#ECEBDF'), # highlight
]

# Flores e detalhes
FLOWER_YELLOW = hex_to_rgba('#F2E27A')
FLOWER_WHITE = hex_to_rgba('#ECEBDF')
FLOWER_PINK = hex_to_rgba('#E39BB0')

# Contorno / sombra de chão
OUTLINE_DARK = hex_to_rgba('#1A2420')
SHADOW_GROUND = hex_to_rgba('#24302A', 180) # Sombra translúcida / sólida
SHADOW_SOLID = hex_to_rgba('#24302A')


class Canvas:
    def __init__(self, width, height, fill=C_TRANSPARENT):
        self.width = width
        self.height = height
        self.pixels = [[fill for _ in range(width)] for _ in range(height)]

    def set_pixel(self, x, y, color):
        if 0 <= x < self.width and 0 <= y < self.height:
            if color[3] == 255 or self.pixels[y][x][3] == 0:
                self.pixels[y][x] = color
            elif color[3] > 0:
                # Alpha blend
                dst = self.pixels[y][x]
                src = color
                a_src = src[3] / 255.0
                a_dst = dst[3] / 255.0 * (1.0 - a_src)
                a_out = a_src + a_dst
                if a_out > 0:
                    r = int((src[0] * a_src + dst[0] * a_dst) / a_out)
                    g = int((src[1] * a_src + dst[1] * a_dst) / a_out)
                    b = int((src[2] * a_src + dst[2] * a_dst) / a_out)
                    self.pixels[y][x] = (r, g, b, int(a_out * 255))

    def get_pixel(self, x, y):
        if 0 <= x < self.width and 0 <= y < self.height:
            return self.pixels[y][x]
        return C_TRANSPARENT

    def draw_rect(self, x, y, w, h, color):
        for cy in range(y, y + h):
            for cx in range(x, x + w):
                self.set_pixel(cx, cy, color)

    def draw_circle(self, cx, cy, radius, color):
        r2 = radius * radius
        for dy in range(-int(radius) - 1, int(radius) + 2):
            for dx in range(-int(radius) - 1, int(radius) + 2):
                if dx * dx + dy * dy <= r2:
                    self.set_pixel(cx + dx, cy + dy, color)

    def draw_ellipse(self, cx, cy, rx, ry, color):
        for dy in range(-int(ry) - 1, int(ry) + 2):
            for dx in range(-int(rx) - 1, int(rx) + 2):
                if (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0:
                    self.set_pixel(cx + dx, cy + dy, color)

    def blit(self, source, dx, dy):
        for sy in range(source.height):
            for sx in range(source.width):
                c = source.get_pixel(sx, sy)
                if c[3] > 0:
                    self.set_pixel(dx + sx, dy + sy, c)

    def save_png(self, filepath):
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        raw_data = bytearray()
        for y in range(self.height):
            raw_data.append(0)  # Filter type 0: None
            for x in range(self.width):
                r, g, b, a = self.pixels[y][x]
                raw_data.extend([r, g, b, a])

        compressed = zlib.compress(raw_data, 9)

        # PNG signature
        png = bytearray(b'\x89PNG\r\n\x1a\n')

        # IHDR chunk
        ihdr = struct.pack('>IIBBBBB', self.width, self.height, 8, 6, 0, 0, 0)
        png.extend(struct.pack('>I', len(ihdr)))
        png.extend(b'IHDR')
        png.extend(ihdr)
        png.extend(struct.pack('>I', zlib.crc32(b'IHDR' + ihdr) & 0xffffffff))

        # IDAT chunk
        png.extend(struct.pack('>I', len(compressed)))
        png.extend(b'IDAT')
        png.extend(compressed)
        png.extend(struct.pack('>I', zlib.crc32(b'IDAT' + compressed) & 0xffffffff))

        # IEND chunk
        png.extend(struct.pack('>I', 0))
        png.extend(b'IEND')
        png.extend(struct.pack('>I', zlib.crc32(b'IEND') & 0xffffffff))

        with open(filepath, 'wb') as f:
            f.write(png)
        print(f"Saved: {filepath} ({self.width}x{self.height})")


if __name__ == '__main__':
    print("pixel_art_tool loaded successfully!")
