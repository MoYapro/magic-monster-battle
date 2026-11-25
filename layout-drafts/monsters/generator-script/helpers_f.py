"""Linocut helpers for the robed casters (bone caller, frost mage, witch).

Cloth with torn hems and carved folds, wooden staffs, fur trim, beards, ice shards, bubbles and
a cauldron. Shapes are returned as point lists (pure) or drawn as one carved part via `form`.
"""
import math

from helpers_a import form, ink_line, paper_line
from helpers_b import spline
from style import INK, PAPER, bezier, knob, path, rng, sliver, taper


def hem(a, b, n, depth, lean=0.0, jag=0.5):
    """Points from a to b with n torn teeth hanging down, each `depth` deep (varied by `jag`)."""
    (x1, y1), (x2, y2) = a, b
    pts = []
    for i in range(n * 2 + 1):
        t = i / (n * 2)
        x, y = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
        if i % 2:
            d = depth * rng.uniform(1 - jag, 1 + jag * 0.4)
            x, y = x + lean * d, y + d
        pts.append((x, y))
    return pts


def folds(lines, w=4.0):
    """Carved fold creases: each line is (top, mid, bottom); black crease plus a cream gouge beside it."""
    marks = []
    for a, c, b in lines:
        marks.append(ink_line(a, c, b, w, 1.0))
        marks.append(paper_line((a[0] + 7, a[1] + 14), (c[0] + 7, c[1]), (b[0] + 6, b[1] - 10), w * 0.8, 0.8))
    return marks


def cloth(p, outline, curve, toward=(1, 0.35), fold_lines=(), marks=(), color=None, sw=5, count=7):
    """A robe or cloak panel: one carved shape shaded along a curve, with fold creases."""
    form(p, [outline], curve, toward=toward, marks=folds(fold_lines) + list(marks), color=color, sw=sw,
         rows=1, count=count, lmin=10, lmax=24, w=5, gap=10)


