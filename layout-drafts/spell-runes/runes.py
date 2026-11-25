"""Spell-rune generator: plain letters in, ember-style SVG icons out.

Library:
    spell_icon("F", "#e0602a")                     -> standalone SVG string
    spell_icon("FRB", "#e0602a")                   -> several letters merged into one bind-rune
    alchemy_icon("F", "F", "R", "#d9d9d9")         -> catalyst (bottom), reactant A (top left), reactant B (top right)
    spell_body / alchemy_body(..., cx, cy, r)      -> SVG fragments for embedding in a larger sheet (needs DEFS)

CLI:
    python runes.py spell FRB "#e0602a" out.svg [radius]
    python runes.py alchemy F F R "#d9d9d9" out.svg [radius]
    A .png output path renders through rsvg-convert.
"""
import math
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------- rune alphabet
# Each glyph: list of polylines in a unit box (x 0..1 left->right, y 0..1 top->bottom).
# Traced by eye from the user's sketch, so expect some letters to be off.
RUNES = {
    "A": [[(0.15, 0.15), (0.55, 0.0), (0.7, 1.0)], [(0.1, 0.3), (0.6, 0.75)], [(0.45, 1.0), (0.95, 0.95)]],
    "B": [[(0.9, 0.0), (0.1, 0.0), (0.1, 1.0), (0.9, 1.0)], [(0.1, 0.5), (0.9, 0.5)], [(0.9, 0.0), (0.9, 0.35)],
          [(0.1, 0.7), (0.9, 0.7)]],
    "C": [[(0.85, 0.0), (0.85, 1.0), (0.1, 1.0)]],
    "D": [[(0.45, 0.0), (0.05, 1.0)], [(0.6, 0.0), (0.3, 1.0), (0.95, 1.0)]],
    "E": [[(0.5, 0.05), (0.1, 1.0)], [(0.8, 0.0), (0.4, 1.0)], [(0.35, 0.1), (0.9, 0.02)]],
    "F": [[(0.1, 0.45), (0.9, 0.95)], [(0.85, 0.3), (0.15, 0.85)]],
    "G": [[(0.1, 1.0), (0.1, 0.0), (0.9, 0.0), (0.9, 1.0), (0.1, 1.0)], [(0.45, 0.3), (0.45, 1.0)],
          [(0.45, 0.3), (0.7, 0.3), (0.7, 1.0)]],
    "H": [[(0.0, 0.2), (1.0, 0.2)], [(0.3, 0.05), (0.3, 1.0)], [(0.7, 0.2), (0.7, 1.0)]],
    "I": [[(0.5, 0.0), (0.5, 1.05)], [(0.2, 0.3), (0.8, 0.3)], [(0.05, 0.95), (0.95, 0.9)]],
    "J": [[(0.15, 0.25), (0.15, 1.0), (0.85, 1.0), (0.85, 0.0)], [(0.5, 0.4), (0.5, 0.75)]],
    "K": [[(0.05, 0.1), (0.95, 0.15)], [(0.5, 0.0), (0.4, 1.0)], [(0.2, 0.5), (0.75, 0.45)]],
    "L": [[(0.55, 0.0), (0.05, 1.0), (1.0, 1.0)], [(0.3, 0.05), (0.8, 0.5)]],
    "M": [[(0.1, 1.0), (0.1, 0.0), (0.9, 0.0)]],
    "N": [[(0.75, 0.0), (0.75, 1.0), (0.05, 1.0)]],
    "O": [[(0.1, 0.0), (0.9, 0.0), (0.9, 1.0), (0.1, 1.0), (0.1, 0.0)]],
    "P": [[(0.1, 0.4), (0.1, 0.0), (0.9, 0.0), (0.8, 1.0)], [(0.1, 0.4), (0.85, 0.42)]],
    "Q": [[(0.1, 0.0), (0.9, 0.0), (0.9, 1.0), (0.1, 1.0), (0.1, 0.0)], [(0.5, 0.5), (0.52, 0.52)]],
    "R": [[(0.2, 0.0), (0.2, 1.0)], [(0.2, 0.0), (0.75, 0.25), (0.2, 0.5), (0.85, 1.0)]],
    "S": [[(0.3, 0.0), (0.3, 1.0)], [(0.3, 0.3), (0.8, 0.0)], [(0.3, 0.55), (0.8, 0.25)]],
    "T": [[(0.0, 0.85), (0.9, 0.35)], [(0.2, 0.6), (0.75, 1.0)]],
    "U": [[(0.1, 1.0), (0.1, 0.0), (0.9, 0.0), (0.9, 1.0)]],
    "V": [[(0.0, 0.0), (0.35, 1.0), (1.0, 0.0)]],
    "W": [[(0.1, 1.0), (0.1, 0.0), (0.9, 1.0), (0.9, 0.0)], [(0.75, 0.0), (1.0, 0.0)]],
    "X": [[(0.5, 0.0), (0.5, 1.0)], [(0.1, 0.2), (0.9, 0.8)], [(0.9, 0.2), (0.1, 0.8)]],
    "Y": [[(0.5, 0.35), (0.5, 1.0)], [(0.0, 0.0), (0.5, 0.6), (1.0, 0.0)]],
    "Z": [[(0.0, 0.6), (0.3, 1.0), (0.7, 0.0), (0.9, 0.3)]],
    # row 3 -> digits 0-9 (assumed order)
    "0": [[(0.0, 0.7), (0.5, 0.2), (1.0, 0.7)], [(0.5, 0.5), (0.52, 0.52)]],
    "1": [[(0.5, 0.0), (0.95, 0.5), (0.5, 1.0), (0.05, 0.5), (0.5, 0.0)], [(0.5, 0.5), (0.52, 0.52)]],
    "2": [[(0.95, 0.0), (0.1, 0.55), (0.95, 0.5), (0.2, 1.0)]],
    "3": [[(0.5, 0.0), (0.5, 1.0)], [(0.95, 0.0), (0.0, 1.0)]],
    "4": [[(0.1, 1.0), (0.1, 0.0), (0.5, 0.6), (0.9, 0.0), (0.9, 1.0)]],
    "5": [[(0.5, 0.0), (0.5, 1.0)], [(0.1, 0.4), (0.5, 0.0), (0.9, 0.4)], [(0.5, 0.3), (0.9, 0.5), (0.5, 0.6)]],
    "6": [[(0.0, 1.0), (1.0, 0.0)], [(0.1, 0.1), (0.9, 0.9)], [(0.75, 0.0), (0.95, 0.25)], [(0.85, 0.0), (1.0, 0.2)]],
    "7": [[(0.5, 0.0), (0.5, 1.0)], [(0.0, 0.0), (0.5, 0.5), (1.0, 0.0)], [(0.0, 1.0), (0.5, 0.5), (1.0, 1.0)]],
    "8": [[(0.1, 0.0), (0.1, 1.0)], [(0.1, 0.3), (0.95, 0.1)], [(0.1, 0.85), (0.95, 0.95)],
          [(0.1, 0.5), (0.35, 0.3)]],
    "9": [[(0.5, 0.0), (0.5, 1.0)], [(0.5, 0.0), (0.8, 0.2)], [(0.0, 0.75), (0.5, 0.5), (1.0, 0.75), (0.5, 1.0),
                                                                (0.0, 0.75)]],
}


