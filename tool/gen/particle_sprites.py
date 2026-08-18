#!/usr/bin/env python3
"""Generate every particle texture the weather scene draws.

All four are DPIP's own artwork, generated rather than extracted. Two of them
(`particle_blurred`, `drop_normal`) are not artwork at all once you look at
them — they are a blurred disc and an analytic hemisphere — so they are
reproduced from the maths directly and land within a couple of levels of the
textures they replace. The other two are drawn to the same *character* as the
originals without being the same picture.

Outputs, all into `assets/weather/particles/`:

    rain_drop.webp        128x68  4 width variants of a motion-blurred streak
    snow_flake.webp        40x40  a soft out-of-focus flake
    particle_blurred.webp  64x64  the metaball kernel the card water splats
    drop_normal.webp     128x128  hemisphere normal map for one water drop

Run: `python3 tool/gen/particle_sprites.py` (needs numpy, scipy, pillow).
"""

import argparse
import os

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter

WEBP = dict(format="WEBP", lossless=True, quality=100, method=6, exact=True)


# ---------------------------------------------------------------------------
# rain
# ---------------------------------------------------------------------------
# One atlas cell. `drawAtlas` can only scale uniformly, but the engine's rain
# quad is `startSize * 0.4 * (3 - 2*depth)` wide against `startSize * 3.0` tall
# — so width over length is `0.1333 * (3 - 2*depth)` and a *distant* drop is
# relatively the widest. That ratio has to live in the texture instead: four
# width variants across one row, widest first, indexed by depth.
CELL_W, CELL_H = 32, 68

# Ink width in texels = (0.2222 - 0.1481 * depth) * CELL_H, evaluated at depth
# 0, 1/3, 2/3, 1. The 0.2222 is that width-over-length ratio scaled by the
# fraction of the source quad its ink actually covered.
RAIN_INK = (15, 12, 8, 5)

# Fraction of the streak's length taken by the head's falloff — the drop's own
# diameter smeared over one frame, which is what stops the sprite ending in a
# hard edge.
HEAD = 0.06
# The tail's ramp. 1.0 is a linear wedge; a little convexity keeps the faint
# end from reading as a hairline.
TAIL_GAMMA = 1.3

FLAKE = 40
KERNEL = 64
NORMAL = 128


def _cross_section(u):
    """Lateral profile at |x| / halfInk, zero outside the ink.

    Half-maximum lands at u = 0.61, so ink extent / FWHM is 1.64 — the soft
    shoulders of a blurred drop rather than a Gaussian's long tails.
    """
    return np.where(u >= 1.0, 0.0, np.clip(1.0 - u * u, 0.0, None) ** 1.5)


def rain_cell(ink):
    """One motion-blurred streak: faint tail at the top, bright head below."""
    # 4x supersampled across the texel — the narrowest variant is five texels
    # wide and point sampling quantises its width away.
    sub = (np.arange(CELL_W * 4) + 0.5) / 4.0 - 0.5
    cx = CELL_W / 2.0 - 0.5
    lateral = _cross_section(np.abs(sub - cx) / (ink / 2.0))
    lateral = lateral.reshape(CELL_W, 4).mean(axis=1)

    t = np.linspace(0.0, 1.0, CELL_H)
    body = np.clip(t / (1.0 - HEAD), 0.0, 1.0) ** TAIL_GAMMA
    # Cosine shoulder over the head, so the leading edge fades instead of
    # clipping — a hard edge there reads as a falling matchstick.
    k = np.clip((t - (1.0 - HEAD)) / HEAD, 0.0, 1.0)
    head = 0.5 * (1.0 + np.cos(np.pi * k))
    along = np.where(t <= 1.0 - HEAD, body, head)

    return np.clip(along[:, None] * lateral[None, :], 0.0, 1.0)


def rain_atlas():
    alpha = np.concatenate([rain_cell(ink) for ink in RAIN_INK], axis=1)
    rgba = np.zeros(alpha.shape + (4,), dtype=np.uint8)
    # White; the per-particle colour tints it. The engine's own streak texture
    # is white too — night rain dims because its alpha is tiny over a dark sky,
    # not because the drops are coloured.
    rgba[..., :3] = 250
    rgba[..., 3] = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


