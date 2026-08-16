// Night layer — stars, Milky Way band and moon, porting the reference
// engine's the reference shader (stars) and the look of
// The reference shader (band).
//
// The star field itself is pre-baked into a tiling RGBA texture
// ([night_field.frag]: R = bright-core stars, G = bright glow, B = medium
// stars, A = faint stars) and sampled here — the CPU-side bake runs once per
// sky size, not per frame. What stays per-frame:
//
//   * the per-star shimmer (`star *= 1.2 + sin(…)·0.6`) — recomputed per cell
//     from the same hashes the bake used, so every star keeps its own phase;
//   * the glow's twinkle gate (`glow *= 0.5 + sin(…)·0.5`) — ditto, bright
//     cells only;
//   * the slow drift (`coord += iTime·0.004`).
//
// The hash grid repeats every 4 cells (`hash22(mod(cellID, numCells))`), and
// the texture tiles via `fract(coord / 4.0)` on the same cycle — sampling is
// exactly equivalent to the original per-pixel field, not an approximation.
//
// There is no moon: the reference's scene has no moon layer at all, and the one this
// file used to draw was invented.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution  (0..1)  render size in pixels
//   iGalaxyTint  (2..4)  Milky Way colour
//   iTime        (7)     animation time (twinkle)
//   iAlpha       (8)     night visibility 0..1 (fades in after sunset)
//   iScroll      (9)     parallax offset in pixels
//   iCloudCover  (10)    0..1 cloud cover, dims the field
//   iGalaxy      (11)    Milky Way strength 0..1
//   sampler 0            iStarField — the baked RGBA star texture
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec3 iGalaxyTint;
uniform float iTime;
uniform float iAlpha;
uniform float iScroll;
uniform float iCloudCover;
uniform float iGalaxy;

uniform sampler2D iStarField;

out vec4 fragColor;

#define PI 3.14159265
#define TWO_PI 6.28318531

/// Gap between twinkles, in units of 2π (the reference's `TwinkleInterval`).
const float kTwinkleInterval = 40.0;

vec2 hash22(vec2 p) {
  p = vec2(dot(p, vec2(12.9898, 78.233)), dot(p, vec2(26.65125, 83.054543)));
  return fract(sin(p) * 43758.5453);
}

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
             mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x),
             u.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * vnoise(p);
    p = p * 2.03 + 11.3;
    a *= 0.5;
  }
  return v;
}

/// The bright pass's star centre in cell [cell] — the same hash the bake used,
/// so per-star shimmer/twinkle phases line up with the sampled field.
vec2 starCenter(vec2 cell, float numCells, bool glow) {
  vec2 rnd = hash22(mod(cell, numCells));
  vec2 offset = rnd * 0.7 + rnd.x * 0.3;
  return cell + (glow ? mix(vec2(0.1), vec2(0.9), offset)
                      : mix(vec2(0.01), vec2(0.99), offset));
}

/// The `star *= 1.2 + sin(…)·0.6` shimmer for the star in [cell].
float shimmer(vec2 cell, float numCells) {
  vec2 center = starCenter(cell, numCells, false);
  return 1.2 + sin(center.y * 10.0 + center.x * 71.9 + iTime * 2.0) * 0.6;
}

/// The bright pass's twinkle gate (`glow *= 0.5 + sin(…)·0.5`) for [cell].
float twinkle(vec2 cell) {
  vec2 center = starCenter(cell, 4.0, true);
  float t = center.y * 721.3 + center.x * 37.1 + iTime * 2.0;
  float phase = mod(t, (2.0 + kTwinkleInterval) * PI) <= TWO_PI
      ? mod(t, TWO_PI)
      : TWO_PI;
  return 0.5 + sin(phase - PI * 0.5) * 0.5;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / iResolution;
  float aspect = iResolution.x / max(iResolution.y, 1.0);

  float alpha = clamp(iAlpha, 0.0, 1.0) * (1.0 - 0.85 * clamp(iCloudCover, 0.0, 1.0));
  if (alpha < 0.004) {
    fragColor = vec4(0.0);
    return;
  }

  vec2 coord = (uv * 2.0 - 1.0) * vec2(aspect, 1.0);
  // Very slow drift so the sky feels alive without reading as movement.
  coord += vec2(iTime * 0.004, iScroll / max(iResolution.y, 1.0) * 0.6);

  // Stars thin out toward the horizon, where haze washes them out.
  float horizonFade = smoothstep(0.05, 0.55, 1.0 - uv.y);

  vec3 col = vec3(0.0);

  // --- Milky Way band ----------------------------------------------------
  float galaxy = clamp(iGalaxy, 0.0, 1.0);
  if (galaxy > 0.01) {
    // Rotate into the band's frame, then measure distance from its spine.
    float ca = cos(-0.42), sa = sin(-0.42);
    vec2 g = vec2(coord.x * ca - coord.y * sa, coord.x * sa + coord.y * ca);
    // Wobble the spine so the band is not a straight ruler.
    float spine = g.y + 0.18 * sin(g.x * 1.3) + 0.07 * sin(g.x * 3.1 + 1.7);
    float band = exp(-spine * spine * 7.0);

    float dust = fbm(g * 2.6 + 4.0);
    float dark = smoothstep(0.35, 0.75, fbm(g * 4.1 + 20.0)); // dust lanes
    float density = band * mix(0.35, 1.0, dust) * (1.0 - 0.65 * dark);

    col += iGalaxyTint * density * 0.22 * galaxy * horizonFade;
  }

  // --- star field (sampled, per-cell animation) --------------------------
  // The baked texture holds bright-cell world [0,4]; the field repeats on the
  // same 4-cell cycle, so `fract` wraps exactly.
  vec4 field = texture(iStarField, fract(coord / 4.0));

  vec2 cell4 = floor(coord / 4.0);
  vec2 cell8 = floor(coord / 8.0);
  vec2 cell16 = floor(coord / 16.0);

  // Bright pass: the glow rides the twinkle gate, the core star the shimmer.
  col += vec3(0.74, 0.74, 0.74) *
         (field.r * shimmer(cell4, 4.0) + field.g * twinkle(cell4)) *
         horizonFade;
  col += vec3(0.97, 0.85, 0.80) * field.b * shimmer(cell8, 8.0) *
         horizonFade;
  col += vec3(0.85, 0.90, 1.00) * field.a * shimmer(cell16, 16.0) *
         horizonFade;

  col *= alpha;
  float a = clamp(max(col.r, max(col.g, col.b)), 0.0, 1.0);
  if (a < 0.003) {
    fragColor = vec4(0.0);
    return;
  }

  // Additive-over-sky look via premultiplied output.
  fragColor = vec4(col, a);
}
