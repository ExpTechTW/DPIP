import 'package:flutter/material.dart';

/// Hex conversion for feeding theme colours into MapLibre style JSON.
extension ColorHex on Color {
  /// Opaque `#RRGGBB` hex string (drops alpha).
  String toHexRgb() =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

/// Parses an opaque `#RRGGBB` (or `RRGGBB`) hex string, or null if malformed.
///
/// The inverse of [ColorHex.toHexRgb]: a layer's value ramp is written as hex for
/// MapLibre, and the Flutter UI reads the same ramp back so a station's colour on
/// the map and in its sheet can never disagree.
Color? colorFromHexRgb(String hex) {
  final digits = hex.startsWith('#') ? hex.substring(1) : hex;
  if (digits.length != 6) return null;
  final value = int.tryParse(digits, radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

/// [value] read against a **banded** `(at, hexColour)` ramp — the Dart twin of
/// the `step` expression handed to MapLibre.
///
/// A value takes the colour of the last stop it is at or above; below the first
/// stop it takes the first stop's colour. Unlike [rampColor] no colour is ever
/// invented between two stops, which is the point: on a categorical scale (the
/// CWA rainfall bands) a blend would render a reading that no band defines.
Color? stepColor(List<(double, String)> stops, double value) {
  if (stops.isEmpty) return null;
  var chosen = stops.first.$2;
  for (final (at, hex) in stops) {
    if (value < at) break;
    chosen = hex;
  }
  return colorFromHexRgb(chosen);
}

/// [value] interpolated on a `(at, hexColour)` ramp — the Dart twin of the
/// `interpolate` expression handed to MapLibre, so a value-coloured dot on the
/// map and its reading in the sheet agree by construction rather than by two
/// hand-kept colour tables.
///
/// Values below the first stop clamp to it; above the last, to it.
Color? rampColor(List<(double, String)> stops, double value) {
  if (stops.isEmpty) return null;
  if (value <= stops.first.$1) return colorFromHexRgb(stops.first.$2);
  if (value >= stops.last.$1) return colorFromHexRgb(stops.last.$2);
  for (var i = 0; i < stops.length - 1; i++) {
    final (lowAt, lowHex) = stops[i];
    final (highAt, highHex) = stops[i + 1];
    if (value < lowAt || value > highAt) continue;
    final low = colorFromHexRgb(lowHex);
    final high = colorFromHexRgb(highHex);
    if (low == null || high == null) return low ?? high;
    final span = highAt - lowAt;
    return Color.lerp(low, high, span == 0 ? 0 : (value - lowAt) / span);
  }
  return colorFromHexRgb(stops.last.$2);
}
