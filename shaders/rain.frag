#include <flutter/runtime_effect.glsl>

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;

out vec4 fragColor;

vec2 hash22(vec2 p) {
    vec2 p2 = fract(p * vec2(.1031, .1030));
    p2 += dot(p2, p2.yx + 19.19);
    return fract((p2.x + p2.y) * p2);
}

#define round(x) floor((x) + .5)

float simplex2D(vec2 p) {
    const float K1 = (sqrt(3.) - 1.) / 2.;
    const float K2 = (3. - sqrt(3.)) / 6.;
    const float K3 = K2 * 2.;

    vec2 i = floor(p + dot(p, vec2(K1)));

    vec2 a = p - i + dot(i, vec2(K2));
    vec2 o = 1. - clamp((a.yx - a) * 1.e35, 0., 1.);
    vec2 b = a - o + K2;
    vec2 c = a - 1.0 + K3;

    vec3 h = clamp(.5 - vec3(dot(a, a), dot(b, b), dot(c, c)), 0., 1.);

    h *= h;
    h *= h;

    vec3 n = vec3(
        dot(a, hash22(i) - .5),
        dot(b, hash22(i + o) - .5),
        dot(c, hash22(i + 1.) - .5)
    );

    return dot(n, h) * 140.;
}

vec2 wetGlass(vec2 p) {
    p += simplex2D(p * 0.1) * 3.;

    float t = iTime;

    p *= vec2(.025, .025 * .25);
    p.y += t * .25;

    vec2 rp = round(p);
    vec2 dropPos = p - rp;
    vec2 noise = hash22(rp);

    dropPos.y *= 4.;

    t = t * noise.y + (noise.x * 6.28);

    vec2 trailPos = vec2(dropPos.x, fract((dropPos.y - t) * 2.) * .5 - .25);

    dropPos.y += cos(t + cos(t));

    float trailMask = clamp(dropPos.y * 2.5 + .5, 0., 1.);

    float dropSize = dot(dropPos, dropPos);

    float trailSize = clamp(trailMask * dropPos.y - 0.5, 0., 1.) + 0.5;
    trailSize = dot(trailPos, trailPos) * trailSize * trailSize;

    float drop = clamp(dropSize * -60. + 3. * noise.y, 0., 1.);
    float trail = clamp(trailSize * -60. + .5 * noise.y, 0., 1.);

    trail *= trailMask;

    return drop * dropPos + trailPos * trail;
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = fragCoord.xy / iResolution.xy;

    uv += wetGlass(fragCoord);

    fragColor = texture(iChannel0, uv);
}
