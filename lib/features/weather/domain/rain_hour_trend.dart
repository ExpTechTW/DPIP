/// Near-term 1-hour rainfall trend (per-minute mm), for the home sheet card.
///
/// Wire shape (`GET /api/weather/rainforecast/{code}` on `exptech.dingbot.tw`):
/// the response is a single-series envelope keyed by name (e.g.
/// `rainfallWarnings-rkai`) whose value is a list of `{start, rain}` records —
/// a minute-aligned Unix-second [startSecond] and sixty [mm] samples, one
/// millimetre value per minute. UI can render without a live feed via
/// [placeholder].
library;

/// Sixty minute-buckets of forecast rainfall starting at [startSecond].
class RainHourTrend {
  const RainHourTrend({required this.startSecond, required this.mm})
    : assert(mm.length == 60, 'expected 60 one-minute samples');

  /// Decodes the `rainforecast` envelope: the first non-empty series wins; its
  /// `start` (Unix seconds) and `rain` (60 mm samples) become this trend. An
  /// empty response — or a series with a non-numeric `start`, non-list `rain`,
  /// or wrong sample count — throws, which `guardResult` folds into a
  /// `DecodeFailure`.
  factory RainHourTrend.decode(Map<String, dynamic> json) {
    for (final series in json.values) {
      if (series is! List<dynamic> || series.isEmpty) continue;
      final raw = series.first;
      if (raw is! Map<dynamic, dynamic>) continue;
      final start = raw['start'];
      final rain = raw['rain'];
      if (start is! num || rain is! List<dynamic>) continue;
      if (rain.length != 60) {
        throw const FormatException('Expected 60 rain samples');
      }
      return RainHourTrend(
        startSecond: start.toInt(),
        mm: [for (final value in rain) (value as num).toDouble()],
      );
    }
    throw const FormatException('No rainforecast series in response');
  }

  /// Prediction origin, Unix **seconds**, aligned to a whole minute
  /// (`startSecond % 60 == 0`).
  final int startSecond;

  /// Rainfall for each of the next 60 minutes, mm (index 0 = the minute
  /// starting at [startSecond]).
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
