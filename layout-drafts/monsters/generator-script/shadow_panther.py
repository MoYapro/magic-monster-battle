"""Shadow panther (linocut v2): a sleek big cat stalking low towards the left, shoulders high,
head down, a long curling tail, and dark smoke rising off its back."""
import math

from helpers_c import (INK, PAPER, bend, curve_cut, figure_rim, groove, oval, part, smoke, spikes, swell)
from style import Print, auto_cut, bar_cut, bezier, bulged, eyes, ground, knob, path, rng, sliver, taper

VIOLET = "#9a86b8"


def body_shade(polys, curve, toward=(0.25, 1), **kw):
    return curve_cut(curve, toward, **kw)


def smoke_wisps(p):
    with p.group("smoke", (300, 236)):
        for x, h, w, lean, curl in [(214, 110, 34, 0.6, 1.4), (272, 150, 40, 0.7, 1.1),
                                    (338, 124, 36, 0.8, 1.6), (392, 90, 28, 0.8, 1.2)]:
            poly = smoke(x, 246, h, w, lean, curl)
            marks = [groove((x + 6, 244), (x + w * 0.3 + lean * h * 0.15, 244 - h * 0.5),
                            (x + lean * h * 0.6, 246 - h * 0.85), 3.5)]
            part(p, [poly], marks=marks, color=INK)


def tail(p):
    with p.group("tail", (424, 262)):
        line = bezier((424, 262), (490, 300), (498, 236), 12)[:-1] + bezier((498, 236), (502, 182), (462, 192), 8)
        poly = taper(line, 24, 8)
        shade, marks = curve_cut(line, (1, 0.4), count=5, lmin=6, lmax=12, w=4)
        part(p, [poly], shade, marks)


def leg_chain(p, name, pts, widths, bends, paw, color, toes=True):
    """Curved, muscled segments plus a paw; each its own group pivoting at its top joint."""
    names = ("upper", "lower", "foot")
    for i, (a, b) in enumerate(zip(pts, pts[1:])):
        with p.group(f"{name}_{names[i]}", a):
            line = bezier(a, bend(a, b, bends[i]), b, 10)
            poly = swell(line, widths[i], widths[i + 1], widths[i] * 0.15)
            polys = [poly, knob(*b, widths[i + 1] * 0.5, 7)]
            shade, marks = auto_cut(polys, depth=0.4, count=2, lmin=6, lmax=14, w=4)
            part(p, polys, shade, marks, color=color)
    a = pts[-1]
    with p.group(f"{name}_paw", a):
        cx, cy, rx = paw
        pad = oval(cx, cy, rx, rx * 0.55, 14)
        toe = [knob(cx - rx * 0.75 + i * rx * 0.45, cy + rx * 0.25, rx * 0.28, 6) for i in range(4)] if toes else []
        marks = [(sliver(cx - rx * 0.5 + i * rx * 0.45, cy + rx * 0.55, -math.pi / 2, rx * 0.4, 3), PAPER)
                 for i in range(3)]
        part(p, [pad] + toe, path(bar_rect(cx, cy, rx)), marks, color=color)


def bar_rect(cx, cy, rx):
    return [(cx - rx * 2, cy + rx * 0.05), (cx + rx * 2, cy + rx * 0.05), (cx + rx * 2, cy + rx * 2),
            (cx - rx * 2, cy + rx * 2)]


def torso(p):
    with p.group("torso", (280, 280)):
        body = [(122, 312), (150, 252), (196, 220), (240, 226), (290, 246), (340, 238), (386, 228),
                (428, 240), (446, 272), (440, 312), (410, 332), (350, 334), (300, 330), (250, 340),
                (206, 352), (160, 350), (134, 346)]
        back = bezier((122, 316), (270, 236), (452, 286), 16)
        shade, marks = curve_cut(back, (0.15, 1), count=7, lmin=14, lmax=30, w=6)
        marks += [groove((176, 246), (232, 262), (240, 330), 4.5),         # shoulder blade
                  groove((196, 236), (250, 250), (262, 316), 3.5),
                  groove((400, 246), (432, 280), (420, 322), 4.5),         # haunch
                  groove((382, 244), (410, 290), (392, 326), 3.5)]
        hair = [s for a, b in zip(body[1:11], body[2:12]) for s in spikes(a, b, 2, 5, w=4, sides=(-1,), lean=1.2)]
        part(p, [body] + hair, shade, marks)


def head(p):
    with p.group("jaw", (118, 362)):
        jaw = [(122, 362), (90, 380), (52, 390), (34, 382), (58, 370), (98, 356)]
        marks = [(sliver(46 + i * 14, 378, -math.pi / 2 - 0.1, 14, 6), PAPER) for i in range(2)]
        part(p, [jaw], marks=marks + [(path([(30, 384), (130, 372), (130, 400), (30, 400)]), INK)])
    with p.group("head", (132, 322)):
        skull = oval(96, 330, 50, 40, 16, -0.15)
        muzzle = [(62, 322), (34, 336), (24, 354), (40, 368), (86, 366), (98, 342)]
        ear_near = [(80, 302), (82, 274), (94, 262), (116, 292)]
        ear_far = [(118, 296), (128, 266), (140, 268), (148, 300)]
        brow = [(50, 322), (92, 306), (116, 320)]
        curve = bezier((26, 366), (118, 346), (152, 298), 10)
        shade, marks = curve_cut(curve, (1, 0.7), count=5, lmin=8, lmax=18, w=5)
        marks += [(sliver(36, 362, math.pi / 2, 18, 6), PAPER), (sliver(52, 364, math.pi / 2 + 0.1, 20, 6.5), PAPER)]
        marks += [(sliver(94, 270, math.pi / 2 + 0.2, 22, 7), INK), (sliver(132, 274, math.pi / 2 + 0.1, 20, 6), INK)]
        marks += [(path(knob(26, 344, 6, 5)), INK)]
        for i in range(3):
            marks.append((sliver(48 + i * 3, 344 + i * 6, math.pi + 0.25 - i * 0.22, 24, 2.4), PAPER))
        part(p, [skull, muzzle, ear_far, ear_near, brow], shade, marks)
        p.fill(path(eye_slit(76, 326, 16, 7)), INK)
        eyes(p, [(76, 326)], 6)


def eye_slit(cx, cy, w, h):
    return [(cx - w, cy + 1), (cx - w * 0.2, cy - h), (cx + w, cy - h * 0.4), (cx + w * 0.2, cy + h * 0.6)]


def build():
    p = Print(VIOLET, seed=47)
    with p.group("ground", (256, 452)):
        ground(p, 24, 500, 448)
    smoke_wisps(p)
    leg_chain(p, "leg_far_back", [(372, 290), (350, 362), (392, 404), (380, 434)], [40, 22, 16, 14],
              [-14, 6, 0], (372, 440, 18), INK, toes=False)
    leg_chain(p, "leg_far_front", [(240, 296), (256, 368), (238, 430)], [40, 22, 18], [-10, 8],
              (228, 440, 20), INK, toes=False)
    tail(p)
    torso(p)
    leg_chain(p, "leg_back", [(400, 276), (368, 356), (422, 404), (408, 436)], [54, 24, 18, 15],
              [-22, 8, 0], (398, 442, 20), None)
    leg_chain(p, "leg_front", [(196, 262), (214, 358), (172, 428)], [44, 24, 20], [-16, 10],
              (160, 440, 24), None)
    head(p)
    figure_rim(p, 11)
    return p


if __name__ == "__main__":
    build().save("shadow_panther")
