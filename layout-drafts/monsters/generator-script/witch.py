"""Witch (linocut v2): a hunched crone in a bent pointed hat and ragged cloak, leaning on a crooked
staff and tipping a potion into a bubbling cauldron."""
import math

from helpers_a import Print2, finger_bones, form, ink_line, paper_line
from helpers_b import spline, wave
from helpers_f import bubble, cloth, hem, lit_edge, staff, strands
from style import INK, PAPER, eyes, ground, knob, path, rough, sliver, taper

VIOLET = "#a774c4"


def the_staff(p):
    with p.group("staff", (384, 268)):
        line = staff(p, (396, 468), (378, 122), w=11, crook=14, knots=4, color=PAPER)
        hook = taper(spline([(378, 126), (372, 100), (384, 80), (402, 88), (400, 108), (390, 110)], 4), 11, 6)
        form(p, [hook], ((396, 80), (410, 96), (396, 114)), toward=(1, 0.2), color=PAPER, sw=3.5, rows=0,
             count=2, lmin=2, lmax=4, w=2)


def far_arm(p):
    with p.group("sleeve_far", (320, 240)):
        sleeve = [(310, 228), (346, 244), (376, 262), (378, 284), (348, 288), (318, 268)]
        cloth(p, sleeve, ((340, 238), (376, 266), (366, 292)), toward=(1, 0.4),
              fold_lines=[((326, 246), (348, 262), (366, 276))], color=INK, sw=4, count=4)
    with p.group("hand_far", (384, 272)):
        finger_bones(p, (388, 272), math.pi * 1.05, fingers=4, length=18, spread=1.1, w=7, curl=-1.3,
                     palm=10, color=PAPER, sw=3)


def cloak(p):
    with p.group("cloak", (290, 250)):
        outline = ([(232, 200), (262, 186), (304, 186), (342, 206), (366, 250), (374, 310), (376, 370), (382, 420),
                    (386, 452)] + hem((386, 452), (198, 458), 9, 22, lean=-0.2)
                   + [(204, 400), (212, 330), (220, 270), (224, 226)])
        fold_lines = [((262, 250), (258, 350), (250, 446)), ((300, 240), (310, 340), (318, 446)),
                      ((338, 280), (350, 360), (360, 446)), ((228, 300), (222, 380), (214, 446))]
        cloth(p, outline, ((318, 204), (352, 300), (380, 470)), toward=(1, 0.1), fold_lines=fold_lines,
              marks=lit_edge([(226, 232), (218, 300), (210, 380)], inward=(1, 0), offset=10, w=4),
              count=9)


def head(p):
    with p.group("head", (262, 214), offset=(-8, 12)):
        head_parts(p)


def head_parts(p):
    with p.group("hair", (270, 200)):
        hair = [(244, 176), (292, 170), (306, 196), (310, 250), (300, 290), (288, 262), (278, 300),
                (266, 258), (254, 236)]
        form(p, [hair], ((296, 168), (312, 240), (296, 300)), toward=(1, 0.1), color=PAPER, sw=3.5, rows=0,
             count=3, lmin=3, lmax=6, w=2, marks=strands(((250, 182), (300, 178)), ((266, 260), (296, 280)), 6, 3))
    with p.group("face", (236, 210)):
        face = [(222, 176), (252, 172), (262, 196), (256, 226), (244, 244), (228, 250), (214, 244),
                (220, 228), (206, 220), (212, 208)]
        nose = [(214, 194), (184, 216), (176, 230), (192, 226), (212, 214)]
        marks = [ink_line((216, 192), (230, 186), (244, 194), 5, 2), ink_line((214, 226), (226, 232), (236, 228), 3),
                 ink_line((236, 206), (242, 216), (240, 228), 2), ink_line((244, 200), (250, 212), (248, 224), 2),
                 (path(rough([(222, 196), (240, 194), (240, 206), (224, 208)], amp=0.4)), INK)]
        marks.append((path(knob(232, 236, 3, 5)), INK))
        form(p, [face, nose], ((248, 170), (266, 210), (240, 252)), toward=(1, 0.2), marks=marks,
             color=PAPER, sw=3.5, rows=1, count=3, lmin=3, lmax=6, w=3, gap=5)
        eyes(p, [(230, 201)], 4)
    with p.group("hat", (254, 176)):
        brim = [(176, 176), (214, 160), (262, 154), (312, 160), (330, 170), (304, 184), (254, 186), (204, 186)]
        cone = [(214, 164), (230, 120), (256, 84), (290, 54), (330, 40), (352, 46), (334, 62), (310, 80),
                (296, 110), (292, 160)]
        band = [(216, 152), (292, 146), (294, 162), (214, 166)]
        cloth(p, [brim, cone][1], ((300, 48), (300, 110), (296, 170)), toward=(1, 0.2),
              fold_lines=[((262, 90), (254, 124), (248, 156))], color=INK, sw=5, count=4,
              marks=lit_edge([(222, 150), (240, 108), (274, 70)], inward=(1, 0.3), offset=8, w=4, rows=1))
        form(p, [brim], ((250, 150), (330, 176), (250, 196)), toward=(0.3, 1), color=INK, sw=5, rows=0,
             count=4, lmin=4, lmax=10, w=3, marks=lit_edge([(186, 176), (230, 164), (290, 162)], inward=(0, 1),
                                                         offset=5, w=3, rows=1))
        p.part([band], color=VIOLET, sw=3)


