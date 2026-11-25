"""Linocut v2 helpers (skeleton, goblin): one shared paper rim, form-following gouges, fine parts.

`Print2` keeps the cream paper rim of every part in one layer *under* the whole figure, so
overlapping parts no longer show cream seams. The rim of each part still sits in its own
sub-group (`rim_<part>`, same pivot), so a Godot rig can move it together with the part.

The shading helpers carve along a curve instead of a straight line: the shadow edge bends
with the form, the gouges point into the shadow, and extra rows of short cream cuts follow
the same curve, like contour carving in a real block.
"""
import math
from contextlib import contextmanager

from style import INK, OUT, PAPER, Print, bezier, knob, path, rng, rough, sliver, taper

# ---------------------------------------------------------------- print with one rim layer


def orient(poly):
    """The polygon wound clockwise. rsvg merges clipPath children with the nonzero rule, so
    overlapping polygons of opposite winding would cut holes into a part's clip."""
    area = sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]))
    return list(poly) if area > 0 else list(reversed(poly))


class Print2(Print):
    def __init__(self, *a, **kw):
        super().__init__(*a, **kw)
        self.rim_stack = [("", None, [])]
        self.rim_layers = []

    @contextmanager
    def group(self, name, pivot, offset=(0, 0)):
        """A movable part; `offset` shifts everything drawn inside (and its pivot) as one piece."""
        outer = getattr(self, "off", (0, 0))
        total = (outer[0] + offset[0], outer[1] + offset[1])
        pivot = (pivot[0] + total[0], pivot[1] + total[1])
        self.rim_stack.append((name, pivot, []))
        self.off = total
        with super().group(name, pivot):
            yield
        self.off = outer
        name_, pv, items = self.rim_stack.pop()
        if total != (0, 0):
            items = [f'<g transform="translate({total[0]},{total[1]})">' + "".join(items) + "</g>"]
        if offset != (0, 0):
            t = f'<g transform="translate({offset[0]},{offset[1]})">'
            parent = self.cur["body"]
            g = parent[-1]
            head_end = g.index(">") + 1
            parent[-1] = g[:head_end] + t + g[head_end:-4] + "</g></g>"
        self.rim_layers.append((name_, pv, items))

    def part(self, polys, shade=None, marks=(), color=None, sw=6, reg=(5, 4), rim=True):
        polys = [orient(q) for q in polys]
        super().part(polys, shade, marks, color, sw, reg, rim=False)
        if rim:
            ds = "".join(f'<path d="{path(rough(p, amp=1.0))}"/>' for p in polys)
            self.rim_stack[-1][2].append(f'<g fill="{PAPER}" stroke="{PAPER}" stroke-width="{2 * sw + 12}" '
                                         f'stroke-linejoin="round">{ds}</g>')

    def rim(self, d, width=12):
        self.rim_stack[-1][2].append(f'<path d="{d}" fill="{PAPER}" stroke="{PAPER}" '
                                     f'stroke-width="{width}" stroke-linejoin="round"/>')

    def _rim_svg(self):
        out = "".join(self.rim_stack[0][2])
        for name, (px, py), items in self.rim_layers:
            px, py = px * self.zoom + self.shift[0], py * self.zoom + self.shift[1]
            out += f'<g id="rim_{name}" data-pivot="{px:.0f},{py:.0f}">{"".join(items)}</g>'
        return f'<g id="paper_rim">{out}</g>'

    def save(self, name):
        import subprocess
        root = self.stack[0]
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
               f'viewBox="0 0 {self.w} {self.h}"><defs>{"".join(self.defs)}</defs>'
               f'<g transform="translate({self.shift[0]},{self.shift[1]}) scale({self.zoom})">'
               f'{self._rim_svg()}{"".join(root["body"])}</g></svg>')
        src = OUT / f"{name}.svg"
        src.write_text(svg)
        subprocess.run(["rsvg-convert", str(src), "-o", str(OUT / f"{name}.png")], check=True)


# ---------------------------------------------------------------- curved carving (pure)

def _normal_toward(p0, p1, toward):
    tx, ty = p1[0] - p0[0], p1[1] - p0[1]
    L = math.hypot(tx, ty) or 1
    nx, ny = -ty / L, tx / L
    if nx * toward[0] + ny * toward[1] < 0:
        nx, ny = -nx, -ny
    return nx, ny


