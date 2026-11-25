"""Linocut v2 helpers for the banshee and the fire elemental.

Additions to `style.py` (which stays untouched):
- `rpart` draws a part like `Print.part`, but its paper rim goes into one rim layer under the
  whole figure, so overlapping parts show no cream seams.
- Curved shading: `curve_shade` puts the black shadow beyond a curve (not a straight line),
  `gouges` cuts tapered cream slivers along that curve, `stroke` is a tapered carved line
  that follows a polyline (folds, hair streaks, flame flicks, muscle grooves).
- Shape builders: `spline` (smooth curve through points), `wave` (wavy line between two
  points) and `licked` (adds flame tongues to a polygon's outline).
"""
import math

from style import INK, PAPER, path, rng, rough, sliver, taper

RIM = 12


# ---------------------------------------------------------------- geometry (pure)

def spline(pts, n=8):
    """A Catmull-Rom curve through all points, n samples per segment."""
    out = []
    ext = [pts[0]] + list(pts) + [pts[-1]]
    for i in range(1, len(ext) - 2):
        p0, p1, p2, p3 = ext[i - 1], ext[i], ext[i + 1], ext[i + 2]
        for j in range(n):
            t = j / n
            out.append(tuple(0.5 * (2 * p1[k] + (-p0[k] + p2[k]) * t
                                    + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t * t
                                    + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t ** 3) for k in (0, 1)))
    out.append(pts[-1])
    return out


def wave(a, b, amp, waves=1.5, n=16, phase=0.0):
    """A wavy line from a to b, swinging amp pixels to each side."""
    (x1, y1), (x2, y2) = a, b
    L = math.hypot(x2 - x1, y2 - y1) or 1
    nx, ny = -(y2 - y1) / L, (x2 - x1) / L
    pts = []
    for i in range(n):
        t = i / (n - 1)
        o = math.sin(phase + t * waves * 2 * math.pi) * amp * math.sin(t * math.pi) ** 0.5
        pts.append((x1 + (x2 - x1) * t + nx * o, y1 + (y2 - y1) * t + ny * o))
    return pts


def subdivide(poly, step):
    out = []
    for i, (x1, y1) in enumerate(poly):
        x2, y2 = poly[(i + 1) % len(poly)]
        k = max(1, int(math.hypot(x2 - x1, y2 - y1) / step))
        out += [(x1 + (x2 - x1) * j / k, y1 + (y2 - y1) * j / k) for j in range(k)]
    return out


def licked(poly, h, step=22, up=0.9, spread=0.45, lean=0.0):
    """Every other outline point pushed out and upwards (and `lean` sideways) into a flame tongue."""
    cx = sum(x for x, _ in poly) / len(poly)
    cy = sum(y for _, y in poly) / len(poly)
    out = []
    for i, (x, y) in enumerate(subdivide(poly, step)):
        dx, dy = x - cx, y - cy
        L = math.hypot(dx, dy) or 1
        dx, dy = dx / L, dy / L
        if i % 2 == 0 or dy > 0.55:
            out.append((x, y))
            continue
        dy -= up
        dx += lean
        L = math.hypot(dx, dy) or 1
        k = h * rng.uniform(1 - spread, 1 + spread)
        out.append((x + dx / L * k, y + dy / L * k))
    return out


# ---------------------------------------------------------------- marks (pure)

def curve_shade(line, toward, far=900):
    """The region beyond a curve in the `toward` direction, as a path."""
    dx, dy = toward
    L = math.hypot(dx, dy)
    dx, dy = dx / L * far, dy / L * far
    return path(list(line) + [(x + dx, y + dy) for x, y in reversed(line)])


def gouges(line, toward, count=6, lmin=8, lmax=22, w=6, color=PAPER, start=0.05, end=0.95):
    """Tapered cream slivers cut from a curve into its shadow side, following the curve's normal."""
    marks = []
    n = len(line)
    for i in range(count):
        t = start + (end - start) * (i + 0.5 + rng.uniform(-0.3, 0.3)) / count
        k = min(n - 2, max(1, int(t * (n - 1))))
        (ax, ay), (bx, by) = line[k - 1], line[k + 1]
        nx, ny = -(by - ay), bx - ax
        if nx * toward[0] + ny * toward[1] < 0:
            nx, ny = -nx, -ny
        x, y = line[k]
        ang = math.atan2(ny, nx) + rng.uniform(-0.3, 0.3)
        marks.append((sliver(x - math.cos(ang) * 3, y - math.sin(ang) * 3, ang,
                             rng.uniform(lmin, lmax), w * rng.uniform(0.7, 1.1)), color))
    return marks


def stroke(line, w1, w2=1.0, color=INK):
    """A carved line following a polyline, w1 wide at its start, tapering to w2."""
    return path(taper(line, w1, w2)), color


def shaded(line, toward, count=6, lmin=8, lmax=22, w=6):
    """Shadow beyond a curve plus gouges along it: the (shade, marks) pair for rpart."""
    return curve_shade(line, toward), gouges(line, toward, count, lmin, lmax, w)


# ---------------------------------------------------------------- drawing

def orient(poly):
    """The polygon wound clockwise. rsvg merges clipPath children with the nonzero rule, so
    overlapping polygons of opposite winding would cut holes into a part's clip."""
    area = sum(x1 * y2 - x2 * y1 for (x1, y1), (x2, y2) in zip(poly, poly[1:] + poly[:1]))
    return list(poly) if area > 0 else list(reversed(poly))


def rpart(p, polys, shade=None, marks=(), color=None, sw=5, reg=(5, 4), rim=True):
    """A carved part: outline, paper, offset colour block, shadow and marks, rim on the root layer."""
    color = color or p.color
    ds = "".join(f'<path d="{path(rough(orient(q), step=12, amp=1.6))}"/>' for q in polys)
    p.n += 1
    p.defs.append(f'<clipPath id="k{p.n}">{ds}</clipPath>')
    if rim:
        p.stack[0]["halo"].append(f'<g fill="{PAPER}" stroke="{PAPER}" stroke-width="{2 * sw + RIM}" '
                                  f'stroke-linejoin="round">{ds}</g>')
    p.cur["body"].append(f'<g fill="{INK}" stroke="{INK}" stroke-width="{2 * sw}" '
                         f'stroke-linejoin="round">{ds}</g><g fill="{PAPER}">{ds}</g>')
    inner = f'<g fill="{color}" transform="translate({reg[0]},{reg[1]})">{ds}</g>'
    if shade:
        inner += f'<path d="{shade}" fill="{INK}"/>'
    inner += "".join(f'<path d="{d}" fill="{c}"/>' for d, c in marks)
    p.cur["body"].append(f'<g clip-path="url(#k{p.n})">{inner}</g>')
