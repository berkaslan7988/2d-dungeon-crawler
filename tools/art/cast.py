"""The rest of the cast: animation frames, Wardens, item icons, boon glyphs, FX.

Everything here builds on art.py (palette, grid helpers, the first sprites).
"""
from __future__ import annotations

import math

import art
from art import S, grid, pad, patch, recolor, sym

# ------------------------------------------------------------------ helpers ---


def bob(rows: list[str]) -> list[str]:
    """Shift everything but the last row down by one pixel (a walk bob)."""
    w = len(rows[0])
    return ["." * w] + rows[:-2] + [rows[-1]]


def replace_rows(rows: list[str], start: int, new: list[str]) -> list[str]:
    out = list(rows)
    out[start:start + len(new)] = new
    return out


def blank(w: int, h: int) -> list[list[str]]:
    return [["."] * w for _ in range(h)]


def join(g: list[list[str]]) -> list[str]:
    return ["".join(r) for r in g]


def put(g, x, y, ch):
    if 0 <= y < len(g) and 0 <= x < len(g[0]):
        g[y][x] = ch


# ------------------------------------------------------------------ player ---
FLAME_A = art.S["player_a"][:5]
FLAME_B = art.S["player_b"][:5]
_front = art.S["player_a"][5:]                  # rows 5..15
_head_front = _front[:4]
_head_back = [r.replace("0", "h") for r in _head_front]
_head_side = ["....fghhhhgf....", "....ghhh0h0g....", "....fghhhhgf....", ".....efggfe....."]
_body_front = _front[4:10]
_body_back = [r.replace("d", "5").replace("3", "4") for r in _body_front]
_body_back[0] = "....1cw55wc1...."
FEET = {
    "idle": "....111..111....",
    "l": "...111....111...",
    "r": ".....111.111....",
}


def player_frame(view: str, flame: list[str], feet: str, bobbed=False) -> list[str]:
    head = {"down": _head_front, "up": _head_back, "side": _head_side}[view]
    body = {"down": _body_front, "up": _body_back, "side": _body_front}[view]
    rows = flame + head + body + [FEET[feet]]
    return grid(bob(rows) if bobbed else rows, f"player_{view}")


PLAYER_ANIMS: dict[str, list[list[str]]] = {}
for view in ("down", "up", "side"):
    PLAYER_ANIMS[f"idle_{view}"] = [player_frame(view, FLAME_A, "idle"), player_frame(view, FLAME_B, "idle")]
    PLAYER_ANIMS[f"walk_{view}"] = [player_frame(view, FLAME_A, "l"), player_frame(view, FLAME_B, "idle", True),
                                    player_frame(view, FLAME_A, "r"), player_frame(view, FLAME_B, "idle", True)]

# ----------------------------------------------------------------- enemies ---
S["dummy"] = grid(patch(sym([
    "........",
    "........",
    "......11",
    ".....1ww",
    ".....1w1",
    ".....1ww",
    "......1v",
    "..1111vv",
    "..1wwwww",
    "...11wjj",
    "....1wjk",
    "....1wjj",
    "....1www",
    ".....11v",
    "......1v",
    ".....111",
]), {(9, 4): "w", (6, 4): "1"}), "dummy")

_mage = S["mage"]
_mage_dim = recolor(_mage[:], {})
_mage_dim = patch(_mage, {(14, 8): "t", (13, 9): "t"})
_mage_walk = replace_rows(_mage, 15, ["...11.11.11.11.."])

_splitter_b = patch(recolor(S["slime_b"], {"l": "r", "m": "s", "n": "t"}),
                    {(7, 10): "1", (8, 11): "1", (7, 12): "1", (8, 13): "1"})
_mini_b = grid(pad(sym([
    ".llmn",
    "lmn99",
    "lmmmm",
    "lm0mm",
    "lllmm",
    ".llll",
]), 8), "mini_b")

ENEMY_ANIMS = {
    "slime": {"idle": [S["slime_a"], S["slime_b"]], "walk": [S["slime_a"], S["slime_b"]]},
    "mini_slime": {"idle": [S["mini_slime"], _mini_b], "walk": [S["mini_slime"], _mini_b]},
    "splitter": {"idle": [S["splitter"], _splitter_b], "walk": [S["splitter"], _splitter_b]},
    "bat": {"idle": [S["bat_a"], S["bat_b"]], "walk": [S["bat_a"], S["bat_b"]]},
    "mage": {"idle": [_mage, _mage_dim], "walk": [_mage, _mage_walk]},
    "brute": {"idle": [S["brute"], bob(S["brute"])], "walk": [S["brute"], bob(S["brute"])]},
    "dummy": {"idle": [S["dummy"]], "walk": [S["dummy"]]},
}