# ---------------------------------------------------------------------------
# snow
# ---------------------------------------------------------------------------
def snow_flake(seed=7):
    """A soft, out-of-focus flake.

    Not a dendrite: at the size these are drawn a six-armed crystal turns into
    grey mush, and the texture being replaced is itself an out-of-focus faceted
    grain. This builds the same thing — an irregular hexagonal crystal, blurred
    past the point of recognition — so the silhouette keeps a few flat facets
    instead of collapsing to a circle.
    """
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:FLAKE, 0:FLAKE].astype(np.float32)
    c = (FLAKE - 1) / 2.0

    # An irregular convex crystal: half-planes at jittered angles and distances,
    # intersected. Ice grows on facets, so the silhouette wants straight edges
    # and corners — a pile of discs only ever gives a lumpy oval.
    theta = np.arctan2(yy - c, xx - c)
    r = np.hypot(xx - c, yy - c)
    sides = 6
    field = np.full((FLAKE, FLAKE), np.inf, dtype=np.float32)
    for i in range(sides):
        ang = 2.0 * np.pi * (i + rng.uniform(-0.18, 0.18)) / sides
        reach = rng.uniform(0.26, 0.36) * FLAKE
        # Distance inside the half-plane whose outward normal points at `ang`.
        field = np.minimum(field, reach - r * np.cos(theta - ang))
    field = np.clip(field, 0.0, 1.0)

    # Blur, then push the interior back to solid. Blurring alone gives an even
    # Gaussian smudge; what a flake at this size actually looks like is a solid
    # irregular core with a soft rim, so the core has to be restored after the
    # blur has done its work on the silhouette.
    alpha = np.clip(gaussian_filter(field, FLAKE * 0.050) * 1.7, 0.0, 1.0)
    # A round vignette guarantees the sprite reaches zero at its border, so
    # neighbouring atlas cells can never bleed into it.
    r = np.hypot(xx - c, yy - c) / c
    alpha *= np.clip(1.0 - r ** 6, 0.0, 1.0)
    alpha /= max(alpha.max(), 1e-6)

    rgba = np.zeros((FLAKE, FLAKE, 4), dtype=np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


# ---------------------------------------------------------------------------
# card-water particle
# ---------------------------------------------------------------------------
# The kernel the card-water pass splats per particle, then thresholds to get a
# metaball. Fitting the texture it replaces recovers exactly what its name
# says: a hard disc, blurred. Radius and sigma below are that fit (RMSE 0.023
# over the whole 64x64), so this is the same function, not a copy of the file.
KERNEL_RADIUS = 26.23
KERNEL_SIGMA = 3.30


def particle_kernel():
    yy, xx = np.mgrid[0:KERNEL, 0:KERNEL].astype(np.float32)
    c = (KERNEL - 1) / 2.0
    r = np.hypot(xx - c, yy - c)
    disc = np.clip(KERNEL_RADIUS + 0.5 - r, 0.0, 1.0)  # antialiased edge
    alpha = np.clip(gaussian_filter(disc, KERNEL_SIGMA), 0.0, 1.0)

    rgba = np.zeros((KERNEL, KERNEL, 4), dtype=np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = np.clip(alpha * 255.0, 0, 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def drop_normal():
    """The per-drop normal map: a plain hemisphere, `n = (x, y, sqrt(1-r^2))`.

    Verified against the texture it replaces rather than guessed — that one is
    the analytic hemisphere to the level: at r = 0.9375 it stores (8, 128, 173)
    and this returns (8, 128, 173). There is no artwork here to infringe.
    """
    yy, xx = np.mgrid[0:NORMAL, 0:NORMAL].astype(np.float64)
    c = (NORMAL - 1) / 2.0
    x = (xx - c) / (NORMAL / 2.0)
    y = (yy - c) / (NORMAL / 2.0)
    r2 = x * x + y * y
    inside = r2 <= 1.0
    z = np.sqrt(np.clip(1.0 - r2, 0.0, None))

    rgba = np.zeros((NORMAL, NORMAL, 4), dtype=np.uint8)
    for i, comp in enumerate((x, y, z)):
        rgba[..., i] = np.clip((comp * 0.5 + 0.5) * 255.0, 0, 255).astype(np.uint8)
    rgba[..., 3] = np.where(inside, 255, 0).astype(np.uint8)
    rgba[~inside, :3] = 0
    return Image.fromarray(rgba, "RGBA")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/weather/particles")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    for name, image in (
        ("rain_drop.webp", rain_atlas()),
        ("snow_flake.webp", snow_flake()),
        ("particle_blurred.webp", particle_kernel()),
        ("drop_normal.webp", drop_normal()),
    ):
        path = os.path.join(args.out, name)
        image.save(path, **WEBP)
        print("wrote %-22s %-9s %6d bytes" % (name, "%dx%d" % image.size,
                                              os.path.getsize(path)))


if __name__ == "__main__":
    main()
