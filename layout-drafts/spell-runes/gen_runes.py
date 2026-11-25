"""Spell-rune overview sheets, built from the letter-driven generator in runes.py.

Usage: python gen_runes.py [out_dir]   (renders SVG + PNG via rsvg-convert)
"""
import math
import subprocess
import sys
from pathlib import Path

from runes import DEFS, RUNES, alchemy_body, fit, path, rune_segments, spell_body

OUT = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
BG, EDGE, TEXT, DIM, HOT = "#1b120d", "#a07a48", "#f3e3c4", "#b39470", "#f0a030"

SPELLS = [  # name, letters, colour (from gen_drafts.py)
    ("Fireball", "F", "#e0602a"), ("Ice Shard", "I", "#6ab8f0"), ("Vine", "V", "#5fae4a"),
    ("Toxin", "T", "#9a4fc0"), ("Water", "W", "#3f7fd0"), ("Amp", "A", "#d8b040"),
    ("Lightning Bolt", "L", "#e8d84a"), ("Splash", "S", "#d89a30"),
]
BASIC = {  # spell_id: (display name, letters) - ingredients of alchemy recipes
    "fire_catalyst": ("Fire", "FR"), "ember": ("Ember", "EMB"), "bone": ("Bone", "BN"),
    "venom": ("Venom", "VNM"), "frost": ("Frost", "FRS"), "force_push": ("Force Push", "FP"),
}
ALCHEMY = [  # result, colour, (catalyst, reactant, reactant) - from alchemy_table.gd
    ("Steam", "#d9d9d9", ("fire_catalyst", "fire_catalyst", "frost")),
    ("Flame Burst", "#ff4d00", ("fire_catalyst", "ember", "ember")),
    ("Curse", "#8033b3", ("fire_catalyst", "bone", "venom")),
    ("Ice Cube", "#99d9ff", ("force_push", "frost", "frost")),
    ("Soap", "#f2f2ff", ("force_push", "bone", "frost")),
]
TILE, ROW_H, LEFT = 132, 220, 300


def text(x, y, s, size, fill, anchor="middle", weight="normal"):
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="C059" font-size="{size}" fill="{fill}" '
            f'text-anchor="{anchor}" font-weight="{weight}">{s}</text>')


def row_label(y, title, sub):
    return (text(30, y, title, 16, TEXT, "start", "bold") + text(30, y + 20, sub, 12, DIM, "start")
            + text(30, y + 105, "game size (r = 19)", 12, DIM, "start"))


def col_x(i):
    return LEFT + i * TILE + TILE / 2


def single_row(y):
    body = row_label(y, "Single letter", "spell_icon(letter, colour)")
    for i, (name, letters, col) in enumerate(SPELLS):
        body += text(col_x(i), y - 72, name, 13, DIM) + text(col_x(i), y - 58, letters, 12, EDGE)
        body += spell_body(letters, col, col_x(i), y, 52) + spell_body(letters, col, col_x(i), y + 100, 19)
    return body


def alchemy_row(y):
    body = row_label(y, "Alchemy results", "alchemy_icon(catalyst, a, b, colour)")
    for i, (name, col, recipe) in enumerate(ALCHEMY):
        letters = [BASIC[s][1] for s in recipe]
        body += text(col_x(i), y - 72, name, 13, DIM)
        body += text(col_x(i), y - 58, " + ".join(BASIC[s][0] for s in recipe[1:]) + f" / {BASIC[recipe[0]][0]}", 9, EDGE)
        body += alchemy_body(*letters, col, col_x(i), y, 52) + alchemy_body(*letters, col, col_x(i), y + 100, 19)
    return body


def overview_sheet():
    w, h = LEFT + TILE * len(SPELLS) + 30, 110 + ROW_H * 2 + 30
    body = text(30, 45, "Spell runes", 26, TEXT, "start", "bold")
    return w, h, body + single_row(185) + alchemy_row(185 + ROW_H)


def letters_sheet():
    keys, cols, cell = list(RUNES), 13, 92
    w, h = cols * cell + 60, 110 + cell * math.ceil(len(keys) / cols) * 1.25
    body = text(30, 45, "Traced rune alphabet (A-Z, digits 0-9 assumed)", 20, TEXT, "start", "bold")
    for i, ch in enumerate(keys):
        x, y = 30 + (i % cols) * cell, 80 + (i // cols) * cell * 1.25
        body += path(fit(RUNES[ch], x + cell / 2, y + cell / 2, cell * 0.6), TEXT, 3)
        body += text(x + cell / 2, y + cell + 8, ch, 14, DIM)
    return w, h, body


def how_to_read_sheet(letters="FRS"):
    body = text(30, 45, f"Ingredient rune: Frost -> {'-'.join(letters)}", 18, TEXT, "start", "bold")
    body += text(30, 70, "letters overlaid as drawn, stems slid onto one line, close strokes merge", 13, DIM, "start")
    for i, ch in enumerate(letters):
        body += path(fit(RUNES[ch], 80 + i * 130, 160, 80), TEXT, 3) + text(80 + i * 130, 225, ch, 15, DIM)
    cx = 80 + len(letters) * 130
    body += text(cx - 40, 170, "=", 30, DIM)
    return 1150, 280, body + path(fit([list(s) for s in rune_segments(letters)], cx + 80, 160, 130), HOT, 4)


def render(stem, sheet):
    w, h, body = sheet()
    svg = OUT / f"{stem}.svg"
    svg.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="{int(w)}" height="{int(h)}" '
                   f'viewBox="0 0 {int(w)} {int(h)}">{DEFS}<rect width="{int(w)}" height="{int(h)}" '
                   f'fill="{BG}"/>{body}</svg>')
    subprocess.run(["rsvg-convert", str(svg), "-o", str(OUT / f"{stem}.png")], check=True)


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    render("00_overview", overview_sheet)
    render("01_alphabet_trace", letters_sheet)
    render("02_how_to_read", how_to_read_sheet)
