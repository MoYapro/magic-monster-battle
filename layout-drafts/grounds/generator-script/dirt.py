"""Dirt (soil): packed brown earth with clods, pebbles and short carved scratches."""
import math

from style import Tile, blob, rng, scatter

BASE, EDGE = "#4a3628", "#2a1d14"
CLOD_DARK, CLOD_LIGHT, PEBBLE = "#3a2a1e", "#5f4733", "#6e5a46"


def clods(t, n):
    for x, y in scatter(n, margin=34, min_dist=30):
        t.poly(blob(x, y, rng.uniform(10, 20), rng.uniform(7, 14), rot=rng.uniform(0, 3)), CLOD_DARK)
        t.poly(blob(x - 3, y - 3, rng.uniform(6, 11), rng.uniform(4, 8)), CLOD_LIGHT, op=0.8)


def pebbles(t, n):
    for x, y in scatter(n, min_dist=18):
        r = rng.uniform(3, 6)
        t.poly(blob(x, y, r, r * 0.8, n=6), PEBBLE)


def build(seed, variant):
    t = Tile(seed)
    t.base(BASE, EDGE)
    t.texture(CLOD_DARK)
    clods(t, 7 if variant == 1 else 4)
    t.gouges(40, EDGE, ang=-0.5, spread=0.6)
    t.gouges(14, CLOD_LIGHT, lmin=5, lmax=10, w=2.5, op=0.7)
    pebbles(t, 5 if variant == 1 else 12)
    return t


def main():
    for v in (1, 2):
        build(100 + v, v).save(f"dirt_{v}")


if __name__ == "__main__":
    main()
