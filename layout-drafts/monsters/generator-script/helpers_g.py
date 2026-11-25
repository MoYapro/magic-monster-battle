"""Extra linocut helpers for the bog shambler, grove tender and scorpion.

- GPrint: one paper rim under the whole figure (from OuterRimPrint) plus consistent polygon
  winding, so overlapping polygons never cut holes into a part.
- Shapes: hanging drips and weeds, pointed leaves, twig forks, armour plates for segments.
"""
import math

from helpers_b import orient
from helpers_d import OuterRimPrint
from style import INK, PAPER, bezier, path, rng, sliver, taper


class GPrint(OuterRimPrint):
    def part(self, polys, shade=None, marks=(), color=None, sw=6, reg=(5, 4), rim=True):
        super().part([orient(q) for q in polys], shade, marks, color, sw, reg, rim)


def unit(x, y):
    L = math.hypot(x, y) or 1
    return x / L, y / L


def drip(x, y, length, w, sway=0.0):
    """A hanging strand that narrows to a drop: mud drips, dangling weeds, wet roots."""
    pts = [(x + sway * length * (t * t), y + length * t) for t in (i / 8 for i in range(9))]
    body = taper(pts, w, w * 0.35)
    tip = pts[-1]
    drop = [(tip[0] + w * 0.45 * math.cos(a), tip[1] + w * 0.55 + w * 0.5 * math.sin(a))
            for a in (i * math.pi / 4 for i in range(8))]
    return [body, drop]


def weed(x, y, length, w, sway=0.0):
    """A ragged weed strand: tapered, ending in a point, with a small side frond."""
    pts = [(x + sway * length * t * t + math.sin(t * 5) * w * 0.4, y + length * t)
           for t in (i / 10 for i in range(11))]
    main = taper(pts, w, 1.0)
    k = rng.randint(3, 6)
    bx, by = pts[k]
    side = 1 if rng.random() < 0.5 else -1
    frond = taper(bezier((bx, by), (bx + side * w * 1.5, by + length * 0.1),
                         (bx + side * w * 2.2, by + length * 0.25), 6), w * 0.6, 1.0)
    return [main, frond]


def leaf(cx, cy, length, width, angle):
    """A pointed leaf centred on its base (cx, cy), pointing along `angle`."""
    dx, dy = math.cos(angle), math.sin(angle)
    nx, ny = -dy, dx
    pts = []
    for i in range(7):
        t = i / 6
        w = width * math.sin(math.pi * min(1, t * 1.15)) * 0.5
        pts.append((cx + dx * length * t + nx * w, cy + dy * length * t + ny * w))
    back = [(cx + dx * length * t - nx * width * math.sin(math.pi * min(1, t * 1.15)) * 0.5,
             cy + dy * length * t - ny * width * math.sin(math.pi * min(1, t * 1.15)) * 0.5)
            for t in (i / 6 for i in range(5, 0, -1))]
    return pts + back


def leaf_vein(cx, cy, length, angle, w=3, color=INK):
    """The carved midrib of a leaf."""
    return (sliver(cx + math.cos(angle) * length * 0.12, cy + math.sin(angle) * length * 0.12,
                   angle, length * 0.72, w), color)


def twig(a, b, w1, w2=1.5, bend=0.15):
    """A crooked tapered twig from a to b."""
    (x1, y1), (x2, y2) = a, b
    nx, ny = unit(-(y2 - y1), x2 - x1)
    L = math.hypot(x2 - x1, y2 - y1)
    c = ((x1 + x2) / 2 + nx * L * bend, (y1 + y2) / 2 + ny * L * bend)
    return taper(bezier(a, c, b, 8), w1, w2)


def plate(a, b, w1, w2, bulge=0.25):
    """A segment plate between joint centres a and b, rounded at both ends (scorpion segments)."""
    (x1, y1), (x2, y2) = a, b
    dx, dy = unit(x2 - x1, y2 - y1)
    nx, ny = -dy, dx
    L = math.hypot(x2 - x1, y2 - y1)
    out = []
    for i in range(9):
        t = i / 8
        w = (w1 + (w2 - w1) * t) / 2 * (1 + bulge * math.sin(math.pi * t))
        out.append((x1 + dx * L * t + nx * w, y1 + dy * L * t + ny * w))
    for i in range(8, -1, -1):
        t = i / 8
        w = (w1 + (w2 - w1) * t) / 2 * (1 + bulge * math.sin(math.pi * t))
        out.append((x1 + dx * L * t - nx * w, y1 + dy * L * t - ny * w))
    return out


def ridge(a, b, w, side=1.0, color=PAPER, frac=0.2):
    """A carved ridge line running along a segment, offset towards one edge."""
    (x1, y1), (x2, y2) = a, b
    dx, dy = unit(x2 - x1, y2 - y1)
    nx, ny = -dy, dx
    o = w * frac * side
    L = math.hypot(x2 - x1, y2 - y1)
    return (sliver(x1 + nx * o + dx * L * 0.12, y1 + ny * o + dy * L * 0.12, math.atan2(dy, dx),
                   L * 0.7, max(3, w * 0.1)), color)


__all__ = ["GPrint", "drip", "weed", "leaf", "leaf_vein", "twig", "plate", "ridge", "unit"]
