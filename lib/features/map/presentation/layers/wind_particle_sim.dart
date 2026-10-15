/// The wind particles' math, as the GPU does it.
///
/// The particles are drawn natively — `WindParticleLayer.java` and
/// `WindParticleLayer.swift` in the MapLibre fork. Nothing in this file runs in
/// production. It is the one place every number and every sign those two
/// shaders must agree on is written in a language with a test runner, so the
/// tests can hold them still: the tuning tables, the speed curve, the velocity
/// byte encoding, which way is up, and where the trail texture lands while the
/// camera moves.
///
/// Each function names the native code it mirrors. A change to one without the
/// other is the bug these exist to catch, so change them together.
library;

import 'dart:math' as math;
import 'dart:ui';

// --------------------------------------------------------------- the tuning
//
// How the field looks, as numbers. Native carries the same values as
// constants; change them together.

/// Particle-state texture edge: a pool of 65,536, of which zoom draws a part.
const int kWindStateEdge = 256;

/// Sixteen blocks, one reborn every eight 60 Hz frames: every particle lives
/// 128 frames (2.13 s), and its age is always known.
const int kWindBlocks = 16;
const int kWindBlockFrames = 8;
const int kWindLifetime = kWindBlocks * kWindBlockFrames;

/// Stroke width, indexed by tile zoom ([tileZoom]).
const List<double> kWindLineWidth = [
  .6, .6, .6, 1, 1.2, 1.6, 1.8, 2, 2.2, 2.4, 2.4, 2.4, //
  2.4, 2.6, 2.8, 3, 3, 3, 3, 3, 3, 3, 3, 3,
];

/// Speed factor, indexed by tile zoom: particles slow down zoomed out.
const List<double> kWindZoomToSpeed = [
  .5, .5, .5, .6, .7, .8, .9, 1, 1, 1, 1, 1, 1, //
  1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
];

/// Stroke width multiplier, before the device pixel ratio.
const double kWindParticleWidth = 1.3;

/// Physical pixels per second at full curve strength.
const double kWindSpeedPx = 100;

/// The speed curve: full strength at [kWindMaxSpeed] m/s, never below
/// [kWindMinSpeed] m/s's share, and `(speed / max)^pow` between.
const double kWindMaxSpeed = 30;
const double kWindMinSpeed = 1.5;
const double kWindCurvePow = 0.7;

/// The particle count is halved for a phone screen.
const double kWindCountMul = 0.5;

/// Trail decay per 60 Hz frame.
const double kWindFade = 0.97;

/// The trails reach the map at 0.44, with 0.1 subtracted.
///
/// The subtraction is not a matter of taste. An 8-bit trail multiplied by
/// 0.97 stops getting darker once `round(v · 0.97) == v`, which is every value
/// below 17/255; without the lift that floor is a permanent grey haze.
const double kWindCompositeGain = 0.44;
const double kWindCompositeLift = -0.1;

/// The layer fades in at this rate per second when playback starts.
const double kWindAlphaRate = 1.8;

/// How long the camera must hold still before its new view is adopted.
const Duration kWindSettle = Duration(milliseconds: 100);

/// The zoom the tables are indexed by: the 256 px tile zoom, one above
/// MapLibre's 512 px one — kept fractional.
///
/// Rounding it to the nearest entry makes the field jump by 1.6× each time
/// the zoom crosses a half: the framed-Taiwan view at 4.67 drew the density
/// meant for a whole zoom closer. Continuous, the count and both tables hit
/// their entries exactly at whole zooms and move smoothly between them.
double tileZoom(double zoom) => zoom + 1;

/// [table] at a fractional [index], linear between entries, clamped at the
/// ends.
double _at(List<double> table, double index) {
  final i = index.clamp(0.0, table.length - 1.0);
  final lo = i.floor();
  final hi = math.min(table.length - 1, lo + 1);
  return table[lo] + (table[hi] - table[lo]) * (i - lo);
}

/// How many particles each of the sixteen blocks draws for a viewport of
/// [width] × [height] logical points.
///
/// `min(15000, w·h / (50 · 1.6^(z−2)))`, halved on a phone, as a
/// share of the pool. Proportional to area, so a tablet gets more particles
/// than a phone at the same zoom and both look equally dense.
int windParticlesPerBlock(double width, double height, double zoom) {
  final z = tileZoom(zoom);
  final amount = math.min(
    15000,
    (width * height / (50 * math.pow(1.6, z - 2))).roundToDouble(),
  );
  final relative = amount * kWindCountMul / (kWindStateEdge * kWindStateEdge);
  const perBlock = kWindStateEdge * kWindStateEdge ~/ kWindBlocks;
  return (relative * perBlock).round().clamp(1, perBlock);
}

