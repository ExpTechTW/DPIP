/// Pure choreography of the Home chrome as the sheet climbs from collapsed (0)
/// to full (1).
///
/// Every layer that dresses the Home backdrop reads these same thresholds so the
/// pieces move in step: the feature sheet reveals its weather, the shared region
/// bar blends then dismisses, and the app shell's bottom nav slides away. Kept in
/// core (and dependency-free) so `shared/` and `app/` can reach it without
/// importing the Home feature.
///
/// The sequence, by extent, is deliberately staged:
///  - the bottom nav clears out first ([navDismiss], as the sheet commits up),
///  - the weather appears and the region bar blends into it ([weatherReveal] /
///    [regionBlend]),
///  - the region bar finally slides away once the rising sheet invades it
///    ([regionDismiss]).
class HomeChrome {
  const HomeChrome._();

  /// Extent at which the weather backdrop starts to appear.
  static const double _weatherFrom = 0.85;

  /// Extent window over which the bottom nav slides down and fades out — it is
  /// the first chrome to clear, as the sheet commits upward.
  static const double _navFrom = 0.7;
  static const double _navTo = 0.9;

  /// Extent at which the rising sheet's top invades the region bar, so it slides
  /// up and fades out over the remaining travel to full.
  static const double _regionDismissFrom = 0.93;

  /// Weather backdrop reveal, `0` (hidden) → `1` (full).
  static double weatherReveal(double extent) => _ramp(extent, _weatherFrom, 1);

  /// Whether the weather backdrop should be playing (any of it revealed).
  static bool weatherActive(double extent) => extent > _weatherFrom;

  /// Bottom-nav dismissal, `0` (shown) → `1` (slid away) — the first to clear.
  static double navDismiss(double extent) => _ramp(extent, _navFrom, _navTo);

  /// Region-bar blend into the backdrop, `0` (opaque surface) → `1` (transparent
  /// with light badges) — tracks the weather reveal so the bar dissolves in step
  /// with the weather appearing behind it.
  static double regionBlend(double extent) => weatherReveal(extent);

  /// Region-bar dismissal, `0` (shown) → `1` (slid up and gone) — the last
  /// chrome to clear, once the rising sheet invades it.
  static double regionDismiss(double extent) =>
      _ramp(extent, _regionDismissFrom, 1);

  static double _ramp(double x, double from, double to) =>
      ((x - from) / (to - from)).clamp(0.0, 1.0);
}
