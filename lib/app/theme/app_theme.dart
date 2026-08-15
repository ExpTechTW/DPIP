import 'package:dpip/core/settings/display_settings.dart';
import 'package:flutter/material.dart';

/// Centralized Material 3 theming for light and dark modes.
abstract final class AppTheme {
  /// Seed color from which the app's color scheme is derived.
  static const Color _seed = Color(0xFF00696D);

  /// Light theme.
  static ThemeData get light => _base(Brightness.light);

  /// Dark theme.
  static ThemeData get dark => _base(Brightness.dark);

  /// The theme for [brightness] under the user's display settings.
  ///
  /// Text *size* is not here: it travels as a `TextScaler` on `MediaQuery`,
  /// because this theme declares no `textTheme` and `textTheme.apply(
  /// fontSizeFactor:)` asserts on Material's colour-only default.
  static ThemeData of(
    Brightness brightness, {
    TextWeightStep weight = TextWeightStep.normal,
    ContrastStep contrast = ContrastStep.standard,
  }) {
    final data = ThemeData(
      useMaterial3: true,
      colorScheme: scheme(brightness, contrast: contrast),
    );
    if (weight == TextWeightStep.normal) return data;
    return data.copyWith(textTheme: applyTextWeight(data.textTheme, weight));
  }

  /// The color scheme for a [brightness] — exposed so a theme picker can paint a
  /// true-to-theme preview without instantiating a whole [ThemeData].
  static ColorScheme scheme(
    Brightness brightness, {
    ContrastStep contrast = ContrastStep.standard,
  }) => ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
    contrastLevel: contrast.level,
  );

  static ThemeData _base(Brightness brightness) {
    return ThemeData(useMaterial3: true, colorScheme: scheme(brightness));
  }
}
