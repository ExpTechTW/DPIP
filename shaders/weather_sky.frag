// Physically-motivated weather backdrop for the home sheet.
//
// Clear skies use a proper blue gradient + localized sun. Clouds, rain, fog
// and lightning layer on top and scale with their uniforms so clear (low
// iCloud) does NOT pick up overcast wash or a full cloud deck.
// Uniform layout unchanged — Dart sets floats by index.
#include <flutter/runtime_effect.glsl>
#define PI 3.14159265

uniform float iTime;
uniform vec2 iResolution;
uniform float iScene;      // 0 day / 1 night / 2 dawn / 3 sunset
uniform float iScroll;
uniform float iCloud;      // 0..1 coverage control
uniform float iRain;
uniform float iWind;
uniform float iSunPhase;
uniform float iLight;
uniform float iFog;
uniform float iLightning;

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
             mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x),
             u.y);
}

const mat2 M2 = mat2(0.80, 0.60, -0.60, 0.80);

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 5; i++) {
    v += a * vnoise(p);
    p = M2 * p * 2.02 + 13.7;
    a *= 0.5;
  }
  return v;
}

float rfbm(vec2 p) {
  float v = 0.0;
  float a = 0.55;
  for (int i = 0; i < 4; i++) {
    float n = 1.0 - abs(vnoise(p) * 2.0 - 1.0);
    v += a * n * n;
    p = M2 * p * 2.03 + 7.9;
    a *= 0.5;
  }
  return v;
}