def curve_cut(a, c, b, toward=(1, 0.6), count=6, lmin=8, lmax=20, w=5, rows=1, gap=9, E=700):
    """Black shadow beyond the curve a-c-b plus gouges into it and contour cuts along it."""
    pts = bezier(a, c, b, 18)
    (x0, y0), (x1, y1) = pts[0], pts[-1]
    t0 = (pts[1][0] - x0, pts[1][1] - y0)
    t1 = (x1 - pts[-2][0], y1 - pts[-2][1])
    L0, L1 = math.hypot(*t0) or 1, math.hypot(*t1) or 1
    head = (x0 - t0[0] / L0 * E, y0 - t0[1] / L0 * E)
    tail = (x1 + t1[0] / L1 * E, y1 + t1[1] / L1 * E)
    line = [head] + pts + [tail]
    tl = math.hypot(*toward)
    dx, dy = toward[0] / tl * E, toward[1] / tl * E
    shade = path(line + [(x + dx, y + dy) for x, y in reversed(line)])
    marks = []
    for i in range(count):
        k = min(len(pts) - 2, int((i + 0.5 + rng.uniform(-0.3, 0.3)) / count * (len(pts) - 1)))
        (px, py), q = pts[k], pts[k + 1]
        nx, ny = _normal_toward(pts[k], q, toward)
        ang = math.atan2(ny, nx) + rng.uniform(-0.2, 0.2)
        marks.append((sliver(px - nx * 3, py - ny * 3, ang, rng.uniform(lmin, lmax), w * rng.uniform(0.7, 1.1)),
                      PAPER))
    for r in range(1, rows + 1):
        marks += contour_dashes(pts, toward, r * gap + lmin * 0.6, w * 0.55)
    return shade, marks


def contour_dashes(pts, toward, offset, w, keep=0.6):
    """Short tapered cream cuts running parallel to a curve, `offset` into its shadow side."""
    marks, n = [], len(pts)
    shifted = []
    for i in range(n):
        nx, ny = _normal_toward(pts[max(i - 1, 0)], pts[min(i + 1, n - 1)], toward)
        shifted.append((pts[i][0] + nx * offset, pts[i][1] + ny * offset))
    i = 0
    while i < n - 3:
        run = rng.randint(3, 5)
        if rng.random() < keep:
            seg = shifted[i:i + run]
            if len(seg) >= 2:
                marks.append((path(taper(seg, w, 0.8)), PAPER))
        i += run
    return marks


def ink_line(a, c, b, w=3.0, w2=0.8):
    """A thin carved black line (muscle edge, crease, crack) as a mark."""
    return (path(taper(bezier(a, c, b, 10), w, w2)), INK)


def paper_line(a, c, b, w=3.0, w2=0.8):
    """A thin cream gouge line as a mark."""
    return (path(taper(bezier(a, c, b, 10), w, w2)), PAPER)


def midpoint(a, b, bend=0.0):
    """The midpoint of a-b pushed sideways by `bend` (a fraction of the length)."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1) or 1
    return ((x1 + x2) / 2 - (y2 - y1) / L * bend * L, (y1 + y2) / 2 + (x2 - x1) / L * bend * L)


def waisted(line, w, waist=0.7):
    """A closed outline around a polyline, w wide at both ends and narrower (waist * w) in the middle."""
    left, right, n = [], [], len(line)
    for i, (x, y) in enumerate(line):
        (ax, ay), (bx, by) = line[max(i - 1, 0)], line[min(i + 1, n - 1)]
        L = math.hypot(bx - ax, by - ay) or 1
        nx, ny = -(by - ay) / L, (bx - ax) / L
        t = i / (n - 1)
        h = w * (1 - (1 - waist) * math.sin(math.pi * t)) / 2
        left.append((x + nx * h, y + ny * h))
        right.append((x - nx * h, y - ny * h))
    return left + right[::-1]


def scaled(pts, k, c):
    """Points scaled by k around centre c."""
    return [(c[0] + (x - c[0]) * k, c[1] + (y - c[1]) * k) for x, y in pts]


# ---------------------------------------------------------------- primitives

def long_bone(p, a, b, w, ends=1.6, sw=3.5, color=None, toward=(1, 0.5), knobs=(True, True)):
    """A long bone: a slim shaft with double knobs (epiphyses) at both ends."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1)
    ux, uy = (x2 - x1) / L, (y2 - y1) / L
    nx, ny = -uy, ux
    polys = [waisted(bezier(a, midpoint(a, b, 0.02), b, 10), w, 0.72)]
    r = w * ends * 0.5
    for (cx, cy), on in zip(((x1, y1), (x2, y2)), knobs):
        if on:
            polys += [knob(cx + nx * r * 0.55, cy + ny * r * 0.55, r * 0.8, 7, 0.2),
                      knob(cx - nx * r * 0.55, cy - ny * r * 0.55, r * 0.8, 7, 0.5)]
    if nx * toward[0] + ny * toward[1] < 0:
        nx, ny = -nx, -ny
    o = w * 0.22
    s0, s1 = (x1 + nx * o, y1 + ny * o), (x2 + nx * o, y2 + ny * o)
    shade, marks = curve_cut(s0, midpoint(s0, s1, 0.03), s1, toward=toward, count=max(2, int(L / 18)),
                             lmin=w * 0.25, lmax=w * 0.5, w=w * 0.25)
    p.part(polys, shade, marks, color=color, sw=sw, rim=True)


