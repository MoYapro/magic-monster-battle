"""Frost Mage (linocut v2): an old sorcerer in a long robe and mantle with a high pointed collar,
frost runes carved along hem and sleeves, a staff crowned by a jagged ice cluster, and a swirl of
ice shards and snowflake sparks around his casting hand. Frost crystals grow at his feet."""
import math

from helpers_a import Print2, finger_bones, form, ink_line, paper_line
from helpers_b import spline
from helpers_f import (cloth, crystal, hem, lit_edge, rune_marks, snowflake, spike_cluster, staff, strands,
                       swirl)
from style import INK, PAPER, eyes, ground, knob, path, rough, taper

ICE = "#9cc8e6"


def the_staff(p):
    with p.group("staff", (358, 262)):
        staff(p, (364, 468), (352, 150), w=12, crook=-6, knots=3, color=PAPER)
    with p.group("staff_crystal", (352, 146)):
        base = (352, 140)
        spikes = spike_cluster(base, [(-math.pi / 2, 118, 40), (-math.pi * 0.7, 78, 32), (-math.pi * 0.32, 80, 32),
                                      (-math.pi * 0.88, 50, 22), (-math.pi * 0.12, 52, 22), (-math.pi * 0.6, 92, 22),
                                      (-math.pi * 0.42, 60, 18)])
        facets = [ink_line((352, 136), (353, 90), (351, 44), 3), paper_line((344, 128), (342, 96), (346, 62), 4),
                  ink_line((346, 132), (326, 110), (304, 98), 2.5), ink_line((358, 132), (378, 108), (398, 98), 2.5)]
        form(p, spikes, ((362, 40), (380, 110), (370, 150)), toward=(1, 0.1), marks=facets, color=ICE, sw=4,
             rows=0, count=3, lmin=4, lmax=8, w=3)
        claws = [taper([(340, 152), (336, 132)], 7, 3), taper([(364, 152), (368, 132)], 7, 3)]
        p.part(claws, color=INK, sw=3)


def mantle(p):
    with p.group("mantle", (290, 190)):
        outline = ([(250, 178), (300, 172), (338, 196), (356, 260), (370, 340), (382, 420), (392, 456)]
                   + hem((392, 456), (300, 460), 4, 14, lean=-0.1) + [(300, 300), (286, 220)])
        cloth(p, outline, ((300, 174), (330, 300), (360, 470)), toward=(1, 0.05),
              fold_lines=[((330, 220), (350, 330), (364, 446))], color=INK, sw=5, count=6)


def far_arm(p):
    with p.group("sleeve_far", (306, 196)):
        sleeve = [(292, 188), (322, 204), (348, 234), (356, 270), (344, 292), (322, 286), (304, 254), (292, 226)]
        cloth(p, sleeve, ((320, 196), (352, 244), (340, 296)), toward=(1, 0.3),
              fold_lines=[((304, 212), (320, 240), (326, 270))], sw=4, count=4)
    with p.group("hand_far", (358, 262)):
        finger_bones(p, (364, 262), math.pi * 1.05, fingers=4, length=20, spread=1.1, w=8, curl=-1.3,
                     palm=11, color=PAPER, sw=3)


