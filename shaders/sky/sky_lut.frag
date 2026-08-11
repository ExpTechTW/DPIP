// Sky-view LUT — stage 2 of the atmospheric sky (baked at 256x141 RGB8).
//
// Single-scattering ray march in the arrangement of Hillaire 2020 (see
// `transmittance.frag`): step along the view ray, carry the eye-to-step
// transmittance, and at each step add the sunlight that survives to it —
// `sunTransmittance` read from stage 1 — times the phase function.
//
// Each texel ray-marches one view ray through the atmosphere and accumulates
// single scattering, giving the sky's radiance in that direction. The whole
// sky lands in one small texture that `sky_view.frag` samples per frame, so
// the integral runs on a bake rather than per pixel per frame.
//
// LUT axes, exactly the reference's:
//   u → the sun's position along its arc, `mix(0°, 180°)`. This is indexed by
//       the authored `sunAngleY` keyframe value — the engine has no solar
//       ephemeris, and the sun never goes below the horizon here. Night comes
//       from the keyframe's low `sunAngleY` plus its atmosphere, not from a
//       negative elevation.
//   v → view elevation, `sign(m) * (π/2) * m²` over `m ∈ [-0.102, 1]`. The
//       square packs texels near the horizon where the gradient is steepest.
//
// The view ray is coplanar with the sun (the reference forces `texCoord.x = 0.5`), so
// the sky has no azimuthal variation — correct, because the screen pass is a
// pure vertical gradient.
//
// Distances are metres and coefficients 1/m, matching the engine's uploads.
//
// Uniform contract — slots are float indices in declaration order.
//   uResolution       (0..1)   LUT size in pixels
//   uRayleighScatter  (2..4)   Rayleigh scattering coefficient (1/m)
//   uOzoneAbsorb      (5..7)   ozone absorption coefficient (1/m)
//   uSunRadiance      (8..10)  sun radiance (config `sunIntensity`)
//   uPostA..uPostE    (11..15) tonemap coefficients (config `postColor`)
//   uRayleighHeight   (16)     Rayleigh scale height (m)
//   uMieScatter       (17)     Mie scattering coefficient (1/m)
//   uMieAbsorb        (18)     Mie absorption coefficient (1/m)
//   uMieHeight        (19)     Mie scale height (m)
//   uMieAsymmetry     (20)     Mie phase asymmetry g
//   uOzoneCentre      (21)     ozone layer centre altitude (m)
//   uOzoneThickness   (22)     ozone layer half-thickness (m)
//   uPlanetRadius     (23)     planet radius (m)
//   uAtmosphereRadius (24)     atmosphere outer radius (m)
//   uEyeAltitude      (25)     viewer altitude (m)
//   uTransSize        (26..27) stage-1 LUT size in texels
//   sampler 0: uTransmittance  stage-1 LUT
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform vec3 uRayleighScatter;
uniform vec3 uOzoneAbsorb;
uniform vec3 uSunRadiance;
uniform float uPostA;
uniform float uPostB;
uniform float uPostC;
uniform float uPostD;
uniform float uPostE;
uniform float uRayleighHeight;
uniform float uMieScatter;
uniform float uMieAbsorb;
uniform float uMieHeight;
uniform float uMieAsymmetry;
uniform float uOzoneCentre;
uniform float uOzoneThickness;
uniform float uPlanetRadius;
uniform float uAtmosphereRadius;
uniform float uEyeAltitude;
uniform vec2 uTransSize;
uniform sampler2D uTransmittance;

out vec4 fragColor;

#define PI 3.14159265359

/// The reference's `MarchStepCount`. Constant so the loop unrolls on every backend.
const int kStepCount = 30;

/// Scattering and extinction coefficients at altitude [h].
void sigmaAt(float h, out vec3 scatter, out vec3 extinction) {
  vec3 rayleigh = uRayleighScatter * exp(-h / uRayleighHeight);
  float mieDensity = exp(-h / uMieHeight);
  float mieScatter = uMieScatter * mieDensity;
  float mieExtinct = (uMieScatter + uMieAbsorb) * mieDensity;
  float ozone =
      max(0.0, 1.0 - 0.5 * abs(h - uOzoneCentre) / uOzoneThickness);

  scatter = rayleigh + vec3(mieScatter);
  extinction = rayleigh + vec3(mieExtinct) + uOzoneAbsorb * ozone;
}

/// Per-channel phase function, weighted by each component's contribution.
vec3 phaseAt(float h, float cosTheta) {
  vec3 rayleigh = uRayleighScatter * exp(-h / uRayleighHeight);
  float mie = uMieScatter * exp(-h / uMieHeight);

  float cos2 = cosTheta * cosTheta;
  float pRayleigh = 3.0 / (16.0 * PI) * (1.0 + cos2);

  float g = uMieAsymmetry;
  float g2 = g * g;
  float m = max(1.0 + g2 - 2.0 * g * cosTheta, 1e-4);
  float pMie =
      3.0 / (8.0 * PI) * (1.0 - g2) * (1.0 + cos2) / ((2.0 + g2) * m * sqrt(m));

  vec3 total = rayleigh + vec3(mie);
  vec3 weighted = pRayleigh * rayleigh + pMie * vec3(mie);
  return vec3(
      total.x > 0.0 ? weighted.x / total.x : 0.0,
      total.y > 0.0 ? weighted.y / total.y : 0.0,
      total.z > 0.0 ? weighted.z / total.z : 0.0);
}