def form(p, polys, curve, toward=(1, 0.6), marks=(), color=None, sw=5, rows=1, count=6,
         lmin=8, lmax=20, w=5, gap=9):
    """Any solid shape shaded along a curved light/shadow line with contour cuts."""
    polys = [polys] if isinstance(polys[0][0], (int, float)) else polys
    shade, m = curve_cut(*curve, toward=toward, count=count, lmin=lmin, lmax=lmax, w=w, rows=rows, gap=gap)
    p.part(polys, shade, m + list(marks), color=color, sw=sw)


def curved_rib(a, c, b, w):
    return taper(bezier(a, c, b, 12), w, w * 0.55)


def finger_bones(p, at, angle, fingers=4, length=42, spread=0.9, w=6, curl=0.3, color=PAPER, sw=2.5,
                 palm=10):
    """A bony hand: a small palm and segmented, slightly curling fingers."""
    hx, hy = at
    polys = [knob(hx, hy, palm, 6, 0.2)]
    joints = []
    for i in range(fingers):
        a = angle + spread * (i / max(1, fingers - 1) - 0.5)
        mid = (hx + math.cos(a) * length * 0.55, hy + math.sin(a) * length * 0.55)
        tip = (hx + math.cos(a + curl) * length, hy + math.sin(a + curl) * length)
        polys.append(taper(bezier((hx, hy), mid, tip, 8), w, w * 0.45))
        joints.append(mid)
    marks = [(path(knob(x, y, w * 0.45, 5)), INK) for x, y in joints]
    p.part(polys, marks=marks, color=color, sw=sw)


def bony_foot(p, ankle, toe_x, color=None, sw=3, toes=4):
    """A bony foot pointing left: heel knob, a small tarsal block and toe strands fanning out."""
    ax, ay = ankle
    ground = ay + 20
    heel = knob(ax + 8, ground - 8, 8, 6, 0.3)
    tarsal = [(ax - 10, ay + 2), (ax + 10, ay), (ax + 14, ground - 4), (ax - 14, ground - 4)]
    polys = [heel, tarsal]
    for i in range(toes):
        y = ground - 3 + i * 0.5
        sx = ax - 8 - i * 2
        tip = (toe_x + i * 7, ground + 1)
        polys.append(taper(bezier((sx, ay + 6 + i * 3), ((sx + tip[0]) / 2, y - 6 + i), tip, 8), 6, 3))
    marks = [(path(knob(ax - 4, ay + 8, 3, 5)), INK)]
    p.part(polys, marks=marks, color=color, sw=sw)


def sinew(p, a, b, w1, w2=None, bulge=1.2, at=0.4, toward=(1, 0.5), sw=4.5, color=None, marks=(), rows=1):
    """A wiry, muscled limb segment shaded along a curve offset into its shadow side."""
    from style import bulged
    w2 = w1 if w2 is None else w2
    poly = bulged(a, b, w1, w2, bulge, at)
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1) or 1
    nx, ny = -(y2 - y1) / L, (x2 - x1) / L
    if nx * toward[0] + ny * toward[1] < 0:
        nx, ny = -nx, -ny
    o = max(w1, w2) * 0.15
    s0, s1 = (x1 + nx * o, y1 + ny * o), (x2 + nx * o, y2 + ny * o)
    shade, m = curve_cut(s0, midpoint(s0, s1, -0.06), s1, toward=toward, count=max(2, int(L / 16)),
                         lmin=w1 * 0.25, lmax=w1 * 0.5, w=max(2.5, w1 * 0.18), rows=rows, gap=w1 * 0.22)
    p.part([poly], shade, m + list(marks), color=color, sw=sw)


def wrap_lines(a, b, w, n=4, slant=0.35):
    """Diagonal black bands across a segment a-b of width w: cloth wrappings on shins and grips."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1) or 1
    ux, uy = (x2 - x1) / L, (y2 - y1) / L
    nx, ny = -uy, ux
    out = []
    for i in range(n):
        t = (i + 0.5) / n
        cx, cy = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
        p0 = (cx - nx * w + ux * w * slant, cy - ny * w + uy * w * slant)
        p1 = (cx + nx * w - ux * w * slant, cy + ny * w - uy * w * slant)
        out.append((path(taper([p0, (cx, cy), p1], 3.2, 2.2)), INK))
    return out
