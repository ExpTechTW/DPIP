// Moon surface **bake** shader — renders the static lunar relief into a
// single texture for `moon_display.frag` to light per frame:
//
//   RGB = surface normal (n * 0.5 + 0.5), from the procedural height field
//   A   = albedo (grey: dark maria vs bright highlands, fresh-crater casts)
//
// The surface never changes, so it is rasterised once (512 px) and the
// display shader only pays for lighting — phase, earthshine and colour are
// per-frame, relief is baked.
//
// Relief recipe, all procedural (no textures, no network):
//   - 3-octave fbm base terrain (large + medium + fine scales)
//   - three maria basins (smooth, seeded discs that depress the height
//     field and darken the albedo)
//   - six crater generations on a grid ladder (cell size halves each step,
//     radius shrinks with it) so craters appear at every scale
//   - two large seeded craters with radial ray systems (Tycho-like ejecta
//     ridges that show up as bright streaks under grazing light)
// Every crater is a profile, not a disc: raised rim, excavated bowl and a
// central peak for the big ones — that is what makes the terminator read as
// relief instead of a flat two-tone cut.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution  (0..1)  bake texture size in pixels
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;

out vec4 fragColor;

#define PI 3.14159265

vec3 hash33(vec3 p) {
  p = vec3(
    dot(p, vec3(127.1, 311.7, 74.7)),
    dot(p, vec3(269.5, 183.3, 246.1)),
    dot(p, vec3(113.5, 271.9, 124.6))
  );
  return fract(sin(p) * 43758.5453);
}

float noise(vec3 p) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(
      mix(hash33(i).x, hash33(i + vec3(1.0, 0.0, 0.0)).x, f.x),
      mix(hash33(i + vec3(0.0, 1.0, 0.0)).x,
          hash33(i + vec3(1.0, 1.0, 0.0)).x, f.x),
      f.y
    ),
    mix(
      mix(hash33(i + vec3(0.0, 0.0, 1.0)).x,
          hash33(i + vec3(1.0, 0.0, 1.0)).x, f.x),
      mix(hash33(i + vec3(0.0, 1.0, 1.0)).x,
          hash33(i + vec3(1.0, 1.0, 1.0)).x, f.x),
      f.y
    ),
    f.z
  );
}

float fbm(vec3 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p = p * 2.02 + vec3(11.7);
    a *= 0.5;
  }
  return v;
}

/// One crater on the unit disc (radius 1): outer lip, excavated bowl,
/// faint central peak. Returns signed height.
float craterProfile(vec2 q) {
  float d = length(q);
  if (d > 1.15) return 0.0;
  float rim = smoothstep(1.15, 0.82, d) * 0.55;
  float bowl = -smoothstep(0.95, 0.08, d) * 1.35;
  float peak = smoothstep(0.5, 0.0, d) *
               smoothstep(0.0, 0.22, d) * 0.38;
  return rim + bowl + peak;
}

/// One generation of craters: a grid ladder whose cells each hold a crater,
/// so every scale of the surface gets its own relief.
float craterLayer(vec2 p, float n, float rMin, float rMax, float amp) {
  vec2 cell = floor(p * n);
  vec2 f = fract(p * n);
  vec3 h = hash33(vec3(cell, n));
  vec2 c = h.xy;
  float r = mix(rMin, rMax, h.z);
  return craterProfile((f - c) / r) * amp;
}

/// Radial ray system around a crater — ejecta ridges radiating outward,
/// brightest along the axes, fading with distance. Height gain only
/// (positive), so grazing light turns them into bright streaks.
float raysAround(vec2 p, vec2 c, float r, float seed) {
  vec2 d = p - c;
  float len = length(d);
  if (len < r * 1.2 || len > r * 7.0) return 0.0;
  float ang = atan(d.y, d.x) + PI * 0.5;
  // Four symmetry axes (offset by 45°), each ray's reach noise-modulated.
  float angleOffset = abs(mod(ang, PI * 0.5) - PI * 0.25);
  float core = smoothstep(PI * 0.22, 0.0, angleOffset);
  float reach = r * (4.0 + 2.5 * noise(vec3(ang * 3.0, len * 0.03, seed)));
  float along = smoothstep(reach, 0.0, len - r);
  float streak = noise(vec3(ang * 16.0, len * 0.9, seed * 2.0));
  return (0.05 + 0.16 * core) * along * (0.55 + 0.45 * streak);
}

