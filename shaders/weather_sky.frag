// Procedural weather sky for the home backdrop.
//
// Single pass, texture-free. Four moods (clear / rain / fog / thunderstorm) are
// the algebraic result of the weight uniforms — one branchless code path for all
// GPU lanes. Cheap Hoskins hashes (no sin-hash), 4-octave fBM, no derivatives.
//
// WHERE THIS IS SEEN. It sits behind the home sheet, which covers the bottom
// third and rises to cover everything. So the sky is composed for its TOP: the
// horizon sits low and the interesting band — sun, cloud deck, colour gradient —
// lives in the upper two thirds. An earlier version put the vanishing point at
// the very bottom edge, which crushed every cloud into the strip the sheet hides
// and drove the perspective divide to ~16x, where the hash aliases into vertical
// streaks. Both the composition and that artefact came from the same choice.
#include <flutter/runtime_effect.glsl>
#define PI 3.14159265

uniform float iTime;       // seconds (wrapped to 600 for mediump-safe coords)
uniform vec2 iResolution;  // px
uniform float iScene;      // 0 day / 1 night / 2 dawn / 3 sunset
uniform float iScroll;     // px parallax offset (0 disables)
uniform float iCloud;      // 0..1 coverage
uniform float iRain;       // 0..1 rain intensity
uniform float iWind;       // 0..1 drift speed / shear
uniform float iSunPhase;   // 0..1 sun arc position
uniform float iLight;      // 1 light theme / 0 dark
uniform float iFog;        // 0..1 fog density
uniform float iLightning;  // 0..1 per-frame flash scalar (CPU envelope)

out vec4 fragColor;

float hash12(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * 0.1031);
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
  vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
  p3 += dot(p3, p3.yzx + 33.33);
  return fract((p3.xx + p3.yz) * p3.zy);
}

float vnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
             mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

const mat2 M2 = mat2(0.80, 0.60, -0.60, 0.80);

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * vnoise(p);
    p = M2 * p * 2.0 + 11.3;
    a *= 0.5;
  }
  return v;
}

