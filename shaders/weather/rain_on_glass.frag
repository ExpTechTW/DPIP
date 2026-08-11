// Rain on the glass — droplets clinging to a card's face, refracting it.
//
// Hung on the card as a `RenderEffect`, so what bends is the card's own
// pixels: text visibly warps behind a bead rather than having a droplet drawn
// flat on top of it.
//
// What it does, in order:
//   • builds a droplet coverage field `c` from two layers — static beads that
//     fade in and out in place, and running beads that slide down the glass
//   • samples the field once more one step to the right, and takes the pair
//     `(c - cx, cx - c)` as a surface gradient
//   • offsets the texture lookup by that gradient — that displacement *is* the
//     refraction; there is no lighting term, the specular block is dead code
//   • `mix`es between the untouched pixel and the refracted one by `uAlpha`
//
// Two details that are easy to lose and both matter:
//   • `if (c > 0.001)` — pixels with no droplet on them are passed through
//     untouched rather than being refracted by a zero gradient.
//   • `mod(uTime * 0.46, 5.0)` — the clock wraps every five seconds, so the
//     field never drifts into the range where the hash loses precision.
//
// The coordinate frame is **not** the filtered view. `uResolution` is a
// hard-coded 1080×1080, set once and never updated for any view. Every bead
// size, the field's centring, and the refraction displacement are computed
// against that fixed frame in device pixels, which is why a bead is the same
// physical size on every card. Deriving the frame from the filtered widget's
// own size — as an earlier version did — shrinks the beads by the card/screen
// ratio. The engine-fed input size ([uSize]) is used only to normalise the
// texture lookups.
//
// Uniform contract — slots are float indices in declaration order.
//   uSize             (0..1) input texture size — SET BY THE ENGINE, not us
//   uResolution       (2..3) the fixed 1080×1080 frame, in device pixels
//   uTime             (4)    animation time (seconds)
//   uStaticDropSize   (5)    static bead scale (larger = fewer, bigger)
//   uStaticDropAmount (6)    static bead coverage
//   uStaticDropSpeed  (7)    how fast static beads appear and fade
//   uRunningDropSize  (8)    running bead scale
//   uRunningDropAmount(9)    running bead coverage
//   uRunningDropSpeed (10)   how fast running beads slide
//   uAlpha            (11)   effect strength, 0 passes the content through
//   sampler 0: uTex          the content being filtered — SET BY THE ENGINE
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform vec2 uResolution;
uniform float uTime;
uniform float uStaticDropSize;
uniform float uStaticDropAmount;
uniform float uStaticDropSpeed;
uniform float uRunningDropSize;
uniform float uRunningDropAmount;
uniform float uRunningDropSpeed;
uniform float uAlpha;
uniform sampler2D uTex;

out vec4 fragColor;

/// The grid the running beads live on. Written out as a literal in the shipped
/// shader; it is the `vec2(6, 1) * 3` of the older revision.
const vec2 kGrid = vec2(18.0, 3.0);

vec3 N13(float p) {
  vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.11369, 0.13787));
  p3 += dot(p3, p3.yzx + 19.19);
  return fract((p3.xxy + p3.yzz) * p3.zyx);
}

float N(float t) {
  return fract(sin(t * 12345.564) * 7658.76);
}

float Saw(float b, float t) {
  return smoothstep(0.0, b, t) * smoothstep(1.0, b, t);
}

/// Per-cell noise for the running layer, hoisted out of the layer itself so the
/// gradient probe below re-uses it instead of re-hashing.
vec4 GenDropLayerN(vec2 uv, float t) {
  t *= uRunningDropSpeed;
  uv /= uRunningDropSize;
  uv.y += t * 0.55;

  vec2 id = floor(uv * kGrid);
  float colShift = N(id.x);
  uv.y += colShift;
  id = floor(uv * kGrid);
  vec3 n = N13(id.x * 35.2 + id.y * 2376.1);
  return vec4(n, colShift);
}

