// Sun — a port of the reference engine
// (scene layer 12), drawn additively over the sky and clouds.
//
// This layer owns the sun *entirely*. The reference's sky pass is a
// pure vertical gradient with no disc in it, so if this layer does not draw
// the disc, nothing does — which is exactly the bug this replaces: the disc
// was dropped when it moved out of the sky shader and only the rays survived,
// leaving clear days with no sun at all.
//
// Four pieces, all from the original:
//   • the disc — `circleTex(uSunTex, …) * vec3(uR, uG, uB) * 1.02`, a radial
//     colour ramp rather than a flat circle, which is what gives the limb its
//     falloff and the core its warmth
//   • static rays — `uObviousLineTex`, a fixed radial streak pattern, weighted
//     by a forward-facing `fan` term
//   • animated rays — three sine systems at 0, π/5 and π/2, the term the reference
//     writes out by hand as angle-addition. Its gain is
//     `LINE_COLOR * (uLineAlpha / 320)`, and `uLineAlpha` is **20.5**
//     (`SunUniform.f16278e`) — a factor of 0.064. Assuming a gain near 1
//     makes the rays roughly fifteen times too strong and they swamp the sky.
//   • the glow — `vec4(0.851, 0.604, 0.349, 0.5 / exp(x²))`
//
// Everything is then attenuated by `exp(1 - dist) / kDecay` and gated below
// the horizon, as in the original.
//
// The three lookups are radial: `circleTex(tex, st)` samples at
// `vec2(length(st * 2 - 1), 0.5)`, so `sun_profile` and `annulus` are 1-D
// ramps stored one row tall.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution   (0..1)  render size in pixels
//   iSunPos       (2..3)  normalized screen position of the sun (0..1)
//   iRayColor     (4..6)  animated-ray tint (the reference's `LINE_COLOR` × light)
//   iTime         (7)     animation time (seconds)
//   iOpacity      (8)     overall opacity 0..1
//   iDiscAlpha    (9)     sun disc strength 0..1
//   iRayAlpha     (10)    animated ray strength 0..1
//   iAnnulusAlpha (11)    chromatic ring strength (the reference's `uAnnulusAlpha`,
//                         0.13 while the sun is up)
//   iGhostAlpha   (12)    lens-ghost strength (the reference's `uCircleAlpha`, 1.03)
//   iGhostOffset  (13)    ghost spacing along the sun axis (`uCircleOffset`)
//   iSeed         (14)    per-transition ghost randomisation
//   iGlowAlpha    (15)    broad glow strength 0..1
//   sampler 0: iSunTex    radial colour ramp for the disc
//   sampler 1: iRaysTex   static radial streak pattern
//   sampler 2: iAnnulus   radial ramp for the ring
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec2 iSunPos;
uniform vec3 iRayColor;
uniform float iTime;
uniform float iOpacity;
uniform float iDiscAlpha;
uniform float iRayAlpha;
uniform float iAnnulusAlpha;
uniform float iGhostAlpha;
uniform float iGhostOffset;
uniform float iSeed;
uniform float iGlowAlpha;
uniform sampler2D iSunTex;
uniform sampler2D iRaysTex;
uniform sampler2D iAnnulus;

out vec4 fragColor;

#define PI 3.14159265

/// Overall falloff with distance from the sun (the reference's `DECAY`).
const float kDecay = 6.0;
/// The reference's per-channel disc gain.
const vec3 kDiscGain = vec3(1.25, 1.61, 1.84);
/// Animated-ray gain: `uLineAlpha / 320` with the engine's `uLineAlpha` 20.5.
const float kLineGain = 20.5 / 320.0;
/// The reference's `CIRCLE_SIZE`.
const float kCircleSize = 0.95;

