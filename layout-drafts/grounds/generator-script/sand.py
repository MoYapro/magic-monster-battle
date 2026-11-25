"""Sand: muted ochre with wind ripples carved as wavy parallel lines."""
import math

from style import MARGIN, S, Tile, rng, scatter, taper

BASE, EDGE = "#6b5638", "#43341f"
RIPPLE_DARK, RIPPLE_LIGHT, GRAIN = "#54432a", "#84704c", "#7a6646"


def ripple(t, y0, amp, phase, tilt):
    """One wavy ripple across the tile, kept inside the margin."""
    pts = []
    for i in range(24):
        x = MARGIN + (S - 2 * MARGIN) * i / 23
        pts.append((x, y0 + tilt * (x - S / 2) + amp * math.sin(x / 26 + phase)))
    start = rng.randint(0, 6)
    end = len(pts) - rng.randint(0, 6)
    seg = pts[start:end]
    mid = len(seg) // 2
    t.poly(taper(seg[:mid + 1], 0.8, 4.5), RIPPLE_DARK, carve=False)
    t.poly(taper(seg[mid:], 4.5, 0.8), RIPPLE_DARK, carve=False)
    t.poly(taper([(x - 2, y - 4) for x, y in pts[start + 3:end - 3]], 0.5, 3), RIPPLE_LIGHT, 0.8, carve=False)


def build(seed, variant):
    t = Tile(seed)
    t.base(BASE, EDGE)
    t.texture(RIPPLE_DARK)
    tilt = 0.18 if variant == 1 else -0.12
    gap = 30 if variant == 1 else 40
    y = MARGIN + 20
    while y < S - MARGIN - 10:
        ripple(t, y + rng.uniform(-4, 4), rng.uniform(4, 7), rng.uniform(0, 6), tilt)
        y += gap
    for x, yy in scatter(30):
        t.poly([(x, yy), (x + 2, yy + 1), (x + 1, yy + 2.5)], GRAIN, carve=False)
    return t


def main():
    for v in (1, 2):
        build(300 + v, v).save(f"sand_{v}")


if __name__ == "__main__":
    main()
