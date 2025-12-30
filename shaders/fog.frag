#include <flutter/runtime_effect.glsl>

uniform float iTime;
uniform vec2 iResolution;
uniform sampler2D iChannel0;
uniform float iIntensity;
uniform float iSpeed;

out vec4 fragColor;

vec2 hash22(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

float noise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    
    vec2 a = hash22(i);
    vec2 b = hash22(i + vec2(1.0, 0.0));
    vec2 c = hash22(i + vec2(0.0, 1.0));
    vec2 d = hash22(i + vec2(1.0, 1.0));
    
    vec2 u = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(a.x, b.x, u.x),
        mix(c.x, d.x, u.x),
        u.y
    );
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;
    
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    
    for (int i = 0; i < 6; i++) {
        value += amplitude * noise2D(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
        p = rot * p;
    }
    
    return value;
}

float fogMask(vec2 uv) {
    vec2 p = uv * 3.0;
    p.x -= iTime * iSpeed * 0.1;
    p.y += iTime * iSpeed * 0.02;
    
    float fog = fbm(p);
    
    float fog2 = fbm(p * 1.5 - vec2(iTime * iSpeed * 0.12, 0.0));
    fog = mix(fog, fog2, 0.5);
    
    fog = smoothstep(0.2, 0.8, fog);
    
    return fog * iIntensity;
}

void main() {
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec4 originalColor = texture(iChannel0, uv);
    
    float fog = fogMask(uv);
    
    vec3 fogColor = vec3(0.95, 0.97, 1.0);
    
    vec3 finalColor = mix(originalColor.rgb, fogColor, fog);
    
    fragColor = vec4(finalColor, originalColor.a);
}

