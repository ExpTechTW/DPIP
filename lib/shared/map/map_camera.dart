/// Pure fit-to-bounds camera math for the map surfaces — no MapLibre dependency,
/// so it's unit-testable and golden-pinned.
///
/// MapLibre's own `newLatLngBounds` edge-padding is unreliable for a *lasting*
/// off-centre framing on iOS (`fly(to:edgePadding:)` applies the inset only for
/// the flight, then settles the camera on the bounds' geographic centre, so the
/// content springs back to the viewport centre). This computes the target
/// centre + zoom directly instead, and can bias the framing upward by
/// [bottomInset] logical pixels so the bounds sit centred in the band *above* an
/// overlay (e.g. the home sheet) rather than the full viewport.
library;

import 'dart:math' as math;

/// A camera target: geographic centre + zoom, matching MapLibre's units.
typedef MapCamera = ({double latitude, double longitude, double zoom});

/// Web-Mercator tile size the base map uses (its zoom is defined against this).
const int _tileSize = 256;

/// Bounding box framing the main island (plus Penghu), as
/// `[minLng, minLat, maxLng, maxLat]` — the whole-country / nationwide framing.
const List<double> taiwanBounds = <double>[119.35, 21.85, 122.05, 25.40];

/// Camera that fits [bounds] (`[minLng, minLat, maxLng, maxLat]`) into a
/// [width]×[height] logical-pixel viewport, inset by [padding] on every side.
///
/// [bottomInset] shrinks the vertical band the bounds are centred in from the
/// bottom (e.g. the height of the home sheet), then shifts the camera so the
/// bounds land centred in that band — the content sits above the overlay instead
/// of behind it. The zoom is clamped to [minZoom]–[maxZoom].
MapCamera fitBoundsCamera(
  List<double> bounds, {
  required double width,
  required double height,
  double padding = 24,
  double bottomInset = 0,
  double minZoom = 4,
  double maxZoom = 11,
}) {
  final minLng = bounds[0], minLat = bounds[1], maxLng = bounds[2];
  final maxLat = bounds[3];

  final visibleHeight = math.max(1.0, height - bottomInset);
  final fitWidth = math.max(1.0, width - 2 * padding);
  final fitHeight = math.max(1.0, visibleHeight - 2 * padding);

  final yNorth = _mercatorY(maxLat); // north edge → smaller normalised y
  final ySouth = _mercatorY(minLat); // south edge → larger normalised y
  final ySpan = (ySouth - yNorth).abs();
  final lngSpan = (maxLng - minLng).abs();

  // Zoom that fits each axis; the tighter (smaller) one fits both.
  final zoomLng = _zoomForSpan(lngSpan / 360, fitWidth, maxZoom);
  final zoomLat = _zoomForSpan(ySpan, fitHeight, maxZoom);
  final zoom = math.min(zoomLng, zoomLat).clamp(minZoom, maxZoom).toDouble();

  final worldSize = _tileSize * math.pow(2, zoom).toDouble();
  final centerLng = (minLng + maxLng) / 2;
  final centerY = (yNorth + ySouth) / 2;
  // Bias the framing up by half the inset: the bounds centre should land at the
  // centre of the visible band, which is `bottomInset / 2` px above the viewport
  // centre — so move the camera centre that far south (larger normalised y).
  final shiftedY = centerY + (bottomInset / 2) / worldSize;
  final centerLat = _mercatorLat(shiftedY);

  return (latitude: centerLat, longitude: centerLng, zoom: zoom);
}

/// Zoom at which a span covering [fraction] of the world fits [pixels] wide.
double _zoomForSpan(double fraction, double pixels, double maxZoom) {
  if (fraction <= 0) return maxZoom;
  return math.log(pixels / (_tileSize * fraction)) / math.ln2;
}

/// Normalised Web-Mercator Y for [lat] (0 at the north edge, 1 at the south).
double _mercatorY(double lat) {
  final r = lat * math.pi / 180;
  return 0.5 - math.log(math.tan(math.pi / 4 + r / 2)) / (2 * math.pi);
}

/// Inverse of [_mercatorY] — latitude (degrees) for a normalised Y.
double _mercatorLat(double y) {
  final merc = (0.5 - y) * 2 * math.pi;
  return (2 * math.atan(math.exp(merc)) - math.pi / 2) * 180 / math.pi;
}
