"""Generate Ember Grimoire screen drafts as SVG (rendered to PNG with rsvg-convert)."""
import base64
import math
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / "spell-runes"))
import runes  # noqa: E402  rune alphabet from spell-runes/

W, H = 1280, 720
OUT = Path(sys.argv[1])

# ---------------------------------------------------------------- shared sample battle
MAGES = [
    dict(name="Lyra", hp=22, max=30, incoming=5, shield=0, status=[], spent=2, allow=3, color="#e0703a"),
    dict(name="Eron", hp=30, max=30, incoming=3, shield=4, status=[], spent=0, allow=3, color="#5aa0e0"),
    dict(name="Vael", hp=11, max=30, incoming=4, shield=0, status=[("Poison", 2, "#9a4fc0")], spent=1, allow=3, color="#7cc062"),
]
SPELL = {
    # body spells from SpellRegistry: (name, colour, mana cost); the key is the in-game abbreviation
    "Em": ("Ember", "#ff731a", 1), "Fr": ("Frost", "#40a6ff", 3), "Vn": ("Venom", "#4dd933", 1),
    "Bn": ("Bone", "#d9d9bf", 1), "Lt": ("Lightning", "#f2f233", 1), "Dt": ("Detonate", "#e0401a", 1),
    "Fi": ("Fire", "#ff4000", 1), "FP": ("Force Push", "#e6cc33", 1),
    "Amp": ("Amplify", "#cc4dff", 0), "Sh": ("Shield", "#a6bfe6", 2), "Co": ("Corrupted", "#a03ad0", 0),
    "Re": ("Reactive", "#33bf8c", 0), "Di": ("Distillation", "#338ce6", 0), "Su": ("Sunder", "#8c99ad", 0),
    "Ha": ("Harmony", "#ebd9f2", 0), "SM": ("Scorch Mark", "#d9591f", 0), "Cd": ("Conductor", "#59b3f2", 0),
    "TE": ("Toxin Edge", "#73cc40", 0), "Sp": ("Splash", "#80ccd9", 0),
    # tip spells
    "·": ("Single", "#e6e6e6", 1), "|||": ("Line", "#4dccf2", 2), "→→": ("Pierce", "#f28c33", 2),
    "bomb": ("Bomb", "#9a9aa0", 3),
    "↑": ("Bolt ↑", "#f2d933", 1), "↗": ("Bolt ↗", "#f2d933", 1), "→": ("Bolt →", "#f2d933", 1),
    "↘": ("Bolt ↘", "#f2d933", 1), "↓": ("Bolt ↓", "#f2d933", 1), "↙": ("Bolt ↙", "#f2d933", 1),
    "←": ("Bolt ←", "#f2d933", 1), "↖": ("Bolt ↖", "#f2d933", 1),
    # alchemy results (cannot be looted)
    "St": ("Steam", "#d9d9d9", 0), "FB": ("Flame Burst", "#ff4d00", 0), "IC": ("Ice Cube", "#99d9ff", 0),
    "Cu": ("Curse", "#9a4fd0", 0),
}
# rune letters per spell, as assigned on spell-runes/03_all_spells.png
RUNE_LETTERS = {
    "Amp": "A", "bomb": "BL", "Bn": "BN", "Co": "C", "Dt": "DT", "Di": "DS", "Em": "E", "Fi": "FR", "FP": "FP",
    "Fr": "FS", "Cd": "G", "Ha": "H", "Lt": "LG", "|||": "LN", "→→": "P", "Re": "R", "SM": "SM", "Su": "SH",
    "Sh": "SL", "·": "SN", "Sp": "SP", "TE": "T", "Vn": "V",
    **{arrow: "BT" for arrow in "↑↗→↘↓↙←↖"},
}
# alchemy results: catalyst, reactant A, reactant B (catalyst drawn at the bottom)
ALCHEMY_RUNES = {"St": ("FR", "FR", "FS"), "FB": ("FR", "E", "E"), "IC": ("FP", "FS", "FS"), "Cu": ("FR", "BN", "V")}
# slot: (id, gx, gy, abbr, charges, next)
WANDS = [
    [("a", 0, 0, "Amp", 0, "b"), ("b", 1, 0, "Em", 1, "c"), ("c", 2, 0, "Sp", 0, "t"),
     ("d", 1, 1, "Fr", 0, "c"), ("t", 3, 0, "·", 1, "")],
    [("a", 0, 0, "Vn", 0, "b"), ("b", 1, 0, "TE", 0, "c"), ("c", 2, 0, None, 0, "t"), ("t", 3, 0, "|||", 0, "")],
    [("a", 0, 0, "Lt", 1, "c"), ("b", 0, 1, "Fr", 0, "c"), ("c", 1, 0, "Amp", 0, "d"),
     ("d", 2, 0, "Em", 0, "t"), ("t", 3, 0, "↗", 0, "")],
]
# enemy: (name, short, col, row, w, h, hp, max, intent, color, extra)
ENEMIES = [
    ("Goblin", "GOB", 1, 1, 1, 1, 8, 12, ("atk", 6, 0), "#6f8f3a", [("poison", 2)]),
    ("Skeleton", "SKL", 3, 2, 1, 1, 10, 10, ("atk", 5, 2), "#b8b2a0", []),
    ("Orc Brute", "ORC", 2, 4, 2, 2, 24, 30, ("atk", 4, 1), "#8a5a3a", [("armor", 3)]),
    ("War Drummer", "DRM", 4, 0, 1, 1, 9, 9, ("buff", 0, -1), "#a06a8a", []),
]
OBSTACLES = [("Boulder", 0, 3), ("Boulder", 3, 6)]
PUDDLES = [(1, 5), (2, 6), (1, 6), (4, 3)]
COLS, ROWS = 5, 7


def esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;")


class Svg:
    def __init__(self, t):
        self.t = t
        self.parts = []

    def add(self, s):
        self.parts.append(s)

    def rect(self, x, y, w, h, fill="none", stroke="none", sw=1, rx=0, op=1, extra=""):
        self.add(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" fill="{fill}" '
                 f'stroke="{stroke}" stroke-width="{sw}" opacity="{op}" {extra}/>')

    def text(self, x, y, s, size=13, fill=None, anchor="start", weight="normal", font=None, op=1, ls=0):
        fill = fill or self.t["text"]
        font = font or self.t["font"]
        self.add(f'<text x="{x:.1f}" y="{y:.1f}" font-family="{font}" font-size="{size}" fill="{fill}" '
                 f'text-anchor="{anchor}" font-weight="{weight}" opacity="{op}" letter-spacing="{ls}">{esc(s)}</text>')

    def line(self, x1, y1, x2, y2, stroke, sw=1.5, dash="", op=1, marker=""):
        d = f'stroke-dasharray="{dash}"' if dash else ""
        m = f'marker-end="url(#{marker})"' if marker else ""
        self.add(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{stroke}" '
                 f'stroke-width="{sw}" {d} opacity="{op}" stroke-linecap="round" {m}/>')

    def circle(self, cx, cy, r, fill="none", stroke="none", sw=1, op=1):
        self.add(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{fill}" stroke="{stroke}" '
                 f'stroke-width="{sw}" opacity="{op}"/>')

    def save(self, name, defs=""):
        body = "\n".join(self.parts)
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">'
               f'<defs>{defs}{self.t.get("defs", "")}</defs>{body}</svg>')
        (OUT / f"{name}.svg").write_text(svg)


