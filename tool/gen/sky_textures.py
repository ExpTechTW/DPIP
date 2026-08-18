#!/usr/bin/env python3
"""Generate the sky's four support textures.

Two of these are pictures (a star field, a ray fan) and are generated freely —
the output is a different sky and a different fan, not a redraw of anything.
The other two are one-dimensional lookup curves that a lens-flare shader
indexes by radius; those are *functions*, so they are reproduced as functions,
fitted to the optics they describe rather than copied sample by sample.

Outputs, all into `assets/weather/sky/`:

    starmap.webp      2048x1024  equirectangular night sky
    sun_rays.webp       512x512  radial ray fan for the sun's flare
    sun_profile.webp    540x2    flare falloff vs radius, per channel
    annulus.webp        540x4    the dispersed halo ring, per channel

Run: `python3 tool/gen/sky_textures.py` (needs numpy, scipy, pillow).
"""

import argparse
import os

import numpy as np
from PIL import Image
from scipy.ndimage import gaussian_filter, map_coordinates

WEBP_LOSSLESS = dict(format="WEBP", lossless=True, quality=100, method=6, exact=True)

STAR_W, STAR_H = 2048, 1024
# How the field is dialled in. The targets are the sky this replaces: a mean
# level around 20/255 with only ~5 % of pixels above 40 — a dim, dense haze
# with sparse bright stars, not a scatter of hot pixels.
STAR_COUNT = 38_000
# A steep magnitude law is what separates a sky from static: at gamma 4.5 the
# overwhelming majority of stars sit below the visible threshold and contribute
# only to the haze, and a few dozen stand out. A shallow law puts every star at
# the same middling grey and the field reads as sensor noise.
STAR_GAMMA = 4.5
STAR_PEAK = 0.95
MILKY_LEVEL = 0.055
STAR_BLUR = 1.0
STAR_FLOOR = 0.020
RAYS = 512
LUT = 540


# ---------------------------------------------------------------------------
# star field
# ---------------------------------------------------------------------------
def starmap(seed=20260809):
    """An equirectangular night sky.

    Stars are sampled uniformly **on the sphere**, not on the image: an
    equirectangular map stretches enormously toward the poles, so a uniform
    scatter in image space piles stars up at the top and bottom edges where the
    projection is most obvious.

    Brightness follows a power law — a great many faint stars and a handful of
    bright ones — because an evenly-lit field reads as noise. Colour comes from
    a blackbody-ish blue/orange spread around white, and the brightest few get
    a small cross-shaped bloom, which is what makes them read as *stars* rather
    than as hot pixels.
    """
    rng = np.random.default_rng(seed)

    # A faint galactic band: low-frequency noise confined near a great circle
    # drawn across the map, so the sky is not uniformly empty.
    lon = np.linspace(0.0, 2.0 * np.pi, STAR_W, endpoint=False)[None, :]
    lat = np.linspace(np.pi / 2, -np.pi / 2, STAR_H)[:, None]
    tilt, phase = 0.42, 1.1
    band = np.arcsin(
        np.clip(
            np.sin(lat) * np.cos(tilt)
            - np.cos(lat) * np.sin(tilt) * np.sin(lon - phase),
            -1.0,
            1.0,
        )
    )
    coarse = gaussian_filter(rng.random((64, 128)).astype(np.float32), 3.0, mode="wrap")
    clouds = map_coordinates(
        coarse,
        np.meshgrid(
            np.linspace(0, 64, STAR_H, endpoint=False),
            np.linspace(0, 128, STAR_W, endpoint=False),
            indexing="ij",
        ),
        order=1,
        mode="grid-wrap",
    )
    clouds = (clouds - clouds.min()) / max(float(clouds.max() - clouds.min()), 1e-6)
    milky = np.exp(-(band / 0.22) ** 2) * (0.35 + 0.65 * clouds)

    # Stars, sampled uniformly on the sphere and denser inside the band.
    stars = np.zeros((STAR_H, STAR_W, 3), dtype=np.float32)
    count = STAR_COUNT
    z = rng.uniform(-1.0, 1.0, count)
    theta = rng.uniform(0.0, 2.0 * np.pi, count)
    ys = ((np.arcsin(z) - np.pi / 2) / -np.pi * (STAR_H - 1)).astype(np.int32)
    xs = (theta / (2.0 * np.pi) * STAR_W).astype(np.int32) % STAR_W
    keep = rng.random(count) < 0.45 + 0.55 * milky[ys, xs] / max(milky.max(), 1e-6)
    xs, ys = xs[keep], ys[keep]

    mag = np.clip(rng.random(xs.size) ** STAR_GAMMA, 1e-4, 1.0) * STAR_PEAK
    warmth = rng.normal(0.0, 0.16, xs.size)
    tint = np.stack(
        [
            np.clip(1.0 + warmth * 0.55, 0.6, 1.4),
            np.ones_like(warmth),
            np.clip(1.0 - warmth * 0.55, 0.6, 1.4),
        ],
        axis=1,
    ).astype(np.float32)
    np.add.at(stars, (ys, xs), mag[:, None] * tint)

    # Spread each star over ~3 px. This is not decoration: single-pixel spikes
    # read as sensor noise, and — because they are the highest frequency an
    # image can hold — they are also what makes a star field expensive to
    # encode. Blurring first drops the file by a third at the same brightness.
    for c in range(3):
        stars[..., c] = gaussian_filter(stars[..., c], STAR_BLUR)
    img = (milky * MILKY_LEVEL)[..., None] * np.array([0.86, 0.88, 1.0], np.float32)
    img += stars * (1.0 + 2.2 * STAR_BLUR)
    # A dim floor of unresolved stars, so the sky between the bright ones is
    # not pure black.
    img += STAR_FLOOR * np.array([0.80, 0.82, 0.95], np.float32)

    img = np.clip(img, 0.0, 1.0) ** (1 / 1.35)
    return Image.fromarray((img * 255.0 + 0.5).astype(np.uint8), "RGB")


