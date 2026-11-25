"""Bone Caller (linocut v2): a hooded necromancer in a black robe, reaching out with a bony hand,
a skull-topped staff in the other, and the dead clawing out of the ground at its feet."""
import math

from helpers_a import Print2, finger_bones, form, ink_line, long_bone
from helpers_f import cloth, hem, lit_edge, staff
from style import INK, PAPER, eyes, ground, knob, path, rough, sliver

BONE = "#cfc4a2"


def small_skull(p, name, cx, cy, s, pivot, socket_eyes=True):
    """A skull facing left, centred on (cx, cy), scaled by s."""
    def S(pts):
        return [(cx + x * s, cy + y * s) for x, y in pts]

    with p.group(name, pivot):
        cranium = S([(-24, -4), (-20, -22), (-4, -32), (16, -30), (28, -16), (28, 4), (20, 16), (12, 20),
                     (8, 30), (-10, 30), (-18, 20), (-24, 10)])
        sockets = [S([(-20, -8), (-10, -10), (-8, 2), (-18, 4)]), S([(-4, -10), (8, -10), (8, 2), (-2, 4)])]
        nose = S([(-12, 8), (-7, 8), (-9, 15)])
        marks = [(path(rough(q, amp=0.5)), INK) for q in sockets + [nose]]
        marks += [(sliver(*S([(-14 + i * 5, 24)])[0], math.pi / 2, 7 * s, 3 * s), INK) for i in range(5)]
        marks.append(ink_line(*S([(6, -30), (12, -20), (8, -12)]), 2))
        form(p, [cranium], tuple(S([(10, -32), (30, 0), (6, 32)])), toward=(1, 0.3), marks=marks, sw=3.5,
             rows=1, count=4, lmin=3, lmax=7, w=3, gap=5)
        if socket_eyes:
            eyes(p, S([(-14, -3), (2, -3)]), 3 * s)


def the_staff(p):
    with p.group("staff", (348, 250)):
        staff(p, (356, 468), (338, 120), w=12, crook=8, knots=4, color=BONE)
        small_skull(p, "staff_skull", 336, 92, 1.15, (338, 120))


def robe(p):
    with p.group("robe", (262, 190)):
        outline = ([(222, 176), (262, 168), (298, 182), (314, 222), (322, 282), (336, 350), (354, 418),
                    (364, 456)] + hem((364, 456), (174, 460), 8, 18, lean=-0.15)
                   + [(184, 410), (196, 332), (204, 262), (210, 210)])
        fold_lines = [((238, 214), (232, 330), (222, 446)), ((268, 226), (278, 336), (290, 452)),
                      ((296, 250), (316, 352), (334, 452)), ((212, 300), (204, 380), (196, 448))]
        hi = lit_edge([(212, 214), (204, 280), (196, 350), (186, 430)], inward=(1, 0), offset=10, w=5)
        cloth(p, outline, ((292, 176), (312, 330), (346, 472)), toward=(1, 0.15), fold_lines=fold_lines,
              marks=hi, color=INK, count=8)
    with p.group("sash", (258, 266)):
        cord = [(208, 258), (262, 264), (310, 262), (312, 274), (262, 278), (206, 272)]
        tail = [(236, 270), (246, 272), (240, 330), (232, 336), (230, 300)]
        form(p, [cord, tail], ((280, 256), (300, 270), (280, 282)), toward=(0.6, 1), color=BONE, sw=3.5,
             rows=0, count=4, lmin=3, lmax=6, w=2,
             marks=[(sliver(214 + i * 14, 266, 1.3, 10, 3), INK) for i in range(7)])


def far_arm(p):
    with p.group("sleeve_far", (300, 192)):
        sleeve = [(288, 186), (316, 200), (340, 228), (344, 258), (322, 266), (302, 246), (288, 222)]
        cloth(p, sleeve, ((316, 194), (342, 236), (330, 270)), toward=(1, 0.3),
              fold_lines=[((300, 208), (314, 230), (318, 254))], color=INK, sw=4, count=4)
    with p.group("hand_far", (342, 252)):
        finger_bones(p, (346, 252), math.pi * 1.05, fingers=4, length=20, spread=1.1, w=5, curl=-1.3,
                     palm=9, color=BONE, sw=3)