def arrow_defs(color, mid="arr"):
    return (f'<marker id="{mid}" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="7" markerHeight="7" '
            f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{color}"/></marker>')


STATUS_ICON = {"poison": "☠", "burning": "✹", "fire": "✹", "frozen": "❄", "wet": "≈", "armor": "⛨",
               "ward": "⛨", "blind": "◌"}

# ---------------------------------------------------------------- building blocks
def hp_bar(s, x, y, w, h, m, radius=2):
    t = s.t
    s.rect(x, y, w, h, t["hp_bg"], rx=radius)
    after = max(0, m["hp"] - m["incoming"] - sum(st[1] for st in m["status"]))
    s.rect(x, y, w * after / m["max"], h, t["hp"], rx=radius)
    dx = x + w * after / m["max"]
    if m["incoming"]:
        ww = w * min(m["incoming"], m["hp"]) / m["max"]
        s.rect(dx, y, ww, h, t["hp_loss"], rx=0)
        dx += ww
    for _, dmg, c in m["status"]:
        ww = w * dmg / m["max"]
        s.rect(dx, y, ww, h, c, rx=0)
        dx += ww
    if m["shield"]:
        ww = w * m["shield"] / m["max"]
        s.rect(x + w - ww, y, ww, h, t["shield"], op=0.75, rx=radius)


def mana_pips(s, x, y, spent, allow, r=5, gap=13):
    for i in range(allow):
        filled = i < spent
        s.circle(x + i * gap, y, r, s.t["mana"] if filled else s.t["mana_empty"], s.t["mana"], 1.2)


def wand(s, x, y, slots, cell=(58, 50), size=38, active=False):
    t = s.t
    pos = {sid: (x + gx * cell[0], y + gy * cell[1]) for sid, gx, gy, *_ in slots}
    for sid, gx, gy, abbr, ch, nxt in slots:
        if nxt:
            (x1, y1), (x2, y2) = pos[sid], pos[nxt]
            c = size / 2
            ax, ay, bx, by = x1 + c, y1 + c, x2 + c, y2 + c
            if ay != by:
                s.add(f'<path d="M{ax + c - 4:.1f},{ay:.1f} Q{bx - c:.1f},{ay:.1f} {bx - c + 2:.1f},{by + (6 if by < ay else -6):.1f}" '
                      f'fill="none" stroke="{t["edge"]}" stroke-width="1.6" marker-end="url(#edge)"/>')
            else:
                s.line(ax + c, ay, bx - c - 2, by, t["edge"], 1.6, marker="edge")
    for sid, gx, gy, abbr, ch, nxt in slots:
        px, py = pos[sid]
        if abbr is None:
            s.circle(px + size / 2, py + size / 2, size / 2, "none", t["slot_border"], 1)
            continue
        rune_socket(s, px + size / 2, py + size / 2, abbr, size / 2, label=False, charged=ch, tip=nxt == "")
    return pos


def enemy_token(s, x, y, w, h, e, compact=False):
    t = s.t
    name, short, *_r, hp, mx, intent, col, extra = e
    pad = 5
    s.rect(x + pad, y + pad, w - 2 * pad, h - 2 * pad, "none" if short in MONSTER_ART else t["enemy_fill"], col, 2,
           rx=t["token_rx"])
    if short in MONSTER_ART:
        s.add(f'<ellipse cx="{x + w / 2:.1f}" cy="{y + h - pad - 20:.1f}" rx="{w * .3:.1f}" ry="5" fill="#000" opacity=".35"/>')
        s.add(f'<image x="{x + 5:.1f}" y="{y + 13:.1f}" width="{w - 10:.1f}" height="{h - 20:.1f}" '
              f'preserveAspectRatio="xMidYMax meet" href="{MONSTER_ART[short]}"/>')
    else:
        s.circle(x + w / 2, y + h / 2 - 4, min(w, h) * (0.22 if w >= 76 else 0.18), col, op=0.85)
        s.text(x + w / 2, y + h / 2 - 2, short, 11 if w < 100 else 14, t["on_token"], "middle", "bold")
    bw = w - 2 * pad - 10
    s.rect(x + pad + 5, y + h - pad - 14, bw, 6, t["hp_bg"], rx=2)
    s.rect(x + pad + 5, y + h - pad - 14, bw * hp / mx, 6, t["enemy_hp"], rx=2)
    if w >= 76 and short not in MONSTER_ART:
        s.text(x + w / 2, y + h - pad - 18, f"{hp}/{mx}", 9, t["dim"], "middle")
    kind, val, _target = intent
    label = {"atk": f"⚔ {val}", "cleave": f"⚔ {val} all", "buff": "♫ buff", "wail": f"☠ wail {val}",
             "stun": "✶ stunned", "raise": "✝ raise", "heal": f"✚ {val}", "cover": "⛨ cover"}[kind]
    bw2 = 16 + len(label) * 6.2
    ix, iy = x + w / 2 - bw2 / 2, y - 3
    s.rect(ix, iy, bw2, 17, t["intent_bg"], t["intent"], 1, rx=8)
    s.text(x + w / 2, iy + 12.5, label, 11, t["intent"], "middle", "bold", font="DejaVu Sans")
    ox = x + pad + 3
    for k, v in extra:
        c = {"poison": "#9a4fc0", "armor": "#9aa4b0", "wet": "#3f7fd0", "fire": "#e0602a", "frozen": "#6ab8f0",
             "blind": "#707070"}[k]
        s.rect(ox, y + pad + 16, 22, 14, c, rx=3)
        s.text(ox + 11, y + pad + 27, f"{STATUS_ICON[k]}{v}", 10, "#fff", "middle", "bold", font="DejaVu Sans")
        ox += 25


def grid(s, gx, gy, cell, rotated=False, enemies=None, grounds=None, obstacles=None, base=None):
    """Draw 5x7 enemy grid. rotated=True: columns become depth going up (mages below)."""
    t = s.t

    def to_px(c, r, w=1, h=1):
        if not rotated:
            return gx + c * cell, gy + r * cell, w * cell, h * cell
        # col 0 (closest to mages) at bottom, rows run left->right
        return gx + r * cell, gy + (COLS - c - w) * cell, h * cell, w * cell

    grounds = grounds if grounds is not None else [("wet", c, r) for c, r in PUDDLES]
    state = {(c, r): kind for kind, c, r in grounds if kind in STATE_TILES}
    for c in range(COLS):
        for r in range(ROWS):
            x, y, w, h = to_px(c, r)
            if base and GROUND_TILES:
                draw_tile(s, cell_tile(base, state.get((c, r)), c, r), x, y, w)
            else:
                s.rect(x + 1, y + 1, w - 2, h - 2, t["cell"], t["cell_border"], 1, rx=t["cell_rx"])
                if (c, r) in state:
                    GROUND_DRAW[state[(c, r)]](s, x, y, w, h)
    for kind, c, r in grounds:
        if kind not in STATE_TILES:
            x, y, w, h = to_px(c, r)
            GROUND_DRAW[kind](s, x, y, w, h)
    for c in range(COLS):
        for r in range(ROWS):
            x, y, w, h = to_px(c, r)
            s.rect(x + 0.5, y + 0.5, w - 1, h - 1, "none", "#140c08", 1.2, op=0.8)
    for name, c, r in obstacles if obstacles is not None else OBSTACLES:
        x, y, w, h = to_px(c, r)
        obstacle(s, name, x, y, w, h)
    boxes = {}
    for e in enemies if enemies is not None else ENEMIES:
        x, y, w, h = to_px(e[2], e[3], e[4], e[5])
        enemy_token(s, x, y, w, h, e)
        boxes[e[0]] = (x, y, w, h)
    return boxes, to_px


def obstacle(s, name, x, y, w, h):
    t = s.t
    if name == "Boulder" and "stone_3" in GROUND_TILES:
        draw_tile(s, "stone_3", x, y, w)
    elif name == "Grave":
        s.add(f'<path d="M{x + w * .3:.1f},{y + h * .82:.1f} L{x + w * .3:.1f},{y + h * .38:.1f} '
              f'Q{x + w * .3:.1f},{y + h * .16:.1f} {x + w * .5:.1f},{y + h * .16:.1f} '
              f'Q{x + w * .7:.1f},{y + h * .16:.1f} {x + w * .7:.1f},{y + h * .38:.1f} L{x + w * .7:.1f},{y + h * .82:.1f} z" '
              f'fill="#7d776c" stroke="#17110c" stroke-width="3" stroke-linejoin="round"/>')
        s.line(x + w * .44, y + h * .38, x + w * .56, y + h * .38, "#17110c", 2.2)
        s.line(x + w * .5, y + h * .3, x + w * .5, y + h * .52, "#17110c", 2.2)
        s.rect(x + w * .2, y + h * .8, w * .6, h * .07, "#3a2a1c", "#17110c", 2, rx=2)
    else:
        s.add(f'<path d="M{x + w * .18:.1f},{y + h * .8:.1f} L{x + w * .35:.1f},{y + h * .3:.1f} '
              f'L{x + w * .62:.1f},{y + h * .22:.1f} L{x + w * .84:.1f},{y + h * .8:.1f} z" '
              f'fill="{t["rock"]}" stroke="{t["cell_border"]}"/>')


def hover_targeting(s, to_px, pattern_center, cells):
    for c, r in cells:
        x, y, w, h = to_px(c, r)
        s.rect(x + 2, y + 2, w - 4, h - 4, "none", s.t["target"], 2.5, rx=s.t["cell_rx"])
        s.rect(x + 2, y + 2, w - 4, h - 4, s.t["target"], op=0.12, rx=s.t["cell_rx"])


def button(s, x, y, w, h, label, primary=False, size=14):
    t = s.t
    s.rect(x, y, w, h, t["btn_primary"] if primary else t["btn"], t["accent"] if primary else t["border"], 1.2,
           rx=t["btn_rx"])
    s.text(x + w / 2, y + h / 2 + size * 0.36, label, size, t["btn_primary_text"] if primary else t["text"],
           "middle", "bold" if primary else "normal")


def note(s, x, y, lines, w=330):
    h = 18 + 17 * len(lines)
    s.rect(x, y, w, h, "#fff7d6", "#c9a640", 1, rx=4, op=0.96)
    for i, ln in enumerate(lines):
        s.text(x + 10, y + 20 + i * 17, ln, 12, "#4a3a10", font="Noto Sans", weight="bold" if i == 0 else "normal")


def portrait(s, cx, cy, r, m, ring):
    s.circle(cx, cy, r, s.t["portrait_bg"], ring, 2)
    s.circle(cx, cy - r * 0.18, r * 0.34, m["color"], op=0.9)
    s.add(f'<path d="M{cx - r * .6:.1f},{cy + r * .7:.1f} Q{cx:.1f},{cy + r * .05:.1f} {cx + r * .6:.1f},'
          f'{cy + r * .7:.1f} z" fill="{m["color"]}" opacity="0.9"/>')


# ---------------------------------------------------------------- ember grimoire theme
EMBER = dict(
    bg="#1b120d", panel="#2a1c14", panel2="#352318", border="#6b4a2a", inner="#4a3220", text="#f3e3c4",
    dim="#b39470", accent="#f0a030", font="C059", hp="#d9a032", hp_bg="#140c08", hp_loss="#e2442a",
    shield="#e8d9a8", mana="#ff8a2a", mana_empty="#3a2414", edge="#a07a48", slot_fill="#3b281a",
    slot_border="#8b6a40", tip_fill="#4a2a12", tip_border="#ffb84a", slot_rx=19, cell="#2a1d14",
    cell_border="#4a3420", cell_rx=3, enemy_fill="#3a2618", on_token="#fff3dc", enemy_hp="#e2442a",
    intent="#ffcf6a", intent_bg="#3a200e", token_rx=4, rock="#5a4632", target="#ffd34a", btn="#3a2618",
    btn_primary="#e8892a", btn_primary_text="#2a1404", btn_rx=3, portrait_bg="#1b120d",
)
T = EMBER
SERIF = "DejaVu Serif"
SYM = "DejaVu Sans"


DEFS = ('<radialGradient id="vig" cx="50%" cy="45%" r="75%"><stop offset="55%" stop-color="#000" stop-opacity="0"/>'
        '<stop offset="100%" stop-color="#000" stop-opacity="0.55"/></radialGradient>'
        '<linearGradient id="wood" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#6b4424"/>'
        '<stop offset="0.5" stop-color="#8a5a30"/><stop offset="1" stop-color="#4a2c16"/></linearGradient>'
        '<radialGradient id="glow" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#ffb04a" stop-opacity=".55"/>'
        '<stop offset="1" stop-color="#ffb04a" stop-opacity="0"/></radialGradient>'
        '<radialGradient id="ash" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="#7a5a40" stop-opacity=".35"/>'
        '<stop offset="1" stop-color="#7a5a40" stop-opacity="0"/></radialGradient>'
        '<filter id="runeglow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="1.6"/></filter>'
        '<linearGradient id="parch" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#3a2818"/>'
        '<stop offset="1" stop-color="#24170e"/></linearGradient>'
        + arrow_defs(T["edge"], "edge") + arrow_defs(T["target"], "tgt") + arrow_defs(T["intent"], "int"))


# ---------------------------------------------------------------- shared ember chrome
def backdrop(s, line="#2a1b12", bg=None):
    s.rect(0, 0, W, H, bg or T["bg"])
    for i in range(-H, W, 22):
        s.line(i, 0, i + H, H, line, 1, op=0.35)


def title_plate(s, title, left=""):
    s.rect(440, 10, 400, 40, T["panel"], T["border"], 1.5, rx=3)
    s.rect(446, 16, 388, 28, "none", T["inner"], 1, rx=2)
    s.text(W / 2, 36, f"❧  {title}  ☙", 18, T["accent"], "middle", font=SERIF)
    if left:
        s.text(24, 36, left, 18, T["dim"], weight="bold")


def panel(s, x, y, w, h, sel=False, fill=None):
    s.rect(x, y, w, h, fill or T["panel"], T["accent"] if sel else T["border"], 2 if sel else 1.2, rx=4)
    s.rect(x + 6, y + 6, w - 12, h - 12, "none", T["inner"], 1, rx=3)


def panel_heading(s, x, y, w, label, sub=""):
    s.text(x + w / 2, y, label, 17, T["text"], "middle", "bold")
    s.line(x + w / 2 - 70, y + 9, x + w / 2 + 70, y + 9, T["border"], 1)
    if sub:
        s.text(x + w / 2, y + 27, sub, 12, T["dim"], "middle", font=SERIF)


def bottom_bar(s, buttons, hint=""):
    s.rect(0, H - 56, W, 56, "#140d09")
    s.line(0, H - 56, W, H - 56, T["border"], 1.5)
    x = 90
    for label in buttons:
        bw = 26 + len(label) * 8.5
        button(s, x, H - 44, bw, 32, label, size=15)
        x += bw + 10
    if hint:
        s.text(x + 14, H - 23, hint, 13, T["dim"], font=SERIF)


def wax_seal(s, l1, l2, cx=W - 70, cy=H - 42, r=34):
    s.circle(cx, cy, r + 10, "url(#glow)")
    s.circle(cx, cy, r, "#9a2a1a", "#e2643a", 2)
    s.circle(cx, cy, r - 7, "none", "#ffb08a", 1, op=0.6)
    s.text(cx, cy - 3, l1, 14, "#ffe8d0", "middle", "bold")
    s.text(cx, cy + 12, l2, 11, "#ffe8d0", "middle", "bold", font=SYM if not l2.isalpha() else None)


def finish(s, name):
    s.rect(0, 0, W, H, "url(#vig)")
    s.save(name, DEFS + (TILE_DEFS if any("#tile_" in p for p in s.parts) else ""))


def _rune(letters, col, cx, cy, size, width):
    return runes.ember_strokes(letters, col, cx, cy, size, width).replace("url(#glow)", "url(#runeglow)")


def draw_rune(s, abbr, col, cx, cy, r):
    """The spell's rune from spell-runes/, glowing in the spell colour; bolts add their direction arrow."""
    if abbr in ALCHEMY_RUNES:
        for (fx, fy), letters in zip(runes.ALCHEMY_SPOTS, ALCHEMY_RUNES[abbr]):
            s.add(_rune(letters, col, cx + fx * r, cy + fy * r, r * 0.5, max(1.0, r * 0.05)))
        return
    s.add(_rune(RUNE_LETTERS[abbr], col, cx, cy, r * 1.0, max(1.2, r * 0.08)))
    if RUNE_LETTERS[abbr] == "BT":
        s.text(cx + r * 0.62, cy + r * 0.85, abbr, max(9, r * 0.5), col, "middle", "bold", font=SYM)


def rune_socket(s, cx, cy, abbr, r=20, glow=False, label=True, charged=0, tip=False):
    """One look for a spell everywhere: coloured ring, abbreviation, mana pips below (filled = charged)."""
    if abbr is None:
        s.circle(cx, cy, r, "#1e140d", T["inner"], 1.2)
        s.text(cx, cy + 6, "?", 16, T["inner"], "middle", "bold")
        if label:
            s.text(cx, cy + r + 24, "· · ·", 11, T["inner"], "middle")
        return
    name, col, cost = SPELL[abbr]
    if glow or tip:
        s.circle(cx, cy, r + 14, "url(#glow)", op=1 if glow else 0.6)
    s.circle(cx, cy, r, T["tip_fill"] if tip else T["slot_fill"], col, 1.8)
    s.circle(cx, cy, r - 4, "none", T["tip_border"] if tip else T["inner"], 1)
    draw_rune(s, abbr, col, cx, cy, r)
    pr = 3.2 if r >= 18 else 2.6
    for i in range(cost):
        filled = i < charged
        s.circle(cx - (cost - 1) * 4.5 + i * 9, cy + r + 7, pr, T["mana"] if filled else T["mana_empty"], T["mana"], 0.8)
    if label:
        s.text(cx, cy + r + 26, name, 11, T["dim"], "middle")


def staff(s, x, y, length):
    s.rect(x, y, length, 14, "url(#wood)", "#3a2412", 1, rx=7)
    s.circle(x + length - 6, y + 7, 13, "#ffb84a", op=0.35)


def medallion(s, cx, cy, r, m, sel=False, dead=False):
    if dead:
        s.circle(cx, cy, r, "#140d09", T["inner"], 2)
        s.circle(cx, cy - r * 0.18, r * 0.34, "#3a2a1e")
        s.add(f'<path d="M{cx - r * .6:.1f},{cy + r * .7:.1f} Q{cx:.1f},{cy + r * .05:.1f} {cx + r * .6:.1f},'
              f'{cy + r * .7:.1f} z" fill="#3a2a1e"/>')
        return
    if sel:
        s.circle(cx, cy, r + 8, "url(#glow)")
    portrait(s, cx, cy, r, m, T["accent"] if sel else T["border"])


def loot_wand_card(s, x, y, w, runes, label):
    panel(s, x, y, w, 86, fill=T["panel2"])
    s.text(x + 16, y + 28, label, 12, T["dim"])
    staff(s, x + 14, y + 50, w - 28)
    for k, abbr in enumerate(runes):
        cx, cy = x + 40 + k * 56, y + 57
        if abbr:
            rune_socket(s, cx, cy, abbr, 14, label=False)
        else:
            s.circle(cx, cy, 14, "#1e140d", T["slot_border"], 1)


# ---------------------------------------------------------------- monster art + ground effects
def _png_uri(path):
    """PNG trimmed to its visible pixels, as a data URI (monster drafts have wide empty margins)."""
    p = Path(__file__).parent / path
    if not p.exists():
        return ""
    png = subprocess.run(["magick", str(p), "-trim", "+repage", "png:-"], capture_output=True, check=True).stdout
    return "data:image/png;base64," + base64.b64encode(png).decode()


# linocut monster drafts rendered by monsters/generator-script/build.py into monsters/
MONSTER_FILES = {"SKL": "skeleton", "BAN": "banshee", "GOB": "goblin", "SPD": "cave_spider",
                 "PNT": "shadow_panther", "FEL": "fire_elemental", "TRL": "troll", "TRE": "treant"}
MONSTER_ART = {k: v for k, v in ((k, _png_uri(f"monsters/{f}.png")) for k, f in MONSTER_FILES.items()) if v}


def _ground_wet(s, x, y, w, h):
    s.rect(x + 4, y + 4, w - 8, h - 8, "#2f6fb8", rx=9, op=0.35)
    s.add(f'<ellipse cx="{x + w * .38:.1f}" cy="{y + h * .4:.1f}" rx="{w * .16:.1f}" ry="{h * .05:.1f}" '
          f'fill="none" stroke="#8ac0f0" stroke-width="1" opacity=".5"/>')
    s.add(f'<ellipse cx="{x + w * .64:.1f}" cy="{y + h * .66:.1f}" rx="{w * .12:.1f}" ry="{h * .04:.1f}" '
          f'fill="none" stroke="#8ac0f0" stroke-width="1" opacity=".4"/>')


def _ground_frozen(s, x, y, w, h):
    s.rect(x + 3, y + 3, w - 6, h - 6, "#bfe6ff", "#e8f6ff", 1, rx=3, op=0.28)
    for (ax, ay, bx, by) in [(.2, .25, .45, .5), (.45, .5, .4, .8), (.45, .5, .8, .38), (.62, .2, .7, .44)]:
        s.line(x + w * ax, y + h * ay, x + w * bx, y + h * by, "#e8f6ff", 1, op=0.6)


def _ground_burning(s, x, y, w, h):
    s.rect(x + 3, y + 3, w - 6, h - 6, "#e2442a", rx=3, op=0.18)
    for k, (fx, fh) in enumerate([(.3, .32), (.52, .45), (.72, .3)]):
        bx, by, fw = x + w * fx, y + h * .82, w * .1
        s.add(f'<path d="M{bx - fw:.1f},{by:.1f} C{bx - fw:.1f},{by - h * fh * .5:.1f} {bx:.1f},{by - h * fh * .6:.1f} '
              f'{bx:.1f},{by - h * fh:.1f} C{bx:.1f},{by - h * fh * .6:.1f} {bx + fw:.1f},{by - h * fh * .5:.1f} '
              f'{bx + fw:.1f},{by:.1f} z" fill="{"#ff8a2a" if k != 1 else "#ffcf4a"}" opacity=".75"/>')


def _ground_poisoned(s, x, y, w, h):
    s.rect(x + 4, y + 4, w - 8, h - 8, "#6a2f8a", rx=12, op=0.38)
    for fx, fy, r in [(.3, .35, .07), (.6, .55, .1), (.42, .72, .05), (.72, .3, .04)]:
        s.circle(x + w * fx, y + h * fy, w * r, "none", "#c38ae0", 1.2, op=0.7)


def _ground_overgrown(s, x, y, w, h):
    s.rect(x + 3, y + 3, w - 6, h - 6, "#3f7a2a", rx=3, op=0.22)
    for fx in (.25, .45, .65, .8):
        bx, by = x + w * fx, y + h * .85
        s.add(f'<path d="M{bx:.1f},{by:.1f} q{-w * .08:.1f},{-h * .2:.1f} {w * .02:.1f},{-h * .36:.1f}" fill="none" '
              f'stroke="#6fae4a" stroke-width="1.6" opacity=".8"/>')


def _ground_fog(s, x, y, w, h):
    for fx, fy, rx in [(.35, .4, .3), (.62, .55, .32), (.45, .7, .26)]:
        s.add(f'<ellipse cx="{x + w * fx:.1f}" cy="{y + h * fy:.1f}" rx="{w * rx:.1f}" ry="{h * .12:.1f}" '
              f'fill="#d8d0c0" opacity=".2"/>')


def _ground_ash(s, x, y, w, h):
    s.rect(x + 3, y + 3, w - 6, h - 6, "#0e0906", rx=3, op=0.55)
    for fx, fy in [(.3, .3), (.6, .5), (.4, .7), (.75, .25)]:
        s.circle(x + w * fx, y + h * fy, 1.6, "#ff8a2a", op=0.7)


GROUND_DRAW = {"wet": _ground_wet, "frozen": _ground_frozen, "burning": _ground_burning, "poisoned": _ground_poisoned,
               "overgrown": _ground_overgrown, "fog": _ground_fog, "ash": _ground_ash}
GROUND_INFO = [("wet", "Wet", "Puddle. Conducts lightning, freezes into ice."),
               ("frozen", "Frozen", "Ice. Brittle: cracks for bonus damage."),
               ("burning", "Burning", "Fire. Burns whoever stands here each turn."),
               ("poisoned", "Poisoned", "Poison seeps into the one standing here."),
               ("overgrown", "Overgrown", "Vines. Snares, burns away quickly."),
               ("fog", "Fog", "Steam. Hides what stands inside it."),
               ("ash", "Scorched", "Ash and embers left after a fire.")]


# ---------------------------------------------------------------- ground tiles (grounds/)
STATE_TILES = {"wet": "wet", "frozen": "frozen", "burning": "burning", "poisoned": "poisoned",
               "overgrown": ("overgrown_1", "overgrown_2")}


def _tile_uri(name, px=128):
    p = Path(__file__).parent / "grounds" / f"{name}.png"
    if not p.exists():
        return ""
    png = subprocess.run(["magick", str(p), "-resize", f"{px}x{px}", "png:-"], capture_output=True, check=True).stdout
    return "data:image/png;base64," + base64.b64encode(png).decode()


GROUND_TILES = {n: u for n, u in ((p.stem, _tile_uri(p.stem)) for p in sorted((Path(__file__).parent / "grounds").glob("*_*.png"))
                                  if not p.stem.startswith("00")) if u}
GROUND_TILES.update({n: u for n, u in ((n, _tile_uri(n)) for n in ("wet", "frozen", "burning", "poisoned")) if u})
TILE_DEFS = "".join(f'<image id="tile_{n}" width="80" height="80" preserveAspectRatio="none" href="{u}"/>'
                    for n, u in GROUND_TILES.items())


def cell_tile(base, kind, c, r):
    """The one tile a cell shows: its state tile if it has one, else a base variant picked by position."""
    pick = (c * 7 + r * 13 + c * r) % 97
    if kind in STATE_TILES:
        t = STATE_TILES[kind]
        return t if isinstance(t, str) else t[pick % len(t)]
    return base[pick % len(base)]


def draw_tile(s, name, x, y, size):
    s.add(f'<use href="#tile_{name}" transform="translate({x:.1f},{y:.1f}) scale({size / 80:.4f})"/>')


# ---------------------------------------------------------------- battle layouts
# enemy: (name, short, col, row, w, h, hp, max, intent, color, statuses)
CAVERNS = dict(
    title="The Mossy Caverns", turn="Battle 4  ·  Turn 3", mana=7,
    mages=MAGES, sel=0,
    enemies=[
        ("Goblin", "GOB", 1, 1, 1, 1, 18, 30, ("atk", 5, 0), "#33a633", [("poison", 2)]),
        ("Skeleton", "SKL", 3, 2, 1, 1, 22, 30, ("atk", 4, 2), "#ccccb3", [("wet", 1)]),
        ("Cave Spider", "SPD", 4, 0, 1, 1, 40, 40, ("atk", 3, 1), "#8a70b0", []),
        ("Troll", "TRL", 2, 4, 1, 2, 160, 200, ("heal", 30, -1), "#4d8033", []),
        ("Shadow Panther", "PNT", 4, 5, 1, 1, 50, 50, ("cover", 0, -1), "#7a60a0", []),
    ],
    grounds=[("wet", 1, 5), ("wet", 2, 6), ("wet", 1, 6), ("wet", 4, 3), ("wet", 3, 2),
             ("overgrown", 0, 5), ("overgrown", 0, 6), ("fog", 2, 0), ("fog", 3, 0)],
    obstacles=[("Boulder", 0, 3), ("Boulder", 3, 6)], base=["stone_1", "stone_2", "dirt_1", "mud_1", "grass_2"],
    target=[(1, 0), (1, 1), (1, 2), (0, 1), (2, 1)], intent_from="Goblin",
)

GRAVE_MAGES = [
    dict(MAGES[0], hp=20, incoming=13, status=[("Burning", 2, "#e0602a")], spent=2),
    dict(MAGES[1], hp=26, incoming=11, shield=0, status=[], spent=0),
    dict(MAGES[2], hp=0, incoming=0, status=[], spent=0),
]
GRAVEYARD = dict(
    title="The Graveyard", turn="Battle 9  ·  Turn 6", mana=8,
    mages=GRAVE_MAGES, sel=1, dead=[2],
    enemies=[
        ("Skeleton", "SKL", 0, 2, 1, 1, 12, 30, ("atk", 4, 0), "#ccccb3", [("frozen", 1)]),
        ("Skeleton", "SKL", 1, 5, 1, 1, 30, 30, ("stun", 0, -1), "#ccccb3", [("fire", 2)]),
        ("Banshee", "BAN", 3, 3, 1, 1, 22, 40, ("wail", 9, 0), "#9ab0c8", [("blind", 1)]),
        ("Fire Elemental", "FEL", 4, 0, 1, 1, 55, 55, ("atk", 11, 1), "#f2660d", []),
    ],
    grounds=[("frozen", 0, 2), ("frozen", 0, 1), ("frozen", 1, 2), ("burning", 1, 5), ("burning", 2, 5),
             ("ash", 1, 4), ("ash", 2, 4), ("poisoned", 3, 6), ("poisoned", 4, 6), ("poisoned", 4, 5),
             ("fog", 3, 3), ("fog", 4, 3), ("fog", 3, 2), ("wet", 2, 1)],
    obstacles=[("Grave", 2, 3), ("Grave", 0, 6)], base=["dirt_1", "dirt_2", "mud_2", "grass_1", "dirt_2"],
    target=[(3, 2), (3, 3), (3, 4)], intent_from="Banshee", tooltip=(2, 5),
)


def mana_chalice(s, mana):
    s.rect(20, 70, 54, 560, T["panel"], T["border"], 1.5, rx=27)
    for i in range(10):
        yy, on = 600 - i * 52, i < mana
        s.add(f'<path d="M47,{yy - 16} C60,{yy - 2} 58,{yy + 12} 47,{yy + 14} C36,{yy + 12} 34,{yy - 2} 47,{yy - 16} z" '
              f'fill="{T["mana"] if on else T["mana_empty"]}" stroke="{T["mana"]}" stroke-width="1" opacity="{1 if on else .7}"/>')
    s.text(47, 655, f"{mana}/10", 14, T["mana"], "middle", "bold")


def mage_row(s, y, m, slots, sel, dead):
    panel(s, 90, y, 540, 174, sel, fill="#1e140e" if dead else None)
    medallion(s, 146, y + 60, 32, m, sel, dead)
    s.text(146, y + 116, m["name"], 18, T["dim"] if dead else T["text"], "middle", "bold")
    if dead:
        s.text(146, y + 140, "fallen", 13, T["border"], "middle", font=SERIF)
        staff(s, 206, y + 50, 400)
        s.rect(206, y + 40, 400, 40, "#140d09", op=0.6)
        s.text(406, y + 120, "The wand lies cold.", 15, T["border"], "middle", font=SERIF)
        return
    hp_bar(s, 108, y + 128, 76, 9, m, 4)
    s.text(146, y + 152, f"{m['hp']}/{m['max']}", 12, T["dim"], "middle")
    mana_pips(s, 133, y + 163, m["spent"], m["allow"], 4.2, 13)
    staff(s, 206, y + 50, 400)
    wand(s, 226, y + 38, slots, cell=(96, 62), size=38)
    if m["incoming"]:
        s.text(610, y + 26, f"⚔ −{m['incoming']}", 14, T["hp_loss"], "end", "bold", font=SYM)
    tags = [(f"{STATUS_ICON[nm.lower()]} {nm} {v}", c) for nm, v, c in m["status"]]
    if m["shield"]:
        tags.append((f"⛨ Ward {m['shield']}", T["shield"]))
    for k, (txt, c) in enumerate(tags):
        s.text(610, y + 152 - k * 18, txt, 13, c, "end", font=SYM)


def ground_tooltip(s, x, y, kind):
    _, name, desc = next(g for g in GROUND_INFO if g[0] == kind)
    w, h = 250, 64
    s.rect(x, y, w, h, "#140d09", T["accent"], 1.2, rx=3, op=0.97)
    draw_tile(s, cell_tile(["dirt_1"], kind, 0, 0), x + 12, y + 12, 22)
    s.rect(x + 12, y + 12, 22, 22, "none", T["cell_border"], 1, rx=2)
    s.text(x + 44, y + 29, f"{name} ground", 14, T["accent"], weight="bold")
    s.text(x + 14, y + 52, desc, 11, T["dim"])


def battle_board(s, b, show_targets=True):
    cell = 80
    gx, gy = 650 + (610 - COLS * cell) / 2, 78
    panel(s, 650, 64, 610, 580, fill="#21170f")
    boxes, to_px = grid(s, gx, gy, cell, enemies=b["enemies"], grounds=b["grounds"], obstacles=b["obstacles"],
                        base=b.get("base"))
    return boxes, to_px


def draw_battle(s, b):
    backdrop(s)
    title_plate(s, b["title"], b["turn"])
    mana_chalice(s, b["mana"])
    for i, m in enumerate(b["mages"]):
        mage_row(s, 70 + i * 186, m, WANDS[i], i == b["sel"], i in b.get("dead", []))
    boxes, to_px = battle_board(s, b)
    hover_targeting(s, to_px, None, b["target"])
    src = next(e for e in b["enemies"] if e[0] == b["intent_from"])
    bx, by, bw, bh = boxes[src[0]]
    s.line(bx + 4, by + bh / 2, 632, 70 + src[8][2] * 186 + 60, T["intent"], 2.2, "2 6", 0.9, "int")
    if "tooltip" in b:
        c, r = b["tooltip"]
        x, y, w, h = to_px(c, r)
        s.rect(x + 2, y + 2, w - 4, h - 4, "none", T["accent"], 2, rx=3)
        ground_tooltip(s, x - 85, y + h + 4, "burning")
    bottom_bar(s, ["↶ Undo", "Codex"], "Touch a wand's tip to aim  ·  right-click a rune to draw its mana back")
    wax_seal(s, "END", "TURN")


def screen_battle():
    s = Svg(T)
    draw_battle(s, CAVERNS)
    finish(s, "01a_battle_caverns")


def screen_battle_graveyard():
    s = Svg(T)
    draw_battle(s, GRAVEYARD)
    finish(s, "01b_battle_graveyard")


def screen_battle_won():
    s = Svg(T)
    b = dict(GRAVEYARD, enemies=[], turn="Battle 9  ·  Turn 7", mana=0)
    backdrop(s)
    title_plate(s, b["title"], b["turn"])
    mana_chalice(s, 0)
    for i, m in enumerate(b["mages"]):
        mage_row(s, 70 + i * 186, dict(m, incoming=0), WANDS[i], False, i in b["dead"])
    boxes, to_px = battle_board(s, b)
    s.rect(0, 0, W, H, "#000", op=0.5)
    # victory plaque
    px, py, pw, ph = 340, 190, 600, 300
    s.circle(W / 2, py + 60, 200, "url(#glow)")
    panel(s, px, py, pw, ph, True, fill="url(#parch)")
    s.text(W / 2, py + 74, "Victory", 52, T["accent"], "middle", "bold")
    s.text(W / 2, py + 108, "The Graveyard falls silent.", 17, T["text"], "middle", font=SERIF)
    s.line(W / 2 - 120, py + 128, W / 2 + 120, py + 128, T["border"])
    rows = [("Turns", "7"), ("Foes slain", "4"), ("Lost", "Vael")]
    for k, (a, v) in enumerate(rows):
        yy = py + 164 + k * 28
        s.text(W / 2 - 20, yy, a, 15, T["dim"], "end")
        s.text(W / 2 + 10, yy, v, 15, T["hp_loss"] if a == "Lost" else T["text"], weight="bold")
    bottom_bar(s, ["Codex"], "")
    wax_seal(s, "CLAIM", "SPOILS", W / 2, py + ph + 10, 36)
    finish(s, "01c_battle_won")


# ---------------------------------------------------------------- 02 loot
def screen_loot():
    s = Svg(T)
    backdrop(s)
    title_plate(s, "Spoils of the Caverns", "Battle 4 won")
    panel(s, 20, 66, 390, 584)
    panel_heading(s, 20, 98, 390, "Spoils", "1 of 3 taken")
    for k, a in enumerate(["Lt", "FP", "Bn", "Sh", "Dt"]):
        rune_socket(s, 80 + (k % 4) * 90, 170 + (k // 4) * 92, a, 24, glow=(k == 0))
    s.text(48, 360, "Wands", 13, T["dim"], ls=1.5)
    s.line(100, 356, 382, 356, T["inner"])
    loot_wand_card(s, 36, 372, 358, ["Fr", "Lt", "|||"], "Rowan staff  ·  3 runes  ·  tip: Line")
    loot_wand_card(s, 36, 470, 358, [None, None, None, None, "→→"], "Bog-oak staff  ·  5 runes  ·  tip: Pierce")
    s.text(215, 610, "What you leave behind is lost to the dark.", 12, T["dim"], "middle", font=SERIF)
    panel(s, 426, 66, 360, 584)
    panel_heading(s, 426, 98, 360, "Satchel", "9 of 24 pockets")
    held = ["Em", "Amp", "Vn", "TE", "Fr", "Sp", "Su", "Cd", "·"]
    for k in range(24):
        cx, cy = 476 + (k % 5) * 65, 170 + (k // 5) * 88
        if k < len(held):
            rune_socket(s, cx, cy, held[k], 20)
        else:
            s.circle(cx, cy, 20, "#1e140d", T["inner"], 1, op=0.8)
    s.line(110, 170, 600, 336, T["accent"], 1.8, "2 6", 0.75, "tgt")
    s.circle(606, 346, 22, "none", T["accent"], 2, op=0.8)
    panel(s, 802, 66, 458, 584)
    panel_heading(s, 802, 98, 458, "Wielded Wands")
    for i, m in enumerate(MAGES):
        y = 126 + i * 172
        medallion(s, 850, y + 44, 26, m)
        s.text(850, y + 92, m["name"], 14, T["text"], "middle", "bold")
        s.text(850, y + 108, f"{m['hp']}/{m['max']}", 11, T["dim"], "middle")
        staff(s, 892, y + 34, 350)
        wand(s, 906, y + 22, WANDS[i], cell=(84, 56), size=38)
    bottom_bar(s, ["+ Rune", "↺ Reroll", "Codex", "Auto Assign"], "Drag runes between spoils, satchel and wands")
    wax_seal(s, "GO", "FORTH")
    finish(s, "02_loot")


# ---------------------------------------------------------------- 03 level up
def screen_level_up():
    s = Svg(T)
    backdrop(s)
    title_plate(s, "The Embers Grow", "Battle 4 won")
    s.text(W / 2, 92, "One mage may draw strength from the fire.", 15, T["dim"], "middle", font=SERIF)
    cw, gap = 360, 40
    x0 = (W - 3 * cw - 2 * gap) / 2
    for i, m in enumerate(MAGES):
        x, y = x0 + i * (cw + gap), 116
        sel = i == 2
        panel(s, x, y, cw, 494, sel)
        medallion(s, x + cw / 2, y + 74, 46, m, sel)
        s.text(x + cw / 2, y + 150, m["name"], 22, T["text"], "middle", "bold")
        hp_bar(s, x + 80, y + 166, cw - 160, 9, dict(m, incoming=0, status=[], shield=0), 4)
        s.text(x + cw / 2, y + 194, f"{m['hp']}/{m['max']}", 12, T["dim"], "middle")
        opts = [("♥", "Vitality", "Max HP", f"{m['max']}  →  {m['max'] + 10}", "#e2643a"),
                ("✦", "Attunement", "Mana per turn", f"{m['allow']}  →  {m['allow'] + 1}", T["mana"])]
        for k, (icon, title, sub, val, c) in enumerate(opts):
            oy = y + 230 + k * 130
            hov = sel and k == 1
            s.rect(x + 24, oy, cw - 48, 110, T["tip_fill"] if hov else T["panel2"],
                   T["tip_border"] if hov else T["slot_border"], 1.6 if hov else 1, rx=3)
            if hov:
                s.circle(x + 66, oy + 55, 36, "url(#glow)")
            s.circle(x + 66, oy + 55, 22, T["slot_fill"], c, 1.6)
            s.text(x + 66, oy + 62, icon, 18, c, "middle", font=SYM)
            s.text(x + 104, oy + 42, title, 17, T["text"], weight="bold")
            s.text(x + 104, oy + 60, sub, 12, T["dim"])
            s.text(x + 104, oy + 88, val, 17, c, weight="bold")
    bottom_bar(s, ["Codex"], "Pick one upgrade  ·  the whole party heals before the next battle")
    finish(s, "03_level_up")


# ---------------------------------------------------------------- 04 path selection
# Boss omens: shown on a biome card from approach 5 on, growing more ominous until the boss at approach 10.
OMENS = {
    5: ("The air grows still.", "#b39470"),
    6: ("Tracks too large for any beast.", "#c08a60"),
    7: ("Something watches from afar.", "#c97a50"),
    8: ("The ground trembles at night.", "#d26a44"),
    9: ("Its breath can be heard.", "#da5a38"),
    10: ("☠ The guardian stirs", "#e2442a"),
}


def biome_card(s, x, y, w, h, b, sel=False):
    name, tag, color, level = b
    panel(s, x, y, w, h, sel, fill="url(#parch)")
    s.rect(x + 14, y + 14, w - 28, 210, color, op=0.12, rx=2)
    cx, cy = x + w / 2, y + 118
    if sel:
        s.circle(cx, cy, 95, "url(#glow)")
    s.circle(cx, cy, 64, T["slot_fill"], color, 2.5)
    s.circle(cx, cy, 54, "none", T["inner"], 1)
    for k in range(8):
        a = k * math.pi / 4
        s.line(cx + 58 * math.cos(a), cy + 58 * math.sin(a), cx + 70 * math.cos(a), cy + 70 * math.sin(a), color, 1.5)
    s.text(cx, cy + 14, name[0], 40, color, "middle", "bold")
    s.text(cx, y + 262, name, 30, T["text"], "middle", "bold")
    s.line(cx - 90, y + 276, cx + 90, y + 276, T["border"])
    s.text(cx, y + 302, f"“{tag}”", 14, T["dim"], "middle", font=SERIF)
    s.text(cx, y + 340, f"Approach {level} of 10", 13, T["accent"], "middle")
    for k in range(10):
        s.circle(cx - 81 + k * 18, y + 362, 5, T["mana"] if k < level - 1 else T["mana_empty"], T["mana"], 1)
    if level in OMENS:
        omen, col = OMENS[level]
        s.text(cx, y + 396, omen, 14 + (level - 5) * 0.4, col, "middle", font=SYM if level == 10 else SERIF)


def screen_path():
    s = Svg(T)
    backdrop(s)
    title_plate(s, "Choose Your Path", "Next: battle 5")
    s.add(f'<path d="M640,600 C600,520 420,540 340,500" fill="none" stroke="{T["border"]}" stroke-width="2" '
          'stroke-dasharray="3 8"/>')
    s.add(f'<path d="M640,600 C680,520 860,540 940,500" fill="none" stroke="{T["accent"]}" stroke-width="2.5" '
          'stroke-dasharray="3 8"/>')
    s.circle(640, 604, 9, T["accent"], "#ffe0a0", 1.5)
    s.text(640, 632, "you are here", 12, T["dim"], "middle", font=SERIF)
    biome_card(s, 110, 76, 460, 420, ("Swamp", "Nothing enters here and leaves clean.", "#5aa060", 7))
    biome_card(s, 710, 76, 460, 420, ("Desert", "The heat breaks minds before bodies.", "#e0a030", 10),
               sel=True)
    bottom_bar(s, ["Codex"], "Choose a road  ·  each grows harder the more often it is walked")
    finish(s, "04_path_selection")


# ---------------------------------------------------------------- 05 codex overlay
def codex_rows(s, x, y, title, runes, step=76):
    s.text(x, y, title, 14, T["dim"], ls=1.2)
    for k, a in enumerate(runes):
        rune_socket(s, x + 30 + (k % 6) * step, y + 50 + (k // 6) * 74, a, 22, glow=(a == "Fi"))


def screen_codex():
    s = Svg(T)
    backdrop(s)
    s.rect(0, 0, W, H, "#000", op=0.55)
    bx, by, bw, bh = 120, 50, 1040, 630
    s.rect(bx - 10, by - 6, bw + 20, bh + 12, "#3a2412", "#6b4424", 2, rx=8)
    s.rect(bx, by, bw / 2, bh, "url(#parch)", T["border"], 1, rx=3)
    s.rect(bx + bw / 2, by, bw / 2, bh, "url(#parch)", T["border"], 1, rx=3)
    s.line(bx + bw / 2, by + 6, bx + bw / 2, by + bh - 6, "#120a06", 4, op=0.7)
    for k, tab in enumerate(["Runes", "Bestiary", "Lands"]):
        tx, act = bx + 40 + k * 120, k == 0
        s.rect(tx, by - 36, 104, 34, T["btn_primary"] if act else T["btn"], T["border"], 1, rx=2)
        s.text(tx + 52, by - 13, tab, 15, T["btn_primary_text"] if act else T["dim"], "middle", "bold")
    s.text(bx + bw - 30, by + 34, "✕", 18, T["dim"], "middle", font=SYM)
    codex_rows(s, bx + 40, by + 32, "Body runes", ["Em", "Fr", "Vn", "Bn", "Lt", "Dt", "Fi", "FP", "Amp", "Sh", None, None,
                                                  "Di", "Su", None, "SM", "Cd", "TE"])
    codex_rows(s, bx + 40, by + 300, "Tip runes", ["·", "|||", "→→", "bomb", "↑", "↗", "→", "↘", "↓", None, None, None])
    codex_rows(s, bx + 40, by + 494, "Alchemy  ·  2 discovered", ["St", "IC", None, None, None, None])
    px, cx = bx + bw / 2 + 50, bx + bw * 0.75
    s.circle(cx, by + 112, 76, "url(#glow)")
    rune_socket(s, cx, by + 112, "Fi", 46, label=False)
    s.text(cx, by + 206, "Fire", 30, T["text"], "middle", "bold")
    s.line(cx - 90, by + 220, cx + 90, by + 220, T["border"])
    s.text(cx, by + 246, "Catalyst  ·  1 mana  ·  Fire", 14, T["accent"], "middle")
    lines = ["Deals 2 damage and applies 3 fire stacks.", "",
             "Leading a trio, it heats the two spells", "after it into something new."]
    for k, ln in enumerate(lines):
        s.text(px, by + 294 + k * 22, ln, 15, T["text"], font=SERIF)
    s.text(px, by + 436, "Known reactions", 14, T["dim"], ls=1.2)
    s.line(px, by + 446, px + 420, by + 446, T["inner"])
    for k, (trio, out, col) in enumerate([(("Fi", "Fi", "Fr"), "Steam", "#d8d8d8"),
                                           (("Fi", "Fr", "Vn"), "Fizzle", T["dim"])]):
        yy = by + 486 + k * 56
        for j, ab in enumerate(trio):
            rune_socket(s, px + 20 + j * 44, yy, ab, 15, label=False)
        s.text(px + 160, yy + 6, "→", 18, T["dim"], font=SYM)
        s.text(px + 192, yy + 6, out, 16, col, weight="bold")
    s.text(bx + bw / 2 - 30, by + bh - 18, "iv", 12, T["dim"], "end", font=SERIF)
    s.text(bx + bw / 2 + 30, by + bh - 18, "v", 12, T["dim"], font=SERIF)
    finish(s, "05_codex")


# ---------------------------------------------------------------- 06 game over
def cold_brazier(s, cx, top):
    s.add(f'<path d="M{cx - 80},{top} L{cx + 80},{top} L{cx + 50},{top + 50} L{cx - 50},{top + 50} z" '
          f'fill="#2a1c14" stroke="{T["border"]}" stroke-width="2"/>')
    s.rect(cx - 20, top + 50, 40, 40, "#2a1c14", T["border"], 1.5)
    s.rect(cx - 50, top + 88, 100, 12, "#2a1c14", T["border"], 1.5, rx=2)
    for k, (dx, dy) in enumerate([(-30, -10), (0, -40), (25, -18), (12, -70), (-14, -95)]):
        s.circle(cx + dx, top - 10 + dy, 6 - k * 0.8, "#8a6a50", op=0.5 - k * 0.07)
    s.circle(cx - 15, top - 2, 3, T["mana"], op=0.8)


def screen_game_over():
    s = Svg(T)
    backdrop(s, "#1a110b", "#0e0906")
    s.circle(W / 2, 250, 240, "url(#ash)")
    cold_brazier(s, W / 2, 300)
    s.text(W / 2, 140, "The Embers Fade", 54, "#c9a27a", "middle", "bold")
    s.text(W / 2, 182, "All mages have fallen.", 18, T["dim"], "middle", font=SERIF)
    for i, m in enumerate(MAGES):
        cx = W / 2 + (i - 1) * 180
        medallion(s, cx, 470, 34, m, dead=True)
        s.text(cx, 530, m["name"], 16, T["dim"], "middle", "bold")
        s.text(cx, 550, ["fell in battle 12", "fell in battle 14", "fell in battle 14"][i], 12, T["border"],
               "middle", font=SERIF)
    s.text(W / 2, 600, "Battles won: 14   ·   Furthest: Desert, approach 10   ·   Alchemy found: 2", 15,
           T["accent"], "middle")
    wax_seal(s, "BEGIN", "ANEW", W / 2, 660, 32)
    finish(s, "06_game_over")


# ---------------------------------------------------------------- 07 victory
def lit_brazier(s, cx, top):
    s.circle(cx, top - 30, 150, "url(#glow)")
    flames = [(0, 120, 40, "#ff8a2a"), (-22, 80, 26, "#e2643a"), (24, 90, 26, "#e2643a"), (0, 70, 20, "#ffd34a")]
    for dx, hgt, wid, col in flames:
        bx = cx + dx
        s.add(f'<path d="M{bx - wid},{top} C{bx - wid},{top - hgt * .5} {bx - wid * .2},{top - hgt * .6} {bx},{top - hgt} '
              f'C{bx + wid * .2},{top - hgt * .6} {bx + wid},{top - hgt * .5} {bx + wid},{top} z" fill="{col}" opacity="0.9"/>')
    s.add(f'<path d="M{cx - 80},{top} L{cx + 80},{top} L{cx + 50},{top + 50} L{cx - 50},{top + 50} z" '
          f'fill="#3a2618" stroke="{T["accent"]}" stroke-width="2"/>')
    s.rect(cx - 20, top + 50, 40, 40, "#3a2618", T["accent"], 1.5)
    s.rect(cx - 50, top + 88, 100, 12, "#3a2618", T["accent"], 1.5, rx=2)
    for k, (dx, dy) in enumerate([(-50, -130), (40, -150), (-10, -175), (60, -110), (-70, -95)]):
        s.circle(cx + dx, top + dy, 3 - k * 0.3, "#ffd34a", op=0.8 - k * 0.1)


def screen_victory():
    s = Svg(T)
    backdrop(s)
    s.circle(W / 2, 330, 320, "url(#glow)", op=0.5)
    s.text(W / 2, 118, "The Great Work Is Done", 50, T["accent"], "middle", "bold")
    s.text(W / 2, 160, "The Source is sealed. The fire answers to you now.", 18, T["text"], "middle", font=SERIF)
    lit_brazier(s, W / 2, 360)
    fates = [("returned", False), ("returned", False), ("fell at the Source", True)]
    for i, m in enumerate(MAGES):
        cx = W / 2 + (i - 1) * 180
        fate, dead = fates[i]
        medallion(s, cx, 520, 34, m, sel=not dead, dead=dead)
        s.text(cx, 580, m["name"], 16, T["dim"] if dead else T["text"], "middle", "bold")
        s.text(cx, 600, fate, 12, T["border"] if dead else T["dim"], "middle", font=SERIF)
    s.text(W / 2, 640, "Battles won: 112   ·   Guardians slain: 7   ·   Alchemy found: 23 of 31", 15,
           T["accent"], "middle")
    wax_seal(s, "BEGIN", "ANEW", W / 2, 684, 30)
    finish(s, "07_victory")


# ---------------------------------------------------------------- 01d/01e detail overlays
def section_title(s, x, y, w, label):
    s.text(x, y, label, 13, T["dim"], ls=1.3)
    s.line(x + len(label) * 8 + 10, y - 4, x + w, y - 4, T["inner"])


def info_row(s, x, y, w, icon, icon_col, title, desc, right="", right_col=None, hi=False):
    if hi:
        s.rect(x - 8, y - 20, w + 16, 46, T["tip_fill"], T["tip_border"], 1.2, rx=3)
    s.circle(x + 12, y - 1, 13, T["slot_fill"], icon_col, 1.4)
    s.text(x + 12, y + 4, icon, 13, icon_col, "middle", font=SYM)
    s.text(x + 34, y - 2, title, 15, T["text"], weight="bold")
    s.text(x + 34, y + 16, desc, 11, T["dim"])
    if right:
        s.text(x + w, y + 4, right, 14, right_col or T["accent"], "end", "bold", font=SYM)


def dim_battle(s):
    s.rect(0, 64, W, H - 120, "#000", op=0.6)


def close_hint(s, x, y):
    s.text(x, y, "✕", 18, T["dim"], "middle", font=SYM)


def screen_monster_details():
    s = Svg(T)
    draw_battle(s, {k: v for k, v in GRAVEYARD.items() if k != "tooltip"})
    dim_battle(s)
    boxes, to_px = battle_board_positions(GRAVEYARD)
    ban = next(e for e in GRAVEYARD["enemies"] if e[0] == "Banshee")
    x, y, w, h = to_px(ban[2], ban[3])
    s.circle(x + w / 2, y + h / 2, 70, "url(#glow)")
    enemy_token(s, x, y, w, h, ban)
    s.rect(x, y, w, h, "none", T["accent"], 2.5, rx=4)
    s.line(x - 2, y + h / 2, 640, 300, T["accent"], 1.6, "2 6", 0.8)
    # bestiary page
    px, py, pw, ph = 90, 70, 550, 570
    panel(s, px, py, pw, ph, True, fill="url(#parch)")
    close_hint(s, px + pw - 24, py + 30)
    s.circle(px + 110, py + 112, 92, "url(#ash)")
    if "BAN" in MONSTER_ART:
        s.add(f'<image x="{px + 26}" y="{py + 26}" width="170" height="170" preserveAspectRatio="xMidYMid meet" '
              f'href="{MONSTER_ART["BAN"]}"/>')
    tx = px + 214
    s.text(tx, py + 58, "Banshee", 30, T["text"], weight="bold")
    s.text(tx, py + 82, "Debuffer  ·  Graveyard", 13, T["accent"])
    s.rect(tx, py + 98, 290, 10, T["hp_bg"], rx=4)
    s.rect(tx, py + 98, 290 * 22 / 40, 10, T["enemy_hp"], rx=4)
    s.text(tx, py + 128, "22/40", 13, T["dim"])
    s.text(tx + 290, py + 128, "Blinded 1", 13, "#a0a0a0", "end", font=SERIF)
    for k, ln in enumerate(["“A wailing spirit whose soul-draining", "screams weaken and terrify the living.”"]):
        s.text(tx, py + 160 + k * 18, ln, 12, T["dim"], font=SERIF)
    ix, iw = px + 34, pw - 68
    section_title(s, ix, py + 232, iw, "This turn")
    info_row(s, ix, py + 270, iw, "☠", T["intent"], "Wail → Lyra",
             "Blinded: 50% to miss, 50% to strike a random mage instead", "9", T["hp_loss"], hi=True)
    section_title(s, ix, py + 322, iw, "Might also")
    info_row(s, ix, py + 356, iw, "⚔", T["dim"], "Soul Drain", "Heavy strike on one mage", "12", T["dim"])
    info_row(s, ix, py + 400, iw, "●", "#c0306a", "Leech", "Heals 1 for each mana the target spends this turn")
    section_title(s, ix, py + 452, iw, "Nature")
    info_row(s, ix, py + 486, iw, "✹", "#e0602a", "Burning touch 2", "Its hits set mages burning")
    info_row(s, ix + iw / 2, py + 486, iw / 2, "☠", "#9a4fc0", "Poison immune", "Toxins do nothing")
    s.text(ix, py + 542, "Stands in fog  ·  hidden from sight", 12, T["dim"], font=SERIF)
    s.text(ix + iw - 84, py + 542, "May drop:", 12, T["dim"], "end", font=SERIF)
    rune_socket(s, ix + iw - 58, py + 532, "Em", 14, label=False)
    rune_socket(s, ix + iw - 16, py + 532, "Fr", 14, label=False)
    finish(s, "01d_details_monster")


def screen_mage_details():
    s = Svg(T)
    draw_battle(s, {k: v for k, v in dict(GRAVEYARD, sel=0).items() if k != "tooltip"})
    dim_battle(s)
    m = GRAVE_MAGES[0]
    mage_row(s, 70, m, WANDS[0], True, False)
    # mage page over the board
    px, py, pw, ph = 650, 64, 610, 580
    panel(s, px, py, pw, ph, True, fill="url(#parch)")
    close_hint(s, px + pw - 24, py + 30)
    medallion(s, px + 80, py + 80, 46, m, True)
    tx = px + 150
    s.text(tx, py + 64, "Lyra", 30, T["text"], weight="bold")
    s.text(tx, py + 88, "12 battles survived", 13, T["accent"])
    hp_bar(s, tx, py + 104, 300, 10, m, 4)
    s.text(tx, py + 134, f"{m['hp']}/{m['max']}", 13, T["dim"])
    s.text(tx + 300, py + 134, f"−{m['incoming']} incoming  ·  −2 burn", 13, T["hp_loss"], "end", "bold")
    ix, iw = px + 34, pw - 68
    section_title(s, ix, py + 184, iw, "Attributes")
    info_row(s, ix, py + 220, iw / 2 - 10, "♥", "#e2643a", "Max HP 30", "+10 per Vitality upgrade")
    info_row(s, ix + iw / 2, py + 220, iw / 2, "✦", T["mana"], "Mana per turn 3", f"{m['spent']} spent  ·  {m['allow'] - m['spent']} left this turn")
    info_row(s, ix, py + 266, iw / 2 - 10, "◆", "#e0602a", "Focus: Ember", "+1 fire mana each round")
    info_row(s, ix + iw / 2, py + 266, iw / 2, "↯", T["dim"], "Mana debt 1", "Fizzle in the last battle")
    section_title(s, ix, py + 318, iw, "Afflictions")
    info_row(s, ix, py + 352, iw, "✹", "#e0602a", "Burning 2", "Takes 2 damage at the end of each turn, then it fades by 1",
             "2 turns", T["dim"])
    section_title(s, ix, py + 404, iw, "Threats")
    info_row(s, ix, py + 438, iw, "☠", T["intent"], "Banshee · Wail", "Blinded: may miss or hit someone else", "9",
             T["hp_loss"])
    info_row(s, ix, py + 482, iw, "⚔", T["intent"], "Skeleton · Strike", "Frozen in place, still strikes", "4", T["hp_loss"])
    s.text(ix, py + 540, "Cast now: Ember ×2 (Amplify) = 6 damage + 6 fire  ·  Splash: half to the 4 neighbours", 12, T["accent"],
           font=SERIF)
    finish(s, "01e_details_mage")


def battle_board_positions(b):
    cell = 80
    gx, gy = 650 + (610 - COLS * cell) / 2, 78

    def to_px(c, r, w=1, h=1):
        return gx + c * cell, gy + r * cell, w * cell, h * cell
    return None, to_px


# ---------------------------------------------------------------- 01f/01g large branching wands
# slot: (id, gx, gy, abbr, charges, next) -- several branches merge toward the single tip
BIG_WANDS = [
    [("A", 0, 0, "Em", 1, "E"), ("B", 0, 1, "Cd", 0, "F"), ("C", 0, 2, "Fr", 0, "G"), ("D", 0, 3, "Lt", 1, "H"),
     ("E", 1, 0, "Amp", 0, "I"), ("F", 1, 1, "Em", 0, "I"), ("G", 1, 2, "Amp", 0, "J"), ("H", 1, 3, "FP", 0, "J"),
     ("I", 2, 0, "Fr", 1, "K"), ("J", 2, 2, "Vn", 0, "L"), ("K", 3, 0, "Bn", 0, "M"), ("L", 3, 2, "TE", 0, "M"),
     ("M", 4, 1, "Sp", 0, "T"), ("T", 5, 1, "·", 1, "")],
    [("a", 0, 0, "Vn", 1, "d"), ("b", 0, 1, "Cd", 0, "e"), ("c", 0, 2, "Bn", 0, "f"), ("d", 1, 0, "TE", 0, "g"),
     ("e", 1, 1, "Sh", 0, "h"), ("f", 1, 2, "Fr", 0, "h"), ("g", 2, 0, "Amp", 0, "j"), ("h", 2, 1, "FP", 0, "j"),
     ("j", 3, 1, "Ha", 0, "k"), ("k", 4, 1, "Em", 0, "t"), ("t", 5, 1, "|||", 0, "")],
    [("a", 0, 0, "Lt", 1, "c"), ("c", 1, 0, "Amp", 0, "e"), ("e", 2, 0, "Em", 0, "g"), ("i", 1, 1, "FP", 0, "h"),
     ("h", 2, 1, "Bn", 0, "g"), ("b", 0, 2, "Fr", 0, "d"), ("d", 1, 2, "Cd", 0, "f"), ("f", 2, 2, "Lt", 0, "g"),
     ("g", 3, 1, "SM", 0, "t"), ("t", 4, 1, "→→", 0, "")],
]
BIG_MAGES = [dict(m, allow=6, spent=sum(sl[4] for sl in w)) for m, w in zip(MAGES, BIG_WANDS)]


def mini_wand(s, x, y, slots, cell=(30, 18), r=6):
    """Read-only thumbnail: coloured dots and thin edges, no text."""
    pos = {sid: (x + gx * cell[0], y + gy * cell[1]) for sid, gx, gy, *_ in slots}
    for sid, gx, gy, abbr, ch, nxt in slots:
        if nxt:
            (x1, y1), (x2, y2) = pos[sid], pos[nxt]
            s.line(x1, y1, x2, y2, T["edge"], 1, op=0.7)
    for sid, gx, gy, abbr, ch, nxt in slots:
        col = SPELL[abbr][1] if abbr else T["inner"]
        s.circle(*pos[sid], r + (2 if nxt == "" else 0), T["slot_fill"], col, 1.6 if ch else 1)
        if ch:
            s.circle(*pos[sid], r - 2.5, T["mana"])


def collapsed_row(s, y, h, m, slots):
    panel(s, 90, y, 540, h)
    medallion(s, 130, y + h / 2 - 6, 24, m)
    s.text(130, y + h / 2 + 36, m["name"], 14, T["text"], "middle", "bold")
    hp_bar(s, 176, y + 34, 110, 8, m, 4)
    s.text(176, y + 60, f"{m['hp']}/{m['max']}", 12, T["dim"])
    mana_pips(s, 180, y + 80, m["spent"], m["allow"], 4, 12)
    if m["incoming"]:
        s.text(286, y + 60, f"⚔ −{m['incoming']}", 13, T["hp_loss"], "end", "bold", font=SYM)
    mini_wand(s, 330, y + h / 2 - 27, slots)
    s.text(612, y + h - 16, f"{len(slots)} runes  ·  click to open", 11, T["dim"], "end", font=SERIF)


def expanded_row(s, y, h, m, slots):
    panel(s, 90, y, 540, h, True)
    medallion(s, 136, y + 50, 28, m, True)
    s.text(176, y + 44, m["name"], 20, T["text"], weight="bold")
    hp_bar(s, 176, y + 56, 150, 9, m, 4)
    s.text(176, y + 82, f"{m['hp']}/{m['max']}", 12, T["dim"])
    s.text(352, y + 50, "MANA", 10, T["dim"], ls=1.2)
    mana_pips(s, 400, y + 46, m["spent"], m["allow"], 5, 14)
    s.text(612, y + 36, f"⚔ −{m['incoming']}", 14, T["hp_loss"], "end", "bold", font=SYM)
    s.text(612, y + 82, f"{len(slots)} runes", 12, T["dim"], "end", font=SERIF)
    s.line(110, y + 100, 610, y + 100, T["inner"])
    staff(s, 112, y + 112 + 56 + 19 - 7, 498)
    wand(s, 128, y + 112, slots, cell=(88, 56), size=38)


def compact_row(s, y, m, slots, sel):
    panel(s, 90, y, 540, 174, sel)
    medallion(s, 140, y + 52, 28, m, sel)
    s.text(140, y + 102, m["name"], 16, T["text"], "middle", "bold")
    hp_bar(s, 106, y + 114, 68, 8, m, 4)
    s.text(140, y + 138, f"{m['hp']}/{m['max']}", 11, T["dim"], "middle")
    mana_pips(s, 104, y + 156, m["spent"], m["allow"], 3.6, 12)
    staff(s, 200, y + 12 + 38 + 14 - 7, 416)
    wand(s, 214, y + 12, slots, cell=(74, 38), size=28)
    if m["incoming"]:
        s.text(616, y + 24, f"⚔ −{m['incoming']}", 13, T["hp_loss"], "end", "bold", font=SYM)


def big_wand_board(s, b, row_mid_y):
    boxes, to_px = battle_board(s, b)
    hover_targeting(s, to_px, None, b["target"])
    src = next(e for e in b["enemies"] if e[0] == b["intent_from"])
    bx, by, bw, bh = boxes[src[0]]
    s.line(bx + 4, by + bh / 2, 632, row_mid_y, T["intent"], 2.2, "2 6", 0.9, "int")


def screen_battle_big_focus():
    s = Svg(T)
    backdrop(s)
    title_plate(s, CAVERNS["title"], CAVERNS["turn"])
    mana_chalice(s, 10 - sum(m["spent"] for m in BIG_MAGES))
    expanded_row(s, 70, 340, BIG_MAGES[0], BIG_WANDS[0])
    collapsed_row(s, 420, 105, BIG_MAGES[1], BIG_WANDS[1])
    collapsed_row(s, 535, 105, BIG_MAGES[2], BIG_WANDS[2])
    big_wand_board(s, CAVERNS, 110)
    bottom_bar(s, ["↶ Undo", "Codex"], "Click a mage to open their wand  ·  Tab cycles mages")
    wax_seal(s, "END", "TURN")
    finish(s, "01f_battle_big_wands_focus")


def screen_battle_big_compact():
    s = Svg(T)
    backdrop(s)
    title_plate(s, CAVERNS["title"], CAVERNS["turn"])
    mana_chalice(s, 10 - sum(m["spent"] for m in BIG_MAGES))
    for i, m in enumerate(BIG_MAGES):
        compact_row(s, 70 + i * 186, m, BIG_WANDS[i], i == 0)
    big_wand_board(s, CAVERNS, 130)
    bottom_bar(s, ["↶ Undo", "Codex"], "All wands at once, smaller runes")
    wax_seal(s, "END", "TURN")
    finish(s, "01g_battle_big_wands_compact")


SCREENS = [screen_battle, screen_battle_graveyard, screen_battle_won, screen_monster_details, screen_mage_details, screen_battle_big_focus, screen_battle_big_compact, screen_loot, screen_level_up, screen_path, screen_codex, screen_game_over, screen_victory]

if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for screen in SCREENS:
        screen()
