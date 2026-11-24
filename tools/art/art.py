"""Sunless Crown art kit.

Every sprite and tile in the game is drawn here as text, from one 32-colour
palette. A character in a grid is a palette key; '.' is transparent.
Tiles use digits instead: a digit is a *shade* that the light model shifts
along a material ramp, so the same tile is cold and dark far from the ember
and warm next to it.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

# ---------------------------------------------------------------- palette ---
PAL = {
    # cold neutrals: void → parchment
    "0": "#060609", "1": "#0e0f15", "2": "#171923", "3": "#222534",
    "4": "#303347", "5": "#454860", "6": "#646781", "7": "#8f90a6",
    "8": "#c9c4b5", "9": "#efe8d6",
    # warm stone (what the ember light turns stone into)
    "b": "#43322a", "c": "#6b4b36", "w": "#9c6a3e",
    # ember → gold: the only warm light in the game
    "d": "#6e2412", "e": "#b8461b", "f": "#ec7a2a", "g": "#f5b84a", "h": "#ffe39a",
    # blood
    "i": "#5c1424", "j": "#c33a4b", "k": "#f07a86",
    # moss / slime
    "l": "#1d4a44", "m": "#2f8a6e", "n": "#7fdcb0",
    # violet / arcane
    "o": "#3a2763", "p": "#7552c4", "q": "#b79cf2",
    # frost
    "r": "#1f3a73", "s": "#4a7fe0", "t": "#a8d4ff",
    # wood
    "u": "#3b2418", "v": "#6b4128",
}
assert len(PAL) == 32
RGB = {k: tuple(int(v[i:i + 2], 16) for i in (1, 3, 5)) for k, v in PAL.items()}

# material ramps for lit tiles (index = shade + light level)
STONE = ["0", "1", "2", "3", "4", "b", "c", "w"]
TOP = ["0", "0", "1", "1", "2", "2", "3", "3"]


# ---------------------------------------------------------------- helpers ---
def grid(rows: list[str], name: str = "?") -> list[str]:
    w = len(rows[0])
    for i, r in enumerate(rows):
        assert len(r) == w, f"{name}: row {i} is {len(r)} wide, expected {w}: {r!r}"
        for ch in r:
            assert ch == "." or ch in PAL or ch.isdigit(), f"{name}: bad key {ch!r}"
    return rows


def sym(halves: list[str]) -> list[str]:
    """Mirror left halves into full rows."""
    return [h + h[::-1] for h in halves]


def pad(rows: list[str], h: int) -> list[str]:
    """Bottom-align rows inside a sprite h rows tall."""
    w = len(rows[0])
    return ["." * w] * (h - len(rows)) + rows


def patch(rows: list[str], pts: dict[tuple[int, int], str]) -> list[str]:
    out = [list(r) for r in rows]
    for (x, y), ch in pts.items():
        out[y][x] = ch
    return ["".join(r) for r in out]


def recolor(rows: list[str], mapping: dict[str, str]) -> list[str]:
    return ["".join(mapping.get(c, c) for c in r) for r in rows]


def to_image(rows: list[str], scale: int = 1) -> Image.Image:
    h, w = len(rows), len(rows[0])
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != ".":
                px[x, y] = RGB[ch] + (255,)
    if scale != 1:
        im = im.resize((w * scale, h * scale), Image.NEAREST)
    return im


# ---------------------------------------------------------------- sprites ---
S: dict[str, list[str]] = {}

_player_body = sym([
    "....fghh",
    "....gh0h",
    "....fghh",
    ".....efg",
    "....1cwd",
    "...1cw54",
    "...1b553",
    "..1b4553",
    "..144553",
    "..134453",
    "....111.",
])
S["player_a"] = grid([
    "........e.......",
    ".......ef...e...",
    "......efge......",
    ".....effgfe.....",
    ".....fgghgf.....",
] + _player_body, "player_a")
S["player_b"] = grid([
    ".......e........",
    "...e...fe.......",
    "......egfe......",
    ".....efgffe.....",
    ".....fghggf.....",
] + _player_body, "player_b")

S["slime_a"] = grid(pad(sym([
    "......ll",
    "....llmm",
    "...lmmmn",
    "..lmmmn9",
    "..lmmmmn",
    ".lmmm0mm",
    ".lmmm0mm",
    ".lmmmmmm",
    ".lllmmmm",
    "..llllll",
]), 16), "slime_a")
S["slime_b"] = grid(pad(sym([
    ".....lll",
    "...llmmn",
    "..lmmmn9",
    ".lmmmmmn",
    "lmmmm0mm",
    "lmmmm0mm",
    "lllmmmmm",
    ".lllllll",
]), 16), "slime_b")
S["mini_slime"] = grid(sym([
    "...ll",
    ".llmn",
    ".lmn9",
    "lmmmm",
    "lm0mm",
    "lmmmm",
    "lllmm",
    ".llll",
]), "mini_slime")
S["splitter"] = grid(patch(recolor(S["slime_a"], {"l": "r", "m": "s", "n": "t"}),
                           {(7, 7): "1", (8, 8): "1", (7, 9): "1", (7, 10): "1",
                            (8, 11): "1", (8, 12): "1", (7, 13): "1"}), "splitter")

S["bat_a"] = grid(pad(sym([
    ".o......",
    ".po.....",
    ".ppo..o.",
    ".pppo.oo",
    ".ppppoko",
    "oppppooq",
    "o.ppp.oq",
    "...o..o.",
    "........",
    "........",
]), 16), "bat_a")
S["bat_b"] = grid(pad(sym([
    "......o.",
    ".....ooo",
    "....ooko",
    "..oppooq",
    ".opppooq",
    "opppp.o.",
    "opp.p...",
    "o..o....",
    "........",
    "........",
]), 16), "bat_b")

S["mage"] = grid(patch(sym([
    "........",
    ".......1",
    "......1r",
    ".....1rs",
    "....1rs0",
    "...1r0t0",
    "...1r000",
    "...11r00",
    "..1rr111",
    "..1rssrr",
    "..1rssrt",
    ".1rsssrt",
    ".1rssrrt",
    ".1rsrrrt",
    ".1rrrrrt",
    "..11.11.",
]), {(13, 8): "t", (14, 8): "9", (13, 9): "9", (14, 9): "t", (12, 9): "s", (15, 8): "t"}), "mage")

S["brute"] = grid(sym([
    "........",
    "........",
    "....1111",
    "...15666",
    "...15j66",
    "..115555",
    ".1557655",
    "15677654",
    "16776544",
    "16765444",
    "16651444",
    "15561444",
    "16651144",
    "17651.14",
    "1551..14",
    ".11...11",
]), "brute")

S["chest"] = grid(patch(pad(sym([
    "..111111",
    ".1uvvvvv",
    ".1vwwwww",
    ".1uvvvvv",
    ".1445555",
    ".1uuuu1g",
    ".1vvvv1h",
    ".1vvvvv1",
    ".1uvvvvv",
    ".1445555",
    ".1uuuuuu",
    "..111111",
]), 16), {(8, 10): "g"}), "chest")
S["chest_open"] = grid(sym([
    "........",
    "..111111",
    ".1uvvvvv",
    ".1445555",
    ".1vwwwww",
    ".1uuuuuu",
    ".1111111",
    ".1000hg0",
    ".10gh000",
    ".1445555",
    ".1uvvvvv",
    ".1vvvvvv",
    ".1uvvvvv",
    ".1445555",
    ".1uuuuuu",
    "..111111",
]), "chest_open")

_brazier_base = sym([
    "..155555",
    "...15666",
    "....1444",
    "......14",
    "......14",
    "......14",
    ".....144",
    "....1111",
])
S["brazier_a"] = grid([
    "................",
    ".......e........",
    "......ef..e.....",
    ".....efge.fe....",
    "....efggfefge...",
    "....fghhgggfe...",
    "...efghhhhgfe...",
    "..1fghhhhhhgf1..",
] + _brazier_base, "brazier_a")
S["brazier_b"] = grid([
    "................",
    "........e.......",
    ".....e..fe......",
    "....ef.efge.....",
    "....efgfggfe....",
    "...efghhggfe....",
    "...efghhhhgfe...",
    "..1fghhhhhhgf1..",
] + _brazier_base, "brazier_b")

S["soul"] = grid([
    "...e...",
    "..eg...",
    "..ghe..",
    ".ghhhg.",
    ".ghhhg.",
    "..ggg..",
], "soul")

_orb = ["...s", "..st", ".st9", "st99"]
S["frost_orb"] = grid(sym(_orb + _orb[::-1]), "frost_orb")

S["sword"] = grid([
    "...........9",
    "..........97",
    ".........97.",
    "........97..",
    ".......97...",
    "......97....",
    "...g.97.....",
    "....g7......",
    "...v.g......",
    "..v.........",
    ".v..........",
    "g...........",
], "sword")

S["skull"] = grid([
    ".888.",
    "80808",
    "88888",
    ".8.8.",
], "skull")
S["bones"] = grid([
    "7.....7",
    ".88888.",
    "7.....7",
], "bones")
S["rubble"] = grid([
    ".45..",
    "4554.",
    ".44.5",
], "rubble")

# --- upgrade glyphs (cards)
S["g_lifesteal"] = grid(patch(pad(sym([
    ".......i",
    ".......j",
    "......ij",
    "......jj",
    ".....ijj",
    "....ijjj",
    "....ijjj",
    "...ijjjj",
    "...ijjjj",
    "...ijjjj",
    "...iijjj",
    "....iijj",
    ".....iii",
]), 15), {(5, 6): "k", (5, 7): "k", (4, 8): "k", (4, 9): "k", (6, 4): "k"}) + ["." * 16], "g_lifesteal")
S["g_dash"] = grid([
    "................",
    "................",
    "................",
    "................",
    "........ggg.....",
    "..ddeeeegghh....",
    "........ghhhg...",
    ".ddeeefffghhhhg.",
    "........ghhhg...",
    "..ddeeeegghh....",
    "........ggg.....",
    "................",
    "................",
    "................",
    "................",
    "................",
], "g_dash")
S["g_glass"] = grid(patch(pad(sym([
    "......11",
    "....1144",
    "...14tt5",
    "..14t995",
    "..1t9955",
    ".14t9555",
    ".1t95554",
    ".1t55ef4",
    ".145efgf",
    "..14efgh",
    "..1145ff",
    "...11444",
    ".....111",
]), 16), {(9, 5): "1", (10, 6): "1", (10, 7): "1", (11, 8): "1", (9, 4): "1"}), "g_glass")

# ------------------------------------------------------------- the crown ---
def eclipse(w: int, h: int, cx: float, cy: float, r: float,
            spikes=((-60, 2), (-30, 3), (0, 4), (30, 3), (60, 2)),
            base_w: float = 1.6, glow: bool = True) -> list[str]:
    """The Sunless Crown: a dead sun whose corona rises into crown points."""
    import math
    out = [["."] * w for _ in range(h)]
    ring = r + 1.15
    tris = []
    for ang, ln in spikes:
        a = math.radians(ang - 90)
        ux, uy = math.cos(a), math.sin(a)
        px, py = -uy, ux
        bx, by = cx + ux * (ring - 0.3), cy + uy * (ring - 0.3)
        tip = (cx + ux * (ring + ln), cy + uy * (ring + ln))
        tris.append(((bx + px * base_w, by + py * base_w), (bx - px * base_w, by - py * base_w), tip))

    def inside(p, t):
        (x1, y1), (x2, y2), (x3, y3) = t
        x, y = p
        d1 = (x - x2) * (y1 - y2) - (x1 - x2) * (y - y2)
        d2 = (x - x3) * (y2 - y3) - (x2 - x3) * (y - y3)
        d3 = (x - x1) * (y3 - y1) - (x3 - x1) * (y - y1)
        neg = d1 < 0 or d2 < 0 or d3 < 0
        pos = d1 > 0 or d2 > 0 or d3 > 0
        return not (neg and pos)

    for y in range(h):
        for x in range(w):
            p = (x + 0.5, y + 0.5)
            d = math.hypot(p[0] - cx, p[1] - cy)
            if d < r:
                out[y][x] = "0"
            elif d < ring:
                upper_left = (p[0] - cx) + (p[1] - cy) < -r * 0.4
                out[y][x] = "h" if upper_left else "g"
            elif any(inside(p, t) for t in tris):
                out[y][x] = "g"
            elif glow and d < ring + 1.3 and (x + y) % 2 == 0:
                out[y][x] = "e"
    # bright spike tips
    for ang, ln in spikes:
        a = math.radians(ang - 90)
        tx, ty = cx + math.cos(a) * (ring + ln - 0.6), cy + math.sin(a) * (ring + ln - 0.6)
        ix, iy = int(tx), int(ty)
        if 0 <= ix < w and 0 <= iy < h and out[iy][ix] == "g":
            out[iy][ix] = "h"
    return ["".join(r_) for r_ in out]


def under(top: list[str], base: list[str]) -> list[str]:
    """Lay `top` over `base` (same size)."""
    return ["".join(t if t != "." else b for t, b in zip(rt, rb)) for rt, rb in zip(top, base)]


_vorlak_body = ["." * 32] * 8 + sym([
    "..............11",
    ".............178",
    "............1788",
    "............10k8",
    "............1078",
    "............1788",
    ".............177",
    "..............17",
    ".........1iiii1g",
    "........1iijjj14",
    ".......1iijjjj15",
    ".......1ijjjjj15",
    "......1iijjjjj15",
    "......1ijjjjj188",
    ".....1iijjjjj178",
    ".....1ijjjjj1ggg",
    ".....1ijjjjj1445",
    "....1iijjjjj1445",
    "....1ijjjjji1445",
    "....1ijjjjii1435",
    "...1iijjjiii1435",
    "...1ijjjjiii1435",
    "...1ijjjiiii1235",
    "..1iijjjiiii1235",
    "..1ijjjiiiii1235",
    "..1ijjiiiiii1235",
    ".1iijjiiiii11235",
    ".1ijjiiiiii1.125",
    ".1ijiiiiiii1.125",
    "1iiiiiiiii1...15",
    "11111111111....1",
    "................",
])
S["vorlak"] = grid(under(_vorlak_body, eclipse(32, 40, 16, 11.5, 5.3)), "vorlak")
S["mark32"] = grid(eclipse(32, 32, 16, 19.5, 6.6,
                           spikes=((-70, 4), (-35, 6), (0, 8.5), (35, 6), (70, 4)), base_w=2.5), "mark32")
S["mark16"] = grid(patch(sym([
    "........",
    ".......h",
    "..h....g",
    "..g....g",
    "...g...g",
    "...ggggg",
    "..gh0000",
    "..g00000",
    "..g00000",
    "..g00000",
    "..g00000",
    "...g0000",
    "....gggg",
    "........",
    "........",
    "........",
]), {(13, 2): "g", (13, 6): "g"}), "mark16")

# ------------------------------------------------------------------ tiles ---
T: dict[str, list[str]] = {}
# Tiles: a digit is a shade shifted by light; 'x' is always void; letters are literal.
_fa = [
    "3333333330333333",
    "2222222210222222",
    "2222222210222222",
    "2222222210222222",
    "0000000000000000",
    "3330333333333033",
    "2210222222222102",
    "2210222222222102",
    "2210222222222102",
    "0000000000000000",
    "3333333033333333",
    "2222221022222222",
    "2222221022222222",
    "2222221022222222",
    "2222221022222222",
    "0000000000000000",
]
T["floor_a"] = grid(_fa, "floor_a")
_fb = [list(r) for r in _fa]
for y in range(5, 9):          # one darker, sunken stone
    for x in range(4, 12):
        _fb[y][x] = {"3": "2", "2": "1"}.get(_fb[y][x], _fb[y][x])
T["floor_b"] = grid(patch(["".join(r) for r in _fb],
                          {(2, 1): "1", (3, 2): "1", (3, 3): "1", (11, 12): "1", (12, 13): "1", (12, 14): "1"}), "floor_b")
T["floor_c"] = grid(patch(_fa, {(12, 1): "1", (13, 1): "1", (12, 2): "1", (6, 7): "1", (2, 12): "1",
                                (3, 12): "1", (10, 11): "3", (14, 13): "1"}), "floor_c")
T["wall_face"] = grid([
    "3333333333333333",
    "2222222222222222",
    "1111111111111111",
    "3333333033333330",
    "2222222022222220",
    "2222222022222220",
    "1111111011111110",
    "0000000000000000",
    "3330333333303333",
    "2220222222202222",
    "2220222222202222",
    "1110111111101111",
    "0000000000000000",
    "3333333033333330",
    "2222222022222220",
    "0000000000000000",
], "wall_face")
T["wall_top"] = ["x" * 16] * 16
T["stairs"] = grid([
    "1111111111111111",
    "1333333333333331",
    "1222222222222221",
    "1111111111111111",
    "1122222222222211",
    "1111111111111111",
    "11000000000000 1".replace(" ", "1"),
    "1101111111111011",
    "1100000000000011",
    "1100000000000011",
    "1000000000000001",
    "1000000dd0000001",
    "100000deed000001",
    "1000000dd0000001",
    "1000000000000001",
    "1111111111111111",
], "stairs")

OUT = Path(__file__).with_name("out")
