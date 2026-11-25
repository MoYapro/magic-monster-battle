"""Flying cat (linocut): the tabby from cat.py leaping left with feathered wings spread up
behind its shoulders, legs stretched out, tail streaming back, a small shadow far below."""
import math

from cat import GINGER, head
from helpers_c import (INK, PAPER, curve_cut, figure_rim, groove, oval, part, rings, stripe,
                       swell, wing)
from style import Print, auto_cut, bezier, path, sliver


def limb(p, name, top, knee, foot, w, color, paw_ang):
    """A stretched leg: one curved, ringed segment plus a paw, pivoting at the top."""
    with p.group(name, top):
        line = bezier(top, knee, foot, 12)
        poly = swell(line, w, w * 0.62, 4)
        paw = oval(foot[0], foot[1], w * 0.7, w * 0.42, 12, paw_ang)
        shade, marks = auto_cut([poly, paw], depth=0.3, count=2, lmin=6, lmax=12, w=4)
        marks += rings(line, [0.45, 0.65], w * 0.8, depth=0.6)
        part(p, [poly, paw], shade, marks, color=color)


def wing_part(p, name, base, wrist, tip, color, **kw):
    with p.group(name, base):
        polys, marks = wing(base, wrist, tip, **kw)
        arm = bezier(base, wrist, tip, 12)
        shade, m2 = curve_cut([(x + 30, y + 70) for x, y in arm], (0.6, 1), count=6, lmin=10, lmax=20, w=5)
        part(p, polys, shade, marks + m2, color=color)


def tail(p):
    with p.group("tail", (412, 246)):
        line = bezier((412, 250), (470, 262), (486, 220), 10)[:-1] + bezier((486, 220), (500, 176), (470, 160), 8)
        poly = swell(line, 30, 16, 4)
        shade, marks = curve_cut(line, (0.4, 1), count=4, lmin=6, lmax=12, w=4)
        marks += rings(line, [0.15, 0.3, 0.45, 0.6, 0.75, 0.9], 30, depth=1.2)
        part(p, [poly], shade, marks)


def body(p):
    with p.group("body", (290, 250)):
        torso = [(170, 220), (232, 198), (300, 202), (370, 208), (420, 228), (434, 264), (408, 298),
                 (336, 310), (266, 306), (204, 298), (164, 266)]
        belly = bezier((168, 266), (300, 254), (436, 254), 14)
        shade, marks = curve_cut(belly, (0.1, 1), count=8, lmin=10, lmax=20, w=5)
        marks += [stripe((230 + i * 34, 210), (242 + i * 34, 238), (230 + i * 34, 270), 8) for i in range(6)]
        marks += [groove((340, 232), (392, 236), (410, 270), 4)]
        part(p, [torso], shade, marks)


def build():
    p = Print(GINGER, seed=73)
    with p.group("ground_shadow", (270, 470)):
        part(p, [oval(270, 470, 92, 9, 16)], color=INK,
             marks=[(sliver(210 + i * 40, 470, 0, 26, 3), PAPER) for i in range(3)])
    wing_part(p, "wing_far", (268, 220), (336, 140), (448, 70), INK, n=7, lmin=50, lmax=110, ang=0.9, w=20, fan=1.1, coverts=1)
    limb(p, "leg_far_back", (366, 286), (418, 330), (462, 342), 26, INK, 0.3)
    limb(p, "leg_far_front", (214, 284), (160, 316), (104, 330), 24, INK, -0.2)
    tail(p)
    body(p)
    limb(p, "leg_back", (380, 270), (420, 322), (450, 368), 32, None, 0.6)
    limb(p, "leg_front", (196, 270), (140, 300), (78, 300), 28, None, 0.1)
    wing_part(p, "wing_near", (226, 228), (236, 130), (296, 40), None, n=8, lmin=60, lmax=150, ang=0.9, w=24, fan=1.2, coverts=1)
    head(p)
    figure_rim(p, 11)
    return p


if __name__ == "__main__":
    build().save("flying_cat")
