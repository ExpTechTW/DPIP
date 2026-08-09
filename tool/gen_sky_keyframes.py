#!/usr/bin/env python3
"""Generate the sky's keyframe rings as a Dart source file.

WHAT A KEYFRAME IS
------------------
The sky is not simulated per frame. Two lookup tables are baked whenever the
weather or the time slot changes (`shaders/sky/transmittance.frag` then
`sky_lut.frag`), and the screen pass just reads them. A keyframe is the set of
inputs to that bake: where the sun is, how bright it is, and what the air is
made of. `sky_keyframe.dart` holds the contract; this file holds the content.

Clear and cloudy skies carry a full 17-point ring around the day. Everything
else carries four points — night, day, day, night — because a thick deck
flattens the sky into something that barely changes with the sun, and four
points say that more honestly than seventeen near-identical ones would.

HOW THE NUMBERS ARE ARRIVED AT
------------------------------
Nothing here is hand-typed per keyframe. Each weather type declares its
*intent* — how much haze, how damp, how much dust, how much light gets through
— and the medium is derived from that:

  * The **dry baseline** is the standard Earth atmosphere from Hillaire, "A
    Scalable and Production Ready Sky and Atmosphere Rendering Technique"
    (EGSR 2020): Mie scattering 3.996e-6 /m, Mie absorption 4.4e-6 /m, aerosol
    scale height 1200 m. The Rayleigh coefficients and the planet radii are the
    same paper's and live in `SkyConstants`.
  * **Haze and dust** multiply the aerosol terms. Haze scatters far more than
    it absorbs, which is why fog is bright; dust does the reverse, which is why
    a sand sky is dim and brown.
  * **Dampness** lifts the aerosol layer (`mieHeight`) and, in this shader,
    `rayleighHeight` — which is the knob that decides how much blue survives to
    the top of the frame rather than being a physical scale height. It is named
    for what it does here, not for the atmosphere.
  * The **sun's elevation** is a sine over the daylight half of the ring. It is
    the sky LUT's u coordinate directly (`sunAngleY = elevation / 180`), since
    the LUT's u axis sweeps the sun from one horizon to the other.

`sunIntensity` is deliberately NOT proportional to elevation: it carries a
dawn/dusk boost, because the interesting sky is the low-sun one and a straight
`sin(elevation)` makes it the dullest moment of the day.

Run: `python3 tool/gen_sky_keyframes.py > <dart file>` then `dart format`
(no dependencies). The generator does not try to match dartfmt itself.
"""

import math
import sys

# --- the dry baseline -------------------------------------------------------
MIE_SCATTER_DRY = 3.996e-6
MIE_ABSORB_DRY = 4.4e-6
MIE_HEIGHT_DRY = 1200.0
# What `rayleighHeight` means here: how far up the blue survives. The clear-sky
# value is the real scale height; the rest of the range is art direction.
RAYLEIGH_HEIGHT_CLEAR = 8000.0

# --- the day ----------------------------------------------------------------
RING = 17                 # keyframes in a full-day ring
DAY_START, DAY_END = 4, 12   # indices the sun is above the horizon between
PEAK_ELEVATION = 78.0     # degrees at local noon
TWILIGHT_ELEVATION = 2.4  # degrees held through the night, so dusk has a floor

# How far the night frames of a four-point ring are dimmed against their day
# frames. The sky is the same sky; only the light changes.
NIGHT_GAIN = 0.38

# Ozone half-thickness (m). Real enough at the clear end; thickening it drains
# the last of the blue, which is what a heavy overcast wants.
OZONE_CLEAR = 20000.0

