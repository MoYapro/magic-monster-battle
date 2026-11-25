"""Linocut ground tiles: top-down 256x256 squares for the battle grid.

Same print language as the monsters (jittered carved edges, tapered gouges, a colour block
printed slightly out of register, black ink), but quieter: grounds sit under the monsters,
so they stay in mid and dark tones, use small marks and no big black masses.

A base tile is opaque and fills the square. An overlay (wet, burning, ...) is transparent and
is layered over any base. Marks keep a margin from the edges so neighbouring tiles don't
produce hard seams.
"""
import math
import random
import subprocess
from pathlib import Path

OUT = Path(__file__).parent.parent
S = 256
INK = "#17110c"
PAPER = "#f1e4c6"
MARGIN = 14
rng = random.Random(0)


# ---------------------------------------------------------------- geometry (pure)

def rough(pts, step=12, amp=1.8):
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


def path(pts, close=True):
    return "M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in pts) + ("Z" if close else "")


def blob(cx, cy, rx, ry, n=10, wobble=0.25, rot=0.0):
    """An irregular closed shape around (cx, cy): puddles, stones, scorch marks."""
    pts = []
    for i in range(n):
        a = rot + i * 2 * math.pi / n
        r = 1 + rng.uniform(-wobble, wobble)
        pts.append((cx + rx * r * math.cos(a), cy + ry * r * math.sin(a)))
    return pts


def sliver(x, y, ang, length, w):
    """A tapered gouge: wide at (x, y), pointed at the far end."""
    dx, dy = math.cos(ang), math.sin(ang)
    nx, ny = -dy * w / 2, dx * w / 2
    return [(x + nx, y + ny), (x + dx * length, y + dy * length), (x - nx, y - ny)]


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


def inside(x, y, margin=MARGIN):
    return margin <= x <= S - margin and margin <= y <= S - margin


def scatter(n, margin=MARGIN, min_dist=0):
    """n random points inside the margin, kept min_dist apart where possible."""
    pts = []
    for _ in range(n * 30):
        if len(pts) == n:
            break
        p = (rng.uniform(margin, S - margin), rng.uniform(margin, S - margin))
        if all(math.hypot(p[0] - q[0], p[1] - q[1]) >= min_dist for q in pts):
            pts.append(p)
    return pts


# ---------------------------------------------------------------- the tile

class Tile:
    def __init__(self, seed):
        rng.seed(seed)
        self.body = []

    def poly(self, pts, color, op=1.0, carve=True):
        d = path(rough(pts) if carve else pts)
        self.body.append(f'<path d="{d}" fill="{color}" opacity="{op}"/>')

    def block(self, pts, color, ink=INK, reg=(3, 2), op=1.0, ink_op=0.55, ink_w=2.5):
        """A carved colour block: a thin ink edge with the colour printed slightly offset."""
        d = path(rough(pts))
        self.body.append(f'<path d="{d}" fill="none" stroke="{ink}" stroke-width="{ink_w}" '
                         f'stroke-linejoin="round" opacity="{ink_op}"/>')
        self.body.append(f'<path d="{d}" fill="{color}" opacity="{op}" '
                         f'transform="translate({reg[0]},{reg[1]})"/>')

    def line(self, pts, color, w=2.5, op=1.0):
        self.body.append(f'<path d="{path(pts, close=False)}" fill="none" stroke="{color}" '
                         f'stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round" '
                         f'opacity="{op}"/>')

    def gouges(self, n, color, lmin=6, lmax=14, w=3.0, ang=None, spread=0.4, op=1.0, margin=MARGIN):
        """Small tapered carving marks scattered over the tile."""
        for x, y in scatter(n, margin):
            a = (ang if ang is not None else rng.uniform(0, 2 * math.pi)) + rng.uniform(-spread, spread)
            self.poly(sliver(x, y, a, rng.uniform(lmin, lmax), w * rng.uniform(0.7, 1.2)), color,
                      op, carve=False)

    def texture(self, color, ang=-0.35, rows=11, op=0.45, w=2.6):
        """Rows of short parallel tool marks, the background texture of a carved block."""
        gap = (S - 2 * MARGIN) / rows
        for r in range(rows):
            y = MARGIN + gap * (r + 0.5)
            x = MARGIN + rng.uniform(0, 14)
            while x < S - MARGIN - 12:
                length = rng.uniform(7, 15)
                yy = y + rng.uniform(-3, 3)
                self.poly(taper([(x, yy), (x + length * math.cos(ang), yy + length * math.sin(ang))],
                                w, 0.4), color, op, carve=False)
                x += length + rng.uniform(6, 16)

    def base(self, color, edge):
        """Opaque square with a faint carved inner edge so cells read as cells."""
        self.poly([(0, 0), (S, 0), (S, S), (0, S)], color, carve=False)
        m = 5
        self.line(rough([(m, m), (S - m, m), (S - m, S - m), (m, S - m)], step=20, amp=1.5)
                  + [(m, m)], edge, w=2, op=0.5)

    def save(self, name):
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{S}" height="{S}" '
               f'viewBox="0 0 {S} {S}">{"".join(self.body)}</svg>')
        src = OUT / f"{name}.svg"
        src.write_text(svg)
        subprocess.run(["rsvg-convert", str(src), "-o", str(OUT / f"{name}.png")], check=True)
