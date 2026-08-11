// Transmittance LUT — stage 1 of the atmospheric sky pipeline.
//
// The pipeline is the standard precomputed-scattering one: Bruneton & Neyret,
// "Precomputed Atmospheric Scattering" (EGSR 2008), in the LUT arrangement of
// Hillaire, "A Scalable and Production Ready Sky and Atmosphere Rendering
// Technique" (EGSR 2020). The medium's coefficients in `SkyConstants` are that
// paper's standard Earth atmosphere.
//
// For every (altitude, sun-zenith) pair it integrates the optical depth of
// the atmosphere along the ray leaving that point, and stores
// `exp(-opticalDepth)` — the fraction of sunlight that survives the trip.
// Stage 2 (`sky_lut.frag`) samples this to know how much sun reaches each
// point it marches through, which is what makes sunsets redden correctly
// instead of being tinted by hand.
//
// The medium is the standard three-component model: Rayleigh (air molecules,
// exponential falloff, the blue), Mie (aerosols/haze, sharper falloff, the
// white glare), and an ozone absorption band (a tent centred in the
// stratosphere) which is what keeps a clear zenith from going muddy.
// Distances are metres and coefficients 1/m.
//
// LUT layout:
//   u = altitude / atmosphereThickness
//   v = 0.5 + 0.5 * cos(zenith)
//
// This is baked once per atmosphere change (never per frame) — see
// `sky_lut.dart`.
//
// Uniform contract — slots are float indices in declaration order
// (vec3 = 3 slots, vec2 = 2, float = 1). See shaders/README.md.
//   uResolution       (0..1)  LUT size in pixels
//   uRayleighScatter  (2..4)  Rayleigh scattering coefficient (1/m)
//   uOzoneAbsorb      (5..7)  ozone absorption coefficient (1/m)
//   uRayleighHeight   (8)     Rayleigh scale height (m)
//   uMieScatter       (9)     Mie scattering coefficient (1/m)
//   uMieAbsorb        (10)    Mie absorption coefficient (1/m)
//   uMieHeight        (11)    Mie scale height (m)
//   uOzoneCentre      (12)    ozone layer centre altitude (m)
//   uOzoneThickness   (13)    ozone layer half-thickness (m)
//   uPlanetRadius     (14)    planet radius (m)
//   uAtmosphereRadius (15)    atmosphere outer radius (m)
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform vec3 uRayleighScatter;
uniform vec3 uOzoneAbsorb;
uniform float uRayleighHeight;
uniform float uMieScatter;
uniform float uMieAbsorb;
uniform float uMieHeight;
uniform float uOzoneCentre;
uniform float uOzoneThickness;
uniform float uPlanetRadius;
uniform float uAtmosphereRadius;

out vec4 fragColor;

/// Samples along the ray. Constant so the loop unrolls on every backend
/// (Impeller rejects
/// uniform-bounded loops).
const int kStepCount = 20;

/// Total extinction (out-scattering + absorption) at altitude [h].
vec3 sigmaExtinction(float h) {
  vec3 rayleigh = uRayleighScatter * exp(-h / uRayleighHeight);
  float mie = (uMieScatter + uMieAbsorb) * exp(-h / uMieHeight);
  // Tent profile: full strength at the centre, linearly to zero at the edges.
  float ozoneFalloff =
      max(0.0, 1.0 - 0.5 * abs(h - uOzoneCentre) / uOzoneThickness);
  return rayleigh + vec3(mie) + uOzoneAbsorb * ozoneFalloff;
}

/// Distance from [o] along [d] to the sphere of radius [r], or -1 if it is
/// missed / behind. Both are 2D because the problem is radially symmetric.
float raySphere(vec2 o, vec2 d, float r) {
  float b = dot(o, d);
  float c = dot(o, o) - r * r;
  float disc = b * b - c;
  if (disc < 0.0) return -1.0;
  float sq = sqrt(disc);
  float t0 = -b - sq;
  float t1 = -b + sq;
  if (t1 < 0.0) return -1.0;
  return t0 >= 0.0 ? t0 : t1;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;

  float thickness = uAtmosphereRadius - uPlanetRadius;
  float altitude = uv.x * thickness;
  // v encodes cos(zenith): 0 → straight down, 1 → straight up.
  float cosZenith = clamp(uv.y * 2.0 - 1.0, -1.0, 1.0);
  float sinZenith = sqrt(max(0.0, 1.0 - cosZenith * cosZenith));

  vec2 origin = vec2(0.0, uPlanetRadius + altitude);
  vec2 dir = vec2(sinZenith, cosZenith);

  // A ray that hits the ground is fully blocked; otherwise it exits the top.
  float ground = raySphere(origin, dir, uPlanetRadius);
  float distance = ground > 0.0
      ? ground
      : max(raySphere(origin, dir, uAtmosphereRadius), 0.0);

  vec3 opticalDepth = vec3(0.0);
  float dt = distance / float(kStepCount);
  for (int i = 0; i < kStepCount; i++) {
    // Midpoint rule — a full step's worth of extinction at the step centre.
    vec2 p = origin + dir * (dt * (float(i) + 0.5));
    opticalDepth += sigmaExtinction(length(p) - uPlanetRadius) * dt;
  }

  fragColor = vec4(exp(-opticalDepth), 1.0);
}