/// The stroke's full width in physical pixels: `max(1, lineWidth · 1.3 ·
/// DPR)`, plus the one feathered pixel the quad grows by.
double windStrokeWidth(double zoom, double pixelRatio) =>
    math.max(
      1.0,
      _at(kWindLineWidth, tileZoom(zoom)) * kWindParticleWidth * pixelRatio,
    ) +
    1;

/// Physical pixels a particle moves per second at full curve strength.
double windFullSpeed(double zoom, double pixelRatio) =>
    kWindSpeedPx * _at(kWindZoomToSpeed, tileZoom(zoom)) * pixelRatio;

/// The fraction of [windFullSpeed] a wind of [speed] m/s moves at.
///
/// `(speed / 30)^0.7`, floored at 1.5 m/s's share so a breeze still visibly
/// moves. Capped at 1: a byte-encoded velocity has no headroom past 30 m/s,
/// and uncapped, a typhoon core would overflow and skew the direction.
double windSpeedCurve(double speed) {
  final o = speed / kWindMaxSpeed;
  if (o * o < 1e-8) return 0;
  return math
      .max(
        math.pow(o * o, kWindCurvePow / 2).toDouble(),
        kWindMinSpeed / kWindMaxSpeed,
      )
      .clamp(0.0, 1.0);
}

/// The alpha a particle is drawn with at each frame of its life: in over the
/// first 20 % (power 0.9), out over the last 30 % (power 0.8).
List<double> windAlphaLut() {
  final fadeInEnd = (0.2 * kWindLifetime).round();
  final fadeOutFrom = kWindLifetime - (0.3 * kWindLifetime).round();
  return [
    for (var i = 0; i < kWindLifetime; i++)
      if (i < fadeInEnd)
        math.pow(i / fadeInEnd, 0.9).toDouble()
      else if (i >= fadeOutFrom)
        math
            .pow((kWindLifetime - i) / (kWindLifetime - fadeOutFrom), 0.8)
            .toDouble()
      else
        1.0,
  ];
}

// ------------------------------------------------------------------ camera

/// A tilt-free, bearing-rotated Web Mercator camera over a viewport of
/// [width] × [height] logical points — what MapLibre hands a custom layer.
class WindCamera {
  const WindCamera({
    required this.centerLat,
    required this.centerLng,
    required this.zoom,
    required this.bearing,
    this.width = 0,
    this.height = 0,
  });

  final double centerLat;
  final double centerLng;
  final double zoom;

  /// Camera heading, degrees clockwise from north. 90 puts east at the top.
  final double bearing;

  final double width;
  final double height;

  double get _world => 512 * math.pow(2.0, zoom).toDouble();
  double get _cx => (centerLng + 180) / 360 * _world;
  double get _cy => mercatorY(centerLat) * _world;

  /// cos and sin of **minus** the bearing, which is how MapLibre rotates.
  double get _cos => math.cos(-bearing * math.pi / 180);
  double get _sin => math.sin(-bearing * math.pi / 180);

  /// Same scale, rotation and size: the two views differ by a pan only.
  bool sameFrame(WindCamera o) =>
      (zoom - o.zoom).abs() < 1e-6 &&
      (bearing - o.bearing).abs() < 1e-6 &&
      width == o.width &&
      height == o.height;

  @override
  bool operator ==(Object other) =>
      other is WindCamera &&
      other.centerLat == centerLat &&
      other.centerLng == centerLng &&
      other.zoom == zoom &&
      other.bearing == bearing &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode =>
      Object.hash(centerLat, centerLng, zoom, bearing, width, height);
}

/// Web Mercator northing in `[0, 1]`, 0 at the north edge.
double mercatorY(double lat) {
  final phi = lat.clamp(-85.051129, 85.051129) * math.pi / 180;
  return (1 - math.log(math.tan(math.pi / 4 + phi / 2)) / math.pi) / 2;
}

/// Inverse of [mercatorY].
double mercatorLat(double y) =>
    (2 * math.atan(math.exp(math.pi * (1 - 2 * y))) - math.pi / 2) *
    180 /
    math.pi;

/// Where a geographic point sits on screen, in logical points from the
/// top-left — MapLibre's own projection, written independently of the
/// functions below so they can be checked against it.
Offset projectLatLng(WindCamera cam, double lat, double lng) {
  final world = cam._world;
  var dx = (lng + 180) / 360 * world - cam._cx;
  dx -= world * (dx / world + 0.5).floorToDouble();
  final dy = mercatorY(lat) * world - cam._cy;
  return Offset(
    cam.width / 2 + dx * cam._cos - dy * cam._sin,
    cam.height / 2 + dx * cam._sin + dy * cam._cos,
  );
}

/// The lat/lng under a point of the viewport in *particle space* — 0..1 across
/// it, y up. `FRAG_PROJECT` / `projectFragment`: unrotate, then unproject.
({double lat, double lng}) particleToLatLng(WindCamera cam, Offset p) {
  final dx = (p.dx * 2 - 1) * cam.width / 2;
  final dy = (1 - p.dy * 2) * cam.height / 2;
  final wx = cam._cx + dx * cam._cos + dy * cam._sin;
  final wy = cam._cy - dx * cam._sin + dy * cam._cos;
  final lng = wx / cam._world * 360 - 180;
  return (lat: mercatorLat(wy / cam._world), lng: lng);
}

