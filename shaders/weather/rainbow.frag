// Rainbow layer — a port of the reference engine.
//
// The spectral maths is the reference's verbatim, and it is the reason this looks like
// a rainbow instead of a hue sweep. Real bows are defined by *deviation
// angles*: light leaves a droplet at ~137.7° for red and ~139.6° for violet
// (the primary bow), and at ~129.5°/126.1° for the secondary — which is why
// the secondary is both wider and colour-reversed. `GetSpectrum` places one
// smooth peak per channel at those angles, so the band structure falls out of
// the geometry rather than being painted in.
//
// `ApplyAtmosphere` is kept as well: the bow's strength comes from the
// optical depth through a sphere of moisture (`(r-l)/r` cubed, then
// `1 - exp2(-depth)`), so it fades naturally at the edges instead of being
// masked. `RainbowShadow` keeps it off the side of the sky the light comes
// from.
//
// The only structural change: the reference aims a camera with `uCamPos`/`uFov` and
// ray-marches; here the ray fan is built directly from screen UVs, which is
// equivalent for a fixed background camera and skips the matrix.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution  (0..1)  render size in pixels
//   iSunDir      (2..4)  direction toward the sun (the bow is opposite it)
//   iOpacity     (5)     overall opacity 0..1
//   iRadius      (6)     bow radius trim (0.5 = textbook angles)
//   iGap         (7)     primary→secondary separation (0.5 = textbook)
//   iBrightness0 (8)     primary bow brightness
//   iBrightness1 (9)     secondary bow brightness
//   iVisRange    (10)    radius of the moisture volume
//   iFov         (11)    vertical field of view (radians)
//   iPitch       (12)    camera pitch (radians)
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec3 iSunDir;
uniform float iOpacity;
uniform float iRadius;
uniform float iGap;
uniform float iBrightness0;
uniform float iBrightness1;
uniform float iVisRange;
uniform float iFov;
uniform float iPitch;

out vec4 fragColor;

/// Smooth unit-height bump per channel, peaked at [peak] with width 1/[range].
vec3 getSpectrum(float x, vec3 brightness, vec3 peak, vec3 range) {
  vec3 t = clamp(1.0 - abs((peak - x) * range), 0.0, 1.0);
  vec3 t2 = t * t;
  // Smoothstep-shaped falloff (3t² - 2t³).
  return (3.0 * t2 - 2.0 * t * t2) * brightness;
}

/// Colour of the bow at scattering angle [theta] (degrees from the antisolar
/// point).
vec4 rainbowRGBA(float theta) {
  vec4 result = vec4(0.0);

  // Primary bow: red at 137.7°, violet at 139.6°, measured from the sun.
  vec3 peak0 = vec3(180.0 - 137.7,
                    180.0 - (137.7 + 139.6) * 0.5,
                    180.0 - 139.6) +
               vec3((iRadius - 0.5) * 180.0);
  vec3 range0 = vec3(1.0 / (peak0.b - peak0.r));
  result.xyz += getSpectrum(theta, vec3(iBrightness0), peak0, range0);

  // Secondary bow: wider, dimmer, and colour-reversed.
  vec3 peak1 = vec3(180.0 - 129.5,
                    180.0 - (129.5 + 126.1) * 0.5,
                    180.0 - 126.1) +
               vec3((iGap - 0.5) * 180.0) + vec3((iRadius - 0.5) * 180.0);
  vec3 range1 = vec3(1.0 / (peak1.b - peak1.r));
  result.xyz += getSpectrum(theta, vec3(iBrightness1), peak1, range1);

  float aFactor = max(smoothstep(peak0.r + 1.0, peak0.b - 1.0, theta),
                      smoothstep(peak1.r - 1.0, peak1.b + 1.0, theta) * 0.2);
  result.a = 1.0 - aFactor;
  return result;
}

/// Keeps the bow off the lit side of the sky.
float rainbowShadow(vec3 p) {
  float f = -p.x * 1.1 + p.y - 1.5 - p.z;
  return clamp(f * 0.05 + 0.1, 0.0, 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / iResolution;
  float aspect = iResolution.x / max(iResolution.y, 1.0);

  float opacity = clamp(iOpacity, 0.0, 1.0);
  if (opacity < 0.004) {
    fragColor = vec4(0.0);
    return;
  }

  // Same view ray construction as the sky, so the bow sits in the same space.
  vec2 ndc = vec2(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0) * vec2(aspect, 1.0);
  float tanHalfFov = tan(iFov * 0.5);
  vec3 camRay = normalize(vec3(ndc.x * tanHalfFov, ndc.y * tanHalfFov, 1.0));
  float cp = cos(iPitch);
  float sp = sin(iPitch);
  vec3 rayDir = vec3(camRay.x,
                     camRay.y * cp + camRay.z * sp,
                     camRay.z * cp - camRay.y * sp);

  vec3 rayOrigin = vec3(0.0, 0.0, 0.0);

  // Optical depth through the moisture sphere centred on the viewer.
  vec3 offset = -rayOrigin;
  float d = dot(rayDir, offset);
  vec3 closest = rayOrigin + rayDir * d;
  float l = length(closest);
  float r = max(iVisRange, 1e-3);
  if (l >= r) {
    fragColor = vec4(0.0);
    return;
  }

  float f = (r - l) / r;
  f = f * f * f;
  float opticalDepth = 10.0 * f * 0.1;
  float amount = 1.0 - exp2(-opticalDepth);

  float shadow = rainbowShadow(rayOrigin) * 0.75 + 0.25;
  float strength = clamp(amount * shadow, 0.0, 1.0);

  vec3 sunDir = normalize(iSunDir);
  float dp = clamp(dot(sunDir, rayDir), -1.0, 1.0);
  vec4 bow = rainbowRGBA(degrees(acos(dp)) + 0.5);

  // The reference's 0.6 brightness trim keeps the bow from reading as neon.
  vec3 color = bow.xyz * strength * 0.6 * opacity;

  float a = clamp(max(color.r, max(color.g, color.b)), 0.0, 1.0);
  if (a < 0.003) {
    fragColor = vec4(0.0);
    return;
  }

  fragColor = vec4(color, a); // premultiplied
}
