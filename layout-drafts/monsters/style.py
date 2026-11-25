"""Two-colour linocut style: black plus one colour block per monster on warm cream paper.

Every edge is jittered so it looks carved, the colour block is printed slightly out of
register, the shadow side of each part is solid black with tapered cream gouges cut along
the light/shadow line, and each part carries its own cream paper rim so it can later be cut
out and moved on its own. Light comes from the top left, shadows fall to the bottom right.

A monster is drawn as named groups (`with p.group(name, pivot)`), one per body part that
should be able to move. The SVG groups carry `id` and `data-pivot` for the Godot rig later.
"""
import math
import random
import subprocess
from contextlib import contextmanager
from pathlib import Path

OUT = Path(__file__).parent / "out"
INK = "#17110c"
PAPER = "#f1e4c6"
EMBER = "#f0a030"
SHADOW = (0.86, 0.5)   # direction shadows fall towards (light from the top left)
rng = random.Random(0)


# ---------------------------------------------------------------- geometry (pure)

def rough(pts, step=14, amp=2.0):
    """Subdivide a closed polygon and jitter it, so edges look hand-carved."""
    out = []
    for i, (x1, y1) in enumerate(pts):
        x2, y2 = pts[(i + 1) % len(pts)]
        k = max(1, int(math.hypot(x2 - x1, y2 - y1) / step))
        for j in range(k):
            t = j / k
            out.append((x1 + (x2 - x1) * t + rng.uniform(-amp, amp),
                        y1 + (y2 - y1) * t + rng.uniform(-amp, amp)))
    return out


def path(pts):
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + "Z"


def sliver(x, y, ang, length, w):
    """A tapered gouge: wide at (x, y), pointed at the far end."""
    dx, dy = math.cos(ang), math.sin(ang)
    nx, ny = -dy * w / 2, dx * w / 2
    return (f"M{x + nx:.1f},{y + ny:.1f} L{x + dx * length:.1f},{y + dy * length:.1f} "
            f"L{x - nx:.1f},{y - ny:.1f}Z")


def bar(x1, y1, x2, y2, w1, w2=None):
    """A straight segment from (x1, y1) to (x2, y2), w1 wide at the start and w2 at the end."""
    w2 = w1 if w2 is None else w2
    L = math.hypot(x2 - x1, y2 - y1)
    nx, ny = -(y2 - y1) / L, (x2 - x1) / L
    return [(x1 + nx * w1 / 2, y1 + ny * w1 / 2), (x2 + nx * w2 / 2, y2 + ny * w2 / 2),
            (x2 - nx * w2 / 2, y2 - ny * w2 / 2), (x1 - nx * w1 / 2, y1 - ny * w1 / 2)]