# ---------------------------------------------------------------- letters -> strokes (pure)
def normalize(letters):
    """'f r b' / 'frb' -> ['F', 'R', 'B']; rejects letters without a rune."""
    chars = [c for c in letters.upper() if not c.isspace()]
    unknown = [c for c in chars if c not in RUNES]
    if unknown or not chars:
        raise ValueError(f"no rune for {unknown or 'empty input'}")
    return chars


def stem_x(glyph):
    """x of the longest near-vertical segment, or None."""
    best, best_len = None, 0.45
    for line in glyph:
        for (x0, y0), (x1, y1) in zip(line, line[1:]):
            if abs(x1 - x0) < 0.15 and abs(y1 - y0) > best_len:
                best, best_len = (x0 + x1) / 2, abs(y1 - y0)
    return best


def shift(glyph, dx):
    return [[(x + dx, y) for x, y in line] for line in glyph]


def overlay(chars):
    """Letters as drawn; letters with a stem are slid so their stems coincide, others are centred."""
    lines = []
    for ch in chars:
        sx = stem_x(RUNES[ch])
        lines += shift(RUNES[ch], 0.5 - sx if sx is not None else 0.0)
    return lines


def to_segments(lines):
    return [(a, b) for line in lines for a, b in zip(line, line[1:]) if a != b]


def seg_dir(seg):
    (x0, y0), (x1, y1) = seg
    n = math.hypot(x1 - x0, y1 - y0)
    return (x1 - x0) / n, (y1 - y0) / n


def similar(a, b, tol=0.15, max_angle=22):
    """Near-parallel, close together and overlapping along their length."""
    da, db = seg_dir(a), seg_dir(b)
    if abs(da[0] * db[0] + da[1] * db[1]) < math.cos(math.radians(max_angle)):
        return False
    (ox, oy), nx, ny = a[0], -da[1], da[0]
    if any(abs((px - ox) * nx + (py - oy) * ny) > tol for px, py in b):
        return False
    ta = sorted((px - ox) * da[0] + (py - oy) * da[1] for px, py in a)
    tb = sorted((px - ox) * da[0] + (py - oy) * da[1] for px, py in b)
    return min(ta[1], tb[1]) - max(ta[0], tb[0]) > -tol


def clusters(items, same):
    parent = list(range(len(items)))

    def root(i):
        while parent[i] != i:
            i = parent[i]
        return i
    for i in range(len(items)):
        for j in range(i + 1, len(items)):
            if same(items[i], items[j]):
                parent[root(i)] = root(j)
    groups = {}
    for i, item in enumerate(items):
        groups.setdefault(root(i), []).append(item)
    return list(groups.values())


