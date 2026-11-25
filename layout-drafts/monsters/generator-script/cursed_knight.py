"""Cursed Knight (linocut v2): battered plate armour, closed helm leaking dark smoke,
a notched cursed blade held low and a kite shield on the far arm."""
import math

from helpers_a import Print2, form, ink_line, paper_line
from helpers_e import (cloth, joint_cap, kite_shield, plated, rivets, scratches, smoke, sword, torn_hem,
                       visor_slit)
from style import EMBER, INK, PAPER, eyes, ground, knob, path, rough, sliver

STEEL = "#8f86ad"   # dusty violet: the knight's dark violet, light enough to print

J = dict(
    sh_near=(200, 172), el_near=(180, 238), wr_near=(168, 296),
    sh_far=(300, 168), el_far=(322, 226), wr_far=(330, 276),
    hip_near=(228, 302), kn_near=(208, 378), an_near=(196, 446),
    hip_far=(284, 302), kn_far=(308, 376), an_far=(322, 446),
)


def helm_smoke(p):
    with p.group("smoke", (266, 72)):
        smoke(p, [((256, 70), (300, 16), 28, 16, 0.3), ((272, 78), (360, 26), 24, 18, 1.6),
                  ((280, 96), (392, 80), 18, 14, 2.6)], color=STEEL, stroke_color=INK)


def helm(p):
    with p.group("helm", (246, 140)):
        shell = [(214, 74), (238, 62), (264, 62), (280, 72), (284, 100), (282, 128), (274, 140), (244, 144),
                 (216, 140), (210, 122), (198, 110), (194, 100), (206, 90), (208, 80)]
        marks = [visor_slit(228, 96, 44, 7), visor_slit(232, 110, 30, 4),
                 ink_line((236, 62), (222, 92), (224, 142), 3, 3),
                 ink_line((210, 126), (246, 132), (282, 126), 3),
                 ink_line((210, 82), (244, 76), (280, 80), 2.5)]
        marks += [(sliver(214 + i * 6, 124, math.pi / 2, 9, 3), INK) for i in range(4)]
        marks += rivets([(270, 96), (272, 116), (262, 132)], 2.4)
        marks += scratches(258, 86, 14, 12, 3)
        form(p, [shell], ((248, 50), (282, 96), (250, 150)), toward=(1, 0.35), marks=marks, sw=4.5, rows=2,
             count=6, lmin=6, lmax=14, w=4, gap=8)
        eyes(p, [(216, 96), (236, 96)], 3)


def gorget(p):
    with p.group("gorget", (248, 158)):
        g = [(216, 140), (282, 140), (290, 164), (246, 170), (208, 164)]
        form(p, [g], ((262, 138), (284, 154), (268, 172)), toward=(1, 0.4),
             marks=[ink_line((210, 154), (248, 160), (288, 154), 2.5)], sw=4, rows=0, count=3,
             lmin=4, lmax=8, w=3)


def torso(p):
    with p.group("torso", (252, 230)):
        plate = [(190, 160), (250, 148), (312, 158), (320, 196), (300, 236), (288, 280), (252, 292),
                 (220, 284), (206, 238), (188, 198)]
        marks = [ink_line((244, 156), (238, 220), (246, 292), 3),
                 ink_line((200, 240), (252, 252), (306, 238), 3),
                 ink_line((198, 262), (252, 274), (302, 260), 2.5)]
        marks += rivets([(212, 236), (292, 234), (226, 168), (286, 166)], 2.6)
        marks += scratches(232, 200, 26, 30, 5)
        marks += [paper_line((262, 188), (266, 206), (258, 222), 2.5, 0.8),   # a cursed crack
                  (path(rough([(258, 196), (264, 200), (262, 210)], amp=0.4)), STEEL)]
        form(p, [plate], ((268, 150), (300, 222), (266, 298)), toward=(1, 0.3), marks=marks, sw=5, rows=2,
             count=8, lmin=8, lmax=18, w=5, gap=10)


def pauldron(p, side):
    sh = J[f"sh_{side}"]
    x, y = sh
    with p.group(f"pauldron_{side}", sh):
        if side == "near":
            lames = [[(x - 34, y - 14), (x - 6, y - 26), (x + 22, y - 18), (x + 26, y + 4), (x - 30, y + 8)],
                     [(x - 38, y + 2), (x + 24, y), (x + 22, y + 20), (x - 34, y + 24)],
                     [(x - 36, y + 18), (x + 18, y + 16), (x + 14, y + 34), (x - 30, y + 38)]]
        else:
            lames = [[(x - 18, y - 16), (x + 6, y - 22), (x + 28, y - 10), (x + 30, y + 10), (x - 10, y + 8)],
                     [(x - 8, y + 4), (x + 30, y + 6), (x + 28, y + 24), (x - 4, y + 22)]]
        if side == "near":
            spikes = [[(x - 24 + k * 16, y - 18 - k * 3), (x - 16 + k * 16, y - 44 - k * 4), (x - 10 + k * 16, y - 20 - k * 3)]
                      for k in range(3)]
            p.part(spikes, color=INK, sw=3)
        for i, lame in enumerate(lames):
            xs, ys = [q[0] for q in lame], [q[1] for q in lame]
            cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
            form(p, [lame], ((cx + 6, min(ys) - 4), (max(xs) + 2, cy), (cx + 4, max(ys) + 4)), toward=(1, 0.4),
                 marks=rivets([(cx - 10, cy + 2)], 2.2), sw=4, rows=0, count=2, lmin=4, lmax=8, w=3)


