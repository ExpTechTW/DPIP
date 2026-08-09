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
//   iSunElevParam (23)     sky-LUT u coordinate for the current keyframe
//   iOpacity      (24)     instance opacity
//   iStartEdge    (25)     soft-edge start (cloud profile `uStartEdge`)
//   iEndEdge      (26)     soft-edge end   (cloud profile `uEndEdge`)
//   iProgress     (27)     deck reveal 0..2 (the reference's `uProgress`)
//   iSmooth       (28)     reveal softness (the reference's `uSmooth`)
//   iCloudDepth   (29)     depth weighting 0..1
//   iSunIntensity (30)     direct-sun strength 0..1
//   iFogDensity   (31)     haze blending the sprite toward the sky
//   iInner        (32)     internal illumination 0..1 (lightning inside)
//   iWhitePer     (33)     noon whitening (the reference's `whitePer`)
//   iLutSize      (34..35) sky LUT size in texels
//   iTexSize      (36..37) sprite size in texels
//   sampler 0: iSprite     the cloud sprite
//   sampler 1: iSkyView    the sky LUT (`sky/sky_lut.frag`)
#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec2 iSpriteSize;
uniform vec3 iLightDir0;
uniform vec3 iLightDir1;
uniform vec3 iLightDir2;
uniform vec3 iBaseCfg;
uniform vec3 iSunCfg;
uniform vec3 iGroundCfg;
uniform vec3 iAmbientCfg;
uniform float iSunElevParam;
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
uniform vec3 iFrustumA;
uniform vec3 iFrustumC;
uniform vec2 iTexSize;
uniform sampler2D iSprite;
uniform sampler2D iSkyView;

out vec4 fragColor;

#define PI 3.14159265359
#define ONE_OVER_PI 0.3183098861837907

/// Bilinear sky-LUT fetch. Flutter binds samplers as NEAREST with no way to
/// request linear, so without this the cloud lighting steps as the sun moves.
vec3 sampleLut(vec2 uv) {
  vec2 texel = 1.0 / iLutSize;
  vec2 st = uv * iLutSize - 0.5;
  vec2 base = floor(st);
  vec2 f = st - base;
  vec2 uv0 = (base + 0.5) * texel;

  vec3 c00 = texture(iSkyView, uv0).rgb;
  vec3 c10 = texture(iSkyView, uv0 + vec2(texel.x, 0.0)).rgb;
  vec3 c01 = texture(iSkyView, uv0 + vec2(0.0, texel.y)).rgb;
  vec3 c11 = texture(iSkyView, uv0 + texel).rgb;
  return mix(mix(c00, c10, f.x), mix(c01, c11, f.x), f.y);
}

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

/// The sky's colour at probe [picker], 0 = horizon … 1 = zenith.
///
/// NOT yet the environment-light model. The engine's probe walks the **camera
/// frustum** — `texCoord2uv` does `normalize(mix(FrustumA, FrustumC, 1 -
/// probe))`, a band of roughly -0.4 to +19 degrees with its 20-degree lens —
/// so every probe lands near the horizon, the brightest part of the sky.
///
/// That is correct, and it was tried: with the frustum band all four lights
/// return bright haze, the four-light sum passes 1 and the sprites clamp to
/// solid white. The reference keeps it in range because it weights those lights with
/// the **authored per-keyframe `cloudConfig`** (picker/multi/intensity per
/// light), while this port still synthesises them from one `day` scalar and
/// runs far hotter.
///
/// So this deliberately keeps the wider 0..90-degree mapping, which stays in
/// range at the cost of taking fill light from zenith blue rather than
/// horizon haze. Switching to the real band is blocked on consuming the
/// authored cloudConfig — the same prerequisite as the real `whitePer` curve.
vec3 skyAt(float picker) {
  float elevation = clamp(picker, 0.0, 1.0) * (PI / 2.0);
  float m = sqrt(elevation / (PI / 2.0));
  float v = clamp((m + 0.1015625) / 1.1015625, 0.0, 1.0);
  return sampleLut(vec2(clamp(iSunElevParam, 0.0, 1.0), v));
}

