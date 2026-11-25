"""Snow: muted blue-grey drifts with carved shadow scoops and a few frozen tufts."""
import math

from style import Tile, blob, rng, scatter, sliver

BASE, EDGE = "#68717b", "#454d56"
DRIFT, SCOOP, TUFT = "#7a848e", "#555e68", "#3d3a30"


def build(seed, variant):
    t = Tile(seed)
    t.base(BASE, EDGE)
    t.texture(SCOOP)
    for x, y in scatter(5 if variant == 1 else 3, margin=60, min_dist=60):
        rx, ry = rng.uniform(30, 48), rng.uniform(16, 24)
        t.poly(blob(x, y, rx, ry, rot=-0.3), DRIFT, op=0.9)
        t.poly(blob(x + rx * 0.3, y + ry * 0.6, rx * 0.6, ry * 0.35, rot=-0.3), SCOOP, op=0.8)
    t.gouges(24, SCOOP, lmin=6, lmax=12, ang=0.5, spread=0.3)
    if variant == 2:
        for x, y in scatter(4, margin=30, min_dist=50):
            for _ in range(4):
                a = -math.pi / 2 + rng.uniform(-1.2, 1.2)
                t.poly(sliver(x, y, a, rng.uniform(8, 13), 3), TUFT, carve=False)
    return t


def main():
    for v in (1, 2):
        build(500 + v, v).save(f"snow_{v}")


if __name__ == "__main__":
    main()
