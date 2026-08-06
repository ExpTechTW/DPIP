/// Near-term 1-hour rainfall trend (per-minute mm), for the home sheet card.
///
/// Wire shape (API not shipped yet): a minute-aligned Unix-second
/// [startSecond] and sixty [mm] samples — one millimetre total for each of the
/// following sixty minutes. UI can render without a live feed via [placeholder].
library;

/// Sixty minute-buckets of forecast rainfall starting at [startSecond].
class RainHourTrend {
  const RainHourTrend({required this.startSecond, required this.mm})
    : assert(mm.length == 60, 'expected 60 one-minute samples');

  /// Prediction origin, Unix **seconds**, aligned to a whole minute
  /// (`startSecond % 60 == 0`).
  final int startSecond;

  /// Rainfall for each of the next 60 minutes, mm (index 0 = first minute after
  /// [startSecond]).
  final List<double> mm;

  /// Wall-clock UTC instant of [startSecond].
  DateTime get startUtc =>
      DateTime.fromMillisecondsSinceEpoch(startSecond * 1000, isUtc: true);

  /// Synthetic series for UI work until the API lands — a soft pulse peaking
  /// mid-hour so the bar chart has shape.
  static RainHourTrend placeholder({int? startSecond}) {
    final raw =
        startSecond ?? (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000);
    final aligned = raw - (raw % 60);
    return RainHourTrend(
      startSecond: aligned,
      mm: [
        for (var i = 0; i < 60; i++)
          // Gentle hump around minute 20–35, quiet elsewhere.
          (i >= 18 && i <= 38)
              ? (1.2 * (1 - ((i - 28).abs() / 12))).clamp(0.0, 1.2)
              : (i % 7 == 0 ? 0.08 : 0.0),
      ],
    );
  }
}