/// The wind (m/s, eastward [u], northward [v]) as the particle-space
/// displacement it becomes on screen: rotated into the view, y up.
Offset windToScreen(WindCamera cam, double u, double v) =>
    Offset(u * cam._cos + v * cam._sin, -u * cam._sin + v * cam._cos);

/// One velocity texel, as `FRAG_PROJECT` / `projectFragment` writes it:
/// `(128 + 127 · direction · curve) / 255` per axis, rounded to a byte.
///
/// Calm is exactly byte 128, which decodes to exactly zero. A `128 ± 128`
/// encoding cannot represent zero in eight bits, and drifts every particle
/// toward the top right by half a step.
(int, int) encodeWindTexel(WindCamera cam, double u, double v) {
  final s = windToScreen(cam, u, v);
  final speed = s.distance;
  final mag = windSpeedCurve(speed);
  if (mag == 0) return (128, 128);
  int byte(double c) => (128 + 127 * c / speed * mag).round().clamp(0, 255);
  return (byte(s.dx), byte(s.dy));
}

/// What `FRAG_UPDATE` / `updateFragment` turns a velocity texel into: the
/// fraction of full speed along each axis.
Offset decodeWindTexel(int r, int g) =>
    Offset((r - 128) / 127, (g - 128) / 127);

/// The texture coordinate the projection pass samples the grid at for a
/// point at [lat], [lng].
///
/// The half-texel term is what puts grid node `i` — the value at `lon0 + i ·
/// dLon` — at the centre of texel `i`, where a linear sample returns it
/// exactly. Without it the particles ride a field half a cell (0.125°) west
/// and north of the raster drawn from the same data.
Offset windFieldUv({
  required double lat,
  required double lng,
  required double lat0,
  required double lon0,
  required double dLat,
  required int width,
  required int height,
}) {
  final x = ((lng - lon0) / 360) % 1.0;
  final y = (lat - lat0) / (dLat * height);
  return Offset(x + 0.5 / width, y + 0.5 / height);
}

// --------------------------------------------------------------- the trails

/// Where a point of the reference viewport ([p] in particle space) is in
/// [cam]'s clip space — `refToClip` in both natives.
///
/// The trails and the particles live in the viewport as it was when the
/// camera last settled ([ref]). While the camera moves they are drawn as one
/// quad placed by this mapping, so a pan or a pinch carries the field with the
/// map at the cost of three points per frame. The world shift folds the
/// reference onto the copy of the world nearest the camera, or a pan across
/// the antimeridian would throw the field a world away.
Offset referenceToClip(WindCamera ref, WindCamera cam, Offset p) {
  final s = cam._world / ref._world;
  final wrap =
      cam._world * ((ref._cx * s - cam._cx) / cam._world).roundToDouble();
  final dx = (p.dx * 2 - 1) * ref.width / 2;
  final dy = (1 - p.dy * 2) * ref.height / 2;
  final ex = (ref._cx + dx * ref._cos + dy * ref._sin) * s - cam._cx - wrap;
  final ey = (ref._cy - dx * ref._sin + dy * ref._cos) * s - cam._cy;
  return Offset(
    (ex * cam._cos - ey * cam._sin) / (cam.width / 2),
    -(ex * cam._sin + ey * cam._cos) / (cam.height / 2),
  );
}

/// What the camera coming to rest does to the field.
sealed class WindSettle {
  const WindSettle();
}

/// The camera is where the field already is.
final class WindStay extends WindSettle {
  const WindStay();
}

/// A pan: the trails and the particles move by [shift] (particle space,
/// whole trail texels) into the new view, so nothing visibly jumps.
final class WindShift extends WindSettle {
  const WindShift(this.shift);

  final Offset shift;
}

/// A zoom, a rotation or a resize: the old trails no longer line up with
/// anything, so they are cleared and grow back.
final class WindClear extends WindSettle {
  const WindClear();
}

/// `settleCamera` in both natives, for a camera that has held still at [cam]
/// while the field's reference is [ref], over a trail texture of
/// [trailWidth] × [trailHeight].
WindSettle windSettle(
  WindCamera ref,
  WindCamera cam, {
  required int trailWidth,
  required int trailHeight,
}) {
  if (cam == ref) return const WindStay();
  if (!cam.sameFrame(ref)) return const WindClear();
  final o = referenceToClip(ref, cam, Offset.zero);
  return WindShift(
    Offset(
      ((o.dx + 1) * 0.5 * trailWidth).round() / trailWidth,
      ((o.dy + 1) * 0.5 * trailHeight).round() / trailHeight,
    ),
  );
}