# Weather types, in the order `weatherKeyframes` publishes them.
#
#   haze   aerosol load that scatters (cloud, fog, spray)
#   dust   aerosol load that absorbs (sand, smog)
#   damp   how far the scattering layer is lifted
#   gain   how much sunlight reaches the top of the atmosphere at all
#   blue   how much of the Rayleigh blue is kept
#   pin    for four-point rings: the elevation the sky is pinned to, degrees
WEATHERS = [
    # name           frames haze  dust  damp  gain  blue  pin
    ("sunny",        RING,  0.00, 0.00, 0.20, 1.00, 1.00, None),
    ("cloudy",       RING,  0.20, 0.00, 0.40, 0.92, 1.05, None),
    ("overcast",     4,     2.60, 0.10, 0.75, 0.80, 1.45, 34.0),
    ("foggy",        4,     1.40, 0.05, 1.00, 1.00, 0.55, 34.0),
    ("smoggy",       4,     2.80, 0.90, 0.55, 0.85, 1.70, 34.0),
    ("rainyLight",   4,     1.00, 0.00, 0.60, 0.95, 1.60, 34.0),
    ("rainyMedium",  4,     1.90, 0.00, 0.60, 0.88, 1.50, 34.0),
    ("rainyHeavy",   4,     2.40, 0.15, 0.60, 0.78, 1.45, 34.0),
    ("rainyExtreme", 4,     0.90, 0.00, 0.60, 0.62, 1.30, 34.0),
    ("snowyLight",   4,     4.00, 0.00, 0.60, 1.05, 0.75, 34.0),
    ("snowyMedium",  4,     4.60, 0.00, 0.60, 0.98, 0.80, 34.0),
    ("snowyHeavy",   4,     4.60, 0.00, 0.60, 0.90, 0.65, 34.0),
    ("sandyHeavy",   4,     6.00, 2.20, 0.10, 1.45, 3.00, 66.0),
    ("sandyLight",   4,     4.00, 0.45, 0.90, 1.30, 2.10, 34.0),
]

# The tonemap `sky_lut.frag` applies inside the bake, as (a, b, c, d, e) in
# `(x*(a*x + b)) / (x*(c*x + d) + e)`. These give `x^2 / (x + 1)`: near-square
# in the shadows so the night sky stays dark, asymptotically linear so a bright
# horizon does not clip.
POST = (1, 0, 0, 0, 1)


def elevation(i, frames, pin):
    """Sun elevation in degrees at ring index [i]."""
    if pin is not None:
        return pin
    if i <= DAY_START or i >= DAY_END:
        # Night. Ease down to the floor and back so dusk is not a step.
        edge = min(abs(i - DAY_START), abs(i - DAY_END), 4) / 4.0
        return TWILIGHT_ELEVATION + (6.0 - TWILIGHT_ELEVATION) * (1.0 - edge) ** 2
    phase = (i - DAY_START) / (DAY_END - DAY_START)
    return max(TWILIGHT_ELEVATION, PEAK_ELEVATION * math.sin(math.pi * phase))


def sun_intensity(elev, gain):
    """Sun radiance multiplier.

    Rises with elevation, but with a dawn/dusk term on top: the low-sun sky is
    the one worth looking at, and a plain `sin(elevation)` makes it the dullest
    part of the day.
    """
    s = math.sin(math.radians(elev))
    low = math.exp(-((elev - 7.0) / 9.0) ** 2)  # peaks just above the horizon
    return round((4.0 + 15.0 * s + 9.0 * low) * gain, 1)


def medium(haze, dust, damp, blue):
    """The five `(dry, wet)` ramps, from one weather's intent."""
    # Haze scatters far more than it absorbs — that is why fog is bright and
    # smog is not.
    scatter = MIE_SCATTER_DRY * (1.0 + 3.2 * haze + 1.2 * dust)
    absorb = MIE_ABSORB_DRY * (1.0 + 0.3 * haze + 5.0 * dust)
    height = MIE_HEIGHT_DRY * (1.0 + 1.2 * damp)
    rayleigh = RAYLEIGH_HEIGHT_CLEAR * blue

    def ramp(dry, wet_factor):
        # Humidity only has room to move on a sky that is not already saturated
        # with water; a rainy ring's two ends are the same number.
        wet = dry * wet_factor if haze < 0.5 else dry
        return (_num(dry), _num(wet))

    return dict(
        humidRayleighHeight=ramp(rayleigh, 0.80),
        humidMieScatter=ramp(scatter, 2.60),
        humidMieAbsorb=ramp(absorb, 1.60),
        humidMieHeight=ramp(height, 1.45),
        # Aerosols scatter forward; the clear sky's remaining haze barely does.
        humidMieAsymmetry=(_num(0.0), _num(0.45 if haze < 0.5 else 0.0)),
    )


