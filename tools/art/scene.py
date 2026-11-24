"""Mock-up renders for the design canvas, using the same light model the game
will use: light levels 0–4 from point lights, ordered (Bayer) dithering
between levels, tiles shifted along their material ramp, sprites darkened
or reduced to silhouettes with glowing eyes."""
from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image

import art

W, H = 640, 360
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
EMISSIVE = {
    "player_a": set("efgh"), "player_b": set("efgh"),
    "brazier_a": set("defgh"), "brazier_b": set("defgh"),
    "bat_a": {"k"}, "bat_b": {"k"}, "mage": {"t", "9"}, "brute": {"j"},
    "soul": set("defgh"), "frost_orb": set("rst9"), "vorlak": set("ghek"),
}


def _nearest(rgb):
    return min(art.RGB, key=lambda k: sum((a - b) ** 2 for a, b in zip(art.RGB[k], rgb)))


_dark_cache: dict[tuple[str, float], str] = {}


def darken(key: str, f: float) -> str:
    if (key, f) not in _dark_cache:
        r, g, b = art.RGB[key]
        _dark_cache[(key, f)] = _nearest((r * f, g * f * 0.97, b * f * 1.04))
    return _dark_cache[(key, f)]


class Scene:
    def __init__(self, tmap: list[str], explored, lights, ox=0, oy=0):
        self.m = tmap
        self.explored = explored
        self.lights = lights  # (x, y, radius, intensity)
        self.ox, self.oy = ox, oy
        self.img = Image.new("RGB", (W, H), art.RGB["0"])
        self.px = self.img.load()

    # -- light
    def light(self, x, y, dither=True):
        v = 0.0
        for lx, ly, rad, inten in self.lights:
            d = math.hypot(x - lx, y - ly)
            if d < rad:
                v += inten * (1 - d / rad) ** 1.35
        if not dither:
            return min(5, v)
        t = (BAYER[y % 4][x % 4] + 0.5) / 16
        return max(0, min(5, int(v + t)))

    def cell(self, tx, ty):
        if 0 <= ty < len(self.m) and 0 <= tx < len(self.m[0]):
            return self.m[ty][tx]
        return "#"

    def seen(self, tx, ty):
        return (tx, ty) in self.explored

    # -- tiles
    def draw_tiles(self, floor_pick=None):
        rows, cols = len(self.m), len(self.m[0])
        for ty in range(rows):
            for tx in range(cols):
                c = self.cell(tx, ty)
                if c in ".S":
                    if not self.seen(tx, ty):
                        continue
                    if c == "S":
                        tile, ramp = art.T["stairs"], art.STONE
                    else:
                        v = floor_pick(tx, ty) if floor_pick else (tx * 7 + ty * 13) % 11
                        tile = art.T["floor_b"] if v == 3 else art.T["floor_c"] if v in (5, 9) else art.T["floor_a"]
                        ramp = art.STONE
                    self._blit_tile(tile, ramp, tx, ty)
                else:
                    below = self.cell(tx, ty + 1)
                    if below in ".S" and self.seen(tx, ty + 1):
                        self._blit_tile(art.T["wall_face"], art.STONE, tx, ty)
                    else:
                        nb = {
                            "n": self.cell(tx, ty - 1) in ".S" and self.seen(tx, ty - 1),
                            "e": self.cell(tx + 1, ty) in ".S" and self.seen(tx + 1, ty),
                            "w": self.cell(tx - 1, ty) in ".S" and self.seen(tx - 1, ty),
                        }
                        # a wall top only shows if it borders something we have seen
                        near = any(self.seen(tx + dx, ty + dy) and self.cell(tx + dx, ty + dy) in ".S"
                                   for dx in (-1, 0, 1) for dy in (-1, 0, 1, 2))
                        if not near:
                            continue
                        top = [list(r) for r in art.T["wall_top"]]
                        for i in range(16):
                            if nb["n"]:
                                top[0][i] = "2"
                            if nb["e"]:
                                top[i][15] = "1"
                            if nb["w"]:
                                top[i][0] = "1"
                        self._blit_tile(["".join(r) for r in top], art.STONE, tx, ty)

    def _blit_tile(self, tile, ramp, tx, ty):
        x0, y0 = tx * 16 - self.ox, ty * 16 - self.oy
        for y in range(16):
            sy = y0 + y
            if not 0 <= sy < H:
                continue
            for x in range(16):
                sx = x0 + x
                if not 0 <= sx < W:
                    continue
                ch = tile[y][x]
                if ch == "x":
                    key = "0"
                elif ch.isdigit():
                    idx = int(ch) + self.light(sx, sy) - 1
                    key = ramp[max(0, min(idx, len(ramp) - 1))]
                else:
                    key = ch
                self.px[sx, sy] = art.RGB[key]

    # -- sprites
    def sprite(self, name, x, y, flash=False, level=None, rows=None):
        rows = rows or art.S[name]
        h, w = len(rows), len(rows[0])
        emit = EMISSIVE.get(name, set())
        if level is None:
            level = self.light(int(x + w / 2), int(y + h - 2), dither=False)
        if flash:
            mode = "flash"
        elif level >= 3:
            mode = 1.0
        elif level >= 2:
            mode = 0.78
        elif level >= 0.9:
            mode = 0.55
        else:
            mode = "sil"
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch == ".":
                    continue
                sx, sy = int(x) + i, int(y) + j
                if not (0 <= sx < W and 0 <= sy < H):
                    continue
                if mode == "flash":
                    key = "9"
                elif ch in emit or mode == 1.0:
                    key = ch
                elif mode == "sil":
                    key = "1"
                else:
                    key = darken(ch, mode)
                self.px[sx, sy] = art.RGB[key]

    def dot(self, x, y, key):
        if 0 <= x < W and 0 <= y < H:
            self.px[int(x), int(y)] = art.RGB[key]

    def slash(self, cx, cy, ang_deg, r0=19, r1=24, span=110):
        a0 = math.radians(ang_deg - span / 2)
        for y in range(int(cy - r1 - 1), int(cy + r1 + 2)):
            for x in range(int(cx - r1 - 1), int(cx + r1 + 2)):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if not r0 <= d <= r1:
                    continue
                a = math.atan2(y + 0.5 - cy, x + 0.5 - cx)
                t = ((a - a0) % (2 * math.pi)) / math.radians(span)
                if t > 1:
                    continue
                # thick at the leading edge, thinning and dithering towards the tail
                inner = r1 - (r1 - r0) * t
                if d < inner:
                    continue
                if t < 0.35 and (x + y) % 2:
                    continue
                key = "h" if d > r1 - 1.2 else ("g" if t > 0.55 else "f")
                self.dot(x, y, key)

    def spark(self, x, y):
        for dx, dy, k in [(0, 0, "9"), (1, 0, "h"), (-1, 0, "h"), (0, 1, "h"), (0, -1, "h"),
                          (2, -2, "g"), (-2, 2, "g"), (3, 0, "g"), (-3, 0, "g"), (0, -3, "g"), (0, 3, "g"),
                          (-2, -2, "g"), (2, 2, "g")]:
            self.dot(x + dx, y + dy, k)

    def dim(self, factor):
        for y in range(H):
            for x in range(W):
                r, g, b = self.px[x, y]
                self.px[x, y] = (int(r * factor), int(g * factor), int(b * factor))

    def save(self, path):
        self.img.save(path)