# ----------------------------------------------------------------- wardens ---
S["garoth"] = grid(sym([
    "................",
    "................",
    "................",
    "................",
    "................",
    "................",
    "...........11111",
    "..........156666",
    "..........167777",
    "..........166666",
    "..........11nnnn",
    "..........155555",
    "..........145555",
    "....111111114444",
    "...1566666651444",
    "..15677666651544",
    "..1566l66mm51554",
    "..156lmm66651155",
    "..1556m665515555",
    "...1155551155665",
    "....1566l1556766",
    "....156611556666",
    "....156m11555666",
    "....156611555566",
    "....155611455556",
    "...1566611445555",
    "...1677661144444",
    "...1566661uuuuug",
    "....11111.144455",
    "....6......14455",
    "....7......14455",
    "...6.......14455",
    "....7......15445",
    "....6......1544.",
    "...7.......1544.",
    "...........1544.",
    "..........15544.",
    "..........15554.",
    "..........11111.",
    "................",
]), "garoth")

S["myrra"] = grid(patch(sym([
    "................",
    "................",
    "................",
    "...............q",
    "..........q.....",
    "................",
    ".............111",
    "............1ooo",
    "...........1oppp",
    "..........1oppqq",
    "..........1op000",
    "..........1o0q00",
    "..........1op000",
    "..........1oop00",
    "..........1ooppp",
    ".........1ooopp1",
    "........1ooopp11",
    ".......1ooopp1o8",
    "......1oooppo1o8",
    "......1ooppoo188",
    ".....1oooppoo1o8",
    ".....1ooppooo1oo",
    ".....1oppooooo1o",
    "....1ooppooooo1o",
    "....1oppoooooo1o",
    "....1oppooooo1oo",
    "...1ooppooooo1oo",
    "...1oppoooooo1oo",
    "...1oppooooo1ooo",
    "..1ooppooooo1ooo",
    "..1oppoooooo1ooo",
    "..1opooooooo1ooo",
    ".1oopooooooo1ooo",
    ".1opooooooo1oooo",
    ".1ooooooooo1oooo",
    "1oo.oooo.ooo1o.o",
    "1o...oo...oo1..o",
    "1.....o....o....",
    "................",
    "................",
]), {}), "myrra")

WARDEN_ANIMS = {
    name: {"idle": [S[name], bob(S[name])], "walk": [S[name], bob(S[name])]}
    for name in ("garoth", "myrra", "vorlak")
}

# --------------------------------------------------------------- item icons ---


def diagonal_weapon(blade_len: int, blade_w: int, light: str, body: str, dark: str,
                    guard: str, grip: str, pommel: str, emissive=False) -> list[str]:
    """A weapon lying bottom-left → top-right on a 16×16 icon."""
    g = blank(16, 16)
    hx, hy = 4, 11                                  # where blade meets guard
    for t in range(1, blade_len + 1):
        x, y = hx + t, hy - t
        put(g, x, y, body)
        put(g, x - 1, y, light)                     # upper-left edge catches light
        if blade_w >= 2:
            put(g, x, y + 1, dark)
        if blade_w >= 3:
            put(g, x + 1, y + 1, dark)
            put(g, x, y + 1, body)
    tip_x, tip_y = hx + blade_len + 1, hy - blade_len - 1
    put(g, tip_x, tip_y, light)
    for dx, dy in ((-1, -1), (1, 1), (-2, -2), (2, 2)):
        put(g, hx + dx, hy + dy, guard)
    put(g, hx, hy, guard)
    for t in range(1, 3):
        put(g, hx - t, hy + t, grip)
    put(g, hx - 3, hy + 3, pommel)
    return grid(join(g), "weapon")


ICONS: dict[str, list[str]] = {
    "rusty_sword": diagonal_weapon(7, 2, "w", "c", "b", "4", "u", "5"),
    "iron_sword": diagonal_weapon(8, 2, "8", "7", "5", "5", "v", "g"),
    "steel_dagger": diagonal_weapon(5, 2, "9", "8", "6", "6", "u", "7"),
    "broadsword": diagonal_weapon(9, 3, "9", "8", "6", "g", "v", "g"),
    "flame_blade": diagonal_weapon(9, 2, "h", "g", "f", "e", "u", "g"),
}
_hammer = [list(r) for r in diagonal_weapon(0, 1, "v", "v", "v", "v", "v", "u")]
for t in range(0, 9):
    put(_hammer, 4 + t, 11 - t, "v")
    put(_hammer, 3 + t, 11 - t, "u") if t % 3 == 0 else None
