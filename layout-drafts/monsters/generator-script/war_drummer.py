"""War drummer (linocut v2, 1x1): a shouting orc with a war drum on a strap and both sticks raised."""
import math

from helpers_d import arcs, body, gouge, sinew
from helpers_h import RimPrint, drum_body, ellipse_pts, fist, fur, grained, mid, rivet, strap
from style import INK, PAPER, ground, knob, path, sliver, strand

HIDE = "#c98a4e"

J = dict(
    neck=(214, 196),
    sh_far=(318, 214), el_far=(388, 184), wr_far=(382, 104),
    sh_near=(194, 222), el_near=(124, 272), wr_near=(104, 194),
    hip_far=(300, 378), kn_far=(330, 428), an_far=(334, 470),
    hip_near=(226, 380), kn_near=(196, 428), an_near=(194, 470),
)


def stick(p, name, hand, tip):
    """A drumstick: a wooden shaft with a round knob at its striking end."""
    with p.group(name, hand):
        sinew(p, [hand, mid(hand, tip), tip], [12, 13, 12, 10], color=PAPER, frac=0.3, gouges=2)
        p.part([knob(tip[0], tip[1], 13, 7, 0.4)], color=PAPER, sw=4,
               marks=[(path(knob(tip[0] + 3, tip[1] + 3, 7, 6)), INK)])


def arm(p, side, widths, tip, fist_at):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        sinew(p, [sh, mid(sh, el, 0, 8), el], widths[:4], color=HIDE)
    with p.group(f"forearm_{side}", el):
        bands = [(path(strap(mid(el, wr, t=t), mid(el, wr, 6, 0, t + 0.06), widths[4] * 0.9)), INK)
                 for t in (0.55, 0.7)]
        sinew(p, [mid(el, sh, t=0.12), el, mid(el, wr, 8), wr], [widths[2]] + widths[3:], color=HIDE,
              extra=bands)
    stick(p, f"stick_{side}", wr, tip)
    with p.group(f"hand_{side}", wr):
        fist(p, fist_at, HIDE, size=0.62, knuckles=3)


def leg(p, side, foot):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        sinew(p, [hp, mid(hp, kn, 6), kn], [62, 66, 58, 50], color=HIDE)
    with p.group(f"shin_{side}", kn):
        wraps = [(path(strap(mid(kn, an, -30, 0, t), mid(kn, an, 30, 4, t), 6)), INK) for t in (0.3, 0.55, 0.8)]
        sinew(p, [mid(kn, hp, t=0.1), kn, an], [52, 48, 46, 42], color=PAPER, extra=wraps)
    with p.group(f"foot_{side}", an):
        body(p, foot, [(foot[1][0], foot[1][1] - 6), (foot[2][0] - 12, foot[2][1])], color=INK, count=2,
             lmin=5, lmax=10, w=4)


def torso(p):
    with p.group("torso", mid(J["hip_far"], J["hip_near"])):
        hull = [(186, 214), (232, 192), (300, 192), (346, 216), (360, 280), (346, 350), (316, 392),
                (240, 396), (196, 372), (176, 310)]
        pecs = arcs(244, 250, 60, 40, math.pi * 0.15, math.pi * 0.85, n=2, step=14, w=5, color=INK)
        abs_ = [(gouge((x, 300), (x + 4, 320), (x, 344), 5), INK) for x in (236, 264, 292)]
        body(p, hull, [(330, 206), (350, 300), (310, 396)], color=HIDE, count=6, lmin=8, lmax=18, w=5,
             extra=pecs + abs_)
    with p.group("kilt", (264, 382)):
        flaps = [[(x, 372), (x + 34, 372), (x + 30, 424), (x + 4, 430)] for x in (198, 230, 262, 294)]
        body(p, flaps, [(330, 376), (318, 428)], color=INK, count=3, lmin=6, lmax=12, w=4,
             extra=[(path(strap((196, 376), (334, 376), 14)), PAPER)] + rivet(220, 376, 4) + rivet(310, 376, 4))


def mantle(p):
    with p.group("fur_mantle", J["neck"]):
        fur(p, (176, 206), (356, 206), 12, 36)


