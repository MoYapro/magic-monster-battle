"""Extra linocut helpers for the cave spider and shadow panther (v2).

- A paper rim around the whole figure instead of per part: parts are drawn with `rim=False`
  and remember their outlines; `figure_rim` draws one rim under everything at the end.
- Curved shadow cuts: the black shadow side ends along a curve that follows the form, and
  the cream gouges are cut along that curve, pointing into the shadow.
- Hair spikes along a segment, so legs and fur read as bristly in the silhouette.
"""
import math

from style import INK, PAPER, bar, bezier, knob, path, rng, rough, sliver, taper


def part(p, polys, shade=None, marks=(), color=None, sw=5):
    """Like Print.part, but without a per-part rim; the outline joins the figure rim instead."""
    p.__dict__.setdefault("rim_polys", []).extend(polys)
    p.part(polys, shade, marks, color=color, sw=sw, rim=False)


def figure_rim(p, width=16):
    """One cream rim around the whole figure, drawn below every part (call at top level)."""
    for poly in p.__dict__.get("rim_polys", []):
        p.rim(path(rough(poly, amp=1.5)), width)


def unit(x, y):
    L = math.hypot(x, y) or 1
    return x / L, y / L


def curve_cut(curve, toward, count=6, lmin=8, lmax=22, w=6, ink_cuts=0):
    """Black shadow beyond `curve` on the `toward` side, with gouges cut along the curve."""
    E = 1600
    tx, ty = unit(toward[0], toward[1])
    (ax, ay), (a2x, a2y) = curve[0], curve[1]
    (bx, by), (b2x, b2y) = curve[-1], curve[-2]
    sx, sy = unit(ax - a2x, ay - a2y)
    ex, ey = unit(bx - b2x, by - b2y)
    start, end = (ax + sx * E, ay + sy * E), (bx + ex * E, by + ey * E)
    poly = [start] + list(curve) + [end, (end[0] + tx * E, end[1] + ty * E),
                                    (start[0] + tx * E, start[1] + ty * E)]
    marks = []
    for i in range(count):
        t = (i + 0.5 + rng.uniform(-0.3, 0.3)) / count
        x, y, nx, ny = along(curve, t)
        if nx * tx + ny * ty < 0:
            nx, ny = -nx, -ny
        ang = math.atan2(ny, nx) + rng.uniform(-0.2, 0.2)
        marks.append((sliver(x - nx * 3, y - ny * 3, ang, rng.uniform(lmin, lmax),
                             w * rng.uniform(0.7, 1.1)), PAPER))
    return path(poly), marks


def along(line, t):
    """Point and unit normal at fraction t along a polyline."""
    lens = [math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(line, line[1:])]
    goal, acc = t * sum(lens), 0.0
    for (a, b), L in zip(zip(line, line[1:]), lens):
        if acc + L >= goal:
            k = (goal - acc) / L if L else 0
            k = min(max(k, 0), 1)
            dx, dy = unit(b[0] - a[0], b[1] - a[1])
            return a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, -dy, dx
        acc += L
    a, b = line[-2], line[-1]
    dx, dy = unit(b[0] - a[0], b[1] - a[1])
    return b[0], b[1], -dy, dx


def groove(a, c, b, w=4, color=PAPER):
    """A thin curved gouge (cream) or carved line (ink) following the form."""
    return path(taper(bezier(a, c, b, 10), w, 0.8)), color


def spikes(a, b, n, length, w=5, lean=0.6, sides=(1, -1), jitter=0.3):
    """Small triangular hairs along segment a-b, leaning towards b."""
    (x1, y1), (x2, y2) = a, b
    dx, dy = unit(x2 - x1, y2 - y1)
    out = []
    for side in sides:
        nx, ny = -dy * side, dx * side
        for i in range(n):
            t = (i + 0.5 + rng.uniform(-jitter, jitter)) / n
            x, y = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
            L = length * rng.uniform(0.7, 1.2)
            tip = (x + nx * L + dx * L * lean, y + ny * L + dy * L * lean)
            out.append([(x - dx * w / 2, y - dy * w / 2), tip, (x + dx * w / 2, y + dy * w / 2)])
    return out


def swell(line, w1, w2, bulge=0.0):
    """Outline around a polyline whose width tapers from w1 to w2 and swells by `bulge` midway."""
    left, right, n = [], [], len(line)
    for i, (x, y) in enumerate(line):
        (ax, ay), (bx, by) = line[max(i - 1, 0)], line[min(i + 1, n - 1)]
        nx, ny = unit(-(by - ay), bx - ax)
        t = i / (n - 1)
        w = (w1 + (w2 - w1) * t + bulge * math.sin(math.pi * t)) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


def bend(a, b, amount):
    """Control point for a curve from a to b, pushed sideways by `amount` (positive = right of a->b)."""
    nx, ny = unit(-(b[1] - a[1]), b[0] - a[0])
    return ((a[0] + b[0]) / 2 - nx * amount, (a[1] + b[1]) / 2 - ny * amount)


def segment(a, b, w1, w2, offset=(0, 0)):
    """bar() with the segment's edges, shifted sideways so a seg can sit on the near edge."""
    return bar(a[0] + offset[0], a[1] + offset[1], b[0] + offset[0], b[1] + offset[1], w1, w2)


def smoke(cx, cy, h, w, lean, curl=1.0, n=24):
    """A rising wisp of smoke: a smooth tapered S-curve from (cx, cy) upwards, bending back."""
    line = []
    for i in range(n):
        t = i / (n - 1)
        x = cx + lean * h * t * t + math.sin(t * math.pi * curl) * w * 0.5 * t
        line.append((x, cy - h * t))
    return taper(line, w, 3)


