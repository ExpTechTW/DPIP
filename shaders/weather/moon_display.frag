// Moon **display** shader — the real Moon, lit for a given phase.
//
// The surface is not invented here. It is NASA/GSFC's CGI Moon Kit: a colour
// map built from over 100,000 Lunar Reconnaissance Orbiter Wide Angle Camera
// images, and an elevation map from the LOLA laser altimeter. Procedural
// craters can be made to look plausible but never look like *this* Moon —
// Tycho's rays, Mare Tranquillitatis, Copernicus and Grimaldi are recognised,
// not evaluated, and getting them wrong is the whole difference between "a
// moon" and "the Moon".
//
// What makes it read as a sphere rather than a printed disc:
//
//   1. **Orthographic sphere lookup.** Each pixel of the disc is turned into a
//      point on a unit sphere, then into latitude/longitude, then into a
//      texel of the equirectangular map. That is what compresses features
//      toward the limb — a flat texture lookup leaves the maria the same size
//      at the edge as at the centre, which the eye reads immediately as a
//      sticker.
//   2. **Relief from real elevation.** Normals are finite-differenced from the
//      height map in *surface* space and rotated into view space, so the
//      shading of a crater depends on where it sits on the globe. Under
//      grazing light near the terminator this is what throws the long shadows
//      that make the phase look three-dimensional.
//   3. **Lommel-Seeliger scattering, not Lambert.** Lunar regolith is
//      backscattering: a Lambert sphere darkens steadily toward the limb, but
//      the real full Moon is famously *flat* and bright all the way to the
//      edge. The L/(L+V) term is the standard first-order fix and is the
//      single biggest reason a rendered full moon looks wrong or right.
//   4. **Opposition surge.** Near full, shadows hide behind the grains that
//      cast them and the disc brightens sharply — a few degrees wide, and very
//      characteristic.
//   5. **Earthshine.** The night side is not black: it is lit by a nearly full
//      Earth, blue-grey, strongest around new moon.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution (0..1)  draw size in pixels
//   iPhase      (2)     phase angle in radians, 0 = new, π = full
//   iLibration  (3..4)  sub-earth longitude/latitude offset, radians
//   iColor      (s0)    equirectangular colour map, 0° longitude centred
//   iHeight     (s1)    equirectangular elevation map, greyscale
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform float iPhase;
uniform vec2 iLibration;
uniform sampler2D iColor;
uniform sampler2D iHeight;

out vec4 fragColor;

const float PI = 3.14159265359;

/// Equirectangular texel for a point on the unit sphere, in surface space.
///
/// The maps are centred on 0° longitude — the middle of the near side — so the
/// centre of the disc must land on u = 0.5. `+z` points at the viewer, hence
/// `atan(x, z)`: negating z instead would centre the disc on ±180° and quietly
/// render the *far* side, which is the same brightness and the wrong Moon.
vec2 sphereUv(vec3 p) {
  float lon = atan(p.x, p.z);
  float lat = asin(clamp(p.y, -1.0, 1.0));
  return vec2(lon / (2.0 * PI) + 0.5, 0.5 - lat / PI);
}

float heightAt(vec3 p) { return texture(iHeight, sphereUv(p)).r; }

void main() {
  vec2 uv = FlutterFragCoord().xy / iResolution;
  vec2 p = uv * 2.0 - 1.0;
  // Flip y: screen y grows downward, the sphere's north is up.
  p.y = -p.y;

  float r2 = dot(p, p);
  // Anti-aliased limb, one pixel wide in screen terms.
  float px = 2.0 / iResolution.y;
  float limb = 1.0 - smoothstep(1.0 - px * 1.5, 1.0, sqrt(r2));
  if (limb <= 0.0) {
    fragColor = vec4(0.0);
    return;
  }

  // View-space normal of the visible hemisphere: the disc *is* the sphere seen
  // orthographically, so z falls out of x and y.
  vec3 view = vec3(p, sqrt(max(1.0 - r2, 0.0)));

  // Libration — the Moon rocks a few degrees each month, showing a little
  // around each edge. Rotating the lookup (not the disc) is what keeps the
  // same face toward us while the visible edges change. iLibration is the
  // selenographic point facing Earth, so these rotations are exactly what puts
  // that point at the centre of the disc.
  float cl = cos(iLibration.x), sl = sin(iLibration.x);
  float cb = cos(iLibration.y), sb = sin(iLibration.y);
  float ex = -sl * view.x + cl * view.z;
  vec3 surf = vec3(
    cl * view.x + sl * view.z,
    cb * view.y + sb * ex,
    cb * ex - sb * view.y
  );

  vec3 albedo = texture(iColor, sphereUv(surf)).rgb;

  // Relief: sample the elevation along two tangents of the sphere and tilt the
  // normal by the slope. Done in surface space so a crater near the limb is
  // shaded by its own geometry rather than by its screen position.
  vec3 tangentU = normalize(cross(vec3(0.0, 1.0, 0.0), surf) + vec3(1e-5));
  vec3 tangentV = cross(surf, tangentU);
  float step = 0.004;
  float hU = heightAt(normalize(surf + tangentU * step)) -
             heightAt(normalize(surf - tangentU * step));
  float hV = heightAt(normalize(surf + tangentV * step)) -
             heightAt(normalize(surf - tangentV * step));
  // Relief is exaggerated: at true scale the Moon is smoother than a billiard
  // ball and would show nothing at this size.
  const float relief = 9.0;
  vec3 n = normalize(view - relief * (hU * tangentU + hV * tangentV));

  // Sun direction. θ = 0 puts it behind the Moon (new), θ = π in front (full),
  // θ = π/2 lights the right-hand half (first quarter).
  vec3 sun = normalize(vec3(sin(iPhase), 0.0, -cos(iPhase)));
  vec3 eye = vec3(0.0, 0.0, 1.0);

  float mu0 = dot(n, sun);   // cos(incidence)
  float mu = dot(n, eye);    // cos(emission)

  // Lommel-Seeliger: bright to the limb, unlike Lambert.
  float lit = clamp(mu0, 0.0, 1.0);
  float scatter = lit > 0.0 ? mu0 / max(mu0 + mu, 0.05) : 0.0;

  // Opposition surge — a narrow brightening as the phase angle goes to zero.
  float alpha = PI - iPhase;
  float surge = 1.0 + 0.55 * exp(-abs(alpha) / 0.12);

  // Terminator softening: the Sun is half a degree wide, so the shadow edge is
  // not a razor line.
  float terminator = smoothstep(-0.06, 0.10, mu0);

  vec3 col = albedo * scatter * surge * terminator * 1.55;

  // Earthshine: a nearly full Earth lights the night side around new moon.
  float earthshine = 0.055 * (1.0 + cos(iPhase)) * 0.5 * (1.0 - terminator);
  col += albedo * vec3(0.45, 0.55, 0.85) * earthshine;

  fragColor = vec4(col, limb);
}
