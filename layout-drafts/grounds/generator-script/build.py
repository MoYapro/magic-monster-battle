"""Render every ground tile into the grounds folder and rebuild 00_all_grounds.png.

Usage: python3 build.py
Each ground script writes ../<id>.svg and ../<id>.png. Every tile is a fully opaque replacement
ground. The overview shows the base grounds, the state grounds and a mock-up battle grid with
monsters standing on it. The build fails if any tile has transparent pixels.
"""
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
OUT = HERE.parent
MONSTERS = OUT.parent / "monsters"
BASE_SCRIPTS = ["dirt", "grass", "sand", "stone", "snow", "mud"]
STATE_SCRIPTS = ["wet", "burning", "frozen", "poisoned", "overgrown"]
BASES = ["dirt_1", "dirt_2", "grass_1", "grass_2", "sand_1", "sand_2", "stone_1", "stone_2", "stone_3",
         "snow_1", "snow_2", "mud_1", "mud_2"]
STATES = ["wet", "burning", "frozen", "poisoned", "overgrown_1", "overgrown_2"]
BG, FRAME, TEXT = "#1b120d", "#0b0705", "#e8d3a8"
CARD, CELL = 150, 160   # overview card size; mock-up cell (80 px shown at 2x)
FONT = ["-font", "DejaVu-Serif", "-fill", TEXT]

# mock-up grid: one tile per cell, 6 columns x 4 rows
GRID = [
    ["grass_1", "grass_2", "dirt_1", "overgrown_1", "dirt_2", "overgrown_2"],
    ["wet", "grass_2", "mud_1", "dirt_2", "stone_1", "burning"],
    ["sand_1", "burning", "stone_3", "dirt_1", "frozen", "sand_2"],
    ["sand_2", "poisoned", "dirt_2", "stone_2", "grass_1", "wet"],
]
# (monster, column, row, rows spanned)
STANDING = [("skeleton", 0, 1, 1), ("goblin", 1, 2, 1), ("cave_spider", 3, 0, 1), ("troll", 4, 1, 2),
            ("banshee", 1, 3, 1), ("shadow_panther", 2, 2, 1), ("fire_elemental", 3, 3, 1)]


def magick(*args):
    subprocess.run(["magick", *map(str, args)], check=True)


def render(script):
    subprocess.run([sys.executable, str(HERE / f"{script}.py")], cwd=HERE, check=True)


def min_alpha(png):
    return float(subprocess.run(["magick", str(png), "-alpha", "on", "-format", "%[fx:minima.a]", "info:"],
                                capture_output=True, text=True, check=True).stdout)


def check_opaque(names):
    leaky = [n for n in names if min_alpha(OUT / f"{n}.png") < 1]
    if leaky:
        sys.exit(f"tiles with transparent pixels: {', '.join(leaky)}")


def card(name, out):
    label = name.replace("_", " ")
    magick(OUT / f"{name}.png", "-resize", f"{CARD}x{CARD}", "-background", BG, "-gravity", "south",
           "-splice", "0x26", *FONT, "-pointsize", "15", "-annotate", "+0+4", label,
           "-bordercolor", FRAME, "-border", "4", out)


def row(title, names, tmp, out):
    cards = []
    for name in names:
        cards.append(tmp / f"card_{name}.png")
        card(name, cards[-1])
    magick(*cards, "+append", "-background", BG, "-gravity", "northwest", "-splice", "0x36",
           *FONT, "-pointsize", "20", "-annotate", "+10+8", title, out)


def mockup(out):
    w, h = CELL * len(GRID[0]), CELL * len(GRID)
    args = ["-size", f"{w}x{h}", f"xc:{BG}"]
    for r, cells in enumerate(GRID):
        for c, name in enumerate(cells):
            args += ["(", OUT / f"{name}.png", "-resize", f"{CELL}x{CELL}", ")",
                     "-geometry", f"+{c * CELL}+{r * CELL}", "-composite"]
    for name, c, r, span in STANDING:
        args += ["(", MONSTERS / f"{name}.png", "-resize", f"{CELL}x{CELL * span}", ")",
                 "-geometry", f"+{c * CELL}+{r * CELL}", "-composite"]
    magick(*args, "-gravity", "northwest", "-background", BG, "-splice", "0x36", *FONT, "-pointsize", "20",
           "-annotate", "+10+8", "Battle grid mock-up (80 px cells, shown at 2x)", out)


def main():
    for script in BASE_SCRIPTS + STATE_SCRIPTS:
        render(script)
    check_opaque(BASES + STATES)
    with tempfile.TemporaryDirectory() as d:
        tmp = Path(d)
        rows = [tmp / "bases.png", tmp / "states.png", tmp / "mockup.png"]
        row("Base grounds", BASES, tmp, rows[0])
        row("State grounds (replace the base)", STATES, tmp, rows[1])
        mockup(rows[2])
        magick(*rows, "-background", FRAME, "-gravity", "northwest", "-append", "+repage",
               "-bordercolor", FRAME, "-border", "8", OUT / "00_all_grounds.png")


if __name__ == "__main__":
    main()
