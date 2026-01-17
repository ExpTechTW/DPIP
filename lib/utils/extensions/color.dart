import 'dart:ui';

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
}
