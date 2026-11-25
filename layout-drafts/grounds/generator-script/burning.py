"""Burning: scorched, smouldering ground over the whole cell: charred earth, ash, glowing ember
cracks and flame tongues spread across the area. Fully opaque, replaces the base."""
import math

from style import INK, Tile, bezier, blob, rng, scatter, taper

CHAR, CHAR_EDGE, ASH, CRACK, CRACK_CORE = "#2b1e16", "#150e09", "#3e332b", "#b8501c", "#f0a83a"
FLAME, FLAME_CORE = "#d0642a", "#f0b040"


def flame(x, y, h, w, lean):
    tip = (x + lean * h, y - h)
    left = bezier((x - w / 2, y), (x - w * 0.6 + lean * h * 0.2, y - h * 0.55), tip, 8)
    right = bezier(tip, (x + w * 0.55 + lean * h * 0.45, y - h * 0.4), (x + w / 2, y), 8)
    return left + right[1:] + [(x + w * 0.2, y + w * 0.15), (x - w * 0.2, y + w * 0.15)]


def ember_crack(t, x, y, a, steps):
    pts = [(x, y)]
    for _ in range(steps):
        a += rng.uniform(-0.7, 0.7)
        x, y = x + 13 * math.cos(a), y + 13 * math.sin(a)
        pts.append((x, y))
    t.poly(taper(pts, 4.5, 0.6), CRACK, carve=False)
    t.poly(taper(pts[:-1], 1.8, 0.4), CRACK_CORE, carve=False)


def build(seed):
    t = Tile(seed)
    t.base(CHAR, CHAR_EDGE)
    for x, y in scatter(6, margin=32, min_dist=55):
        t.poly(blob(x, y, rng.uniform(22, 34), rng.uniform(14, 22), rot=rng.uniform(0, 3)), ASH)
    t.texture(CHAR_EDGE)
    for x, y in scatter(7, margin=34, min_dist=45):
        ember_crack(t, x, y, rng.uniform(0, 6.28), rng.randint(3, 5))
    for x, y in scatter(7, margin=36, min_dist=52):
        h = rng.uniform(40, 60)
        lean = rng.uniform(-0.2, 0.2)
        t.block(flame(x, y + h / 2, h, h * 0.5, lean), FLAME, op=0.97, ink_op=0.75, ink_w=2.5)
        t.poly(flame(x + 1, y + h / 2 - 3, h * 0.55, h * 0.22, lean), FLAME_CORE)
    for x, y in scatter(12, margin=18):
        t.poly(blob(x, y, 2.2, 2.2, n=5), CRACK_CORE, carve=False)
    return t


def main():
    build(800).save("burning")


if __name__ == "__main__":
    main()
