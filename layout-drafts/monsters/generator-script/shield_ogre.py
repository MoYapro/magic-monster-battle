"""Shield ogre (linocut v2, 1x2): a bald, hulking ogre behind a planked tower shield, axe raised."""
import math

from helpers_d import arcs, body, gouge, sinew, wart
from helpers_h import RimPrint, crack, ellipse_pts, fist, grained, mid, rivet, strap
from style import INK, PAPER, ground, knob, path, rag, sliver, strand

BRICK = "#c97a5b"

J = dict(
    neck=(250, 390),
    sh_far=(392, 438), el_far=(470, 372), wr_far=(436, 282),
    sh_near=(214, 448), el_near=(150, 560),
    hip_far=(370, 742), kn_far=(398, 858), an_far=(386, 948),
    hip_near=(262, 746), kn_near=(234, 858), an_near=(246, 948),
)


def leg(p, side, foot):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        sinew(p, [hp, mid(hp, kn, 12), kn], [118, 128, 112, 92], color=BRICK)
    with p.group(f"shin_{side}", kn):
        sinew(p, [mid(kn, hp, t=0.12), kn, mid(kn, an, 8), an], [98, 92, 90, 80, 72], color=BRICK)
    with p.group(f"foot_{side}", an):
        toes = [(sliver(x, foot[2][1] + 8, -0.2, 20, 6), INK) for x in (foot[0][0] + 12, foot[0][0] + 32)]
        body(p, foot, [(foot[1][0], foot[1][1] - 8), (foot[2][0] - 18, foot[2][1])], color=BRICK,
             count=3, lmin=6, lmax=14, w=5, extra=toes)


def axe(p):
    """A long-hafted war axe raised over the far shoulder, its bearded blade facing the mages."""
    with p.group("axe", J["wr_far"]):
        a, b = (468, 352), (378, 96)
        sinew(p, [a, mid(a, b), b], [22, 24, 24, 20], color=PAPER, frac=0.3, gouges=3,
              extra=grained([a, mid(a, b), b], 22, n=2))
        blade = [(384, 100), (346, 80), (304, 28), (264, 62), (246, 118), (258, 172), (296, 214), (324, 180),
                 (384, 154)]
        bevel = [(path([(304, 40), (270, 70), (256, 118), (266, 166), (296, 200), (290, 206), (256, 170),
                        (244, 118), (258, 62), (300, 30)]), INK)]
        bevel += [(path([(310, 52), (282, 76), (270, 118), (280, 160), (302, 186), (294, 190), (272, 162),
                         (262, 118), (274, 72), (304, 46)]), INK)]
        nicks = [(path([(250, 96), (264, 102), (250, 108)]), INK), (path([(262, 150), (276, 152), (266, 162)]), INK)]
        body(p, blade, [(354, 76), (334, 128), (374, 160)], color=PAPER, count=3, lmin=8, lmax=16, w=5,
             extra=bevel + nicks + rivet(368, 116, 6) + rivet(364, 146, 5))


def far_arm(p):
    sh, el, wr = J["sh_far"], J["el_far"], J["wr_far"]
    with p.group("upper_arm_far", sh):
        sinew(p, [sh, mid(sh, el, 10, 14), el], [104, 116, 104, 86], color=BRICK)
    with p.group("forearm_far", el):
        sinew(p, [mid(el, sh, t=0.12), el, mid(el, wr, 14), wr], [84, 88, 80, 70, 64], color=BRICK,
              extra=wart(470, 330, 6))
    axe(p)
    with p.group("hand_far", wr):
        fist(p, (444, 300), BRICK, size=0.9)


def torso(p):
    with p.group("torso", mid(J["hip_far"], J["hip_near"])):
        hull = [(206, 412), (268, 380), (356, 372), (430, 404), (466, 470), (470, 590), (450, 700),
                (402, 760), (300, 772), (214, 754), (166, 690), (150, 600), (162, 500)]
        belly = arcs(250, 640, 96, 104, math.pi * 0.5, math.pi * 1.1, n=3, step=20, w=6)
        navel = [(path(knob(196, 650, 7, 5, 0.3)), INK)]
        chest = [(gouge((330, 430), (360, 470), (352, 520), 8), INK), (gouge((250, 430), (290, 452), (330, 446), 7), INK)]
        scars = [(crack((380, 480), (430, 560), kinks=2, w=4, jag=6), PAPER)]
        body(p, hull, [(420, 410), (444, 560), (420, 700), (330, 780)], color=BRICK, count=9,
             extra=belly + navel + chest + scars)
    with p.group("belt", (310, 712)):
        belt = strap((158, 700), (466, 716), 34)
        body(p, belt, [(466, 700), (300, 728), (158, 718)], color=PAPER, count=3, lmin=6, lmax=10, w=4,
             extra=rivet(230, 704) + rivet(300, 708) + rivet(380, 712) + rivet(440, 714))
    with p.group("loincloth", (316, 740)):
        rag(p, (212, 730), (430, 738), 120, tatters=6)