/// The two large seeded craters with ray systems.
float bigCraters(vec2 p) {
  vec3 a = hash33(vec3(1.7, 3.1, 4.0));
  vec3 b = hash33(vec3(8.2, 2.9, 5.0));
  vec2 ca = (a.xy - 0.5) * 5.5;
  vec2 cb = (b.xy - 0.5) * 5.5;
  float ra = 0.55 + a.z * 0.5;
  float rb = 0.45 + b.z * 0.4;
  float h = craterProfile((p - ca) / ra) * 0.9;
  h += craterProfile((p - cb) / rb) * 0.8;
  h += raysAround(p, ca, ra, 21.0);
  h += raysAround(p, cb, rb, 37.0);
  return h;
}

float maria(vec2 p) {
  vec3 s1 = hash33(vec3(4.1, 8.3, 1.0));
  vec3 s2 = hash33(vec3(9.7, 3.9, 2.0));
  vec3 s3 = hash33(vec3(15.3, 6.1, 3.0));
  vec2 c1 = (s1.xy - 0.5) * 5.0;
  vec2 c2 = (s2.xy - 0.5) * 5.0;
  vec2 c3 = (s3.xy - 0.5) * 5.0;
  float r1 = 0.9 + s1.z * 0.9;
  float r2 = 0.7 + s2.z * 0.7;
  float r3 = 0.5 + s3.z * 0.6;
  float m = 0.0;
  m = max(m, smoothstep(r1 * 1.25, 0.0, length(p - c1)));
  m = max(m, smoothstep(r2 * 1.25, 0.0, length(p - c2)));
  m = max(m, smoothstep(r3 * 1.25, 0.0, length(p - c3)));
  return clamp(m, 0.0, 1.0);
}

float heightAt(vec2 p) {
  float h = 0.0;
  h += (fbm(vec3(p * 1.1, 0.0)) - 0.5) * 0.95;
  h += (fbm(vec3(p * 2.3, 5.0)) - 0.5) * 0.40;
  h += (fbm(vec3(p * 5.1, 9.0)) - 0.5) * 0.18;
  h -= maria(p) * 0.55;
  h += craterLayer(p, 4.0, 0.30, 0.55, 0.55);
  h += craterLayer(p, 8.0, 0.18, 0.35, 0.45);
  h += craterLayer(p, 16.0, 0.10, 0.22, 0.35);
  h += craterLayer(p, 32.0, 0.055, 0.14, 0.25);
  h += craterLayer(p, 64.0, 0.15, 0.35, 0.15);
  h += craterLayer(p, 128.0, 0.2, 0.4, 0.08);
  h += bigCraters(p);
  return h;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / iResolution;
  // World space: 8 units across the bake; one unit ≈ 64 px.
  vec2 p = uv * 8.0;
  float e = 8.0 / iResolution.x; // one pixel, in world units

  // Central-difference normal from the height field.
  float h = heightAt(p);
  float hx = heightAt(p + vec2(e, 0.0)) - heightAt(p - vec2(e, 0.0));
  float hy = heightAt(p + vec2(0.0, e)) - heightAt(p - vec2(0.0, e));
  vec3 n = normalize(vec3(-hx, -hy, 1.0));

  // Albedo: dark maria over bright highlands, fresh-crater interior casts,
  // plus a faint blotchy mottle so no two pixels are flat.
  float m = maria(p);
  float albedo = mix(0.76, 0.33, m);
  albedo *= 1.0 + 0.10 * (noise(vec3(p * 3.0, 13.0)) - 0.5);
  albedo += clamp(h * 0.05, -0.06, 0.06);

  fragColor = vec4(n * 0.5 + 0.5, clamp(albedo, 0.0, 1.0));
}
