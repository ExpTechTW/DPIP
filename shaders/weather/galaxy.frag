// Milky Way — a port of the reference engine
// (scene layer 1), drawn additively under the star field.
//
// This is a real sky, not a procedural band: an equirectangular photograph of
// the Milky Way is projected through a rotated camera, so the arch bends
// across the frame the way it actually does. A hand-drawn band cannot
// reproduce the dust lanes or the density falloff along the galactic plane.
//
// The projection, from the original:
//   • each pixel's screen offset becomes a small rotation of the view ray
//     `(0, 0, -1)` about y and then x, scaled by `uFov`
//   • that ray is then rotated into galactic orientation by `rx`, `ry`, `rz`
//
// Every rotation is by the NEGATIVE of its angle. GLSL's `mat4(...)` takes
// **columns**, so the engine's matrices — written out to read like row-major
// rotations — are their own transposes, i.e. rotations by `-angle`. And
// `rotate0 = rotateX0 * rotateY0` applied as `rotate0 * v` runs Y first.
// Getting either wrong lands on a different patch of sky: the diagonal arch
// flattens into a horizontal band.
//   • the result is converted to equirectangular UV with
//     `vec2(atan(dir.z, dir.x), asin(dir.y)) * vec2(0.1591, 0.3183) + 0.5`
//     (those constants are 1/2π and 1/π), then flipped on both axes because
//     the starmap is stored upside-down
//
// Beware the naming: `uGalaxyAlpha` is **not** an opacity — it is the first
// rotation angle, `rx = uGalaxyAlpha * 2π`. The engine's real values are
// alpha 0.38, theta 0.64, phi 0.16, fov 0.27, and the
// blend is `SRC_ALPHA, ONE` — additive.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution  (0..1) render size in pixels
//   iRotation    (2..4) galaxy orientation (alpha, theta, phi), in turns
//   iFov         (5)    field of view, in turns
//   iStaticTime  (6)    slow drift, added to the roll angle
//   iOpacity     (7)    overall opacity
//   iAlpha       (8)    night visibility 0..1
//   sampler 0: iStarMap equirectangular Milky Way
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec3 iRotation;
uniform float iFov;
uniform float iStaticTime;
uniform float iOpacity;
uniform float iAlpha;
uniform sampler2D iStarMap;

out vec4 fragColor;

#define PI 3.141592653
#define TWO_PI 6.283185307

float luminance(vec3 rgb) {
  return dot(vec3(0.2126729, 0.7151522, 0.0721750), rgb);
}

vec3 saturation(vec3 rgb, float amount) {
  vec3 intensity = vec3(dot(rgb, vec3(0.2125, 0.7154, 0.0721)));
  return mix(intensity, rgb, amount);
}

float cpfv(float v, float lo, float hi) {
  return clamp((v - lo) / (hi - lo), 0.0, 1.0);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / iResolution;
  // The engine's vUv has y up.
  uv.y = 1.0 - uv.y;

  float aspect = iResolution.x / max(iResolution.y, 1.0);
  vec2 st = (uv - 0.5) * 2.0;
  st.x *= aspect;
  // The reference's own framing tweaks for tall and wide screens.
  if (aspect > 0.8) st /= 1.4;
  if (aspect > 1.5) st.x += aspect / 2.0;

  float fov = iFov * TWO_PI;
  float rx0 = st.y * fov;
  float ry0 = st.x * fov;

  // Fade the far left and right, where the projection stretches badly.
  float edgeFade = cpfv(abs(ry0), PI / 3.0, PI / 2.5);

  // Screen ray: Y first, then X, both negated (see the note above).
  vec3 dir = vec3(0.0, 0.0, -1.0);
  float c1 = cos(-ry0), s1 = sin(-ry0);
  dir = vec3(dir.x * c1 + dir.z * s1, dir.y, -dir.x * s1 + dir.z * c1);
  float c0 = cos(-rx0), s0 = sin(-rx0);
  dir = vec3(dir.x, dir.y * c0 - dir.z * s0, dir.y * s0 + dir.z * c0);

  // Galactic orientation. `iRotation.x` is an angle despite being named alpha.
  float rx = iRotation.x * TWO_PI;
  float ry = iRotation.y * TWO_PI;
  float rz = iRotation.z * TWO_PI + iStaticTime / 150.0;

  // `rotate = rotateZ * rotateY * rotateX` applied as `rotate * v`: X, then Y,
  // then Z — again all negated.
  float cx = cos(-rx), sx = sin(-rx);
  dir = vec3(dir.x, dir.y * cx - dir.z * sx, dir.y * sx + dir.z * cx);
  float cy = cos(-ry), sy = sin(-ry);
  dir = vec3(dir.x * cy + dir.z * sy, dir.y, -dir.x * sy + dir.z * cy);
  float cz = cos(-rz), sz = sin(-rz);
  dir = vec3(dir.x * cz - dir.y * sz, dir.x * sz + dir.y * cz, dir.z);

  // Equirectangular lookup; 0.1591 = 1/2π and 0.3183 = 1/π.
  vec2 tx = vec2(atan(dir.z, dir.x), asin(clamp(dir.y, -1.0, 1.0)));
  tx *= vec2(0.1591, 0.3183);
  tx += 0.5;
  // The starmap is stored flipped on both axes.
  tx = 1.0 - tx;

  vec4 color = texture(iStarMap, tx);
  // The photograph is nearly monochrome; the reference pushes saturation hard so the
  // warm core and the cool dust separate.
  color.rgb = saturation(color.rgb, 4.0);
  color.a *= smoothstep(0.1, 0.2, luminance(color.rgb));

  // Fade out toward the horizon and the very top of the frame.
  // `1/exp(k)` is `exp(-k)`, which skips the reciprocal.
  float fb = clamp(1.0 - exp(-4.0 * uv.y * uv.y), 0.0, 1.0);
  float ft = clamp(mix(1.0, 0.0, (uv.y - 0.7) / 0.3), 0.0, 1.0);
  color.a *= ft * fb;

  color = mix(color, vec4(0.0), edgeFade);

  float a = clamp(color.a * iOpacity * clamp(iAlpha, 0.0, 1.0), 0.0, 1.0);
  if (a < 0.003) {
    fragColor = vec4(0.0);
    return;
  }

  fragColor = vec4(clamp(color.rgb, 0.0, 1.0) * a, a); // premultiplied
}