def bulged(a, b, w1, w2, bulge=1.25, at=0.4):
    """A segment that swells in the middle, like a muscled limb."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1)
    nx, ny = -(y2 - y1) / L, (x2 - x1) / L
    mx, my = x1 + (x2 - x1) * at, y1 + (y2 - y1) * at
    wm = max(w1, w2) * bulge
    side = [(x1, y1, w1), (mx, my, wm), (x2, y2, w2)]
    return ([(x + nx * w / 2, y + ny * w / 2) for x, y, w in side]
            + [(x - nx * w / 2, y - ny * w / 2) for x, y, w in reversed(side)])


def knob(cx, cy, r, n=6, rot=0.3):
    """A small polygon 'circle': joints, eyes, palms, pommels."""
    return [(cx + r * math.cos(rot + i * 2 * math.pi / n), cy + r * math.sin(rot + i * 2 * math.pi / n))
            for i in range(n)]


def bezier(a, c, b, n=12):
    """Points along a quadratic curve from a over control c to b."""
    return [((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * c[0] + t * t * b[0],
             (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * c[1] + t * t * b[1])
            for t in (i / (n - 1) for i in range(n))]


def taper(line, w1, w2):
    """A closed outline around a polyline, w1 wide at its start and w2 at its end."""
    left, right, n = [], [], len(line)
    for i, (x, y) in enumerate(line):
        (ax, ay), (bx, by) = line[max(i - 1, 0)], line[min(i + 1, n - 1)]
        L = math.hypot(bx - ax, by - ay) or 1
        nx, ny = -(by - ay) / L, (bx - ax) / L
        w = (w1 + (w2 - w1) * i / (n - 1)) / 2
        left.append((x + nx * w, y + ny * w))
        right.append((x - nx * w, y - ny * w))
    return left + right[::-1]


def flame_pts(x, y, h, w, lean=0.0):
    """A teardrop flame standing on (x, y), h tall, w wide, its tip pushed sideways by lean."""
    tip = (x + lean * h, y - h)
    left = bezier((x - w / 2, y), (x - w * 0.62 + lean * h * 0.2, y - h * 0.55), tip, 8)
    right = bezier(tip, (x + w * 0.55 + lean * h * 0.45, y - h * 0.4), (x + w / 2, y), 8)
    return left + right[1:] + [(x + w * 0.2, y + w * 0.12), (x - w * 0.2, y + w * 0.12)]


# ---------------------------------------------------------------- shading (pure)

def cut(a, b, count=6, lmin=8, lmax=22, w=6, toward=(1, 1)):
    """Black shadow beyond line a-b (on the `toward` side) plus cream gouges cut into it."""
    (ax, ay), (bx, by) = a, b
    L = math.hypot(bx - ax, by - ay)
    tx, ty = (bx - ax) / L, (by - ay) / L
    nx, ny = -ty, tx
    if nx * toward[0] + ny * toward[1] < 0:
        nx, ny = -nx, -ny
    E = 1600
    half = [(ax - tx * E, ay - ty * E), (bx + tx * E, by + ty * E),
            (bx + tx * E + nx * E, by + ty * E + ny * E), (ax - tx * E + nx * E, ay - ty * E + ny * E)]
    marks = []
    for i in range(count):
        t = (i + 0.5 + rng.uniform(-0.3, 0.3)) / count
        x, y = ax + (bx - ax) * t, ay + (by - ay) * t
        ang = math.atan2(ny, nx) + rng.uniform(-0.25, 0.25)
        marks.append((sliver(x - nx * 3, y - ny * 3, ang, rng.uniform(lmin, lmax), w * rng.uniform(0.7, 1.1)), PAPER))
    return path(half), marks


def bar_cut(x1, y1, x2, y2, w, frac=0.05, count=None, **kw):
    """Shadow line along a bar's centre, shifted a little towards the bottom-right."""
    L = math.hypot(x2 - x1, y2 - y1)
    nx, ny = -(y2 - y1) / L, (x2 - x1) / L
    if nx + ny < 0:
        nx, ny = -nx, -ny
    o = w * frac
    count = count or max(2, int(L / 14))
    return cut((x1 + nx * o, y1 + ny * o), (x2 + nx * o, y2 + ny * o), count=count,
               lmin=w * 0.25, lmax=w * 0.5, w=w * 0.22, **kw)


def auto_cut(polys, depth=0.3, toward=SHADOW, count=None, lmin=10, lmax=26, w=6):
    """Shadow on the far `depth` share of the shapes along `toward`, with gouges along its edge."""
    dx, dy = toward
    L = math.hypot(dx, dy)
    dx, dy = dx / L, dy / L
    px, py = -dy, dx
    pts = [q for poly in polys for q in poly]
    along = [x * dx + y * dy for x, y in pts]
    across = [x * px + y * py for x, y in pts]
    s = max(along) - depth * (max(along) - min(along))
    lo, hi = min(across), max(across)
    a = (dx * s + px * lo, dy * s + py * lo)
    b = (dx * s + px * hi, dy * s + py * hi)
    count = count or max(3, int((hi - lo) / 24))
    return cut(a, b, count=count, lmin=lmin, lmax=lmax, w=w, toward=(dx, dy))


def teeth(x0, x1, y, n, length, down=True, w=None, color=PAPER):
    """A row of n pointed teeth between x0 and x1, as marks for a part."""
    w = w or (x1 - x0) / n * 0.8
    ang = math.pi / 2 if down else -math.pi / 2
    step = (x1 - x0) / n
    return [(sliver(x0 + step * (i + 0.5), y, ang, length, w), color) for i in range(n)]


# ---------------------------------------------------------------- the print