def _num(v):
    """Format a float the way Dart wants it, without trailing noise."""
    if v == 0:
        return "0"
    if abs(v) >= 1000:
        return "%d" % round(v)
    if abs(v) < 1e-3:
        return "%.3e" % v
    return ("%.4f" % v).rstrip("0").rstrip(".")


def keyframes(name, frames, haze, dust, damp, gain, blue, pin):
    out = []
    med = medium(haze, dust, damp, blue)
    # Ozone absorbs hardest in the GREEN (see `SkyConstants.ozoneAbsorb`), so
    # this is a narrow knob, not a dimmer: run the tent much past the real
    # layer's thickness and the sky loses its green channel and goes maroon.
    ozone = min(34000.0, OZONE_CLEAR * (1.0 + 0.16 * haze))
    for i in range(frames):
        if pin is None:
            elev = elevation(i, frames, None)
            night = 1.0
        else:
            # A four-point ring is night, day, day, night — and its sun does
            # NOT move. Under a deck thick enough to need this ring you cannot
            # see where the sun is; the sky is lit diffusely and night is the
            # same sky, dimmer. Letting the elevation fall to the horizon for
            # the night frames instead makes every overcast midnight a sunset,
            # which is a red sky under a rain cloud.
            elev = pin
            night = 1.0 if i % 3 else NIGHT_GAIN
        # The band lifts a little as the sun climbs, so a bright sky shows more
        # of its own gradient and a dark one sits closer to the horizon.
        yaw = round(1.5 + 6.0 * math.sin(math.radians(elev)), 1)
        out.append(dict(
            time=i,
            sunAngleY=round(elev / 180.0, 4),
            cameraYaw=yaw,
            sunIntensity=sun_intensity(elev, gain * night),
            ozoneThickness=int(round(ozone / 500.0) * 500),
            **med,
        ))
    return out


def emit(stream):
    w = stream.write
    w("// GENERATED by tool/gen_sky_keyframes.py — do not edit by hand.\n")
    w("//\n")
    w("// The scene keyframe rings, in the GL units the sky shaders consume.\n")
    w("// See the generator for how each number is arrived at; the short\n")
    w("// version is that a weather type declares how hazy, damp and dusty it\n")
    w("// is and everything else follows from that plus the sun's elevation.\n")
    w("\n")
    w("import 'package:dpip/features/home/presentation/widgets/weather_sky/"
      "sky_keyframe.dart';\n")

    for name, frames, haze, dust, damp, gain, blue, pin in WEATHERS:
        rows = keyframes(name, frames, haze, dust, damp, gain, blue, pin)
        w("\n/// %s — %d keyframes.\n" % (name, frames))
        w("const List<SkyKeyframe> %sKeyframes = [\n" % name)
        for r in rows:
            w("  SkyKeyframe(\n")
            w("    time: %d,\n" % r["time"])
            w("    sunAngleY: %s,\n" % _num(r["sunAngleY"]))
            w("    cameraYaw: %s,\n" % _num(r["cameraYaw"]))
            w("    sunIntensity: %s,\n" % _num(r["sunIntensity"]))
            w("    ozoneThickness: %d,\n" % r["ozoneThickness"])
            w("    postColor: (%s),\n" % ", ".join(str(v) for v in POST))
            for k in ("humidRayleighHeight", "humidMieScatter", "humidMieAbsorb",
                      "humidMieHeight", "humidMieAsymmetry"):
                w("    %s: (%s, %s),\n" % (k, r[k][0], r[k][1]))
            w("  ),\n")
        w("];\n")

    w("\n/// All weather types, in weather-code order.\n")
    w("const List<List<SkyKeyframe>> weatherKeyframes = [\n")
    for name, *_ in WEATHERS:
        w("  %sKeyframes,\n" % name)
    w("];\n")


if __name__ == "__main__":
    emit(sys.stdout)
