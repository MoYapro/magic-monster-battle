"""Extra linocut helpers for the unicorns: horse legs and hooves, a spiral horn, flowing
mane/tail strands, eyes (open and closed) and a carved grass mound."""
import math

from helpers_b import rpart, shaded, spline, stroke, wave
from helpers_c import bend, oval, swell
from style import INK, PAPER, bezier, knob, path, rng, rough, sliver, taper

GOLD = "#e3c27a"
RAINBOW = ["#d6a3a6", "#e0b791", "#e3d391", "#aac29b", "#a1b9d0", "#b8a5cf"]  # muted, dusty


def horn(p, base, tip, width=24, turns=7):
    """A long cone from base to tip with diagonal carved spiral ridges."""
    (bx, by), (tx, ty) = base, tip
    L = math.hypot(tx - bx, ty - by)
    nx, ny = -(ty - by) / L, (tx - bx) / L
    cone = [(bx + nx * width / 2, by + ny * width / 2), (tx, ty), (bx - nx * width / 2, by - ny * width / 2)]
    marks = []
    for i in range(1, turns + 1):
        t = i / (turns + 1)
        w = width * (1 - t) / 2 + 1
        cx, cy = bx + (tx - bx) * t, by + (ty - by) * t
        a = (cx + nx * w, cy + ny * w)
        b = (cx - nx * w + (tx - bx) / L * w * 1.4, cy - ny * w + (ty - by) / L * w * 1.4)
        marks.append(stroke([a, b], max(2.2, 4.5 * (1 - t)), 1.0, INK))
    shade_line = [(bx - nx * width * 0.1, by - ny * width * 0.1), (tx, ty)]
    shade, gs = shaded(shade_line, (-nx, -ny), count=3, lmin=4, lmax=8, w=3)
    rpart(p, [cone], shade, marks + gs, color=GOLD, sw=3.5)


def leg(p, name, joints, widths, bends, color=None, toward=(1, 0.3), knobs=True, shade=True):
    """A horse leg as chained segments (upper, lower, cannon, ...), each its own pivot group.
    knobs=False and shade=False give a smooth, slim leg without the segmented look."""
    names = ("upper", "lower", "cannon", "pastern")
    for i, (a, b) in enumerate(zip(joints, joints[1:])):
        with p.group(f"{name}_{names[i]}", a):
            line = bezier(a, bend(a, b, bends[i]), b, 10)
            poly = swell(line, widths[i], widths[i + 1], widths[i] * 0.12)
            polys = [poly, knob(*b, widths[i + 1] * (0.55 if knobs else 0.5), 7 if knobs else 10)]
            cut = None, []
            if shade and color != INK:
                cut = shaded(_offset(line, toward, widths[i] * 0.28), toward, count=2, lmin=4, lmax=8, w=3.5)
            rpart(p, polys, cut[0], cut[1], color=color, sw=4.5)


def _offset(line, toward, d):
    tx, ty = toward
    L = math.hypot(tx, ty) or 1
    return [(x + tx / L * d, y + ty / L * d) for x, y in line]


def hoof(p, name, at, angle=0.0, size=17, color=INK):
    """A hoof: a short trapezoid under the fetlock, tilted by angle, with a carved rim line."""
    cx, cy = at
    c, s = math.cos(angle), math.sin(angle)

    def rot(x, y):
        return cx + x * c - y * s, cy + x * s + y * c
    shape = [rot(-size * 0.7, -size * 0.2), rot(size * 0.6, -size * 0.2), rot(size * 0.9, size * 0.8),
             rot(-size * 1.0, size * 0.8)]
    with p.group(name, at):
        marks = [stroke([rot(-size * 0.75, size * 0.25), rot(size * 0.7, size * 0.25)], 3, 2, PAPER)]
        rpart(p, [shape], None, marks, color=color, sw=4)


def strand_polys(roots_tips, width_scale=1.0):
    """Wavy tapered strands from (root, tip, width, amp, phase) tuples; returns (lines, polys)."""
    lines, polys = [], []
    for root, tip, w, amp, phase in roots_tips:
        ln = spline(wave(root, tip, amp, waves=1.2, n=9, phase=phase), 4)
        lines.append(ln)
        polys.append(taper(ln, w * width_scale, 2))
    return lines, polys


def hair(p, name, pivot, strands, under, toward=(0.3, 1), color=None, colors=None):
    """Mane or tail: carved strands with ink streaks and cream highlight cuts, shaded below `under`.
    With `colors`, each strand is its own colour block, cycling through the list."""
    with p.group(name, pivot):
        lines, polys = strand_polys(strands)
        shade, gs = shaded(under, toward, count=6, lmin=8, lmax=20, w=5)
        streaks = [[stroke(ln[3:-3], 2.6 if colors else 3.5, 1, INK)] for ln in lines]
        for i, ln in enumerate(lines):
            if i % 2 == 0:
                streaks[i].append(stroke([(x + 3, y - 3) for x, y in ln[3:-5]], 2.6, 0.8, PAPER))
        if not colors:
            rpart(p, polys, shade, gs + [m for st in streaks for m in st], color=color)
            return
        for i, (poly, st) in enumerate(zip(polys, streaks)):
            rpart(p, [poly], shade, st + (gs if i == 0 else []), color=colors[i % len(colors)])