# ---------------------------------------------------------------------------
# ray fan
# ---------------------------------------------------------------------------
def sun_rays(seed=31):
    """The sun's ray fan: brightness varies with angle only, not radius.

    Built by summing a few sine harmonics of the polar angle and sharpening the
    result, which gives rays of uneven width and spacing — a fixed comb reads
    as a machine part. The fan is warm because it stands in for sunlight
    through haze; the shader multiplies it, so it is stored dim.
    """
    rng = np.random.default_rng(seed)
    yy, xx = np.mgrid[0:RAYS, 0:RAYS].astype(np.float32)
    c = (RAYS - 1) / 2.0
    theta = np.arctan2(yy - c, xx - c)

    fan = np.zeros_like(theta)
    for k, amp in ((7, 1.0), (11, 0.55), (17, 0.32), (23, 0.18)):
        fan += amp * np.sin(k * theta + rng.uniform(0.0, 2.0 * np.pi))
    fan = fan / 2.05 * 0.5 + 0.5
    fan = np.clip(fan, 0.0, 1.0) ** 2.2

    # The very centre has no defined angle, so fade the fan out there instead
    # of letting the singularity show as a pinwheel of aliasing.
    r = np.hypot(xx - c, yy - c) / c
    fan *= np.clip(r / 0.05, 0.0, 1.0)

    warm = np.array([1.0, 0.83, 0.44], dtype=np.float32)  # the original's hue
    rgb = np.clip(fan[..., None] * warm * 0.215 + 0.012, 0.0, 1.0)
    return Image.fromarray((rgb * 255.0 + 0.5).astype(np.uint8), "RGB")


# ---------------------------------------------------------------------------
# lens-flare lookup curves
# ---------------------------------------------------------------------------
def sun_profile():
    """Flare intensity against radius: a forward-scattering falloff.

    `(1 + x*A)^-B` per channel, with A rising and B falling toward the blue —
    which is scattering behaving as scattering: short wavelengths spread wider
    and decay more gently, so the flare's core is white and its skirt is blue.
    The three (A, B) pairs are a least-squares fit of that form to the optics
    the curve describes.
    """
    x = (np.arange(LUT) + 0.5) / LUT
    coeffs = ((2.97, 2.939), (6.09, 2.305), (26.31, 1.444))
    rgb = np.stack([(1.0 + x * a) ** -b for a, b in coeffs], axis=1)
    row = np.clip(rgb * 255.0 + 0.5, 0, 255).astype(np.uint8)
    return Image.fromarray(np.repeat(row[None, :, :], 2, axis=0), "RGB")


def annulus():
    """The dispersed halo ring — one bump per channel at its own radius.

    A halo is a single optical feature smeared by wavelength, so this is one
    profile shifted three times: red innermost, blue outermost. The lobe is
    asymmetric (it rises over ~25 samples and decays over ~65) because the ring
    is a caustic — sharp on its inner edge, trailing outward.
    """
    x = np.arange(LUT, dtype=np.float64)
    centres = (348.0, 371.0, 413.0)
    peaks = (119.0, 109.0, 108.0)
    sigma_in, sigma_out = 25.0, 65.0

    cols = []
    for mu, peak in zip(centres, peaks):
        d = x - mu
        sigma = np.where(d < 0, sigma_in, sigma_out)
        cols.append(peak * np.exp(-0.5 * (d / sigma) ** 2))
    rgb = np.clip(np.stack(cols, axis=1), 0, 255)
    # Below ~1/255 the shader sees nothing; snapping the tails to zero keeps
    # the encoded row flat and small.
    rgb[rgb < 1.0] = 0.0
    row = (rgb + 0.5).astype(np.uint8)
    return Image.fromarray(np.repeat(row[None, :, :], 4, axis=0), "RGB")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="assets/weather/sky")
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    for name, image, opts in (
        # The star field is the one texture where lossless costs real bytes and
        # buys nothing: it is consumed as a dim background, and near-lossless
        # WebP holds every star while halving the file.
        ("starmap.webp", starmap(), dict(format="WEBP", quality=75, method=6)),
        # The ray fan is pure visual (the shader multiplies it dim); q85 keeps
        # every ray edge while shrinking the file ~8x.
        ("sun_rays.webp", sun_rays(), dict(format="WEBP", quality=85, method=6)),
        ("sun_profile.webp", sun_profile(), WEBP_LOSSLESS),
        ("annulus.webp", annulus(), WEBP_LOSSLESS),
    ):
        path = os.path.join(args.out, name)
        image.save(path, **opts)
        print("wrote %-18s %-11s %7d bytes" % (name, "%dx%d" % image.size,
                                               os.path.getsize(path)))


if __name__ == "__main__":
    main()