def near_arm(p):
    with p.group("sleeve_near", (240, 240)):
        sleeve = ([(244, 232), (210, 250), (182, 272), (174, 290)] + hem((180, 300), (250, 300), 3, 18, lean=0.1)
                  + [(262, 262)])
        cloth(p, sleeve, ((246, 236), (210, 270), (186, 302)), toward=(0.4, 1),
              fold_lines=[((236, 250), (210, 268), (192, 288))], color=INK, sw=5, count=4)
    with p.group("hand_near", (176, 292)):
        finger_bones(p, (168, 296), math.pi * 0.75, fingers=4, length=22, spread=1.2, w=7, curl=-0.9,
                     palm=10, color=PAPER, sw=3)
    with p.group("potion", (160, 312)):
        flask = [(152, 302), (164, 302), (164, 314), (178, 326), (178, 346), (166, 356), (150, 356),
                 (138, 346), (138, 326), (152, 314)]
        brew = [(140, 334), (176, 334), (176, 346), (166, 354), (150, 354), (140, 346)]
        form(p, [flask], ((166, 300), (182, 330), (166, 360)), toward=(1, 0.1), color=PAPER, sw=3, rows=0,
             count=2, lmin=2, lmax=4, w=2,
             marks=[(path(brew), VIOLET), paper_line((144, 330), (144, 340), (148, 348), 3)])
        drip = taper([(150, 358), (148, 368), (148, 376)], 6, 2)
        p.part([drip], color=VIOLET, sw=2.5)


def cauldron(p):
    with p.group("cauldron", (138, 420)):
        legs = [[(92, 440), (104, 444), (98, 466), (88, 466)], [(172, 444), (184, 440), (190, 466), (180, 466)]]
        p.part(legs, color=INK, sw=3)
        pot = [(72, 388), (204, 388), (212, 412), (206, 438), (186, 456), (138, 462), (92, 456), (72, 438), (66, 412)]
        marks = lit_edge([(78, 400), (84, 430), (104, 450)], inward=(1, -0.2), offset=8, w=4, rows=2)
        marks += [paper_line((96, 404), (98, 420), (104, 436), 4)]
        form(p, [pot], ((170, 386), (208, 430), (170, 466)), toward=(1, 0.2), color=INK, sw=4, rows=0,
             count=3, lmin=4, lmax=8, w=3, marks=marks)
        rim = [(64, 380), (212, 380), (216, 394), (60, 394)]
        p.part([rim], color=INK, sw=3.5, marks=[paper_line((76, 384), (130, 382), (190, 384), 3)])
        brew = [(72, 378), (100, 370), (140, 368), (180, 370), (206, 378), (180, 384), (100, 384)]
        p.part([brew], color=VIOLET, sw=3, marks=[(path(bubble(x, y, r)), PAPER) for x, y, r in
                                                   ((104, 376, 5), (150, 374, 6), (178, 378, 4))])
    with p.group("bubbles", (140, 340)):
        polys = [bubble(x, y, r) for x, y, r in ((120, 356, 7), (148, 344, 9), (168, 358, 6), (132, 324, 8),
                                                 (110, 300, 5), (150, 304, 6), (126, 270, 4))]
        steam = [taper(wave((x, 300), (x + 16, 220), 8, waves=1.2, n=12, phase=x * 0.2), 8, 2)
                 for x in (96, 130)]
        p.part(polys + steam, color=VIOLET, sw=2.5,
               marks=[(path(knob(x - 2, y - 2, r * 0.35, 5)), PAPER) for x, y, r in ((148, 344, 9), (132, 324, 8))])


def build():
    p = Print2(VIOLET, seed=67)
    with p.group("ground", (260, 470)):
        ground(p, 60, 430, 466)
    the_staff(p)
    far_arm(p)
    cloak(p)
    cauldron(p)
    near_arm(p)
    head(p)
    return p


if __name__ == "__main__":
    build().save("witch")
