// Sky screen pass — stage 3.
//
// This is a **pure vertical gradient**: every pixel in a horizontal row gets
// the same colour. The sky has no azimuthal variation and no sun disc — the
// disc belongs to the separate sun layer. All this pass does is turn a screen
// row into a view elevation and read the colour stage 2 already integrated
// for it.
//
// The elevation comes from the frustum built in `sky_lut_cache.dart`: a narrow
// band of sky a little above the horizon — roughly 3.6° to 22.9° of elevation
// at the default yaw — rather than a full dome. Widening that band is the
// single biggest change available to the look. `uFrustumA` (top ray) and
// `uFrustumC` (bottom ray) are unit directions rebuilt on the CPU from the
// keyframe's `cameraYaw`.
//
// Uniform contract — slots are float indices in declaration order.
//   uResolution (0..1)   render size in pixels
//   uFrustumA   (2..4)   top-of-frustum ray
//   uFrustumC   (5..7)   bottom-of-frustum ray
//   uSunAngleY  (8)      sky-LUT u coordinate (the keyframe's authored value)
//   uTime       (9)      animation time (dither scroll)
//   uLutSize    (10..11) stage-2 LUT size in texels
//   sampler 0: uSkyView  stage-2 LUT
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 uResolution;
uniform vec3 uFrustumA;
uniform vec3 uFrustumC;
uniform float uSunAngleY;
uniform float uTime;
uniform vec2 uLutSize;
uniform sampler2D uSkyView;

out vec4 fragColor;

#define PI 3.14159265359

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

/// Bilinear LUT fetch — Flutter binds samplers as NEAREST and offers no way
/// to ask for linear, while the engine's LUTs are LINEAR. Without this the
/// sky shows one visible step per LUT row.
vec3 sampleLut(vec2 uv) {
  vec2 texel = 1.0 / uLutSize;
  vec2 st = uv * uLutSize - 0.5;
  vec2 base = floor(st);
  vec2 f = st - base;
  vec2 uv0 = (base + 0.5) * texel;

  vec3 c00 = texture(uSkyView, uv0).rgb;
  vec3 c10 = texture(uSkyView, uv0 + vec2(texel.x, 0.0)).rgb;
  vec3 c01 = texture(uSkyView, uv0 + vec2(0.0, texel.y)).rgb;
  vec3 c11 = texture(uSkyView, uv0 + texel).rgb;
  return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

void main() {
  vec2 fc = FlutterFragCoord().xy;
  vec2 uv = fc / uResolution;

  // Screen top → FrustumA, bottom → FrustumC. Flutter's fragment coordinate
  // already has y increasing downward, so no flip is needed here (the reference flips
  // because its own vUv has y up).
  vec3 dir = normalize(mix(uFrustumA, uFrustumC, uv.y));

  float theta = asin(clamp(dir.y, -1.0, 1.0));
  float v = 0.5 + 0.5 * sign(theta) * sqrt(abs(theta) / (PI / 2.0));

  // The reference's remap into the 141-row LUT, plus its sub-texel dither (0.00375)
  // which hides the row seams in the steep gradient near the horizon.
  float jitter = (hash12(fc + vec2(0.0, floor(uTime * 8.0))) - 0.5) * 0.00375;
  float lutV = clamp((v * 256.0 - 115.0) / 141.0 + jitter, 0.0, 1.0);

  vec3 color = sampleLut(vec2(clamp(uSunAngleY, 0.0, 1.0), lutV));

  fragColor = vec4(color, 1.0);
}
