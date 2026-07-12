/// The app's animation durations.
///
/// Use these tokens for UI motion instead of bare `Duration(...)` so timing
/// feels consistent across the app. (Continuous/background animations such as
/// the weather shader set their own periods.)
abstract final class AppMotion {
  /// 150ms — quick feedback: taps, small fades, icon swaps.
  static const Duration fast = Duration(milliseconds: 150);

  /// 220ms — standard transitions: sheet snapping, reveals.
  static const Duration medium = Duration(milliseconds: 220);

  /// 400ms — larger transitions: full-screen or theme changes.
  static const Duration slow = Duration(milliseconds: 400);
}
