// Rain on the glass — droplets clinging to a card's face, refracting it.
//
// Applied as a `ui.ImageFilter.shader` over the card's own pixels, so what
// bends is the content itself: text visibly warps behind a bead rather than
// having a droplet drawn flat on top of it.
//
// The field is built from two populations, which is what water on a vertical
// pane actually does:
//
//   • **Beads** condense in place on a jittered lattice, grow quickly, hold,
//     and evaporate slowly. The asymmetry matters — a symmetric envelope makes
//     the whole field pulse in step, which reads as a flicker rather than as
//     weather. Each bead runs its own clock, seeded from its cell.
//   • **Runners** are beads that grew heavy enough to break their pinning and
//     slide. One track per column; a runner clings, releases, accelerates, and
//     drags a thinning ribbon behind it that pinches off into a line of shed
//     droplets. The ribbon and the shed beads are unioned, not added, because
//     the tail is one body of water breaking up, not two overlapping ones.
//
// The two populations are combined with a **soft union** (`max` plus a
// fraction of `min`) rather than a sum: surface tension merges two touching
// drops into one larger drop, it does not stack their heights.
//
// Refraction is the field's own gradient. The coverage mask is sampled three
// times — here, one step in x, one step in y — and the pair `(c-cx, c-cy)` is
// the surface's slope, which offsets the texture lookup. There is no lighting
// term at all; the displacement IS the effect, and it is large: the finite
// difference of a 0..1 mask reaches hundreds of pixels at a bead's rim, which
// is what makes this a lens rather than a nudge.
//
// The coordinate frame is a **fixed 1080x1080** ([uResolution]), not the
// filtered widget. Every bead size and the refraction displacement are
// computed against that frame in device pixels, so a bead is the same physical
// size on every card in the app. Deriving the frame from the filtered widget's
// own size — as an earlier version did — shrinks the beads by the card/screen
// ratio and they stop reading as water. The engine-fed input size ([uSize]) is
// used only to normalise the texture lookups.
//
// Uniform contract — slots are float indices in declaration order.
//   uSize             (0..1) input texture size — SET BY THE ENGINE, not us
//   uResolution       (2..3) the fixed 1080x1080 frame, in device pixels
//   uTime             (4)    animation time (seconds)
//   uStaticDropSize   (5)    bead lattice scale — a DIVISOR, larger = fewer,
//                            bigger beads
//   uStaticDropAmount (6)    bead coverage
//   uStaticDropSpeed  (7)    how fast beads condense and evaporate
//   uRunningDropSize  (8)    runner column width — also a divisor
//   uRunningDropAmount(9)    runner coverage
//   uRunningDropSpeed (10)   how fast runners slide
//   uAlpha            (11)   effect strength, 0 passes the content through
//   sampler 0: uTex          the content being filtered — SET BY THE ENGINE
#include <flutter/runtime_effect.glsl>

precision highp float;

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

/// Runner tracks across the fixed frame's width, at `uRunningDropSize` 1.
const float kColumns = 14.0;

/// How far down the frame a runner travels, in frame heights.
const float kRunSpan = 1.25;

/// Runner releases per second at `uRunningDropSpeed` 1.
///
/// This and [kRunSpan] are the two halves of one speed, and setting only one
/// of them is how the first version came out four times too fast: a full-frame
/// traverse at one release per second crosses a card in a tenth of a second,
/// which reads as a streak rather than as a drop. At the rate below a runner
/// takes about half a second to cross a 120pt card in a downpour and a couple
/// of seconds in drizzle, which is what water on glass actually does.
const float kRunRate = 0.21;

/// Bead condense-and-evaporate cycles per second at `uStaticDropSpeed` 1.
/// Condensation is slow — a bead that appears and is gone inside a second
/// reads as a flicker, not as water gathering.
const float kBeadRate = 0.15;

/// Where a runner releases, in frame units. Nothing of its tail exists above
/// this line.
const float kReleaseY = 0.62;

/// Three uncorrelated values from a lattice cell.
vec3 hash32(vec2 p) {
  vec3 q = vec3(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)),
                dot(p, vec2(419.2, 371.9)));
  return fract(sin(q) * 43758.5453123);
}

/// Condensed beads on a jittered lattice.
float beadLayer(vec2 uv, float t) {
  vec2 g = uv * (40.0 / uStaticDropSize);
  vec2 cell = floor(g);
  vec2 f = fract(g) - 0.5;
  vec3 h = hash32(cell);

  // Condense fast, hold, evaporate slowly. Offsetting each bead's clock by its
  // own cell hash is what keeps the lattice from breathing as one sheet.
  float life = fract(t * uStaticDropSpeed * kBeadRate + h.z);
  float envelope =
      smoothstep(0.0, 0.10, life) * (1.0 - smoothstep(0.42, 1.0, life));

  // Jitter is bounded so a bead cannot reach its cell's edge — one cell is
  // sampled, not a neighbourhood, and a bead crossing the boundary would clip.
  vec2 centre = (h.xy - 0.5) * 0.46;
  float radius = (0.11 + 0.17 * fract(h.z * 7.31)) * envelope;
  float d = length(f - centre);
  // Nearly flat-topped with a quick shoulder: a spherical cap held by surface
  // tension, not a gaussian blob.
  return smoothstep(radius, radius * 0.45, d);
}