class Print:
    def __init__(self, color, w=512, h=512, seed=0, zoom=1.0, shift=(0, 0)):
        """zoom and shift place the whole drawing on the canvas; pivots are stored in canvas space."""
        rng.seed(seed)
        self.color, self.w, self.h = color, w, h
        self.zoom, self.shift = zoom, shift
        self.defs, self.n, self.ids = [], 0, set()
        self.stack = [{"halo": [], "body": []}]

    @property
    def cur(self):
        return self.stack[-1]

    @contextmanager
    def group(self, name, pivot):
        """Everything drawn inside belongs to one movable body part rotating around pivot."""
        assert name not in self.ids, f"duplicate part {name}"
        self.ids.add(name)
        g = {"halo": [], "body": []}
        self.stack.append(g)
        try:
            yield
        finally:
            self.stack.pop()
            px, py = pivot[0] * self.zoom + self.shift[0], pivot[1] * self.zoom + self.shift[1]
            self.cur["body"].append(f'<g id="{name}" data-pivot="{px:.0f},{py:.0f}">'
                                    f'{"".join(g["halo"] + g["body"])}</g>')

    def part(self, polys, shade=None, marks=(), color=None, sw=6, reg=(5, 4), rim=True):
        """Polygons unioned into one carved part: rim, outline, paper, offset colour, shadow, gouges."""
        color = color or self.color
        ds = "".join(f'<path d="{path(rough(p))}"/>' for p in polys)
        self.n += 1
        self.defs.append(f'<clipPath id="k{self.n}">{ds}</clipPath>')
        if rim:
            self.cur["halo"].append(f'<g fill="{PAPER}" stroke="{PAPER}" stroke-width="{2 * sw + 10}" '
                                    f'stroke-linejoin="round">{ds}</g>')
        self.cur["body"].append(f'<g fill="{INK}" stroke="{INK}" stroke-width="{2 * sw}" '
                                f'stroke-linejoin="round">{ds}</g><g fill="{PAPER}">{ds}</g>')
        inner = f'<g fill="{color}" transform="translate({reg[0]},{reg[1]})">{ds}</g>'
        if shade:
            inner += f'<path d="{shade}" fill="{INK}"/>'
        inner += "".join(f'<path d="{d}" fill="{c}"/>' for d, c in marks)
        self.cur["body"].append(f'<g clip-path="url(#k{self.n})">{inner}</g>')

    def fill(self, d, color=INK):
        self.cur["body"].append(f'<path d="{d}" fill="{color}"/>')

    def rim(self, d, width=10):
        self.cur["halo"].append(f'<path d="{d}" fill="{PAPER}" stroke="{PAPER}" '
                                f'stroke-width="{width}" stroke-linejoin="round"/>')

    def eye(self, cx, cy, r, color=EMBER):
        self.fill(path(knob(cx, cy, r, 5, 0.6)), color)

    def save(self, name):
        root = self.stack[0]
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
               f'viewBox="0 0 {self.w} {self.h}"><defs>{"".join(self.defs)}</defs>'
               f'<g transform="translate({self.shift[0]},{self.shift[1]}) scale({self.zoom})">'
               f'{"".join(root["halo"] + root["body"])}</g></svg>')
        src = OUT / f"{name}.svg"
        src.write_text(svg)
        subprocess.run(["rsvg-convert", str(src), "-o", str(OUT / f"{name}.png")], check=True)


# ---------------------------------------------------------------- body-part primitives

def ground(p, x0, x1, y):
    """A black carved ground band with horizontal cream gouges."""
    pts = [(x0, y + 4), (x0 + 60, y - 6), ((x0 + x1) / 2, y + 2), (x1 - 50, y - 8), (x1, y + 6),
           (x1 - 10, y + 24), (x0 + 10, y + 24)]
    d = path(rough(pts, amp=3))
    p.rim(d)
    p.fill(d)
    for _ in range(int((x1 - x0) / 30)):
        x = rng.uniform(x0 + 20, x1 - 40)
        p.fill(sliver(x, y + rng.uniform(4, 16), rng.uniform(-0.1, 0.1), rng.uniform(18, 40), 4), PAPER)


def bone(p, a, b, w1, w2=None, r1=0, r2=0, color=None):
    """A straight tapered segment with optional knob joints at its ends: bones, spider legs."""
    (x1, y1), (x2, y2) = a, b
    w2 = w1 if w2 is None else w2
    polys = [bar(x1, y1, x2, y2, w1, w2)]
    polys += [knob(x, y, r) for x, y, r in ((x1, y1, r1), (x2, y2, r2)) if r]
    shade, marks = bar_cut(x1, y1, x2, y2, max(w1, w2))
    p.part(polys, shade, marks, color=color)


def limb(p, a, b, w1, w2=None, bulge=1.25, color=None, joint=0):
    """A fleshy segment that swells in the middle: upper arms, thighs, shins, forearms."""
    w2 = w1 if w2 is None else w2
    polys = [bulged(a, b, w1, w2, bulge)]
    if joint:
        polys.append(knob(*b, joint, 7))
    shade, marks = bar_cut(*a, *b, max(w1, w2) * bulge, frac=0.12)
    p.part(polys, shade, marks, color=color)


