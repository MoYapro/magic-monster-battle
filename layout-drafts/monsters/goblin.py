"""Goblin (linocut v2): a wiry, hunched pest with big ears, a hooked nose, a nasty grin and a curved knife."""
import math

from helpers_a import Print2, curve_cut, finger_bones, form, ink_line, paper_line, sinew, wrap_lines
from style import INK, PAPER, bezier, eyes, ground, knob, path, rag, rng, rough, sliver, taper

GREEN = "#7aa653"

J = dict(
    neck=(250, 226),
    sh_near=(216, 240), el_near=(166, 276), wr_near=(138, 234),
    sh_far=(300, 238), el_far=(334, 294), wr_far=(328, 346),
    hip_near=(240, 332), kn_near=(190, 386), an_near=(204, 446),
    hip_far=(284, 332), kn_far=(330, 386), an_far=(318, 446),
)


def ear(p, name, root_top, root_bot, tip, sag):
    with p.group(name, ((root_top[0] + root_bot[0]) / 2, (root_top[1] + root_bot[1]) / 2)):
        upper = bezier(root_top, ((root_top[0] + tip[0]) / 2, root_top[1] - sag), tip, 8)
        lower = bezier(tip, ((root_bot[0] + tip[0]) / 2, root_bot[1] + sag * 0.3), root_bot, 8)
        notch = len(lower) // 2
        lower[notch] = (lower[notch][0], lower[notch][1] - 7)
        inner = ink_line(((root_top[0] * 2 + tip[0]) / 3, (root_top[1] + root_bot[1]) / 2),
                         ((root_top[0] + tip[0]) / 2, (root_top[1] + tip[1]) / 2 + 4),
                         (tip[0] * 0.9 + root_top[0] * 0.1, tip[1] + 6), 4, 1)
        mid = ((root_bot[0] + tip[0]) / 2, (root_bot[1] + tip[1]) / 2 + 6)
        form(p, [upper + lower[1:]], (root_bot, mid, tip), toward=(0.2, 1), marks=[inner], sw=4.5,
             rows=0, count=4, lmin=5, lmax=10, w=3)


def head(p):
    with p.group("head", J["neck"], offset=(-6, 14)):
        ear(p, "ear_far", (206, 150), (204, 176), (118, 124), 14)
        skull = [(196, 142), (214, 118), (244, 108), (272, 116), (288, 140), (288, 176), (276, 204),
                 (256, 224), (228, 238), (206, 234), (194, 216), (188, 190), (190, 164)]
        mouth = [(196, 210), (214, 216), (238, 212), (260, 198), (258, 212), (240, 226), (214, 230), (198, 224)]
        marks = [(path(rough(mouth, amp=0.8)), INK)]
        marks += [(sliver(202 + i * 9.5, 214 - max(0, i - 2) * 2.5, math.pi / 2 + 0.1, 9, 6), PAPER) for i in range(6)]
        marks += [(sliver(206 + i * 10, 228 - max(0, i - 2) * 2, -math.pi / 2, 7, 5), PAPER) for i in range(4)]
        marks += [(sliver(196, 158, -0.35, 26, 8), INK), (sliver(254, 152, math.pi + 0.45, 30, 9), INK)]
        marks += [ink_line((214, 126), (236, 120), (258, 126), 2.5), ink_line((210, 136), (234, 130), (262, 136), 2.5),
                  ink_line((244, 170), (258, 186), (256, 204), 2.5), ink_line((206, 236), (218, 242), (234, 236), 2)]
        form(p, [skull], ((262, 108), (296, 160), (250, 232)), toward=(1, 0.45), marks=marks, sw=5,
             rows=2, count=6, lmin=6, lmax=14, w=4, gap=7)
        p.fill(path(rough(knob(206, 168, 9, 6, 0.3), amp=0.6)), INK)
        p.fill(path(rough(knob(239, 164, 10, 6, 0.3), amp=0.6)), INK)
        eyes(p, [(207, 168), (240, 164)], 5.5)
        nose = [(214, 164), (226, 170), (222, 190), (206, 208), (190, 210), (186, 202), (200, 194), (208, 180)]
        form(p, [nose], ((222, 168), (220, 194), (200, 212)), toward=(1, 0.6), sw=3.5, rows=0, count=2,
             lmin=3, lmax=6, w=2)
        ear(p, "ear_near", (276, 140), (280, 178), (378, 112), 16)


