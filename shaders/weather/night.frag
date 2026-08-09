// Night layer — stars, Milky Way band and moon, porting the reference
// engine's the reference shader (stars) and the look of
// The reference shader (band).
//
// Stars follow the reference's `drawStars` closely: the sky is diced into `numCells`
// cells, each holding one star at a hashed offset, drawn as a smoothstep of
// the distance to that centre. Three passes at 4/8/16 cells give bright,
// medium and faint stars. The bright pass also gets the reference's glow stack — a
// wide halo, a four-point diffraction cross built from the angle modulo 90°,
// and a tight core — gated by a slow per-star twinkle so only a few sparkle
// at once instead of the whole field shimmering.
//
// The reference samples a starmap texture for the galaxy; this draws the band
// procedurally: a rotated, softly-bounded strip filled with fbm dust and
// scattered faint stars, which needs no 4K texture upload.
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
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec3 iGalaxyTint;
uniform float iTime;
uniform float iAlpha;
uniform float iScroll;
uniform float iCloudCover;
uniform float iGalaxy;

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

/// One star field pass. [numCells] sets density, [size] the radius, [br] the
/// brightness; [showGlow] adds the halo and diffraction spikes.
float drawStars(vec2 coord, float numCells, float size, float br,
                bool showGlow) {
  vec2 bigCoord = coord * numCells;
  vec2 cellID = floor(bigCoord);

  vec2 rnd = hash22(mod(cellID, numCells));
  vec2 centerOffset = rnd * 0.7 + rnd.x * 0.3;
  // Keep glowing stars away from the cell edge so their halo is not clipped.
  vec2 center = cellID + (showGlow ? mix(vec2(0.1), vec2(0.9), centerOffset)
                                   : mix(vec2(0.01), vec2(0.99), centerOffset));

  vec2 offset = (bigCoord - center) / (numCells * size);
  float d = dot(offset, offset);
  if (d > 0.16 || (!showGlow && d > 0.0025)) return 0.0;

  float sqrtd = 1.0 - sqrt(d);
  float star = br * smoothstep(0.95, 1.0, sqrtd);
  // Base shimmer, always on and subtle.
  star *= 1.2 + sin(center.y * 10.0 + center.x * 71.9 + iTime * 2.0) * 0.6;

  if (!showGlow) return star;

  // Wide halo.
  float glow = pow(clamp(br * smoothstep(0.6, 1.0, sqrtd), 0.0, 2.0), 3.5) *
               0.016666667;

  // Four-point diffraction cross: the spike is longest at ±45°/±135°.
  float angle = atan(offset.y, offset.x) + PI * 0.25;
  float angleOffset = abs(mod(angle, PI * 0.5) - PI * 0.25);
  float len = mix(0.76, 0.88, pow(angleOffset, 0.5) / (PI * 0.25));
  glow += smoothstep(len + 0.05, 1.1, sqrtd) * 0.5;

  // Tight core.
  if (sqrtd > 0.895) {
    glow += pow(clamp(br * smoothstep(0.895, 1.0, sqrtd), 0.0, 2.0), 2.0) *
            0.33333333;
  }

  // Twinkle gate: mostly dark, with a brief sine pulse every interval.
  float t = center.y * 721.3 + center.x * 37.1 + iTime * 2.0;
  float phase = mod(t, (2.0 + kTwinkleInterval) * PI) <= TWO_PI
      ? mod(t, TWO_PI)
      : TWO_PI;
  glow *= 0.5 + sin(phase - PI * 0.5) * 0.5;

  return star + glow;
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
    // Unresolved stars inside the band.
    col += vec3(1.0) * drawStars(coord * 1.3, 26.0, 0.02, 0.35, false) *
           band * galaxy * horizonFade;
  }

  // --- star field --------------------------------------------------------
  col += vec3(0.74, 0.74, 0.74) * drawStars(coord, 4.0, 0.08, 2.0, true) *
         horizonFade;
  col += vec3(0.97, 0.85, 0.80) * drawStars(coord, 8.0, 0.05, 1.0, false) *
         horizonFade;
  col += vec3(0.85, 0.90, 1.00) * drawStars(coord, 16.0, 0.025, 0.5, false) *
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