/// The reference's ghost colour table. SkSL has no array initialisers.
vec3 ghostColor(int index) {
  if (index == 0) return vec3(0.1686, 0.7412, 0.2353);
  if (index == 1) return vec3(1.0000, 0.3843, 0.0000);
  if (index == 2) return vec3(1.0000, 0.5333, 0.0000);
  if (index == 3) return vec3(0.7804, 1.0000, 0.3725);
  if (index == 4) return vec3(1.0000, 0.5333, 0.0000);
  if (index == 5) return vec3(1.0000, 0.3843, 0.0000);
  if (index == 6) return vec3(1.0000, 0.5333, 0.0000);
  if (index == 7) return vec3(1.0000, 0.5333, 0.0000);
  return vec3(1.0000, 0.2588, 0.1294);
}

vec3 hash31(float n) {
  vec3 p = fract(vec3(n) * vec3(0.1031, 0.11369, 0.13787));
  p += dot(p, p.yzx + 19.19);
  return fract(vec3((p.x + p.y) * p.z, (p.x + p.z) * p.y, (p.y + p.z) * p.x));
}

/// The reference's `getCircle`: one lens ghost along the sun axis.
vec3 ghost(int index, vec2 uv, vec2 sunPos, float size, float dist,
           float blur, float alpha) {
  blur = mix(0.45, 1.0, blur);
  float c = max(0.01 - pow(length(uv + sunPos * dist), size * 1.4), 0.0) * 50.0;
  float c1 = (c > 0.1) ? (0.1 - (c - 0.1) / 5.0) : (c / 1.4) * blur * 2.0;
  float c2 = mix(c1, c, (blur > 0.5) ? ((blur - 0.5) * 2.0) : 0.0);
  float a = alpha * mix(1.0, 0.4, clamp((size - 1.0) * 3.0, 0.0, 1.0)) *
            ((blur >= 0.82) ? 0.5 : 1.0);
  return max(c2 * ghostColor(index) * a - 0.01, 0.0);
}

/// The reference's `ring`: the chromatic halo, offset per channel.
vec3 ring(vec2 uv, vec2 pos, float dist) {
  vec2 uvd = uv * length(uv);
  float r = max(2.0 / (1.0 + 32.0 * pow(length(uvd + (dist - 0.05) * pos), 2.0)), 0.0) * 0.25;
  float g = max(2.0 / (1.0 + 32.0 * pow(length(uvd + dist * pos), 2.0)), 0.0) * 0.23;
  float b = max(2.0 / (1.0 + 32.0 * pow(length(uvd + (dist + 0.05) * pos), 2.0)), 0.0) * 0.21;
  return vec3(r, g, b);
}

/// The reference's `circleTex` is a radial lookup — distance from the centre into a
/// ramp. SkSL forbids passing a sampler to a function, so the coordinate is
/// computed here and each lookup is written out at its use site.
vec2 circleUv(vec2 st) {
  return vec2(length(st * 2.0 - 1.0), 0.5);
}

/// One animated ray system (the reference's `dimLine` term).
float rayAt(float theta) {
  return abs(sin(3.0 * theta + cos(9.0 * theta))) * abs(sin(9.0 * theta));
}

float perFromVal(float v, float from, float to) {
  return (v - from) / (to - from);
}

