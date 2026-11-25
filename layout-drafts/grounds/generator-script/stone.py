"""Stone: natural stony ground: uneven earth with embedded rocks, pebbles, gravel and cracks."""
import math

from style import INK, S, Tile, blob, rng, scatter, taper

BASE, EDGE = "#3d3832", "#211e1a"
EARTH, ROCK, ROCK_LIGHT, ROCK_DARK, GRAVEL = "#443d34", "#57524b", "#706a60", "#2c2925", "#635c52"


def rock(t, x, y, r):
    """An embedded stone: shadowed rim bottom-right, body, a lit facet top-left."""
    rot = rng.uniform(0, 3)
    t.poly(blob(x + r * 0.12, y + r * 0.15, r * 1.05, r * 0.85, n=7, wobble=0.18, rot=rot), ROCK_DARK)
    t.poly(blob(x, y, r, r * 0.8, n=7, wobble=0.18, rot=rot), ROCK)
    t.poly(blob(x - r * 0.25, y - r * 0.22, r * 0.5, r * 0.35, n=6, rot=rot), ROCK_LIGHT, 0.8)


def crack(t, x, y, a, steps, w=2.6):
    pts = [(x, y)]
    for _ in range(steps):
        a += rng.uniform(-0.6, 0.6)
        x, y = x + 11 * math.cos(a), y + 11 * math.sin(a)
        pts.append((x, y))
    t.poly(taper(pts, w, 0.4), INK, 0.6, carve=False)


def gravel(t, n, margin=16):
    for x, y in scatter(n, margin=margin):
        r = rng.uniform(1.8, 3.8)
        t.poly(blob(x, y, r, r * 0.8, n=5), rng.choice([GRAVEL, ROCK_LIGHT, ROCK_DARK]), carve=False)


BOULDER, BOULDER_LIGHT, BOULDER_RIM = "#625c53", "#7d766b", "#36322c"


def boulder(t, x, y, rx, ry, rot):
    """A big rock slab: shadow rim, body, lit top-left facet and a crack across it."""
    t.poly(blob(x + 5, y + 6, rx, ry, n=8, wobble=0.12, rot=rot), BOULDER_RIM)
    t.poly(blob(x, y, rx, ry, n=8, wobble=0.12, rot=rot), BOULDER)
    t.poly(blob(x - rx * 0.28, y - ry * 0.3, rx * 0.5, ry * 0.38, n=7, rot=rot), BOULDER_LIGHT, 0.75)
    crack(t, x - rx * 0.45 + rng.uniform(-6, 6), y + rng.uniform(-8, 8), rng.uniform(-0.4, 0.4), max(2, int(rx / 14)), 3.6)


def boulders(t):
    """3-5 large slabs filling most of the cell, with earth and gravel in the gaps."""
    t.texture(EDGE)
    gravel(t, 60)
    slabs = [(84, 82, 66, 50, 0.5), (190, 70, 40, 38, 1.1), (170, 168, 58, 54, 2.0),
             (64, 196, 36, 30, 0.7), (200, 220, 18, 14, 0.2)]
    for x, y, rx, ry, rot in slabs:
        boulder(t, x + rng.uniform(-4, 4), y + rng.uniform(-4, 4), rx, ry, rot)
    rock(t, 112, 156, 12)
    rock(t, 150, 108, 9)
    gravel(t, 18, margin=20)


def build(seed, variant):
    t = Tile(seed)
    t.base(BASE, EDGE)
    if variant == 3:
        boulders(t)
        return t
    for x, y in scatter(6, margin=40, min_dist=50):
        t.poly(blob(x, y, rng.uniform(26, 40), rng.uniform(18, 28), rot=rng.uniform(0, 3)), EARTH, 0.8)
    t.texture(EDGE)
    gravel(t, 70 if variant == 1 else 45)
    if variant == 1:
        rock(t, 150, 110, 42)
        sizes = [20, 16, 13, 11, 10, 8, 7]
    else:
        sizes = [26, 22, 18, 16, 12, 10, 9, 8]
    for (x, y), r in zip(scatter(len(sizes), margin=34, min_dist=44), sizes):
        rock(t, x, y, r)
    for x, y in scatter(3, margin=40):
        crack(t, x, y, rng.uniform(0, 6), 4)
    return t


def main():
    for v in (1, 2, 3):
        build(400 + v, v).save(f"stone_{v}")


if __name__ == "__main__":
    main()
