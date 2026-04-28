import 'dart:ui';

import 'package:dpip/utils/extensions/number.dart';

/// Extension on [Color] that provides color manipulation utilities.
///
/// This extension adds helpful methods and getters for transforming and manipulating colors, including color inversion
/// and other common color operations.
extension ColorExtension on Color {
  /// Gets the inverted color of this color.
  ///
  /// Inverts the red, green, and blue channels by subtracting each component from 1.0, while preserving the original
  /// alpha (opacity) value. This creates a complementary color effect commonly used for contrast or visual effects.
  ///
  /// The formula for each channel is: `inverted = 1.0 - original`
  ///
  /// Example:
  /// ```dart
  /// final white = Color(0xFFFFFFFF);
  /// final black = white.inverted; // Color(0xFF000000)
  ///
  /// final red = Color(0xFFFF0000);
  /// final cyan = red.inverted; // Color(0xFF00FFFF)
  /// ```
  Color get inverted => Color.from(
    alpha: a,
    red: 1 - r,
    green: 1 - g,
    blue: 1 - b,
  );

  /// Returns a copy of this color with the given opacity applied.
  ///
  /// [value] can be a fraction in `[0, 1]` or a percentage in `(1, 100]` — both
  /// map to the same `[0, 1]` alpha range. Values outside `[0, 100]` are clamped.
  ///
  /// Example:
  /// ```dart
  /// color / 0.5   // 50% opacity (fraction form)
  /// color / 50    // 50% opacity (percentage form)
  /// ```
  ///
  /// You can also divide it by zero, which may not sound great in common math,
  /// but it will just simply make the color transparent. *(Go take a screenshot
  /// and confuse your best friends!)*
  ///
  /// ```dart
  /// color / 0     // fully transparent
  /// color / 0.0   // or a double if you are psychopath
  /// ```
  Color operator /(num value) {
    final alpha = switch (value) {
      > 1 => value / 100,
      _ => value,
    }.clamp(0, 1).asDouble;

    return withValues(alpha: alpha);
  }
}
