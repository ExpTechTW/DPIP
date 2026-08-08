/// Colour ramps for an earthquake report's magnitude and hypocentral depth —
/// small indicator dots next to the numeric value on the report detail page.
/// Ported verbatim (same hex values) from the legacy palette.
library;

import 'package:flutter/material.dart';

/// Continuous colour ramp for magnitude, interpolated between named stops.
abstract final class MagnitudeColors {
  static const List<(double magnitude, Color color)> _stops = [
    (2.5, Color(0xFF00C8C8)),
    (3.5, Color(0xFF00C800)),
    (4.5, Color(0xFFFFC800)),
    (6.0, Color(0xFFFF0000)),
    (7.0, Color(0xFF9600FF)),
  ];

  /// The colour for [magnitude], linearly interpolated between stops and
  /// clamped to the end colours outside the ramp's range.
  static Color of(double magnitude) {
    if (magnitude <= _stops.first.$1) return _stops.first.$2;
    if (magnitude >= _stops.last.$1) return _stops.last.$2;
    for (var i = 0; i < _stops.length - 1; i++) {
      final (lo, loColor) = _stops[i];
      final (hi, hiColor) = _stops[i + 1];
      if (magnitude >= lo && magnitude < hi) {
        return Color.lerp(loColor, hiColor, (magnitude - lo) / (hi - lo))!;
      }
    }
    return _stops.first.$2;
  }
}

/// Continuous colour ramp for hypocentral depth (km), interpolated between
/// named stops — shallow (red) to deep (blue).
abstract final class DepthColors {
  static const List<(double depthKm, Color color)> _stops = [
    (5, Color(0xFFFF0000)),
    (15, Color(0xFFFF6400)),
    (30, Color(0xFFFFC800)),
    (50, Color(0xFF00C800)),
    (100, Color(0xFF00C8C8)),
    (150, Color(0xFF0000C8)),
  ];

  /// The colour for [depthKm], linearly interpolated between stops and
  /// clamped to the end colours outside the ramp's range.
  static Color of(double depthKm) {
    if (depthKm <= _stops.first.$1) return _stops.first.$2;
    if (depthKm >= _stops.last.$1) return _stops.last.$2;
    for (var i = 0; i < _stops.length - 1; i++) {
      final (lo, loColor) = _stops[i];
      final (hi, hiColor) = _stops[i + 1];
      if (depthKm >= lo && depthKm < hi) {
        return Color.lerp(loColor, hiColor, (depthKm - lo) / (hi - lo))!;
      }
    }
    return _stops.first.$2;
  }
}
