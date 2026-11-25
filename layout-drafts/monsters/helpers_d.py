"""Extra linocut helpers for the troll and treant (v2).

Adds a print with one paper rim around the whole figure instead of one per part, shadows
bounded by curves instead of straight lines, and gouges that bend along the form.
"""
import math

from style import INK, OUT, PAPER, SHADOW, Print, bezier, knob, path, rng, rough, sliver, taper
import subprocess


class OuterRimPrint(Print):
    """A Print whose paper rim is collected under the whole figure, so parts show no seams."""

    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.outer = []

    def part(self, polys, shade=None, marks=(), color=None, sw=6, reg=(5, 4), rim=True):
        if rim:
            ds = "".join(f'<path d="{path(q)}"/>' for q in polys)
            self.outer.append(f'<g fill="{PAPER}" stroke="{PAPER}" stroke-width="{2 * sw + 12}" '
                              f'stroke-linejoin="round">{ds}</g>')
        super().part(polys, shade, marks, color, sw, reg, rim=False)

    def save(self, name):
        root = self.stack[0]
        body = "".join(self.outer + root["halo"] + root["body"])
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
               f'viewBox="0 0 {self.w} {self.h}"><defs>{"".join(self.defs)}</defs>'
               f'<g transform="translate({self.shift[0]},{self.shift[1]}) scale({self.zoom})">{body}</g></svg>')
        src = OUT / f"{name}.svg"
        src.write_text(svg)
        subprocess.run(["rsvg-convert", str(src), "-o", str(OUT / f"{name}.png")], check=True)


# ---------------------------------------------------------------- curves (pure)

def normals(line):
    """Unit normals along a polyline (rotated left of the walking direction)."""
    out, n = [], len(line)
    for i in range(n):
        (ax, ay), (bx, by) = line[max(i - 1, 0)], line[min(i + 1, n - 1)]
        L = math.hypot(bx - ax, by - ay) or 1
        out.append((-(by - ay) / L, (bx - ax) / L))
    return out


def facing(nrm, toward):
    """Flip a normal so it points towards `toward` (or downwards when the curve runs along `toward`)."""
    d = nrm[0] * toward[0] + nrm[1] * toward[1]
    if abs(d) < 0.3:
        d = nrm[0] * 0.2 + nrm[1]
    return nrm if d >= 0 else (-nrm[0], -nrm[1])


def sided(line, toward):
    """Normals along a polyline, all flipped to the same side: the one facing `toward` on average."""
    nrm = normals(line)
    ax, ay = sum(n[0] for n in nrm), sum(n[1] for n in nrm)
    L = math.hypot(ax, ay) or 1
    fx, fy = facing((ax / L, ay / L), toward)
    flip = fx * ax + fy * ay < 0
    return [(-x, -y) for x, y in nrm] if flip else nrm


def chain(pts, n=6):
    """A smooth polyline through joints, rounding each corner with a quadratic curve."""
    if len(pts) < 3:
        return list(pts)
    out = [pts[0]]
    for i in range(1, len(pts) - 1):
        a = ((pts[i - 1][0] + pts[i][0]) / 2, (pts[i - 1][1] + pts[i][1]) / 2)
        b = ((pts[i][0] + pts[i + 1][0]) / 2, (pts[i][1] + pts[i + 1][1]) / 2)
        out += bezier(a, pts[i], b, n)
    return out + [pts[-1]]


def swell(line, widths):
    """Closed outline around a polyline whose width follows `widths` (sampled evenly)."""
    k = len(widths) - 1
    def w_at(t):
        i = min(int(t * k), k - 1)
        f = t * k - i
        return widths[i] + (widths[i + 1] - widths[i]) * f
    left, right, n = [], [], len(line)
    for i, ((x, y), (nx, ny)) in enumerate(zip(line, normals(line))):
        w = w_at(i / (n - 1)) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


def curve_shade(line, toward=SHADOW, E=1600):
    """The region beyond a curve on the `toward` side, as a path: a curved light/shadow edge."""
    nrm = sided(line, toward)
    (fx, fy), (lx, ly) = line[0], line[-1]
    (n0x, n0y), (n1x, n1y) = nrm[0], nrm[-1]
    tx, ty = lx - fx, ly - fy
    L = math.hypot(tx, ty) or 1
    tx, ty = tx / L, ty / L
    far = [(lx + tx * E, ly + ty * E), (lx + tx * E + n1x * E, ly + ty * E + n1y * E),
           (fx - tx * E + n0x * E, fy - ty * E + n0y * E), (fx - tx * E, fy - ty * E)]
    return path(list(line) + far)


def gouge(a, c, b, w):
    """A curved tapered cream cut from a over c to b."""
    return path(taper(bezier(a, c, b, 8), w, 0.6))


def edge_gouges(line, toward=SHADOW, count=6, lmin=10, lmax=26, w=6, bend=0.35, color=PAPER):
    """Curved gouges starting on a light/shadow curve and bending into the shadow."""
    marks, n = [], len(line)
    nrm = sided(line, toward)
    for i in range(count):
        k = min(n - 1, int((i + 0.5 + rng.uniform(-0.3, 0.3)) / count * n))
        (x, y), (nx, ny) = line[k], nrm[k]
        L = rng.uniform(lmin, lmax)
        tx, ty = -ny, nx
        s = bend * rng.choice((-1, 1))
        a = (x - nx * 3, y - ny * 3)
        c = (x + nx * L * 0.55 + tx * L * s, y + ny * L * 0.55 + ty * L * s)
        b = (x + nx * L + tx * L * s * 0.4, y + ny * L + ty * L * s * 0.4)
        marks.append((gouge(a, c, b, w * rng.uniform(0.7, 1.1)), color))
    return marks