def oval(cx, cy, rx, ry, n=16, rot=0.0):
    c, s = math.cos(rot), math.sin(rot)
    return [(cx + rx * math.cos(a) * c - ry * math.sin(a) * s,
             cy + rx * math.cos(a) * s + ry * math.sin(a) * c)
            for a in (i * 2 * math.pi / n for i in range(n))]


def spots(cx, cy, rx, ry, n, rmin, rmax, color=PAPER, keep=None):
    """Random cream spots inside an ellipse (for the spider's abdomen)."""
    out = []
    for _ in range(n):
        a, r = rng.uniform(0, 2 * math.pi), math.sqrt(rng.uniform(0, 1))
        x, y = cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r
        if keep and not keep(x, y):
            continue
        out.append((path(knob(x, y, rng.uniform(rmin, rmax), 6, rng.uniform(0, 1))), color))
    return out


__all__ = ["INK", "PAPER", "part", "figure_rim", "curve_cut", "groove", "spikes", "segment",
           "smoke", "oval", "spots", "along", "unit", "swell", "bend"]


# ---------------------------------------------------------------- cats (tabby, wings, grass)

def rings(line, ts, width, depth=0.5, color=INK):
    """Tabby rings across a tapered strand: short bands at fractions `ts` along `line`."""
    out = []
    for t in ts:
        x, y, nx, ny = along(line, t)
        dx, dy = ny, -nx
        h = width / 2 + 6
        out.append((path([(x - nx * h - dx * depth * 6, y - ny * h - dy * depth * 6),
                          (x + nx * h - dx * depth * 4, y + ny * h - dy * depth * 4),
                          (x + nx * h + dx * depth * 10, y + ny * h + dy * depth * 10),
                          (x - nx * h + dx * depth * 8, y - ny * h + dy * depth * 8)]), color))
    return out


def stripe(a, c, b, w=7, color=INK):
    """One carved tabby stripe: a curved band, thick in the middle, pointed at both ends."""
    line = bezier(a, c, b, 12)
    return path(swell(line, 1.5, 1.5, w)), color


def feather(root, ang, length, w):
    """A single long flight feather: tapered, slightly curved, rounded at the root."""
    dx, dy = math.cos(ang), math.sin(ang)
    tip = (root[0] + dx * length, root[1] + dy * length)
    mid = (root[0] + dx * length * 0.5 - dy * length * 0.06, root[1] + dy * length * 0.5 + dx * length * 0.06)
    return swell(bezier(root, mid, tip, 10), w, 3, w * 0.25)


def wing(base, wrist, tip, n=8, lmin=60, lmax=150, ang=0.9, w=24, coverts=2, fan=0.35):
    """A feathered wing spread up behind the shoulder.

    The arm runs base -> wrist -> tip; flight feathers hang from it, pointing at `ang`
    (radians), longest towards the tip. Returns (polys, marks): covert rows as scalloped
    bands, plus a cream gouge along each feather shaft.
    """
    arm = bezier(base, wrist, tip, 16)
    polys, marks = [swell(arm, w * 1.2, w * 0.5, w * 0.3)], []
    for i in range(n):
        t = 0.25 + 0.75 * i / (n - 1)
        x, y, _, _ = along(arm, t)
        L = lmin + (lmax - lmin) * t
        a = ang - fan * t
        polys.append(feather((x, y), a, L, w))
        marks.append((path(taper(bezier((x, y), (x + math.cos(a) * L * 0.5, y + math.sin(a) * L * 0.5),
                                        (x + math.cos(a) * L * 0.85, y + math.sin(a) * L * 0.85), 6), 3, 0.8)),
                      PAPER))
    for row in range(coverts):
        for i in range(n + 2):
            t = 0.1 + 0.9 * i / (n + 1)
            x, y, _, _ = along(arm, t)
            off = 14 + row * 22
            cx, cy = x + math.cos(ang) * off, y + math.sin(ang) * off
            polys.append(oval(cx, cy, w * 0.75, w * 0.55, 10, ang))
            marks.append((sliver(cx - math.cos(ang) * 4, cy - math.sin(ang) * 4, ang, w * 0.7, 4), INK))
    return polys, marks


def blades(x, y, n, h, spread=50, lean=-0.2):
    """A grass tuft: n tapered blades fanning up from around (x, y)."""
    out = []
    for i in range(n):
        bx = x + (i / max(1, n - 1) - 0.5) * spread * 0.5 + rng.uniform(-4, 4)
        a = -math.pi / 2 + lean + (i / max(1, n - 1) - 0.5) * 1.2 + rng.uniform(-0.15, 0.15)
        L = h * rng.uniform(0.6, 1.0)
        tip = (bx + math.cos(a) * L, y + math.sin(a) * L)
        c = (bx + math.cos(a) * L * 0.5 - 6, y + math.sin(a) * L * 0.5)
        out.append(taper(bezier((bx, y), c, tip, 8), 7, 1))
    return out


def whiskers(p, root, n=3, length=60, ang=math.pi + 0.15, spread=0.35, w=2.6, color=PAPER):
    """Thin cream whiskers fanning out from the muzzle; not part of the figure rim."""
    for i in range(n):
        a = ang + spread * (i / max(1, n - 1) - 0.5)
        tip = (root[0] + math.cos(a) * length, root[1] + math.sin(a) * length)
        c = (root[0] + math.cos(a) * length * 0.5, root[1] + math.sin(a) * length * 0.5 - 5)
        p.fill(path(taper(bezier(root, c, tip, 8), w, 0.6)), color)
