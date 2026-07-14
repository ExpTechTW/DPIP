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