def offset(line, toward, d):
    """The polyline pushed d pixels along its normals on the `toward` side."""
    return [(x + nx * d, y + ny * d) for (x, y), (nx, ny) in
            zip(line, sided(line, toward))]


def grain(line, w, n=4, spread=0.35, length=(0.3, 0.7), color=INK, width=4):
    """Long cuts that run along a polyline: bark grain, muscle fibre, hair flow."""
    marks, pts = [], len(line)
    nrm = normals(line)
    for _ in range(n):
        o = rng.uniform(-spread, spread) * w
        t0 = rng.uniform(0, 1 - length[0])
        t1 = min(1.0, t0 + rng.uniform(*length))
        seg = [(x + nx * o, y + ny * o) for (x, y), (nx, ny) in
               zip(line[int(t0 * (pts - 1)):int(t1 * (pts - 1)) + 1], nrm[int(t0 * (pts - 1)):int(t1 * (pts - 1)) + 1])]
        if len(seg) >= 2:
            marks.append((path(taper(seg, width * rng.uniform(0.6, 1.2), 0.6)), color))
    return marks


def arcs(cx, cy, rx, ry, a0, a1, n=4, step=10, w=5, color=PAPER):
    """Concentric curved cuts around a round form: bellies, skulls, knots."""
    marks = []
    for i in range(n):
        k = 1 - i * step / max(rx, ry)
        jit = rng.uniform(-0.08, 0.08)
        pts = [(cx + rx * k * math.cos(a), cy + ry * k * math.sin(a))
               for a in (a0 + jit + (a1 - a0) * j / 10 for j in range(11))]
        marks.append((path(taper(pts, w, 0.6)), color))
    return marks


def wart(x, y, r):
    """A small raised wart: a black bump with a cream catch-light on its top-left."""
    return [(path(knob(x, y, r, 7, rng.uniform(0, 1))), INK),
            (path(knob(x - r * 0.3, y - r * 0.3, r * 0.38, 5, 0.4)), PAPER)]


def leaf_cluster(cx, cy, r, leaves=7, rot=0.0, squash=0.75):
    """A clump of pointed leaves around a centre: an irregular, scalloped polygon."""
    pts = []
    for i in range(leaves * 2):
        a = rot + (i + rng.uniform(-0.3, 0.3)) * math.pi / leaves
        rr = r * (rng.uniform(0.85, 1.12) if i % 2 == 0 else rng.uniform(0.66, 0.8))
        pts.append((cx + rr * math.cos(a), cy + rr * squash * math.sin(a)))
    return pts


def canopy_spots(cx, cy, rx, ry, n, rmin, rmax, upper_left=False):
    """Random cluster positions inside an ellipse; optionally only on its lit upper-left side."""
    out = []
    while len(out) < n:
        u, v = rng.uniform(-1, 1), rng.uniform(-1, 1)
        if u * u + v * v > 1 or (upper_left and u * 0.86 + v * 0.5 > 0.25):
            continue
        out.append((cx + u * rx, cy + v * ry, rng.uniform(rmin, rmax)))
    return out


def leaf_marks(cx, cy, r, n=6, color=PAPER):
    """Little paired leaf-vein cuts scattered inside a cluster."""
    marks = []
    for _ in range(n):
        x, y = cx + rng.uniform(-r, r) * 0.6, cy + rng.uniform(-r, r) * 0.45
        a = rng.uniform(-math.pi, math.pi)
        marks.append((sliver(x, y, a, rng.uniform(10, 18), 6), color))
        marks.append((sliver(x, y, a + 0.9, rng.uniform(8, 14), 5), color))
    return marks


# ---------------------------------------------------------------- body-part primitives

def sinew(p, joints, widths, color=None, toward=SHADOW, frac=0.18, gouges=None, extra=(), lmin=8, lmax=22):
    """A fleshy or woody segment along a bent polyline with a curved shadow and bent gouges."""
    line = chain(joints)
    poly = swell(line, widths)
    edge = offset(line, toward, max(widths) * frac)
    count = gouges or max(3, int(sum(math.dist(a, b) for a, b in zip(joints, joints[1:])) / 18))
    marks = edge_gouges(edge, toward, count, lmin, lmax, max(4, min(widths) * 0.14)) + list(extra)
    p.part([poly], curve_shade(edge, toward), marks, color=color)


def body(p, polys, edge, color=None, toward=SHADOW, count=8, lmin=12, lmax=30, w=7, extra=(), bend=0.35):
    """A big mass (torso, head, trunk) whose shadow edge is a hand-placed curve."""
    polys = [polys] if isinstance(polys[0][0], (int, float)) else polys
    edge = chain(edge, 8)
    marks = edge_gouges(edge, toward, count, lmin, lmax, w, bend) + list(extra)
    p.part(polys, curve_shade(edge, toward), marks, color=color)
