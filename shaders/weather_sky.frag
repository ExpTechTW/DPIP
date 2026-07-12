// Procedural weather sky for the home backdrop.
//
// Single pass, texture-free. Four moods (clear / rain / fog / thunderstorm) are
// the algebraic result of the weight uniforms — one branchless code path for all
// GPU lanes. Cheap Hoskins hashes (no sin-hash), 4-octave fBM, no derivatives.
// See the shader-research spec for the derivation of each layer.
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

// One sheared column of rain streaks (no drop loops, no textures).
float rainLayer(vec2 uv, float t, float cols, float spd, float slant, float aa) {
  uv.x += uv.y * slant;
  uv.x *= cols;
  float c = floor(uv.x);
  float fx = fract(uv.x) - 0.5;
  float s = hash12(vec2(c, 1.0));
  float y = uv.y * (1.0 + s * 0.5) - t * spd * (0.6 + s) + s * 10.0;
  float fy = fract(y);
  float row = floor(y);
  float streak = smoothstep(0.0, 0.15, fy) * smoothstep(1.0, 0.45, fy);
  float w = 0.08 + s * 0.05;
  float line = smoothstep(w + aa * cols, w - aa * cols, abs(fx));
  float on = step(0.55, hash12(vec2(c * 7.1, row * 3.3)));
  return line * streak * on;
}

