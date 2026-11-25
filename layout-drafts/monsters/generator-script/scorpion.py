"""Scorpion (linocut v2): a big desert scorpion with a segmented, ridged body, two heavy
pincers held forward, eight jointed legs and a high curled tail ending in a stinger. Faces left."""
import math

from helpers_d import body, chain, gouge
from helpers_g import GPrint, plate, ridge
from style import INK, PAPER, bar, bar_cut, bezier, ground, knob, path, rng, sliver, taper

SAND = "#c9a45a"

# legs: (name, base, knee, tip); far legs sit behind the body and are printed black
FAR_LEGS = [
    ("far_1", (238, 322), (190, 256), (180, 422)),
    ("far_2", (270, 316), (252, 240), (262, 424)),
    ("far_3", (304, 314), (334, 238), (338, 424)),
    ("far_4", (338, 316), (398, 250), (420, 422)),
]
NEAR_LEGS = [
    ("near_4", (344, 370), (428, 318), (466, 452)),
    ("near_3", (308, 380), (352, 316), (378, 458)),
    ("near_2", (272, 382), (234, 314), (214, 458)),
    ("near_1", (238, 380), (176, 322), (146, 454)),
]
TAIL = [(372, 330), (418, 300), (448, 244), (450, 180), (424, 128), (380, 104), (334, 110)]


def leg(p, name, base, knee, tip, w, color):
    foot = (tip[0] + (tip[0] - knee[0]) * 0.18, tip[1] + 6)
    with p.group(f"leg_{name}_femur", base):
        shade, marks = bar_cut(*base, *knee, w, frac=0.1, count=2)
        p.part([bar(*base, *knee, w, w * 0.85), knob(*knee, w * 0.6, 7)], shade, marks, color=color, sw=4)
    with p.group(f"leg_{name}_tibia", knee):
        shade, marks = bar_cut(*knee, *tip, w * 0.85, frac=0.1, count=2)
        p.part([bar(*knee, *tip, w * 0.85, w * 0.5), knob(*tip, w * 0.35, 6),
                bar(*tip, *foot, w * 0.45, 2)], shade, marks, color=color, sw=4)


def mesosoma(p):
    """The broad body: seven overlapping armour plates from the head back to the tail."""
    with p.group("body", (300, 344)):
        plates = []
        xs = [218, 246, 274, 302, 330, 356, 378]
        for i, x in enumerate(xs):
            h = 88 - abs(i - 2.5) * 6
            plates.append([(x - 4, 344 - h / 2 - 4), (x + 30, 344 - h / 2 + 2), (x + 34, 344 + h / 2 - 2),
                           (x - 2, 344 + h / 2 + 4)])
        hull = [(212, 306), (260, 292), (330, 294), (394, 312), (406, 344), (390, 378), (320, 390), (250, 390),
                (212, 378)]
        seams = [(gouge((x + 30, 344 - 30), (x + 36, 344), (x + 32, 344 + 32), 6), INK) for x in xs[:-1]]
        hi = [(sliver(x + 4, 314 + abs(i - 3) * 2, 0.08, 20, 5), PAPER) for i, x in enumerate(xs)]
        dots = [(path(knob(x + 16, 334, 3, 5)), INK) for x in xs[1:-1]]
        body(p, [hull] + plates, [(214, 352), (300, 358), (400, 340)], color=SAND, count=7, lmin=8, lmax=16,
             w=5, extra=seams + hi + dots)


def head(p):
    with p.group("head", (220, 344)):
        shell = [(128, 342), (148, 306), (196, 294), (236, 304), (246, 346), (234, 384), (186, 392), (142, 378)]
        marks = [(gouge((160, 322), (190, 312), (226, 318), 5), PAPER),
                 (gouge((168, 352), (198, 360), (228, 352), 5), INK)]
        body(p, shell, [(150, 356), (200, 362), (238, 340)], color=SAND, count=4, lmin=6, lmax=12, w=4,
             extra=marks)
        p.eye(158, 324, 7)
        p.eye(178, 316, 6)
        p.fill(path(knob(196, 316, 3, 5)), INK)


