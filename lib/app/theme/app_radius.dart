import 'package:flutter/widgets.dart';

/// The app's corner-radius scale, with ready-made [BorderRadius] values.
///
/// Use these instead of bare `Radius.circular(n)` so rounding stays consistent.
abstract final class AppRadius {
  /// 8 — chips, small controls.
  static const double sm = 8;

  /// 16 — cards.
  static const double md = 16;

  /// 20 — sheets and large surfaces.
  static const double lg = 20;

  /// All-corner [BorderRadius] at [sm].
  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));

  /// All-corner [BorderRadius] at [md].
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));

  /// All-corner [BorderRadius] at [lg].
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));

  /// Top-only [BorderRadius] at [lg] — for bottom sheets.
  static const BorderRadius topSheet = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
}