# ------------------------------------------------------------ the scenes ---
def dungeon_map():
    m = [["#"] * 40 for _ in range(23)]

    def room(x0, y0, x1, y1):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                m[y][x] = "."

    room(0, 6, 4, 13)
    room(5, 9, 8, 10)
    room(9, 5, 27, 16)
    room(28, 10, 33, 11)
    room(34, 4, 39, 15)
    room(17, 17, 18, 22)
    for x, y in [(13, 8), (14, 8), (13, 9), (14, 9), (22, 12), (23, 12), (22, 13), (23, 13)]:
        m[y][x] = "#"
    m[8][2] = "S"
    explored = set()
    for y in range(23):
        for x in range(40):
            if m[y][x] in ".S" and x < 34:
                explored.add((x, y))
    return ["".join(r) for r in m], explored


def main_scene(out: Path, dimmed=False):
    m, explored = dungeon_map()
    px, py = 318, 170  # player sprite top-left
    lights = [
        (px + 8, py + 5, 168, 6.6),
        (184, 85, 96, 3.9), (408, 85, 96, 3.9),
        (40, 136, 40, 2.6),
        (452, 172, 34, 2.2),
    ]
    sc = Scene(m, explored, lights)
    sc.draw_tiles()
    # decals
    sc.sprite("skull", 288, 118)
    sc.sprite("bones", 392, 238)
    sc.sprite("rubble", 152, 166)
    sc.sprite("rubble", 420, 200)
    # props
    sc.sprite("brazier_a", 176, 80)
    sc.sprite("brazier_b", 400, 80)
    sc.sprite("chest", 236, 196)
    for sx, sy in [(352, 204), (361, 211), (344, 214)]:
        sc.sprite("soul", sx, sy)
    # enemies
    sc.sprite("bat_a", 188, 104)
    sc.sprite("slime_b", 252, 222)
    sc.sprite("slime_a", 344, 146)
    sc.sprite("mage", 478, 158)
    sc.sprite("bat_b", 572, 120, level=0)       # unexplored room: only eyes
    sc.sprite("mage", 276, 336, level=0)        # south corridor, out of the light
    # projectile with trail
    sc.dot(462, 172, "r"); sc.dot(460, 172, "r"); sc.dot(458, 173, "r")
    sc.dot(464, 171, "s"); sc.dot(465, 173, "s")
    sc.sprite("frost_orb", 448, 168)
    # player, weapon, swing
    sc.sprite("player_a", px, py, level=5)
    sc.sprite("sword", px + 13, py + 3, level=5)
    sc.slash(px + 8, py + 10, -38)
    sc.spark(352, 156)
    if dimmed:
        sc.dim(0.42)
    sc.save(out)
    return sc