/// A runner and the tail it drags, for the column containing [uv].
float runLayer(vec2 uv, float t) {
  float cellW = uRunningDropSize / kColumns;
  float col = floor(uv.x / cellW);
  float xu = uv.x - (col + 0.5) * cellW;
  vec3 h = hash32(vec2(col, 11.7));

  // Successive drops down one track, staggered per column so no two columns
  // release together. The index is wrapped: it feeds a hash, and an unbounded
  // argument to `sin` loses precision long before the app is closed.
  float k = t * uRunningDropSpeed * kRunRate * (0.6 + 0.8 * h.x) + h.y;
  vec3 hd = hash32(vec2(col, mod(floor(k), 64.0)));
  float u = fract(k);

  // Cling, release, accelerate, and slow again as the tail drains. A linear
  // descent reads as a machine part sliding on a rail.
  float travel = u * u * (1.6 - 0.6 * u);
  float headY = kReleaseY - travel * kRunSpan;

  float dx = xu - (hd.x - 0.5) * cellW * 0.5;
  float dy = uv.y - headY;  // > 0 is above the head, i.e. the tail

  float rHead = cellW * (0.18 + 0.13 * hd.y);
  // Taller than wide: a drop being dragged is stretched along its travel.
  float head = smoothstep(rHead, rHead * 0.40, length(vec2(dx, dy * 0.82)));

  // The tail exists only behind the head and only below the release point —
  // a runner leaves a wet track, it does not paint the column it came from.
  float inTrack = step(0.0, dy) * step(uv.y, kReleaseY);
  // And it is SHORT. Tapering by a fraction of the total travel keeps the
  // trail full width however far the drop has gone, which silhouettes as a
  // hard vertical bar — the one shape here that reads as a machine part.
  float taper = exp(-dy / (rHead * 7.0));

  // A rounded ridge, not a flat-topped ribbon: `smoothstep(r, 0, |dx|)` peaks
  // at the centre line and reaches zero at the edge.
  // Faded by `taper` in AMPLITUDE as well as width. Width alone is not
  // enough: `smoothstep(r, 0, |dx|)` is exactly 1 on the centre line for any
  // r > 0, so a ribbon that only narrows leaves a permanent one-pixel hairline
  // running the full height of the track.
  float ribbonR = rHead * 0.34 * taper;
  float ribbon = smoothstep(ribbonR, 0.0, abs(dx)) * inTrack * taper;

  // The track pinches off into a line of beads rather than staying a filament,
  // each smaller and more scattered the further back it is.
  float pitch = rHead * 2.4;
  float sIdx = floor(dy / pitch);
  float sY = fract(dy / pitch) - 0.5;
  vec3 hs = hash32(vec2(col * 7.0 + sIdx, floor(k)));
  float shedR = 0.42 * taper * (0.6 + 0.5 * hs.x);
  float sX = dx - (hs.y - 0.5) * rHead * 0.6;
  float shed =
      smoothstep(shedR, shedR * 0.30, length(vec2(sX / (rHead * 1.2), sY))) *
      inTrack;

  return head + max(ribbon, shed);
}

/// The droplet coverage mask, 0 (dry) to 1.
float coverage(vec2 uv, float t, float beadGain) {
  float b = beadLayer(uv, t) * uStaticDropAmount * beadGain;
  float r = runLayer(uv, t) * uRunningDropAmount;
  // Soft union: two touching drops merge into one, they do not stack.
  float merged = max(b, r) + 0.35 * min(b, r);
  return smoothstep(0.22, 0.92, merged);
}

void main() {
  vec2 xy = FlutterFragCoord().xy;
  // The OpenGL ES backend hands image filters a y-flipped texture, so the
  // sampler needs the mirrored row. The **field** must not be mirrored with
  // it: flipping `xy` before the field is built reverses `uv.y`, and the
  // runners then slide *up* the glass. Worse, the mirror is about `uSize.y/2`
  // while the field is scaled by the fixed frame, so it also translates the
  // lattice by `uSize.y - uResolution.y`. Keep the two coordinates separate.
  vec2 texXY = xy;
#ifdef IMPELLER_TARGET_OPENGLES
  texXY.y = uSize.y - xy.y;
#endif

  // The field's frame: centred, normalised by the fixed frame's height, and
  // with y increasing upward so a runner's descent is a decrease.
  vec2 uv = (xy - 0.5 * uResolution) / uResolution.y;
  uv.y = -uv.y;

  // Fade the whole effect in, so it does not appear fully formed.
  float alpha = smoothstep(0.0, 2.0, uTime);
  // Wrapped well inside single-precision range; the hashes are seeded by cell,
  // not by time, so nothing is lost at the seam.
  float t = mod(uTime, 600.0);

  // Beads thin out toward the top of the frame, where a card's own edge sheds
  // water fastest. A flat field over the whole card reads as frosted glass.
  float beadGain = 0.75 + 0.35 * smoothstep(0.45, -0.35, uv.y);

  float c = coverage(uv, t, beadGain);
  if (c > 0.001) {
    // A true 2-D gradient, so a bead refracts radially the way a lens does.
    vec2 e = vec2(0.0006, 0.0);
    float cx = coverage(uv + e.xy, t, beadGain);
    float cy = coverage(uv + e.yx, t, beadGain);
    vec2 n = vec2(c - cx, c - cy);

    // `n` is in frame units, so the displacement is `n * uResolution` device
    // pixels. It is not small — the finite difference of a 0..1 mask reaches
    // hundreds of pixels at a bead's rim.
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
