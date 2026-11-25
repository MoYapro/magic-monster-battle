"""Treant (linocut v2, 1x2): an ancient gnarled tree with a stern bark face, a leafy crown,
branch arms ending in twig claws, and spreading root legs."""
import math

from helpers_d import (OuterRimPrint, arcs, body, canopy_spots, chain, gouge, grain, leaf_cluster, leaf_marks,
                       sinew)
from style import INK, PAPER, ground, knob, path, rng, sliver, strand

BARK = "#a8955c"

J = dict(
    base=(256, 780), crown=(256, 300),
    sh_far=(334, 392), el_far=(444, 486), wr_far=(462, 640),
    sh_near=(186, 392), el_near=(80, 480), wr_near=(56, 640),
    hip_far=(318, 760), kn_far=(376, 856), an_far=(410, 950),
    hip_near=(198, 760), kn_near=(140, 856), an_near=(104, 950),
)


def mid(a, b, dx=0, dy=0, t=0.5):
    return a[0] + (b[0] - a[0]) * t + dx, a[1] + (b[1] - a[1]) * t + dy


def foliage(p, clusters, color, cuts=5):
    """Leaf clumps; coloured ones get a black shadow corner, black ones get cream leaf cuts."""
    for x, y, r in clusters:
        poly = leaf_cluster(x, y, r, leaves=rng.choice((10, 11, 12)), rot=rng.uniform(0, 1))
        shade = None
        if color != INK:
            shade = path([(x + r * 0.1, y + r), (x + r * 1.2, y - r * 0.2), (x + r * 2, y + r * 2)])
        p.part([poly], shade, leaf_marks(x, y, r, cuts, INK if color == PAPER else PAPER), color=color, sw=5)


def crown(p):
    with p.group("crown", J["crown"]):
        back = canopy_spots(256, 210, 214, 124, 34, 44, 66)
        foliage(p, back, INK, cuts=5)
        for a, c, b, w in (((220, 330), (190, 260), (120, 220), 30), ((290, 330), (330, 250), (400, 210), 30),
                           ((256, 320), (250, 240), (262, 160), 26)):
            sinew(p, [a, c, b], [w, w * 0.8, w * 0.5], color=BARK, gouges=3, lmin=4, lmax=10)
        front = canopy_spots(236, 196, 210, 116, 22, 32, 50, upper_left=True)
        foliage(p, front, BARK, cuts=3)


def face(p):
    """Heavy frowning brows, deep sockets with embers, a bark-ridge nose and a hollow mouth."""
    brows = [(path([(166, 412), (236, 432), (240, 448), (170, 432)]), INK),
             (path([(318, 404), (258, 430), (256, 446), (314, 424)]), INK)]
    sockets = [(path(knob(214, 452, 14, 6, 0.2)), INK), (path(knob(276, 448, 12, 6, 0.2)), INK)]
    nose = [(gouge((246, 452), (236, 490), (226, 520), 12), INK), (gouge((240, 452), (232, 486), (222, 514), 4), PAPER)]
    mouth = [(path([(198, 548), (232, 532), (276, 538), (290, 556), (250, 566), (210, 566)]), INK)]
    lines = [(gouge((176, 470), (186, 500), (184, 530), 5), INK), (gouge((300, 466), (296, 496), (304, 526), 5), INK)]
    return brows + sockets + nose + mouth + lines