CARPET = ["0", "0", "1", "1", "i", "i", "i", "j"]


def throne_scene(out: Path):
    m = [["#"] * 40 for _ in range(23)]
    for y in range(2, 21):
        for x in range(5, 35):
            m[y][x] = "."
    for x0 in (8, 30):
        for y0 in (5, 10, 15):
            for dx in (0, 1):
                for dy in (0, 1):
                    m[y0 + dy][x0 + dx] = "#"
    m = ["".join(r) for r in m]
    explored = {(x, y) for y in range(23) for x in range(40) if m[y][x] == "."}
    px, py = 312, 196
    lights = [(px + 8, py + 5, 168, 6.6), (212, 53, 100, 5.0), (420, 53, 100, 5.0),
              (104, 149, 96, 4.6), (536, 149, 96, 4.6), (320, 46, 80, 3.0)]
    sc = Scene(m, explored, lights)
    sc.draw_tiles()
    # carpet runner up to the dais
    rug = ["2222222222222222"] * 13 + ["2222222112222222", "2222221331222222", "2222222112222222"]
    for ty in range(2, 21):
        for tx in range(17, 23):
            x0, y0 = tx * 16, ty * 16
            for y in range(16):
                for x in range(16):
                    ch = rug[y][x] if tx in (19, 20) else "2"
                    edge = (tx == 17 and x < 2) or (tx == 22 and x > 13)
                    if edge:
                        key = "g" if sc.light(x0 + x, y0 + y) >= 3 else "e"
                    else:
                        idx = int(ch) + sc.light(x0 + x, y0 + y) - 1
                        key = CARPET[max(0, min(idx, 7))]
                    sc.dot(x0 + x, y0 + y, key)
    for bx, by in [(204, 48), (412, 48), (96, 144), (528, 144)]:
        sc.sprite("brazier_a" if bx % 3 else "brazier_b", bx, by)
    sc.sprite("skull", 150, 250)
    sc.sprite("bones", 470, 230)
    sc.sprite("vorlak", 304, 22, level=4)
    sc.sprite("player_b", px, py, level=5)
    sc.sprite("sword", px + 13, py + 3, level=5)
    sc.save(out)


