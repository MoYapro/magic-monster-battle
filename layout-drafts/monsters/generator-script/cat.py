"""Cat (linocut): a sitting tabby in an alert 3/4 pose facing left, tail curling up behind,
carved tabby stripes following the body, whiskers, and a grass tuft at its paws."""
import math

from helpers_c import (INK, PAPER, blades, curve_cut, figure_rim, groove, oval, part, rings,
                       spikes, stripe, swell, whiskers)
from style import Print, auto_cut, bezier, eyes, ground, knob, path, sliver

GINGER = "#d8945a"


def tail(p):
    with p.group("tail", (326, 440)):
        line = bezier((326, 442), (424, 446), (430, 344), 12)[:-1] + bezier((430, 344), (434, 238), (470, 190), 10)
        poly = swell(line, 24, 13, 3)
        shade, marks = curve_cut(line, (1, 0.2), count=5, lmin=5, lmax=10, w=3.5)
        marks += rings(line, [0.18, 0.3, 0.42, 0.54, 0.66, 0.78, 0.9], 22, depth=1.0)
        part(p, [poly], shade, marks)


def body(p):
    with p.group("body", (240, 340)):
        torso = [(148, 214), (196, 190), (236, 226), (282, 280), (316, 336), (340, 382), (344, 424),
                 (318, 450), (250, 454), (204, 444), (176, 410), (164, 360), (148, 300), (144, 250)]
        haunch = oval(298, 404, 50, 44, 16, -0.3)
        fluff = spikes((154, 250), (160, 330), 3, 6, w=5, sides=(1,), lean=0.3)
        back = bezier((222, 206), (334, 300), (330, 462), 12)
        shade, marks = curve_cut(back, (1, 0.35), count=7, lmin=10, lmax=22, w=5)
        marks += [stripe((194 + i * 20, 214 + i * 14), (220 + i * 22, 258 + i * 12), (204 + i * 24, 306 + i * 10), 6)
                  for i in range(3)]
        marks += [stripe((262 + i * 6, 384 + i * 20), (290 + i * 8, 370 + i * 22), (318 + i * 6, 388 + i * 20), 6)
                  for i in range(3)]
        marks += [stripe((164, 286 + i * 24), (176, 296 + i * 24), (192, 290 + i * 24), 4.5) for i in range(3)]
        marks += [groove((250, 432), (244, 372), (306, 360), 3.5, INK)]
        part(p, [torso, haunch] + fluff, shade, marks)


def front_leg(p, name, top, foot, color, w=30):
    with p.group(f"{name}", top):
        line = bezier(top, ((top[0] + foot[0]) / 2 + 8, (top[1] + foot[1]) / 2), foot, 10)
        poly = swell(line, w, w * 0.7, 4)
        paw = oval(foot[0] - 6, foot[1] + 4, w * 0.75, w * 0.42, 12)
        toes = [(sliver(foot[0] - 16 + i * 10, foot[1] + 12, -math.pi / 2, 9, 3), INK) for i in range(3)]
        shade, marks = auto_cut([poly, paw], depth=0.22, count=2, lmin=6, lmax=12, w=4)
        marks += [stripe((top[0] - 10, top[1] + 40 + i * 30), (top[0], top[1] + 50 + i * 30),
                         (top[0] + 14, top[1] + 44 + i * 30), 5) for i in range(2)]
        part(p, [poly, paw], shade, marks + toes, color=color)


def head(p, at=(150, 190), k=1.0):
    """The tabby head, drawn at `at` (skull centre) and scaled by k; shared with flying_cat."""
    def T(x, y):
        return at[0] + (x - 150) * k, at[1] + (y - 190) * k

    def P(pts):
        return [T(*q) for q in pts]

    with p.group("head", T(176, 236)):
        skull = P(oval(150, 190, 54, 46, 18, -0.05))
        muzzle = P(oval(108, 212, 24, 18, 10))
        cheeks = [P(c) for c in spikes((186, 214), (128, 240), 4, 10, w=8, sides=(-1,), lean=0.2)]
        ear_near = P([(108, 168), (110, 112), (148, 150)])
        ear_far = P([(160, 146), (194, 104), (198, 162)])
        curve = P(bezier((112, 240), (190, 226), (206, 150), 10))
        shade, marks = curve_cut(curve, (1, 0.6), count=4, lmin=8 * k, lmax=16 * k, w=5 * k)
        marks += [(path(P([(116, 156), (118, 126), (138, 152)])), INK), (path(P([(170, 148), (190, 118), (192, 156)])), INK)]
        marks += [(sliver(*T(140 + i * 10, 150), math.pi / 2 + (i - 1) * 0.15, 20 * k, 6 * k), INK) for i in range(3)]
        marks += [stripe(T(176, 172 + i * 14), T(196, 168 + i * 14), T(204, 180 + i * 14), 5 * k) for i in range(2)]
        marks += [(path(P([(94, 204), (106, 202), (100, 212)])), INK), groove(T(100, 212), T(100, 222), T(110, 228), 3 * k, INK)]
        part(p, [skull, muzzle, ear_near, ear_far] + cheeks, shade, marks)
        for x, y, r in ((124, 186, 9), (164, 184, 8)):
            (x, y), r = T(x, y), r * k
            eyes(p, [(x, y)], r)
            p.fill(path([(x - 1.5, y - r + 2), (x + 1.5, y - r + 2), (x + 1.5, y + r - 2), (x - 1.5, y + r - 2)]), INK)
        whiskers(p, T(104, 216), 3, 58 * k)
        whiskers(p, T(118, 220), 2, 40 * k, ang=math.pi + 0.45, spread=0.25)


def build():
    p = Print(GINGER, seed=61)
    with p.group("ground", (256, 456)):
        ground(p, 90, 440, 452)
    tail(p)
    front_leg(p, "leg_far_front", (204, 300), (196, 446), INK, 19)
    body(p)
    with p.group("paw_back", (284, 452)):
        part(p, [oval(284, 452, 26, 11, 12)], marks=[(sliver(268 + i * 10, 460, -math.pi / 2, 7, 3), INK)
                                                     for i in range(3)])
    front_leg(p, "leg_front", (178, 296), (160, 446), None, 22)
    head(p, (170, 150), 0.82)
    with p.group("grass", (86, 452)):
        part(p, blades(108, 452, 6, 52, 40, -0.25), color=INK)
        part(p, blades(400, 452, 4, 34, 24, 0.3), color=INK)
    figure_rim(p, 11)
    return p


if __name__ == "__main__":
    build().save("cat")
