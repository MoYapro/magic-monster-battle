"""Frozen: an ice sheet over the whole cell, pale and mid blue slabs with ink cracks and frost
marks. Fully opaque, replaces the base."""
import math

from style import INK, PAPER, S, Tile, rng, scatter, sliver

ICE, ICE_EDGE, ICE_PALE, ICE_DARK, FROST = "#4f7590", "#2c445a", "#7d9fb7", "#3f617a", "#b7cedd"


def crack(t, x, y, a, steps):
    pts = [(x, y)]
    for _ in range(steps):
        a += rng.uniform(-0.6, 0.6)
        x, y = x + 16 * math.cos(a), y + 16 * math.sin(a)
        pts.append((x, y))
        if rng.random() < 0.3:
            crack(t, x, y, a + rng.choice([-1, 1]) * 0.9, 2)
    t.line(pts, INK, w=2, op=0.7)


def slab(t, cx, cy, r):
    """An angular pale ice plate with a darker lower-right edge."""
    n = rng.randint(5, 7)
    a0 = rng.uniform(0, 6.28)
    pts = [(cx + r * rng.uniform(0.75, 1.1) * math.cos(a0 + i * 6.28 / n),
            cy + r * rng.uniform(0.75, 1.1) * math.sin(a0 + i * 6.28 / n)) for i in range(n)]
    t.poly([(x + 4, y + 4) for x, y in pts], ICE_DARK)
    t.poly(pts, ICE_PALE)


def frost(t, x, y):
    for k in range(6):
        t.poly(sliver(x, y, k * math.pi / 3, rng.uniform(5, 8), 2), FROST, carve=False)


def build(seed):
    t = Tile(seed)
    t.base(ICE, ICE_EDGE)
    for x, y in scatter(6, margin=40, min_dist=62):
        slab(t, x, y, rng.uniform(26, 38))
    t.texture(ICE_DARK, ang=0.6)
    for a in (0.3, 1.9, 3.4, 4.8):
        crack(t, 128, 128, a, 5)
    for x, y, ln in [(54, 52, 36), (88, 42, 24), (176, 64, 30), (46, 120, 20), (150, 180, 28)]:
        t.poly([(x, y), (x + ln, y - ln * 0.4), (x + ln - 3, y - ln * 0.4 + 5)], PAPER, 0.75, carve=False)
    for x, y in scatter(9, margin=22, min_dist=30):
        frost(t, x, y)
    return t


def main():
    build(900).save("frozen")


if __name__ == "__main__":
    main()