void main() {
  vec2 fc = FlutterFragCoord();
  vec2 uv = fc.xy / iResolution.xy;  // uv.y: 0 zenith (top) -> 1 horizon (bottom)
  float aspect = iResolution.x / iResolution.y;
  float t = mod(iTime, 600.0);
  float scrollN = iScroll / iResolution.y;

  // --- sky gradient (branchless scene palette) ---
  float wDay = 1.0 - min(abs(iScene - 0.0), 1.0);
  float wNight = 1.0 - min(abs(iScene - 1.0), 1.0);
  float wDawn = 1.0 - min(abs(iScene - 2.0), 1.0);
  float wSun = 1.0 - min(abs(iScene - 3.0), 1.0);
  vec3 zDay = mix(vec3(0.06, 0.20, 0.42), vec3(0.28, 0.55, 0.86), iLight);
  vec3 hDay = mix(vec3(0.34, 0.62, 0.84), vec3(0.72, 0.87, 0.97), iLight);
  vec3 zenith = wDay * zDay + wNight * vec3(0.015, 0.03, 0.07) +
                wDawn * vec3(0.10, 0.06, 0.20) + wSun * vec3(0.09, 0.05, 0.10);
  vec3 horizon = wDay * hDay + wNight * vec3(0.05, 0.09, 0.16) +
                 wDawn * vec3(0.86, 0.42, 0.28) + wSun * vec3(0.98, 0.46, 0.20);
  vec3 col = mix(zenith, horizon, pow(uv.y, 0.8));

  // --- sun / celestial ---
  float phase = clamp(iSunPhase, 0.0, 1.0);
  float sunH = sin(phase * PI);
  vec2 sunUV = vec2(mix(0.12, 0.88, phase), mix(0.94, 0.24, sunH));
  sunUV.y += scrollN * 0.40;
  vec2 sd = uv - sunUV;
  sd.x *= aspect;
  float ang = length(sd);
  vec3 sunCol = wDay * vec3(1.0, 0.95, 0.72) + wDawn * vec3(1.0, 0.62, 0.34) +
                wSun * vec3(1.0, 0.55, 0.26);
  float overcast = clamp(iCloud, 0.0, 1.0);
  float sunVis = (1.0 - wNight) * (1.0 - 0.75 * overcast);
  float disc = smoothstep(0.045, 0.038, ang);
  float glow = exp(-ang * 7.0) * 0.35 + exp(-ang * 16.0) * 0.55;
  float sunAmt = max(1.0 - ang * 1.4, 0.0);
  col = mix(col, mix(col, sunCol, 0.30), pow(sunAmt, 4.0) * sunVis);
  col += sunCol * (disc + glow) * sunVis;

  // moon + one twinkling star layer (night)
  vec2 md = uv - vec2(0.80, 0.18 + scrollN * 0.40);
  md.x *= aspect;
  float mdl = length(md);
  float moon = smoothstep(0.060, 0.052, mdl);
  float moonSh = smoothstep(0.052, 0.045, length(vec2(md.x - 0.020, md.y + 0.004)));
  col += vec3(0.85, 0.88, 0.97) * exp(-mdl * 9.0) * 0.18 * wNight;
  col = mix(col, vec3(0.90, 0.92, 0.99), clamp(moon - moonSh, 0.0, 1.0) * wNight);
  vec2 sg = vec2(uv.x * aspect, uv.y + scrollN * 0.10) * 80.0;
  vec2 rnd = hash22(floor(sg));
  vec2 scv = (fract(sg) - 0.5) - (rnd - 0.5) * 0.6;
  float star = step(0.86, rnd.x) * (1.0 / (1.0 + dot(scv, scv) * 550.0));
  star *= 0.55 + 0.45 * sin(t * 2.2 + rnd.y * 6.28);
  col += vec3(star) * wNight * (1.0 - overcast) * smoothstep(0.75, 0.0, uv.y);

  // --- clouds (domain-warped fBM sheet; `field` reused by fog) ---
  float hor = max(1.02 - uv.y, 0.06);
  vec2 sky = vec2((uv.x - 0.5) * aspect, 1.0) / hor;
  sky += vec2(0.06 + 0.22 * iWind, 0.015) * t + vec2(0.0, scrollN * 0.6);
  vec2 q = vec2(fbm(sky * 0.9), fbm(sky * 0.9 + vec2(5.2, 1.3)));
  float field = fbm(sky * 0.9 + 2.4 * q);
  float lo = mix(0.72, 0.05, overcast);
  float hi = lo + mix(0.10, 0.42, clamp(iFog, 0.0, 1.0));
  float cover = smoothstep(lo, hi, field) * smoothstep(0.0, 0.15, uv.y);
  vec2 ld = normalize(sunUV - uv + 0.001);
  float lit = fbm(sky * 0.9 + 2.4 * q + ld * 0.20);
  float shade = clamp((field - lit) * 2.5 + 0.5, 0.0, 1.0);
  float beer = exp(-cover * 2.5);
  vec3 cHi = wDay * vec3(1.0, 0.99, 0.96) + wNight * vec3(0.20, 0.23, 0.30) +
             wDawn * vec3(1.0, 0.72, 0.55) + wSun * vec3(1.0, 0.66, 0.42);
  vec3 cLo = wDay * vec3(0.55, 0.62, 0.72) + wNight * vec3(0.06, 0.08, 0.12) +
             wDawn * vec3(0.40, 0.22, 0.32) + wSun * vec3(0.45, 0.22, 0.20);
  vec3 cloudCol = mix(cLo, cHi, shade) * (0.55 + 0.45 * beer);
  col = mix(col, cloudCol, cover);

  // --- rain (3 parallax streak layers + wet grade) ---
  float rainAmt = clamp(iRain, 0.0, 1.0);
  float aa = 1.5 / iResolution.y;
  vec2 ruv = vec2(uv.x * aspect, uv.y + scrollN * 0.4);
  float rain = rainLayer(ruv, t, 42.0, 1.2, 0.04 + 0.10 * iWind, aa) * 0.55 +
               rainLayer(ruv, t, 27.0, 1.9, 0.06 + 0.14 * iWind, aa) * 0.80 +
               rainLayer(ruv, t, 17.0, 2.7, 0.08 + 0.18 * iWind, aa) * 1.00;
  rain *= rainAmt * smoothstep(0.02, 0.25, uv.y);
  col += mix(vec3(0.55, 0.65, 0.78), vec3(0.40, 0.50, 0.65), wNight) * rain * 0.5;
  float luma = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(col, vec3(luma) * vec3(0.85, 0.90, 1.0), 0.30 * rainAmt);
  col *= 1.0 - 0.22 * rainAmt;

  // --- fog (reuses cloud `field`; aerial-perspective grade) ---
  float fogAmt = clamp(iFog, 0.0, 1.0);
  float fog = clamp(field * 0.8 + 0.30, 0.0, 1.0) * smoothstep(0.15, 1.0, uv.y) * fogAmt;
  float sa = max(1.0 - ang * 1.2, 0.0);
  vec3 fogCol = mix(vec3(0.62, 0.66, 0.72), sunCol, pow(sa, 4.0) * sunVis * 0.6);
  fogCol = mix(fogCol, vec3(0.10, 0.12, 0.16), wNight);
  col = mix(col, vec3(dot(col, vec3(0.2126, 0.7152, 0.0722))), 0.55 * fog);
  col = mix(col, fogCol, 0.65 * fog);

  // --- lightning (uniform flash + branchless bolt) ---
  float flash = clamp(iLightning, 0.0, 1.0);
  col += vec3(0.85, 0.90, 1.0) * flash * (0.35 + 0.45 * cover);
  col = mix(col, vec3(0.92, 0.95, 1.0), flash * 0.35);
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