def merge_group(group):
    """One segment along the longest member, spanning all members, centred on their average offset."""
    base = max(group, key=lambda s: math.dist(*s))
    (ox, oy), (dx, dy) = base[0], seg_dir(base)
    pts = [p for s in group for p in s]
    ts = [(px - ox) * dx + (py - oy) * dy for px, py in pts]
    off = sum((px - ox) * -dy + (py - oy) * dx for px, py in pts) / len(pts)
    at = lambda t: (ox + dx * t - dy * off, oy + dy * t + dx * off)
    return at(min(ts)), at(max(ts))


def snap_ends(segs, tol=0.06):
    """Pull endpoints that nearly meet onto their common average point."""
    groups = clusters([p for s in segs for p in s], lambda a, b: math.dist(a, b) < tol)
    where = {p: tuple(sum(c) / len(g) for c in zip(*g)) for g in groups for p in g}
    return [(where[a], where[b]) for a, b in segs]


def rune_segments(letters):
    """Letters -> cleaned stroke segments in unit space. One letter = its rune; more = merged bind-rune."""
    segs = to_segments(overlay(normalize(letters)))
    return snap_ends([merge_group(g) for g in clusters(segs, similar)])


# ---------------------------------------------------------------- svg
DEFS = """<defs>
<radialGradient id="wood" cx="45%" cy="40%" r="65%"><stop offset="0" stop-color="#3a2416"/>
<stop offset="1" stop-color="#140b06"/></radialGradient>
<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="4"/></filter>
</defs>"""
CORE = "#fff3c8"


def bounds(lines):
    xs = [x for line in lines for x, _ in line]
    ys = [y for line in lines for _, y in line]
    return min(xs), min(ys), max(xs), max(ys)


def fit(lines, cx, cy, size):
    """Scale lines uniformly into a size x size box centred on cx, cy."""
    x0, y0, x1, y1 = bounds(lines)
    k = size / max(x1 - x0, y1 - y0, 1e-6)
    ox, oy = cx - (x1 - x0) * k / 2, cy - (y1 - y0) * k / 2
    return [[(ox + (x - x0) * k, oy + (y - y0) * k) for x, y in line] for line in lines]


def path(lines, stroke, sw, op=1.0, extra=""):
    d = " ".join("M" + " L".join(f"{x:.1f},{y:.1f}" for x, y in line) for line in lines)
    return (f'<path d="{d}" fill="none" stroke="{stroke}" stroke-width="{sw:.2f}" stroke-linecap="round" '
            f'stroke-linejoin="round" opacity="{op}" {extra}/>')


def circle(cx, cy, r, fill, stroke="none", sw=1, op=1.0):
    return (f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{fill}" stroke="{stroke}" '
            f'stroke-width="{sw:.2f}" opacity="{op}"/>')


def ember_strokes(letters, color, cx, cy, size, width):
    """Glow + coloured stroke + hot core for one rune, fitted into a size box."""
    pts = fit([list(s) for s in rune_segments(letters)], cx, cy, size)
    return (path(pts, color, width * 2, 0.9, 'filter="url(#glow)"') + path(pts, color, width)
            + path(pts, CORE, width * 0.38, 0.9))


def disc(color, cx, cy, r):
    return circle(cx, cy, r, "url(#wood)", color, r * 0.05)


def spell_body(letters, color, cx, cy, r):
    return disc(color, cx, cy, r) + ember_strokes(letters, color, cx, cy, r * 1.05, r * 0.08)


ALCHEMY_SPOTS = ((0.0, 0.27), (-0.3, -0.2), (0.3, -0.2))  # catalyst bottom, reactants top left / top right


def alchemy_body(catalyst, reactant_a, reactant_b, color, cx, cy, r):
    out = disc(color, cx, cy, r)
    for (fx, fy), letters in zip(ALCHEMY_SPOTS, (catalyst, reactant_a, reactant_b)):
        out += ember_strokes(letters, color, cx + fx * r, cy + fy * r, r * 0.55, r * 0.045)
    return out


def standalone(body, r):
    s = int(2 * r + 4)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{s}" height="{s}" viewBox="0 0 {s} {s}">'
            f'{DEFS}{body}</svg>')


def spell_icon(letters, color, r=52):
    return standalone(spell_body(letters, color, r + 2, r + 2, r), r)


def alchemy_icon(catalyst, reactant_a, reactant_b, color, r=52):
    return standalone(alchemy_body(catalyst, reactant_a, reactant_b, color, r + 2, r + 2, r), r)


# ---------------------------------------------------------------- cli
def write(svg, out):
    out = Path(out)
    if out.suffix == ".png":
        subprocess.run(["rsvg-convert", "-o", str(out)], input=svg.encode(), check=True)
    else:
        out.write_text(svg)


def main(argv):
    if len(argv) >= 4 and argv[0] == "spell":
        _, letters, color, out, *rest = argv
        return write(spell_icon(letters, color, float(rest[0]) if rest else 52), out)
    if len(argv) >= 6 and argv[0] == "alchemy":
        _, cat, a, b, color, out, *rest = argv
        return write(alchemy_icon(cat, a, b, color, float(rest[0]) if rest else 52), out)
    sys.exit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