/// Bilinear transmittance fetch.
///
/// Flutter binds fragment-shader samplers as NEAREST with no way to request
/// linear, and the engine's own LUTs are LINEAR — so the interpolation has to
/// be done by hand or the sunset reddening quantises into bands.
vec3 sunTransmittance(float h, float cosZenith) {
  float u = clamp(h / (uAtmosphereRadius - uPlanetRadius), 0.0, 1.0);
  float v = clamp(0.5 + 0.5 * cosZenith, 0.0, 1.0);

  vec2 texel = 1.0 / uTransSize;
  vec2 st = vec2(u, v) * uTransSize - 0.5;
  vec2 base = floor(st);
  vec2 f = st - base;
  vec2 uv0 = (base + 0.5) * texel;

  vec3 c00 = texture(uTransmittance, uv0).rgb;
  vec3 c10 = texture(uTransmittance, uv0 + vec2(texel.x, 0.0)).rgb;
  vec3 c01 = texture(uTransmittance, uv0 + vec2(0.0, texel.y)).rgb;
  vec3 c11 = texture(uTransmittance, uv0 + texel).rgb;
  return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

/// The reference's `tonemap`: the generic filmic curve with authored coefficients.
vec3 tonemap(vec3 x) {
  return (x * (vec3(uPostA) * x + vec3(uPostB))) /
         (x * (vec3(uPostC) * x + vec3(uPostD)) + vec3(uPostE));
}

/// The reference's `postProcessColor` dither: the LUT is 8-bit, so each channel is
/// nudged to a neighbouring level with probability equal to its fraction.
vec3 dither8Bit(vec2 seed, vec3 color) {
  float rand =
      fract(sin(dot(seed, vec2(12.9898, 78.233) * vec2(2.0))) * 43758.5453);
  vec3 scaled = vec3(255.0) * clamp(pow(color, vec3(1.0 / 2.2)), 0.0, 1.0);
  vec3 frac = scaled - floor(scaled);
  return mix(floor(scaled), ceil(scaled), step(vec3(rand), frac)) / 255.0;
}

/// Whether a ray from [o] along [d] meets the sphere of radius [r].
bool hitsSphere(vec3 o, vec3 d, float r) {
  float b = dot(o, d);
  float c = dot(o, o) - r * r;
  return (b * b - c >= 0.0) && (c <= 0.0 || b <= 0.0);
}

/// Nearest forward intersection distance with a circle of radius [r].
bool circleHit(vec2 o, vec2 d, float r, out float t) {
  float b = dot(o, d);
  float c = dot(o, o) - r * r;
  float disc = b * b - c;
  if (disc < 0.0) return false;
  t = -b + (c <= 0.0 ? sqrt(disc) : -sqrt(disc));
  return (c <= 0.0) || (b <= 0.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  // --- view elevation (v axis) -------------------------------------------
  float m = uv.y * 1.1015625 - 0.1015625;
  float theta = sign(m) * (PI / 2.0) * m * m;
  float sinT = sin(theta);
  float cosT = cos(theta);
  vec3 dir = vec3(-cosT, sinT, 0.0);

  // --- sun position along its arc (u axis) --------------------------------
  // The reference's `calSunDir` negates elevation, and every use is of `-sunDir`; the
  // direction *toward* the sun is therefore (-cos e, sin e, 0).
  float e = radians(mix(0.0, 180.0, uv.x));
  vec3 toSun = vec3(-cos(e), sin(e), 0.0);

  float cosPhase = dot(dir, toSun);

  // --- ray extent ---------------------------------------------------------
  vec2 planetOri = vec2(0.0, uEyeAltitude + uPlanetRadius);
  vec2 planetDir = vec2(cosT, sinT);
  float endT = 0.0;
  if (!circleHit(planetOri, planetDir, uPlanetRadius, endT)) {
    circleHit(planetOri, planetDir, uAtmosphereRadius, endT);
  }

  // --- march --------------------------------------------------------------
  vec3 inScatter = vec3(0.0);
  vec3 sumSigmaT = vec3(0.0);
  float dt = endT / float(kStepCount);

  for (int i = 0; i < kStepCount; i++) {
    float thisT = dt * float(i);
    float midT = thisT + 0.5 * dt;

    vec3 posR = vec3(0.0, uEyeAltitude + uPlanetRadius, 0.0) + dir * midT;
    float h = length(posR) - uPlanetRadius;

    vec3 scatter, extinction;
    sigmaAt(h, scatter, extinction);

    vec3 deltaSigmaT = extinction * dt;
    // Transmittance from the eye to the middle of this step.
    vec3 eyeTrans = exp(-sumSigmaT - 0.5 * deltaSigmaT);

    if (!hitsSphere(posR, toSun, uPlanetRadius)) {
      float cosZenith = dot(toSun, normalize(posR));
      vec3 sunTrans = sunTransmittance(h, cosZenith);
      inScatter += dt * eyeTrans * scatter * phaseAt(h, cosPhase) * sunTrans;
    }

    sumSigmaT += deltaSigmaT;
  }

  // The LUT is 8-bit, so it stores display-ready values: the reference tonemaps,
  // gamma-encodes and dithers here rather than at display time.
  vec3 color = inScatter * uSunRadiance;
  color = dither8Bit(vec2(0.5, uv.y), tonemap(color));

  fragColor = vec4(color, 1.0);
}