def staff(p, bottom, top, w=11, crook=0.0, knots=3, color=PAPER):
    """A wooden staff from bottom to top; `crook` bends it sideways, knots are carved bumps."""
    (x1, y1), (x2, y2) = bottom, top
    mid = ((x1 + x2) / 2 + crook, (y1 + y2) / 2)
    line = spline([bottom, ((x1 + mid[0]) / 2 - crook * 0.3, (y1 + mid[1]) / 2), mid,
                   ((x2 + mid[0]) / 2 + crook * 0.4, (y2 + mid[1]) / 2), top], 5)
    body = taper(line, w * 0.8, w)
    marks = []
    for i in range(knots):
        k = int(len(line) * (0.2 + 0.6 * (i + rng.uniform(0, 0.5)) / knots))
        x, y = line[k]
        marks.append((path(knob(x + w * 0.2, y, w * 0.28, 5)), INK))
    for i in range(0, len(line) - 6, 6):
        marks.append((path(taper(line[i:i + 5], 2.5, 0.8)), INK))
    form(p, [body], (line[0], line[len(line) // 2], line[-1]), toward=(1, 0.05), marks=marks, color=color,
         sw=3.5, rows=0, count=3, lmin=2, lmax=4, w=2)
    return line


def fur(line, w, tufts=None):
    """A fur trim band along a polyline with scalloped tufts on both edges (pure outline)."""
    n = len(line)
    left, right = [], []
    for i, (x, y) in enumerate(line):
        (ax, ay), (bx, by) = line[max(i - 1, 0)], line[min(i + 1, n - 1)]
        L = math.hypot(bx - ax, by - ay) or 1
        nx, ny = -(by - ay) / L, (bx - ax) / L
        bump = w * (0.62 if i % 2 else 0.42)
        left.append((x + nx * bump, y + ny * bump))
        right.append((x - nx * bump, y - ny * bump))
    return left + right[::-1]


def fur_marks(line, w, n=None):
    """Short ink tufts across a fur band."""
    marks = []
    step = max(1, len(line) // (n or len(line)))
    for i in range(0, len(line) - 1, step):
        (x, y), (bx, by) = line[i], line[i + 1]
        ang = math.atan2(by - y, bx - x) + math.pi / 2 + rng.uniform(-0.4, 0.4)
        marks.append((sliver(x, y, ang, w * 0.7, 3), INK))
    return marks


def shard(cx, cy, length, w, ang):
    """An ice shard: a long narrow diamond pointing along `ang`."""
    ux, uy = math.cos(ang), math.sin(ang)
    nx, ny = -uy, ux
    return [(cx + ux * length * 0.6, cy + uy * length * 0.6),
            (cx + nx * w / 2 + ux * length * 0.05, cy + ny * w / 2 + uy * length * 0.05),
            (cx - ux * length * 0.4, cy - uy * length * 0.4),
            (cx - nx * w / 2 - ux * length * 0.1, cy - ny * w / 2 - uy * length * 0.1)]


def crystal(cx, base_y, h, w):
    """A faceted crystal standing upright: pointed top, flat-ish base."""
    return [(cx, base_y - h), (cx + w * 0.5, base_y - h * 0.62), (cx + w * 0.38, base_y),
            (cx - w * 0.42, base_y), (cx - w * 0.5, base_y - h * 0.55)]


def strands(top, bottom, n, w, sway=10):
    """n beard or hair strand lines from a top edge down to a bottom edge, as cream marks."""
    (x1, y1), (x2, y2) = top
    (x3, y3), (x4, y4) = bottom
    marks = []
    for i in range(n):
        t = (i + 0.5) / n
        a = (x1 + (x2 - x1) * t, y1 + (y2 - y1) * t)
        b = (x3 + (x4 - x3) * t, y3 + (y4 - y3) * t)
        c = ((a[0] + b[0]) / 2 + rng.uniform(-sway, sway), (a[1] + b[1]) / 2)
        marks.append((path(taper(bezier(a, c, b, 8), w, 0.8)), INK))
    return marks


def bubble(cx, cy, r):
    return knob(cx, cy, r, 8, rng.uniform(0, 1))


def lit_edge(pts, inward=(1, 0), offset=9, w=4.0, rows=2, gap=8):
    """Rows of cream highlight cuts just inside a lit edge (for black cloth facing the light)."""
    from helpers_a import contour_dashes
    line = spline(pts, 6)
    marks = []
    for r in range(rows):
        marks += contour_dashes(line, inward, offset + r * gap, w * (1 - r * 0.3), keep=0.75)
    return marks


def spike(base, ang, length, w):
    """A crystal spike growing from `base` along `ang` (a shard whose back end sits on the base)."""
    cx, cy = base[0] + math.cos(ang) * length * 0.4, base[1] + math.sin(ang) * length * 0.4
    return shard(cx, cy, length, w, ang)


def spike_cluster(base, spikes):
    """A jagged ice cluster: spikes is a list of (angle, length, width) growing from one base point."""
    return [spike(base, a, L, w) for a, L, w in spikes]


def snowflake(cx, cy, r, w=None, rot=0.0):
    """A six-armed snowflake sigil as a list of thin bar polygons (arms with small side ticks)."""
    w = w or max(2.0, r * 0.22)
    polys = []
    for k in range(6):
        a = rot + k * math.pi / 3
        ux, uy = math.cos(a), math.sin(a)
        polys.append(taper([(cx, cy), (cx + ux * r, cy + uy * r)], w, w * 0.6))
        mx, my = cx + ux * r * 0.6, cy + uy * r * 0.6
        for s in (-1, 1):
            b = a + s * 0.8
            polys.append(taper([(mx, my), (mx + math.cos(b) * r * 0.35, my + math.sin(b) * r * 0.35)],
                               w * 0.7, w * 0.4))
    return polys


def rune_marks(a, b, n, h, color=PAPER):
    """Carved frost runes along a band from a to b: alternating angular glyphs and small snowflakes."""
    (x1, y1), (x2, y2) = a, b
    marks = []
    for i in range(n):
        t = (i + 0.5) / n
        x, y = x1 + (x2 - x1) * t, y1 + (y2 - y1) * t
        if i % 3 == 1:
            marks += [(path(q), color) for q in snowflake(x, y, h * 0.42, w=2.2)]
        else:
            s = h * 0.38
            kind = i % 2
            pts = [(x - s * 0.4, y + s), (x - s * 0.4, y - s)] if kind else [(x, y + s), (x, y - s)]
            marks.append((path(taper(pts, 2.6, 2.6)), color))
            tick = [(x - s * 0.4, y - s * 0.2), (x + s * 0.5, y - s * 0.8)] if kind else \
                   [(x - s * 0.5, y - s * 0.5), (x + s * 0.5, y + s * 0.1)]
            marks.append((path(taper(tick, 2.4, 2.0)), color))
    return marks


def swirl(center, n, r0, r1, turns=1.1, start=0.0, L0=14, L1=34, w0=6, w1=11):
    """Ice shards laid along a spiral around `center`, each pointing along the swirl (pure)."""
    out = []
    for i in range(n):
        t = i / max(1, n - 1)
        a = start + t * turns * 2 * math.pi
        r = r0 + (r1 - r0) * t
        x, y = center[0] + math.cos(a) * r, center[1] + math.sin(a) * r
        out.append(shard(x, y, L0 + (L1 - L0) * t, w0 + (w1 - w0) * t, a + math.pi / 2))
    return out
