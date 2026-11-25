"""Troll (linocut v2, 1x2): a hunched, warty brute with a heavy brow, long nose and a spiked club."""
import math

from helpers_d import OuterRimPrint, arcs, body, chain, gouge, grain, sinew, wart
from style import INK, PAPER, ground, knob, path, rag, rng, sliver, strand

MOSS = "#93ab62"

J = dict(
    neck=(250, 300), hip=(320, 700),
    sh_far=(420, 290), el_far=(458, 520), wr_far=(450, 730),
    sh_near=(244, 296), el_near=(176, 496), wr_near=(138, 614),
    hip_far=(372, 704), kn_far=(404, 830), an_far=(386, 930),
    hip_near=(256, 704), kn_near=(214, 830), an_near=(232, 930),
)


def mid(a, b, dx=0, dy=0, t=0.5):
    return a[0] + (b[0] - a[0]) * t + dx, a[1] + (b[1] - a[1]) * t + dy


def fist(p, at, color=MOSS):
    """A clenched fist: a lumpy block with knuckle bumps and finger creases."""
    x, y = at
    poly = [(x - 38, y - 30), (x + 30, y - 34), (x + 46, y + 2), (x + 36, y + 46), (x - 18, y + 56), (x - 48, y + 22)]
    creases = [(sliver(x - 30 + i * 19, y + 10 + i * 3, 1.25, 30, 6), INK) for i in range(4)]
    body(p, poly, [(x + 44, y - 30), (x + 14, y + 22), (x - 40, y + 56)], color=color, count=3, lmin=6,
         lmax=12, w=4, extra=creases + wart(x - 4, y - 14, 5))


def arm(p, side, widths, hand):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        warts = [w for t in (0.2, 0.42, 0.64) for w in wart(*mid(sh, el, -18, 0, t), rng.uniform(5, 8))]
        sinew(p, [sh, mid(sh, el, 18), el], widths[:4], extra=warts, color=MOSS)
    with p.group(f"forearm_{side}", el):
        fibre = grain(chain([el, mid(el, wr, -8), wr]), widths[4], n=3, spread=0.25, color=INK, width=4)
        sinew(p, [mid(el, sh, 0, 0, 0.12), el, mid(el, wr, -10), wr], [widths[2]] + widths[3:], extra=fibre,
              color=MOSS)
    with p.group(f"hand_{side}", wr):
        hand()


def leg(p, side, foot, toes):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        sinew(p, [hp, mid(hp, kn, 10), kn], [112, 124, 110, 90], color=MOSS)
    with p.group(f"shin_{side}", kn):
        sinew(p, [mid(kn, hp, 0, 0, 0.12), kn, mid(kn, an, 10), an], [96, 90, 92, 78, 70], color=MOSS)
    with p.group(f"foot_{side}", an):
        marks = [(sliver(x, y, -0.2, 22, 6), INK) for x, y in toes]
        body(p, foot, [(foot[1][0], foot[1][1] - 10), (foot[2][0] - 20, foot[2][1])], color=MOSS,
             count=3, lmin=6, lmax=14, w=5, extra=marks)


def torso(p):
    with p.group("torso", J["hip"]):
        hull = [(196, 300), (244, 238), (310, 196), (396, 192), (452, 246), (480, 390), (464, 560), (418, 684),
                (330, 718), (218, 708), (140, 660), (108, 566), (124, 460), (166, 362)]
        trap = [(gouge((262, 250), (300, 300), (296, 372), 9), INK), (gouge((300, 210), (350, 220), (392, 214), 6), PAPER)]
        chest = [(gouge((150 + i * 30, 440), (176 + i * 30, 452), (204 + i * 30, 446), 9), INK) for i in range(3)]
        belly = arcs(214, 596, 100, 114, math.pi * 0.55, math.pi * 1.15, n=4, step=18, w=6)
        navel = [(path(knob(176, 604, 7, 5, 0.3)), INK)]
        warts = [w for x, y in ((300, 262), (338, 284), (270, 300), (376, 252), (318, 322), (400, 300),
                                (356, 330), (420, 360)) for w in wart(x, y, rng.uniform(5, 9))]
        body(p, hull, [(396, 222), (434, 400), (404, 590), (320, 724)], color=MOSS, count=9,
             extra=chest + belly + navel + warts + trap)
    with p.group("loincloth", (316, 700)):
        rag(p, (206, 680), (420, 688), 128, tatters=7)
        p.fill(path([(200, 676), (426, 684), (424, 700), (198, 694)]), INK)


def hair(p):
    for i in range(9):
        x = 170 + i * 13 + rng.uniform(-4, 4)
        ln = rng.uniform(50, 90)
        a = -1.9 + i * 0.16 + rng.uniform(-0.15, 0.15)
        tip = (x + math.cos(a) * ln, 180 + math.sin(a) * ln)
        strand(p, (x, 186), (x + math.cos(a + 0.4) * ln * 0.5, 180 + math.sin(a + 0.4) * ln * 0.5), tip,
               rng.uniform(12, 18), 1.5, color=INK, shade=False)