def torso(p):
    with p.group("torso", ((J["hip_near"][0] + J["hip_far"][0]) / 2, 334)):
        neck = [(234, 214), (266, 212), (272, 240), (236, 244)]
        form(p, [neck], ((256, 210), (264, 228), (262, 246)), toward=(1, 0.3), sw=4, rows=0, count=2,
             lmin=3, lmax=6, w=2)
        tunic = [(210, 242), (236, 232), (256, 244), (276, 232), (298, 236), (312, 264), (314, 306),
                 (304, 338), (260, 346), (228, 340), (220, 300), (212, 284), (204, 266)]
        strap = [(path(taper([(222, 244), (262, 286), (300, 330)], 10, 10)), INK)]
        folds = [ink_line((226, 270), (232, 300), (230, 330), 3), ink_line((262, 296), (268, 316), (264, 340), 3),
                 ink_line((244, 250), (238, 268), (244, 290), 2.5), ink_line((212, 262), (224, 252), (240, 246), 2.5),
                 (path([(246, 232), (256, 250), (266, 232)]), INK)]
        patch = [(path(rough([(232, 262), (252, 260), (254, 280), (234, 282)], amp=1)), INK)]
        stitches = [(sliver(232 + i * 6, 262, math.pi / 2, 6, 2.5), PAPER) for i in range(4)]
        form(p, [tunic], ((272, 228), (296, 290), (268, 348)), toward=(1, 0.3), color=PAPER,
             marks=strap + folds + patch + stitches, sw=5, rows=2, count=6, lmin=8, lmax=16, w=4, gap=8)
    with p.group("tunic_hem", (262, 340)):
        rag(p, (220, 326), (316, 326), 48, tatters=6, color=INK)
    with p.group("belt", (262, 322)):
        belt = [(216, 314), (314, 310), (316, 326), (218, 330)]
        buckle = [(path(rough([(244, 312), (260, 312), (260, 330), (244, 330)], amp=0.6)), PAPER),
                  (path([(248, 316), (256, 316), (256, 326), (248, 326)]), INK)]
        p.part([belt], marks=buckle, color=INK, sw=3.5)
        pouch = [(292, 322), (312, 320), (314, 346), (300, 352), (290, 344)]
        form(p, [pouch], ((304, 318), (310, 336), (302, 354)), toward=(1, 0.3), color=PAPER, sw=3.5, rows=0,
             count=2, lmin=3, lmax=6, w=2)


def leg(p, side, toe_x, heel_x):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        sinew(p, hp, kn, 26, 18, bulge=1.25)
    with p.group(f"shin_{side}", kn):
        sinew(p, kn, an, 18, 13, bulge=1.15, marks=wrap_lines((kn[0] + (an[0] - kn[0]) * 0.35,
                                                               kn[1] + (an[1] - kn[1]) * 0.35), an, 12, 4))
        p.part([knob(*kn, 11, 7)], marks=[paper_line((kn[0] - 6, kn[1] - 4), (kn[0], kn[1] - 8), (kn[0] + 6, kn[1] - 4), 2)],
               sw=3.5)
    with p.group(f"foot_{side}", an):
        ax, ay = an
        foot = [(heel_x, 466), (heel_x - 2, 452), (ax + 4, ay - 4), (ax - 12, ay + 2), (toe_x + 14, 456),
                (toe_x, 466), (toe_x, 472), (heel_x, 472)]
        marks = [(path(taper([(ax - 16 + i * 10, ay + 2), (ax - 10 + i * 10, 462), (ax - 6 + i * 10, 472)], 3, 2)), INK)
                 for i in range(3)]
        form(p, [foot], ((ax + 6, 446), (ax + 2, 462), (heel_x - 6, 474)), toward=(1, 0.3), color=GREEN,
             marks=marks, sw=4, rows=0, count=3, lmin=3, lmax=6, w=2)
        claws = [taper(bezier((toe_x + 4 + i * 7, 468), (toe_x - 4 + i * 7, 468), (toe_x - 10 + i * 6, 474), 6), 5, 1)
                 for i in range(3)]
        p.part(claws, color=PAPER, sw=2.5)


