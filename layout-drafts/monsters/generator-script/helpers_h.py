"""Helpers for the shield ogre, stone giant and war drummer (linocut v2).

Adds a rim print that winds every polygon the same way (no clip holes), plain geometry for
points between joints, and shapes these three need: fists, carved rock slabs with cracks,
rivets, a tower shield and a 3/4-view drum.
"""
import math

from helpers_b import orient
from helpers_d import OuterRimPrint, body, chain, gouge, grain
from style import INK, PAPER, knob, path, rng, sliver


class RimPrint(OuterRimPrint):
    """OuterRimPrint with every polygon wound clockwise, so overlapping polygons never cut holes."""

    def part(self, polys, shade=None, marks=(), color=None, sw=6, reg=(5, 4), rim=True):
        super().part([orient(q) for q in polys], shade, marks, color, sw, reg, rim)


# ---------------------------------------------------------------- geometry (pure)

def mid(a, b, dx=0, dy=0, t=0.5):
    """The point at t between a and b, nudged by (dx, dy)."""
    return a[0] + (b[0] - a[0]) * t + dx, a[1] + (b[1] - a[1]) * t + dy


def ellipse_pts(cx, cy, rx, ry, a0=0.0, a1=2 * math.pi, n=24):
    """Points on an ellipse arc from angle a0 to a1."""
    return [(cx + rx * math.cos(a0 + (a1 - a0) * i / n), cy + ry * math.sin(a0 + (a1 - a0) * i / n))
            for i in range(n + 1)]


def rivet(x, y, r=5):
    """A black iron rivet head with a cream catch-light."""
    return [(path(knob(x, y, r, 6, 0.3)), INK), (path(knob(x - r * 0.3, y - r * 0.3, r * 0.35, 5)), PAPER)]


def crack(a, b, kinks=3, w=4, jag=10):
    """A jagged ink crack from a to b, as a tapered mark."""
    pts = [a]
    for i in range(1, kinks + 1):
        x, y = mid(a, b, t=i / (kinks + 1))
        pts.append((x + rng.uniform(-jag, jag), y + rng.uniform(-jag, jag)))
    pts.append(b)
    return gouge_line(pts, w)


def gouge_line(pts, w):
    """A tapered mark along a polyline (thick at the start, thin at the end)."""
    from style import taper
    return path(taper(pts, w, 0.6))


# ---------------------------------------------------------------- body-part primitives

def fist(p, at, color, size=1.0, knuckles=4):
    """A clenched fist: a lumpy block with finger creases, its shadow on the lower right."""
    x, y = at
    s = size
    poly = [(x - 38 * s, y - 30 * s), (x + 30 * s, y - 34 * s), (x + 46 * s, y + 2 * s),
            (x + 36 * s, y + 46 * s), (x - 18 * s, y + 56 * s), (x - 48 * s, y + 22 * s)]
    creases = [(sliver(x - 30 * s + i * 19 * s, y + 10 * s + i * 3 * s, 1.25, 30 * s, 6), INK)
               for i in range(knuckles)]
    body(p, poly, [(x + 44 * s, y - 30 * s), (x + 14 * s, y + 22 * s), (x - 40 * s, y + 56 * s)],
         color=color, count=3, lmin=6, lmax=12, w=4, extra=creases)


def slab(p, poly, edge, color, cracks=1, count=4, extra=()):
    """A carved rock slab: an angular mass with a curved shadow edge, gouges and ink cracks."""
    xs, ys = [q[0] for q in poly], [q[1] for q in poly]
    cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
    rw, rh = (max(xs) - min(xs)) * 0.32, (max(ys) - min(ys)) * 0.32
    marks = [(crack((cx - rw + rng.uniform(-8, 8), cy - rh * rng.uniform(0.2, 1)),
                    (cx + rw * rng.uniform(0.2, 0.8), cy + rh * rng.uniform(0.3, 1)), kinks=2, w=4), INK)
             for _ in range(cracks)]
    body(p, poly, edge, color=color, count=count, lmin=8, lmax=20, w=5, extra=marks + list(extra))


def strap(a, b, w):
    """A straight band between two points (belt, drum strap, shield brace) as a polygon."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1) or 1
    nx, ny = -(y2 - y1) / L * w / 2, (x2 - x1) / L * w / 2
    return [(x1 + nx, y1 + ny), (x2 + nx, y2 + ny), (x2 - nx, y2 - ny), (x1 - nx, y1 - ny)]


def fur(p, a, b, n, length, color=PAPER):
    """A row of pointed fur tufts hanging from the line a-b, drawn as one carved part."""
    tufts = []
    for i in range(n):
        x, y = mid(a, b, t=(i + 0.5) / n)
        L = length * rng.uniform(0.7, 1.15)
        lean = rng.uniform(-0.35, 0.35)
        w = (math.dist(a, b) / n) * 0.75
        tufts.append([(x - w, y - 6), (x + w, y - 6), (x + lean * L + w * 0.2, y + L)])
    body(p, tufts, [a, mid(a, b, 0, 14), b], color=color, count=n // 2, lmin=6, lmax=12, w=4,
         extra=[(gouge((x, y + 2), (x + 2, y + length * 0.4), (x, y + length * 0.6), 3), INK)
                for x, y in (mid(a, b, t=(i + 0.5) / n) for i in range(0, n, 2))])


def drum_body(cx, cy, rx, ry, depth):
    """Outline of a 3/4-view drum shell: the top ellipse's back arc, straight sides, bottom arc."""
    top_back = ellipse_pts(cx, cy, rx, ry, math.pi, 2 * math.pi, 16)
    bottom = ellipse_pts(cx, cy + depth, rx, ry, 0, math.pi, 16)
    return top_back + bottom


def grained(line, w, n=4):
    """Grain cuts along a line, re-exported for wooden shafts."""
    return grain(chain(line), w, n=n, color=INK, width=4)


def rock_limb(a, b, w1, w2, facets=3, jit=0.12):
    """An angular, faceted block around the segment a-b: a stone arm or leg piece."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1) or 1
    tx, ty = (x2 - x1) / L, (y2 - y1) / L
    nx, ny = -ty, tx
    left, right = [], []
    for i in range(facets + 1):
        t = i / facets
        w = (w1 + (w2 - w1) * t) / 2 * (1 + rng.uniform(-jit, jit))
        x, y = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w * (1 + rng.uniform(-jit, jit)), y - ny * w))
    cap1 = (x1 - tx * w1 * 0.25, y1 - ty * w1 * 0.25)
    cap2 = (x2 + tx * w2 * 0.25, y2 + ty * w2 * 0.25)
    return [cap1] + left + [cap2] + right[::-1]


def boulder(cx, cy, r, n=8, squash=1.0, rot=0.0, jit=0.14):
    """A faceted boulder outline: a polygon with uneven radii."""
    return [(cx + r * (1 + rng.uniform(-jit, jit)) * math.cos(rot + i * 2 * math.pi / n),
             cy + r * squash * (1 + rng.uniform(-jit, jit)) * math.sin(rot + i * 2 * math.pi / n))
            for i in range(n)]