def mass(p, polys, color=None, depth=0.3, marks=(), **kw):
    """Any solid blob (torso, head, skull, abdomen, foot) with an automatic shadow side."""
    polys = [polys] if isinstance(polys[0][0], (int, float)) else polys
    shade, m = auto_cut(polys, depth=depth, **kw)
    p.part(polys, shade, m + list(marks), color=color)


def strand(p, a, c, b, w1, w2=2, color=None, shade=True):
    """A curved tapered stroke: hair, horns, tusks, fangs, tails, tentacles, roots, twigs."""
    poly = taper(bezier(a, c, b), w1, w2)
    if shade:
        s, m = auto_cut([poly], depth=0.35, count=2, lmin=4, lmax=max(6, w1 * 0.5), w=max(2, w1 * 0.2))
        p.part([poly], s, m, color=color)
    else:
        p.part([poly], color=color)


def claw(p, at, angle, fingers=4, length=60, spread=1.2, w=12, palm=18, curl=0.25, color=PAPER):
    """A palm with fingers fanned around `angle`, each curling a little and ending in a point."""
    hx, hy = at
    polys = [knob(hx, hy, palm, 6, 0.2)]
    for i in range(fingers):
        a = angle + spread * (i / max(1, fingers - 1) - 0.5)
        tip = (hx + math.cos(a + curl) * length, hy + math.sin(a + curl) * length)
        mid = (hx + math.cos(a) * length * 0.6, hy + math.sin(a) * length * 0.6)
        polys.append(taper(bezier((hx, hy), mid, tip, 8), w, 1.5))
    shade, marks = auto_cut(polys, depth=0.35, count=3, lmin=6, lmax=14, w=4)
    p.part(polys, shade, marks, color=color)


def branch(p, a, b, w1, w2=None, color=None, grain=3):
    """A woody segment with bark grain gouged along its length."""
    (x1, y1), (x2, y2) = a, b
    w2 = w1 if w2 is None else w2
    polys = [bar(x1, y1, x2, y2, w1, w2)]
    shade, marks = bar_cut(x1, y1, x2, y2, max(w1, w2), frac=0.18)
    ang = math.atan2(y2 - y1, x2 - x1)
    L = math.hypot(x2 - x1, y2 - y1)
    nx, ny = -math.sin(ang), math.cos(ang)
    for _ in range(grain):
        t = rng.uniform(0.05, 0.6)
        o = rng.uniform(-0.3, 0.1) * w1
        x, y = x1 + (x2 - x1) * t + nx * o, y1 + (y2 - y1) * t + ny * o
        marks.append((sliver(x, y, ang + rng.uniform(-0.05, 0.05), L * rng.uniform(0.25, 0.4), 4), INK))
    p.part(polys, shade, marks, color=color)


def flame(p, x, y, h, w, lean=0.0, color=None, core=True):
    """A carved flame tongue; the hot core is left as bare paper."""
    poly = flame_pts(x, y, h, w, lean)
    shade, marks = auto_cut([poly], depth=0.3, count=3, lmin=8, lmax=20, w=5)
    if core:
        marks.append((path(flame_pts(x - w * 0.05, y - h * 0.04, h * 0.5, w * 0.4, lean * 0.6)), PAPER))
    p.part([poly], shade, marks, color=color)


def rag(p, top_l, top_r, length, tatters=5, color=INK):
    """A hanging cloth with a torn, toothed hem and long cream fold gouges."""
    (x0, y0), (x1, y1) = top_l, top_r
    hem = []
    for i in range(tatters * 2 + 1):
        t = i / (tatters * 2)
        deep = length * (1.0 if i % 2 else 0.6) * rng.uniform(0.8, 1.1)
        hem.append((x0 + (x1 - x0) * t, y0 + (y1 - y0) * t + deep))
    poly = [top_l, top_r] + hem[::-1]
    marks = [(sliver(x0 + (x1 - x0) * (i + 0.5) / tatters, y0 + 8, math.pi / 2 + rng.uniform(-0.15, 0.15),
                     length * rng.uniform(0.5, 0.8), 5), PAPER) for i in range(tatters)]
    p.part([poly], marks=marks, color=color)


def eyes(p, pts, r, color=EMBER):
    for x, y in pts:
        p.eye(x, y, r, color)
