// Procedural weather sky for the home backdrop.
//
// Single pass, texture-free. Four moods (clear / rain / fog / thunderstorm) are
// the algebraic result of the weight uniforms — branchless WITHIN a mood. The
// rain and fog blocks are gated on their own uniforms, which are frame
// constants, so that branch is uniform across the whole draw (a draw-level
// early-out, not lane divergence) and a clear sky skips ~60% of the noise work. Cheap Hoskins hashes (no sin-hash), 4-octave fBM, no derivatives.
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

// 4-octave fBM that also returns the RIDGED sum in .y, for free.
//
// A smooth value-noise fBM is a sum of C1 interpolants and is near-Gaussian, so
// every iso-contour is a soft rounded blob — thresholding it can only give
// cotton. The ridged sum has creases where the signed noise crosses zero, and
// multiplying the smooth field by it carves those creases in: the creases are
// the lumpy silhouette. Zero extra hashes.
// (Accumulator folded into the existing loop; `f *= r + f` from Drift's "2D
// clouds", mirrored at https://godotshaders.com/shader/cloudy-skies/)
vec2 fbm2(vec2 p) {
  float v = 0.0;
  float r = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    float n = vnoise(p);
    v += a * n;
    r += a * abs(2.0 * n - 1.0);  // vnoise is 0..1, so signed = 2n-1
    p = M2 * p * 2.0 + 11.3;
    a *= 0.5;
  }
  return vec2(v, r);
}

// Sharp Worley F1 (distance to nearest feature point).
//
// Value/Perlin noise CANNOT make cauliflower: it is a sum of smooth
// interpolants, so every iso-contour is a rounded blob. Worley's iso-contours
// are packed convex cells with cusps between them, and inverting it puts the
// billows where the cells are. This is the structural reason the old deck read
// as smoke no matter how the octaves were tuned.
//   Häggström (DiVA thesis p.8): "The Perlin noise creates fog-like structure
//   while Worley noise adds more billowy looking shapes."
//   https://www.diva-portal.org/smash/get/diva2:1223894/FULLTEXT01.pdf
//   Schneider 2015: "Worley noise… If it is inverted… It makes tightly packed
//   billow shapes."
//
// Deliberately NOT iq's smoothVoronoi: that function exists to remove the min()
// discontinuity, and the discontinuity is the cusp we want. (It also does not
// compile here — `ivec2 p = floor(x)` has no implicit float→int cast in GLSL ES.)
// Squared distance in the loop, one sqrt at the end: 9 hashes, no transcendentals.
float worley(vec2 p) {
  vec2 n = floor(p);
  vec2 f = fract(p);
  float d = 1e9;
  for (int j = -1; j <= 1; j++) {
    for (int i = -1; i <= 1; i++) {
      vec2 g = vec2(float(i), float(j));
      vec2 r = g + hash22(n + g) - f;
      d = min(d, dot(r, r));
    }
  }
  return sqrt(d);
}

// Schlick's approximation to Henyey-Greenstein — the phase function without a
// pow(). k = 1.55g - 0.55g³ (Frostbite eq.10).
// https://media.contentapi.ea.com/content/dam/eacom/frostbite/files/s2016_pbs_frostbite_sky_clouds.pdf
//
// The sign matters: both papers print (1 + k·cosθ)² which peaks BACKWARD while
// their HG on the facing page peaks forward. (1 - k·mu) is the one that matches HG.
float schlick(float mu, float k) {
  float dn = 1.0 - k * mu;
  return (1.0 - k * k) / (12.566 * dn * dn);
}