def head(p):
    with p.group("head", J["neck"]):
        hair(p)
        skull = [(150, 176), (214, 160), (266, 176), (290, 230), (284, 290), (250, 334), (196, 356), (148, 354),
                 (112, 336), (100, 300), (96, 254), (80, 224), (110, 196)]
        brow = [(path([(78, 222), (204, 204), (210, 226), (160, 236), (90, 240)]), INK)]
        mouth = [(path([(108, 318), (194, 314), (220, 298), (212, 326), (162, 338), (114, 334)]), INK)]
        teeth = [(sliver(x, 334, -math.pi / 2, 14, 8), PAPER) for x in (132, 152)]
        lines = [(gouge((200, 262), (224, 296), (216, 326), 6), PAPER),
                 (gouge((238, 196), (264, 214), (272, 246), 6), PAPER),
                 (gouge((120, 196), (150, 188), (186, 190), 5), PAPER)]
        warts = wart(242, 272, 7) + wart(254, 306, 5) + wart(166, 180, 6) + wart(206, 340, 5)
        body(p, skull, [(240, 166), (270, 262), (226, 354)], color=MOSS, count=5, lmin=8, lmax=18, w=5,
             extra=brow + mouth + teeth + lines + warts)
        p.eye(140, 252, 8)
        p.eye(186, 248, 7)
        with p.group("nose", (116, 262)):
            nose = [(112, 246), (132, 262), (114, 306), (84, 318), (58, 310), (62, 290), (90, 270)]
            body(p, nose, [(132, 266), (108, 304), (74, 322)], color=MOSS, count=2, lmin=6, lmax=12, w=4,
                 extra=[(path(knob(76, 306, 5, 5)), INK)] + wart(104, 278, 5))
        with p.group("ear", (266, 236)):
            ear = [(258, 222), (322, 194), (300, 232), (274, 256)]
            body(p, ear, [(314, 198), (280, 254)], color=MOSS, count=2, lmin=6, lmax=12, w=4,
                 extra=[(gouge((268, 232), (288, 220), (304, 210), 5), INK)])
        for side, x in (("far", 184), ("near", 132)):
            with p.group(f"tusk_{side}", (x, 322)):
                strand(p, (x, 326), (x - 8, 306), (x - 2, 288), 13, 2, color=PAPER)


def club(p):
    """A knotted log held forward at belly height, its head studded with iron spikes."""
    with p.group("club", J["wr_near"]):
        a, c, b = (158, 650), (80, 600), (-10, 548)
        sinew(p, [a, c, b], [34, 38, 46, 58], color=PAPER, frac=0.32, gouges=4,
              extra=grain(chain([a, c, b]), 36, n=4, color=INK, width=4))
        for x, y, ang in ((-46, 520, -2.6), (-14, 492, -1.7), (22, 506, -0.9), (-58, 570, 2.9), (-30, 604, 2.0),
                          (14, 590, 1.0)):
            p.part([[(x - 9 * math.sin(ang), y + 9 * math.cos(ang)), (x + 30 * math.cos(ang), y + 30 * math.sin(ang)),
                     (x + 9 * math.sin(ang), y - 9 * math.cos(ang))]], color=PAPER, sw=4)
        head = [(-54, 540), (-30, 500), (10, 500), (34, 530), (30, 584), (-4, 610), (-46, 600), (-64, 572)]
        body(p, head, [(30, 520), (0, 580), (-50, 612)], color=PAPER, count=4, lmin=8, lmax=18, w=5,
             extra=grain(chain([(-50, 530), (-10, 556), (26, 570)]), 50, n=3, color=INK, width=4)
             + [(path(knob(-20, 540, 6, 5)), INK), (path(knob(-34, 578, 5, 5)), INK)])


def build():
    p = OuterRimPrint(MOSS, w=512, h=1024, seed=21, zoom=0.84, shift=(82, 180))
    with p.group("ground", (256, 980)):
        ground(p, 40, 500, 962)
    arm(p, "far", [92, 108, 100, 84, 78, 64], lambda: fist(p, (450, 762)))
    leg(p, "far", [(360, 920), (420, 918), (454, 960), (448, 978), (350, 978)], [(420, 966), (436, 968)])
    torso(p)
    leg(p, "near", [(212, 918), (264, 920), (270, 978), (128, 980), (126, 956), (168, 938)],
        [(140, 966), (160, 968), (180, 970)])
    head(p)
    club(p)
    arm(p, "near", [90, 106, 98, 82, 76, 62], lambda: fist(p, (142, 646)))
    return p


if __name__ == "__main__":
    build().save("troll")
