"""Stone giant (linocut v2, 2x2): a colossal humanoid of carved rock slabs, head sunk between its shoulders."""
from helpers_h import RimPrint, boulder, crack, mid, rock_limb, slab
from style import INK, PAPER, ground, knob, path, sliver

GRANITE = "#aaa395"

J = dict(
    neck=(452, 330),
    sh_far=(660, 330), el_far=(800, 520), wr_far=(790, 700),
    sh_near=(300, 360), el_near=(206, 560), wr_near=(176, 712),
    hip_far=(600, 690), kn_far=(668, 820), an_far=(676, 930),
    hip_near=(410, 700), kn_near=(372, 820), an_near=(362, 930),
)


def edge_of(poly, lean=0.25):
    """A hand-like shadow curve for a slab: down its right side, so the shadow falls lower right."""
    xs, ys = [q[0] for q in poly], [q[1] for q in poly]
    x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
    w = x1 - x0
    return [(x0 + w * (0.55 + lean), y0 - 10), (x0 + w * (0.62 + lean * 0.5), (y0 + y1) / 2),
            (x0 + w * 0.4, y1 + 10)]


def rock(p, poly, cracks=1, count=4, extra=()):
    slab(p, poly, edge_of(poly), GRANITE, cracks=cracks, count=count, extra=extra)


def stone_fist(p, at, s):
    """A huge fist of three knuckle blocks on a palm block."""
    x, y = at
    palm = [(x - 70 * s, y - 50 * s), (x + 60 * s, y - 60 * s), (x + 80 * s, y + 10 * s),
            (x + 60 * s, y + 70 * s), (x - 50 * s, y + 80 * s), (x - 84 * s, y + 20 * s)]
    rock(p, palm, cracks=1, count=3)
    for i in range(3):
        k = boulder(x - 50 * s + i * 44 * s, y + 70 * s, 26 * s, n=6, squash=0.8, rot=0.4)
        rock(p, k, cracks=0, count=2)


def arm(p, side, widths, fist_at, s):
    sh, el, wr = J[f"sh_{side}"], J[f"el_{side}"], J[f"wr_{side}"]
    with p.group(f"upper_arm_{side}", sh):
        rock(p, rock_limb(sh, el, widths[0], widths[1]), cracks=2, count=5)
    with p.group(f"forearm_{side}", el):
        rock(p, rock_limb(el, wr, widths[1], widths[2]), cracks=2, count=5)
    with p.group(f"hand_{side}", wr):
        stone_fist(p, fist_at, s)


def leg(p, side, foot):
    hp, kn, an = J[f"hip_{side}"], J[f"kn_{side}"], J[f"an_{side}"]
    with p.group(f"thigh_{side}", hp):
        rock(p, rock_limb(hp, kn, 190, 160), cracks=2, count=5)
    with p.group(f"shin_{side}", kn):
        rock(p, rock_limb(kn, an, 150, 140), cracks=1, count=5)
        rock(p, boulder(kn[0] - 10, kn[1], 56, n=7, rot=0.3), cracks=0, count=2)
    with p.group(f"foot_{side}", an):
        rock(p, foot, cracks=1, count=3)


def torso(p):
    with p.group("torso", mid(J["hip_far"], J["hip_near"])):
        back = [(330, 330), (470, 290), (650, 300), (724, 380), (720, 560), (660, 700), (520, 740),
                (390, 720), (330, 620), (310, 470)]
        rock(p, back, cracks=0, count=8)
        for poly in ([(340, 380), (470, 360), (500, 480), (430, 540), (350, 520)],
                     [(500, 360), (640, 370), (680, 480), (610, 540), (520, 500)],
                     [(370, 556), (480, 540), (500, 640), (420, 690), (360, 650)],
                     [(510, 540), (620, 560), (640, 650), (560, 700), (500, 660)]):
            rock(p, poly, cracks=1, count=3)


def head(p):
    with p.group("head", J["neck"]):
        skull = [(392, 236), (476, 222), (522, 262), (524, 330), (490, 370), (420, 380), (376, 352), (366, 290)]
        brow = [(path([(360, 300), (468, 266), (474, 288), (420, 304), (362, 318)]), INK)]
        mouth = [(path([(380, 356), (414, 344), (444, 350), (440, 360), (412, 356), (384, 366)]), INK)]
        jaw = [(crack((470, 300), (500, 360), kinks=2, w=4, jag=6), INK)]
        slab(p, skull, [(500, 226), (520, 300), (480, 380)], GRANITE, cracks=1, count=4, extra=brow + mouth + jaw)
        p.eye(392, 318, 11)
        p.eye(442, 314, 10)


def shoulders(p):
    for side, at, r in (("far", (650, 320), 118), ("near", (270, 420), 96)):
        with p.group(f"shoulder_{side}", at):
            rock(p, boulder(*at, r, n=8, squash=0.82, rot=0.2), cracks=2, count=4)


def build():
    p = RimPrint(GRANITE, w=1024, h=1024, seed=73, shift=(36, 0))
    with p.group("ground", (512, 990)):
        ground(p, 70, 960, 970)
    arm(p, "far", (190, 160, 150), (808, 760), 1.5)
    leg(p, "far", [(610, 900), (740, 900), (790, 960), (780, 982), (600, 982)])
    torso(p)
    leg(p, "near", [(300, 900), (420, 900), (430, 982), (240, 984), (250, 950)])
    head(p)
    shoulders(p)
    arm(p, "near", (180, 150, 140), (170, 780), 1.6)
    return p


if __name__ == "__main__":
    build().save("stone_giant")