def head(p):
    with p.group("hood", (262, 186)):
        hood = [(204, 150), (212, 118), (236, 94), (268, 86), (296, 100), (312, 128), (314, 166), (304, 192),
                (270, 202), (236, 198), (212, 188), (202, 170)]
        hole = [(208, 128), (228, 114), (250, 120), (258, 150), (250, 180), (228, 192), (206, 184), (200, 156)]
        fold_lines = [((268, 96), (290, 130), (296, 186)), ((250, 100), (270, 140), (276, 194))]
        cloth(p, hood, ((280, 90), (312, 140), (296, 200)), toward=(1, 0.3), fold_lines=fold_lines,
              marks=lit_edge([(210, 124), (226, 100), (256, 90)], inward=(0.5, 1), offset=9, w=4, rows=1)
              + [(path(rough(hole, amp=1)), INK)], color=INK, sw=5, count=5)
    with p.group("face", (230, 184)):
        face = [(212, 140), (226, 130), (242, 136), (248, 158), (242, 178), (230, 190), (216, 186), (208, 166)]
        sockets = [[(212, 148), (222, 146), (224, 158), (214, 160)], [(230, 146), (242, 146), (242, 158), (232, 160)]]
        nose = [(220, 164), (226, 164), (223, 172)]
        marks = [(path(rough(q, amp=0.5)), INK) for q in sockets + [nose]]
        marks += [(sliver(216 + i * 5, 182, math.pi / 2, 7, 3), INK) for i in range(5)]
        marks.append(ink_line((236, 134), (244, 146), (240, 156), 2))
        form(p, [face], ((236, 128), (250, 160), (232, 194)), toward=(1, 0.2), marks=marks, sw=3.5,
             rows=1, count=3, lmin=3, lmax=6, w=3, gap=5)
        eyes(p, [(218, 154), (236, 153)], 3.5)


def near_arm(p):
    with p.group("sleeve_near", (232, 196)):
        sleeve = ([(238, 186), (200, 194), (160, 200), (132, 204)] + hem((128, 232), (240, 262), 5, 26, lean=0.2)
                  + [(252, 226)])
        cloth(p, sleeve, ((236, 196), (190, 216), (132, 214)), toward=(0.1, 1),
              fold_lines=[((226, 198), (190, 212), (148, 214)), ((230, 220), (200, 232), (170, 236))],
              marks=lit_edge([(232, 190), (190, 198), (140, 206)], inward=(0, 1), offset=7, w=4, rows=1),
              color=INK, sw=5, count=5)
    with p.group("hand_near", (130, 218)):
        wrist = [(140, 212), (122, 214), (122, 224), (140, 226)]
        form(p, [wrist], ((132, 210), (134, 220), (132, 228)), toward=(1, 0.2), color=BONE, sw=3, rows=0,
             count=1, lmin=2, lmax=3, w=2)
        finger_bones(p, (118, 220), math.pi * 1.02, fingers=4, length=46, spread=1.0, w=6, curl=-0.25,
                     palm=10, color=BONE, sw=3)


def risen_dead(p):
    with p.group("risen_skull", (150, 456)):
        small_skull(p, "risen_skull_bone", 148, 438, 0.9, (150, 456), socket_eyes=False)
    with p.group("risen_arm", (186, 462)):
        long_bone(p, (190, 466), (180, 414), 8, color=BONE)
        finger_bones(p, (178, 406), -math.pi * 0.55, fingers=4, length=24, spread=1.0, w=5, curl=-0.5,
                     palm=7, color=BONE, sw=3)
    with p.group("bones", (390, 460)):
        long_bone(p, (372, 460), (414, 454), 7, color=BONE)
        long_bone(p, (112, 462), (134, 448), 6, color=BONE)


def build():
    p = Print2(BONE, seed=53)
    with p.group("ground", (260, 470)):
        ground(p, 96, 430, 466)
    the_staff(p)
    far_arm(p)
    robe(p)
    head(p)
    near_arm(p)
    risen_dead(p)
    return p


if __name__ == "__main__":
    build().save("bone_caller")