def arm(p, side):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        plated(p, sh, el, 26, 22, seams=(0.45,))
    with p.group(f"forearm_{side}", el):
        plated(p, el, wr, 22, 20, seams=(0.3, 0.65))
        joint_cap(p, el, 14)


def gauntlet(p, side, at, ang):
    x, y = at
    with p.group(f"hand_{side}", at):
        fist = knob(x, y, 14, 7, 0.4)
        cuff = [(x + 10 * math.cos(ang + 2.6), y + 10 * math.sin(ang + 2.6) - 8),
                (x + 18, y - 12), (x + 16, y + 6), (x - 2, y + 10)]
        marks = [ink_line((x - 10, y - 2), (x - 2, y + 4), (x + 8, y + 2), 2.5),
                 ink_line((x - 10, y + 5), (x - 2, y + 10), (x + 8, y + 8), 2.5)]
        form(p, [fist, cuff], ((x + 2, y - 14), (x + 12, y), (x + 2, y + 14)), toward=(1, 0.5), marks=marks,
             sw=4, rows=0, count=2, lmin=3, lmax=6, w=2.5)


def shield(p):
    with p.group("shield", J["wr_far"]):
        ring = knob(352, 262, 20, 14, 0.1)
        hole = knob(352, 262, 11, 10, 0.3)
        emblem = [(path(rough(ring, amp=0.6)) + path(rough(hole[::-1], amp=0.4)), STEEL),
                  (path(knob(352, 262, 5, 6)), INK)]
        emblem += [(sliver(352 + math.cos(a) * 22, 262 + math.sin(a) * 22, a, 16, 7), STEEL)
                   for a in (i * math.pi / 3 + 0.5 for i in range(6))]
        emblem += [ink_line((326, 226), (346, 266), (372, 318), 3, 1.5), ink_line((346, 266), (334, 286), (330, 310), 2, 1)]
        kite_shield(p, 352, 270, 94, 156, color=PAPER, emblem=emblem, dents=6)


def legs(p, side):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        plated(p, hp, kn, 32, 26, seams=(0.5,))
    with p.group(f"shin_{side}", kn):
        plated(p, kn, an, 24, 20, seams=(0.25, 0.6))
        joint_cap(p, kn, 15)
    with p.group(f"foot_{side}", an):
        x, y = an
        foot = [(x - 12, y - 6), (x + 14, y - 8), (x + 16, y + 18), (x - 44, y + 20), (x - 40, y + 8)]
        marks = [ink_line((x - 30, y + 6), (x - 26, y + 12), (x - 24, y + 19), 2.5),
                 ink_line((x - 14, y + 2), (x - 10, y + 10), (x - 8, y + 19), 2.5)]
        form(p, [foot], ((x - 4, y - 8), (x + 12, y + 6), (x + 4, y + 22)), toward=(1, 0.4), marks=marks,
             sw=4, rows=0, count=2, lmin=3, lmax=7, w=2.5)


def skirt(p):
    with p.group("skirt", (254, 292)):
        rag = [(212, 286), (300, 290)] + torn_hem((304, 296), (206, 292), 5, 64, lean=(0.25, 1.0))
        cloth(p, rag, ((262, 284), (284, 316), (262, 344)), color=INK,
              folds=[((236, 300), (234, 320), (238, 336)), ((268, 300), (270, 318), (266, 334))])
    with p.group("faulds", (254, 288)):
        band = [(206, 278), (304, 282), (306, 300), (204, 298)]
        marks = [ink_line((206, 290), (254, 294), (306, 291), 2.5)] + rivets([(220, 288), (250, 290), (286, 290)], 2.2)
        form(p, [band], ((270, 276), (296, 290), (270, 304)), toward=(1, 0.4), marks=marks, sw=4, rows=0,
             count=3, lmin=4, lmax=8, w=3)


def build():
    p = Print2(STEEL, seed=61)
    with p.group("ground", (258, 470)):
        ground(p, 70, 410, 466)
    helm_smoke(p)
    arm(p, "far")
    shield(p)
    legs(p, "far")
    legs(p, "near")
    skirt(p)
    pauldron(p, "far")
    torso(p)
    gorget(p)
    helm(p)
    pauldron(p, "near")
    arm(p, "near")
    with p.group("sword", J["wr_near"]):
        hand = (J["wr_near"][0] - 2, J["wr_near"][1] + 10)
        g, t = sword(p, hand, math.radians(118), 168, 26, notches=(0.3, 0.55, 0.8),
                     marks=[(sliver(hand[0] - 30 - k * 22, hand[1] + 56 + k * 40, math.radians(118), 12, 4),
                             STEEL) for k in range(3)])
    gauntlet(p, "near", (J["wr_near"][0] - 2, J["wr_near"][1] + 8), math.radians(118))
    return p


if __name__ == "__main__":
    build().save("cursed_knight")
