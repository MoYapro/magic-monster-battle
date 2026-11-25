"""Unicorn (linocut): a graceful, gentle horse prancing towards the left, one foreleg raised, a
round soft head with a big eye, a gold spiral horn, and a muted rainbow mane and tail."""
from helpers_i import (INK, PAPER, RAINBOW, bezier, hair, hoof, horn, leg, mass, oval, rpart, soft_head,
                       spline, stroke)
from style import Print, ground, taper

PEARL = "#ddd3ea"


def tail(p):
    strands = [((414, 262), (462, 320), 20, 10, 0.3), ((418, 266), (484, 360), 24, 14, 1.2),
               ((418, 272), (478, 414), 26, 16, 2.1), ((414, 278), (450, 440), 22, 14, 0.8),
               ((410, 270), (430, 398), 18, 10, 2.7), ((420, 260), (492, 296), 14, 8, 1.9)]
    under = spline([(440, 270), (482, 340), (490, 420)], 6)
    hair(p, "tail", (414, 266), strands, under, toward=(1, 0.2), colors=RAINBOW)


def far_legs(p):
    leg(p, "leg_far_front", [(236, 322), (232, 390), (236, 434), (234, 446)], [24, 16, 12, 11],
        [-3, 2, 0], color=INK, knobs=False)
    hoof(p, "leg_far_front_hoof", (232, 450), size=13)
    leg(p, "leg_far_back", [(354, 320), (350, 380), (368, 410), (358, 440), (356, 448)],
        [34, 22, 14, 12, 11], [-5, 3, -2, 0], color=INK, knobs=False)
    hoof(p, "leg_far_back_hoof", (354, 451), size=13)


def near_hind(p):
    leg(p, "leg_back", [(386, 292), (396, 358), (416, 400), (404, 440), (400, 448)],
        [52, 26, 16, 13, 12], [-10, 5, -3, 0], toward=(1, 0.2), knobs=False, shade=False)
    hoof(p, "leg_back_hoof", (398, 451), size=14)


def body(p):
    with p.group("body", (304, 290)):
        barrel = oval(306, 292, 112, 58, 22)
        chest = oval(220, 294, 42, 46, 16)
        rump = oval(392, 280, 40, 44, 16)
        under = bezier((196, 336), (304, 358), (430, 306), 14)
        marks = [stroke(spline([(222, 262), (244, 300), (238, 332)], 4), 4, 1, PAPER),
                 stroke(spline([(380, 248), (404, 280), (396, 318)], 4), 4, 1, PAPER),
                 stroke(spline([(270, 306), (306, 318), (350, 312)], 4), 2.6, 1, INK)]
        shade_line = under
        from helpers_i import shaded
        shade, gs = shaded(shade_line, (0.15, 1), count=6, lmin=8, lmax=18, w=5)
        rpart(p, [barrel, chest, rump], shade, marks + gs)


def neck(p):
    with p.group("neck", (220, 286)):
        crest = bezier((168, 134), (226, 156), (250, 262), 12)
        throat = bezier((222, 310), (190, 248), (138, 176), 12)
        poly = crest + throat
        under = spline([(176, 176), (216, 236), (240, 296)], 6)
        marks = [stroke(spline([(160, 204), (180, 248), (196, 292)], 4), 3, 1, PAPER)]
        mass(p, poly, under, toward=(1, 0.4), marks=marks, count=4)


def mane(p):
    strands = [((166, 128), (252, 144), 20, 10, 0.4), ((180, 140), (270, 182), 24, 14, 1.3),
               ((196, 160), (282, 220), 24, 14, 2.2), ((210, 184), (286, 254), 22, 12, 0.9),
               ((224, 210), (280, 284), 20, 12, 1.7), ((234, 236), (268, 306), 16, 10, 2.6)]
    under = spline([(214, 150), (274, 214), (296, 296)], 6)
    hair(p, "mane", (180, 140), strands, under, toward=(1, 0.3), colors=RAINBOW)


def head(p):
    with p.group("head", (160, 150)):
        brow = soft_head(p, (148, 160), tilt=0.15, scale=1.2)
    with p.group("forelock", brow):
        lines = [spline([brow, (brow[0] - 20, brow[1] + 10), (brow[0] - 30, brow[1] + 30)], 4),
                 spline([(brow[0] + 6, brow[1] + 2), (brow[0] - 8, brow[1] + 18), (brow[0] - 12, brow[1] + 36)], 4)]
        for ln, w, c in zip(lines, (14, 11), (RAINBOW[0], RAINBOW[5])):
            rpart(p, [taper(ln, w, 2)], None, [stroke(ln[1:-2], 3, 1, INK)], color=c)
    with p.group("horn", brow):
        horn(p, brow, (brow[0] - 64, brow[1] - 100), width=20, turns=8)


def near_fore(p):
    leg(p, "leg_front", [(214, 300), (172, 360), (196, 396), (208, 406)], [34, 18, 13, 12],
        [-10, -7, 0], toward=(1, 0.3), knobs=False, shade=False)
    hoof(p, "leg_front_hoof", (212, 409), angle=-0.8, size=14, color=INK)


def build():
    p = Print(PEARL, seed=97)
    with p.group("ground", (270, 462)):
        ground(p, 70, 480, 460)
    tail(p)
    far_legs(p)
    near_hind(p)
    body(p)
    neck(p)
    mane(p)
    head(p)
    near_fore(p)
    return p


if __name__ == "__main__":
    build().save("unicorn")