float DropLayer2(vec2 uv, vec3 n, float t, float colShift) {
  t *= uRunningDropSpeed;
  float oldY = uv.y;

  uv /= uRunningDropSize;
  uv.y += t * 0.55;
  uv.y += colShift;

  vec2 a = vec2(6.0, 1.0);
  vec2 st = fract(uv * kGrid) - vec2(0.5, 0.0);
  float x = n.x - 0.5;
  float y = oldY * 20.0;
  x *= 0.7;
  float ti = fract(t + n.z);
  y = (Saw(0.9, ti) - 0.5) * 0.9 + 0.5;
  vec2 p = vec2(x, y);
  float d = length((st - p) * a.yx);

  float mainDrop = smoothstep(0.4, 0.0, d);

  float rr = smoothstep(1.0, y, st.y);
  float r = sqrt(rr);
  float cd = abs(st.x - x);

  // The trail is commented out in the shipped shader; only its front edge is
  // still used, as a mask on the shed droplets.
  float trailFront = smoothstep(-0.02, 0.02, st.y - y);
  y = oldY;

  y = fract(y * 10.0) + (st.y - 0.5);
  float dd = length(st - vec2(x, y));
  float droplets = smoothstep(0.3, 0.0, dd);
  return mainDrop + droplets * r * trailFront;
}

vec3 GenStaticLayerN(vec2 uv) {
  uv *= 40.0 / uStaticDropSize;
  vec2 id = floor(uv);
  return N13(id.x * 107.45 + id.y * 3543.654);
}

float StaticDrops(vec2 uv, vec3 n, float t) {
  t *= uStaticDropSpeed;
  uv *= 40.0 / uStaticDropSize;
  uv = fract(uv) - 0.5;

  vec2 p = (n.xy - 0.5) * 0.7;
  float d = length(uv - p);
  float fade = Saw(0.025, fract(t + n.z));
  return smoothstep(0.3, 0.0, d) * fract(n.z * 10.0) * fade;
}

float Drops(vec2 uv, vec3 dropN, vec3 staticN, float t, float rs, float ra,
            float colShift) {
  float s = StaticDrops(uv, staticN, t * 1.2) * rs * uStaticDropAmount;
  float m1 = DropLayer2(uv, dropN, t * 1.85, colShift) * ra * uRunningDropAmount;
  return smoothstep(0.3, 1.0, s + m1);
}

void main() {
  vec2 xy = FlutterFragCoord().xy;
  // The OpenGL ES backend hands image filters a y-flipped texture, so the
  // sampler needs the mirrored row. The **field** must not be mirrored with
  // it: flipping `xy` before the field is built reverses `uv.y`, and the
  // running beads — whose lattice scrolls with `uv.y += t * 0.55` — then slide
  // *up* the glass. Worse, the mirror is about `uSize.y / 2` while the field
  // is scaled by the fixed 1080 frame, so it also translates the lattice by
  // `uSize.y - 1080`. Keep the two coordinates separate.
  vec2 texXY = xy;
#ifdef IMPELLER_TARGET_OPENGLES
  texXY.y = uSize.y - xy.y;
#endif

  // All in the fixed 1080-frame, exactly as shipped.
  vec2 UV = xy / uResolution;
  vec2 uv = (xy - 0.5 * uResolution) / uResolution.y;
  uv.y = 1.0 - uv.y;

  float alpha = smoothstep(0.0, 2.0, uTime);
  // Wraps every five seconds — see the note at the top.
  float t = mod(uTime * 0.46, 5.0);

  float rainAmount = sin(UV.x * UV.y) * 0.3 + 0.7;
  float staticDrops = smoothstep(-0.5, 1.0, rainAmount) * 2.0;

  vec4 dropN = GenDropLayerN(uv, t);
  vec3 staticN = GenStaticLayerN(uv);
  float c = Drops(uv, dropN.xyz, staticN, t, staticDrops, rainAmount, dropN.w);

  if (c > 0.001) {
    vec2 e = vec2(0.0005, 0.0);
    float cx =
        Drops(uv + e, dropN.xyz, staticN, t, staticDrops, rainAmount, dropN.w);
    vec2 n = vec2(c - cx, cx - c);
    // `uTex.eval(texUV * uResolution)`: the displacement is `n` in the
    // 1080-frame, i.e. `n * uResolution` device pixels. It is not small — the
    // finite difference of a 0..1 mask reaches hundreds of pixels at a bead's
    // rim, which is what makes this a lens rather than a nudge.
    vec2 refracted = texXY + n * uResolution;

    vec4 uiColor = texture(uTex, texXY / uSize);
    // Sampled straight, with no clamp and no decal. Punching the out-of-bounds
    // lookup through to transparent was tried and looks worse here: this card
    // is small enough that a bead's displacement leaves its bounds often, so
    // the beads read as holes.
    vec4 rainDropColor = texture(uTex, refracted / uSize);
    fragColor = mix(uiColor, rainDropColor, uAlpha * alpha);
    return;
  }
  fragColor = texture(uTex, texXY / uSize);
}
