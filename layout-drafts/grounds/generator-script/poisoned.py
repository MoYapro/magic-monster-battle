"""Poisoned: a continuous toxic bog over the whole cell, fully opaque, replacing the base.

Hard-edged carved shapes only (no blur): a sickly yellow-green ground run through with
violet slime pools and veins, carved ripples in light green and lilac, and lilac bubbles.
"""
import math

from style import INK, Tile, bezier, blob, rng, scatter, taper

GROUND, GROUND_EDGE, GROUND_DARK = "#3b4612", "#1f260a", "#2c350c"
SLIME, SLIME_DARK, LILAC, GREEN_HI = "#553868", "#33213f", "#a888c4", "#9cb734"


def pool(t, x, y, rx, ry):
    """A violet slime pool: dark carved rim, body, a lighter lilac skin patch top-left."""
    rot = rng.uniform(0, 3)
    t.poly(blob(x + 3, y + 3, rx * 1.06, ry * 1.06, n=13, wobble=0.35, rot=rot), SLIME_DARK)
    t.poly(blob(x, y, rx, ry, n=13, wobble=0.35, rot=rot), SLIME)
    ripple(t, x, y, rx * 0.6, LILAC, 2)
    ripple(t, x + rx * 0.1, y + ry * 0.2, rx * 0.35, SLIME_DARK, 2)


def vein(t, a, b, w):
    """A violet streak connecting pools, so the slime reads as one network."""
    c = ((a[0] + b[0]) / 2 + rng.uniform(-30, 30), (a[1] + b[1]) / 2 + rng.uniform(-30, 30))
    pts = bezier(a, c, b, 14)
    t.poly(taper(pts, w, w * 0.6), SLIME_DARK)
    t.poly(taper([(x - 1, y - 1) for x, y in pts], w * 0.6, w * 0.3), SLIME)


def ripple(t, x, y, r, color, w):
    a0 = rng.uniform(3.4, 4.2)
    arc = [(x + r * math.cos(a0 + i * 0.22), y + r * 0.65 * math.sin(a0 + i * 0.22)) for i in range(9)]
    t.poly(taper(arc, 0.6, w), color, carve=False)


def bubble(t, x, y, r, color):
    ring = [(x + r * math.cos(i * math.pi / 5), y + r * math.sin(i * math.pi / 5)) for i in range(11)]
    t.line(ring, color, w=2.2)
    t.poly([(x - r * 0.4, y - r * 0.5), (x - r * 0.1, y - r * 0.6), (x - r * 0.3, y - r * 0.2)],
           color, carve=False)


def build(seed):
    t = Tile(seed)
    t.base(GROUND, GROUND_EDGE)
    for x, y in scatter(6, margin=30, min_dist=50):
        t.poly(blob(x, y, rng.uniform(22, 34), rng.uniform(14, 22), rot=rng.uniform(0, 3)), GROUND_DARK)
    t.texture(GROUND_EDGE)
    centres = scatter(7, margin=36, min_dist=58)
    for i, a in enumerate(centres):
        others = sorted(centres[:i] + centres[i + 1:], key=lambda b: math.dist(a, b))
        vein(t, a, others[0], rng.uniform(10, 16))
        if rng.random() < 0.4:
            vein(t, a, (min(max(a[0] + rng.uniform(-70, 70), 14), 242), min(max(a[1] + rng.uniform(-70, 70), 14), 242)), 7)
    for x, y in centres:
        pool(t, x, y, rng.uniform(16, 34), rng.uniform(12, 24))
    for x, y in scatter(8, margin=22, min_dist=40):
        ripple(t, x, y, rng.uniform(10, 16), GREEN_HI, 2.8)
    for x, y in scatter(16, margin=16, min_dist=20):
        bubble(t, x, y, rng.uniform(3, 6.5), LILAC if rng.random() < 0.6 else GREEN_HI)
    return t


def main():
    build(1000).save("poisoned")


if __name__ == "__main__":
    main()
