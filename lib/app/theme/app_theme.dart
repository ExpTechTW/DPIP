import 'package:flutter/material.dart';

/// Centralized Material 3 theming for light and dark modes.
abstract final class AppTheme {
  /// Seed color from which the app's color scheme is derived.
  static const Color _seed = Color(0xFF00696D);

  /// Light theme.
  static ThemeData get light => _base(Brightness.light);

  /// Dark theme.
  static ThemeData get dark => _base(Brightness.dark);

  /// The color scheme for a [brightness] — exposed so a theme picker can paint a
  /// true-to-theme preview without instantiating a whole [ThemeData].
  static ColorScheme scheme(Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);

  static ThemeData _base(Brightness brightness) {
    return ThemeData(useMaterial3: true, colorScheme: scheme(brightness));
  }
}
