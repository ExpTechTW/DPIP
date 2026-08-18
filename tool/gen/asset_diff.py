#!/usr/bin/env python3
"""Build side-by-side comparison sheets for the weather textures.

The weather scene's textures are being replaced with generated originals, and
"close enough" is a judgement only an eye can make. This lays each replacement
next to the texture it replaces — same scale, same channel breakdown, labelled
— so the pair can be looked at rather than argued about.

    old | new | difference

The difference panel is `|old - new|` amplified, on the channel that matters
for that texture. It is a *guide*, not a target: these are meant to be
different pictures. Read it as "did anything structural change", not as an
error metric. The header line under each pair carries the numbers that do
matter — size, and whatever statistic that texture is judged on.

Usage:
    python3 tool/gen/asset_diff.py --old <dir-of-originals> --new <dir-of-new>

Both directories are searched for the same filenames (extension-insensitive),
so a `.png` replaced by a `.webp` still pairs up. Sheets land in
`build/asset_diff/`.
"""

import argparse
import os
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

# Per-texture presentation. `panels` names how to break a texture into rows so
# the comparison shows what the shader actually consumes: a cloud sprite's
# coverage and normal map say far more than its flat RGBA does.
LAYOUT = {
    "clouds": dict(panels="cloud", scale=1.0),  # matched by folder name
    "particle_blurred": dict(panels="alpha", scale=4.0),
    "drop_normal": dict(panels="rgb", scale=2.0),
    "snow_flake": dict(panels="alpha", scale=6.0),
    "rain_drop": dict(panels="alpha", scale=3.0),
    "starmap": dict(panels="crop", scale=1.0),
    "sun_rays": dict(panels="rgb_norm", scale=0.7),
    "sun_profile": dict(panels="lut", scale=1.0),
    "annulus": dict(panels="lut", scale=1.0),
}

LABEL_H = 22
GAP = 10
BG = (24, 24, 28)


def _load(path):
    return np.array(Image.open(path).convert("RGBA")).astype(np.float32)


def _gray(a):
    return np.dstack([a] * 3)


def _panels(kind, rgba):
    """Break one texture into the rows worth comparing."""
    rgb, alpha = rgba[..., :3], rgba[..., 3]
    if kind == "cloud":
        h = rgba.shape[0] // 2
        return [("coverage", _gray(rgba[h:, :, 3])), ("normal", rgba[:h, :, :3])]
    if kind == "alpha":
        return [("alpha", _gray(alpha))]
    if kind == "rgb":
        return [("rgb", rgb)]
    if kind == "rgb_norm":
        # Stored deliberately dim; normalise so the shape is visible at all.
        return [("rgb (normalised)", rgb / max(rgb.max(), 1e-6) * 255.0)]
    if kind == "crop":
        # A star map is only meaningful at 1:1 — a downscale averages the
        # stars away and every field looks identical.
        h, w = rgba.shape[:2]
        y, x = h // 3, w // 3
        return [("1:1 crop", rgb[y:y + 300, x:x + 760])]
    if kind == "lut":
        # A 1-D curve: show it as a wide swatch and as a plot of the three
        # channels, because the swatch alone hides everything below ~1/20.
        row = rgb[0]
        swatch = np.repeat(row[None, :, :], 40, axis=0)
        plot = np.zeros((120, row.shape[0], 3), dtype=np.float32)
        for c, colour in enumerate(((255, 80, 80), (80, 255, 110), (110, 150, 255))):
            ys = (119 - row[:, c] / 255.0 * 118).astype(int)
            plot[ys, np.arange(row.shape[0])] = colour
        return [("swatch", swatch), ("curve", plot)]
    raise ValueError(kind)


def _to_img(arr, scale):
    img = Image.fromarray(np.clip(arr, 0, 255).astype(np.uint8), "RGB")
    if scale != 1.0:
        img = img.resize(
            (max(1, int(img.width * scale)), max(1, int(img.height * scale))),
            Image.NEAREST if scale > 1 else Image.LANCZOS,
        )
    return img


def _layout_for(name, path):
    """Pick the panel treatment by filename, falling back to the directory.

    The cloud sprites are named `00`..`11`, so they can only be recognised by
    the folder they live in — and getting that wrong shows the raw RGBA instead
    of the coverage and normal map the shader actually reads.
    """
    if name in LAYOUT:
        return LAYOUT[name]
    parent = Path(path).parent.name
    return LAYOUT.get(parent, dict(panels="rgb", scale=1.0))


def sheet(name, old_path, new_path, out_dir):
    kind = _layout_for(name, old_path)
    old, new = _load(old_path), _load(new_path)
    if old.shape != new.shape:
        new_img = Image.open(new_path).convert("RGBA").resize(
            (old.shape[1], old.shape[0]), Image.LANCZOS
        )
        new_cmp = np.array(new_img).astype(np.float32)
    else:
        new_cmp = new

    rows = []
    for (label, a), (_, b) in zip(_panels(kind["panels"], old),
                                  _panels(kind["panels"], new_cmp)):
        diff = np.clip(np.abs(a - b) * 3.0, 0, 255)
        rows.append((label, [a, b, diff]))

    scale = kind["scale"]
    tiles = [[_to_img(p, scale) for p in panels] for _, panels in rows]
    col_w = max(t.width for row in tiles for t in row)
    total_w = col_w * 3 + GAP * 2
    total_h = sum(row[0].height + LABEL_H for row in tiles) + GAP * (len(tiles) - 1)

    canvas = Image.new("RGB", (total_w, total_h + LABEL_H), BG)
    draw = ImageDraw.Draw(canvas)
    for i, header in enumerate(("original (the reference)", "generated", "|difference| x3")):
        draw.text((i * (col_w + GAP) + 4, 5), header, fill=(210, 210, 215))

    y = LABEL_H
    for (label, _), row in zip(rows, tiles):
        for i, tile in enumerate(row):
            canvas.paste(tile, (i * (col_w + GAP), y))
        draw.text((4, y + row[0].height + 4), label, fill=(150, 150, 158))
        y += row[0].height + LABEL_H + GAP

    out = Path(out_dir) / f"{name}.png"
    canvas.save(out)
    return out, os.path.getsize(old_path), os.path.getsize(new_path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--old", required=True, help="directory tree of the originals")
    ap.add_argument("--new", required=True, help="directory tree of the replacements")
    ap.add_argument("--out", default="build/asset_diff")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    olds = {p.stem: p for p in Path(args.old).rglob("*") if p.suffix in {".png", ".webp"}}
    news = {p.stem: p for p in Path(args.new).rglob("*") if p.suffix in {".png", ".webp"}}

    total_old = total_new = 0
    for stem in sorted(olds.keys() & news.keys()):
        out, ob, nb = sheet(stem, olds[stem], news[stem], args.out)
        total_old += ob
        total_new += nb
        print("%-22s %8d -> %8d bytes (%+.0f%%)  %s"
              % (stem, ob, nb, (nb - ob) / ob * 100, out))

    missing = sorted(olds.keys() - news.keys())
    if missing:
        print("no replacement yet:", ", ".join(missing))
    if total_old:
        print("total %d -> %d bytes (%+.0f%%)"
              % (total_old, total_new, (total_new - total_old) / total_old * 100))


if __name__ == "__main__":
    main()