def tail(p):
    """Five ridged tail segments curling up over the back, then the bulb and the stinger."""
    segs = list(zip(TAIL, TAIL[1:]))
    widths = [40, 38, 35, 32, 30, 28]
    for i, ((a, b), w) in enumerate(zip(segs, widths)):
        with p.group(f"tail_{i + 1}", a):
            poly = plate(a, b, w, w * 0.9, 0.3)
            shade, marks = bar_cut(*a, *b, w * 1.15, frac=0.12, count=2)
            marks += [ridge(a, b, w, -1), (path(knob(*b, 4, 5)), INK)]
            p.part([poly, knob(*b, w * 0.42, 7)], shade, marks, color=SAND, sw=5)
    with p.group("stinger", TAIL[-1]):
        bx, by = TAIL[-1]
        bulb = [(bx + 6, by - 20), (bx - 26, by - 18), (bx - 40, by + 4), (bx - 30, by + 26), (bx + 4, by + 24)]
        sting = taper(bezier((bx - 34, by + 8), (bx - 66, by + 18), (bx - 62, by + 56), 8), 15, 1.5)
        shade, marks = bar_cut(bx, by - 10, bx - 40, by + 20, 40, frac=0.15, count=2)
        marks.append((gouge((bx - 8, by - 10), (bx - 24, by - 12), (bx - 34, by), 4), PAPER))
        p.part([bulb, sting], shade, marks, color=SAND, sw=5)


def pincer(p, side, sh, el, wr, color, scale=1.0):
    """Upper arm, forearm and a heavy claw with a fixed and a hinged finger, opening forward."""
    w = 26 * scale
    with p.group(f"arm_{side}", sh):
        shade, marks = bar_cut(*sh, *el, w, frac=0.12, count=2)
        p.part([plate(sh, el, w, w * 0.9), knob(*el, w * 0.55, 7)], shade, marks, color=color, sw=5)
    with p.group(f"forearm_{side}", el):
        shade, marks = bar_cut(*el, *wr, w * 1.1, frac=0.12, count=2)
        p.part([plate(el, wr, w * 0.9, w * 1.2, 0.4), knob(*wr, w * 0.6, 7)], shade, marks, color=color, sw=5)
    with p.group(f"claw_{side}", wr):
        x, y = wr
        s = scale
        hand = [(x + 10 * s, y - 26 * s), (x - 40 * s, y - 34 * s), (x - 70 * s, y - 22 * s),
                (x - 74 * s, y + 4 * s), (x - 44 * s, y + 24 * s), (x + 6 * s, y + 26 * s), (x + 20 * s, y)]
        upper = taper(bezier((x - 64 * s, y - 20 * s), (x - 104 * s, y - 36 * s), (x - 128 * s, y - 8 * s), 8),
                      26 * s, 3)
        lower = taper(bezier((x - 66 * s, y + 6 * s), (x - 100 * s, y + 24 * s), (x - 118 * s, y + 6 * s), 8),
                      20 * s, 3)
        teeth = [(sliver(x - (84 + 10 * i) * s, y - (10 - i) * s, -1.4, 8 * s, 4 * s), INK) for i in range(3)]
        marks = [(gouge((x - 6 * s, y - 20 * s), (x - 36 * s, y - 28 * s), (x - 62 * s, y - 18 * s), 6 * s), PAPER),
                 (gouge((x - 10 * s, y + 16 * s), (x - 38 * s, y + 20 * s), (x - 60 * s, y + 12 * s), 6 * s), INK)]
        body(p, [hand, upper, lower], [(x - 70 * s, y + 10 * s), (x - 30 * s, y + 18 * s), (x + 16 * s, y + 6 * s)],
             color=color, count=4, lmin=6, lmax=14, w=5, extra=teeth + marks)


def build():
    p = GPrint(SAND, seed=53, zoom=0.94, shift=(34, 22))
    with p.group("ground", (256, 462)):
        ground(p, 24, 496, 458)
    pincer(p, "far", (204, 318), (176, 270), (150, 236), INK, 0.85)
    for name, *pts in FAR_LEGS:
        leg(p, name, *pts, 13, INK)
    tail(p)
    mesosoma(p)
    for name, *pts in NEAR_LEGS:
        leg(p, name, *pts, 16, SAND)
    head(p)
    pincer(p, "near", (176, 378), (126, 406), (96, 386), SAND, 0.95)
    return p


if __name__ == "__main__":
    build().save("scorpion")
