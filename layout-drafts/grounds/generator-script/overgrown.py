"""Overgrown overlays: a dense mat of dark undergrowth, tangled vines, roots, thorns and leaves.

Fully opaque: dark earth shows in a few gaps of the undergrowth mat, so the cell reads as overgrown
even at 80 px. It stays in mid and dark greens so monsters still stand out on it.
"""
import math

from style import INK, S, Tile, bezier, blob, path, rng, rough, scatter, sliver, taper

MAT, MAT_DARK, ROOT, VINE, VINE_LIGHT, LEAF, LEAF_LIGHT = (
    "#2b3a19", "#1d2810", "#3a2c18", "#4f6024", "#76863a", "#5f8028", "#93ad4c")


EARTH, EARTH_EDGE = "#2e2216", "#1a130c"


def mat(t):
    """Dark earth under an undergrowth layer that covers the cell except a few gaps (even-odd holes)."""
    t.base(EARTH, EARTH_EDGE)
    t.gouges(30, EARTH_EDGE, lmin=5, lmax=10)
    m = 4
    outer = path(rough([(m, m), (S - m, m), (S - m, S - m), (m, S - m)], step=10, amp=3))
    holes = "".join(path(rough(blob(x, y, rng.uniform(10, 18), rng.uniform(7, 12), n=8)))
                    for x, y in scatter(6, margin=36, min_dist=55))
    t.body.append(f'<path d="{outer}{holes}" fill="{MAT}" fill-rule="evenodd" opacity="0.93"/>')
    for x, y in scatter(9, margin=24, min_dist=40):
        t.poly(blob(x, y, rng.uniform(16, 28), rng.uniform(10, 18), rot=rng.uniform(0, 3)), MAT_DARK, 0.8)


def strand(t, color, light, w, thorny):
    """One vine or root crossing the cell along a curve, with thorns or leaves along it."""
    def edge_point(side):
        u = rng.uniform(20, S - 20)
        return [(12, u), (u, 12), (S - 12, u), (u, S - 12)][side]
    side = rng.randint(0, 3)
    a = edge_point(side)
    b = edge_point((side + rng.choice([1, 2, 3])) % 4)
    c = (rng.uniform(20, S - 20), rng.uniform(20, S - 20))
    pts = [(min(max(x, 8), S - 8), min(max(y, 8), S - 8)) for x, y in bezier(a, c, b, 16)]
    t.block(taper(pts, w, w * 0.35), color, op=0.97, ink_op=0.7, ink_w=2, reg=(2, 1))
    t.poly(taper(pts[1:-3], w * 0.22, 0.4), light, 0.55, carve=False)
    for i in range(1, 15, 2):
        (x, y), (nx, ny) = pts[i], pts[i + 1]
        ang = math.atan2(ny - y, nx - x) + rng.choice([-1, 1]) * rng.uniform(0.9, 1.4)
        if thorny:
            t.poly(sliver(x, y, ang, rng.uniform(5, 8), 2.5), INK, 0.85, carve=False)
        elif rng.random() < 0.5:
            leaf(t, x, y, ang, rng.uniform(9, 13))


def leaf(t, x, y, a, size):
    tip = (x + size * math.cos(a), y + size * math.sin(a))
    n = (-math.sin(a) * size * 0.32, math.cos(a) * size * 0.32)
    mid = ((x + tip[0]) / 2, (y + tip[1]) / 2)
    t.poly([(x, y), (mid[0] + n[0], mid[1] + n[1]), tip, (mid[0] - n[0], mid[1] - n[1])], LEAF, carve=False)
    t.line([(x, y), tip], LEAF_LIGHT, w=1.3, op=0.9)


def build_tangle(seed):
    """Variant 1: thin vines and roots crossing in all directions, small leaves."""
    t = Tile(seed)
    mat(t)
    t.gouges(40, MAT_DARK, lmin=6, lmax=12, w=3)
    for _ in range(5):
        strand(t, ROOT, "#5a4628", rng.uniform(7, 10), thorny=False)
    for _ in range(7):
        strand(t, VINE, VINE_LIGHT, rng.uniform(5, 8), thorny=rng.random() < 0.5)
    for x, y in scatter(8, margin=16):
        leaf(t, x, y, rng.uniform(0, 6.28), rng.uniform(8, 12))
    return t


BROAD, BROAD_DARK, BROAD_VEIN = "#45621f", "#33491a", "#6e8a36"


def broad_leaf(t, x, y, a, size):
    """A wide carved leaf lying flat: dark underside offset, body, midrib and two side veins."""
    tip = (x + size * math.cos(a), y + size * math.sin(a))
    n = (-math.sin(a) * size * 0.45, math.cos(a) * size * 0.45)
    mid = (x + (tip[0] - x) * 0.45, y + (tip[1] - y) * 0.45)
    pts = [(x, y), (mid[0] + n[0], mid[1] + n[1]), tip, (mid[0] - n[0], mid[1] - n[1])]
    t.poly([(px + 3, py + 3) for px, py in pts], BROAD_DARK, 0.9)
    t.poly(pts, BROAD, 0.97)
    t.line([(x, y), tip], BROAD_VEIN, w=1.6, op=0.8)
    for k in (-1, 1):
        t.line([mid, (mid[0] + n[0] * 0.7 * k + (tip[0] - x) * 0.15, mid[1] + n[1] * 0.7 * k + (tip[1] - y) * 0.15)],
               BROAD_VEIN, w=1.1, op=0.6)


def rosette(t, x, y, size):
    """A clump of broad leaves radiating from one point: creeping ground cover."""
    a0 = rng.uniform(0, 6.28)
    for i in range(rng.randint(4, 6)):
        broad_leaf(t, x, y, a0 + i * 6.28 / 5 + rng.uniform(-0.3, 0.3), size * rng.uniform(0.8, 1.1))


def thick_root(t, a, c, b, w):
    pts = bezier(a, c, b, 16)
    t.block(taper(pts, w, w * 0.3), ROOT, op=0.97, ink_op=0.7, ink_w=2.2, reg=(2, 1))
    t.poly(taper(pts[1:-4], w * 0.25, 0.5), "#5a4628", 0.7, carve=False)
    for i in range(3, 14, 4):
        (x, y), (nx, ny) = pts[i], pts[i + 1]
        side = math.atan2(ny - y, nx - x) + rng.choice([-1, 1]) * 1.2
        t.poly(taper([(x, y), (x + 14 * math.cos(side), y + 14 * math.sin(side))], w * 0.35, 0.4),
               ROOT, 0.9, carve=False)


def build_cover(seed):
    """Variant 2: broad-leaved ground cover with a few thick roots and only two vines."""
    t = Tile(seed)
    mat(t)
    t.gouges(30, MAT_DARK, lmin=6, lmax=12, w=3)
    thick_root(t, (14, 70), (110, 120), (180, 242), 14)
    thick_root(t, (242, 40), (170, 110), (110, 14), 11)
    thick_root(t, (242, 190), (190, 170), (150, 236), 9)
    for x, y in scatter(13, margin=30, min_dist=42):
        rosette(t, x, y, rng.uniform(16, 24))
    for _ in range(2):
        strand(t, VINE, VINE_LIGHT, rng.uniform(4, 6), thorny=True)
    return t


def main():
    build_tangle(1100).save("overgrown_1")
    build_cover(1200).save("overgrown_2")


if __name__ == "__main__":
    main()
