"""Fallen Paladin (linocut v2): a tall corrupted holy knight with a spiked crown helm, ornate dark
armour, a long tattered cloak and a big two-handed sword lowered in front of it."""
import math

from helpers_a import Print2, form, ink_line, paper_line
from helpers_e import cloth, joint_cap, plated, rivets, scratches, sword, torn_hem, visor_slit
from style import INK, PAPER, eyes, ground, knob, path, rough, sliver

PEWTER = "#968e7f"   # the paladin's tarnished grey-beige

J = dict(
    sh_near=(204, 168), el_near=(180, 234), wr_near=(198, 284),
    sh_far=(302, 164), el_far=(304, 230), wr_far=(222, 272),
    hip_near=(232, 312), kn_near=(214, 386), an_near=(204, 448),
    hip_far=(284, 312), kn_far=(302, 386), an_far=(316, 448),
)
GRIP = (206, 286)
SWORD_ANG = math.radians(124)


def cloak(p):
    with p.group("cloak", (256, 160)):
        back = ([(204, 150), (262, 138), (316, 150), (338, 182), (348, 230), (372, 278), (384, 330), (412, 384), (434, 420)]
                + torn_hem((436, 440), (188, 446), 10, 30, lean=(0.1, 1.0))
                + [(182, 360), (190, 250)])
        folds = [((300, 190), (330, 300), (360, 420)), ((272, 200), (290, 320), (300, 430)),
                 ((330, 220), (370, 320), (400, 410))]
        cloth(p, back, ((320, 150), (352, 300), (396, 440)), color=INK, toward=(1, 0.2), folds=folds, count=8)


def crown_helm(p):
    with p.group("helm", (248, 140)):
        shell = [(216, 72), (240, 64), (266, 66), (282, 80), (286, 108), (280, 132), (250, 142), (218, 138),
                 (208, 118), (198, 106), (208, 96)]
        marks = [visor_slit(228, 100, 40, 6), (path(rough([(225, 100), (231, 100), (231, 128), (225, 128)],
                                                          amp=0.4)), INK),
                 ink_line((206, 118), (246, 126), (284, 120), 2.5),
                 paper_line((244, 70), (240, 100), (244, 136), 2.5, 2.5)]
        marks += rivets([(268, 96), (272, 114)], 2.4)
        form(p, [shell], ((252, 62), (284, 104), (252, 144)), toward=(1, 0.35), marks=marks, sw=4.5, rows=2,
             count=6, lmin=6, lmax=13, w=4, gap=8)
        eyes(p, [(214, 100), (238, 100)], 3)
        band = [(212, 64), (286, 70), (286, 84), (212, 80)]
        spikes = [[(214 + k * 18, 70), (220 + k * 18 + (k - 2) * 2, 30 + abs(k - 2) * 10), (228 + k * 18, 70)]
                  for k in range(5)]
        form(p, [band] + spikes, ((262, 28), (282, 60), (270, 84)), toward=(1, 0.3),
             marks=[(path(knob(220 + k * 18, 74, 3, 5)), INK) for k in range(4)], color=PAPER, sw=3.5,
             rows=0, count=3, lmin=4, lmax=9, w=3)


def torso(p):
    with p.group("torso", (254, 230)):
        plate = [(192, 158), (252, 146), (314, 156), (322, 198), (304, 244), (292, 290), (254, 300),
                 (220, 292), (206, 244), (188, 198)]
        trim = [paper_line((196, 164), (252, 154), (312, 162), 3, 3),
                paper_line((210, 250), (254, 262), (300, 250), 3, 3)]
        sigil = [(path(rough([(246, 176), (258, 176), (257, 236), (247, 236)], amp=0.5)), PAPER),
                 (path(rough([(226, 192), (278, 190), (278, 200), (226, 202)], amp=0.5)), PAPER),
                 ink_line((236, 180), (252, 206), (268, 234), 2.5, 1)]
        marks = trim + sigil + rivets([(206, 230), (298, 228)], 2.6) + scratches(236, 220, 22, 26, 4)
        form(p, [plate], ((272, 146), (306, 222), (270, 302)), toward=(1, 0.3), marks=marks, sw=5, rows=2,
             count=8, lmin=8, lmax=18, w=5, gap=10)


