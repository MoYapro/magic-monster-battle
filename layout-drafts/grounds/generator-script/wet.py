"""Wet: a flooded cell, dark water from edge to edge with carved ripples, glints, a few
drowned grass tips and stones breaking the surface. Fully opaque, replaces the base."""
import math

from style import PAPER, Tile, blob, rng, scatter, sliver, taper

WATER, WATER_EDGE, DEEP, SHALLOW, RIPPLE = "#23405a", "#142838", "#1b3348", "#2f5574", "#7ea6c2"
STONE, STONE_LIGHT, REED = "#4a4a46", "#66665e", "#4f6a2a"


def ripple(t, x, y, r, w=2.8):
    arc = [(x + r * math.cos(a), y + r * 0.6 * math.sin(a)) for a in (3.5 + i * 0.24 for i in range(10))]
    t.poly(taper(arc, 0.6, w), RIPPLE, 0.85, carve=False)


def build(seed):
    t = Tile(seed)
    t.base(WATER, WATER_EDGE)
    for x, y in scatter(5, margin=34, min_dist=60):
        t.poly(blob(x, y, rng.uniform(26, 40), rng.uniform(16, 26), rot=rng.uniform(0, 3)), DEEP)
    for x, y in scatter(6, margin=30, min_dist=50):
        t.poly(blob(x, y, rng.uniform(16, 26), rng.uniform(10, 16), rot=rng.uniform(0, 3)), SHALLOW)
    t.texture(WATER_EDGE, ang=0.0)
    for x, y in scatter(11, margin=26, min_dist=36):
        ripple(t, x, y, rng.uniform(10, 22))
    for x, y in scatter(6, margin=24):
        t.poly(taper([(x, y), (x + rng.uniform(10, 16), y - 2)], 2.6, 0.5), PAPER, 0.7, carve=False)
    for x, y in scatter(2, margin=40, min_dist=90):
        t.poly(blob(x, y, 11, 8, n=7), STONE)
        t.poly(blob(x - 3, y - 3, 5, 3.5, n=6), STONE_LIGHT)
        ripple(t, x, y + 2, 17, 2.2)
    for x, y in scatter(4, margin=28, min_dist=40):
        for _ in range(3):
            t.poly(sliver(x, y, -math.pi / 2 + rng.uniform(-0.8, 0.8), rng.uniform(8, 13), 3), REED, carve=False)
    return t


def main():
    build(700).save("wet")


if __name__ == "__main__":
    main()
