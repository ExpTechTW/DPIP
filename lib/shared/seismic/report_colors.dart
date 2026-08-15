/// Colour ramps for an earthquake report's magnitude and hypocentral depth —
/// small indicator dots next to the numeric value on the report detail page.
/// Ported verbatim (same hex values) from the legacy palette.
///
/// The literals are the *standard-vision* palette; each is routed through
/// `.vision` at its definition, so both ramps are recoloured with the rest of
/// the app when a colour-vision correction is on. These dots are drawn by
/// Flutter, not by a server-rendered tile, so there is nothing here to exempt.
/// A stop is corrected *before* the interpolation, the same way the map's
/// `interpolate` expression blends between already-corrected stops — so a
/// value's dot and its twin on the map cannot disagree. Because the transform
/// is not a compile-time constant, the tables are getters rather than
/// `static const`.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:flutter/material.dart';

/// Continuous colour ramp for magnitude, interpolated between named stops.
abstract final class MagnitudeColors {
  static List<(double magnitude, Color color)> get _stops => [
    (2.5, const Color(0xFF00C8C8).vision),
    (3.5, const Color(0xFF00C800).vision),
    (4.5, const Color(0xFFFFC800).vision),
    (6.0, const Color(0xFFFF0000).vision),
    (7.0, const Color(0xFF9600FF).vision),
  ];

  /// The colour for [magnitude], linearly interpolated between stops and
  /// clamped to the end colours outside the ramp's range.
  static Color of(double magnitude) {
    final stops = _stops;
    if (magnitude <= stops.first.$1) return stops.first.$2;
    if (magnitude >= stops.last.$1) return stops.last.$2;
    for (var i = 0; i < stops.length - 1; i++) {
      final (lo, loColor) = stops[i];
      final (hi, hiColor) = stops[i + 1];
      if (magnitude >= lo && magnitude < hi) {
        return Color.lerp(loColor, hiColor, (magnitude - lo) / (hi - lo))!;
      }
    }
    return stops.first.$2;
  }
}

/// Continuous colour ramp for hypocentral depth (km), interpolated between
/// named stops — shallow (red) to deep (blue).
abstract final class DepthColors {
  static List<(double depthKm, Color color)> get _stops => [
    (5, const Color(0xFFFF0000).vision),
    (15, const Color(0xFFFF6400).vision),
    (30, const Color(0xFFFFC800).vision),
    (50, const Color(0xFF00C800).vision),
    (100, const Color(0xFF00C8C8).vision),
    (150, const Color(0xFF0000C8).vision),
  ];

  /// The colour for [depthKm], linearly interpolated between stops and
  /// clamped to the end colours outside the ramp's range.
  static Color of(double depthKm) {
    final stops = _stops;
    if (depthKm <= stops.first.$1) return stops.first.$2;
    if (depthKm >= stops.last.$1) return stops.last.$2;
    for (var i = 0; i < stops.length - 1; i++) {
      final (lo, loColor) = stops[i];
      final (hi, hiColor) = stops[i + 1];
      if (depthKm >= lo && depthKm < hi) {
        return Color.lerp(loColor, hiColor, (depthKm - lo) / (hi - lo))!;
      }
    }
    return stops.first.$2;
  }
}
