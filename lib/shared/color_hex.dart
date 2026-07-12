import 'package:flutter/material.dart';

/// Hex conversion for feeding theme colours into MapLibre style JSON.
extension ColorHex on Color {
  /// Opaque `#RRGGBB` hex string (drops alpha).
  String toHexRgb() =>
      '#${(toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}
