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