def trunk(p):
    with p.group("trunk", J["base"]):
        hull = [(186, 320), (226, 300), (290, 300), (336, 322), (346, 384), (330, 452), (350, 524), (338, 604),
                (364, 684), (408, 770), (340, 796), (180, 796), (106, 768), (154, 690), (172, 610), (156, 526),
                (178, 452), (166, 384)]
        bark = []
        for x0, bend in ((190, -16), (214, 10), (300, 14), (326, -10), (240, -8), (276, 12)):
            line = chain([(x0, 320), (x0 + bend, 560), (x0 - bend * 0.5 + (x0 - 256) * 0.35, 780)])
            bark += grain(line, 24, n=3, spread=0.4, length=(0.25, 0.55), color=INK, width=6)
        knot = arcs(300, 680, 26, 34, 0, math.pi * 2, n=3, step=8, w=4, color=INK)
        body(p, hull, [(306, 300), (300, 450), (316, 600), (334, 720), (300, 800)], color=BARK, count=12,
             extra=bark + knot + face(p))
        p.eye(212, 452, 7)
        p.eye(274, 448, 6)
    with p.group("beard", (246, 566)):
        hem = [(300, 572)] + [(296 - i * 14, 620 + (28 if i % 2 else 0) + rng.uniform(-6, 10)) for i in range(8)] + [(190, 572)]
        beard = [(196, 562), (246, 576), (298, 560)] + hem
        hair = [m for i in range(6) for m in grain(chain([(206 + i * 16, 578), (200 + i * 14, 612), (192 + i * 13, 646)]),
                                                     6, n=1, length=(0.6, 1.0), color=INK, width=4)]
        body(p, beard, [(300, 566), (276, 610), (240, 660)], color=BARK, count=3, lmin=6, lmax=14, w=4, extra=hair)


def twig_claw(p, at, base_angle, n=4, length=86):
    """Gnarled twig fingers fanning out from a wrist, each with a hooked tip."""
    x, y = at
    for i in range(n):
        a = base_angle + (i / (n - 1) - 0.5) * 1.3
        mid_pt = (x + math.cos(a) * length * 0.55, y + math.sin(a) * length * 0.55)
        tip = (x + math.cos(a + 0.35) * length, y + math.sin(a + 0.35) * length)
        strand(p, (x, y), mid_pt, tip, 18, 2, color=BARK)


def arm(p, side, spread):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        sinew(p, [sh, mid(sh, el, 0, -16), el], [62, 52, 44, 40], color=BARK,
              extra=grain(chain([sh, mid(sh, el, 0, -16), el]), 40, n=3, color=INK, width=4))
    with p.group(f"forearm_{side}", el):
        sinew(p, [mid(el, sh, 0, 0, 0.1), el, mid(el, wr, spread * 10), wr], [46, 42, 36, 28], color=BARK,
              extra=grain(chain([el, wr]), 36, n=2, color=INK, width=4))
    with p.group(f"hand_{side}", wr):
        twig_claw(p, wr, math.pi / 2 + spread * 0.25)


def leg(p, side, spread):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        sinew(p, [hp, mid(hp, kn, -spread * 8, -6), kn], [116, 96, 82], color=BARK,
              extra=grain(chain([hp, kn]), 70, n=3, color=INK, width=5))
    with p.group(f"shin_{side}", kn):
        sinew(p, [mid(kn, hp, 0, 0, 0.12), kn, mid(kn, an, spread * 8), an], [88, 82, 70, 60], color=BARK,
              extra=grain(chain([kn, an]), 50, n=2, color=INK, width=4))
    with p.group(f"foot_{side}", an):
        x, y = an
        for dx, dy, w in ((spread * 70, 18, 22), (spread * 30, 30, 20), (-spread * 30, 24, 18), (-spread * 60, 12, 14)):
            strand(p, (x, y), (x + dx * 0.5, y + dy), (x + dx, y + dy * 0.6 + 6), w, 3, color=BARK)


def build():
    p = OuterRimPrint(BARK, w=512, h=1024, seed=31, zoom=0.96, shift=(10, 30))
    with p.group("ground", (256, 980)):
        ground(p, 20, 492, 966)
    arm(p, "far", 1)
    leg(p, "far", 1)
    leg(p, "near", -1)
    trunk(p)
    crown(p)
    arm(p, "near", -1)
    return p


if __name__ == "__main__":
    build().save("treant")
