"""Grass: dark olive turf with tufts of carved blades and a few bare patches."""
import math

from style import Tile, blob, rng, scatter, sliver

BASE, EDGE = "#34401f", "#1c2410"
BLADE, BLADE_LIGHT, BARE = "#4d5c30", "#6a7a40", "#3d3322"


def tuft(t, x, y, size):
    """A clump of blades radiating from one point, seen from above."""
    for i in range(rng.randint(5, 8)):
        a = -math.pi / 2 + rng.uniform(-1.4, 1.4)
        color = BLADE_LIGHT if i % 3 == 0 else BLADE
        t.poly(sliver(x, y, a, size * rng.uniform(0.7, 1.1), rng.uniform(3, 4.5)), color, carve=False)


def build(seed, variant):
    t = Tile(seed)
    t.base(BASE, EDGE)
    t.texture(EDGE)
    if variant == 2:
        for x, y in scatter(2, margin=50, min_dist=80):
            t.poly(blob(x, y, rng.uniform(18, 26), rng.uniform(12, 18)), BARE, op=0.9)
    t.gouges(30, EDGE, lmin=5, lmax=11, ang=-1.3, spread=0.5)
    for x, y in scatter(16 if variant == 1 else 11, margin=26, min_dist=24):
        tuft(t, x, y, rng.uniform(11, 18))
    return t


def main():
    for v in (1, 2):
        build(200 + v, v).save(f"grass_{v}")


if __name__ == "__main__":
    main()