/// The reference's `readColorConfig`: sample the sky at the config's probe, then gain.
vec3 readColorConfig(vec3 cfg) {
  return skyAt(cfg.x) * cfg.y;
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
  vec3 lightDir3 = vec3(iLightDir0.xy, -iLightDir0.z);

  float l0 = max(dot(iLightDir0, normal), 0.0) * ONE_OVER_PI;
  float l1 = max(dot(iLightDir1, normal), 0.0) * ONE_OVER_PI;
  float l2 = max(dot(iLightDir2, normal), 0.0) * ONE_OVER_PI;
  float l3 = max(dot(lightDir3, normal), 0.0) * ONE_OVER_PI;

  // How thin the cloud is here. Thin cloud transmits, so it is brighter and
  // takes the silver-lining rim.
  float backMulti =
      smoothstep(0.05, 1.0, mix(1.0 - iCloudDepth, 1.0, texBack));

  // --- the five-light rig, all sampled from the sky -----------------------
  vec3 baseCfg = iBaseCfg;
  float baseEdgeMulti = mix(1.0, 2.1, backMulti * min(1.0, iSunCfg.z));
  baseEdgeMulti = mix(baseEdgeMulti, 1.0, iWhitePer * 0.9);
  // Cap the combined gain: the reference's two multipliers can reach 3.1x, which
  // drives the blue channel past clipping at high sun and leaves the
  // unclipped channels behind as a colour cast.
  baseCfg.y *= min(mix(1.0, 1.5, backMulti) * baseEdgeMulti, 1.8);
  baseCfg.x = mix(0.05, baseCfg.x, iCloudDepth);
  baseCfg.y = mix(1.0, baseCfg.y, iCloudDepth);
  vec3 baseColor = readColorConfig(baseCfg);

  // Each light samples the sky between its own probe and the next one, blended
  // by how strongly it hits — so a lit face reads the brighter sky.
  // The probe is nudged by how strongly the light hits, but only gently:
  // moving it the full way makes neighbouring pixels read different LUT rows
  // and speckles the cloud with stray hues.
  vec3 sunCfg =
      vec3(mix(iSunCfg.x, iGroundCfg.x, l0 * 0.35), iSunCfg.y, iSunCfg.z);
  vec3 sunColor = readColorConfig(sunCfg);
  float sunI = mix(0.3, sunCfg.z, iSunIntensity);

  vec3 groundCfg = vec3(mix(iGroundCfg.x, iAmbientCfg.x, l1 * 0.35),
                        iGroundCfg.y, iGroundCfg.z);
  vec3 groundColor = readColorConfig(groundCfg);
  float groundI = mix(0.3, groundCfg.z, iSunIntensity);

  vec3 ambientCfg = vec3(mix(iAmbientCfg.x, 1.0, l2 * 0.35), iAmbientCfg.y,
                         iAmbientCfg.z);
  vec3 ambientColor = readColorConfig(ambientCfg);
  float ambientI = mix(0.3, ambientCfg.z, iSunIntensity);

  vec3 backCfg = vec3(mix(iSunCfg.x, iGroundCfg.x, l3 * 0.35),
                      mix(0.0, 1.3, backMulti), iSunCfg.z);
  vec3 backColor = readColorConfig(backCfg);
  float backI = mix(1.5, 1.0, iSunIntensity) * backCfg.z;

  // The reference's authored noon tint — at high sun the sky probes go too blue, so it
  // pulls the lights toward warm white.
  sunColor = mix(sunColor, vec3(1.0, 0.74, 0.53), iWhitePer);
  groundColor = mix(groundColor, vec3(0.85, 0.54, 0.37), iWhitePer);
  ambientColor = mix(ambientColor, vec3(0.96, 0.63, 0.42), iWhitePer);
  backColor = mix(backColor, vec3(1.0, 0.74, 0.53), iWhitePer);

  // --- composite ----------------------------------------------------------
  vec3 diffuse = mix(vec3(texDepth), vec3(1.0), 0.8);
  diffuse = mix(diffuse, vec3(0.8), iFogDensity);

  float fogMulti = 1.0 - pow(max(0.0, iFogDensity), 2.0);

  vec3 color = baseColor;
  color += l0 * sunColor * sunI * fogMulti;
  color += l1 * groundColor * groundI * fogMulti;
  color += l2 * ambientColor * ambientI * fogMulti;
  color += l3 * backColor * backI * fogMulti;

  // Lightning inside the cloud, masked by the sprite's inner-glow channel.
  vec3 innerColor = mix(baseColor, vec3(1.0), 0.1);
  color += innerColor * (0.1 + smoothstep(0.05, 1.0, texInner)) * iInner * 0.4;
  color *= mix(1.0, 1.5, iInner);

  color *= diffuse;
  // Haze dissolves the sprite into the sky behind it.
  color = mix(color, skyAt(0.95), iFogDensity);

  float a = clamp(alpha * depthAlpha, 0.0, 1.0);
  fragColor = vec4(clamp(color, 0.0, 1.0) * a, a); // premultiplied
}
