"""Render every linocut monster into the monsters folder and rebuild 00_all_monsters.png.

Usage: python3 build.py
Each monster script writes ../<id>.svg and ../<id>.png. The overview shows each monster
at 300 px per grid cell and at 128 px per grid cell (tile size) on the dark UI colour.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
OUT = HERE.parent
MONSTERS = ["skeleton", "banshee", "goblin", "cave_spider", "shadow_panther", "fire_elemental",
            "troll", "treant", "bog_shambler", "bone_caller", "cursed_knight", "fallen_paladin",
            "frost_mage", "grove_tender", "scorpion", "shield_ogre", "stone_giant", "war_drummer",
            "witch", "wraith_blade", "cat", "flying_cat", "unicorn", "sleeping_unicorn"]
BG = "#1b120d"
CELL, TILE = 300, 128


def render(monster):
    subprocess.run([sys.executable, str(HERE / f"{monster}.py")], cwd=HERE, check=True)


def grid_cells(png):
    """Grid size (cols, rows) from the canvas: 512 px per cell."""
    size = subprocess.run(["magick", "identify", "-format", "%w %h", png], capture_output=True,
                          text=True, check=True).stdout.split()
    return int(size[0]) // 512, int(size[1]) // 512


def card(monster, out):
    """A label, the big version and the tile-size version, stacked on a fixed-height card."""
    png = str(OUT / f"{monster}.png")
    cols, rows = grid_cells(png)
    big = CELL // cols  # wide monsters are scaled down to fit the card width
    subprocess.run([
        "magick",
        "(", png, "-resize", f"{big * cols}x{big * rows}", "-background", BG, "-gravity", "south",
        "-extent", f"{CELL}x{CELL * 2}", ")",
        "(", png, "-resize", f"{TILE * cols}x{TILE * rows}", "-background", BG, "-gravity", "south",
        "-extent", f"{CELL}x{TILE * 2 + 16}", ")",
        "-append", "-background", BG, "-fill", "#e8d3a8", "-font", "DejaVu-Serif", "-pointsize", "22",
        "-gravity", "north", "-splice", "0x40", "-annotate", "+0+8", monster.replace("_", " "),
        "-bordercolor", "#0b0705", "-border", "5", str(out),
    ], check=True)


SCREEN_W, SCREEN_H = 5120, 2160
SCREEN_CELL = 430   # px per grid cell on the screen-sized overview, the same for every monster
LABEL_H = 56


def screen_slot(monster, width, out):
    """One monster at SCREEN_CELL px per grid cell, standing on its name at the bottom of a slot."""
    png = str(OUT / f"{monster}.png")
    cols, rows = grid_cells(png)
    subprocess.run([
        "magick", png, "-resize", f"{SCREEN_CELL * cols}x{SCREEN_CELL * rows}",
        "-background", BG, "-gravity", "south", "-extent", f"{width}x{SCREEN_H // 2 - LABEL_H}",
        "-fill", "#e8d3a8", "-font", "DejaVu-Serif", "-pointsize", "30",
        "-gravity", "south", "-splice", f"0x{LABEL_H}", "-annotate", "+0+10", monster.replace("_", " "),
        str(out),
    ], check=True)


def screen_rows():
    """Two rows that each fill the screen width: small monsters on top, the big ones below."""
    wide = [m for m in MONSTERS if grid_cells(str(OUT / f"{m}.png"))[0] > 1]
    rest = [m for m in MONSTERS if m not in wide]
    half = (len(rest) + 2 * len(wide) + 1) // 2
    top, bottom = rest[:half], rest[half:] + wide
    return top, bottom


def screen_overview(tmp):
    """All monsters at the same scale on one 5120x2160 image (the size of the main monitor)."""
    rows = []
    for r, row in enumerate(screen_rows()):
        units = sum(grid_cells(str(OUT / f"{m}.png"))[0] for m in row)
        slots = []
        for i, monster in enumerate(row):
            width = SCREEN_W * grid_cells(str(OUT / f"{monster}.png"))[0] // units
            slots.append(str(Path(tmp) / f"s{r}_{i:02d}.png"))
            screen_slot(monster, width, slots[-1])
        rows.append(str(Path(tmp) / f"row{r}.png"))
        subprocess.run(["magick", *slots, "+append", "-background", BG, "-gravity", "center",
                        "-extent", f"{SCREEN_W}x{SCREEN_H // 2}", rows[-1]], check=True)
    subprocess.run(["magick", *rows, "-append", "+repage", str(OUT / f"00_all_monsters_{SCREEN_W}x{SCREEN_H}.png")],
                   check=True)


def main():
    OUT.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        cards = []
        for i, monster in enumerate(MONSTERS):
            render(monster)
            cards.append(str(Path(tmp) / f"{i:02d}.png"))
            card(monster, cards[-1])
        subprocess.run(["magick", "montage", *cards, "-tile", "6x4", "-geometry", "+0+0",
                        "-background", "#0b0705", str(OUT / "00_all_monsters.png")], check=True)
        screen_overview(tmp)


if __name__ == "__main__":
    main()
