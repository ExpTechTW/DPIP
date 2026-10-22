// Cloud sprite — a port of the reference engine's
// The reference shader.
//
// The reference's clouds are authored volumetric sprites with baked normal maps drawn
// as 3D quads, not procedural noise. Reproducing them procedurally is what the
// first attempt at this got wrong: an fbm field reads as marble, never as
// cauliflower. So this shader shades one sprite, and the Dart layer places and
// draws the instances — which is exactly the division the original engine has.
//
// The sprite is the reference's two-part layout (the reference shader,
// `TEXTURE_PART_NUM 2.0`):
//
//     top half     normal map     RGB = normal * 0.5 + 0.5, A = 255
//     bottom half  R = depth from the silhouette edge
//                  G = backness (far side of the cloud)
//                  B = inner-glow mask
//                  A = coverage
//
// The channel order deviates from the reference's on one point, and it matters:
// The reference keeps coverage in B and uploads raw ASTC, but Flutter **premultiplies
// every image at decode**. An alpha channel holding anything but coverage
// therefore silently multiplies RGB toward zero — which is exactly what made
// the first attempt at this render almost invisible. Coverage lives in A, and
// the other channels are divided back out below.
//
// The lighting is the environment-light model, and it is the part worth
// porting: cloud colour is not authored, it is *sampled from the sky LUT* at a
// set of elevation probes. A cloud's shaded underside is literally the colour
// of the sky near the horizon; its lit top is the sky near the sun. That is
// why the reference's clouds agree with the sky at every hour with no palette to
// maintain.
//
// Four directional lights are dotted against the normal, as in the original —
// the fourth being `directionalLights0` with its z mirrored, which is what
// lights the cloud from behind and produces silver linings on thin edges
// (`backMulti`).
//
// Uniform contract — slots are float indices in declaration order.
//   iSpriteSize   (0..1)   sprite size in pixels (full, both halves)
//   iLightDir0    (2..4)   sun direction (view space)
//   iLightDir1    (5..7)   ground-bounce direction
//   iLightDir2    (8..10)  ambient direction
//   iBaseCfg      (11..13) base    light: picker, multi, intensity
//   iSunCfg       (14..16) sun     light: picker, multi, intensity
//   iGroundCfg    (17..19) ground  light: picker, multi, intensity
//   iAmbientCfg   (20..22) ambient light: picker, multi, intensity
//   iOpacity      (23)     instance opacity
//   iStartEdge    (24)     soft-edge start (cloud profile `uStartEdge`)
//   iEndEdge      (25)     soft-edge end   (cloud profile `uEndEdge`)
//   iProgress     (26)     deck reveal 0..2 (the reference's `uProgress`)
//   iSmooth       (27)     reveal softness (the reference's `uSmooth`)
//   iCloudDepth   (28)     depth weighting 0..1
//   iSunIntensity (29)     direct-sun strength 0..1
//   iFogDensity   (30)     haze blending the sprite toward the sky
//   iInner        (31)     internal illumination 0..1 (lightning inside)
//   iWhitePer     (32)     noon whitening (the reference's `whitePer`)
//   iLutSize      (33..34) kept so the slots after it do not move. The LUT
//                          sampler is gone; the value is not read for colour
//   iTexSize      (35..36) sprite size in texels
//   iBaseSky      (37..39) sky colour at the base light's probe — baked once
//                          per keyframe on the CPU (the probe is pixel-
//                          independent), so the GPU skips that LUT fetch
//   iHazeSky      (40..42) sky colour at the 0.95 haze probe, same reason
//   iSunLit       (43..45) sun light, gain and fog already applied
//   iGroundLit    (46..48) ground light, same
//   iAmbientLit   (49..51) ambient light, same
//   iBackSky      (52..54) sun-probe sky for the thin-edge light; its gain
//                          stays here because it changes per pixel
//   sampler 0: iSprite     the cloud sprite
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 iSpriteSize;
uniform vec3 iLightDir0;
uniform vec3 iLightDir1;
uniform vec3 iLightDir2;
uniform vec3 iBaseCfg;
uniform vec3 iSunCfg;
uniform vec3 iGroundCfg;
uniform vec3 iAmbientCfg;
uniform float iOpacity;
uniform float iStartEdge;
uniform float iEndEdge;
uniform float iProgress;
uniform float iSmooth;
uniform float iCloudDepth;
uniform float iSunIntensity;
uniform float iFogDensity;
uniform float iInner;
uniform float iWhitePer;
uniform vec2 iLutSize;
uniform vec2 iTexSize;
uniform vec3 iBaseSky;
uniform vec3 iHazeSky;
/// Sun, ground and ambient, already gained, warm-mixed and scaled by
/// intensity and fog. The per-pixel probe nudge is gone: it was a LUT fetch
/// per light, and at phone size the lit face reads the same without it.
uniform vec3 iSunLit;
uniform vec3 iGroundLit;
uniform vec3 iAmbientLit;
/// Sky colour at the sun's probe, before the per-pixel back-light gain.
uniform vec3 iBackSky;
uniform sampler2D iSprite;