def robe(p):
    with p.group("robe", (262, 200)):
        outline = [(222, 184), (264, 178), (304, 190), (318, 232), (326, 300), (336, 370), (346, 430),
                   (352, 456), (300, 460), (240, 460), (182, 456), (190, 400), (200, 320), (208, 250), (212, 210)]
        fold_lines = [((240, 300), (236, 372), (228, 432)), ((276, 300), (286, 372), (296, 432)),
                      ((214, 320), (206, 380), (198, 432))]
        hi = lit_edge([(212, 220), (204, 300), (194, 400)], inward=(1, 0), offset=10, w=4)
        cloth(p, outline, ((262, 182), (278, 320), (300, 472)), toward=(1, 0.05), fold_lines=fold_lines,
              marks=hi, count=9)
    with p.group("robe_trim", (266, 446)):
        band = [(184, 432), (300, 436), (350, 432), (354, 458), (300, 462), (180, 458)]
        p.part([band], color=INK, sw=3.5, marks=rune_marks((194, 446), (344, 446), 9, 20))
        front = taper(spline([(250, 214), (246, 320), (240, 434)], 5), 16, 18)
        p.part([front], color=INK, sw=3, marks=rune_marks((249, 236), (242, 420), 7, 14))
    with p.group("belt", (262, 292)):
        belt = [(204, 284), (320, 290), (322, 304), (204, 300)]
        clasp = [(path(q), ICE) for q in snowflake(250, 294, 12, w=3.2)]
        p.part([belt], marks=clasp, color=INK, sw=3)


def collar(p):
    with p.group("collar", (262, 196)):
        left = [(214, 198), (196, 118), (240, 176)]
        right = [(286, 176), (316, 128), (310, 198)]
        back = [(214, 198), (236, 170), (262, 176), (290, 168), (310, 198), (262, 206)]
        cloth(p, [left, right, back][2], ((290, 166), (306, 186), (300, 210)), toward=(1, 0.3), color=INK,
              sw=4, count=2)
        form(p, [left, right], ((300, 100), (330, 150), (318, 204)), toward=(1, 0.1), color=ICE, sw=4,
             rows=0, count=3, lmin=4, lmax=8, w=3,
             marks=[ink_line((200, 126), (214, 160), (222, 194), 2.5), ink_line((312, 136), (306, 162), (302, 194), 2.5)])


def head(p):
    with p.group("hair", (274, 160)):
        hair = [(236, 104), (268, 96), (296, 112), (310, 152), (312, 196), (300, 214), (290, 186), (282, 206),
                (272, 176), (262, 150)]
        form(p, [hair], ((296, 100), (316, 160), (300, 220)), toward=(1, 0.1), color=PAPER, sw=3.5, rows=0,
             count=3, lmin=3, lmax=6, w=2, marks=strands(((246, 104), (296, 112)), ((278, 196), (304, 206)), 6, 3))
    with p.group("face", (240, 186)):
        face = [(218, 128), (226, 108), (246, 100), (266, 108), (270, 132), (266, 160), (258, 180), (232, 184),
                (218, 166)]
        sockets = [[(224, 140), (238, 138), (238, 150), (226, 152)], [(244, 138), (258, 138), (258, 150), (246, 150)]]
        marks = [(path(rough(q, amp=0.5)), INK) for q in sockets]
        marks += [ink_line((220, 136), (232, 128), (242, 138), 6, 3), ink_line((244, 136), (254, 128), (264, 136), 5, 3),
                  ink_line((232, 116), (246, 112), (260, 118), 2.2), ink_line((228, 124), (244, 120), (262, 126), 2),
                  ink_line((262, 150), (266, 162), (262, 172), 2)]
        form(p, [face], ((262, 100), (276, 146), (258, 188)), toward=(1, 0.2), marks=marks, color=PAPER,
             sw=3.5, rows=1, count=3, lmin=3, lmax=6, w=3, gap=5)
        eyes(p, [(231, 145), (251, 144)], 3.6)
        nose = [(228, 148), (214, 168), (220, 174), (232, 168)]
        form(p, [nose], ((230, 150), (234, 160), (230, 174)), toward=(1, 0.3), color=PAPER, sw=3, rows=0,
             count=1, lmin=2, lmax=3, w=2)
    with p.group("circlet", (246, 108)):
        band = taper(spline([(222, 116), (246, 106), (270, 114)], 5), 6, 6)
        gem = [(240, 112), (246, 96), (252, 112), (246, 120)]
        p.part([band, gem], color=ICE, sw=3)
    with p.group("beard", (238, 180)):
        beard = [(214, 166), (232, 176), (252, 174), (268, 166), (268, 206), (260, 244), (250, 276),
                 (240, 306), (232, 278), (222, 240), (214, 204)]
        marks = strands(((218, 178), (264, 178)), ((234, 276), (250, 276)), 7, 3, sway=6)
        marks.append(ink_line((214, 174), (234, 166), (256, 174), 6, 2))
        form(p, [beard], ((256, 170), (264, 236), (240, 308)), toward=(1, 0.1), marks=marks, color=PAPER,
             sw=4, rows=0, count=4, lmin=3, lmax=7, w=2)