// Interleaved-gradient noise for the final dither.
float ign(vec2 p) {
  return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

// One depth layer of falling drops.
//
// Drops live on a JITTERED CELL LATTICE, not in `fract` stripes. Stripes give
// every drop in a column the same x, so the eye reads the columns rather than
// the rain — which is what made the old curtain look like tick marks. Each cell
// hashes its own x offset, fall phase, speed, length and brightness, and the
// lattice is pre-warped by noise so the grid itself never becomes visible.
// (Technique: monster555/flutter_shady_weather_demo `drops.frag` — cell lattice,
// per-cell continuous radius, pre-warp.)
//
// `soft` is the layer's edge width: far layers are blurrier, which is the
// cheapest depth cue available without a second pass.
float rainLayer(vec2 uv, float t, float density, float spd, float shear,
                float soft, float seed) {
  // Pre-warp: bends the lattice so its rows/columns stop lining up.
  vec2 warp = vec2(vnoise(uv * 2.7 + seed), vnoise(uv * 2.7 + seed + 19.3));
  uv += (warp - 0.5) * 0.10;
  uv.x += uv.y * shear;

  // Anisotropic cells: drops are spaced widely across and tightly down, so the
  // streak has room to fall without the cell clipping it.
  vec2 p = vec2(uv.x * density, uv.y * density * 0.5);
  vec2 cell = floor(p);
  vec2 f = fract(p);

  // Fold the seed into the hash so layers never correlate.
  float h = hash12(cell + seed);
  float g = hash12(cell + seed + 47.11);
  // Roughly a third of cells carry a drop — a continuous weight, not a step, so
  // drops fade in and out instead of popping.
  float alive = smoothstep(0.55, 0.95, g);

  float cx = 0.18 + 0.64 * h;                        // jitter across
  float fall = fract(h * 6.37 + t * spd * (0.75 + 0.5 * g));  // and along
  float len = 0.22 + 0.42 * g;                       // per-drop streak length

  float dx = f.x - cx;
  float dy = f.y - fall;
  // Wrap so a streak crossing the cell edge stays continuous.
  dy -= floor(dy + 0.5);

  float w = 0.030 + 0.022 * h;
  float lateral = smoothstep(w + soft, w * 0.15, abs(dx));
  // The tail trails BEHIND the head (upward), fading along its length.
  float along = smoothstep(-len, -len * 0.12, dy) * smoothstep(0.045, -0.010, dy);
  return lateral * along * alive * (0.45 + 0.55 * h);
}

void main() {
  vec2 fc = FlutterFragCoord();
  vec2 uv = fc.xy / iResolution.xy;  // uv.y: 0 top -> 1 bottom
  float aspect = iResolution.x / iResolution.y;
  float t = mod(iTime, 600.0);
  float scrollN = iScroll / iResolution.y;

  // --- sky gradient (branchless scene palette) ---
  float wDay = 1.0 - min(abs(iScene - 0.0), 1.0);
  float wNight = 1.0 - min(abs(iScene - 1.0), 1.0);
  float wDawn = 1.0 - min(abs(iScene - 2.0), 1.0);
  float wSun = 1.0 - min(abs(iScene - 3.0), 1.0);
  vec3 zDay = mix(vec3(0.06, 0.20, 0.42), vec3(0.19, 0.45, 0.80), iLight);
  vec3 hDay = mix(vec3(0.34, 0.62, 0.84), vec3(0.78, 0.89, 0.98), iLight);
  vec3 zenith = wDay * zDay + wNight * vec3(0.015, 0.03, 0.07) +
                wDawn * vec3(0.10, 0.06, 0.20) + wSun * vec3(0.09, 0.05, 0.10);
  vec3 horizon = wDay * hDay + wNight * vec3(0.05, 0.09, 0.16) +
                 wDawn * vec3(0.86, 0.42, 0.28) + wSun * vec3(0.98, 0.46, 0.20);
  // Rayleigh-ish falloff: most of the frame holds the deep zenith and the warm
  // band stays tight to the horizon, which is what makes a sky read as depth
  // rather than as a two-stop linear ramp.
  float sky01 = clamp(uv.y, 0.0, 1.0);
  vec3 col = mix(zenith, horizon, pow(sky01, 2.2));

  // --- sun / celestial ---
  float phase = clamp(iSunPhase, 0.0, 1.0);
  float sunH = sin(phase * PI);
  vec2 sunUV = vec2(mix(0.16, 0.84, phase), mix(0.86, 0.20, sunH));
  sunUV.y += scrollN * 0.40;
  vec2 sd = uv - sunUV;
  sd.x *= aspect;
  float ang = length(sd);
  vec3 sunCol = wDay * vec3(1.0, 0.96, 0.86) + wDawn * vec3(1.0, 0.62, 0.34) +
                wSun * vec3(1.0, 0.55, 0.26);
  float overcast = clamp(iCloud, 0.0, 1.0);
  float sunVis = (1.0 - wNight) * (1.0 - 0.75 * overcast);
  float disc = smoothstep(0.032, 0.026, ang);
  // Tight glow only. The previous falloff washed warm light across most of the
  // frame, and every semi-transparent cloud blended against it — which is why
  // white cloud read as brown.
  float glow = exp(-ang * 14.0) * 0.30 + exp(-ang * 34.0) * 0.55;
  col += sunCol * (disc + glow) * sunVis;

  // moon + one twinkling star layer (night)
  vec2 md = uv - vec2(0.80, 0.16 + scrollN * 0.40);
  md.x *= aspect;
  float mdl = length(md);
  float moon = smoothstep(0.048, 0.041, mdl);
  float moonSh = smoothstep(0.042, 0.036, length(vec2(md.x - 0.017, md.y + 0.003)));
  col += vec3(0.85, 0.88, 0.97) * exp(-mdl * 11.0) * 0.16 * wNight;
  col = mix(col, vec3(0.90, 0.92, 0.99), clamp(moon - moonSh, 0.0, 1.0) * wNight);
  vec2 sg = vec2(uv.x * aspect, uv.y + scrollN * 0.10) * 80.0;
  vec2 rnd = hash22(floor(sg));
  vec2 scv = (fract(sg) - 0.5) - (rnd - 0.5) * 0.6;
  float star = step(0.86, rnd.x) * (1.0 / (1.0 + dot(scv, scv) * 550.0));
  star *= 0.55 + 0.45 * sin(t * 2.2 + rnd.y * 6.28);
  col += vec3(star) * wNight * (1.0 - overcast) * smoothstep(0.62, 0.0, uv.y);

  // --- cloud deck ---
  //
  // The horizon sits below the frame (`HZ`), so the perspective divide stays
  // bounded across the whole canvas instead of diverging at the bottom edge.
  // That divergence was the vertical-streak artefact: past ~8x the fBM is
  // sampled far outside the range the hash stays smooth over.
  const float HZ = 1.34;
  float depth = clamp(HZ - uv.y, 0.30, HZ);
  vec2 sky = vec2((uv.x - 0.5) * aspect, 0.85) / depth;
  sky += vec2(0.05 + 0.20 * iWind, 0.012) * t + vec2(0.0, scrollN * 0.6);

  vec2 q = vec2(fbm(sky * 1.15), fbm(sky * 1.15 + vec2(5.2, 1.3)));
  float field = fbm(sky * 1.15 + 2.1 * q);
  float lo = mix(0.70, 0.22, overcast);
  float cover = smoothstep(lo, lo + 0.30, field);
  // Fade the deck in from the top edge only when the sky is not overcast: a
  // broken deck should thin out overhead, but an overcast one covers the zenith,
  // and a fixed fade left a clear blue strip pinned above the cloud.
  float topFade = mix(smoothstep(0.0, 0.16, uv.y), 1.0, overcast);
  cover *= topFade * smoothstep(1.06, 0.86, uv.y);

  // Self-shadowing: sample the field again toward the sun and compare.
  vec2 ld = normalize(sunUV - uv + 0.0001);
  float lit = fbm(sky * 1.15 + 2.1 * q + ld * 0.30);
  float shade = clamp((lit - field) * 2.2 + 0.55, 0.0, 1.0);
  // Thicker cloud transmits less, so its base darkens — the cue that reads as
  // volume rather than as a flat stencil.
  float thick = smoothstep(0.0, 0.9, cover);
  vec3 cTop = wDay * vec3(1.00, 1.00, 0.99) + wNight * vec3(0.22, 0.25, 0.33) +
              wDawn * vec3(1.00, 0.80, 0.66) + wSun * vec3(1.00, 0.76, 0.56);
  vec3 cBase = wDay * vec3(0.62, 0.67, 0.76) + wNight * vec3(0.05, 0.07, 0.11) +
               wDawn * vec3(0.44, 0.30, 0.40) + wSun * vec3(0.46, 0.28, 0.28);
  vec3 cloudCol = mix(cBase, cTop, shade);
  cloudCol *= 1.0 - 0.28 * thick;
  // A rim only on cloud actually near the sun — applied deck-wide it tinted
  // every distant cloud warm, which is the muddy look this replaced.
  cloudCol += sunCol * pow(shade, 3.0) * 0.30 * sunVis * exp(-ang * 3.0);
  col = mix(col, cloudCol, cover);

  // --- rain (3 parallax drop layers + wet grade) ---
  float rainAmt = clamp(iRain, 0.0, 1.0);
  vec2 ruv = vec2(uv.x * aspect, uv.y + scrollN * 0.4);
  // Near layers: sparser, faster, sharper. Far layers: denser, slower, blurrier
  // — per-layer edge width is the depth cue (snow.frag, same repo).
  float rain =
      rainLayer(ruv, t, 26.0, 0.85, 0.05 + 0.10 * iWind, 0.055, 3.0) * 0.40 +
      rainLayer(ruv, t, 17.0, 1.25, 0.07 + 0.14 * iWind, 0.028, 61.0) * 0.70 +
      rainLayer(ruv, t, 11.0, 1.75, 0.09 + 0.18 * iWind, 0.012, 131.0) * 1.00;
  rain *= rainAmt * smoothstep(0.0, 0.22, uv.y);
  // Rain is lit by whatever light there is, so a lightning flash lights it too.
  vec3 rainCol = mix(vec3(0.72, 0.79, 0.90), vec3(0.46, 0.56, 0.72), wNight);
  col += rainCol * rain * (0.30 + 0.9 * clamp(iLightning, 0.0, 1.0));
  float luma = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(col, vec3(luma) * vec3(0.86, 0.90, 0.98), 0.30 * rainAmt);
  col *= 1.0 - 0.18 * rainAmt;

  // --- fog: extinction toward airlight, not a tint ---------------------
  //
  // The previous version lerped the sky toward grey, which is what "washed out"
  // looks like — never fog. Fog OCCLUDES: light from the scene is extinguished
  // over distance and REPLACED by airlight, so at high density nothing of the
  // scene survives. That is the Beer-Lambert / airlight model
  // (https://iquilezles.org/articles/fog/), and it is why this now reads as fog
  // at the top of frame too, where a height-only band left clear blue.
  float fogAmt = clamp(iFog, 0.0, 1.0);
  // No depth buffer here, so screen height stands in for distance: the sky meets
  // the ground far away at the bottom of the frame.
  float dist = mix(0.45, 1.0, smoothstep(0.0, 0.95, uv.y));
  // Drifting banks: two domain-warped sheets counter-scrolling at ~5x speed, so
  // the fog churns rather than sliding as one texture
  // (https://iquilezles.org/articles/warp/, /articles/dynclouds/).
  vec2 g1 = vec2(uv.x * aspect * 1.25 + t * 0.010, uv.y * 1.9 - t * 0.005);
  vec2 g2 = vec2(uv.x * aspect * 2.60 - t * 0.048, uv.y * 3.3 + t * 0.022);
  vec2 gw = vec2(fbm(g1), fbm(g1 + vec2(3.1, 7.7)));
  float bank = fbm(g1 + 1.7 * gw) * 0.65 + fbm(g2) * 0.35;
  float density = fogAmt * (2.0 + 4.4 * fogAmt) * dist * (0.30 + 1.6 * bank);
  float trans = exp(-density);
  // Airlight: what the fog replaces the scene with. It must match the light in
  // the scene, so it carries the sun's colour near the sun
  // (in-scattering, iq) and goes near-black at night.
  vec3 air = mix(vec3(0.82, 0.85, 0.88), vec3(0.09, 0.11, 0.15), wNight);
  air = mix(air, sunCol, 0.35 * sunVis * pow(max(1.0 - ang, 0.0), 3.0));
  col = mix(air, col, trans);

  // --- lightning (uniform flash + branchless bolt) ---
  float flash = clamp(iLightning, 0.0, 1.0);
  // A flash lights the cloud base and lifts the shadows; it does not wash the
  // frame to white. At full strength the previous gain blew every channel past
  // 1.0 across the whole sky, so the storm briefly had no cloud, no rain and no
  // depth — the one moment it should look most dramatic.
  col += vec3(0.72, 0.80, 0.98) * flash * (0.10 + 0.30 * cover);
  col = mix(col, vec3(0.82, 0.87, 0.98), flash * 0.14);
  vec2 buv = uv - vec2(0.5, 0.0);
  buv.x *= aspect;
  float seed = floor(t * 3.0);
  float jig = (hash12(vec2(seed, 3.0)) - 0.5) * 0.6;
  float disp = 0.0;
  float amp = 0.14;
  float fr = 3.0;
  for (int i = 0; i < 4; i++) {
    disp += amp * sin(buv.y * fr + t * 2.0 + float(i) * 11.0 + seed);
    amp *= 0.5;
    fr *= 2.1;
  }
  float boltGlow = (0.010 / (abs(buv.x - jig - disp) + 0.001)) * smoothstep(1.0, 0.15, uv.y);
  col += vec3(0.80, 0.90, 1.0) * boltGlow * flash;

  // --- composite: highlight rolloff + dither + opaque output ---
  col = col / (1.0 + max(col - 1.0, 0.0));
  col = max(col, vec3(0.0));
  col += (ign(fc.xy) - 0.5) / 255.0;
  fragColor = vec4(col, 1.0);
}