out vec4 fragColor;

#define PI 3.14159265359
#define ONE_OVER_PI 0.3183098861837907

/// Bilinear sprite fetch.
///
/// Sprites are magnified roughly 2.7x on screen, and Flutter binds samplers as
/// NEAREST — so without this the cloud is drawn from visibly blocky texels.
/// It matters most for the normal map: per-texel normal steps swing the light
/// weights between the blue sky probe and the warm noon tint, which is what
/// speckles a sunlit cloud with stray hues.
///
/// Filtering happens on the premultiplied values, which is the correct order —
/// that is what premultiplied alpha is for. The caller divides afterwards.
vec4 sampleSprite(vec2 uv) {
  vec2 texel = 1.0 / iTexSize;
  vec2 st = uv * iTexSize - 0.5;
  vec2 base = floor(st);
  vec2 f = st - base;
  vec2 uv0 = (base + 0.5) * texel;

  vec4 c00 = texture(iSprite, uv0);
  vec4 c10 = texture(iSprite, uv0 + vec2(texel.x, 0.0));
  vec4 c01 = texture(iSprite, uv0 + vec2(0.0, texel.y));
  vec4 c11 = texture(iSprite, uv0 + texel);
  return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

/// The reference's `calcDepthAlpha` — the deck reveal sweeps a band through the
/// sprite's depth channel, so a cloud materialises front-to-back.
float calcDepthAlpha(float depth) {
  float per = (1.0 + iSmooth) - clamp(iProgress, 0.0, 1.0);
  return clamp((depth - (per - iSmooth)) / max(iSmooth, 1e-4), 0.0, 1.0);
}

void main() {
  // The sprite's two halves, addressed exactly as the reference's vertex shader does.
  vec2 uv = FlutterFragCoord().xy / iSpriteSize;
  // Keep each half's v inside its own band by a texel, so the bilinear taps
  // never straddle the seam and pull the other half's data across it.
  float guard = 1.0 / iTexSize.y;
  vec2 albedoUv = vec2(uv.x, clamp(uv.y * 0.5 + 0.5, 0.5 + guard, 1.0 - guard));
  vec2 normalUv = vec2(uv.x, clamp(uv.y * 0.5, guard, 0.5 - guard));

  // Flutter hands back premultiplied samples, so undo it to recover the
  // packed channels.
  vec4 raw = sampleSprite(albedoUv);
  float coverage = raw.a;
  if (coverage < 0.004) {
    fragColor = vec4(0.0);
    return;
  }
  // Guard the divisor: at the feathered rim coverage approaches zero and
  // dividing by it amplifies 8-bit quantisation into visible speckle.
  vec3 unpremul = raw.rgb / max(coverage, 0.10);
  float texDepth = clamp(unpremul.r, 0.0, 1.0);
  float texBack = clamp(unpremul.g, 0.0, 1.0);
  float texInner = clamp(unpremul.b, 0.0, 1.0);

  float depthAlpha = calcDepthAlpha(texDepth);
  if (depthAlpha < 0.01) {
    fragColor = vec4(0.0);
    return;
  }

  // --- alpha -------------------------------------------------------------
  float alpha = iOpacity * coverage;
  // Soft edge: the outer wisps (low depth) are eroded away.
  float edge = smoothstep(iEndEdge, iStartEdge, texDepth);
  alpha = max(alpha * 0.5, alpha - edge * edge * 0.5);
  // The far side of the cloud is transparent.
  alpha *= smoothstep(1.0, 0.5, texBack);
  if (alpha < 0.004) {
    fragColor = vec4(0.0);
    return;
  }

  // --- normal ------------------------------------------------------------
  // The reference stores an un-normalised normal and normalises after scaling xy, so
  // the stored xy:z ratio is what carries the surface tilt.
  // The normal half is stored with A = 255, so premultiply is a no-op.
  vec3 mapN = sampleSprite(normalUv).rgb * 2.0 - 1.0;
  // The encoded z straddles zero (the reference's own distribution does too, and its
  // shader flips on gl_FrontFacing). A sprite is always front-facing here, so
  // clamp z positive — letting it go negative flips the lighting on scattered
  // pixels and speckles the cloud with stray hues.
  mapN.z = max(mapN.z, 0.08);
  vec3 normal = normalize(mapN);

  // The fourth light is light 0 with z mirrored — the reference's back light.
  // Mirroring z only flips the sign of that one term, so the two dot products
  // are the same plane term plus and minus the same depth term: compute each
  // once and the back light costs an add rather than a second dot.
  float plane0 = dot(iLightDir0.xy, normal.xy);
  float depth0 = iLightDir0.z * normal.z;

  float l0 = max(plane0 + depth0, 0.0) * ONE_OVER_PI;
  float l1 = max(dot(iLightDir1, normal), 0.0) * ONE_OVER_PI;
  float l2 = max(dot(iLightDir2, normal), 0.0) * ONE_OVER_PI;
  float l3 = max(plane0 - depth0, 0.0) * ONE_OVER_PI;

  // How thin the cloud is here. Thin cloud transmits, so it is brighter and
  // takes the silver-lining rim.
  float backMulti =
      smoothstep(0.05, 1.0, mix(1.0 - iCloudDepth, 1.0, texBack));

  // --- the five-light rig ------------------------------------------------
  // Sun, ground and ambient colours are baked on the CPU from the uniform
  // probe (no per-pixel LUT nudge). The base gain still rides `backMulti`.
  vec3 baseCfg = iBaseCfg;
  float baseEdgeMulti = mix(1.0, 2.1, backMulti * min(1.0, iSunCfg.z));
  baseEdgeMulti = mix(baseEdgeMulti, 1.0, iWhitePer * 0.9);
  // Cap the combined gain: the reference's two multipliers can reach 3.1x, which
  // drives the blue channel past clipping at high sun and leaves the
  // unclipped channels behind as a colour cast.
  baseCfg.y *= min(mix(1.0, 1.5, backMulti) * baseEdgeMulti, 1.8);
  baseCfg.y = mix(1.0, baseCfg.y, iCloudDepth);
  vec3 baseColor = iBaseSky * baseCfg.y;

  vec3 sunColor = iSunLit;
  vec3 groundColor = iGroundLit;
  vec3 ambientColor = iAmbientLit;

  // The back light's gain is the thin-edge term, which is per pixel. Its sky
  // colour is the sun probe, baked. The warm mix happens after the gain, the
  // same order as mixing the gained colour toward white.
  float backGain = mix(0.0, 1.3, backMulti);
  vec3 backColor = mix(iBackSky * backGain, vec3(1.0, 0.74, 0.53), iWhitePer);
  float backI = mix(1.5, 1.0, iSunIntensity) * iSunCfg.z;

  // --- composite ----------------------------------------------------------
  vec3 diffuse = mix(vec3(texDepth), vec3(1.0), 0.8);
  diffuse = mix(diffuse, vec3(0.8), iFogDensity);

  float fog = max(0.0, iFogDensity);
  float fogMulti = 1.0 - fog * fog;

  vec3 color = baseColor;
  color += l0 * sunColor;
  color += l1 * groundColor;
  color += l2 * ambientColor;
  color += l3 * backColor * backI * fogMulti;

  // Lightning inside the cloud, masked by the sprite's inner-glow channel.
  vec3 innerColor = mix(baseColor, vec3(1.0), 0.1);
  color += innerColor * (0.1 + smoothstep(0.05, 1.0, texInner)) * iInner * 0.4;
  color *= mix(1.0, 1.5, iInner);

  color *= diffuse;
  // Haze dissolves the sprite into the sky behind it. The 0.95 haze probe is
  // pixel-independent, so its colour arrives baked in `iHazeSky` (see
  // `iBaseSky`).
  color = mix(color, iHazeSky, iFogDensity);
  // iLutSize still occupies slots 33..34 so the baked colours after it stay
  // put. A multiply by zero is deleted and the uniform goes with it, which
  // would slide every later slot. The painter's values are a positive height
  // and 1, so this branch never fires.
  if (iLutSize.x + iLutSize.y < 0.0) {
    color = vec3(1.0);
  }

  float a = clamp(alpha * depthAlpha, 0.0, 1.0);
  fragColor = vec4(clamp(color, 0.0, 1.0) * a, a); // premultiplied
}