def open_eye(cx, cy, size=9, angle=-0.25):
    """An almond eye (ink) with a cream glint, as part marks."""
    c, s = math.cos(angle), math.sin(angle)
    pts = [(-size, 0), (-size * 0.2, -size * 0.55), (size, -size * 0.1), (size * 0.1, size * 0.45)]
    eye = [(cx + x * c - y * s, cy + x * s + y * c) for x, y in pts]
    return [(path(eye), INK), (path(knob(cx - size * 0.15, cy - size * 0.12, size * 0.22, 5)), PAPER)]


def closed_eye(cx, cy, size=12, angle=-0.2):
    """A sleeping eye: a downward-curved lid line with a few lashes."""
    c, s = math.cos(angle), math.sin(angle)

    def rot(x, y):
        return cx + x * c - y * s, cy + x * s + y * c
    lid = bezier(rot(-size, 0), rot(0, size * 0.55), rot(size, 0), 8)
    marks = [stroke(lid, 4, 2, INK)]
    for k in (-0.5, 0.0, 0.5):
        x0, y0 = rot(k * size, size * 0.35)
        marks.append(stroke([(x0, y0), (x0 - 2, y0 + size * 0.45)], 2.4, 1, INK))
    return marks


def grass_mound(p, x0, x1, y, h=34, blades=26):
    """A carved black grass mound with cream gouged blades along its crest."""
    top = [(x0 + (x1 - x0) * t, y - h * math.sin(math.pi * t) ** 0.7) for t in (i / 16 for i in range(17))]
    body = top + [(x1 - 6, y + 22), (x0 + 6, y + 22)]
    blade_polys = []
    for _ in range(blades):
        t = rng.uniform(0.04, 0.96)
        bx = x0 + (x1 - x0) * t
        by = y - h * math.sin(math.pi * t) ** 0.7 + 3
        ang = -math.pi / 2 + rng.uniform(-0.6, 0.6)
        L = rng.uniform(14, 30)
        tip = (bx + math.cos(ang) * L, by + math.sin(ang) * L)
        blade_polys.append([(bx - 3.5, by), tip, (bx + 3.5, by)])
    d = path(rough(body, amp=2.5))
    with p.group("ground", ((x0 + x1) / 2, y)):
        p.rim(d, 12)
        for b in blade_polys:
            p.rim(path(b), 8)
        p.fill(d)
        for b in blade_polys:
            p.fill(path(b))
        for _ in range(int((x1 - x0) / 18)):
            gx = rng.uniform(x0 + 20, x1 - 20)
            p.fill(sliver(gx, y + rng.uniform(-h * 0.4, 12), -math.pi / 2 + rng.uniform(-0.5, 0.5),
                          rng.uniform(10, 20), 3.5), PAPER)


def mass(p, poly, under, toward=(0.25, 1), marks=(), color=None, count=7):
    """A body mass with a curved shadow below `under` and gouges along it."""
    shade, gs = shaded(under, toward, count=count, lmin=10, lmax=26, w=6)
    rpart(p, [poly], shade, list(marks) + gs, color=color)


def soft_head(p, at, tilt=0.0, scale=1.0, asleep=False):
    """A cute, rounded horse head facing left (round cranium, short muzzle, big gentle eye).
    Returns the forehead point where the horn sits, in canvas coordinates."""
    ox, oy = at
    c, s = math.cos(tilt), math.sin(tilt)

    def T(x, y):
        x, y = x * scale, y * scale
        return ox + x * c - y * s, oy + x * s + y * c

    def poly(pts):
        return [T(x, y) for x, y in pts]
    cranium = poly(oval(0, 0, 36, 33, 18))
    muzzle = poly(oval(-42, 30, 27, 21, 16, -0.45))
    bridge = poly([(-18, -30), (-62, 16), (-52, 48), (8, 34), (32, 4)])
    ear_far = poly([(18, -24), (30, -58), (38, -16)])
    ear = poly([(2, -26), (10, -62), (22, -24)])
    cheek = [T(x, y) for x, y in bezier((-38, 52), (30, 44), (36, -12), 10)]
    shade, marks = shaded(cheek, (math.cos(tilt) + 0.3, 0.8), count=3, lmin=5, lmax=10, w=3.5)
    marks += [(path(knob(*T(-60, 28), 4 * scale, 5)), INK),
              stroke([T(-62, 42), T(-52, 47), T(-42, 45)], 2.6, 1.4, INK),
              stroke([T(10, -56), T(13, -42)], 3.2, 1.5, INK),
              stroke([T(-26, -22), T(-44, 2), T(-54, 18)], 2.6, 1, PAPER)]
    marks += closed_eye(*T(-8, 6), 12 * scale, tilt - 0.3) if asleep else gentle_eye(*T(-8, 6), 10 * scale)
    rpart(p, [ear_far, cranium, muzzle, bridge, ear], shade, marks)
    return T(-12, -30)


def gentle_eye(cx, cy, r):
    """A big round dark eye with a cream glint and a short upper lash line."""
    return [(path(knob(cx, cy, r, 12, 0.0)), INK),
            (path(knob(cx - r * 0.35, cy - r * 0.35, r * 0.3, 6)), PAPER),
            (path(knob(cx + r * 0.3, cy + r * 0.3, r * 0.14, 5)), PAPER),
            stroke([(cx + r * 0.6, cy - r * 0.95), (cx + r * 1.25, cy - r * 1.2)], 2.6, 1, INK)]


__all__ = ["GOLD", "RAINBOW", "horn", "leg", "hoof", "hair", "open_eye", "closed_eye", "grass_mound", "mass", "soft_head", "gentle_eye", "oval",
           "bezier", "spline", "stroke", "rpart", "shaded", "path", "knob", "sliver", "INK", "PAPER"]