def near_arm(p):
    with p.group("sleeve_near", (236, 200)):
        bell = ([(242, 190), (204, 198), (168, 210), (150, 216)]
                + hem((146, 230), (154, 300), 3, 10, lean=-1.0)
                + [(186, 300), (222, 288), (246, 252)])
        cloth(p, bell, ((240, 196), (196, 236), (160, 306)), toward=(0.5, 1),
              fold_lines=[((226, 214), (196, 240), (176, 288)), ((206, 206), (180, 236), (164, 284))],
              marks=lit_edge([(236, 192), (196, 202), (158, 214)], inward=(0, 1), offset=7, w=4, rows=1),
              sw=5, count=5)
        cuff = taper(spline([(152, 214), (148, 256), (156, 300)], 5), 14, 14)
        p.part([cuff], color=INK, sw=3, marks=rune_marks((152, 224), (154, 292), 4, 12))
    with p.group("hand_near", (140, 222)):
        finger_bones(p, (132, 218), math.pi * 1.15, fingers=4, length=30, spread=1.3, w=8, curl=-0.15,
                     palm=12, color=PAPER, sw=3)


def magic(p):
    center = (78, 206)
    with p.group("frost_aura", center):
        arcs = []
        for a0, a1, r in ((-2.5, -1.4, 68), (0.9, 2.0, 66)):
            pts = [(center[0] + math.cos(a0 + (a1 - a0) * t / 8) * r, center[1] + math.sin(a0 + (a1 - a0) * t / 8) * r)
                   for t in range(9)]
            arcs.append(taper(pts, 7, 2))
        p.part(arcs, color=ICE, sw=2.5)
    with p.group("ice_swirl", center):
        shards = swirl(center, 8, 16, 52, turns=1.0, start=-0.4, L0=18, L1=40, w0=8, w1=15)
        form(p, shards, ((40, 150), (30, 230), (70, 280)), toward=(-0.6, 1), color=ICE, sw=3, rows=0,
             count=2, lmin=2, lmax=4, w=2)
    with p.group("snowflakes", center):
        flakes = []
        for x, y, r in ((116, 150, 11), (26, 158, 9), (36, 280, 10), (112, 290, 8), (78, 128, 7)):
            flakes += snowflake(x, y, r, rot=x * 0.05)
        p.part(flakes, color=PAPER, sw=2.5)


def frost(p):
    with p.group("frost", (260, 466)):
        polys = [crystal(x, 470, h, w) for x, h, w in ((150, 40, 18), (170, 24, 12), (132, 22, 12),
                                                        (374, 32, 15), (394, 20, 11), (214, 18, 10))]
        form(p, polys, ((150, 420), (170, 450), (160, 476)), toward=(1, 0.1), color=ICE, sw=3, rows=0,
             count=2, lmin=2, lmax=4, w=2,
             marks=[paper_line((x - 3, 466), (x - 4, 466 - h * 0.4), (x - 2, 470 - h * 0.8), 2.5)
                    for x, h in ((150, 40), (374, 32))])


def build():
    p = Print2(ICE, seed=61)
    with p.group("ground", (260, 470)):
        ground(p, 96, 430, 466)
    the_staff(p)
    mantle(p)
    far_arm(p)
    robe(p)
    collar(p)
    head(p)
    near_arm(p)
    magic(p)
    frost(p)
    return p


if __name__ == "__main__":
    build().save("frost_mage")
