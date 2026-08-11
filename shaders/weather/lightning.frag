// Lightning layer — a port of the reference engine's
// The reference shader (the full-screen flash) and
// The reference shader (the bolt and its branch timing).
//
// The reference builds the bolt as CPU-generated branch geometry drawn as point
// sprites, with `vAttri` carrying "is this the main branch" and the point's
// normalised position along the path. A fragment shader has no geometry, so
// the channel is reconstructed as a distance field: the bolt's horizontal
// position at each height is a sum of noise octaves seeded per strike, and
// the pixel's distance to that path becomes the glow. Forks are the same
// function with a lateral bias, gated to start partway down.
//
// The timing envelope is the reference's, and it is the part that sells the effect:
// `uExpandPath` grows the channel downward (pixels below the growth front are
// discarded), the main branch then holds and fades over `uMainBranchFade`,
// and sub-branches fade faster over `uSubBranchFade`. The flash is a separate
// smoothstep pulse — `start → peek → fade` — tinted from `iBottomCol` to
// `iTopCol` up the screen.
//
// The flash is deliberately capped well below full white: this is a
// disaster-prevention app, and a full-screen strobe at high frequency is a
// photosensitivity hazard. The Dart side additionally rate-limits strikes.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution (0..1)   render size in pixels
//   iTopCol     (2..4)   flash colour at the top of the screen
//   iBottomCol  (5..7)   flash colour at the horizon
//   iBoltCol    (8..10)  bolt core colour
//   iTime       (11)     seconds since this strike began
//   iFlash      (12)     flash intensity 0..1
//   iBoltAlpha  (13)     bolt opacity 0..1
//   iSeed       (14)     per-strike seed (path shape, position)
//   iExpandPath (15)     seconds for the channel to reach full length
//   iBranchShow (16)     seconds the main branch holds at full brightness
//   iBranchFade (17)     seconds for the main branch to fade
//   iSubFade    (18)     seconds for sub-branches to fade
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec3 iTopCol;
uniform vec3 iBottomCol;
uniform vec3 iBoltCol;
uniform float iTime;
uniform float iFlash;
uniform float iBoltAlpha;
uniform float iSeed;
uniform float iExpandPath;
uniform float iBranchShow;
uniform float iBranchFade;
uniform float iSubFade;

out vec4 fragColor;

/// Hard ceiling on flash brightness — photosensitivity guard.
const float kMaxFlash = 0.62;

float hash11(float n) {
  return fract(sin(n * 127.1) * 43758.5453);
}

/// Value noise in 1D, for the channel's lateral wander.
float vnoise1(float x) {
  float i = floor(x);
  float f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  return mix(hash11(i), hash11(i + 1.0), f);
}

/// Horizontal position of a bolt channel at height [y] (0 top → 1 bottom).
///
/// [seed] picks the strike, [wander] scales how far it strays.
float pathX(float y, float seed, float wander) {
  float x = 0.0;
  x += (vnoise1(y * 3.0 + seed) - 0.5) * 1.00;
  x += (vnoise1(y * 7.0 + seed * 3.1) - 0.5) * 0.42;
  x += (vnoise1(y * 17.0 + seed * 7.7) - 0.5) * 0.16;
  x += (vnoise1(y * 41.0 + seed * 11.3) - 0.5) * 0.06;
  return x * wander;
}

/// Glow contribution of one channel, given the pixel's horizontal distance.
float channel(float dist, float core, float glow) {
  float c = smoothstep(core, 0.0, dist);          // hot core
  float g = exp(-dist / max(glow, 1e-4)) * 0.55;  // corona
  return c + g;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / iResolution;
  float aspect = iResolution.x / max(iResolution.y, 1.0);

  vec3 color = vec3(0.0);

  // --- full-screen flash (thunder_light_frag) -----------------------------
  // A single pulse: rise to the peak, then decay.
  float peek = iBranchShow;
  float pulse = smoothstep(max(peek - 0.05, 0.0), peek, iTime) *
                (1.0 - smoothstep(peek, peek + iBranchFade, iTime));
  float intensity = clamp(iFlash, 0.0, 1.0) * pulse;
  intensity = min(intensity, kMaxFlash);
  // The reference tints bottom → top; the flash is brightest where the cloud is.
  color += mix(iBottomCol, iTopCol, 1.0 - uv.y) * intensity * 0.8;

  // --- bolt (thunder_frag) ------------------------------------------------
  float boltAlpha = clamp(iBoltAlpha, 0.0, 1.0);
  if (boltAlpha > 0.005 && iTime < iExpandPath + iBranchShow + iBranchFade) {
    // Growth front: nothing below it has been drawn yet.
    float grown = iTime <= iExpandPath ? iTime / max(iExpandPath, 1e-4) : 1.0;

    // Strike origin, stable per seed, biased to the upper half.
    float originX = mix(0.18, 0.82, hash11(iSeed * 1.7));
    // Bolts stop partway down — they strike toward, not into, the sheet.
    float endY = mix(0.45, 0.78, hash11(iSeed * 5.3));

    // Aspect-correct so the channel is not stretched on wide screens.
    float px = (uv.x - originX) * aspect;
    float y = uv.y;

    float visible = step(y, grown * endY);
    float taper = 1.0 - smoothstep(endY * 0.7, endY, y); // thins toward the tip

    // Main channel.
    float mainX = pathX(y, iSeed, 0.16);
    float mainDist = abs(px - mainX);
    float mainAge = clamp((iTime - iExpandPath - iBranchShow) /
                          max(iBranchFade, 1e-4), 0.0, 1.0);
    float mainLife = 1.0 - mainAge;
    color += iBoltCol * channel(mainDist, 0.0035, 0.020) * visible * taper *
             mainLife * boltAlpha;

    // Two forks, each leaving the trunk at its own height.
    float subAge = clamp((iTime - iExpandPath) / max(iSubFade, 1e-4), 0.0, 1.0);
    float subLife = 1.0 - subAge;
    for (int i = 0; i < 2; i++) {
      float fs = iSeed + float(i) * 23.0 + 4.0;
      float forkY = mix(0.18, 0.50, hash11(fs));
      if (y < forkY) continue;
      float t = y - forkY;
      // The fork inherits the trunk's position, then diverges.
      float dir = hash11(fs * 3.0) > 0.5 ? 1.0 : -1.0;
      float forkX = pathX(forkY, iSeed, 0.16) +
                    pathX(y + fs, fs, 0.10) - pathX(forkY + fs, fs, 0.10) +
                    dir * t * mix(0.35, 0.8, hash11(fs * 7.0));
      float forkEnd = forkY + mix(0.10, 0.26, hash11(fs * 11.0));
      float forkVis = step(y, min(grown * endY, forkEnd));
      float forkTaper = 1.0 - smoothstep(forkY, forkEnd, y);
      color += iBoltCol * channel(abs(px - forkX), 0.0018, 0.011) * forkVis *
               forkTaper * subLife * boltAlpha * 0.7;
    }
  }

  float a = clamp(max(color.r, max(color.g, color.b)), 0.0, 1.0);
  if (a < 0.003) {
    fragColor = vec4(0.0);
    return;
  }

  fragColor = vec4(clamp(color, 0.0, 1.0), a); // premultiplied
}
