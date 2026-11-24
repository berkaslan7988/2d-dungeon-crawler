"""Export the art kit into the Godot project.

    python tools/art/build.py

Writes PNGs, SpriteFrames and the TileSet under assets/. Pixels drawn with an
emissive key get alpha 240, so the lit sprite shader leaves them bright in the
dark. Tile pixels that are shades are stored as (shade*32+16, 0, 0, 200); the
lit tile shader turns them into colours from the stone ramp.
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image

import art
import cast
import scene

ROOT = Path(__file__).resolve().parents[2]
A = ROOT / "assets"
EMIT_ALPHA = 240
SHADE_ALPHA = 200


def img(rows: list[str], emit: set[str] = frozenset()) -> Image.Image:
    h, w = len(rows), len(rows[0])
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = im.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch != ".":
                px[x, y] = art.RGB[ch] + (EMIT_ALPHA if ch in emit else 255,)
    return im


def save(im: Image.Image, rel: str) -> str:
    p = A / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    im.save(p)
    return "res://assets/" + rel


def sheet(anims: dict[str, list[list[str]]], emit) -> tuple[Image.Image, int, int, list[str]]:
    names = list(anims)
    fw = max(len(f[0]) for a in anims.values() for f in a)
    fh = max(len(f) for a in anims.values() for f in a)
    cols = max(len(a) for a in anims.values())
    im = Image.new("RGBA", (fw * cols, fh * len(names)), (0, 0, 0, 0))
    for r, n in enumerate(names):
        for c, f in enumerate(anims[n]):
            fi = img(f, emit)
            # bottom-centre each frame in its cell
            im.paste(fi, (c * fw + (fw - fi.width) // 2, r * fh + (fh - fi.height)), fi)
    return im, fw, fh, names


def frames_tres(tex_path: str, anims: dict[str, list], fw: int, fh: int, speeds: dict[str, float]) -> str:
    subs, blocks = [], []
    k = 0
    for r, (name, frames) in enumerate(anims.items()):
        refs = []
        for c in range(len(frames)):
            sid = f"a{k}"
            k += 1
            subs.append(f'[sub_resource type="AtlasTexture" id="{sid}"]\natlas = ExtResource("1")\n'
                        f"region = Rect2({c * fw}, {r * fh}, {fw}, {fh})\n")
            refs.append('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % sid)
        blocks.append('{\n"frames": [%s],\n"loop": true,\n"name": &"%s",\n"speed": %.1f\n}'
                      % (", ".join(refs), name, speeds.get(name, 5.0)))
    head = f'[gd_resource type="SpriteFrames" load_steps={k + 2} format=3]\n\n' \
           f'[ext_resource type="Texture2D" path="{tex_path}" id="1"]\n\n'
    return head + "\n".join(subs) + "\n[resource]\nanimations = [" + ", ".join(blocks) + "]\n"


def write(rel: str, text: str) -> None:
    p = A / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text, encoding="utf-8", newline="\n")


def animated(name: str, anims, folder: str, emit_key: str, speeds) -> None:
    im, fw, fh, _ = sheet(anims, cast.EMIT.get(emit_key, set()))
    tex = save(im, f"{folder}/{name}.png")
    write(f"{folder}/{name}_frames.tres", frames_tres(tex, anims, fw, fh, speeds))


# ------------------------------------------------------------------- tiles ---
def tile_img(rows: list[str], ramp_row: int = 0) -> Image.Image:
    """Green 0 = stone ramp (floors, faces), green 255 = wall-top ramp."""
    im = Image.new("RGBA", (16, 16))
    px = im.load()
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch == "x":
                px[x, y] = art.RGB["0"] + (255,)
            elif ch.isdigit():
                px[x, y] = (int(ch) * 32 + 16, 255 if ramp_row else 0, 0, SHADE_ALPHA)
            else:
                px[x, y] = art.RGB[ch] + (EMIT_ALPHA,)
    return im


## The flat top of a wall: dark cool stone with a few chips, on its own
## ramp so it never turns warm like the floor, and a two-pixel lit lip on
## every side that borders floor. It has to read as solid mass against both
## the floor and the black of unexplored space.
WALL_CAP = [
    "1111111111111111",
    "1121111111111211",
    "1111111111111111",
    "1111110111111111",
    "1111111111211111",
    "1211111111111111",
    "1111111101111111",
    "1111111111111121",
    "1111211111111111",
    "1111111111110111",
    "1101111111111111",
    "1111111121111111",
    "1111111111111111",
    "1111121111111111",
    "1111111111111101",
    "1111111111111111",
]
TOP_RAMP = ["0", "1", "2", "3", "4", "5", "6", "7"]


def wall_top(mask: int) -> list[str]:
    g = [list(r) for r in WALL_CAP]
    for i in range(16):
        if mask & 1:
            g[0][i] = "4"
            g[1][i] = "3"
        if mask & 2:
            g[i][15] = "4"
            g[i][14] = "3" if g[i][14] != "4" else "4"
        if mask & 4:
            g[i][0] = "4"
            g[i][1] = "3" if g[i][1] != "4" else "4"
    return ["".join(r) for r in g]


def wall_face(mask: int) -> list[str]:
    g = [list(r) for r in art.T["wall_face"]]
    for y in range(16):
        if mask & 1:
            g[y][15] = "1"
        if mask & 2:
            g[y][0] = "3"
    return ["".join(r) for r in g]


FLOOR_D = art.patch(art.T["floor_a"], {(3, 2): "1", (4, 2): "1", (9, 6): "1", (10, 7): "1",
                                        (11, 7): "1", (5, 12): "3", (13, 11): "1"})


def tiles() -> None:
    atlas = Image.new("RGBA", (16 * 8, 16 * 3), (0, 0, 0, 0))
    row0 = [art.T["floor_a"], art.T["floor_b"], art.T["floor_c"], FLOOR_D, art.T["stairs"]]
    for i, t in enumerate(row0):
        atlas.paste(tile_img(t), (i * 16, 0))
    for m in range(8):
        atlas.paste(tile_img(wall_top(m), 1), (m * 16, 16))
    for m in range(4):
        atlas.paste(tile_img(wall_face(m)), (m * 16, 32))
    save(atlas, "tilesets/dungeon_tiles.png")
    ramp = Image.new("RGBA", (8, 2))
    for i, k in enumerate(art.STONE):
        ramp.putpixel((i, 0), art.RGB[k] + (255,))
    for i, k in enumerate(TOP_RAMP):
        ramp.putpixel((i, 1), art.RGB[k] + (255,))
    save(ramp, "tilesets/ramp_stone.png")
    poly = "PackedVector2Array(-8, -8, 8, -8, 8, 8, -8, 8)"
    lines = ['[gd_resource type="TileSet" load_steps=3 format=3]', "",
             '[ext_resource type="Texture2D" path="res://assets/tilesets/dungeon_tiles.png" id="1"]', "",
             '[sub_resource type="TileSetAtlasSource" id="1"]', 'texture = ExtResource("1")',
             "texture_region_size = Vector2i(16, 16)"]
    for x in range(5):
        lines.append(f"{x}:0/0 = 0")
    for y, n in ((1, 8), (2, 4)):
        for x in range(n):
            lines.append(f"{x}:{y}/0 = 0")
            lines.append(f"{x}:{y}/0/physics_layer_0/polygon_0/points = {poly}")
    lines += ["", "[resource]", "physics_layer_0/collision_layer = 1",
              "physics_layer_0/collision_mask = 0", 'sources/0 = SubResource("1")', ""]
    write("tilesets/dungeon_tileset.tres", "\n".join(lines))


# --------------------------------------------------------------------- run ---
def main() -> None:
    animated("player", cast.PLAYER_ANIMS, "sprites", "player",
             {k: (4.0 if k.startswith("idle") else 8.0) for k in cast.PLAYER_ANIMS})
    for name, anims in cast.ENEMY_ANIMS.items():
        animated(name, anims, "sprites/enemies", name, {"idle": 3.0, "walk": 6.0})
    for name, anims in cast.WARDEN_ANIMS.items():
        animated(name, anims, "sprites/wardens", name, {"idle": 2.0, "walk": 4.0})
    animated("brazier", {"burn": [art.S["brazier_a"], art.S["brazier_b"]]}, "sprites/props", "brazier", {"burn": 6.0})
    animated("slash", {"swing": cast.SLASH}, "sprites/fx", "slash", {"swing": 24.0})
    animated("spark", {"pop": cast.SPARK}, "sprites/fx", "spark", {"pop": 18.0})
    for n in ("chest", "chest_open", "skull", "bones", "rubble", "dummy"):
        save(img(art.S[n]), f"sprites/props/{n}.png")
    save(img(art.S["frost_orb"], cast.EMIT["frost_orb"]), "sprites/fx/frost_orb.png")
    save(img(art.S["soul"], cast.EMIT["soul"]), "sprites/fx/soul.png")
    for n, rows in cast.ICONS.items():
        emit = set("efgh") if n == "flame_blade" else set()
        save(img(rows, emit), f"sprites/items/{n}.png")
    for n, rows in cast.GLYPHS.items():
        save(img(rows), f"sprites/glyphs/{n}.png")
    tiles()
    # UI pieces
    save(img(art.S["mark32"]), "ui/mark32.png")
    save(img(art.S["mark16"]), "ui/mark16.png")
    save(img(art.S["soul"]), "ui/soul.png")
    save(img(["..e...", "..fe..", ".efg..", ".fggf.", "efghgf", "fghhgf", "fghhgf", ".fggf."]), "ui/ember.png")
    scene.title_scene(A / "ui" / "title_bg.png")
    # app icon: the mark on the void, 8× nearest
    icon = Image.new("RGBA", (32, 32), art.RGB["0"] + (255,))
    m = img(art.S["mark32"])
    icon.paste(m, (0, -2), m)
    icon.resize((256, 256), Image.NEAREST).save(ROOT / "icon.png")
    docs_images()
    print("art exported to", A)


def docs_images() -> None:
    """Pictures for the README: the mark, the palette, the light ramp, the cast."""
    d = ROOT / "docs"
    d.mkdir(exist_ok=True)
    m = img(art.S["mark32"])
    m.resize((128, 128), Image.NEAREST).save(d / "mark.png")
    keys = list(art.PAL)
    pal = Image.new("RGBA", (len(keys) * 6, 6))
    for i, k in enumerate(keys):
        pal.paste(art.RGB[k] + (255,), (i * 6, 0, i * 6 + 6, 6))
    pal.resize((pal.width * 4, pal.height * 4), Image.NEAREST).save(d / "palette.png")
    scene.ramp_strip(d / "ramp.png")
    r = Image.open(d / "ramp.png")
    r.resize((r.width * 5, r.height * 5), Image.NEAREST).save(d / "ramp.png")
    names = ["player_a", "slime_a", "splitter", "bat_a", "mage", "brute", "garoth", "myrra", "vorlak"]
    sprites = [img(art.S[n]) for n in names]
    w = sum(s.width for s in sprites) + 6 * (len(sprites) + 1)
    h = max(s.height for s in sprites) + 12
    cast_im = Image.new("RGBA", (w, h), art.RGB["0"] + (255,))
    x = 6
    for s in sprites:
        cast_im.paste(s, (x, h - 6 - s.height), s)
        x += s.width + 6
    cast_im.resize((w * 4, h * 4), Image.NEAREST).save(d / "cast.png")


if __name__ == "__main__":
    main()
