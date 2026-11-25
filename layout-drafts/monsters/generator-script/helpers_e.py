"""Linocut helpers for the armoured and spectral warriors (cursed knight, fallen paladin, wraith blade).

Built on `Print2` (one paper rim under the whole figure) and the curved carving from helpers_a:
plated limbs with seam lines and rivets, a generic notched sword, a kite shield, solid smoke
plumes (tapered wavy strands like the banshee's hair, not thin quills) and torn hems.
"""
import math

from helpers_a import curve_cut, form, ink_line, midpoint, paper_line, sinew
from helpers_b import spline, wave
from style import INK, PAPER, bezier, knob, path, rng, rough, sliver, taper


def frame(a, b):
    """Length, unit direction and unit normal of the segment a-b."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1) or 1
    u = ((x2 - x1) / L, (y2 - y1) / L)
    return L, u, (-u[1], u[0])


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


# ---------------------------------------------------------------- marks (pure)

def seam(a, b, t, w, sag=4, width=3.0, color=INK):
    """A curved plate seam across the segment a-b at fraction t, w wide, sagging towards b."""
    L, u, n = frame(a, b)
    cx, cy = lerp(a, b, t)
    s = (cx + n[0] * w / 2, cy + n[1] * w / 2)
    e = (cx - n[0] * w / 2, cy - n[1] * w / 2)
    c = (cx + u[0] * sag, cy + u[1] * sag)
    return (path(taper(bezier(s, c, e, 10), width, width * 0.7)), color)


def rivets(pts, r=2.6, color=PAPER):
    return [(path(knob(x, y, r, 5, 0.4)), color) for x, y in pts]


def scratches(cx, cy, rx, ry, n, color=PAPER, w=2.2):
    """Short random nicks and scratches inside an ellipse: battered metal."""
    marks = []
    for _ in range(n):
        a, r = rng.uniform(0, 2 * math.pi), rng.uniform(0, 1) ** 0.5
        x, y = cx + math.cos(a) * rx * r, cy + math.sin(a) * ry * r
        marks.append((sliver(x, y, rng.uniform(-0.6, 0.6) + math.pi * rng.choice((0, 1)), rng.uniform(5, 11), w),
                      color))
    return marks


# ---------------------------------------------------------------- shapes (pure)

def plume(root, tip, w, amp, phase=0.0, waves=1.2, n=9):
    """A solid smoke tendril: a wavy strand tapering from w at the root to a point."""
    return taper(spline(wave(root, tip, amp, waves=waves, n=n, phase=phase), 4), w, 2)


def plume_line(root, tip, amp, phase=0.0, waves=1.2, n=9):
    return spline(wave(root, tip, amp, waves=waves, n=n, phase=phase), 4)


def torn_hem(a, b, n, depth, lean=(0.2, 1.0), jag=0.35):
    """Points from a to b with n ragged tatters hanging past the line (leaning by `lean`)."""
    pts = []
    for i in range(n * 2 + 1):
        x, y = lerp(a, b, i / (n * 2))
        if i % 2:
            d = depth * rng.uniform(0.55, 1.15)
            x, y = x + lean[0] * d, y + lean[1] * d
        else:
            d = depth * rng.uniform(0, jag)
            x, y = x + lean[0] * d, y + lean[1] * d
        pts.append((x, y))
    return pts


def kite_outline(cx, cy, w, h, n=10):
    """A kite shield: slightly arched top, sides curving down to a point."""
    top = [(cx - w / 2 + w * i / n, cy - h * 0.42 - math.sin(math.pi * i / n) * h * 0.05) for i in range(n + 1)]
    right = bezier((cx + w / 2, cy - h * 0.42), (cx + w * 0.52, cy + h * 0.18), (cx, cy + h * 0.58), 12)[1:]
    left = bezier((cx, cy + h * 0.58), (cx - w * 0.52, cy + h * 0.18), (cx - w / 2, cy - h * 0.42), 12)[1:-1]
    return top + right + left


# ---------------------------------------------------------------- parts

def plated(p, a, b, w1, w2=None, seams=(0.35, 0.7), bulge=1.08, toward=(1, 0.5), color=None,
           rivet=True, extra=(), sw=4.5):
    """An armoured limb segment: a slightly swelling plate with curved seams and rivets."""
    w2 = w1 if w2 is None else w2
    marks = [seam(a, b, t, (w1 + (w2 - w1) * t) * 1.05) for t in seams]
    if rivet:
        L, u, n = frame(a, b)
        pts = []
        for t in seams:
            cx, cy = lerp(a, b, t + 0.08)
            w = (w1 + (w2 - w1) * t) * 0.32
            pts += [(cx + n[0] * w, cy + n[1] * w)]
        marks += rivets(pts, 2.2)
    sinew(p, a, b, w1, w2, bulge=bulge, toward=toward, sw=sw, color=color, marks=list(extra) + marks)


def joint_cap(p, at, r, color=None, toward=(1, 0.5), sw=4):
    """A round couter / poleyn (elbow or knee plate) with a ridge and a rivet."""
    x, y = at
    poly = knob(x, y, r, 9, 0.2)
    marks = [(path(knob(x - r * 0.15, y - r * 0.15, r * 0.25, 5)), PAPER),
             ink_line((x - r * 0.8, y + r * 0.1), (x, y - r * 0.5), (x + r * 0.8, y + r * 0.1), 2.5)]
    form(p, [poly], ((x + r * 0.1, y - r), (x + r * 0.7, y), (x, y + r)), toward=toward, marks=marks,
         color=color, sw=sw, rows=0, count=2, lmin=3, lmax=6, w=2.5)


def sword(p, hand, ang, length, width, color=PAPER, notches=(), guard=24, grip=26, marks=(), sw=3.5,
          edge_color=INK, pommel=7, shaded=True):
    """A straight blade from the hand along `ang` (radians): guard, grip, pommel and nicked edges.
    `notches` are fractions along the blade where the near edge is chipped."""
    hx, hy = hand
    ux, uy = math.cos(ang), math.sin(ang)
    nx, ny = -uy, ux
    gx, gy = hx + ux * 14, hy + uy * 14
    tx, ty = gx + ux * length, gy + uy * length
    steps = 10
    near, far = [], []
    for k in range(steps + 1):
        t = k / steps
        d = length * t * 0.93
        half = width / 2 * (1 - 0.25 * t)
        cut = 4 if any(abs(t - q) < 0.06 for q in notches) else 0
        near.append((gx + ux * d + nx * (half - cut), gy + uy * d + ny * (half - cut)))
        far.append((gx + ux * d - nx * half, gy + uy * d - ny * half))
    blade = near + [(tx, ty)] + far[::-1]
    fuller = paper_line((gx + ux * 12, gy + uy * 12), (gx + ux * length * 0.4, gy + uy * length * 0.4),
                        (gx + ux * length * 0.75, gy + uy * length * 0.75), 2.5, 1)
    shade = path([(gx, gy), (tx, ty), (tx - nx * 40, ty - ny * 40), (gx - nx * 40, gy - ny * 40)]) if shaded else None
    p.part([blade], shade, [fuller] + list(marks), color=color, sw=sw)
    g = [(gx + nx * guard, gy + ny * guard - 2), (gx + nx * guard + ux * 8, gy + ny * guard + uy * 8),
         (gx - nx * guard + ux * 8, gy - ny * guard + uy * 8), (gx - nx * guard, gy - ny * guard + 2)]
    gr = [(hx - ux * grip + nx * 5, hy - uy * grip + ny * 5), (gx + nx * 5, gy + ny * 5),
          (gx - nx * 5, gy - ny * 5), (hx - ux * grip - nx * 5, hy - uy * grip - ny * 5)]
    p.part([g, gr, knob(hx - ux * (grip + 4), hy - uy * (grip + 4), pommel, 6)], sw=sw, color=INK)
    return (gx, gy), (tx, ty)


def kite_shield(p, cx, cy, w, h, color=None, emblem=(), toward=(1, 0.4), sw=5, dents=4):
    """A battered kite shield with an inked border band and an optional emblem (marks)."""
    outer = kite_outline(cx, cy, w, h)
    inner = [(cx + (x - cx) * 0.84, cy + (y - cy) * 0.86 + 2) for x, y in outer]
    marks = scratches(cx, cy, w * 0.3, h * 0.35, dents) + list(emblem)
    form(p, [outer], ((cx + w * 0.12, cy - h * 0.55), (cx + w * 0.42, cy), (cx + w * 0.05, cy + h * 0.6)),
         toward=toward, marks=marks, color=color, sw=sw, rows=1, count=6, lmin=7, lmax=14, w=4, gap=9)
    p.fill(path(rough(outer, amp=0.6)) + path(rough(inner[::-1], amp=0.8)), INK)
    return outer


def smoke(p, roots, color=INK, sw=4, stroke_color=PAPER):
    """Solid smoke tendrils from a list of (root, tip, width, amp, phase); carved with cream streaks."""
    polys, marks = [], []
    for root, tip, w, amp, ph in roots:
        line = plume_line(root, tip, amp, ph)
        polys.append(taper(line, w, 2))
        inner = line[2:-4]
        if len(inner) > 3:
            marks.append((path(taper([(x + 2, y + 1) for x, y in inner], max(2.5, w * 0.18), 0.8)), stroke_color))
    p.part(polys, marks=marks, color=color, sw=sw)


def cloth(p, poly, curve, color=None, toward=(1, 0.4), folds=(), sw=4.5, count=6):
    """A cloth panel (cloak, tabard, skirt) shaded along a curve, with carved fold lines."""
    marks = [paper_line(a, c, b, 3, 0.8) for a, c, b in folds]
    form(p, [poly], curve, toward=toward, marks=marks, color=color, sw=sw, rows=1, count=count,
         lmin=8, lmax=18, w=4, gap=10)


def visor_slit(cx, cy, w, h=5, color=INK):
    return (path(rough([(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2 + 1), (cx + w / 2 - 2, cy + h / 2),
                        (cx - w / 2 + 2, cy + h / 2)], amp=0.6)), color)


__all__ = ["frame", "lerp", "seam", "rivets", "scratches", "plume", "plume_line", "torn_hem", "kite_outline",
           "plated", "joint_cap", "sword", "kite_shield", "smoke", "cloth", "visor_slit", "midpoint", "curve_cut"]


# ---------------------------------------------------------------- living-weapon details (pure)

def living_eye(cx, cy, r, ang=0.0, iris="#f0a030"):
    """An almond eye as marks: black lids, ember iris, black slit pupil, along direction `ang`."""
    ux, uy = math.cos(ang), math.sin(ang)
    nx, ny = -uy, ux

    def almond(rx, ry, k=14):
        top = [(cx + ux * rx * math.cos(t) + nx * ry * math.sin(t), cy + uy * rx * math.cos(t) + ny * ry * math.sin(t))
               for t in (math.pi * i / k for i in range(k + 1))]
        return top
    lid = almond(r * 1.5, r * 0.95)
    lid = lid + [(2 * cx - x, 2 * cy - y) for x, y in lid[1:-1]]
    iris_pts = knob(cx, cy, r * 0.72, 8, ang)
    pupil = [(cx + nx * r * 0.6, cy + ny * r * 0.6), (cx + ux * r * 0.18, cy + uy * r * 0.18),
             (cx - nx * r * 0.6, cy - ny * r * 0.6), (cx - ux * r * 0.18, cy - uy * r * 0.18)]
    return [(path(lid), INK), (path(iris_pts), iris), (path(pupil), INK),
            (path(knob(cx - ux * r * 0.25 - nx * r * 0.3, cy - uy * r * 0.25 - ny * r * 0.3, r * 0.16, 5)), PAPER)]


def rune_glyph(cx, cy, s, ang, color=INK, w=3.0):
    """A small angular rune (three carved strokes) at (cx, cy), size s, oriented along ang."""
    ux, uy = math.cos(ang), math.sin(ang)
    nx, ny = -uy, ux
    shapes = rng.choice([
        [((0, -1), (0, 1)), ((0, -0.2), (0.8, -0.9)), ((0, 0.3), (-0.7, 0.9))],
        [((-0.6, -1), (0.6, 1)), ((0.6, -1), (-0.6, 1)), ((-0.8, 0), (0.8, 0))],
        [((0, -1), (0, 1)), ((0, -1), (0.7, -0.3)), ((0.7, -0.3), (0, 0.3))],
        [((-0.7, -0.8), (0.7, -0.8)), ((0, -0.8), (0, 1)), ((-0.5, 0.4), (0.5, 0.9))],
    ])
    out = []
    for (a0, b0), (a1, b1) in shapes:
        x0, y0 = cx + (ux * a0 + nx * b0) * s, cy + (uy * a0 + ny * b0) * s
        x1, y1 = cx + (ux * a1 + nx * b1) * s, cy + (uy * a1 + ny * b1) * s
        out.append((path(taper([(x0, y0), (x1, y1)], w, w * 0.6)), color))
    return out


def shard(cx, cy, r, ang, stretch=1.8):
    """A floating diamond-shaped rune shard."""
    ux, uy = math.cos(ang), math.sin(ang)
    nx, ny = -uy, ux
    return [(cx + ux * r * stretch, cy + uy * r * stretch), (cx + nx * r, cy + ny * r),
            (cx - ux * r * stretch * 0.7, cy - uy * r * stretch * 0.7), (cx - nx * r, cy - ny * r)]
