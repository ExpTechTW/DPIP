/// How often an earthquake's drawn wavefront is refreshed.
///
/// [wavefrontTick] is how often the ticker wakes, by device class. A wake is
/// not itself an upload: the ring is real polygon geometry, so a step smaller
/// than one screen pixel is held, and the next upload draws the radius at
/// that instant, never the one that was skipped.
library;

import 'dart:math' as math;

import 'package:dpip/core/platform/render_tier.dart';

/// The redraw interval for the P/S wave-front rings on a [tier] device.
///
/// The rings are real polygon geometry, not a paint property MapLibre can
/// tween, so this interval *is* the animation's frame rate — and every frame
/// is a GeoJSON serialisation, a platform-channel hop and a re-tessellation on
/// the map's own thread.
///
/// - [RenderTier.high]: 16 ms, about display rate, for an expansion that reads
///   as continuous motion.
/// - [RenderTier.low]: 200 ms (5 Hz). On a 2–4 GB phone sixty ring uploads a
///   second compete with the map's rendering and the alert UI for the same
///   few cores, during the minute it matters most that both stay responsive.
///   The cost is smoothness, not accuracy: each redraw is computed from the
///   calibrated clock when it is sent, so a ring is never more than 200 ms
///   behind the model — the S wave moves about 0.7 km and the P wave about
///   1.2 km in that time, roughly a pixel at island zoom and well inside the
///   travel-time model's own uncertainty. Zoomed in to a city, the expansion
///   visibly steps rather than glides.
Duration wavefrontTick(RenderTier tier) => switch (tier) {
  RenderTier.high => const Duration(milliseconds: 16),
  RenderTier.low => const Duration(milliseconds: 200),
};

/// Web Mercator metres per pixel along the equator at zoom 0.
///
/// MapLibre's zoom is defined on 512 px tiles, so the world is `512 · 2^z`
/// logical pixels wide. The familiar 156543 m is the 256 px figure; using it
/// would make every "one pixel" here two.
const double kMercatorMetresPerPixelZoom0 = 78271.51696;

/// How often a detection box is tested against the S-wave disc.
///
/// The disc itself follows [wavefrontUploadDue]. A box is tens of kilometres
/// across and the S wave takes seconds to cross it, so a fifth of a second
/// late on the moment it winks out is the same picture. On a low-end phone
/// the ticker already wakes this slowly ([wavefrontTick]); this keeps a
/// capable phone from testing the grid at display rate.
const Duration kBoxCoverageInterval = Duration(milliseconds: 200);

/// One alert's P and S radii, in metres, at a single instant.
class WavefrontRing {
  const WavefrontRing({
    required this.id,
    required this.pMetres,
    required this.sMetres,
    required this.latitude,
  });

  /// Alert identity. A new id is a different quake and always uploads.
  final String id;

  final double pMetres;
  final double sMetres;

  /// Degrees. The pixel size of a metre depends on latitude.
  final double latitude;
}

/// Metres on the ground covered by one screen pixel at [zoom].
double metresPerPixel({required double latitude, required double zoom}) {
  final scale = math.pow(2, zoom).toDouble();
  if (scale == 0 || zoom.isNaN) return double.infinity;
  final metres =
      kMercatorMetresPerPixelZoom0 *
      math.cos(latitude * math.pi / 180).abs() /
      scale;
  return metres <= 0 ? double.infinity : metres;
}

/// Whether [nextMetres] is at least one pixel away from the radius on the map.
bool wavefrontMoved({
  required double previousMetres,
  required double nextMetres,
  required double latitude,
  required double zoom,
}) {
  final pixel = metresPerPixel(latitude: latitude, zoom: zoom);
  return (nextMetres - previousMetres).abs() + 1e-6 >= pixel;
}

/// Whether [next] should replace what [onMap] is showing.
///
/// A missing camera uploads: without a zoom the pixel test cannot promise the
/// ring is within a pixel, and a skipped upload would be the wrong trade.
/// When this returns true the caller draws [next], not the radii in [onMap].
bool wavefrontUploadDue({
  required List<WavefrontRing> next,
  required Map<String, WavefrontRing> onMap,
  required double? zoom,
}) {
  if (zoom == null || zoom.isNaN || zoom.isInfinite) return true;
  if (next.length != onMap.length) return true;
  for (final ring in next) {
    final previous = onMap[ring.id];
    if (previous == null) return true;
    if (wavefrontMoved(
      previousMetres: previous.pMetres,
      nextMetres: ring.pMetres,
      latitude: ring.latitude,
      zoom: zoom,
    )) {
      return true;
    }
    if (wavefrontMoved(
      previousMetres: previous.sMetres,
      nextMetres: ring.sMetres,
      latitude: ring.latitude,
      zoom: zoom,
    )) {
      return true;
    }
  }
  return false;
}

/// Whether the S-wave coverage test should run again.
///
/// [last] null is the first look and always runs. Feed-driven updates do not
/// consult this — a new intensity still draws immediately.
bool boxCoverageDue(DateTime? last, DateTime now) =>
    last == null || now.difference(last) >= kBoxCoverageInterval;
