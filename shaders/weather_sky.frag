#include <flutter/runtime_effect.glsl>

uniform float iTime;
uniform vec2 iResolution;
uniform float iScene;
uniform float iScroll;
uniform float iCloud;
uniform float iRain;
uniform float iWind;
uniform float iSunPhase;
uniform float iLight;

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
    return mix(
        mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
        mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float cloudFbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 3; i++) {
        v += a * vnoise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

float cloudShape(vec2 uv, float time, float density) {
    vec2 p = uv * 1.2;
    p.x += time * 0.02;
    float threshold = mix(0.58, 0.40, density);
    return smoothstep(threshold, threshold + 0.05, cloudFbm(p));
}

vec3 skyColor(float y, int scene, float light) {
    if (scene == 0) {
        vec3 darkTop = vec3(0.05, 0.16, 0.34);
        vec3 darkBot = vec3(0.36, 0.68, 0.87);
        vec3 lightTop = vec3(0.42, 0.66, 0.90);
        vec3 lightBot = vec3(0.78, 0.90, 0.98);
        return mix(mix(darkTop, lightTop, light), mix(darkBot, lightBot, light), y);
    }
    if (scene == 1) {
        return mix(vec3(0.02, 0.04, 0.08), vec3(0.07, 0.11, 0.17), y);
    }
    if (scene == 2) {
        vec3 a = vec3(0.83, 0.38, 0.16);
        vec3 b = vec3(0.37, 0.14, 0.33);
        vec3 c = vec3(0.09, 0.04, 0.16);
        return y < 0.5 ? mix(c, b, y * 2.0) : mix(b, a, (y - 0.5) * 2.0);
    }
    vec3 a = vec3(0.94, 0.50, 0.19);
    vec3 b = vec3(0.63, 0.20, 0.12);
    vec3 c = vec3(0.09, 0.05, 0.05);
    return y < 0.5 ? mix(c, b, y * 2.0) : mix(b, a, (y - 0.5) * 2.0);
}

float starField(vec2 uv, float density, float time) {
    vec2 grid = floor(uv);
    vec2 gv = fract(uv) - 0.5;
    vec2 r = hash22(grid);
    float exists = step(density, r.x);
    vec2 starPos = (r - 0.5) * 0.7;
    float d = length(gv - starPos);
    float core = 1.0 / (1.0 + d * d * 600.0);
    float twinkle = 0.55 + 0.45 * sin(time * 2.2 + r.x * 6.28);
    return core * exists * mix(0.45, 1.0, r.y) * twinkle;
}

float crescentMoon(vec2 uv, vec2 c, float r) {
    float d1 = length(uv - c) - r;
    float d2 = length(uv - c - vec2(r * 0.45, -r * 0.07)) - r * 0.85;
    float crescent = max(d1, -d2);
    return smoothstep(0.004, -0.004, crescent);
}

float radialGlow(vec2 uv, vec2 c, float falloff) {
    float d = length(uv - c);
    return exp(-d * falloff);
}

float disc(vec2 uv, vec2 c, float r) {
    float d = length(uv - c);
    return smoothstep(r + 0.005, r - 0.005, d);
}

float rainStreaks(vec2 uv, float time) {
    vec2 p = uv * vec2(50.0, 8.0);
    p.x += p.y * 0.5;
    p.y -= time * 6.0;
    vec2 cell = floor(p);
    vec2 cv = fract(p);
    float r = hash12(cell);
    float alive = step(0.62, r);
    float streak = (1.0 - cv.y * 0.7) * (1.0 - smoothstep(0.0, 0.06, abs(cv.x - 0.5)));
    return streak * alive;
}

void main() {
    vec2 fc = FlutterFragCoord();
    vec2 uv = fc.xy / iResolution.xy;
    float aspect = iResolution.x / iResolution.y;
    vec2 puv = vec2(uv.x * aspect, uv.y);

    int scene = int(iScene + 0.5);

    float scrollN = iScroll / iResolution.y;
    float p1 = scrollN * 0.10;
    float p2 = scrollN * 0.22;
    float p3 = scrollN * 0.40;

    vec3 col = skyColor(uv.y, scene, iLight);

    // Slightly dim sky as cloud cover increases
    col = mix(col, col * mix(0.70, 0.82, iLight), iCloud * 0.30);

    // Sun position arcs east-to-west with the time-of-day phase
    float phase = clamp(iSunPhase, 0.0, 1.0);
    float sunX = mix(0.50, 0.95, phase) * aspect;
    float sunY = 0.40 - sin(phase * 3.14159) * 0.30;
    vec2 sunC = vec2(sunX, sunY - p3);

    if (scene == 0) {
        float sunVis = 1.0 - iCloud * 0.7;
        float dSun = length(puv - sunC);
        // Soft outer bloom
        col += vec3(1.0, 0.76, 0.28) * exp(-dSun * 9.0) * 0.25 * sunVis;
        // Tighter glow
        col += vec3(1.0, 0.86, 0.42) * exp(-dSun * 18.0) * 0.55 * sunVis;
        // Disc with internal gradient: golden rim → bright yellow core,
        // gradient sampled from a point slightly above-left of the sun center
        float discR = 0.050;
        vec2 gradC = sunC - vec2(0.003, 0.003);
        float dGrad = length(puv - gradC);
        vec3 rim = vec3(1.0, 0.78, 0.32);
        vec3 core = vec3(1.0, 0.95, 0.60);
        vec3 discCol = mix(core, rim, smoothstep(0.0, discR, dGrad));
        float discMask = smoothstep(discR + 0.004, discR - 0.004, dSun);
        col = mix(col, discCol, discMask * sunVis);
    }
    else if (scene == 1) {
        float starVis = 1.0 - iCloud * 0.85;
        float bgY = uv.y + p1;
        float bgStars = starField(vec2(uv.x * aspect, bgY) * 65.0, 0.78, iTime)
                      * smoothstep(0.78, 0.0, bgY);
        col += vec3(bgStars * 0.55 * starVis);

        float midY = uv.y + p2;
        float midStars = starField(vec2(uv.x * aspect, midY) * 38.0, 0.66, iTime + 1.7)
                       * smoothstep(0.58, 0.0, midY);
        col += vec3(midStars * 0.95 * starVis);

        vec2 moonC = vec2(aspect * 0.84, 0.10 - p3);
        col += vec3(0.85, 0.88, 0.97) * radialGlow(puv, moonC, 9.0) * 0.20 * starVis;
        col = mix(col, vec3(0.88, 0.91, 0.99), crescentMoon(puv, moonC, 0.06) * starVis);
    }
    else {
        // Dawn (scene 2) or sunset (scene 3): warm sun rides the same arc.
        vec3 sunCol = scene == 2 ? vec3(0.93, 0.46, 0.27) : vec3(1.0, 0.55, 0.26);
        float sunVis = 1.0 - iCloud * 0.5;
        col += sunCol * radialGlow(puv, sunC, 5.0) * 0.40 * sunVis;
        col += sunCol * radialGlow(puv, sunC, 9.0) * 0.70 * sunVis;
        col = mix(col, sunCol * 1.2, disc(puv, sunC, 0.085) * sunVis);
    }

    // Cloud overlay
    if (iCloud > 0.01) {
        vec3 cloudHi;
        vec3 cloudLo;
        if (scene == 1) {
            cloudHi = vec3(0.20, 0.22, 0.28);
            cloudLo = vec3(0.10, 0.12, 0.16);
        }
        else if (scene == 2) {
            cloudHi = vec3(0.85, 0.55, 0.45);
            cloudLo = vec3(0.45, 0.22, 0.30);
        }
        else if (scene == 3) {
            cloudHi = vec3(1.0, 0.65, 0.40);
            cloudLo = vec3(0.55, 0.25, 0.18);
        }
        else {
            cloudHi = vec3(1.0, 0.99, 0.95);
            cloudLo = vec3(0.62, 0.68, 0.76);
        }
        vec3 cloudCol = mix(cloudHi, cloudLo, iCloud);

        float drift = iTime * (0.3 + iWind * 1.4);
        float cy1 = uv.y + p1;
        vec2 cloudUV = vec2(uv.x * aspect, cy1) * vec2(1.8, 2.5);
        float c1 = cloudShape(cloudUV, drift, iCloud) * smoothstep(0.55, 0.0, cy1);
        float c1Up = cloudShape(cloudUV + vec2(0.0, -0.10), drift, iCloud)
                   * smoothstep(0.55, 0.0, cy1);
        col = mix(col, cloudCol, c1);
        col = mix(col, cloudLo * 0.55, c1 * c1Up * 0.45);

        if (iCloud > 0.4) {
            float cy2 = uv.y + p3;
            vec2 cloudUV2 = vec2(uv.x * aspect, cy2) * vec2(2.0, 2.2) + 17.3;
            float c2 = cloudShape(cloudUV2, drift * 1.4 + 50.0, iCloud)
                     * smoothstep(0.40, 0.0, cy2);
            col = mix(col, cloudLo, c2 * 0.6);
        }
    }

    // Rain overlay
    if (iRain > 0.02) {
        float ry = uv.y + p3;
        float rain = rainStreaks(vec2(uv.x * aspect, ry), iTime)
                   * smoothstep(0.60, 0.10, ry);
        vec3 rainTint = scene == 1 ? vec3(0.4, 0.5, 0.65) : vec3(0.55, 0.65, 0.78);
        col += rainTint * rain * 0.45 * iRain;
    }

    fragColor = vec4(col, 1.0);
}