float ign(vec2 p) {
  return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

float hg(float mu, float g) {
  float g2 = g * g;
  return (1.0 - g2) / (4.0 * PI * pow(max(1.0 + g2 - 2.0 * g * mu, 1e-4), 1.5));
}

float rainLayer(vec2 uv, float t, float density, float spd, float shear,
                float soft, float seed) {
  vec2 warp = vec2(vnoise(uv * 3.0 + seed), vnoise(uv * 3.0 + seed + 17.0));
  uv += (warp - 0.5) * 0.06;
  uv.x += uv.y * shear;

  vec2 p = vec2(uv.x * density, uv.y * density * 0.42);
  vec2 cell = floor(p);
  vec2 f = fract(p);

  float h = hash12(cell + seed);
  float g = hash12(cell + seed + 41.7);
  float alive = smoothstep(0.45, 0.92, g);

  float cx = 0.20 + 0.60 * h;
  float fall = fract(h * 5.91 + t * spd * (0.85 + 0.50 * g));
  float len = 0.30 + 0.45 * g;

  float dx = f.x - cx;
  float dy = f.y - fall;
  dy -= floor(dy + 0.5);

  float w = 0.016 + 0.014 * h;
  float lateral = smoothstep(w + soft, w * 0.10, abs(dx));
  float along = smoothstep(-len, -len * 0.18, dy) * smoothstep(0.035, -0.006, dy);
  float tip = smoothstep(-0.02, -len * 0.55, dy) * (0.35 + 0.65 * g);
  return lateral * along * alive * (0.35 + 0.45 * h + tip);
}

// Clear-day sky: zenith→horizon blue with Rayleigh-ish falloff + Mie sun bloom.
// `sunDir2` is screen-space direction from pixel toward the sun (aspect-corrected).
vec3 clearSky(vec2 uv, float sy, vec2 sunOff, float sunVis, float wDay,
              float wDawn, float wSun, float wNight, float iLight) {
  // Base gradients per scene.
  vec3 zen = wDay * mix(vec3(0.10, 0.28, 0.62), vec3(0.30, 0.56, 0.90), iLight)
           + wNight * vec3(0.015, 0.022, 0.060)
           + wDawn * vec3(0.14, 0.16, 0.38)
           + wSun * vec3(0.12, 0.14, 0.36);
  vec3 mid = wDay * mix(vec3(0.22, 0.48, 0.78), vec3(0.48, 0.72, 0.94), iLight)
           + wNight * vec3(0.040, 0.055, 0.120)
           + wDawn * vec3(0.45, 0.32, 0.52)
           + wSun * vec3(0.55, 0.30, 0.40);
  vec3 hor = wDay * mix(vec3(0.55, 0.72, 0.88), vec3(0.82, 0.90, 0.97), iLight)
           + wNight * vec3(0.10, 0.13, 0.22)
           + wDawn * vec3(0.98, 0.70, 0.45)
           + wSun * vec3(1.00, 0.58, 0.30);

  vec3 col = mix(zen, mid, smoothstep(0.00, 0.55, sy));
  col = mix(col, hor, smoothstep(0.45, 1.05, sy));

  // Atmospheric perspective brightening near horizon (day only).
  float haze = pow(smoothstep(0.35, 1.05, sy), 2.0);
  col = mix(col, mix(hor, vec3(1.0), 0.15), haze * 0.35 * (1.0 - wNight));

  // Sun: localized disc + Mie corona (NOT whole-sky wash).
  float ang = length(sunOff);
  vec3 sunCol = wDay * vec3(1.00, 0.97, 0.88)
              + wDawn * vec3(1.00, 0.72, 0.40)
              + wSun * vec3(1.00, 0.55, 0.28);
  float bloom = exp(-ang * ang * 8.0);
  float glow = exp(-ang * ang * 28.0);
  float core = exp(-ang * ang * 90.0);
  float disc = smoothstep(0.034, 0.022, ang);
  col += sunCol * (0.45 * bloom + 0.55 * glow + 0.85 * core + 1.1 * disc) *
         sunVis;

  // Soft sun-side warm fill (narrow, not global).
  col += sunCol * exp(-ang * 3.5) * 0.12 * sunVis * (wDawn + wSun + 0.35 * wDay);

  return col;
}

void main() {
  vec2 fc = FlutterFragCoord();
  vec2 uv = fc.xy / iResolution.xy;  // y: 0 top → 1 bottom
  float aspect = iResolution.x / max(iResolution.y, 1.0);
  float t = mod(iTime, 600.0);
  float scrollN = iScroll / max(iResolution.y, 1.0);

  float wDay = 1.0 - min(abs(iScene - 0.0), 1.0);
  float wNight = 1.0 - min(abs(iScene - 1.0), 1.0);
  float wDawn = 1.0 - min(abs(iScene - 2.0), 1.0);
  float wSun = 1.0 - min(abs(iScene - 3.0), 1.0);

  // Remap iCloud: clear(0.10) → ~0 coverage; rain(0.85) → full.
  // Do NOT treat raw iCloud as overcast wash (that greys clear skies).
  float cloudCtrl = clamp(iCloud, 0.0, 1.0);
  float coverageAmt = smoothstep(0.12, 0.78, cloudCtrl);   // deck amount
  float overcastWash = smoothstep(0.40, 0.92, cloudCtrl);  // grey wash
  float rainAmt = clamp(iRain, 0.0, 1.0);
  float fogAmt = clamp(iFog, 0.0, 1.0);

  float breathe = 0.012 * sin(t * 0.05 + uv.x * 1.5);
  float sy = clamp(uv.y + scrollN * 0.22 + breathe, 0.0, 1.0);

  // Screen-space sun on a day arc (matches iSunPhase from Dart).
  float phase = clamp(iSunPhase, 0.0, 1.0);
  float sunH = sin(phase * PI);
  // Dawn/sunset: keep sun low even if phase is mid-ramp.
  sunH = mix(sunH, sunH * 0.45, wDawn * 0.8 + wSun * 0.8);
  vec2 sunUV = vec2(mix(0.14, 0.86, phase), mix(0.92, 0.18, sunH));
  sunUV.y += scrollN * 0.35;
  vec2 sunOff = (uv - sunUV) * vec2(aspect, 1.0);
  float sunVis = (1.0 - wNight) * (1.0 - 0.75 * overcastWash);

  vec3 col = clearSky(uv, sy, sunOff, sunVis, wDay, wDawn, wSun, wNight, iLight);

  // --- night layer ---
  if (wNight > 0.0) {
    vec3 nightSky = mix(vec3(0.012, 0.018, 0.055), vec3(0.06, 0.08, 0.14),
                        pow(sy, 2.5));
    nightSky += vec3(0.02, 0.05, 0.08) * exp(-abs(sy - 0.82) * 14.0) * 0.3;
    col = mix(col, nightSky, wNight);

    vec2 md = uv - vec2(0.74, 0.17 + scrollN * 0.32);
    md.x *= aspect;
    float mdl = length(md);
    float moon = smoothstep(0.050, 0.036, mdl);
    float bite = smoothstep(0.044, 0.028, length(md - vec2(0.018, -0.007)));
    col += vec3(0.80, 0.86, 0.98) * exp(-mdl * 8.0) * 0.20 * wNight;
    col = mix(col, vec3(0.93, 0.95, 0.99),
              clamp(moon - bite, 0.0, 1.0) * wNight);

    vec2 sg = vec2(uv.x * aspect, uv.y + scrollN * 0.06) * 100.0;
    vec2 id = floor(sg);
    vec2 f = fract(sg) - 0.5;
    vec2 rnd = hash22(id);
    float d = length(f - (rnd - 0.5) * 0.65);
    float star = step(0.915, rnd.x) * exp(-d * d * 850.0);
    star *= 0.45 + 0.55 * sin(t * 2.0 + rnd.y * 6.28);
    col += vec3(star) * wNight * (1.0 - coverageAmt) *
           smoothstep(0.60, 0.08, uv.y);
  }

  // Overcast wash — only when actually cloudy.
  if (overcastWash > 0.0) {
    vec3 slate = mix(vec3(0.30, 0.34, 0.40), vec3(0.60, 0.65, 0.72), iLight);
    slate = mix(slate, vec3(0.08, 0.10, 0.14), wNight);
    col = mix(col, slate, overcastWash * (0.50 + 0.25 * rainAmt));
  }

  // --- cloud deck (gated hard when clear) ---
  float cover = 0.0;
  if (coverageAmt > 0.001) {
    const float HZ = 2.15;
    float depth = clamp(HZ - uv.y, 0.85, HZ);
    vec2 sky = vec2((uv.x - 0.5) * aspect, 0.78) / depth;
    sky += vec2(0.025 + 0.12 * iWind, 0.006) * t + vec2(0.0, scrollN * 0.5);

    vec2 q = vec2(fbm(sky * 0.85), fbm(sky * 0.85 + vec2(5.2, 1.3)));
    vec2 r = vec2(fbm(sky * 1.7 + 1.6 * q + vec2(1.7, 9.2)),
                  fbm(sky * 1.7 + 1.6 * q + vec2(8.3, 2.8)));
    float dens = rfbm(sky * 1.05 + 1.35 * q + 0.65 * r);
    dens = mix(dens, fbm(sky * 1.55 + q), 0.40);
    dens -= (1.0 - coverageAmt) * 0.18 * fbm(sky * 3.0 + r);

    // Clear → high threshold (almost no lobes); storm → low threshold.
    float thresh = mix(0.78, 0.28, coverageAmt);
    cover = smoothstep(thresh, thresh + 0.30, dens);
    cover *= smoothstep(1.05, 0.72, uv.y);
    cover *= mix(smoothstep(0.0, 0.14, uv.y), 1.0, coverageAmt);
    cover *= coverageAmt;  // hard gate for clear
    cover = min(cover, 0.94);

    float tau = clamp((dens - thresh) * 2.8, 0.0, 2.5);
    float transmit = exp(-tau * 0.85);
    float ang = length(sunOff);
    float scatter = exp(-max(dens - thresh, 0.0) * 1.4);
    scatter *= exp(-ang * 1.2) * 0.5 + 0.5;  // brighter toward sun

    vec3 sunLight = mix(vec3(0.55, 0.65, 0.85), vec3(1.0, 0.96, 0.88),
                        (1.0 - wNight) * sunVis);
    sunLight = mix(sunLight, vec3(1.0, 0.65, 0.40), (wDawn + wSun) * 0.55);
    sunLight *= (1.0 - wNight * 0.85);

    vec3 ambient = mix(vec3(0.28, 0.34, 0.48), vec3(0.72, 0.80, 0.90), iLight);
    ambient = mix(ambient, vec3(0.08, 0.10, 0.16), wNight);
    ambient = mix(ambient, vec3(0.55, 0.40, 0.42), (wDawn + wSun) * 0.35);

    float powder = 1.0 - exp(-tau * 2.0);
    float phaseCloud = mix(0.4, 1.0, hg(clamp(1.0 - ang * 0.8, -1.0, 1.0), 0.4));
    vec3 cloudLit = ambient * (0.35 + 0.45 * transmit)
                  + sunLight * scatter * phaseCloud * (0.55 + 0.45 * powder);
    cloudLit *= 1.0 - 0.35 * overcastWash;
    cloudLit *= mix(0.55, 1.0, smoothstep(thresh, thresh + 0.55, dens));
    // Silver lining.
    cloudLit += sunLight * exp(-ang * 4.0) * 0.35 * sunVis * cover;

    col = mix(col, cloudLit, cover);
  }

  // Thin cirrus — only on mostly clear / partly cloudy days.
  float cirAllow = (1.0 - overcastWash) * (1.0 - wNight * 0.7);
  if (cirAllow > 0.01) {
    vec2 cirP = vec2(uv.x * aspect * 1.2 - t * (0.01 + 0.018 * iWind),
                     uv.y * 6.5);
    float cir = fbm(cirP + vec2(fbm(cirP * 0.5) * 1.5, 0.0));
    float cirBand = smoothstep(0.02, 0.16, uv.y) * smoothstep(0.42, 0.18, uv.y);
    // Clear: subtle wisps; mid coverage: a bit more; heavy overcast: off.
    float cirStrength = mix(0.10, 0.04, coverageAmt) * cirAllow;
    float cirA = smoothstep(0.58, 0.90, cir) * cirBand * cirStrength;
    vec3 cirCol = mix(col, vec3(1.0), 0.55 + 0.2 * iLight);
    col = mix(col, cirCol, cirA * (1.0 - cover));
  }

  // --- rain ---
  if (rainAmt > 0.001) {
    float gust = vnoise(vec2(uv.x * aspect * 0.55 - t * 0.15, t * 0.07));
    float R = rainAmt * (0.40 + 1.30 * gust);
    float gs = 0.08 * (R - rainAmt);

    vec2 ruv = vec2(uv.x * aspect, uv.y + scrollN * 0.35);
    float rain =
        rainLayer(ruv, t, 28.0, 0.95, 0.05 + 0.12 * iWind + gs, 0.040, 2.0) *
            0.30 +
        rainLayer(ruv, t, 18.0, 1.35, 0.07 + 0.15 * iWind + gs, 0.022, 59.0) *
            0.60 +
        rainLayer(ruv, t, 11.0, 1.90, 0.09 + 0.18 * iWind + gs, 0.010, 127.0) *
            0.95;
    rain *= R * smoothstep(0.0, 0.18, uv.y);

    vec3 dropCol = mix(col, vec3(0.85, 0.90, 0.98), 0.55);
    dropCol += vec3(0.75, 0.85, 1.0) * clamp(iLightning, 0.0, 1.0);
    col = mix(col, dropCol, clamp(rain * 0.70, 0.0, 1.0));

    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = mix(col, vec3(luma) * vec3(0.88, 0.93, 1.02), 0.28 * rainAmt);
    col *= 1.0 - 0.14 * rainAmt;
  }

  // --- fog ---
  if (fogAmt > 0.001) {
    vec2 fp = vec2(uv.x * aspect * 0.9, uv.y * 1.5);
    float bank = vnoise(fp * 1.1 + vec2(0.035, 0.0) * t) * 0.40
               + vnoise(fp * 2.2 + vec2(0.08, -0.045) * t) * 0.35
               + vnoise(fp * 4.4 + vec2(-0.02, 0.055) * t) * 0.25;
    bank = smoothstep(0.32, 0.70, bank);

    float height = smoothstep(0.02, 0.85, uv.y);
    float density = fogAmt * height * (0.25 + 1.80 * bank) * (0.9 + 2.6 * fogAmt);

    vec3 air = mix(mix(vec3(0.72, 0.76, 0.82), vec3(0.90, 0.93, 0.96), iLight),
                   vec3(0.10, 0.12, 0.18), wNight);
    float ang = length(sunOff);
    air += vec3(1.0, 0.92, 0.80) * exp(-ang * 2.0) * 0.15 * sunVis;
    col = mix(air, col, exp(-density));
  }

  // --- lightning (only when flashing) ---
  float flash = clamp(iLightning, 0.0, 1.0);
  if (flash > 0.001) {
    col += vec3(0.65, 0.75, 0.95) * flash * (0.12 + 0.35 * cover);
    col = mix(col, vec3(0.78, 0.84, 0.96), flash * 0.14);
    vec2 buv = uv - vec2(0.5 + 0.1 * sin(floor(t * 3.0)), 0.0);
    buv.x *= aspect;
    float seed = floor(t * 3.0);
    float jig = (hash12(vec2(seed, 2.0)) - 0.5) * 0.5;
    float disp = 0.0;
    float amp = 0.13;
    float fr = 3.0;
    for (int i = 0; i < 5; i++) {
      disp += amp * sin(buv.y * fr + t * 2.0 + float(i) * 9.0 + seed);
      amp *= 0.5;
      fr *= 2.1;
    }
    float bolt = (0.0055 / (abs(buv.x - jig - disp) + 0.002)) *
                 smoothstep(0.95, 0.08, uv.y);
    float branch = (0.002 / (abs(buv.x - jig - disp * 0.6 + 0.04) + 0.004)) *
                   smoothstep(0.7, 0.15, uv.y);
    col += vec3(0.85, 0.92, 1.0) * (bolt + 0.45 * branch) * flash;
  }

  // Tonemap + dither.
  col = max(col, vec3(0.0));
  vec3 mapped = (col * (2.51 * col + 0.03)) /
                (col * (2.43 * col + 0.59) + 0.14);
  col = clamp(mapped, 0.0, 1.0);
  col += (ign(fc.xy) - 0.5) / 255.0;
  fragColor = vec4(col, 1.0);
}