def drum(p):
    """A war drum slung in front of the belly: cream hide head, dark shell, cord zigzag, iron hoops."""
    with p.group("drum_strap", J["sh_far"]):
        p.part([strap((340, 206), (150, 330), 18)], color=INK, sw=4,
               marks=[m for t in (0.25, 0.5, 0.75) for m in rivet(*mid((340, 206), (150, 330), t=t), 4)])
    with p.group("drum", (226, 312)):
        cx, cy, rx, ry, depth = 226, 312, 102, 30, 92
        shell = drum_body(cx, cy, rx, ry, depth)
        cords = []
        for i in range(7):
            x0 = cx - rx * 0.92 + i * rx * 0.31
            x1 = x0 + rx * 0.155
            cords.append((path(strap((x0, cy + 22), (x1, cy + depth + 14), 6)), PAPER))
            cords.append((path(strap((x1, cy + depth + 14), (x0 + rx * 0.31, cy + 22), 6)), PAPER))
        hoops = [(path(ellipse_pts(cx, y, rx, ry, 0, math.pi, 16)
                       + ellipse_pts(cx, y + 10, rx, ry, math.pi, 0, 16)), INK) for y in (cy + 6, cy + depth - 8)]
        body(p, shell, [(cx + rx * 0.6, cy), (cx + rx * 0.5, cy + depth + 20)], color=HIDE, count=5,
             lmin=6, lmax=14, w=4, extra=cords + hoops)
        head = ellipse_pts(cx, cy, rx, ry, 0, 2 * math.pi, 28)
        p.part([head], color=PAPER, sw=5,
               marks=arcs(cx, cy, rx * 0.8, ry * 0.8, math.pi * 0.1, math.pi * 0.9, n=2, step=10, w=4, color=INK)
               + [(path(knob(cx - 20, cy - 4, 6, 6)), INK)])


def head(p):
    with p.group("head", J["neck"]):
        strand(p, (232, 76), (262, 40), (300, 52), 18, 3, color=INK, shade=False)
        strand(p, (240, 80), (276, 60), (306, 78), 14, 3, color=INK, shade=False)
        skull = [(196, 72), (244, 66), (272, 92), (276, 140), (262, 182), (226, 204), (178, 206),
                 (146, 190), (132, 160), (142, 126), (160, 92)]
        brow = [(path([(140, 120), (214, 108), (222, 126), (176, 134), (144, 138)]), INK)]
        mouth = [(path([(138, 160), (196, 150), (214, 168), (196, 196), (150, 196)]), INK)]
        teeth = [(path([(150, 164), (156, 176), (162, 162)]), PAPER), (path([(176, 160), (182, 172), (188, 158)]), PAPER)]
        tusks = [(path([(152, 194), (148, 168), (162, 192)]), PAPER), (path([(194, 192), (196, 166), (206, 188)]), PAPER)]
        lines = [(gouge((222, 140), (240, 164), (232, 188), 5), PAPER), (gouge((206, 84), (230, 86), (252, 100), 5), PAPER)]
        body(p, skull, [(250, 76), (270, 140), (240, 200)], color=HIDE, count=4, lmin=6, lmax=14, w=4,
             extra=brow + mouth + teeth + tusks + lines)
        p.eye(158, 140, 6)
        p.eye(196, 136, 5)
        with p.group("ear", (262, 128)):
            ear = [(254, 112), (312, 92), (282, 132), (264, 146)]
            body(p, ear, [(306, 96), (270, 144)], color=HIDE, count=2, lmin=5, lmax=10, w=4,
                 extra=[(gouge((262, 126), (280, 116), (296, 104), 4), INK)] + rivet(286, 126, 4))


def build():
    p = RimPrint(HIDE, w=512, h=512, seed=64)
    with p.group("ground", (256, 488)):
        ground(p, 70, 450, 474)
    arm(p, "far", [58, 62, 54, 46, 42, 38], (430, 26), (382, 100))
    leg(p, "far", [(318, 462), (352, 462), (376, 484), (312, 486)])
    torso(p)
    mantle(p)
    leg(p, "near", [(178, 462), (212, 462), (214, 486), (148, 488), (154, 472)])
    drum(p)
    head(p)
    arm(p, "near", [58, 62, 54, 46, 42, 38], (62, 120), (104, 192))
    return p


if __name__ == "__main__":
    build().save("war_drummer")
