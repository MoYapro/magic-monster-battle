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
            "troll", "treant"]
BG = "#1b120d"
CELL, TILE = 300, 128


def render(monster):
    subprocess.run([sys.executable, str(HERE / f"{monster}.py")], cwd=HERE, check=True)


def grid_cells(png):
    """1 for a 512x512 monster, 2 for a 512x1024 (1x2 tile) monster."""
    height = subprocess.run(["magick", "identify", "-format", "%h", png], capture_output=True,
                            text=True, check=True).stdout.strip()
    return 2 if height == "1024" else 1


def card(monster, out):
    """A label, the big version and the tile-size version, stacked on a fixed-height card."""
    png = str(OUT / f"{monster}.png")
    cells = grid_cells(png)
    subprocess.run([
        "magick",
        "(", png, "-resize", f"{CELL}x{CELL * cells}", "-background", BG, "-gravity", "south",
        "-extent", f"{CELL}x{CELL * 2}", ")",
        "(", png, "-resize", f"{TILE}x{TILE * cells}", "-background", BG, "-gravity", "south",
        "-extent", f"{CELL}x{TILE * 2 + 16}", ")",
        "-append", "-background", BG, "-fill", "#e8d3a8", "-font", "DejaVu-Serif", "-pointsize", "22",
        "-gravity", "north", "-splice", "0x40", "-annotate", "+0+8", monster.replace("_", " "),
        "-bordercolor", "#0b0705", "-border", "5", str(out),
    ], check=True)


def main():
    OUT.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        cards = []
        for i, monster in enumerate(MONSTERS):
            render(monster)
            cards.append(str(Path(tmp) / f"{i:02d}.png"))
            card(monster, cards[-1])
        subprocess.run(["magick", "montage", *cards, "-tile", "4x2", "-geometry", "+0+0",
                        "-background", "#0b0705", str(OUT / "00_all_monsters.png")], check=True)


if __name__ == "__main__":
    main()