void main() {
  vec2 uvRaw = FlutterFragCoord().xy / iResolution;
  float aspect = iResolution.x / max(iResolution.y, 1.0);

  float opacity = clamp(iOpacity, 0.0, 1.0);
  if (opacity < 0.004) {
    fragColor = vec4(0.0);
    return;
  }

  // The reference's frame: origin at screen centre, x scaled by aspect, y up.
  vec2 uv = (uvRaw - 0.5) * vec2(aspect, -1.0);
  vec2 sunPos = (iSunPos - 0.5) * vec2(aspect, -1.0);

  vec2 diff = uv - sunPos;
  float dist = length(diff);
  vec3 color = vec3(0.0);

  // --- static rays --------------------------------------------------------
  // Sampled in a frame centred on the sun, a third of the way out, so the
  // pattern radiates from it.
  vec2 st2 = clamp(diff / 3.0 + 0.5, 0.0, 1.0);
  vec3 staticRays = texture(iRaysTex, st2).rgb;

  // Forward-facing weight: brightest looking straight into the sun.
  float fan = min(max(0.3, pow(clamp(perFromVal(
                  dot(normalize(sunPos + 1e-5), normalize(sunPos - uv + 1e-5)),
                  -1.0, 1.0), 0.0, 1.0), 3.0)), 0.8);
  fan = max(pow(max(1.0 - dist, 0.0), 3.0), fan);
  color += staticRays * fan;

  // --- animated rays ------------------------------------------------------
  float rayAlpha = clamp(iRayAlpha, 0.0, 1.0);
  if (rayAlpha > 0.01) {
    float theta = atan(diff.y, diff.x);
    // Three systems, each breathing at its own rate.
    float a0 = (sin(iTime * 2.0) + 1.0) * 0.5;
    float a1 = (sin(iTime * 2.0 + PI * 1.3333) + 1.0) * 0.5;
    float a2 = (sin(iTime * 2.0 + PI * 2.6667) + 1.0) * 0.5;
    float rays = rayAt(theta) * a0 + rayAt(theta + PI / 5.0) * a1 +
                 rayAt(theta + PI / 2.0) * a2;
    // `uLineAlpha / 320` with uLineAlpha = 20.5.
    color += iRayColor * kLineGain * rays * 1.2 * (1.0 - st2.x) * rayAlpha;
  }

  // --- lens ghosts and ring (the reference's `u22Open` block) -----------------------
  // Enabled by `sunUniform.m(...)` in the main scene, so the flare is part of
  // the stock look — the 0 in the constructor is only its initial value.
  float ghostAlpha = clamp(iGhostAlpha, 0.0, 2.0);
  if (ghostAlpha > 0.01) {
    // `light.a` in the original: a slow breath on ghost size and spacing.
    float breath = sin(iTime * 0.3333 + 5.0) * 0.05;
    float count = floor(mix(4.0, 8.0, hash31(17.0 + iSeed).x));
    for (int i = 0; i < 8; i++) {
      if (float(i) >= count) break;
      vec3 rnd = hash31(float(i) + iSeed * 13.0);
      float size = (rnd.x * 0.33 + kCircleSize) + breath;
      float d = (iGhostOffset + rnd.y * 0.35 +
                 float(i) / 30.0 + float(i) * float(i) * 0.01) + breath;
      color += ghost(i, uv, sunPos, size, d, rnd.z, ghostAlpha);
    }
    // The reference's `lensflare`: two chromatic rings either side of the sun.
    vec2 uvs = uv * 4.0;
    vec2 ps = sunPos * 1.5;
    color += (ring(uvs, ps, -1.0) * 0.5 * 4.0 + ring(uvs, ps, 1.0) * 0.5 * 4.0) *
             0.6 * vec3(1.4, 1.2, 1.0);
  }

  float annulusAlpha = clamp(iAnnulusAlpha, 0.0, 1.0);
  if (annulusAlpha > 0.01) {
    vec2 st = uv * 3.0 - sunPos * 2.5;
    color += texture(iAnnulus, circleUv(st * 0.5 + 0.5)).rgb * annulusAlpha * 4.0;
  }

  // --- the disc ------------------------------------------------------------
  // The piece that was missing. A radial colour ramp, not a flat circle.
  vec2 st3 = clamp(diff + 0.5, 0.0, 1.0);
  color += texture(iSunTex, circleUv(st3)).rgb * kDiscGain * 1.02 *
           clamp(iDiscAlpha, 0.0, 1.0);

  // --- glow ----------------------------------------------------------------
  float x = length(st3 * 2.0 - 1.0) * 2.8;
  color += vec3(0.8509803922, 0.6039215686, 0.3490196078) *
           (0.5 / exp(x * x)) * clamp(iGlowAlpha, 0.0, 1.0);

  // --- falloff -------------------------------------------------------------
  color *= exp(1.0 - dist) / kDecay;
  // Gate below the horizon, as the reference does.
  color = clamp(color, 0.0, 1.0) * smoothstep(-0.5, 0.1, uv.y + 0.5) * opacity;

  float a = clamp(max(color.r, max(color.g, color.b)), 0.0, 1.0);
  if (a < 0.003) {
    fragColor = vec4(0.0);
    return;
  }

  fragColor = vec4(color, a); // premultiplied
}
