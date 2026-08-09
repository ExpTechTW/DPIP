#!/usr/bin/env python3
"""Generate DPIP cloud sprites — original artwork, volumetric raymarch.

WHY THIS FILE EXISTS
--------------------
The sprites this replaces were decoded out of the reference engine and are the reference vendor's
copyrighted artwork. Everything here is synthesised from a PRNG: no reference
pixel is read, traced, re-encoded or fitted to at any point. The only thing
borrowed is the *texture contract* — the byte layout `shaders/cloud/clouds.frag`
reads — which is an interface, not artwork.

TEXTURE CONTRACT (see `shaders/cloud/clouds.frag`)
--------------------------------------------------
512 x 576 RGBA, two stacked 512 x 288 halves.

    top half     RGB = normal * 0.5 + 0.5, A = 255
                 The shader does `sampleSprite(normalUv).rgb * 2 - 1` and then
                 `mapN.z = max(mapN.z, 0.08); normalize(mapN)`. It stores an
                 UN-normalised normal, so only the xy:z ratio carries tilt —
                 and any pixel whose z lands negative gets its lighting
                 flattened by that clamp, so z must stay mostly positive.
                 A = 255 makes Flutter's decode-time premultiply a no-op, which
                 is the only reason the normal survives intact.

    bottom half  R = depth from the silhouette edge.  Read by `calcDepthAlpha`
                 (the deck reveal sweeps a band through it front-to-back) and
                 by `edge = smoothstep(iEndEdge, iStartEdge, texDepth)`, which
                 erodes low-depth pixels. A rim crushed to zero leaves both with
                 nothing to work with, so R must stay non-zero out to the
                 feathered edge and rise only ~2x into the core.
                 G = backness, "how far through to the far side". The shader
                 does `alpha *= smoothstep(1.0, 0.5, texBack)` and derives
                 `backMulti` (the silver lining) from it, so backness must be
                 HIGH WHERE THE CLOUD IS THIN. Getting this sign wrong fades the
                 core and puts the rim light in the middle of the cloud.
                 B = inner-glow mask, gated by `smoothstep(0.05, 1.0, texInner)`
                 — a ceiling below ~0.3 means lightning never registers.
                 A = coverage / opacity. Flutter premultiplies on decode and the
                 shader divides RGB back out by `max(coverage, 0.10)`, which is
                 why coverage lives in A and not, as the reference had it, in B.

Files on disk are written UNpremultiplied; the decode does the multiply.

HOW THE ART IS MADE
-------------------
An orthographic volumetric raymarch (the camera looks down -z, so the march is a
cumulative sum through a density volume), with the normal map built on a second,
independent path. Five things distinguish it from a naive march, each fixing a
defect that shows up as a number in the profile AND as something the eye can
name on a contact sheet:

 1. ONE UPDRAUGHT, NOT A ROW OF BLOBS. The crown's position is drawn FIRST and
    the body is built around it: a short chain of large, heavily overlapping
    ellipsoids whose radii and centre height both peak under the crown, standing
    on a soft-min half-space (the condensation level, hence the flat base). So
    the mass already rolls and the crown continues its arc. Build the body first
    and drop a crown wherever lobe placement lands, and the two disagree — every
    sprite comes out as a block with a shelf beside it. The earlier arrangement
    — one wide thin slab plus many small lobes — reads instead as a table with
    popcorn on it, and says so in the numbers: lobe count 4 against a reference
    median of 2, bbox fill 0.45 against 0.58.

 2. A SOFT TRANSFER WITH A VERTICAL GRADIENT. Density is `logistic(F / s)`, so
    the field decays EXPONENTIALLY outside the surface with a tunable length —
    a real 20-px coverage ramp and an exponential wisp tail instead of a binary
    silhouette. `s` grows toward the base, because a cumulus crown is condensing
    hard and its edge is a few pixels wide while its base is evaporating and
    trails off over tens; one tail length for both averages them into a
    uniformly furry outline.

 3. THE RIM IS TORN BY A SEPARATE FIELD, AND TORN ANISOTROPICALLY. A thresholded
    mid-frequency mask multiplies density in the exponential tail (`tear_in`
    sets how far inward it reaches: ~0 on a cumulus, ~1 on a veil, which IS torn
    all the way through). The mask's noise is stretched 3-5x along the wind, so
    a veil comes out as torn horizontal filaments rather than isotropic confetti
    — the defect that made the previous veils read as a spray of dots.

 4. THE TWO SCALES OF THE NORMAL ARE BUILT SEPARATELY. This is the whole point
    of the file. Coverage is taken from the FULL-detail field, so the silhouette
    keeps every erosion octave and stays cauliflower. The normal is taken from a
    SMOOTHED thickness field — a dome per lobe, which is what makes big saturated
    lobes — and fine relief is added back as a SEPARATE term. Taking one gradient
    of the raw surface instead gives the two failure modes the judges named:
    either smooth lobes with no relief, or sandpaper with no lobes.

 5. THE NORMAL'S SPECTRUM IS A CONSTRUCTION, NOT A TUNING. The height field is
    split into one-octave bands, each band's gradient re-weighted, and then —
    the part that makes it a guarantee rather than a hope — the band amplitudes
    are MEASURED ON THE OUTPUT and the weights corrected, twice. The realised
    radial power spectrum is a power law of slope 2*log2(ratio) - 2 whatever the
    raymarch happened to produce. All noise below the volume's resolution is
    synthesised in the Fourier domain, because a cubic-zoomed lattice beats
    against the pixel grid into 45-degree moire that the per-octave
    re-normalisation then promotes into visible scratches.

    Finally the normal is passed through the same saturating map a real surface
    normal gets (`n/sqrt(1+|n|^2)`), which is what makes its histogram a plateau
    instead of a spike with outliers — reference p99/sigma is 2.0, a raw gradient
    is 3.2 — and which is why the reference art reads as broad saturated colour
    fields rather than pale mush with hot specks.

 6. THE SILHOUETTE IS CRENELLATED AT FULL RESOLUTION. The volume is marched at
    half the sprite's size, so its boundary upsamples to a smooth ramp, and a
    real cumulus edge is a row of cauliflower scallops 20-60 px across. Because
    optical depth decays exponentially outside the surface, multiplying it by
    exp(k * detail) TRANSLATES the boundary by k*detail*s — scallops for one
    2-D field. Three details make it work rather than wreck it, and each was a
    visible failure first: the factor is gated off the saturated core (ungated,
    a -3 sigma excursion takes tau=8 to tau=0.3 and the cloud comes out as
    lace); the field is band-limited AFTER rectification (the soft-abs that
    rounds its peaks also manufactures 5-px harmonics, and those displace the
    boundary into fur); and the displacement is asymmetric (a symmetric one
    opens dark pockets just inside the rim, so the silhouette reads as sponge).

CLI
    gen_cloud_sprites.py --out DIR [--count 12] [--seed 7] [--sheet PNG]
                         [--compare REF_SPRITE:OUT_PNG]
"""

from __future__ import annotations

import argparse
import math
import os
import time

import numpy as np
from PIL import Image, ImageDraw
from scipy.ndimage import distance_transform_edt, gaussian_filter, zoom
from scipy.special import ndtri

# --------------------------------------------------------------------------
# geometry constants
# --------------------------------------------------------------------------
TILE_W, TILE_H = 512, 288          # one half of the sprite, in texels
PX = 128.0                          # full-res pixels per world unit

# The density volume is marched at half the sprite's xy resolution. Nothing in
# the profile asks for coverage detail below ~4 px (the thinnest filament the
# reference set carries is 5.7 px), and resolving finer would only spend bytes
# the lossless encoder cannot claw back.
VX, VY, VZ = 256, 144, 112
WX, WY, WZ = TILE_W / PX, TILE_H / PX, 2.6   # world extents (4.0 x 2.25 x 2.6)