for y in range(1, 7):
    for x in range(9, 15):
        d = abs(x - 11.5) + abs(y - 3.5)
        if d < 4.2:
            put(_hammer, x, y, "6" if (x + y) % 5 else "7")
for x, y in ((9, 2), (10, 1), (13, 6), (14, 5)):
    put(_hammer, x, y, "5")
put(_hammer, 10, 2, "8"); put(_hammer, 11, 2, "8")
ICONS["war_hammer"] = grid(join(_hammer), "war_hammer")

_TUNIC = [
    "................",
    "................",
    "....AA....AA....",
    "...ABBA..ABBA...",
    "..ABBBBAABBBBA..",
    "..ABCBBBBBBCBA..",
    "..ABBBBTTBBBBA..",
    "...ABBBTTBBBA...",
    "....ABBTTBBA....",
    "....ABBBBBBA....",
    "....ACBBBBCA....",
    "....ABBBBBBA....",
    "....ATTTTTTA....",
    "....ABBBBBBA....",
    ".....AAAAAA.....",
    "................",
]
_CAP = [
    "................", "................", "................", "................",
    "......AAAA......", ".....ABCCBA.....", "....ABCBBBBA....", "....ABBBBBBA....",
    "...ABBBBBBBBA...", "...ATTTTTTTTA...", "...AAAAAAAAAA...", "....A......A....",
    "................", "................", "................", "................",
]
_HELM = [
    "................", "................", "................", "......AAAA......",
    ".....ABCCBA.....", "....ABCBBBBA....", "....ABBBBBBA....", "...ABBBBBBBBA...",
    "...AB1111111A...".replace("1", "D"), "...ABDBBBBDBA...", "...ABBBBBBBBA...", "...ABBBTTBBBA...",
    "....AAAAAAAA....", "................", "................", "................",
]
_BOOTS = [
    "................", "................", "................", "................",
    "...AAAA..AAAA...", "...ABCA..ABCA...", "...ABBA..ABBA...", "...ABBA..ABBA...",
    "...ABBA..ABBA...", "...ATTA..ATTA...", "..ABBBA.ABBBA...", ".ABBBBA.ABBBBA..",
    ".AAAAAA.AAAAAA..", "................", "................", "................",
]


def mat(shape, a, b, c, t, d="1"):
    return grid(recolor(shape, {"A": a, "B": b, "C": c, "T": t, "D": d}), "armor")


ICONS["leather_armor"] = mat(_TUNIC, "u", "v", "w", "u")
ICONS["iron_armor"] = mat(_TUNIC, "3", "5", "7", "4")
ICONS["plate_armor"] = mat(_TUNIC, "4", "6", "8", "g")
ICONS["leather_cap"] = mat(_CAP, "u", "v", "w", "u")
ICONS["iron_helm"] = mat(_HELM, "3", "5", "7", "4", "1")
ICONS["leather_boots"] = mat(_BOOTS, "u", "v", "w", "u")
ICONS["iron_greaves"] = mat(_BOOTS, "3", "5", "7", "4")

_FLASK_S = sym([
    "........", "........", "........", "......uv",
    "......vw", ".....177", "......18", ".....178",
    "....17jk", "...17jjk", "...1jjjj", "...1ijjj",
    "...1iijj", "....1iii", ".....111", "........",
])
_FLASK_L = sym([
    "........", "........", ".....uvv", ".....vww",
    "....1777", ".....178", "....1788", "...17jkk",
    "..17jjkk", "..1jjjjk", "..1jjjjj", "..1ijjjj",
    "..1iijjj", "...1iiii", "....1111", "........",
])
ICONS["health_potion"] = grid(_FLASK_S, "health_potion")
ICONS["greater_potion"] = grid(_FLASK_L, "greater_potion")
ICONS["slime_goo"] = grid(pad(sym([
    ".....lll",
    "...llmmm",
    "..lmmnn9",
    ".lmmmnnn",
    ".lmmmmmm",
    "lmmmmmmm",
    "llmmmmmm",
    ".llllmml",
    "....llll",
]), 14) + ["." * 16] * 2, "slime_goo")
ICONS["bone_fragment"] = grid([
    "................", "................", "................", "..........88....",
    ".........8998...", ".........89987..", "........8997....", ".......897......",
    "......897.......", ".....897........", "....8997........", "..78997.........",
    "...8998.........", "....87..........", "................", "................",
], "bone_fragment")

