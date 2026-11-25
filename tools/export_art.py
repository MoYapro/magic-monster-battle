"""Export the art drafts from layout-drafts/ into Godot assets.

Grounds: every tile PNG is copied to assets/grounds/.
Monsters: every <id>.svg is split into one PNG per body part (named <g> with data-pivot) plus the
paper-rim layer of that part, and described in rig.json; full.png is the whole monster.

Usage: python3 tools/export_art.py [monster ids...]   (needs rsvg-convert and Pillow)
"""
import copy
import json
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DRAFTS = ROOT / "layout-drafts"
OUT = ROOT / "assets"
SCALE = 0.5            # 512 px per grid cell in the drafts -> 256 px per cell (~3x the 80 px game cell)
CELL_PX = 512
SVG_NS = "http://www.w3.org/2000/svg"
NS = "{%s}" % SVG_NS
LAYER_ATTR = "data-export-layer"
ET.register_namespace("", SVG_NS)
ET.register_namespace("xlink", "http://www.w3.org/1999/xlink")


# ---------------------------------------------------------------- grounds
def export_grounds():
    dst = OUT / "grounds"
    dst.mkdir(parents=True, exist_ok=True)
    for png in sorted((DRAFTS / "grounds").glob("*.png")):
        if not png.name.startswith("00_"):
            shutil.copyfile(png, dst / png.name)


# ---------------------------------------------------------------- monster rig (pure on the XML tree)
def tag(el):
    return el.tag.replace(NS, "")


def pivot_of(el):
    x, y = el.get("data-pivot").split(",")
    return [float(x), float(y)]


def assign_layers(root):
    """Tag every drawable with its layer name; return (joints, layers) in document order.

    A part's own drawables form one layer per run between its named children, so a head drawn
    between its far and near ear keeps that order. Rim drawables go to rim_<part>, below all parts.
    """
    joints, layers, run_names = {}, [], {}

    def run_name(part, run):
        """First layer of a part keeps the part name, later runs get __1, __2, ..."""
        if (part, run) not in run_names:
            n = sum(1 for p, _ in run_names if p == part)
            run_names[(part, run)] = part if n == 0 else f"{part}__{n}"
        return run_names[(part, run)]

    def add_joint(name, pivot, parent):
        joints.setdefault(name, {"name": name, "pivot": pivot, "parent": parent})

    def mark(el, layer, joint, rim):
        el.set(LAYER_ATTR, layer)
        if layer not in [l["name"] for l in layers]:
            layers.append({"name": layer, "joint": joint, "rim": rim})

    def walk(el, stack, runs, rim):
        for child in el:
            if tag(child) == "defs":
                continue
            if tag(child) == "g" and child.get("id") == "paper_rim":
                walk(child, stack, runs, True)
            elif tag(child) == "g" and child.get("data-pivot"):
                name = child.get("id")
                if rim:
                    part = name.removeprefix("rim_")
                    add_joint(part, [p * SCALE for p in pivot_of(child)], "")
                    walk_rim(child, part)
                    continue
                add_joint(name, [p * SCALE for p in pivot_of(child)], stack[-1] if stack else "")
                joints[name]["parent"] = stack[-1] if stack else ""
                walk(child, stack + [name], runs, False)
                if stack:
                    runs[stack[-1]] = runs.get(stack[-1], 0) + 1
            elif tag(child) == "g":
                walk(child, stack, runs, rim)
            else:
                part = stack[-1] if stack else "base"
                if not stack:
                    add_joint("base", [0.0, 0.0], "")
                mark(child, run_name(part, runs.get(part, 0)), part, False)

    def walk_rim(el, part):
        for child in el.iter():
            if child is not el and tag(child) != "g":
                mark(child, f"rim_{part}", part, True)

    walk(root, [], {}, False)
    return joints, layers


def prune(el, layer):
    """Remove every subtree that holds no drawable of this layer (defs stay)."""
    keep = False
    for child in list(el):
        if tag(child) == "defs":
            continue
        if child.get(LAYER_ATTR) == layer or (tag(child) == "g" and prune(child, layer)):
            keep = True
        else:
            el.remove(child)
    return keep


def ordered_joints(joints):
    """Parents before children."""
    out, seen = [], set()

    def visit(name):
        if name in seen:
            return
        parent = joints[name]["parent"]
        if parent:
            visit(parent)
        seen.add(name)
        out.append(joints[name])

    for name in joints:
        visit(name)
    return out


# ---------------------------------------------------------------- monster rendering
def render(svg_root, png):
    with tempfile.NamedTemporaryFile("wb", suffix=".svg", delete=False) as f:
        ET.ElementTree(svg_root).write(f)
    subprocess.run(["rsvg-convert", "-z", str(SCALE), f.name, "-o", str(png)], check=True)
    Path(f.name).unlink()


def trim(png):
    """Crop to visible pixels; return the top-left offset, or None when the layer is empty."""
    img = Image.open(png)
    box = img.getchannel("A").getbbox()
    if box is None:
        png.unlink()
        return None
    img.crop(box).save(png)
    return [box[0], box[1]]


def export_monster(svg_path):
    mid = svg_path.stem
    dst = OUT / "monsters" / mid
    if dst.exists():
        shutil.rmtree(dst)
    dst.mkdir(parents=True)
    root = ET.parse(svg_path).getroot()
    w, h = float(root.get("width")), float(root.get("height"))
    render(copy.deepcopy(root), dst / "full.png")
    joints, layers = assign_layers(root)
    rim_z, part_z, out_layers = 0, 1000, []
    for layer in layers:
        png = dst / f"{layer['name']}.png"
        render(_stripped(root, layer["name"]), png)
        pos = trim(png)
        if pos is None:
            continue
        z = rim_z if layer["rim"] else part_z
        rim_z, part_z = (rim_z + 1, part_z) if layer["rim"] else (rim_z, part_z + 1)
        out_layers.append({"file": png.name, "joint": layer["joint"], "z": z, "pos": pos})
    rig = {"id": mid, "scale": SCALE, "canvas": [w * SCALE, h * SCALE],
           "cells": [round(w / CELL_PX), round(h / CELL_PX)],
           "joints": ordered_joints(joints), "layers": out_layers}
    (dst / "rig.json").write_text(json.dumps(rig, indent=1))
    return len(out_layers)


def _stripped(root, layer):
    tree = copy.deepcopy(root)
    prune(tree, layer)
    return tree


def main(ids):
    export_grounds()
    svgs = sorted((DRAFTS / "monsters").glob("*.svg"))
    for svg in svgs:
        if svg.stem.startswith("00_") or (ids and svg.stem not in ids):
            continue
        print(f"{svg.stem}: {export_monster(svg)} layers")


if __name__ == "__main__":
    main(sys.argv[1:])
