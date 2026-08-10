// Water on the panel edge — the compositing half of the panel water, a port of
// the reference's rain branch (its snow and temperature branches are separate
// and are not used here).
//
// **The ambient is the sky.** The reference's ambient sampler is the 256×141
// sky-view LUT: the cloud shader indexes the very same sampler with the LUT's
// own `(y·256−115)/141` layout, the city scene passes the LUT in directly,
// and `J`'s constructor carries the FrustumA/C constants that exist only for
// that texture's mapping. The rain branch samples it at the fullscreen `vUv`
// — the sky colour at the panel's height — and brightens it:
//
//   ambient = sky × 1.3
//
// which is what makes the water read as *transparent*: a sky-tinted 0.6-alpha
// film with a glint, over whatever it lies on. Every constant tried in its
// place — black, white, the buffer's own normal sum — rendered as grey or
// clamped white; adversarial pixel checks on the normal-sum variant showed
// interiors saturating to (1,1,1) exactly as observed on device.
//
// [iAmbient] receives the LUT row the card band covers (published by the sky
// cache at each re-bake) with the ×1.3 applied by the shader, so the water is
// lit by the same sky the backdrop shows.
//
// 8-bit adaptation: unsigned surfaces cannot hold signed sums, so the Dart
// side accumulates the **positive and negative parts in two buffers** (same
// draw, two channel-packed sprites), scaled by the anti-saturation factor the
// threshold is also scaled by. This pass reassembles `Σn = pos − neg`,
// giving both `normalize(Σn)` and the self-lit ambient the float original
// computes.
//
// Uniform contract — slots are float indices in declaration order.
//   iResolution  (0..1) field size in pixels
//   iAmbient     (2..4) the sky-view LUT sample at the panel band (see above)
//   iSpecular    (5)    specular intensity (1.0 day / 1.2 night, panel branch)
//   iThreshold   (6)    alpha cut — the grade's cut x the accumulation scale
//   iAlpha       (7)    scene alpha (`uAlpha`), multiplied into the 0.6
//   iHour        (8)    local hour 0..23, steers the light sweep
//   sampler 0: iFieldPos  rgb = Σ(max(n,0)) — positive normal parts
//   sampler 1: iFieldNeg  rg = Σ(max(−n,0)), b = Σ kernel·0.784 (coverage)
//
// Alpha is deliberately unused in both: canvas surfaces store premultiplied
// colour, so any payload in an alpha-carrying channel would be scaled by it.
// Both sprites are opaque and every datum lives in a colour channel.
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iResolution;
uniform vec3 iAmbient;
uniform float iSpecular;
uniform float iThreshold;
uniform float iAlpha;
uniform float iHour;
uniform sampler2D iFieldPos;
uniform sampler2D iFieldNeg;

out vec4 fragColor;

/// The reference shader's `sunColor` — a desaturated mauve, not white.
const vec3 kSunColor = vec3(0.59, 0.55, 0.61);

/// `float gloss = 10.0;` on the shipped rain branch — written out as `s^10`
/// below, so no constant is needed.
const float kSurfaceAlpha = 0.6;

// Bilinear fetch — samplers bind NEAREST, and the two buffers must be
// filtered identically or the reassembled sum tears at texel edges. Two
// copies because SkSL rejects samplers as function parameters.
vec4 fieldPosTex(vec2 uv) {
  vec2 texel = 1.0 / iResolution;
  vec2 p = uv * iResolution - 0.5;
  vec2 f = fract(p);
  vec2 base = (floor(p) + 0.5) * texel;
  vec4 a = texture(iFieldPos, base);
  vec4 b = texture(iFieldPos, base + vec2(texel.x, 0.0));
  vec4 c = texture(iFieldPos, base + vec2(0.0, texel.y));
  vec4 d = texture(iFieldPos, base + texel);
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

vec4 fieldNegTex(vec2 uv) {
  vec2 texel = 1.0 / iResolution;
  vec2 p = uv * iResolution - 0.5;
  vec2 f = fract(p);
  vec2 base = (floor(p) + 0.5) * texel;
  vec4 a = texture(iFieldNeg, base);
  vec4 b = texture(iFieldNeg, base + vec2(texel.x, 0.0));
  vec4 c = texture(iFieldNeg, base + vec2(0.0, texel.y));
  vec4 d = texture(iFieldNeg, base + texel);
  return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / iResolution;

  vec3 pos = fieldPosTex(uv).rgb;
  vec3 neg = fieldNegTex(uv).rgb;

  // `if (texColor.a < 0.01) return;` then the metaball cut — the threshold is
  // far above the early-out, so one test covers both.
  if (neg.b <= iThreshold) {
    fragColor = vec4(0.0);
    return;
  }

  // Σn — only the direction is needed, so the accumulation scale cancels.
  vec3 sum = vec3(pos.rg - neg.rg, pos.b);
  float len = length(sum);
  if (len < 1e-4) {
    fragColor = vec4(0.0);
    return;
  }
  vec3 normal = sum / len;

  // The day/night light sweep, verbatim.
  float timePer = smoothstep(0.0, 12.0, iHour) - smoothstep(12.0, 23.0, iHour);
  vec3 lightDir =
      normalize(mix(vec3(-0.2, 0.4, 0.2), vec3(0.0, 1.0, 0.2), timePer));
  if (iHour >= 12.0) lightDir.x *= -1.0;

  vec3 viewDir = vec3(0.0, 0.0, 1.0);
  vec3 halfDir = normalize(viewDir + lightDir);

  // x^10, written out — a constant-exponent `pow` would compile to log/exp;
  // five multiplies are cheaper and bit-identical.
  float s = max(dot(normal, halfDir), 0.0);
  float s2 = s * s;
  float specular = s2 * s2 * s2 * s2 * s2;
  // `texture(uBgLightTex, vUv).rgb * 1.3` — the sky at the panel's height.
  vec3 color = iAmbient * 1.3 + specular * kSunColor * iSpecular;

  // `oFragColor.a = (texColor.a > uAlphaThreshold) ? alpha : 0.0; a *= uAlpha`
  float a = kSurfaceAlpha * clamp(iAlpha, 0.0, 1.0);
  fragColor = vec4(clamp(color, 0.0, 1.0) * a, a); // premultiplied
}
