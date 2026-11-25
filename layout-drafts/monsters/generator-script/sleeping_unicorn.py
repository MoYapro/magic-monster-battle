"""Sleeping unicorn (linocut): the unicorn lying curled on a carved grass mound, legs folded
under, head resting low with closed eyes, horn pointing left, tail curled around its hooves."""
from helpers_i import (INK, PAPER, RAINBOW, bezier, grass_mound, hair, hoof, horn, leg, mass, rpart,
                       soft_head, spline, stroke)
from style import Print, taper
from unicorn import PEARL


def tail(p):
    strands = [((448, 372), (470, 446), 22, 8, 0.4), ((446, 380), (420, 462), 24, 10, 1.3),
               ((440, 388), (360, 462), 24, 12, 2.2), ((436, 394), (318, 458), 20, 12, 0.9),
               ((452, 366), (486, 420), 16, 8, 2.8)]
    under = spline([(466, 410), (440, 456), (340, 470)], 6)
    hair(p, "tail", (448, 372), strands, under, toward=(0.2, 1), colors=RAINBOW)


def far_legs(p):
    leg(p, "leg_far_front", [(222, 404), (182, 430), (228, 440)], [30, 20, 16], [6, 4], color=INK)
    hoof(p, "leg_far_front_hoof", (236, 440), angle=-1.4, size=13)


def body(p):
    with p.group("body", (310, 370)):
        poly = [(184, 372), (202, 336), (240, 318), (290, 322), (336, 314), (386, 312), (424, 324),
                (450, 350), (456, 388), (440, 420), (400, 438), (340, 444), (280, 444), (226, 440),
                (194, 422), (180, 398)]
        under = bezier((186, 410), (320, 438), (456, 384), 14)
        marks = [stroke(spline([(214, 344), (238, 380), (236, 420)], 4), 4, 1, PAPER),
                 stroke(spline([(268, 362), (320, 384), (380, 376)], 4), 3, 1, INK)]
        mass(p, poly, under, toward=(0.1, 1), marks=marks)


def haunch(p):
    with p.group("haunch", (392, 372)):
        poly = [(352, 360), (380, 330), (420, 334), (446, 364), (440, 404), (406, 424), (366, 418), (348, 392)]
        under = bezier((350, 404), (410, 420), (448, 372), 10)
        marks = [stroke(spline([(372, 346), (404, 356), (424, 392)], 4), 4, 1, PAPER)]
        mass(p, poly, under, toward=(0.2, 1), marks=marks, count=4)
    leg(p, "leg_back_shin", [(410, 418), (356, 440), (300, 446)], [26, 18, 15], [-4, 2])
    hoof(p, "leg_back_hoof", (292, 446), angle=1.57, size=14)


def near_fore(p):
    leg(p, "leg_front", [(226, 404), (150, 440), (214, 456)], [34, 22, 16], [10, 6], toward=(0.3, 1))
    hoof(p, "leg_front_hoof", (226, 455), angle=-1.5, size=14, color=INK)


def neck(p):
    with p.group("neck", (220, 360)):
        poly = [(236, 334), (206, 322), (176, 318), (148, 326), (132, 344), (136, 372), (160, 388),
                (194, 400), (222, 404), (238, 380)]
        under = spline([(140, 372), (190, 396), (236, 396)], 6)
        marks = [stroke(spline([(160, 334), (196, 348), (226, 352)], 4), 3, 1, PAPER)]
        mass(p, poly, under, toward=(0.1, 1), marks=marks, count=4)


def mane(p):
    strands = [((150, 318), (210, 290), 20, 8, 0.4), ((168, 316), (246, 296), 24, 10, 1.4),
               ((190, 316), (282, 312), 24, 10, 2.3), ((212, 320), (300, 340), 20, 10, 0.9),
               ((160, 326), (196, 392), 24, 10, 1.8), ((184, 328), (232, 398), 24, 10, 2.7),
               ((206, 330), (262, 392), 20, 8, 0.3), ((228, 332), (290, 376), 16, 8, 1.2)]
    under = spline([(160, 360), (220, 376), (290, 346)], 6)
    hair(p, "mane", (170, 322), strands, under, toward=(0.2, 1), colors=RAINBOW)


def head(p):
    with p.group("head", (130, 360)):
        brow = soft_head(p, (124, 372), tilt=0.45, scale=1.15, asleep=True)
    with p.group("forelock", brow):
        lines = [spline([brow, (brow[0] - 18, brow[1] + 8), (brow[0] - 30, brow[1] + 24)], 4),
                 spline([(brow[0] + 6, brow[1] + 2), (brow[0] - 6, brow[1] + 16), (brow[0] - 14, brow[1] + 30)], 4)]
        for ln, w, c in zip(lines, (13, 10), (RAINBOW[0], RAINBOW[5])):
            rpart(p, [taper(ln, w, 2)], None, [stroke(ln[1:-2], 3, 1, INK)], color=c)
    with p.group("horn", brow):
        horn(p, brow, (brow[0] - 104, brow[1] - 50), width=19, turns=8)


def build():
    p = Print(PEARL, seed=101)
    grass_mound(p, 30, 496, 470, h=36, blades=34)
    far_legs(p)
    body(p)
    haunch(p)
    tail(p)
    neck(p)
    mane(p)
    head(p)
    near_fore(p)
    return p


if __name__ == "__main__":
    build().save("sleeping_unicorn")
