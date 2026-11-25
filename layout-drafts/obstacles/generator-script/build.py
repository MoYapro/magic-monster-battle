"""Render every linocut obstacle into the obstacles folder and rebuild 00_all_obstacles.png.

Usage: python3 build.py [ids...]
Each obstacle is <id>.svg + <id>.png on 512 px per grid cell; the overview shows them on the
dark UI colour, grouped by footprint.
"""
import subprocess
import sys
import tempfile

import kit
import small
import tall
import wide
import big

GROUPS = [small, tall, wide, big]
BG = "#1b120d"


def render(ids):
    done = []
    for g in GROUPS:
        for i, (oid, (draw, color)) in enumerate(g.OBSTACLES.items()):
            if ids and oid not in ids:
                continue
            p = kit.ObstaclePrint(color, g.CELLS, seed=100 + i)
            with p.group("obstacle", (kit.CELL * g.CELLS[0] / 2, kit.CELL * g.CELLS[1] - 60)):
                draw(p)
            p.save(oid)
            done.append(oid)
    return done


def overview():
    with tempfile.TemporaryDirectory() as tmp:
        cards = []
        for g in GROUPS:
            for oid in g.OBSTACLES:
                card = f"{tmp}/{oid}.png"
                h = 260 if g.CELLS[1] == 1 else 520
                subprocess.run(["magick", str(kit.OUT / f"{oid}.png"), "-resize", f"x{h}", "-background", BG,
                                "-gravity", "south", "-extent", f"{max(260, 260 * g.CELLS[0])}x{h + 30}",
                                "-fill", "#e8d3a8", "-font", "DejaVu-Serif", "-pointsize", "18", "-gravity", "south",
                                "-annotate", "+0+4", oid.replace("_", " "), card], check=True)
                cards.append(card)
        subprocess.run(["magick", "montage", *cards, "-tile", "6x", "-geometry", "+8+8", "-background", BG,
                        str(kit.OUT / "00_all_obstacles.png")], check=True)


if __name__ == "__main__":
    print("rendered:", " ".join(render(sys.argv[1:])))
    overview()
