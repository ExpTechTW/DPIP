/// Camera math for framing a bounding box in a map viewport.
library;

import 'dart:math' as math;

/// A resolved snapshot camera: centre + zoom.
typedef MapCamera = ({double latitude, double longitude, double zoom});

/// The camera (centre + zoom) that frames [bounds]
/// (`[minLng, minLat, maxLng, maxLat]`) inside a [width]×[height] viewport
/// (logical px), leaving a [padding] fraction of margin and never exceeding
/// [maxZoom].
///
/// Standard Web-Mercator fit-bounds: the smaller of the latitude- and
/// longitude-limited zooms, so the whole box fits. Used to focus the home
/// backdrop snapshot on the selected township.
MapCamera fitBoundsCamera(
  List<double> bounds, {
  required double width,
  required double height,
  double padding = 0.18,
  double maxZoom = 11,
}) {
  final minLng = bounds[0];
  final minLat = bounds[1];
  final maxLng = bounds[2];
  final maxLat = bounds[3];

  final latFraction = (_latRad(maxLat) - _latRad(minLat)) / math.pi;
  var lngDiff = maxLng - minLng;
  if (lngDiff < 0) lngDiff += 360;
  final lngFraction = lngDiff / 360;

  // Shrink the usable viewport by the padding so the box isn't edge-to-edge.
  final usableWidth = width * (1 - 2 * padding);
  final usableHeight = height * (1 - 2 * padding);

  final latZoom = _zoomFor(usableHeight, latFraction);
  final lngZoom = _zoomFor(usableWidth, lngFraction);
  final zoom = math.min(math.min(latZoom, lngZoom), maxZoom);

  return (
    latitude: (minLat + maxLat) / 2,
    longitude: (minLng + maxLng) / 2,
    zoom: zoom.isFinite ? zoom : maxZoom,
  );
}

double _latRad(double latDegrees) {
  final sin = math.sin(latDegrees * math.pi / 180);
  final radius = math.log((1 + sin) / (1 - sin)) / 2;
  return math.max(math.min(radius, math.pi), -math.pi) / 2;
}

double _zoomFor(double viewportPx, double fraction) {
  const tileSize = 256.0;
  if (fraction <= 0) return double.infinity;
  return math.log(viewportPx / tileSize / fraction) / math.ln2;
}