# ------------------------------------------------------------- boon glyphs ---
GLYPHS = {
    "lifesteal": S["g_lifesteal"],
    "dash": S["g_dash"],
    "glass": S["g_glass"],
}
GLYPHS["heart"] = grid(pad(sym([
    "..eee...",
    ".effge..",
    "efghhge.",
    "efghhgfe",
    "effgggfe",
    "efffffff",
    ".efffffe",
    "..eeffff",
    "...eefff",
    "....eeff",
    ".....eef",
    "......ee",
    ".......e",
]), 15) + ["." * 16], "heart")
GLYPHS["blade"] = grid(patch(pad(sym([
    ".......9",
    "......98",
    "......98",
    "......98",
    "......98",
    "......98",
    "......98",
    "......98",
    "...g..98",
    "...gggg8",
    "......vv",
    "......vu",
    "......gg",
]), 15) + ["." * 16], {(7, 2): "9", (8, 2): "7"}), "blade")
GLYPHS["wing"] = grid([
    "................",
    "................",
    "...........89...",
    ".........8899...",
    ".......88999....",
    ".....8889997....",
    "...88899977.....",
    "..8889997.......",
    ".88999777.......",
    ".8999777........",
    "..99777.........",
    "...777..........",
    "....7...........",
    "................",
    "................",
    "................",
], "wing")
GLYPHS["shield"] = grid(pad(sym([
    "..111111",
    ".1677777",
    ".1677666",
    ".1676666",
    ".16666gg",
    ".1666ghh",
    ".1666ghh",
    "..1666gg",
    "..166666",
    "...16666",
    "....1666",
    ".....166",
    "......11",
]), 15) + ["." * 16], "shield")
_tw = [list(r) for r in ["." * 16] * 16]
for t in range(10):
    put(_tw, 2 + t, 13 - t, "8"); put(_tw, 1 + t, 13 - t, "9")
    put(_tw, 13 - t, 13 - t, "7"); put(_tw, 14 - t, 13 - t, "8")
for p in ((1, 12), (3, 14), (14, 12), (12, 14)):
    put(_tw, *p, "g")
GLYPHS["twin"] = grid(join(_tw), "twin")

UPGRADE_GLYPH = {  # UpgradeData.UpgradeType → glyph
    0: "blade", 1: "glass", 2: "heart", 3: "wing", 4: "twin",
    5: "shield", 6: "lifesteal", 7: "dash", 8: "heart", 9: "wing",
}

# --------------------------------------------------------------------- fx ---


def slash_frames(n=3, size=32) -> list[list[str]]:
    frames = []
    c = size / 2
    for f in range(n):
        g = blank(size, size)
        span = math.radians(120)
        lead = -span / 2 + span * (f + 1) / n
        for y in range(size):
            for x in range(size):
                dx, dy = x + 0.5 - c, y + 0.5 - c
                d = math.hypot(dx, dy)
                if not 9 <= d <= 15.5:
                    continue
                a = math.atan2(dy, dx)
                if a > lead or a < -span / 2:
                    continue
                t = (a + span / 2) / max(lead + span / 2, 1e-3)      # 0 tail → 1 lead
                inner = 15.5 - 6.5 * t
                if d < inner:
                    continue
                if t < 0.4 and (x + y) % 2:
                    continue
                g[y][x] = "h" if d > 14.4 else ("g" if t > 0.55 else "f")
        frames.append(grid(join(g), "slash"))
    return frames


SLASH = slash_frames()
SPARK = [
    grid(["...g...", "...h...", ".g.9.g.", "gh999hg", ".g.9.g.", "...h...", "...g..."], "spark0"),
    grid([".......", "...g...", "..ghg..", ".gh9hg.", "..ghg..", "...g...", "......."], "spark1"),
]

# emissive keys per sprite set (exported with alpha 240 so the shader skips lighting)
EMIT = {
    "player": set("efgh"), "slime": set(), "mini_slime": set(), "splitter": set(),
    "bat": {"k"}, "mage": {"t", "9"}, "brute": {"j"}, "dummy": set(),
    "garoth": {"n"}, "myrra": {"q"}, "vorlak": set("ghek"),
    "brazier": set("defgh"), "soul": set("defgh"), "frost_orb": set("rst9"),
    "slash": set("fgh"), "spark": set("gh9"), "stairs": set("de"),
}
