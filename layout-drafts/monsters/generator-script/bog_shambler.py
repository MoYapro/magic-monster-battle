"""Bog shambler (linocut v2): a hunched, rotting humanoid of mud and roots with long arms that
drag towards the ground, hollow eye sockets, and weeds and mud dripping off every limb. Faces left."""
import math

from helpers_d import body, chain, gouge, grain, sinew
from helpers_g import GPrint, drip, weed
from style import INK, PAPER, claw, ground, knob, path, rng, sliver

BOG = "#7d8f52"

J = dict(
    neck=(222, 156), hip=(290, 336),
    sh_far=(332, 168), el_far=(368, 264), wr_far=(360, 362),
    sh_near=(214, 178), el_near=(172, 270), wr_near=(144, 372),
    hip_far=(318, 330), kn_far=(346, 392), an_far=(340, 450),
    hip_near=(262, 336), kn_near=(236, 396), an_near=(248, 450),
)


def mid(a, b, dx=0, dy=0, t=0.5):
    return a[0] + (b[0] - a[0]) * t + dx, a[1] + (b[1] - a[1]) * t + dy


def dangling(p, spots, color=INK, kind=weed):
    """Weeds or mud drips hanging from a list of (x, y, length, width, sway)."""
    for x, y, ln, w, sw in spots:
        p.part(kind(x, y, ln, w, sw), color=color, sw=3)


def arm(p, side, widths, hand_at, color):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        fibre = grain(chain([sh, mid(sh, el, 10), el]), widths[1], n=3, spread=0.3, color=INK, width=4)
        sinew(p, [sh, mid(sh, el, 12), el], widths[:4], extra=fibre, color=color)
        dangling(p, [(mid(sh, el)[0] + 6, mid(sh, el)[1] + 10, 44, 9, 0.1)])
    with p.group(f"forearm_{side}", el):
        fibre = grain(chain([el, mid(el, wr, -6), wr]), widths[4], n=3, spread=0.3, color=INK, width=4)
        sinew(p, [mid(el, sh, 0, 0, 0.12), el, mid(el, wr, -8), wr], [widths[2]] + widths[3:],
              extra=fibre, color=color)
        dangling(p, [(el[0] + 4, el[1] + 16, 52, 10, 0.15), (mid(el, wr)[0] + 8, mid(el, wr)[1], 40, 8, 0.1)])
    with p.group(f"hand_{side}", wr):
        claw(p, hand_at, math.pi / 2 + 0.25, fingers=4, length=52, spread=1.1, w=11, palm=20, curl=0.35,
             color=color)
        dangling(p, [(hand_at[0] - 6, hand_at[1] + 10, 30, 7, 0.0)], color=color, kind=drip)


def leg(p, side, color):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        sinew(p, [hp, mid(hp, kn, 8), kn], [58, 62, 54, 46], color=color)
    with p.group(f"shin_{side}", kn):
        sinew(p, [mid(kn, hp, 0, 0, 0.12), kn, an], [46, 44, 40, 38], color=color)
    with p.group(f"foot_{side}", an):
        x, y = an
        foot = [(x + 22, y - 10), (x + 26, y + 10), (x - 34, y + 12), (x - 42, y + 2), (x - 20, y - 8)]
        body(p, foot, [(x + 24, y - 6), (x - 10, y + 12)], color=color, count=2, lmin=6, lmax=10, w=4,
             extra=[(sliver(x - 30 + i * 12, y + 6, -0.3, 12, 5), INK) for i in range(3)])


def torso(p):
    with p.group("torso", J["hip"]):
        hull = [(204, 172), (240, 140), (300, 126), (350, 140), (374, 192), (372, 262), (348, 326),
                (292, 350), (240, 342), (214, 300), (200, 236)]
        ribs = [(gouge((226 + i * 6, 206 + i * 26), (256 + i * 4, 198 + i * 28), (284 + i * 2, 210 + i * 26), 7), INK)
                for i in range(3)]
        roots = grain(chain([(300, 140), (336, 210), (330, 320)]), 50, n=5, spread=0.5, color=INK, width=4)
        holes = [(path(knob(x, y, r, 6, 0.4)), INK) for x, y, r in ((296, 180, 8), (322, 270, 9), (256, 312, 7))]
        moss = [(path(knob(x, y, r, 6, 0.2)), PAPER) for x, y, r in ((316, 160, 6), (246, 180, 5), (300, 232, 4))]
        body(p, hull, [(350, 140), (370, 250), (330, 340), (240, 344)], color=BOG, count=9,
             extra=ribs + roots + holes + moss)
        dangling(p, [(x, y, ln, w, sw) for x, y, ln, w, sw in
                     ((226, 326, 74, 12, -0.1), (252, 342, 90, 11, 0.05), (282, 348, 64, 12, 0.1),
                      (312, 340, 84, 10, -0.05), (340, 322, 60, 11, 0.12), (364, 280, 56, 9, 0.1),
                      (370, 210, 48, 9, 0.15))], color=BOG)


def hair(p):
    """Long wet weed hair hanging from the crown, behind the head."""
    with p.group("hair", (190, 80)):
        dangling(p, [(x, y, ln, w, sw) for x, y, ln, w, sw in
                     ((146, 92, 96, 13, -0.12), (166, 76, 124, 14, -0.05), (194, 70, 110, 13, 0.05),
                      (220, 78, 128, 14, 0.1), (240, 98, 100, 12, 0.14), (256, 120, 72, 11, 0.18))])


def head(p):
    with p.group("head", J["neck"]):
        skull = [(120, 106), (146, 76), (190, 64), (228, 82), (238, 122), (226, 160), (192, 180),
                 (150, 178), (122, 158), (110, 130)]
        sockets = [(path(knob(x, y, r, 7, 0.3)), INK) for x, y, r in ((146, 116, 14), (192, 110, 13))]
        mouth = [(path([(126, 146), (166, 150), (190, 144), (186, 180), (152, 190), (126, 172)]), INK)]
        teeth = [(sliver(x, 150, math.pi / 2, 9, 5), PAPER) for x in (140, 176)]
        lines = [(gouge((206, 80), (232, 102), (234, 140), 5), PAPER),
                 (gouge((146, 86), (176, 74), (206, 76), 4), PAPER),
                 (gouge((168, 116), (172, 128), (166, 138), 4), INK)]
        body(p, skull, [(226, 84), (238, 140), (192, 180)], color=BOG, count=4, lmin=6, lmax=14, w=4,
             extra=sockets + mouth + teeth + lines)
        p.eye(148, 118, 4)
        p.eye(193, 112, 4)
        with p.group("hair_front", (150, 74)):
            dangling(p, [(126, 92, 76, 10, -0.1), (152, 72, 40, 9, -0.05), (232, 96, 70, 10, 0.08)])
        with p.group("drool", (160, 184)):
            dangling(p, [(144, 182, 46, 9, 0.0), (170, 184, 30, 8, 0.05)], color=BOG, kind=drip)


def build():
    p = GPrint(BOG, seed=61)
    with p.group("ground", (256, 466)):
        ground(p, 40, 480, 462)
    arm(p, "far", [50, 56, 50, 42, 38, 32], (360, 382), INK)
    leg(p, "far", BOG)
    torso(p)
    leg(p, "near", BOG)
    hair(p)
    head(p)
    arm(p, "near", [54, 60, 54, 46, 42, 36], (140, 392), BOG)
    return p


if __name__ == "__main__":
    build().save("bog_shambler")