def tabard(p):
    with p.group("tabard", (254, 300)):
        panel = [(222, 292), (290, 294)] + torn_hem((292, 300), (220, 298), 4, 96, lean=(0.05, 1.0), jag=0.4)
        cloth(p, panel, ((264, 290), (284, 340), (264, 396)), toward=(1, 0.2),
              folds=[((240, 304), (238, 340), (242, 380)), ((272, 304), (274, 340), (270, 376))], count=5)
    with p.group("belt", (254, 296)):
        belt = [(208, 288), (302, 290), (302, 304), (206, 302)]
        marks = [(path(knob(250, 297, 7, 6)), PAPER), (path(knob(250, 297, 3, 5)), INK)]
        p.part([belt], marks=marks, color=INK, sw=3.5)


def pauldron(p, side):
    x, y = J[f"sh_{side}"]
    with p.group(f"pauldron_{side}", (x, y)):
        flip = -1 if side == "near" else 1
        lames = [[(x - 30 * -flip if False else x - 30, y - 12), (x - 2, y - 24), (x + 26, y - 14), (x + 30, y + 8),
                  (x - 32, y + 10)],
                 [(x - 34, y + 4), (x + 28, y + 4), (x + 26, y + 24), (x - 30, y + 28)]]
        for lame in lames:
            xs, ys = [q[0] for q in lame], [q[1] for q in lame]
            cx, cy = sum(xs) / len(xs), sum(ys) / len(ys)
            form(p, [lame], ((cx + 6, min(ys) - 4), (max(xs) + 2, cy), (cx + 4, max(ys) + 4)), toward=(1, 0.4),
                 marks=[paper_line((min(xs) + 4, cy - 4), (cx, min(ys) + 2), (max(xs) - 4, cy - 4), 2.5, 2.5)],
                 sw=4, rows=0, count=2, lmin=4, lmax=8, w=3)


def arm(p, side):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        plated(p, sh, el, 26, 22, seams=(0.45,))
    with p.group(f"forearm_{side}", el):
        plated(p, el, wr, 22, 20, seams=(0.35, 0.7))
        joint_cap(p, el, 13)


def gauntlet(p, side, at):
    x, y = at
    with p.group(f"hand_{side}", at):
        fist = knob(x, y, 14, 7, 0.4)
        marks = [ink_line((x - 10, y - 3), (x, y + 3), (x + 10, y - 1), 2.5),
                 ink_line((x - 10, y + 4), (x, y + 10), (x + 10, y + 6), 2.5)]
        form(p, [fist], ((x + 2, y - 14), (x + 12, y), (x + 2, y + 14)), toward=(1, 0.5), marks=marks, sw=4,
             rows=0, count=2, lmin=3, lmax=6, w=2.5)


def leg(p, side):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        plated(p, hp, kn, 32, 26, seams=(0.5,))
    with p.group(f"shin_{side}", kn):
        plated(p, kn, an, 25, 21, seams=(0.3, 0.65))
        joint_cap(p, kn, 15)
    with p.group(f"foot_{side}", an):
        x, y = an
        foot = [(x - 12, y - 6), (x + 14, y - 8), (x + 16, y + 18), (x - 46, y + 20), (x - 42, y + 8)]
        form(p, [foot], ((x - 4, y - 8), (x + 12, y + 6), (x + 4, y + 22)), toward=(1, 0.4),
             marks=[ink_line((x - 26, y + 6), (x - 22, y + 12), (x - 20, y + 19), 2.5)], sw=4, rows=0, count=2,
             lmin=3, lmax=7, w=2.5)


def greatsword(p):
    with p.group("sword", GRIP):
        runes = [(sliver(GRIP[0] + math.cos(SWORD_ANG) * d, GRIP[1] + math.sin(SWORD_ANG) * d, SWORD_ANG, 12, 5),
                  INK) for d in (60, 96, 132)]
        sword(p, GRIP, SWORD_ANG, 196, 32, color=PAPER, notches=(0.62,), guard=34, grip=40, marks=runes,
              pommel=9)


def build():
    p = Print2(PEWTER, seed=73)
    with p.group("ground", (258, 470)):
        ground(p, 60, 440, 468)
    cloak(p)
    leg(p, "far")
    leg(p, "near")
    tabard(p)
    pauldron(p, "far")
    arm(p, "far")
    torso(p)
    crown_helm(p)
    pauldron(p, "near")
    arm(p, "near")
    greatsword(p)
    gauntlet(p, "far", (J["wr_far"][0] - 4, J["wr_far"][1] + 4))
    gauntlet(p, "near", (J["wr_near"][0] + 2, J["wr_near"][1] + 8))
    return p


if __name__ == "__main__":
    build().save("fallen_paladin")