def title_scene(out: Path):
    import random
    img = Image.new("RGB", (W, H), art.RGB["0"])
    p = img.load()
    cx, cy, r = 320, 128, 30
    ring = r + 1.15
    for y in range(H):
        for x in range(W):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d <= ring:
                continue
            v = 3.0 * max(0.0, 1 - (d - ring) / 125) ** 1.7
            t = (BAYER[y % 4][x % 4] + 0.5) / 16
            lvl = int(v + t)
            key = {0: "0", 1: "u", 2: "d", 3: "e"}.get(min(lvl, 3))
            p[x, y] = art.RGB[key]
    crown = art.eclipse(160, 160, 80, 80 + 8, r, spikes=((-66, 11), (-33, 18), (0, 26), (33, 18), (66, 11)),
                        base_w=6.0, glow=False)
    for j, row in enumerate(crown):
        for i, ch in enumerate(row):
            if ch != ".":
                p[cx - 80 + i, cy - 88 + j] = art.RGB[ch]
    rnd = random.Random(7)
    for _ in range(46):
        x, y = rnd.randrange(150, 490), rnd.randrange(20, 330)
        if math.hypot(x - cx, y - cy) < ring + 26:
            continue
        k = rnd.choice("ffgh" if y < 230 else "eff")
        p[x, y] = art.RGB[k]
        if rnd.random() < 0.3 and y + 1 < H:
            p[x, y + 1] = art.RGB["e"]
    img.save(out)


def minimap(out: Path):
    m, explored = dungeon_map()
    im = Image.new("RGBA", (80, 46), (0, 0, 0, 0))
    p = im.load()
    for (x, y) in explored:
        cur = 9 <= x <= 27 and 5 <= y <= 16
        key = "5" if cur else "3"
        if m[y][x] == "S":
            key = "f"
        for dx in (0, 1):
            for dy in (0, 1):
                p[x * 2 + dx, y * 2 + dy] = art.RGB[key] + (255,)
    for dx in (0, 1):
        for dy in (0, 1):
            p[20 * 2 + dx, 11 * 2 + dy] = art.RGB["h"] + (255,)
    im.save(out)


def ramp_strip(out: Path):
    sc = Scene(["." * 6], {(i, 0) for i in range(6)}, [])
    img = Image.new("RGB", (6 * 16 + 5 * 4, 16), art.RGB["0"])
    p = img.load()
    for lvl in range(6):
        for y in range(16):
            for x in range(16):
                ch = art.T["floor_a"][y][x]
                idx = int(ch) + lvl - 1
                p[lvl * 20 + x, y] = art.RGB[art.STONE[max(0, min(idx, 7))]]
    img.save(out)


def sprites(out: Path, names):
    for n in names:
        art.to_image(art.S[n]).save(out / f"{n}.png")


if __name__ == "__main__":
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else art.OUT
    out.mkdir(parents=True, exist_ok=True)
    main_scene(out / "scene_main.png")
    main_scene(out / "scene_main_dim.png", dimmed=True)
    throne_scene(out / "scene_throne.png")
    title_scene(out / "scene_title.png")
    minimap(out / "minimap.png")
    ramp_strip(out / "ramp.png")
    sprites(out, ["player_a", "slime_a", "mini_slime", "splitter", "bat_a", "mage", "brute", "chest",
                  "brazier_a", "soul", "frost_orb", "sword", "vorlak", "mark32", "mark16",
                  "g_lifesteal", "g_dash", "g_glass"])
    print("ok")