def arm(p, side):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        sinew(p, sh, el, 20, 15, bulge=1.25)
    with p.group(f"forearm_{side}", el):
        sinew(p, el, wr, 16, 12, bulge=1.3, at=0.3, marks=wrap_lines(
            (el[0] + (wr[0] - el[0]) * 0.65, el[1] + (wr[1] - el[1]) * 0.65), wr, 9, 2))


def knife(p):
    hx, hy = J["wr_near"][0] - 4, J["wr_near"][1] - 6
    with p.group("knife", (hx, hy)):
        grip = taper([(hx + 8, hy + 22), (hx, hy), (hx - 6, hy - 14)], 10, 9)
        p.part([grip], marks=wrap_lines((hx + 8, hy + 22), (hx - 6, hy - 14), 6, 3), color=INK, sw=3)
        base0, base1 = (hx - 18, hy - 10), (hx - 2, hy - 26)
        tip = (hx - 84, hy - 62)
        back = bezier(base1, (hx - 24, hy - 76), tip, 12)
        edge = bezier(tip, (hx - 46, hy - 30), base0, 12)
        for k in (4, 8):
            edge[k] = (edge[k][0] + 1, edge[k][1] - 4)
        blade = back + edge[1:]
        shade = path(bezier((hx - 8, hy - 20), (hx - 34, hy - 52), tip, 10) + [(hx - 120, hy), (hx + 20, hy + 20)])
        marks = [paper_line((hx - 10, hy - 30), (hx - 26, hy - 64), (hx - 70, hy - 66), 2.5, 1)]
        marks += [(path(rough(knob(hx - 40 + d, hy - 44 + d * 0.2, 3, 5), amp=0.4)), INK) for d in (0, 16)]
        p.part([blade], shade, marks, color=PAPER, sw=3.5)
        guard = taper([(hx - 22, hy - 4), (hx - 8, hy - 18), (hx + 6, hy - 32)], 8, 6)
        p.part([guard], color=INK, sw=3)


def hand(p, side, at, angle, curl, length):
    with p.group(f"hand_{side}", J[f"wr_{side}"]):
        finger_bones(p, at, angle, fingers=4, length=length, spread=1.0, w=9, curl=curl, palm=13,
                     color=GREEN, sw=3.5)
        tips = []
        for i in range(4):
            a = angle + 1.0 * (i / 3 - 0.5)
            tx, ty = at[0] + math.cos(a + curl) * length, at[1] + math.sin(a + curl) * length
            tips.append(taper([(tx, ty), (tx + math.cos(a + curl) * 9, ty + math.sin(a + curl) * 9)], 5, 1))
        p.part(tips, color=PAPER, sw=2.5)


def build():
    p = Print2(GREEN, seed=31)
    with p.group("ground", (260, 470)):
        ground(p, 130, 400, 468)
    arm(p, "far")
    hand(p, "far", (330, 352), math.pi * 0.5, 0.35, 30)
    leg(p, "far", 286, 338)
    leg(p, "near", 160, 222)
    torso(p)
    head(p)
    arm(p, "near")
    knife(p)
    hand(p, "near", (140, 232), math.pi * 1.1, 1.6, 18)
    return p


if __name__ == "__main__":
    build().save("goblin")