// True Henyey-Greenstein, for the sharp silver lobe where Schlick degrades.
// dn^-1.5 via inversesqrt(dn)/dn — no pow(). The floor keeps g→1 at mu→1 finite.
float hg(float mu, float g) {
  float g2 = g * g;
  float dn = max(1.0 + g2 - 2.0 * g * mu, 1e-4);
  return (1.0 - g2) * inversesqrt(dn) / (12.566 * dn);
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
  // The aureole is not a glow sprite — it is the forward lobe of the Mie phase
  // function, which is why it reads white/silver and has a specific width.
  // Hosek & Wilkie bolt an explicit anisotropic term onto Perez precisely
  // because the ring is "a highly localised spike, one that is impossible to
  // accurately fit using the original Perez formula".
  // https://cgg.mff.cuni.cz/projects/SkylightModelling/HosekWilkie_SkylightModel_SIGGRAPH2012_Preprint_lowres.pdf
  // g = 0.76 is the standard aerosol value.
  float sunMu = cos(clamp(ang, 0.0, 1.0) * PI);
  float glow = clamp(hg(sunMu, 0.76) * 12.566, 0.0, 14.0) * 0.055;
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
  // Ridged x smooth: the ridged sum's creases carve the lumpy silhouette that a
  // near-Gaussian value-noise field can never produce on its own. Free — the
  // ridged accumulator rides along in the same octave loop.
  vec2 sr = fbm2(sky * 1.15 + 2.1 * q);   // .x smooth, .y ridged
  float field = sr.x * (sr.y + sr.x) * 1.25;

  // Erode the base shape with INVERTED Worley, via a remap rather than a
  // multiply. Nubis 2017: "as opposed to MULTIPLYING the noises together,
  // remapping prevents a loss of too much density at the core of the base cloud
  // shape" — a multiply thins core and edge alike, so nothing reads as solid.
  // https://advances.realtimerendering.com/s2017/Nubis%20-%20Authoring%20Realtime%20Volumetric%20Cloudscapes%20with%20the%20Decima%20Engine%20-%20Final%20.pdf
  // The clamp is load-bearing: this hash's F1 overshoots 1.0 on a fraction of a
  // percent of cells, where a raw 1-F1 would go negative.
  float billow = clamp(1.0 - worley(sky * 2.3), 0.0, 1.0);
  field = clamp((field - billow * 0.28) / max(1.0 - billow * 0.28, 0.25), 0.0, 1.0);

  float lo = mix(0.70, 0.22, overcast);
  // A sharp shoulder, not a 0.30-wide feather. Bouthors et al. (INRIA 2008 §2.1):
  // "Real convective clouds are not blurry on boundaries, they are usually sharp
  // or wispy… density variations are visually more important on the clouds
  // boundaries — where they are directly visible — than in the cloud core."
  // http://maverick.inria.fr/Publications/2008/BNMBC08/cloudsFINAL.pdf
  float sharpK = mix(-5.64, -1.74, overcast);  // log2(0.02) .. log2(0.30)
  float c = max(field - lo, 0.0);
  float cover = 1.0 - exp2(c * sharpK);
  // These stay MULTIPLIES: they are frame vignettes, not erosion.
  float topFade = mix(smoothstep(0.0, 0.16, uv.y), 1.0, overcast);
  cover *= topFade * smoothstep(1.06, 0.86, uv.y);

  // --- cloud lighting: transmittance x phase + sky ambient ---------------
  //
  // Single-scatter shading is precisely why a cloud reads as smoke. Frostbite
  // 2016 §5.2: "With only single scattering… clouds would only look like
  // dirty/smoky element"; §5.8: "Multi-scattering is also a key component for
  // clouds to not look like smoke." The old code was one directional compare.
  //
  // `d` is NOT an optical depth — there is no ray and no accumulator here. It is
  // how far the field sits past the coverage threshold, which on a flat sheet is
  // a monotone proxy for depth through the cloud. The constants are art
  // direction, not physics.
  float d = c * 3.2;
  // Beer's law with the energy-conserving floor: pure exp(-d) makes interiors
  // black because it models attenuation only, never light that scattered IN.
  float beer = max(exp(-d), 0.7 * exp(-0.25 * d));
  // Powder: EDGES are darker than cores, because a point deep inside a billow
  // gathers light from every direction. NOTE THE SIGN — the line this replaces
  // darkened the THICK part, which is backwards, and is why separate billows
  // merged into one flat mass.
  float powder = 1.0 - exp(-2.0 * d);
  float trans = clamp(beer * powder * 2.1, 0.0, 1.0);

  // `sunMu` (computed with the aureole above) is a screen-space proxy: this
  // shader has no view ray, so it is a distance to the sun, not a true angle.
  float mu = sunMu;
  // ONE lobe is not enough. Schneider 2017: "The eccentricity value that worked
  // well for mid-day failed to provide the bright highlights around the sun that
  // we needed at sunset." The fix is max() of a broad lobe and a very sharp one,
  // with the sharp lobe's g driven by sun height — so dawn and sunset get a
  // tighter, hotter rim with no new uniform.
  float gS = clamp(0.99 - 1.15 * sunH, -0.30, 0.99);
  float phaseC = 0.45 + 3.0 * max(schlick(mu, 0.8112), hg(mu, gS));

  vec3 cTop = wDay * vec3(1.00, 1.00, 0.99) + wNight * vec3(0.22, 0.25, 0.33) +
              wDawn * vec3(1.00, 0.80, 0.66) + wSun * vec3(1.00, 0.76, 0.56);
  vec3 cBase = wDay * vec3(0.62, 0.67, 0.76) + wNight * vec3(0.05, 0.07, 0.11) +
               wDawn * vec3(0.44, 0.30, 0.40) + wSun * vec3(0.46, 0.28, 0.28);
  // A thick deck blocks its own light: an overcast sky is darker at the base
  // than a fair-weather one, and a storm deck is darker still. Without this the
  // phase term made a thunderstorm as bright as a summer afternoon.
  float gloom = 1.0 - 0.55 * overcast;
  // Sunlight through the cloud, shaped by the phase function; plus ambient sky
  // light, which every shipped implementation ramps bottom-to-top.
  vec3 lit = cTop * trans * clamp(phaseC, 0.0, 3.2) * sunVis;
  vec3 ambient = mix(cBase, cTop, 0.35 * (1.0 - uv.y)) * (0.55 + 0.45 * trans);
  // Clamped so a phase spike cannot clip the deck to flat white and erase the
  // silhouette it was supposed to reveal.
  vec3 cloudCol = min((ambient + lit) * gloom, vec3(1.35));
  col = mix(col, cloudCol, cover);

  // --- rain (3 parallax drop layers + gusts + wet grade) ---
  float rainAmt = clamp(iRain, 0.0, 1.0);
  if (rainAmt > 0.0) {
  // Gusts and sheets. Tremblay et al. parameterise the whole appearance of rain
  // by one scalar R (mm/hr) — count, length and extinction all derive from it —
  // so the coherent way to get squalls is to make R itself a slow low-frequency
  // field and let everything move together. https://arxiv.org/pdf/2009.03683
  // (Driving R from a noise field is an adaptation: no published rendering
  // source models gusts. The structure is lifted from three.js Sky.js's cloud
  // `region` term.) It scrolls sideways FASTER than the drops fall, so a sheet
  // sweeps across the frame instead of sitting still.
  float gust = vnoise(vec2(uv.x * aspect * 0.55 - t * 0.16, t * 0.09));
  float R = rainAmt * (0.45 + 1.25 * gust);
  float gs = 0.07 * (R - rainAmt);  // a gust steepens the shear too

  vec2 ruv = vec2(uv.x * aspect, uv.y + scrollN * 0.4);
  // Marshall-Palmer + Gunn-Kinzer: drop COUNT scales as R^0.21 and streak
  // length as R^0.105, so a 10x rain rate is only ~1.6x more drops. Cranking
  // density is the wrong lever for "heavy" — the gust must show up as
  // brightness and shear, not as more geometry.
  // https://cave.cs.columbia.edu/Statics/publications/pdfs/Garg_IJCV07.pdf
  float rain =
      rainLayer(ruv, t, 26.0, 0.85, 0.05 + 0.10 * iWind + gs, 0.055, 3.0) * 0.40 +
      rainLayer(ruv, t, 17.0, 1.25, 0.07 + 0.14 * iWind + gs, 0.028, 61.0) * 0.70 +
      rainLayer(ruv, t, 11.0, 1.75, 0.09 + 0.18 * iWind + gs, 0.012, 131.0) * 1.00;
  rain *= R * smoothstep(0.0, 0.22, uv.y);

  // A drop is a 165-degree wide-angle lens: it refracts light from most of the
  // environment with only ~6% loss, so its colour is the ENVIRONMENT AVERAGE,
  // not a fixed blue-grey. https://cave.cs.columbia.edu/Statics/publications/pdfs/Garg_TR04.pdf
  // Composited as a LERP, not an add (Garg & Nayar eq.16). The physical weight
  // is <0.039, which against a bright sky is invisible — so the FORM is physical
  // and the weight is openly not, exactly as production does it: Tatarchuk &
  // Isidoro, "we use a cinematic technique of adding milk to water while filming
  // rain… and bias the raindrops color toward the white spectrum".
  vec3 dropCol = mix(zenith, horizon, 0.55) * 0.94 + sunCol * 0.10 * sunVis;
  dropCol = mix(dropCol, vec3(1.0), 0.35);
  dropCol += vec3(0.80, 0.88, 1.00) * clamp(iLightning, 0.0, 1.0) * 1.10;
  col = mix(col, dropCol, clamp(rain * 0.75, 0.0, 1.0));
  float luma = dot(col, vec3(0.299, 0.587, 0.114));
  col = mix(col, vec3(luma) * vec3(0.86, 0.90, 0.98), 0.30 * rainAmt);
  col *= 1.0 - 0.18 * rainAmt;
  }

  // --- fog: flat spectrum + forward-scattered airlight + a top ----------
  //
  // Beer-Lambert extinction toward airlight is the right operator (fog OCCLUDES
  // rather than tints — https://iquilezles.org/articles/fog/), but three things
  // were making it a flat grey wall:
  //   1. a HALVING fBM spectrum is dominated by its lowest octave, so the field
  //      was one smooth gradient. Three single octaves at a nearly FLAT
  //      amplitude ramp keep mid-frequency energy, which is what makes banks.
  //   2. those octaves scrolled as one rigid texture. Independent velocities
  //      make the field churn and reorganise.
  //   3. airlight was isotropic. It is forward-scattered: fog is dazzling toward
  //      the sun and dim away from it, and that large-scale luminance gradient
  //      is most of why fog reads as a lit volume rather than a grey fill.
  float fogAmt = clamp(iFog, 0.0, 1.0);
  if (fogAmt > 0.0) {
    // Height-fog integral: density a·exp(-b·y) integrated in closed form, so the
    // veil has a TOP and thins on the right curve. (iq, same article. The
    // ro/rd mapping is synthesised from uv — this shader has no camera.)
    const float FB = 2.4;
    float rdy = max(0.62 - uv.y, 0.04);
    float dist = 0.4167 * exp(-0.35 * FB) * (1.0 - exp(-2.2 * rdy * FB)) / rdy;

    vec2 fp = vec2(uv.x * aspect, uv.y * 1.7);
    float bank = vnoise(fp * 1.30 + vec2(0.050, 0.000) * t) * 0.40 +
                 vnoise(fp * 2.60 + vec2(0.100, -0.062) * t) * 0.35 +
                 vnoise(fp * 5.20 + vec2(-0.021, 0.075) * t) * 0.25;
    // A tight window straddling the mean drives large regions to genuinely ZERO
    // density. Real holes with edges are what make a bank read as a bank.
    bank = smoothstep(0.40, 0.58, bank);

    float density = fogAmt * (2.0 + 4.4 * fogAmt) * dist * (0.25 + 1.7 * bank);
    float fogTrans = exp(-density);

    vec3 air = mix(vec3(0.82, 0.85, 0.88), vec3(0.09, 0.11, 0.15), wNight);
    float fogP = clamp(hg(sunMu, 0.70) * 12.566, 0.0, 6.0);
    air = mix(air, sunCol, clamp(0.11 * fogP * sunVis, 0.0, 0.85));
    col = mix(air, col, fogTrans);
  }

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