# --------------------------------------------------------------------------
# noise — 3-D lattice (volume) and 2-D spectral (surface relief)
# --------------------------------------------------------------------------
def _zoom_to(lat: np.ndarray, target: tuple) -> np.ndarray:
    """Periodic upsample of a small lattice to `target`.

    Two stages on purpose: a cubic zoom to half the target is cheap (the output
    is 1/8 the voxels) and removes the derivative creases that plague a linear
    upsample of a coarse lattice; the final x2 is linear, where those creases
    are a voxel apart and invisible. A single cubic zoom to full size costs ~8x
    more for no visible gain.
    """
    half = tuple(max(2, t // 2) for t in target)
    a = zoom(
        lat,
        tuple(h / c for h, c in zip(half, lat.shape)),
        order=3,
        mode="grid-wrap",
        grid_mode=True,
    )
    out = zoom(
        a,
        tuple(t / s for t, s in zip(target, a.shape)),
        order=1,
        mode="grid-wrap",
        grid_mode=True,
    )
    return out[: target[0], : target[1], : target[2]].astype(np.float32)


def _decrease(vol):
    """Kill the derivative creases the final linear zoom leaves behind.

    A linear upsample is C0 but not C1, and its kinks sit on axis-aligned
    planes two voxels apart — at sprite resolution, straight 4-px lines. They
    are invisible in the density (the transfer function smears them) but any
    fixed-amplitude re-normalisation downstream promotes them into scratches.
    One sub-voxel blur removes them. The 2-D relief that actually feeds the
    normal map does not come from this lattice at all, for the same reason.
    """
    return gaussian_filter(vol, 0.62)


def fbm3(rng, freq, octaves, gain, billow=False, target=(VZ, VY, VX), ax=1.0, az=1.0):
    """Seamless 3-D fbm in roughly [0,1]; `freq` = lattice cells per world unit.

    `billow` rectifies each octave into rounded lobes before summing — that is
    what reads as cauliflower. A plain fbm at the same spectrum reads as marble.
    `ax` / `az` stretch the lattice along x / z: a wind-torn veil is not
    isotropic, and an isotropic tear mask is exactly what makes a veil read as
    confetti instead of filaments.
    """
    out = np.zeros(target, dtype=np.float32)
    amp, norm, f = 1.0, 0.0, float(freq)
    for _ in range(octaves):
        cells = (
            max(3, int(round(f * WZ / az))),
            max(3, int(round(f * WY))),
            max(3, int(round(f * WX / ax))),
        )
        layer = _zoom_to(rng.random(cells).astype(np.float32), target)
        if billow:
            layer = 1.0 - np.abs(layer * 2.0 - 1.0)
        out += amp * layer
        norm += amp
        amp *= gain
        f *= 2.0
    out = _decrease(out / norm)
    lo, hi = float(out.min()), float(out.max())
    return (out - lo) / max(hi - lo, 1e-6)


def band_noise(rng, lam, aniso=1.0, shape=(TILE_H, TILE_W)):
    """One isotropic octave of band-limited 2-D noise, peak wavelength `lam` px.

    Synthesised in the Fourier domain rather than by upsampling a lattice. A
    cubic `zoom` of a coarse lattice to a non-integer multiple beats against the
    pixel grid, and the beat is diagonal, coherent and octave-wide — harmless in
    a density field that a logistic then smears, fatal in a normal map whose
    octaves are re-normalised to fixed amplitudes, where it surfaces as 45-degree
    hatching across the whole tile. Building the octave as a radial filter on
    white noise has no lattice to beat against, is exactly periodic, and is
    isotropic by construction.
    """
    fy = np.fft.fftfreq(shape[0])[:, None]
    fx = np.fft.rfftfreq(shape[1])[None, :] * aniso
    r = np.sqrt(fy * fy + fx * fx)
    f0 = 1.0 / lam
    w = np.exp(-0.5 * (np.log(np.maximum(r, 1e-9) / f0) / 0.62) ** 2)
    w[0, 0] = 0.0
    out = np.fft.irfft2(np.fft.rfft2(rng.standard_normal(shape)) * w, s=shape)
    out = out.astype(np.float32)
    return out / max(float(out.std()), 1e-9)


def spec2(rng, lam0, octaves, gain, aniso=1.0, shape=(TILE_H, TILE_W)):
    """Multi-octave spectral noise normalised to [0,1]. Drop-in for a 2-D fbm."""
    out = np.zeros(shape, dtype=np.float32)
    amp, lam = 1.0, float(lam0)
    for _ in range(octaves):
        out += amp * band_noise(rng, lam, aniso, shape)
        amp *= gain
        lam *= 0.5
    lo, hi = float(out.min()), float(out.max())
    return (out - lo) / max(hi - lo, 1e-6)


def billow2(rng, lam0, octaves, gain, soft=0.42, shape=(TILE_H, TILE_W)):
    """Rounded-lobe (cauliflower) relief, zero-mean, unit std.

    `soft` rounds the rectifier's valleys: a hard |n| makes creases whose
    curvature is a delta, and a normal map built on those reads as faceted
    crumpled foil — the failure the erosion generator hit. sqrt(n^2 + soft^2)
    has bounded curvature everywhere, so the lobes stay lobes and the valleys
    between them stay round.
    """
    out = np.zeros(shape, dtype=np.float32)
    amp, lam = 1.0, float(lam0)
    for _ in range(octaves):
        n = band_noise(rng, lam, 1.0, shape)
        out -= amp * (np.sqrt(n * n + soft * soft) - soft)
        amp *= gain
        lam *= 0.5
    out -= out.mean()
    return out / max(float(out.std()), 1e-9)


# --------------------------------------------------------------------------
# shape grammar
# --------------------------------------------------------------------------
def smax(a, b, k):
    """Polynomial smooth maximum. Exactly max() once |a-b| > k, so blobs that
    do not touch contribute nothing — a log-sum-exp instead keeps inflating the
    crowded middle of the cloud into a peak, which is what makes a raymarched
    cumulus read as one round blob."""
    h = np.clip(0.5 + 0.5 * (a - b) / k, 0.0, 1.0)
    return b + (a - b) * h + k * h * (1.0 - h)


def smin(a, b, k):
    """Polynomial smooth minimum — the flat base is an intersection, not a cut."""
    h = np.clip(0.5 - 0.5 * (a - b) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


# Twelve recipes. Each is a *family*, not a sprite: the numbers below are
# ranges the PRNG draws from, so re-seeding gives a different sky of the same
# character. Nine dense + three torn veils, because twelve cumulus is not what
# a sky looks like — and the reference set that has to be replaced splits 9/3
# on exactly that line.
#
#   n         how many cauliflower lobes ride the top of the mass. SMALL on
#             purpose: the reference median is 2. Many small lobes on a wide
#             slab is the "popcorn on a plank" silhouette.
#   half_w    outer half-width of the cloud, world units (1 unit = 128 px)
#   height    base-to-crown height, world units
#   core      fraction of `height` taken by the mass the lobes sit on
#   lobe_r    lobe radius, world units — large, so a lobe is a shoulder of the
#             cloud rather than a bobble on it
#   masses    how many separate masses the base is broken into (1 = one cloud,
#             more = cumulus fractus, which is where the high lobe counts and
#             ragged outlines in the set come from)
#   over      per-family parameter overrides. This is where the SET is tuned as
#             a set rather than a bag of one-offs: the variety gate measures the
#             spread of lobe count, edge width, roughness and normal wavelength
#             ACROSS the twelve, so each family deliberately owns a different
#             corner of those axes. `solid` marks the near-opaque cumulus — two
#             of the nine reference cumulus are 30-70 % opaque core with a narrow
#             rim, and without a couple of those the set has no spread in edge
#             softness or mean coverage at all.
ARCHETYPES = [
    # name         n       half_w        height        core          lobe_r        masses
    # 0  very wide, very low, near-opaque, crisp-edged: the "fair weather" plate
    ("humilis",   (1, 1), (1.50, 1.62), (0.79, 0.89), (0.66, 0.78), (0.52, 0.64), (1, 1),
     dict(solid=1, erode=(0.20, 0.28), blend=(0.22, 0.29), band_ratio=(0.592, 0.620), fine_floor=(0.050, 0.090),
          pend=(0.09, 0.15), nbody=(3, 4), base_wobble=(0.144, 0.240),
          edge_detail=(0.85, 1.05), nrm_xy=(0.26, 0.30), relief=(0.20, 0.28),
          dome_sig=(9.0, 12.0))),
    # 1  medium two-crown cumulus, softest edge of the dense group
    ("humilis",   (2, 2), (1.27, 1.39), (1.07, 1.19), (0.48, 0.60), (0.48, 0.60), (1, 1),
     dict(erode=(0.18, 0.26), blend=(0.21, 0.27), band_ratio=(0.600, 0.630), fine_floor=(0.063, 0.105),
          pend=(0.10, 0.19), nbody=(3, 4), base_wobble=(0.160, 0.272),
          nrm_xy=(0.175, 0.205))),
    # 2  wide solid mediocris — the most "textbook" cumulus of the set
    ("mediocris", (2, 2), (1.41, 1.55), (0.97, 1.07), (0.54, 0.66), (0.46, 0.58), (1, 1),
     dict(solid=1, erode=(0.20, 0.28), blend=(0.20, 0.26), band_ratio=(0.615, 0.645), fine_floor=(0.067, 0.109),
          depth_lo=(0.095, 0.135), grain=(0.080, 0.110), base_wobble=(0.192, 0.304),
          pend=(0.18, 0.28), nbody=(3, 4), dome_mix=(0.55, 0.70),
          nrm_xy=(0.22, 0.26), relief=(0.26, 0.34))),
    # 3  TALL and narrow: the aspect-ratio outlier the variety gate needs
    ("congestus", (2, 2), (1.06, 1.18), (1.25, 1.39), (0.38, 0.50), (0.52, 0.66), (1, 1),
     dict(erode=(0.21, 0.29), blend=(0.20, 0.26), band_ratio=(0.590, 0.620), fine_floor=(0.052, 0.092),
          depth_lo=(0.105, 0.145), base_wobble=(0.112, 0.208), pend=(0.11, 0.20),
          nbody=(2, 3), edge_detail=(0.95, 1.15), dome_mix=(0.30, 0.45),
          nrm_xy=(0.25, 0.29), relief_lam=(62.0, 84.0))),
    # 4  the flattest plate in the set — wide, shallow, many shallow bumps
    ("humilis",   (2, 3), (1.52, 1.65), (0.77, 0.87), (0.64, 0.76), (0.34, 0.44), (1, 1),
     dict(erode=(0.22, 0.30), blend=(0.18, 0.24), band_ratio=(0.645, 0.675), fine_floor=(0.085, 0.120),
          base_wobble=(0.128, 0.224), pend=(0.10, 0.18), nbody=(4, 5),
          relief=(0.34, 0.44), nrm_xy=(0.155, 0.185))),
    # 5  stratocumulus roll: a long deck with a row of small crowns
    ("stratocu",  (3, 4), (1.44, 1.56), (0.85, 0.95), (0.60, 0.72), (0.30, 0.40), (1, 1),
     dict(solid=1, erode=(0.24, 0.32), blend=(0.19, 0.25), band_ratio=(0.660, 0.690), fine_floor=(0.090, 0.125),
          grain=(0.085, 0.115), depth_grain=(0.13, 0.19), pend=(0.14, 0.24),
          depth_vert=(0.18, 0.32),
          base_wobble=(0.112, 0.208), nbody=(4, 5), relief=(0.36, 0.48),
          edge_detail=(1.00, 1.20), relief_lam=(34.0, 46.0), nrm_xy=(0.19, 0.23))),
    # 6  two masses with real sky between them
    ("fractus",   (2, 3), (1.44, 1.56), (0.93, 1.05), (0.46, 0.58), (0.38, 0.50), (2, 2),
     dict(erode=(0.22, 0.30), blend=(0.18, 0.24), band_ratio=(0.610, 0.640), fine_floor=(0.071, 0.118),
          tau_peak=(4.2, 5.6), tail=(0.022, 0.030), pend=(0.11, 0.20), nbody=(2, 3),
          depth_vert=(0.22, 0.38),
          nrm_xy=(0.21, 0.25))),
    # 7  broken cluster: three masses, high lobe count, ragged outline
    ("fractus",   (5, 7), (1.46, 1.58), (0.87, 0.99), (0.38, 0.50), (0.24, 0.32), (3, 3),
     dict(erode=(0.24, 0.32), blend=(0.12, 0.17), band_ratio=(0.665, 0.695), fine_floor=(0.095, 0.130),
          tau_peak=(4.6, 6.0), tail=(0.020, 0.027), pend=(0.20, 0.30),
          depth_vert=(0.16, 0.30),
          base_wobble=(0.160, 0.272), nbody=(2, 3), relief=(0.36, 0.48),
          edge_detail=(1.05, 1.25), relief_lam=(30.0, 42.0), nrm_xy=(0.175, 0.205))),
    # 8  tall-ish solid cumulus with a shoulder — the other end from #0
    ("pair",      (2, 3), (1.20, 1.33), (1.15, 1.27), (0.46, 0.58), (0.50, 0.62), (1, 1),
     dict(solid=1, erode=(0.19, 0.27), blend=(0.21, 0.27), band_ratio=(0.598, 0.626), fine_floor=(0.053, 0.095),
          base_wobble=(0.096, 0.176), tail=(0.019, 0.025), pend=(0.16, 0.26),
          nbody=(2, 3), dome_sig=(8.0, 11.0), nrm_xy=(0.25, 0.29),
          relief=(0.24, 0.32))),
    # 9-11 torn veils. Their normal map is a different animal from the cumulus:
    # short centroid wavelength, high roughness, near-zero z — which is most of
    # the set's spread in every normal-map statistic, so the ratios and relief
    # scales here are deliberately far from the dense families'.
    ("veil",      (3, 5), (1.02, 1.19), (0.40, 0.52), (0.62, 0.82), (0.16, 0.24), (1, 2),
     dict(band_ratio=(0.698, 0.730), base_wobble=(0.048, 0.128), tail=(0.105, 0.130),
          tear_in=(0.70, 0.90), erode=(0.20, 0.32), back_hi=(0.42, 0.56), nbody=(3, 4),
          relief_lam=(18.0, 26.0), tear_ax=(3.2, 4.4))),
    ("veil",      (4, 7), (0.98, 1.15), (0.36, 0.49), (0.58, 0.78), (0.13, 0.20), (1, 2),
     dict(band_ratio=(0.700, 0.732), base_wobble=(0.048, 0.128), tail=(0.107, 0.132),
          tear_in=(0.74, 0.94), erode=(0.20, 0.32), back_hi=(0.42, 0.56), nbody=(3, 5),
          relief_lam=(16.0, 24.0), tear_ax=(3.6, 5.0))),
    ("veil",      (2, 4), (0.94, 1.11), (0.41, 0.56), (0.66, 0.86), (0.17, 0.26), (1, 1),
     dict(band_ratio=(0.695, 0.730), base_wobble=(0.048, 0.128), tail=(0.103, 0.128),
          tear_in=(0.64, 0.84), erode=(0.20, 0.32), back_hi=(0.42, 0.56),
          depth_grain=(0.18, 0.24), nbody=(2, 4), relief_lam=(20.0, 30.0),
          tear_ax=(2.8, 4.0)))
]


def build_shape(rng, spec):
    """Draw one cloud's blob list from its archetype. Returns (blobs, pend, meta).

    A cumulus is a MASS with cauliflower riding its top, not a row of columns
    and not one ellipsoid. The base is flat because that is the condensation
    level; the character is in the lobes on the upper surface, each one a rising
    thermal.

    The mass is NOT one wide flat ellipsoid. That was the previous version's
    mistake and it is visible from across the room: a wide thin slab silhouettes
    as a straight bar, so however good the lobes are the cloud reads as popcorn
    on a plank (bbox fill 0.45 against the reference's 0.58, lobe count 4 against
    2). Here the mass is a short chain of `nbody` large ellipsoids whose radii
    taper toward the ends and whose centres ride a shallow arc, heavily fused —
    so the body already rolls, and the lobes only have to add a crown.
    """
    name, nrange, wrange, hrange, corer, lober, massr, over = spec
    n = int(rng.integers(nrange[0], nrange[1] + 1))
    W = float(rng.uniform(*wrange))
    H = float(rng.uniform(*hrange))
    core = float(rng.uniform(*corer))
    lobe_r = float(rng.uniform(*lober))
    nm = int(rng.integers(massr[0], massr[1] + 1))
    nbody = over.get("nbody", (2, 3))
    veil = name == "veil"
    # A cumulus family is one updraught, so its top is a single dome and its
    # lobes are scallops on that dome. A fractus or a stratocumulus deck is the
    # opposite: separate masses, big independent lobes, no shared crown. The
    # two shaping terms below are for the first kind only — applied to the
    # second they iron the set's broken clouds into loaves.
    domed = name in ("humilis", "mediocris", "congestus", "pair")

    # Frame the cloud about the middle of the tile: the profile wants 15-85 px
    # of margin above and 25-80 below, and a base pinned to the tile floor
    # reads as a cloud that fell out of frame.
    base_y = -0.5 * H + 0.045 + float(rng.uniform(-0.05, 0.05))
    core_h = H * core

    # The crown's position is drawn FIRST, and everything else is built around
    # it. A cumulus is one updraught: the whole mass bulges under the tower, so
    # the body is highest exactly where the crown sits and the crown continues
    # the body's arc rather than standing on it. Build the body first and drop a
    # crown wherever the lobe placement happens to land, and the two disagree —
    # a tall lobe next to a low shoulder joins in a vertical step, and every
    # sprite in the set comes out as a block with a shelf beside it.
    # Kept near the middle on the domed families. The arc falls away as the
    # square of the distance from here, so a crown drawn out at a third of the
    # half-width tips a wide low humilis into a wedge — high at one end, a
    # straight slope to the other — instead of the loaf it should be.
    crown_x = float(rng.uniform(-0.18, 0.18) if domed
                    else rng.uniform(-0.34, 0.34)) * W

    blobs = []
    masses = []          # (cx, rx, ry) of each cluster, for placing lobes later
    if nm == 1:
        masses.append((float(rng.uniform(-0.05, 0.05)), W, core_h * 0.5))
    else:
        # Split the span into unequal chunks with gaps between them.
        cuts = np.sort(rng.uniform(0.18, 1.0, nm - 1))
        edges = np.concatenate([[0.0], cuts, [1.0]]) * 2.0 * W - W
        widest = float(np.max(np.diff(edges)))
        for a, b in zip(edges[:-1], edges[1:]):
            gap = float(rng.uniform(0.10, 0.20)) * (b - a)
            rx = (b - a) * 0.5 - gap
            if rx < lobe_r * 0.7:
                continue
            # Height scales with width, so a broken cloud is one mass with
            # COMPANIONS rather than a row of equals. Equal masses silhouette as
            # a camel — two humps with a dip between them — which is a shape the
            # sky does not make and the eye rejects immediately.
            frac = (b - a) / max(widest, 1e-6)
            masses.append(
                (
                    float((a + b) * 0.5 + rng.uniform(-0.05, 0.05)),
                    rx,
                    core_h * 0.5 * (0.42 + 0.58 * frac) * float(rng.uniform(0.88, 1.08)),
                )
            )
    if not masses:
        masses = [(0.0, W, core_h * 0.5)]

    # Each mass becomes a fused chain. The sub-ellipsoids are deep in z
    # (rz ~ 1.2-1.8 x ry): a cloud is about as deep as it is tall, and a mass
    # that is thin in z never accumulates enough optical depth to bake an opaque
    # core, which is most of why the previous set looked like grey mottle where
    # The reference is solid white.
    body = []
    for cx, rx, ry in masses:
        nb = int(rng.integers(nbody[0], nbody[1] + 1))
        # A wide mass needs at least three links, or the "chain" is two blobs at
        # the extremes with a saddle between them.
        if rx > 0.85:
            nb = max(nb, 3)
        nb = max(1, min(nb, 5))
        # The chain's own top arc. This is what makes the BODY a domed loaf
        # rather than a plate, and it has to be a real fraction of the mass's
        # height: at a tenth of `ry` the chain's top is flat to the eye, the
        # dome has to come from the lobes instead, and a lobe big enough to
        # supply it is a ball sitting on a plate.
        arc = ry * float(rng.uniform(0.45, 0.95) if domed else rng.uniform(0.10, 0.34))
        ts = np.linspace(-1.0, 1.0, nb) if nb > 1 else np.array([0.0])
        for t in ts:
            # Width and height taper TOGETHER, about the crown. Shrinking only
            # the height leaves a wide, very flat ellipsoid at the end of the
            # chain, and a wide flat ellipsoid silhouettes as a horizontal shelf
            # with a right-angle join — the one shape in this grammar that reads
            # instantly as machinery rather than weather.
            ex0 = cx + float(t) * rx * 0.55
            q = float(np.clip((ex0 - crown_x) / max(rx, 1e-6), -1.35, 1.35))
            taper = 1.0 - 0.28 * q * q
            sub_rx = rx * float(rng.uniform(0.52, 0.74)) * (0.58 + 0.42 * taper)
            sub_ry = ry * float(rng.uniform(0.92, 1.12)) * taper
            sub_ry = max(sub_ry, ry * 0.58)
            ex = cx + float(t) * max(rx - sub_rx, 0.0) * float(rng.uniform(0.90, 1.06))
            # The centre sits LESS than one radius above the condensation level,
            # always, so the half-space intersection always bites. Let it float
            # above and the ellipsoid keeps its own rounded underside: the cloud
            # grows a belly, and a cumulus with a belly is instantly wrong.
            # A shallow arc over the chain, so the body's own top is a dome.
            # Without it a two-element chain with a strong taper puts a low wide
            # ellipsoid beside a tall one and the join is a step.
            # The arc's own abscissa spans the CHAIN, not the mass: the links only
            # reach 0.55 of `rx`, so normalising by `rx` leaves `1 - q^2` between
            # 0.7 and 1 across the whole body and the "dome" is a uniform lift
            # with a straight top.
            qa = float(np.clip((ex0 - crown_x) / max(rx * 0.62, 1e-6), -1.0, 1.0))
            cy = (base_y + sub_ry * float(rng.uniform(0.70, 0.92))
                  + arc * max(0.0, 1.0 - qa * qa))
            rz = min(sub_ry * float(rng.uniform(1.25, 1.90)), 0.95)
            rz = max(rz, sub_rx * 0.34)
            body.append((ex, cy, float(rng.uniform(-0.10, 0.10)), sub_rx, sub_ry, rz))
    blobs.extend(body)

    def core_top(x):
        """Top of the body under x — where a lobe would sit."""
        best = base_y
        for ex, cy, _cz, sub_rx, sub_ry, _rz in body:
            t = abs(x - ex) / max(sub_rx, 1e-6)
            if t < 1.0:
                best = max(best, cy + sub_ry * math.sqrt(1.0 - t * t))
        return best

    # Lobes ride the body's top ARC, each rising a fraction of its own radius
    # above whatever is under it. Giving them absolute heights instead is a
    # trap that looks fine in the numbers and terrible on screen: the arc falls
    # away at the ends, so an edge lobe has to stack four or five ellipsoids to
    # reach the same absolute top, and the cloud grows goalposts. The crown lobe
    # is therefore chosen near the body's HIGHEST point, and a stack is capped at
    # two, so the tall one is a shoulder and never a tower.
    # Lobes cluster toward the middle when there are few of them. Spreading two
    # lobes to the flanks leaves the centre lower than both ends and the cloud
    # silhouettes as a W, which no cumulus does.
    lobe_cap = core_h * 0.5 * float(
        rng.uniform(1.00, 1.32) if domed else rng.uniform(2.4, 3.2))
    span = min(0.19 * (n - 1), 0.60)
    slots = np.linspace(-span, span, n) if n > 1 else np.array([0.0])
    tall = int(np.argmin(np.abs(slots)))          # the crown is the middle slot
    for i in range(n):
        # A lobe is a thermal RIDING the mass, so the mass sets its size. Left
        # to `lobe_r` alone it comes out near twice the body's own half-height
        # on a wide shallow humilis, and however well it is sunk into the top
        # it still stands a full body-height proud: the cloud silhouettes as a
        # mushroom, which is the most recognisable way a generated cumulus goes
        # wrong and the one the reference set never does.
        r = min(lobe_r * float(rng.uniform(0.85, 1.20)), lobe_cap)
        cx = float(crown_x + slots[i] * W
                   + rng.uniform(-0.22, 0.22) * (1.2 * W / max(n, 1)))
        cx = float(np.clip(cx, -W * 0.78, W * 0.78))
        top = core_top(cx)
        # A lobe out near the flank rises less than one in the middle. Without
        # that the body's arc falls away under an edge lobe, the lobe reaches
        # for an absolute height anyway, and the cloud grows goalposts.
        centre = 1.0 - 0.50 * abs(cx) / max(W, 1e-6)
        rise = r * float(rng.uniform(0.45, 1.00)) * centre
        if i == tall:
            rise = max(rise, min(base_y + H - top, r * 1.05))
        ht = top + rise - base_y
        y = top - r * 0.72 + r
        stack = 0
        while True:
            # A little wider than tall — but only a little. Push the ratio past
            # ~1.3 and the lobe's own top goes flat over its middle, so the crown
            # silhouettes as a rectangular block with a step down to the body
            # instead of an arc rising out of it.
            blobs.append(
                (
                    cx + float(rng.uniform(-0.05, 0.05)),
                    y,
                    float(rng.uniform(-0.30, 0.30)),
                    r * float(rng.uniform(1.00, 1.26)),
                    r * float(rng.uniform(0.88, 1.06)),
                    r * float(rng.uniform(0.95, 1.35)) * (0.7 if veil else 1.0),
                )
            )
            stack += 1
            if y + r >= base_y + ht - 1e-3 or stack >= 2:
                break
            y += r * float(rng.uniform(0.80, 0.98))
            r *= float(rng.uniform(0.78, 0.92))

    # Pendant shreds. The base plane is an intersection, so anything built
    # below it is simply cut away — which is exactly why an earlier version
    # baked a razor-flat base (sil_base_over_top_rms 0.14 against a reference
    # range of 0.34-1.53; a base FLATTER than the reference is as much a tell
    # as a lumpy one). These are unioned back on AFTER the cut, so they survive:
    # physically, the ragged fractus that hangs beneath a cumulus base.
    pend = []
    pend_r = over.get("pend", (0.14, 0.26))
    npd = int(rng.integers(1, 4))
    for _ in range(npd):
        r = float(rng.uniform(*pend_r)) * (0.5 if veil else 1.0)
        px_ = float(rng.uniform(-0.80, 0.80)) * W
        if core_top(px_) <= base_y + 1e-6:
            continue                      # nothing overhead to hang from
        pend.append(
            (px_, base_y + r * float(rng.uniform(-0.30, 0.05)),
             float(rng.uniform(-0.15, 0.15)),
             r * float(rng.uniform(0.9, 1.5)), r * 0.62,
             r * float(rng.uniform(0.5, 0.9)))
        )

    return blobs, pend, {"name": name, "base_y": base_y, "half_w": W,
                         "height": H, "veil": veil}


# --------------------------------------------------------------------------
# density field + march
# --------------------------------------------------------------------------
def march(rng, blobs, pend, meta, p):
    """Orthographic volumetric march. Returns the 2-D fields at volume res."""
    xs = np.linspace(-WX / 2, WX / 2, VX, dtype=np.float32)
    ys = np.linspace(WY / 2, -WY / 2, VY, dtype=np.float32)   # row 0 = top
    zs = np.linspace(WZ / 2, -WZ / 2, VZ, dtype=np.float32)   # slice 0 = near

    X = xs[None, None, :]
    Y = ys[None, :, None]
    Z = zs[:, None, None]

    # --- domain warp -------------------------------------------------------
    # Advecting the *coordinates* rather than adding noise to the field is what
    # keeps lobes reading as lobes: a warped ellipsoid is still a closed, convex
    # blob, where an additively perturbed one dissolves into fog.
    wa = p["warp"]
    wf = p["warp_freq"]
    WXf = (fbm3(rng, wf, 3, 0.55) - 0.5) * wa
    WYf = (fbm3(rng, wf, 3, 0.55) - 0.5) * wa * 0.62
    WZf = (fbm3(rng, wf, 3, 0.55) - 0.5) * wa
    # Wind shear: the veils are torn streaks, so their warp is stretched
    # horizontally and sheared with height.
    xw = X + WXf + p["shear"] * (Y - meta["base_y"])
    yw = Y + WYf
    zw = Z + WZf
    del WXf, WYf, WZf

    # --- blob union --------------------------------------------------------
    # f_i is an approximate signed distance (positive inside) rather than the
    # usual 1 - r^2, so the smooth-max blend radius `k` is a length in world
    # units and the amount of fusion does not depend on blob size.
    k = p["blend"]
    F = None
    for (cx, cy, cz, rx, ry, rz) in blobs:
        d = np.sqrt(
            ((xw - cx) / rx) ** 2 + ((yw - cy) / ry) ** 2 + ((zw - cz) / rz) ** 2
        )
        f = (1.0 - d) * ((rx * ry * rz) ** (1.0 / 3.0))
        F = f if F is None else smax(F, f, k)
    del xw, yw, zw

    # --- flat base ---------------------------------------------------------
    # A cumulus base is the condensation level: flat, but not machined. The
    # half-space is displaced downward by a SPARSE wobble — zero over most of
    # the span, dipping hard where a shaft of cloud hangs below the level. That
    # is the shape of the reference statistic: ~2/3 of base columns within a few
    # px of the median (base_flat_frac 0.68 on the dense set) yet an rms
    # deviation of 6-25 px (base_rms), which no symmetric wobble reproduces.
    wn = fbm3(rng, 1.7, 3, 0.5, target=(1, VY, VX))[0]
    hang = np.clip((wn - 0.46) / 0.54, 0.0, 1.0) ** 1.3
    base = Y - (meta["base_y"] - p["base_wobble"] * hang[None, :, :])
    F = smin(F, base, p["base_blend"])
    del base, wn, hang

    # Pendants are unioned back AFTER the cut, so the condensation level does
    # not shave them off.
    for (cx, cy, cz, rx, ry, rz) in pend:
        d = np.sqrt(((X - cx) / rx) ** 2 + ((Y - cy) / ry) ** 2 + ((Z - cz) / rz) ** 2)
        F = smax(F, (1.0 - d) * ((rx * ry * rz) ** (1.0 / 3.0)), p["blend"])

    # --- surface erosion ---------------------------------------------------
    # Gated to a shell around the surface: 1 at F=0, falling as 1/(1+(F/w)^2)
    # inward. Eroding the whole field instead hollows the core and destroys the
    # internal density the profile measures as dens_cov_hp_std_thick.
    #
    # The dominant erosion wavelength is deliberately ~40-90 px: the coverage
    # ramp is ~25 px wide, so anything finer is smeared out of the silhouette
    # and only costs file size, while anything coarser just translates the whole
    # surface instead of breaking it into lobes. The 0.30 offset is the field's
    # working point — subtracting it keeps the erosion roughly mean-free so the
    # cloud is scalloped, not shrunk.
    # The shell must close on BOTH sides of the surface. Gating on max(F, 0)
    # leaves the weight at exactly 1 everywhere OUTSIDE it, so the erosion runs
    # at full strength through the whole exponential tail — and since the tail is
    # 20-40 px of low coverage, a mid-frequency field chopping it up turns a soft
    # halo into a mat of curly filaments. On a contact sheet that is a cloud
    # wearing a fur coat, and it is also where the file-size budget goes, because
    # lossless WebP cannot compress it. Outward the shell is deliberately
    # narrower than inward: scalloping belongs at the boundary, not beyond it.
    bill = fbm3(rng, p["erode_freq"], 4, 0.46, billow=True)
    wsh = np.where(F >= 0.0, p["shell_w"], p["shell_w"] * 0.40)
    shell = 1.0 / (1.0 + (F / wsh) ** 2)
    F -= p["erode"] * shell * (bill - 0.30)
    del bill, shell, wsh

    # --- density transfer --------------------------------------------------
    # THE soft-edge lever. logistic(F/s) is ~1 inside and decays as exp(F/s)
    # outside, so the projected coverage has an exponential tail of tunable
    # length instead of stopping dead at the geometric boundary.
    #
    # `s` is not a constant over the cloud. A cumulus crown is where the
    # updraught is condensing hardest — a sharp boundary a few pixels wide —
    # while the base is evaporating into the subcloud layer and trails off over
    # tens. The reference art has exactly that asymmetry (its crown edges are
    # 4 px, its bases 30+), and a single tail length can only average the two
    # into a uniformly furry outline.
    vsoft = np.clip(
        (meta["base_y"] + meta["height"] * 0.50 - Y) / (0.45 * max(meta["height"], 1e-6)),
        0.0, 1.0,
    ) ** 1.5
    s = p["tail"] * (1.0 + p["base_soft"] * vsoft)
    rho = 1.0 / (1.0 + np.exp(np.clip(-F / s, -30.0, 30.0)))

    # Internal density variation — the profile's "no internal structure"
    # defect. Low frequency, moderate amplitude, and it doubles as the pocket
    # field the inner-glow channel is accumulated against, so the glow reads as
    # illuminated cavities rather than a copy of coverage.
    dens_n = fbm3(rng, p["inner_freq"], 3, 0.5)
    rho *= 1.0 + p["inner_amp"] * (dens_n - 0.5)

    # --- tearing the tail into wisps ---------------------------------------
    # The mask only acts where the logistic has already fallen off (tailw ramps
    # in as F goes negative), so the body is untouched while the halo breaks
    # into filaments. Values above 1 make streamers that reach further out than
    # the plain exponential would; values near 0 punch the gaps between them.
    # `tear_ax` stretches the mask along the wind: a torn veil is a set of
    # horizontal filaments, and an isotropic mask makes confetti instead.
    tear = fbm3(rng, p["tear_freq"], 3, 0.62, ax=p["tear_ax"], az=p["tear_ax"])
    # Thresholded, not merely scaled: a mask that only dims the tail gives a
    # smooth halo, and a smooth halo has no filaments in it. Clipping the
    # bottom of the noise away punches genuine holes, which is what turns the
    # exponential skirt into separate streamers of measurable thickness.
    tear = p["tear_hi"] * np.clip((tear - p["tear_cut"]) / 0.42, 0.0, 1.0) ** 1.3
    tear += p["tear_lo"]
    # `tear_in` decides how far in the tearing reaches. Near 0 the body is
    # untouched and only its skirt frays (cumulus); near 1 the whole sheet is
    # shredded, which is what a torn stratus veil actually is.
    tailw = np.clip(
        p["tear_in"] + (1.0 - p["tear_in"]) * (-F / (p["tear_reach"] * s)), 0.0, 1.0
    )
    # Tearing is a base-and-flank phenomenon on a cumulus: the crown is the part
    # actively condensing and it is where the outline stays smooth and scalloped.
    # Applied uniformly, the same mask makes the crown hairy, which is the single
    # loudest difference between a generated cloud and the reference at 1:1.
    tailw = tailw * (p["tear_crown"] + (1.0 - p["tear_crown"]) * vsoft)
    rho *= 1.0 - tailw + tailw * tear
    del tear, tailw, F

    np.maximum(rho, 0.0, out=rho)

    # --- integrate ---------------------------------------------------------
    dz = WZ / VZ
    cum = np.cumsum(rho, axis=0)
    cum *= p["sigma_e"] * dz
    total = cum[-1].copy()

    # Visible surface, for the normal map: the transmittance-weighted expected
    # depth of first scattering. A hard "where does tau cross T" crossing has to
    # pick a fallback threshold wherever the ray never reaches T, and the seam
    # between the two regimes is a cliff that the normal map turns into a
    # scratch. This expectation is continuous everywhere by construction.
    w = rho
    w *= np.exp(-cum)
    zi = np.arange(VZ, dtype=np.float32)[:, None, None]
    wsum = w.sum(axis=0)
    surf = (w * zi).sum(axis=0) / np.maximum(wsum, 1e-6) / float(VZ)
    body = total > 0.35

    # Inner glow: scattered light that escaped toward the viewer, weighted by
    # the interior density noise so it pools in cavities.
    glow = (w * dens_n).sum(axis=0) * dz
    del w, dens_n, rho, cum

    return {"tau": total, "surf": surf, "body": body, "glow": glow}


# --------------------------------------------------------------------------
# 2-D assembly: coverage, the three data channels, the normal map
# --------------------------------------------------------------------------
def up(a, order=3):
    """Volume resolution -> sprite resolution."""
    out = zoom(a.astype(np.float32), (TILE_H / a.shape[0], TILE_W / a.shape[1]),
               order=order, mode="nearest")
    return out[:TILE_H, :TILE_W]


def bbox_of(mask):
    ys, xs = np.nonzero(mask)
    if len(ys) == 0:
        return 0, 0, mask.shape[1] - 1, mask.shape[0] - 1
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def extend_outward(h, m):
    """Continue `h` smoothly past `m` by diffusion (Laplacian inpainting).

    The obvious alternative — filling the outside with the value of the nearest
    body pixel — is a trap. A nearest-value fill is piecewise constant on the
    Voronoi cells of the boundary, so its seams are long straight discontinuities
    radiating away from every concave notch in the silhouette. They are invisible
    in the height field and lethal in the normal map, where they show up as
    saturated 1-px scratches across the whole tile.

    Blur-and-restore converges to the harmonic extension, which has no seams:
    coarse passes first so distant background gets a sensible value, fine passes
    afterwards so the boundary stays sharp.
    """
    known = h.astype(np.float32) * m
    wt = m.astype(np.float32)
    base = gaussian_filter(known, 48.0) / np.maximum(gaussian_filter(wt, 48.0), 1e-6)
    out = np.where(m, h, base).astype(np.float32)
    for sigma, n in ((16.0, 8), (8.0, 8), (4.0, 6), (2.0, 5), (1.0, 4)):
        for _ in range(n):
            out = gaussian_filter(out, sigma)
            out[m] = h[m]
    return out


# One-octave split of the height field. The coarsest band (everything above
# ~40 px) is the cloud's lobe structure and is what the eye reads first; the
# rest is relief riding on it.
NSIG = (1.2, 2.4, 4.8, 9.6, 19.2, 38.4)


def dog_bands(h, sigmas=NSIG):
    g = [gaussian_filter(h, s) for s in sigmas]
    b = [h - g[0]] + [g[i] - g[i + 1] for i in range(len(sigmas) - 1)] + [g[-1]]
    return b[::-1]                       # coarsest first


def _ladder(ch, mask):
    return np.array([float(np.std(b[mask])) for b in dog_bands(ch)])


def shaped_normal(height, mask, ratio, fine_floor=0.095, coarse_boost=1.0, iters=3):
    """Gradient of `height` with a band amplitude ladder enforced on the OUTPUT.

    THE fix for "sandpaper or blur, pick one". The height field is split into
    one-octave bands and each band's gradient is re-weighted so its amplitude is
    `ratio` times the next-coarser band's; the radial power spectrum of the
    result is then a power law of slope 2*log2(ratio) - 2 (ratio 0.63 -> about
    f^-3.3, where the reference art sits) whatever the raymarch produced.

    The re-weighting alone is not enough, and that is the difference between this
    and the previous version. Normalising each band's gradient assumes the
    gradient of band j lands in band j, which difference-of-gaussians bands only
    roughly do — the leakage biased the realised ladder flat at the coarse end
    (measured 0.78 per octave where 0.63 was asked for), which is exactly the
    "large-scale gradient too weak, neither scale reads" complaint. So the
    ladder is MEASURED on the assembled nx/ny and the weights corrected. Two
    passes converge, and the guarantee is then on the thing the eye and the
    profile both look at rather than on an intermediate.

    `fine_floor` stops the ladder below ~10 % of the coarsest band: the
    reference's finest octave sits at 0.11 of its coarsest, not at 0.63^6, and
    driving a band below the 8-bit quantum only spends file size on dither.
    """
    bands = dog_bands(height)
    gx, gy = [], []
    for b in bands:
        by, bx = np.gradient(b)
        gx.append(bx)
        gy.append(by)
    nb = len(bands)
    want_rel = np.maximum(ratio ** np.arange(nb), fine_floor)
    # The coarsest band gets a thumb on the scale, and it earns it. A clean
    # geometric ladder in THESE bins does not come out as a clean ladder when
    # re-measured on octave boundaries half a step away: band 0 spans everything
    # above ~280 px and spills half its energy into the next bin down, so the
    # realised coarse ratio lands near 0.84 where 0.63 was asked for. That is
    # the "large-scale gradient too weak" reading exactly — the lobes lose to
    # the 20-50 px relief riding on them, and the normal map goes chunky.
    want_rel[0] *= coarse_boost
    w = want_rel / np.array(
        [max(float(np.std(np.hypot(gx[i][mask], gy[i][mask]))), 1e-12)
         for i in range(nb)]
    )
    nx = ny = None
    for it in range(iters):
        nx = sum(w[i] * gx[i] for i in range(nb))
        ny = sum(w[i] * gy[i] for i in range(nb))
        if it == iters - 1:
            break
        got = 0.5 * (_ladder(nx, mask) + _ladder(ny, mask))
        w = w * np.clip(got[0] * want_rel / np.maximum(got, 1e-12), 0.25, 4.0)
    return nx, ny


def assemble(rng, f, p, meta):
    """Turn the marched fields into the four stored channels + the normal."""
    tau = up(f["tau"])
    surf = up(f["surf"])
    glow = up(f["glow"])
    body_v = up(f["body"].astype(np.float32), order=1) > 0.5

    # --- coverage ----------------------------------------------------------
    # Normalise the peak optical depth rather than the peak alpha: alpha
    # saturates, so scaling it cannot control how much of the cloud sits in the
    # [0.98, 1] bin. The reference art puts under 1% of its tile there.
    hi = float(np.percentile(tau, 99.85))
    tau = tau * (p["tau_peak"] / max(hi, 1e-6))

    # Full-resolution crenellation of the SILHOUETTE. The volume is marched at
    # half the sprite's resolution and then cubic-upsampled, so the boundary it
    # produces is a smooth ramp: side by side with the reference at 1:1 the
    # difference is not subtle, because a real cumulus edge is a row of little
    # cauliflower puffs 5-15 px across, not a blur.
    #
    # Optical depth decays as exp(F/s) outside the surface, so multiplying it by
    # exp(k * detail) TRANSLATES the boundary by k*detail*s — about +-7 px here —
    # which buys silhouette detail at full resolution for one 2-D field.
    #
    # The gate protects the CORE and nothing else. Because tau decays
    # exponentially outside the surface, multiplying it by exp(k*det) is a pure
    # translation of the boundary — uniform in distance across the whole tail —
    # so the tail wants the displacement at full strength; it is only the
    # saturated interior that must be held out, and `1/(1+(tau/t0)^2)` does
    # exactly that. Leaving the gate out is instructive: the same factor then
    # applies at tau=8 in the core, a -3 sigma excursion takes that to tau=0.3,
    # and the cloud comes out as lace — the popcorn-coverage failure, arrived at
    # from a completely different direction. Confining it the other way, to a
    # band around tau~1, leaves the outer isophotes undisplaced and the cloud
    # silhouettes as a smooth oval with a scalloped ghost inside it.
    #
    # The displacement field is BAND-LIMITED after rectification, and that step
    # is not cosmetic. sqrt(n^2 + soft^2) is what makes the field's peaks round
    # like cauliflower, but rectifying a 50-px octave also manufactures harmonics
    # at 25, 16, 12 px, and those harmonics displace the boundary too — into a
    # mat of 5-px curls. A reference cumulus edge is scallops 20-60 px across
    # with nothing finer; one blur is the difference between scallops and fur.
    gate = gaussian_filter(1.0 / (1.0 + (tau / p["edge_gate"]) ** 2), 2.0)
    det = gaussian_filter(billow2(rng, p["edge_lam"], 2, 0.40), p["edge_blur"])
    det = np.clip(det / max(float(det.std()), 1e-9), -2.0, 2.0)
    # Asymmetric on purpose. A symmetric displacement is as likely to pull the
    # boundary IN as push it out, and pulling in where coverage is still 0.4
    # opens a dark pocket just inside the rim: the silhouette comes out as a
    # sponge. Cauliflower is the other shape — bulges that stick out, separated
    # by shallow crevices — so the inward half is compressed to a third.
    det = np.where(det > 0.0, det, det * 0.32)
    tau *= np.exp(p["edge_detail"] * gate * (det - float(det.mean())))
    cov = 1.0 - np.exp(-tau)

    # Fine density texture on the face of the cloud. The volume is marched at
    # half the sprite's resolution and, more importantly, `1 - exp(-tau)` has a
    # derivative of only 0.05 once tau passes 3 — so a core that is physically
    # lumpy still bakes out flat. This is the sub-voxel variation the transfer
    # function swallowed, put back where the eye and `dens_cov_hp_std_thick`
    # both look for it.
    #
    # It is deliberately WEAK, COARSE, and — the part that matters — confined to
    # a MID-coverage window that closes again before full opacity. Pull up a
    # reference core at 1:1 and it is flat 255 over hundreds of pixels; any grain
    # that survives to cov=1 reads as grey mottle where the reference is clean,
    # and it passes `dens_cov_hp_std_thick` while doing so. Coverage is the one
    # channel where the eye notices texture the metric tolerates.
    grain = spec2(rng, p["grain_lam"], 3, 0.55) - 0.5
    # Where the grain bites is class-dependent. On a cumulus it must stay off
    # the 0.1-0.9 rim, or it inflates the edge gradient past the acceptance
    # bound; on a torn veil almost nothing is above 0.5, so the same window
    # would switch the grain off entirely and leave the sheet glassy.
    window = np.clip((cov - p["grain_a"]) / p["grain_b"], 0.0, 1.0) * np.clip(
        (p["grain_c"] - cov) / 0.22, 0.0, 1.0
    )
    cov *= 1.0 + p["grain"] * grain * window
    cov = np.clip(cov, 0.0, 1.0)
    # Kill the far field so the encoder has large constant regions to spend
    # nothing on, and so the tile corners read a clean zero.
    cov[cov < p["cov_floor"]] = 0.0

    ext = cov >= 0.05
    if ext.sum() < 500:
        raise RuntimeError("cloud vanished")

    # --- R: depth from the silhouette edge ---------------------------------
    # A normalised interior distance, not a power of the optical depth. The
    # shader erodes low-depth pixels and sweeps the deck reveal through this
    # channel, so it has to stay non-zero out on the feathered rim and rise only
    # about 2x into the core — a `tau ** 2.6` crushes the rim to zero and gives
    # both nothing to read.
    #
    # But an interior distance ALONE is not what this channel is. On a cumulus
    # it is dominated by HEIGHT, not by distance to the outline, and that is a
    # visible difference rather than a statistical one. `clouds.frag` reads it
    # twice — `edge = smoothstep(iEndEdge, iStartEdge, texDepth)` then
    # `alpha = max(alpha*0.5, alpha - edge*edge*0.5)`, and
    # `depthAlpha = clamp(texDepth / iSmooth, 0, 1)` once the deck is revealed —
    # so a low-depth region is a region the shader thins out to half alpha. A
    # distance transform puts that region in a ring around the whole silhouette
    # and the cloud reads as a solid slab with a soft outline. A cumulus wants
    # it along the BASE: a bright condensing crown standing on an evaporating
    # underside that dissolves into the sky. That is what `depth_vert` buys, and
    # the ramp below is the shape of it — flat over the upper two-thirds,
    # decaying to about a fifth at the very bottom.
    din = distance_transform_edt(cov >= 0.32).astype(np.float32)
    dref = max(float(np.percentile(din[din > 0], 96.0)), 4.0)
    u = np.clip(din / dref, 0.0, 1.0) ** 0.85
    # Blend in a smooth function of coverage. On a torn veil the cov>=0.32 mask
    # barely exists, so the distance transform alone leaves the depth channel
    # nearly constant — and a constant channel passes a range check while
    # carrying no information for `calcDepthAlpha` to sweep.
    cs = gaussian_filter(cov, 4.0)
    u = 0.62 * u + 0.38 * np.clip(cs / max(float(np.percentile(cs[ext], 96)), 1e-6),
                                  0.0, 1.0)
    u = gaussian_filter(u, 3.0)
    # Two further terms, coarse and fine: the coarse one keeps depth from being a
    # pure function of coverage (the reference set's depth/coverage correlation
    # runs as low as 0.16), the fine one is the relief `dens_depth_hp_std_thick`
    # measures inside the core. The coarse term is MIXED IN, not merely added. Depth built as a function of
    # coverage plus a small perturbation correlates with coverage at 0.88 on every
    # sprite; the reference set runs 0.16 to 0.89 with a dense median of 0.39,
    # because on a real cloud "how deep am I" and "how opaque is this column" are
    # related but not the same question. `depth_mix` trades one for the other per
    # sprite, which is what puts the set's correlations across a range instead of
    # stacking them all at the top of it.
    ind = spec2(rng, p["depth_ind_lam"], 3, 0.5)
    ind = (ind - float(ind[ext].mean())) / max(float(ind[ext].std()), 1e-6)
    ind = np.clip(0.5 + 0.28 * ind, 0.0, 1.0)
    mix = p["depth_mix"]
    depth = (
        p["depth_lo"]
        + p["depth_hi"] * ((1.0 - mix) * u + mix * ind)
        + p["depth_noise"] * (spec2(rng, 150.0, 3, 0.55) - 0.5)
        + p["depth_grain"] * (spec2(rng, p["depth_grain_lam"], 3, 0.5) - 0.5)
    )
    # The vertical taper. `hgt` is 1 at the crown and 0 at the lowest pixel of
    # the body, measured on the body's own bounding box so a low plate and a
    # tall congestus each get the full ramp. Multiplicative, so every structure
    # the terms above put into the channel survives — only its level is graded.
    ys = np.arange(cov.shape[0], dtype=np.float32)[:, None]
    rows = np.nonzero(ext.any(axis=1))[0]
    y0, y1 = float(rows[0]), float(rows[-1])
    hgt = 1.0 - (ys - y0) / max(y1 - y0, 1.0)
    t = np.clip(hgt / 0.38, 0.0, 1.0)
    ramp = 0.18 + 0.82 * (t * t * (3.0 - 2.0 * t))
    depth *= 1.0 - p["depth_vert"] * (1.0 - ramp)
    depth = np.clip(depth, 0.0, 1.0) * (cov > 0.0)

    # --- G: backness -------------------------------------------------------
    # "How far through to the far side" = the transmittance of the whole
    # column: 1 on a rim you can see straight through, ~0 in a thick core.
    # THAT SIGN IS THE POINT — the shader does
    # `alpha *= smoothstep(1.0, 0.5, texBack)` and derives `backMulti` (the
    # silver lining) from it, so a backness that peaks in the core fades the
    # core and lights the middle of the cloud instead of its edge.
    # A plain exp(-tau) transmittance is right in spirit but collapses to zero
    # over most of the body, leaving `back_std_ext` far below the reference
    # 0.075-0.151. A gentle power of the normalised column depth keeps the
    # channel spread across its range while preserving the sign.
    thin = 1.0 - np.clip(tau / max(p["tau_peak"], 1e-6), 0.0, 1.0) ** p["back_pow"]
    thin = gaussian_filter(thin, 3.0)
    # A minority of sprites lean the other way — the reference set's dense
    # sprites run -0.78..+0.54 and its veils are strongly positive, since a
    # veil IS its own far side.
    field = thin if p["back_mix"] < 0.5 else 1.0 - thin
    # Blend in an independent lobe-scale field. A pure function of column depth
    # correlates with coverage at |0.95| whichever way it is signed, and the
    # reference's dense sprites sit at -0.78..+0.54 — strongly signed but never
    # a copy. This is the term that separates "backness follows thickness" from
    # "backness IS thickness".
    fi = spec2(rng, p["back_ind_lam"], 3, 0.5)
    fi = np.clip(0.5 + 0.30 * (fi - float(fi[ext].mean()))
                 / max(float(fi[ext].std()), 1e-6), 0.0, 1.0)
    field = (1.0 - p["back_ind"]) * field + p["back_ind"] * fi
    back = p["back_lo"] + p["back_hi"] * field
    back += p["back_noise"] * (spec2(rng, 120.0, 4, 0.55) - 0.5)
    back = np.clip(back, 0.0, 1.0) * (cov > 0.0)

    # --- B: inner glow -----------------------------------------------------
    # Lightning lighting the cloud from within: pools of illumination, not a
    # copy of coverage. `smoothstep(0.05, 1.0, texInner)` gates it, so the p99
    # has to reach ~0.3-0.6 or the flash never shows.
    gl = glow / max(float(np.percentile(glow, 99.5)), 1e-6)
    pocket = spec2(rng, 130.0, 4, 0.5) ** 2.6
    # The mask saturates well below full opacity on purpose: multiplying by
    # coverage itself makes the glow a copy of the alpha channel (correlation
    # 0.88 against the reference's 0.06-0.75) and no lightning reads as coming
    # from inside anything.
    lit = np.clip((gaussian_filter(gl, 6.0) - 0.008) / 0.055, 0.0, 1.0)
    # A whisper of coverage dependence: with none at all the correlation can go
    # NEGATIVE on a small torn sprite, and glow that avoids the cloud is as
    # wrong as glow that copies it.
    inner = (0.06 + 1.10 * pocket) * lit * (0.66 + 0.34 * np.clip(cov * 4.5, 0, 1))
    inner = gaussian_filter(inner, 2.5)
    inner = inner / max(float(np.percentile(inner[ext], 99.0)), 1e-6)
    # Centre the glow vertically. The pockets are a random field, so left alone
    # their centroid wanders tens of pixels either way; the reference glow sits
    # within +-6 % of the cloud's own centroid (and, in the cumulus, a shade
    # ABOVE it — lightning lights the body, not the base). Solve for the single
    # exponential tilt that puts it there rather than hoping.
    yy = np.linspace(0.0, 1.0, TILE_H, dtype=np.float32)[:, None]
    com = float((cov * yy).sum() / max(cov.sum(), 1e-9))
    ys = np.arange(TILE_H, dtype=np.float32)[:, None]
    com_px = com * TILE_H
    x0, y0, x1, y1 = bbox_of(cov >= 0.5)
    target = com_px - p["inner_bias"] * (y1 - y0 + 1)
    lo, hi = -0.06, 0.06
    for _ in range(22):
        lam = 0.5 * (lo + hi)
        w = inner * np.exp(-lam * (ys - com_px))
        gy = float((w * ys)[ext].sum() / max(float(w[ext].sum()), 1e-9))
        if gy > target:
            lo = lam            # tilt harder toward the top
        else:
            hi = lam
    inner = inner * np.exp(-0.5 * (lo + hi) * (ys - com_px))
    inner *= p["inner_gain"] / max(float(np.percentile(inner[ext], 99.0)), 1e-6)
    inner = np.clip(inner, 0.0, 1.0) * (cov > 0.0)

    # --- normal map --------------------------------------------------------
    # TWO SCALES, BUILT SEPARATELY. Coverage above came from the full-detail
    # field so the silhouette stays cauliflower; the normal is built from a
    # deliberately SMOOTHED height, with relief added back as its own term.
    #
    # The coarse height is a dome per lobe, mixed from two sources because
    # neither alone is enough:
    #   `front`  the marched first-scatter depth. It domes over every lobe, so
    #            it carries the crown's internal structure — but it is the
    #            expectation of almost nothing out in the tail, so it has to be
    #            trusted only inside the body and diffused outward from there.
    #   `thick`  a blurred coverage. Its gradient is the OUTWARD normal of the
    #            whole mass: up at the crown, down under the base, out at the
    #            flanks. That is the big saturated colour field the reference
    #            has and a raw surface gradient does not, and it is also what
    #            draws the bright crenellated rim around the silhouette.
    solid = gaussian_filter(cov, 2.0) >= 0.30
    solid &= body_v
    if solid.sum() < 400:
        solid = cov >= 0.15
    front = 1.0 - extend_outward(np.clip(surf, 0.0, 1.0), solid)
    front = gaussian_filter(front, p["dome_sig"])
    # Two blurs, not one. The tighter one carries per-lobe doming; the wide one
    # is the whole cloud's own dome, and it is what puts real amplitude above
    # 300 px — the band the reference art leads with (its coarsest octave is
    # 1.6x its next, where a single 12-px blur gives 1.2) and the band that makes
    # a normal map read as one lit solid instead of a field of separate bumps.
    thick = gaussian_filter(np.clip(cov, 0.0, 1.0) ** 0.65, p["dome_sig"] * 1.5)
    thick = thick + 1.35 * gaussian_filter(np.clip(cov, 0.0, 1.0) ** 0.65, 40.0)

    core = gaussian_filter(cov, 2.0) > 0.25
    if core.sum() < 400:
        core = ext

    def znorm(a):
        return (a - float(a[core].mean())) / max(float(a[core].std()), 1e-9)

    dome = p["dome_mix"] * znorm(front) + (1.0 - p["dome_mix"]) * znorm(thick)

    # Fine relief: an independent cauliflower field, not a residual of the
    # march. Modulated by a smooth body mask so the empty tile stays flat, and
    # slightly stronger where the cloud faces the viewer, as real cauliflower is.
    mrel = np.clip((gaussian_filter(cov, 6.0) - 0.05) / 0.35, 0.0, 1.0)
    relief = billow2(rng, p["relief_lam"], 5, 0.45) * (0.30 + 0.70 * mrel)
    height = dome + p["relief"] * relief

    nx, ny = shaped_normal(height, core, p["band_ratio"], p["fine_floor"],
                           p["coarse_boost"])

    # `height` rises toward the viewer, so the outward normal is
    # (-dh/dx_world, -dh/dy_world). Row index runs DOWN the image while world y
    # runs up, so the y term flips sign a second time and comes out positive.
    # Getting that one sign wrong is not subtle and not caught by any metric in
    # the profile: it turns the cloud inside out, lighting the base and
    # shadowing the crown, and on a contact sheet it shows as magenta on top of
    # green where the reference is green on top of magenta.
    nx = -nx

    # Saturate, the way a real surface normal saturates. A raw gradient has
    # Gaussian-or-worse tails: the reference's |nx| p99 is 2.0 sigma, a plain
    # band-weighted gradient measures 3.2 — a pale field with hot specks in it,
    # which is precisely how the earlier normal maps read. Dividing by
    # sqrt(1 + |n|^2) is the same map that turns a height gradient into a unit
    # normal; it compresses the specks and fills the mid-range, giving the broad
    # saturated colour fields the reference has.
    sd = float(np.std(np.stack([nx[core], ny[core]])))
    nx /= max(sd, 1e-9)
    ny /= max(sd, 1e-9)
    c = p["sat"]
    damp = 1.0 / np.sqrt(1.0 + (nx * nx + ny * ny) / (c * c))
    nx *= damp
    ny *= damp
    sd = float(np.std(np.stack([nx[ext], ny[ext]])))
    gain = p["nrm_xy"] / max(sd, 1e-9)
    nx = np.clip(nx * gain, -0.98, 0.98)
    ny = np.clip(ny * gain, -0.98, 0.98)

    # z: the reference stores an un-normalised normal, so z is a free scalar that sets
    # how strongly the surface tilts. Derive it from local flatness — high where
    # the surface faces the viewer, low on steep rims — then map it through a
    # rank transform onto a Gaussian with the target mean and spread. Fitting
    # mean and std directly instead leaves the shape of `flat`, which is skewed,
    # and lands nrm_z_p99 at 0.25 against a reference 0.36. `mapN.z =
    # max(mapN.z, 0.08)` in the shader flattens any pixel that lands negative,
    # so the negative tail is kept small on the dense sprites.
    slope = gaussian_filter(np.hypot(nx, ny), 4.0)
    flat = 1.0 / np.sqrt(1.0 + (slope * 2.4) ** 2)
    nz = np.zeros_like(flat)
    vals = flat[ext]
    order = np.argsort(vals, kind="stable")
    ranks = np.empty(vals.size, dtype=np.float32)
    ranks[order] = (np.arange(vals.size, dtype=np.float32) + 0.5) / vals.size
    nz[ext] = p["nrm_z_mean"] + p["nrm_z_std"] * ndtri(
        np.clip(ranks, 1e-4, 1 - 1e-4)
    ).astype(np.float32)
    nz = np.clip(nz, -0.42, 0.75)

    # Fade the normal to flat grey at the visible edge. Narrow on purpose: the
    # reference keeps its normal saturated right out to the silhouette and drops
    # to grey there, and that bright crenellated outline is a large part of what
    # makes it read as a lit solid. The mask is keyed to a blurred coverage so it
    # cannot inherit every detached speck in the halo and multiply that structure
    # into nx/ny, which would land squarely in the sub-16-px band the sandpaper
    # gate measures.
    vis = np.clip((gaussian_filter(cov, 1.4) - 0.012) / 0.055, 0.0, 1.0)
    vis = gaussian_filter(vis, 1.1)
    nx *= vis
    ny *= vis
    nz *= vis

    return {
        "cov": cov,
        "depth": depth,
        "back": back,
        "inner": inner,
        "normal": np.stack([nx, ny, nz], axis=-1),
    }


# --------------------------------------------------------------------------
# per-sprite parameters
# --------------------------------------------------------------------------
def draw_params(rng, spec, meta):  # noqa: C901
    """Everything that varies sprite to sprite.

    The profile's variety gate is not satisfied by re-seeding noise: it measures
    the spread of aspect, lobe count, edge width, halo mass, normal roughness
    and normal wavelength across the set. So each of those has its own drawn
    parameter here, not a shared constant.
    """
    veil = meta["veil"]
    over = spec[7]
    solid = bool(over.get("solid", 0))
    p = {
        "warp": float(rng.uniform(0.09, 0.17)),
        "warp_freq": float(rng.uniform(0.55, 0.95)),
        "shear": float(rng.uniform(0.5, 1.3)) if veil else float(rng.uniform(-0.22, 0.22)),
        "blend": float(rng.uniform(0.17, 0.24)),
        "base_blend": float(rng.uniform(0.07, 0.13)),
        "base_wobble": float(rng.uniform(0.13, 0.24)),
        "erode_freq": float(rng.uniform(2.6, 4.0)),
        "erode": float(rng.uniform(0.24, 0.34)),
        "shell_w": float(rng.uniform(0.07, 0.12)),
        "inner_freq": float(rng.uniform(0.8, 1.6)),
        "inner_amp": float(rng.uniform(0.24, 0.44)),
        "tear_freq": float(rng.uniform(3.4, 4.6)),
        "tear_reach": float(rng.uniform(2.0, 2.8)),
        "tear_cut": float(rng.uniform(0.34, 0.48)),
        "tear_in": float(rng.uniform(0.0, 0.05)),
        "tear_ax": float(rng.uniform(1.2, 1.8)),
        "tear_crown": float(rng.uniform(0.18, 0.34)),
        # How much longer the base's exponential tail is than the crown's.
        # The reference art's crown edges are ~4 px and its bases 30+, so the
        # ratio wants to be several-fold, not the 1.8x an earlier value gave.
        # This is the broad soft apron a cumulus stands on, and it is what
        # the depth channel's vertical taper then fades out — the two terms
        # are the same feature seen from the silhouette and from the shading.
        "base_soft": float(rng.uniform(1.05, 2.05)),
        "sigma_e": 1.0,
        "grain": float(rng.uniform(0.090, 0.125)),
        "grain_lam": float(rng.uniform(34.0, 52.0)),
        "grain_a": 0.42,
        "grain_b": 0.30,
        "grain_c": 1.13,
        "cov_floor": 0.0095,
        "edge_detail": float(rng.uniform(0.90, 1.15)),
        "edge_lam": float(rng.uniform(46.0, 66.0)),
        "edge_gate": float(rng.uniform(1.00, 1.55)),
        "edge_blur": float(rng.uniform(2.6, 3.8)),
        # How much of the depth channel is graded by height rather than by
        # distance to the outline. A cumulus is nearly all height (its base
        # evaporates, so the shader's erosion band belongs there); a shredded
        # fractus or a stratocumulus deck has no single base to fade and keeps
        # the distance reading. Overridden per family below.
        "depth_vert": float(rng.uniform(0.80, 0.95)),
        "depth_lo": float(rng.uniform(0.085, 0.135)),
        "depth_mix": float(rng.uniform(0.12, 0.58)),
        "depth_ind_lam": float(rng.uniform(90.0, 170.0)),
        "depth_grain_lam": float(rng.uniform(54.0, 76.0)),
        # Sized so the body's plateau lands near 0.30. `clouds.frag` erodes
        # everything under `iEndEdge` = 0.23 and scales alpha by
        # `texDepth / iSmooth` = /0.35, so a channel that plateaus at 0.40 is
        # one the erosion never reaches and the reveal saturates — the cloud
        # comes out uniformly opaque with a hard outline. The reference set
        # plateaus at 0.31 and puts 41 % of its body inside the band.
        "depth_hi": float(rng.uniform(0.33, 0.42)),
        "depth_noise": float(rng.uniform(0.16, 0.26)),
        "depth_grain": float(rng.uniform(0.10, 0.15)),
        # Placed so the channel spans the reference's operating band. What the
        # shader makes of backness is
        # `backMulti = smoothstep(0.05, 1, mix(1 - iCloudDepth, 1, texBack))`,
        # which drives the base colour gain from 1.17x to the 1.8 ceiling — so
        # backness IS the silver lining, and its SPAN is the lining's contrast.
        # A channel bunched around its middle lights the whole cloud evenly and
        # the rim stops reading as a rim. Kept below 0.5 at p98 on the dense
        # families, since past that `alpha *= smoothstep(1, 0.5, texBack)`
        # starts eating the cloud itself — which is a thing veils do and
        # cumulus do not.
        "back_lo": float(rng.uniform(0.00, 0.05)),
        "back_hi": float(rng.uniform(0.44, 0.64)),
        "back_pow": float(rng.uniform(0.55, 0.95)),
        "back_noise": float(rng.uniform(0.07, 0.13)),
        "back_ind": float(rng.uniform(0.30, 0.56)),
        "back_ind_lam": float(rng.uniform(90.0, 180.0)),
        # <0.5 = backness is inverse to thickness (the reading the shader
        # needs); >0.5 flips it. Drawn away from the middle so both modes keep
        # a full spread — a half-and-half blend would flatten the channel.
        "back_mix": 0.0 if rng.random() < 0.68 else 1.0,
        "inner_gain": float(rng.uniform(0.40, 0.54)),
        "inner_bias": float(rng.uniform(-0.010, 0.045)),
        # normal-map shaping
        "dome_sig": float(rng.uniform(6.0, 10.0)),
        "dome_mix": float(rng.uniform(0.46, 0.66)),
        "relief": float(rng.uniform(0.26, 0.38)),
        "relief_lam": float(rng.uniform(46.0, 72.0)),
        "band_ratio": float(rng.uniform(0.53, 0.60)),
        "fine_floor": float(rng.uniform(0.030, 0.075)),
        "coarse_boost": float(rng.uniform(1.24, 1.48)),
        "sat": float(rng.uniform(1.35, 1.75)),
        "nrm_xy": float(rng.uniform(0.18, 0.28)),
        "nrm_z_mean": float(rng.uniform(0.10, 0.19)),
        "nrm_z_std": float(rng.uniform(0.085, 0.155)),
    }
    if veil:
        p.update(
            tail=float(rng.uniform(0.075, 0.100)),
            tear_lo=0.0,
            tear_hi=float(rng.uniform(1.9, 2.6)),
            tear_cut=float(rng.uniform(0.60, 0.70)),
            tear_in=float(rng.uniform(0.72, 1.0)),
            tear_reach=float(rng.uniform(1.2, 2.0)),
            tear_freq=float(rng.uniform(4.0, 6.0)),
            tear_crown=1.0,
            base_soft=float(rng.uniform(0.10, 0.40)),
            tear_ax=float(rng.uniform(3.0, 4.5)),
            erode=float(rng.uniform(0.24, 0.38)),
            base_wobble=float(rng.uniform(0.04, 0.10)),
            back_lo=float(rng.uniform(0.10, 0.16)),
            back_hi=float(rng.uniform(0.36, 0.50)),
            depth_vert=float(rng.uniform(0.20, 0.34)),
            depth_hi=float(rng.uniform(0.50, 0.62)),
            inner_bias=float(rng.uniform(-0.03, 0.02)),
            depth_grain=float(rng.uniform(0.15, 0.21)),
            depth_noise=float(rng.uniform(0.14, 0.22)),
            grain=float(rng.uniform(0.34, 0.48)),
            grain_lam=float(rng.uniform(24.0, 34.0)),
            grain_a=0.03,
            grain_b=0.22,
            grain_c=1.30,
            cov_floor=0.0045,
            edge_detail=float(rng.uniform(0.30, 0.46)),
            edge_lam=float(rng.uniform(34.0, 52.0)),
            edge_gate=float(rng.uniform(0.30, 0.55)),
            edge_blur=float(rng.uniform(1.6, 2.6)),
            inner_gain=float(rng.uniform(0.44, 0.58)),
            tau_peak=float(rng.uniform(0.95, 1.25)),
            back_mix=1.0,
            blend=float(rng.uniform(0.10, 0.16)),
            dome_sig=float(rng.uniform(4.0, 6.5)),
            dome_mix=float(rng.uniform(0.20, 0.40)),
            band_ratio=float(rng.uniform(0.66, 0.72)),
            fine_floor=float(rng.uniform(0.09, 0.15)),
            coarse_boost=float(rng.uniform(1.05, 1.25)),
            sat=float(rng.uniform(1.5, 2.0)),
            nrm_xy=float(rng.uniform(0.15, 0.21)),
            nrm_z_mean=float(rng.uniform(0.004, 0.020)),
            nrm_z_std=float(rng.uniform(0.014, 0.030)),
            relief=float(rng.uniform(0.34, 0.50)),
            relief_lam=float(rng.uniform(26.0, 40.0)),
        )
    elif solid:
        # A near-opaque cumulus: high optical depth and a narrow skirt. Two of
        # the nine reference cumulus are like this, and without them the set has
        # no spread in edge softness or mean coverage at all.
        p.update(
            tail=float(rng.uniform(0.020, 0.028)),
            tau_peak=float(rng.uniform(5.5, 8.0)),
            tear_lo=float(rng.uniform(0.14, 0.26)),
            tear_hi=float(rng.uniform(0.95, 1.20)),
            tear_reach=float(rng.uniform(1.6, 2.4)),
        )
    else:
        p.update(
            tail=float(rng.uniform(0.028, 0.039)),
            tau_peak=float(rng.uniform(3.4, 5.2)),
            tear_lo=float(rng.uniform(0.12, 0.24)),
            tear_hi=float(rng.uniform(1.00, 1.30)),
        )
    # Family overrides last: this is where the set is tuned as a set.
    for key, val in over.items():
        if key in ("solid", "nbody"):
            continue
        p[key] = float(rng.uniform(*val)) if isinstance(val, tuple) else float(val)
    return p


# --------------------------------------------------------------------------
# packing
# --------------------------------------------------------------------------
def to_image(ch):
    """Pack into the 512x576 two-part sprite (see the contract at the top)."""
    cov = ch["cov"]
    h, w = cov.shape
    top = np.zeros((h, w, 4), dtype=np.uint8)
    # The normal map is about half the file. Rounding it to even codes drops
    # ~8 % of the whole set's bytes. Safe because the shader magnifies the
    # sprite ~2.7x through its own bilinear tap (`sampleSprite`), which
    # interpolates the 2/255 steps back into a continuous ramp, and because the
    # normal is un-normalised — only the xy:z RATIO is used, so a common step
    # cancels.
    nq = np.clip(np.rint((ch["normal"] * 0.5 + 0.5) * 127.5), 0, 127).astype(np.uint8)
    top[..., :3] = nq * 2
    top[..., 3] = 255           # premultiply must be a no-op on the normal
    bot = np.zeros((h, w, 4), dtype=np.uint8)
    bot[..., 0] = np.clip(np.rint(ch["depth"] * 255.0), 0, 255).astype(np.uint8)
    bot[..., 1] = np.clip(np.rint(ch["back"] * 255.0), 0, 255).astype(np.uint8)
    bot[..., 2] = np.clip(np.rint(ch["inner"] * 255.0), 0, 255).astype(np.uint8)
    bot[..., 3] = np.clip(np.rint(cov * 255.0), 0, 255).astype(np.uint8)
    return Image.fromarray(np.concatenate([top, bot], axis=0), "RGBA")


def save(img, path):
    """Lossless WebP. The lower half's four channels are independent scalar
    fields — a lossy codec corrupts depth, backness and coverage, and the shader
    divides RGB by coverage, which amplifies any error it introduces."""
    img.save(path, "WEBP", lossless=True, quality=100, method=6, exact=True)


# --------------------------------------------------------------------------
# sheets
# --------------------------------------------------------------------------
def contact_sheet(paths, out, scale=0.42):
    """All sprites across: coverage on top, normal map below."""
    pw, ph = int(TILE_W * scale), int(TILE_H * scale)
    pad, lab = 6, 14
    n = len(paths)
    W = pad + n * (pw + pad)
    H = 22 + lab + ph + 4 + ph + pad
    sheet = Image.new("RGB", (W, H), (20, 24, 32))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 5), "generated cloud sprites — coverage (top) / normal map (bottom)",
           fill=(190, 200, 215))
    for i, path in enumerate(paths):
        a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255.0
        nrm, bot = a[:TILE_H], a[TILE_H:]
        cov = bot[..., 3]
        slate = np.array([20.0, 24.0, 32.0])
        sil = slate[None, None, :] * (1 - cov[..., None]) + 255.0 * cov[..., None]
        x = pad + i * (pw + pad)
        sheet.paste(Image.fromarray(sil.astype(np.uint8), "RGB").resize((pw, ph),
                    Image.LANCZOS), (x, 22 + lab))
        sheet.paste(Image.fromarray((nrm[..., :3] * 255).astype(np.uint8), "RGB")
                    .resize((pw, ph), Image.LANCZOS), (x, 22 + lab + ph + 4))
        d.text((x, 22), "%s %.0fkB" % (os.path.basename(path), os.path.getsize(path) / 1024),
               fill=(150, 165, 185))
    sheet.save(out)
    return out


def compare_sheet(ref_path, mine_path, out):
    """One reference sprite beside one of ours: coverage and normal, same scale.

    For visual comparison only — the reference is never read at generation time.
    """
    scale = 0.72
    pw, ph = int(TILE_W * scale), int(TILE_H * scale)
    pad = 10
    sheet = Image.new("RGB", (pad + 2 * (pw + pad), 40 + 2 * (ph + pad)), (20, 24, 32))
    d = ImageDraw.Draw(sheet)
    d.text((pad, 6), "left: the reference reference (comparison only)    right: generated original",
           fill=(190, 200, 215))
    for col, path in enumerate((ref_path, mine_path)):
        a = np.asarray(Image.open(path).convert("RGBA")).astype(np.float32) / 255.0
        nrm, bot = a[:TILE_H], a[TILE_H:]
        cov = bot[..., 3]
        slate = np.array([20.0, 24.0, 32.0])
        sil = slate[None, None, :] * (1 - cov[..., None]) + 255.0 * cov[..., None]
        x = pad + col * (pw + pad)
        sheet.paste(Image.fromarray(sil.astype(np.uint8), "RGB").resize((pw, ph),
                    Image.LANCZOS), (x, 24))
        sheet.paste(Image.fromarray((nrm[..., :3] * 255).astype(np.uint8), "RGB")
                    .resize((pw, ph), Image.LANCZOS), (x, 24 + ph + pad))
        d.text((x, 24 + ph + 1), os.path.basename(path), fill=(150, 165, 185))
    sheet.save(out)
    return out


# --------------------------------------------------------------------------
def render_one(seed, spec):
    rng = np.random.default_rng(seed)
    blobs, pend, meta = build_shape(rng, spec)
    p = draw_params(rng, spec, meta)
    f = march(rng, blobs, pend, meta, p)
    return assemble(rng, f, p, meta)


# Which archetype fills each sprite slot.
#
# The slot index is not cosmetic. `sky_clouds.dart`'s layouts pick sprites by
# index — `fair` uses 0/2/4, `scattered` 0-4, `overcast` 0/3/8/9/10 and `rain`
# 3/8/9/10/11 — so slots 0..4 have to be well-formed standalone cumulus and
# 8..11 the wide decks and broken clusters a rain sky is built from. Slots 5..7
# are referenced by no layout at all, which is where the torn veils park: they
# cost 50 kB each and nothing draws them, but dropping them would renumber
# everything above and silently rewrite every deck.
SLOT_ARCHETYPE = (0, 1, 2, 3, 8, 9, 10, 11, 4, 5, 6, 7)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out", default="assets/weather/clouds")
    ap.add_argument("--count", type=int, default=12)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--start", type=int, default=0)
    ap.add_argument("--sheet", default=None)
    ap.add_argument("--compare", default=None,
                    help="REF_SPRITE:OUT_PNG — side-by-side with one reference")
    args = ap.parse_args()

    os.makedirs(args.out, exist_ok=True)
    paths = []
    for i in range(args.start, args.start + args.count):
        spec = ARCHETYPES[SLOT_ARCHETYPE[i % len(SLOT_ARCHETYPE)]]
        t0 = time.time()
        ch = render_one(args.seed * 1000003 + SLOT_ARCHETYPE[i % 12] * 7919, spec)
        path = os.path.join(args.out, "%02d.webp" % i)
        save(to_image(ch), path)
        paths.append(path)
        print("%-22s %-11s %7d B  %5.1fs"
              % (os.path.basename(path), spec[0], os.path.getsize(path), time.time() - t0))

    total = sum(os.path.getsize(p) for p in paths)
    print("total %d B (%.3f MB)" % (total, total / 1e6))

    if args.sheet:
        print("wrote", contact_sheet(sorted(paths), args.sheet))
    if args.compare:
        ref, outp = args.compare.split(":")
        print("wrote", compare_sheet(ref, sorted(paths)[0], outp))


if __name__ == "__main__":
    main()
