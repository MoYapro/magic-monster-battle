"""Colour-group proposal: every spell takes its family's hue so tiny wand dots stay readable.

Usage: python gen_color_groups.py [out_dir]
"""
import colorsys
import subprocess
import sys
from pathlib import Path

from gen_all_spells import ALCHEMY_GD, load_spells, parse_recipes, rune_letters
from runes import DEFS, alchemy_body, spell_body

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).parent)
BG, EDGE, TEXT, DIM, LINE = "#1b120d", "#a07a48", "#f3e3c4", "#b39470", "#5a4632"

# family: (hue colour, meaning, spell ids incl. alchemy results by name)
FAMILIES = {
    "Fire": ("#ff5a1f", "burns, explodes", ["fire_catalyst", "ember", "detonate", "scorch_mark", "Flame Burst"]),
    "Frost & Water": ("#3fa9ff", "freezes, soaks", ["frost", "Ice Cube", "Steam", "Soap"]),
    "Poison": ("#5fd23a", "damage over time", ["venom", "toxin_edge"]),
    "Death": ("#d8cfae", "bone, curses", ["bone", "Curse"]),
    "Storm": ("#f2e24a", "lightning, chains", ["lightning", "conductor"]),
    "Force & Ward": ("#9d7bff", "pushes, protects", ["force_push", "shield"]),
    "Arcane": ("#ff5ccf", "bends other spells", ["amplify", "harmony", "reactive", "sunder", "distillation",
                                                  "corrupted"]),
    "Shape": ("#7a7266", "where it hits (no element: dim)", ["bolt", "single", "line", "pierce", "bomb", "splash"]),
}


# ---------------------------------------------------------------- colours (pure)
def shade(hex_color, i, n, spread=0.16):
    """Same hue, lightness stepped across a family so members differ slightly up close."""
    r, g, b = (int(hex_color[k:k + 2], 16) / 255 for k in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = min(0.85, max(0.25, l + (spread * (i / (n - 1) - 0.5) if n > 1 else 0)))
    return "#" + "".join(f"{round(c * 255):02x}" for c in colorsys.hls_to_rgb(h, l, s))


def family_colors():
    """{member: colour} for every member of every family."""
    out = {}
    for hue, _, members in FAMILIES.values():
        for i, m in enumerate(members):
            out[m] = shade(hue, i, len(members))
    return out


# ---------------------------------------------------------------- svg
def text(x, y, s, size, fill, anchor="start", weight="normal"):
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="C059" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{s.replace("&", "&amp;")}</text>')


def dot(cx, cy, col, loaded=False, r=7):
    """Wand-strip node as in the battle panel: coloured ring, filled centre when loaded."""
    inner = f'<circle cx="{cx}" cy="{cy}" r="{r * 0.45:.1f}" fill="{col}"/>' if loaded else ""
    return f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="#2a1d14" stroke="{col}" stroke-width="1.6"/>{inner}'


def family_row(y, name, hue, meaning, members, spells, letters, recipes, colors):
    body = text(30, y - 8, name, 17, hue, weight="bold") + text(30, y + 12, meaning, 12, DIM)
    for i, m in enumerate(members):
        x, col = 260 + i * 150, colors[m]
        if m in spells:
            label, icon = spells[m][0], spell_body(letters[m], col, x, y, 34)
        else:
            cat, a, b = recipes[m]
            label, icon = m + " *", alchemy_body(letters[cat], letters[a], letters[b], col, x, y, 34)
        body += icon + text(x, y + 50, label, 12, TEXT, "middle") + dot(x + 50, y + 22, col, True)
    return body


def wand_mock(x0, y0, wands, colors, scale=1.0):
    """A wand strip like the battle panel: rows of nodes joined by lines."""
    body = f'<g transform="translate({x0},{y0}) scale({scale})">'
    for row, wand in enumerate(wands):
        y = row * 20
        pts = [(i * 36, y) for i in range(len(wand))]
        body += "".join(f'<line x1="{a[0]}" y1="{y}" x2="{b[0]}" y2="{y}" stroke="{LINE}" stroke-width="1.4"/>'
                        for a, b in zip(pts, pts[1:]))
        body += "".join(dot(px, py, colors[m], loaded) for (px, py), (m, loaded) in zip(pts, wand))
    return body + "</g>"


WANDS = [  # (member, loaded) per node, like Eron's panel
    [("fire_catalyst", True), ("ember", True), ("amplify", False), ("bolt", False)],
    [("frost", False), ("venom", False), ("toxin_edge", False), ("line", False)],
    [("lightning", True), ("conductor", False), ("splash", False), ("single", False)],
]


def sheet():
    spells = load_spells()
    names = rune_letters([n for n, _ in spells.values()])
    letters = {sid: names[n] for sid, (n, _) in spells.items()}
    recipes = {name: r for name, _, r in parse_recipes(ALCHEMY_GD.read_text())}
    colors = family_colors()
    body = text(30, 45, "Spell colour groups - the hue tells the family", 26, TEXT, weight="bold")
    body += text(30, 70, "Members of a family share one hue (slightly lighter or darker each); "
                         "* = alchemy result; the small dot is the wand-strip size", 13, DIM)
    y = 135
    for name, (hue, meaning, members) in FAMILIES.items():
        body += family_row(y, name, hue, meaning, members, spells, letters, recipes, colors)
        y += 120
    body += text(30, y, "Wand strip at game size (1:1) and zoomed (3x)", 17, TEXT, weight="bold")
    body += wand_mock(60, y + 30, WANDS, colors) + wand_mock(260, y + 30, WANDS, colors, 3)
    return 30 + 260 + 150 * 6, y + 230, body


def render(stem):
    w, h, body = sheet()
    svg = OUT / f"{stem}.svg"
    svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'
                   f'{DEFS}<rect width="{w}" height="{h}" fill="{BG}"/>{body}</svg>')
    subprocess.run(["rsvg-convert", str(svg), "-o", str(OUT / f"{stem}.png")], check=True)


if __name__ == "__main__":
    render("04_color_groups")
