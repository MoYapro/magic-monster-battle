"""Re-stack a monster's exported layers by rig.json and compare them with full.png.

Usage: python3 tools/check_rig.py <id> [...]   -> prints the share of pixels that differ visibly.
"""
import json
import sys
from pathlib import Path

from PIL import Image, ImageChops

MONSTERS = Path(__file__).resolve().parents[1] / "assets" / "monsters"


def restack(mid):
    rig = json.loads((MONSTERS / mid / "rig.json").read_text())
    canvas = Image.new("RGBA", tuple(int(v) for v in rig["canvas"]), (0, 0, 0, 0))
    for layer in sorted(rig["layers"], key=lambda l: l["z"]):
        part = Image.open(MONSTERS / mid / layer["file"]).convert("RGBA")
        canvas.alpha_composite(part, tuple(layer["pos"]))
    return canvas


def diff_share(mid):
    full = Image.open(MONSTERS / mid / "full.png").convert("RGBA")
    diff = ImageChops.difference(full, restack(mid)).convert("L").point(lambda v: 255 if v > 40 else 0)
    return sum(diff.histogram()[255:]) / (full.width * full.height)


if __name__ == "__main__":
    for mid in sys.argv[1:]:
        print(f"{mid}: {diff_share(mid):.4%} pixels differ")