def head(p):
    with p.group("head", J["neck"]):
        skull = [(196, 228), (262, 214), (314, 236), (338, 290), (334, 350), (300, 400), (236, 418),
                 (172, 412), (130, 392), (118, 350), (124, 300), (148, 258)]
        brow = [(path([(116, 296), (230, 282), (236, 304), (186, 314), (120, 318)]), INK)]
        jaw = [(path([(124, 368), (216, 362), (250, 346), (246, 384), (196, 400), (132, 396)]), INK)]
        tusks = [(path([(140, 372), (148, 340), (158, 372)]), PAPER), (path([(196, 368), (206, 334), (216, 366)]), PAPER)]
        dome = arcs(250, 300, 80, 74, math.pi * 1.05, math.pi * 1.6, n=2, step=18, w=5)
        lines = [(gouge((256, 330), (278, 360), (268, 392), 6), PAPER), (gouge((150, 334), (176, 344), (200, 340), 5), INK)]
        body(p, skull, [(300, 230), (330, 320), (290, 410)], color=BRICK, count=5, lmin=8, lmax=18, w=5,
             extra=brow + jaw + tusks + dome + lines)
        p.eye(172, 330, 9)
        p.eye(214, 326, 8)
        with p.group("nose", (140, 330)):
            nose = [(136, 318), (156, 330), (146, 358), (112, 364), (100, 352), (112, 334)]
            body(p, nose, [(154, 332), (130, 362)], color=BRICK, count=2, lmin=5, lmax=10, w=4,
                 extra=[(path(knob(116, 354, 5, 5)), INK)])
        with p.group("ear", (316, 318)):
            ear = [(306, 300), (346, 286), (352, 318), (334, 346), (312, 340)]
            body(p, ear, [(346, 292), (332, 344)], color=BRICK, count=2, lmin=5, lmax=10, w=4,
                 extra=[(gouge((318, 316), (332, 308), (340, 300), 5), INK)] + rivet(344, 332, 5))


def near_arm(p):
    sh, el = J["sh_near"], J["el_near"]
    with p.group("upper_arm_near", sh):
        sinew(p, [sh, mid(sh, el, -14), el], [100, 112, 100, 88], color=BRICK, extra=wart(186, 480, 6))


def shield(p):
    """A tall tower shield of vertical planks with iron bands, rivets and a spiked iron boss."""
    with p.group("shield", J["el_near"]):
        poly = [(36, 474), (66, 430), (140, 410), (214, 420), (254, 452), (258, 822), (234, 884), (148, 910),
                (66, 894), (36, 852)]
        planks = [(path([(x - 3, 420), (x + 3, 420), (x + 5, 900), (x - 1, 900)]), INK) for x in (88, 140, 196)]
        planks += [(gouge((x, y), (x + 3, y + 40), (x + 1, y + 80), 4), INK)
                   for x, y in ((60, 540), (112, 560), (170, 520), (220, 560), (62, 700), (118, 730), (224, 700))]
        bands = []
        for y in (498, 812):
            bands.append((path(strap((30, y), (262, y + 6), 22)), INK))
            bands += [m for x in (56, 116, 166, 226) for m in rivet(x, y + 2 + (x - 30) * 0.026, 4)]
        boss = [(path(knob(146, 656, 46, 12, 0.2)), INK)]
        boss += [(path(knob(146, 656, 30, 10, 0.4)), PAPER), (path(knob(152, 662, 22, 10, 0.4)), INK)]
        rays = [(sliver(146 + math.cos(a) * 52, 656 + math.sin(a) * 52, a, 34, 12), INK)
                for a in (0, math.pi / 2, math.pi, 3 * math.pi / 2)]
        spike = [(path([(138, 650), (106, 632), (140, 640)]), PAPER)]
        nicks = [(path([(36, 600), (52, 608), (36, 616)]), INK), (path([(258, 700), (244, 708), (258, 716)]), INK)]
        body(p, poly, [(232, 430), (238, 660), (220, 890)], color=PAPER, count=6, lmin=8, lmax=20, w=5,
             extra=planks + bands + rays + boss + spike + nicks)


def build():
    p = RimPrint(BRICK, w=512, h=1024, seed=58)
    with p.group("ground", (256, 980)):
        ground(p, 30, 496, 962)
    leg(p, "far", [(360, 938), (420, 936), (452, 962), (446, 980), (350, 980)])
    far_arm(p)
    torso(p)
    leg(p, "near", [(222, 938), (272, 940), (276, 980), (150, 982), (150, 960), (186, 948)])
    head(p)
    near_arm(p)
    shield(p)
    return p


if __name__ == "__main__":
    build().save("shield_ogre")
