/// Crash-safe normalisation for MapLibre bounds fits.
///
/// On iOS, `newLatLngBounds` runs `cameraThatFitsCoordinateBounds`, and if that
/// yields a **non-finite** camera the follow-up `setCamera` throws an uncaught
/// C++ exception in MapLibre native — which aborts the whole process (SIGABRT),
/// not a catchable Dart error. A non-finite camera arises from a degenerate box:
/// a zero / near-zero span (a point-sized or corrupt decoded township makes the
/// fit zoom diverge) or a non-finite corner. [safeFitBounds] rules those out
/// before the box ever reaches the platform.
library;

import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:maplibre_gl/maplibre_gl.dart';

/// ~0.02° ≈ 2 km — the minimum span a fit box is widened to. Enough that the fit
/// zoom stays finite (and within the map's zoom range) instead of diverging for
/// a point-sized box; small enough not to distort a genuinely tiny township
/// (they're already widened further by the caller's framing expansion).
const double _minSpan = 0.02;

/// [bounds] normalised so a `newLatLngBounds` fit can never produce a non-finite
/// camera: corners ordered low→high, and any span under [_minSpan] widened
/// symmetrically about its midpoint. Returns `null` when a corner is non-finite
/// (there is nothing sane to fit) — callers should then skip the camera move.
LatLngBounds? safeFitBounds(LatLngBounds bounds) {
  final sw = bounds.southwest;
  final ne = bounds.northeast;
  final corners = [sw.latitude, sw.longitude, ne.latitude, ne.longitude];
  if (corners.any((v) => !v.isFinite)) return null;

  final (minLat, maxLat) = _widened(sw.latitude, ne.latitude);
  final (minLng, maxLng) = _widened(sw.longitude, ne.longitude);
  return LatLngBounds(
    southwest: LatLng(minLat, minLng),
    northeast: LatLng(maxLat, maxLng),
  );
}

/// Orders [a] and [b] low→high, widening the pair to [_minSpan] about their
/// midpoint when their gap is smaller.
(double, double) _widened(double a, double b) {
  final lo = math.min(a, b);
  final hi = math.max(a, b);
  if (hi - lo >= _minSpan) return (lo, hi);
  final mid = (lo + hi) / 2;
  return (mid - _minSpan / 2, mid + _minSpan / 2);
}

/// A camera (centre + zoom) that fits [bounds] into [viewport] (logical px),
/// leaving [padding] px of margin and a [bottomInset] px band at the bottom
/// unused (e.g. under a sheet) — the box is centred in the band above it.
///
/// Computed in Dart with Web-Mercator math **instead of** MapLibre's native
/// `cameraThatFitsCoordinateBounds` (behind `newLatLngBounds`), which throws an
/// uncaught C++ exception that aborts the whole app when the viewport is zero,
/// the padding/inset exceeds it, or the map hasn't laid out yet. Feed the result
/// to `CameraUpdate.newLatLngZoom`, which builds a finite camera directly and so
/// can never abort. Returns null when the viewport leaves no room to fit into
/// (the caller then skips the move). Zoom is a fit computed from the bounds — not
/// a hardcoded constant — clamped to [minZoom]..[maxZoom].
({LatLng target, double zoom})? boundsFitCamera(
  LatLngBounds bounds, {
  required Size viewport,
  double bottomInset = 0,
  double padding = 24,
  double minZoom = 2,
  double maxZoom = 16,
}) {
  final availWidth = viewport.width - padding * 2;
  final availHeight = viewport.height - bottomInset - padding * 2;
  if (availWidth <= 0 || availHeight <= 0) return null;

  final x1 = _mercatorX(bounds.southwest.longitude);
  final x2 = _mercatorX(bounds.northeast.longitude);
  final yNorth = _mercatorY(bounds.northeast.latitude); // north → smaller y
  final ySouth = _mercatorY(bounds.southwest.latitude);
  final spanX = (x2 - x1).abs();
  final spanY = (ySouth - yNorth).abs();
  if (spanX <= 0 || spanY <= 0 || !spanX.isFinite || !spanY.isFinite) {
    return null;
  }

  // The largest zoom whose world (256·2^z px) still fits the box in the area.
  final zoom = math
      .min(
        _log2(availWidth / (256 * spanX)),
        _log2(availHeight / (256 * spanY)),
      )
      .clamp(minZoom, maxZoom)
      .toDouble();
  if (!zoom.isFinite) return null;

  final worldPx = 256 * math.pow(2, zoom).toDouble();
  final centreX = (x1 + x2) / 2;
  // Shift the camera centre south by half the bottom inset so the box sits in
  // the visible band above the sheet rather than at the screen centre.
  final centreY = (yNorth + ySouth) / 2 + (bottomInset / 2) / worldPx;
  return (
    target: LatLng(_mercatorLat(centreY), _mercatorLng(centreX)),
    zoom: zoom,
  );
}

double _mercatorX(double lng) => (lng + 180) / 360;

double _mercatorY(double lat) {
  final s = math.sin(lat * math.pi / 180).clamp(-0.9999, 0.9999);
  return 0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi);
}

double _mercatorLng(double x) => x * 360 - 180;

double _mercatorLat(double y) {
  final n = math.pi * (1 - 2 * y);
  return math.atan((math.exp(n) - math.exp(-n)) / 2) * 180 / math.pi;
}

double _log2(double x) => math.log(x) / math.ln2;
