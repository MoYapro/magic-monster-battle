"""Shared pieces for the linocut obstacle prints, built on the monster generator's style.

Obstacles are drawn like the monsters (ink + colour block on cream paper, one paper rim
around the figure, light from the top left) on a 512 px per grid cell canvas. They do not
move, so each is one group `obstacle` pivoting at the middle of its base.
"""
import math
import subprocess
import sys
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(OUT.parent / "monsters" / "generator-script"))

from helpers_a import Print2, curve_cut, form, ink_line, paper_line  # noqa: E402,F401
from helpers_b import spline  # noqa: E402,F401
from helpers_c import oval, smoke, spots  # noqa: E402,F401
from helpers_f import crystal, shard  # noqa: E402,F401
from helpers_g import leaf, twig  # noqa: E402,F401
from helpers_h import boulder, crack, ellipse_pts  # noqa: E402,F401
from style import EMBER, INK, PAPER, bezier, flame_pts, knob, path, rng, rough, sliver, taper  # noqa: E402,F401

CELL = 512
LIGHT_SHADE = (1, 0.6)  # shadows fall to the bottom right


class ObstaclePrint(Print2):
    def __init__(self, color, cells=(1, 1), seed=0):
        super().__init__(color, CELL * cells[0], CELL * cells[1], seed=seed)
        self.cells = cells

    def save(self, name):
        root = self.stack[0]
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" '
               f'viewBox="0 0 {self.w} {self.h}"><defs>{"".join(self.defs)}</defs>'
               f'<g>{self._rim_svg()}{"".join(root["body"])}</g></svg>')
        src = OUT / f"{name}.svg"
        src.write_text(svg)
        subprocess.run(["rsvg-convert", str(src), "-o", str(OUT / f"{name}.png")], check=True)


# ---------------------------------------------------------------- pure geometry

def lerp(a, b, t):
    return a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t


def jag(a, b, n, depth, up=-1):
    """Points from a to b with n jagged teeth pointing `up` (-1) or down (+1): broken wood, ice."""
    pts = []
    for i in range(n * 2 + 1):
        x, y = lerp(a, b, i / (n * 2))
        if i % 2:
            y += up * depth * rng.uniform(0.5, 1.2)
        pts.append((x, y))
    return pts


def puff(cx, cy, r, lobes=6):
    """A cloud puff: a scalloped circle (spore clouds, smoke balls, snow)."""
    pts = []
    for i in range(lobes * 4):
        a = i * 2 * math.pi / (lobes * 4)
        bump = 1 + 0.18 * abs(math.sin(a * lobes / 2))
        pts.append((cx + r * bump * math.cos(a), cy + r * bump * math.sin(a)))
    return pts


def mound(x0, x1, y, h, bumps=3, peak=0.5):
    """A low heap from x0 to x1 standing on y, highest (h) near `peak`: sand, snow, ash."""
    top = []
    for i in range(25):
        t = i / 24
        hh = h * math.sin(math.pi * t) ** 0.8 * (1 - 0.25 * abs(t - peak))
        hh *= 1 + 0.07 * math.sin(t * math.pi * bumps * 2)
        top.append((x0 + (x1 - x0) * t, y - hh))
    return top + [(x1, y + 6), (x0, y + 6)]


# ---------------------------------------------------------------- carved pieces

def cast_shadow(p, cx, y, rx, ry=16):
    """The ink shadow the obstacle throws on the ground, offset towards the bottom right."""
    d = path(rough(oval(cx + rx * 0.12, y, rx, ry, 20), amp=2))
    p.rim(d)
    p.fill(d)
    for _ in range(max(2, int(rx / 40))):
        x = rng.uniform(cx - rx * 0.6, cx + rx * 0.5)
        p.fill(sliver(x, y + rng.uniform(-4, 6), rng.uniform(-0.08, 0.08), rng.uniform(16, 34), 3.5), PAPER)


def rock(p, poly, curve, color=None, cracks=1, facets=(), count=5, sw=5, extra=()):
    """A carved stone: curved shadow side, gouges, ink cracks and facet edges."""
    xs, ys = [q[0] for q in poly], [q[1] for q in poly]
    cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
    rw, rh = (max(xs) - min(xs)) * 0.3, (max(ys) - min(ys)) * 0.3
    marks = [(crack((cx - rw * rng.uniform(0.3, 1), cy - rh * rng.uniform(0.2, 0.9)),
                    (cx + rw * rng.uniform(0.1, 0.7), cy + rh * rng.uniform(0.2, 0.9)), kinks=2, w=4), INK)
             for _ in range(cracks)]
    marks += [ink_line(a, lerp(a, b, 0.5), b, 3.5, 1) for a, b in facets]
    form(p, poly, curve, toward=LIGHT_SHADE, color=color, sw=sw, count=count, lmin=8, lmax=20,
         marks=marks + list(extra))


def pebbles(p, spots_, color=None):
    """A few small stones lying around the base."""
    for x, y, r in spots_:
        poly = boulder(x, y, r, 7, 0.7, rng.uniform(0, 1))
        form(p, poly, ((x - r, y + r * 0.1), (x, y - r * 0.2), (x + r, y - r * 0.5)), color=color, sw=3,
             count=1, lmin=3, lmax=5, w=2, rows=0)


def grain_lines(a, b, n, spread, w=3.5, color=INK):
    """n long wavy grain cuts running parallel to a-b, spread across `spread` px."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1) or 1
    nx, ny = -(y2 - y1) / L, (x2 - x1) / L
    out = []
    for i in range(n):
        o = (i - (n - 1) / 2) / max(1, n - 1) * spread + rng.uniform(-4, 4)
        t0, t1 = rng.uniform(0.0, 0.2), rng.uniform(0.6, 1.0)
        s, e = lerp(a, b, t0), lerp(a, b, t1)
        s = (s[0] + nx * o, s[1] + ny * o)
        e = (e[0] + nx * o, e[1] + ny * o)
        c = lerp(s, e, 0.5)
        c = (c[0] + nx * rng.uniform(-6, 6), c[1] + ny * rng.uniform(-6, 6))
        out.append((path(taper(bezier(s, c, e, 10), w, 0.8)), color))
    return out


def end_rings(cx, cy, rx, ry, n=4, w=3):
    """Growth rings on a cut log end, as cream arcs."""
    out = []
    for i in range(1, n + 1):
        k = i / (n + 1)
        a0 = rng.uniform(0, 1)
        pts = ellipse_pts(cx, cy, rx * k, ry * k, a0, a0 + 2 * math.pi * 0.8, 16)
        out.append((path(taper(pts, w, 1)), PAPER))
    return out


def thread(p, line, w=2.2, halo=5):
    """A thin ink line with a narrow paper halo: web threads, cords, hairline twigs."""
    d = path(taper(line, w, w * 0.6))
    p.rim(d, width=halo)
    p.fill(d)


def smoke_wisps(p, roots, color=PAPER):
    """Rising smoke curls (cream parts with a thin ink edge)."""
    for x, y, h, w, lean in roots:
        p.part([smoke(x, y, h, w, lean, curl=1.4)], color=color, sw=3)
