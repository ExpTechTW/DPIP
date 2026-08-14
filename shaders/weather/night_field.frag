// Night star-field **bake** shader — renders the static star layers into a
// single tiling RGBA texture for `night.frag` to sample:
//
//   R = bright pass core stars (4-cell grid)
//   G = bright pass glow (halo + diffraction cross + tight core)
//   B = medium pass stars (8-cell grid)
//   A = faint pass stars (16-cell grid)
//
// The per-star shimmer and twinkle are multiplicative and time-driven, so they
// are NOT baked — `night.frag` recomputes them per cell from the same hashes
// this file uses, which keeps the frame-time animation identical. Splitting
// star and glow into separate channels is what lets the two be modulated
// differently at display time (shimmer rides the star, the twinkle gate the
// glow), exactly as the original single-pass shader did.
//
// The texture covers 4×4 bright cells of the world coordinate space (`coord`
// spans -2..2) and tiles via `fract` at sample time — the original field
// repeats every 4 cells anyway (`hash22(mod(cellID, numCells))`), so tiling is
// exactly equivalent, not an approximation.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution  (0..1)  bake texture size in pixels
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;

out vec4 fragColor;

#define PI 3.14159265

vec2 hash22(vec2 p) {
  p = vec2(dot(p, vec2(12.9898, 78.233)), dot(p, vec2(26.65125, 83.054543)));
  return fract(sin(p) * 43758.5453);
}

/// Core star brightness — `night.frag`'s `star` term before shimmer.
float starCore(vec2 coord, float numCells, float size, float br) {
  vec2 bigCoord = coord * numCells;
  vec2 cellID = floor(bigCoord);
  vec2 rnd = hash22(mod(cellID, numCells));
  vec2 center = cellID + mix(vec2(0.01), vec2(0.99), rnd * 0.7 + rnd.x * 0.3);
  vec2 offset = (bigCoord - center) / (numCells * size);
  float d = dot(offset, offset);
  if (d > 0.0025) return 0.0;
  return br * smoothstep(0.95, 1.0, 1.0 - sqrt(d));
}

/// The bright pass's glow stack — `night.frag`'s `glow` term, unmodulated.
float glowCore(vec2 coord, float numCells, float size, float br) {
  vec2 bigCoord = coord * numCells;
  vec2 cellID = floor(bigCoord);
  vec2 rnd = hash22(mod(cellID, numCells));
  vec2 center = cellID + mix(vec2(0.1), vec2(0.9), rnd * 0.7 + rnd.x * 0.3);
  vec2 offset = (bigCoord - center) / (numCells * size);
  float d = dot(offset, offset);
  if (d > 0.16) return 0.0;
  float sqrtd = 1.0 - sqrt(d);

  // Wide halo.
  float glow = pow(clamp(br * smoothstep(0.6, 1.0, sqrtd), 0.0, 2.0), 3.5) *
               0.016666667;

  // Four-point diffraction cross: the spike is longest at ±45°/±135°.
  float angle = atan(offset.y, offset.x) + PI * 0.25;
  float angleOffset = abs(mod(angle, PI * 0.5) - PI * 0.25);
  float len = mix(0.76, 0.88, sqrt(angleOffset) / (PI * 0.25));
  glow += smoothstep(len + 0.05, 1.1, sqrtd) * 0.5;

  // Tight core.
  if (sqrtd > 0.895) {
    float core = clamp(br * smoothstep(0.895, 1.0, sqrtd), 0.0, 2.0);
    glow += core * core * 0.33333333;
  }
  return glow;
}

void main() {
  // The bake covers bright cells 0..3 of the same world space the display
  // shader uses (texture [0,1] ↔ world [0,4]); the texture tiles via
  // `fract(coord / 4.0)` there, which lands cell N back on its own hash.
  vec2 coord = FlutterFragCoord().xy / iResolution * 4.0;
  float r = starCore(coord, 4.0, 0.08, 2.0);
  float g = glowCore(coord, 4.0, 0.08, 2.0);
  float b = starCore(coord, 8.0, 0.05, 1.0);
  float a = starCore(coord, 16.0, 0.025, 0.5);
  fragColor = vec4(r, g, b, a);
}
