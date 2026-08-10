/// Near-term 1-hour rainfall trend (per-minute mm), for the home sheet card.
///
/// Wire shape (`GET /api/weather/rainforecast/{code}` on `exptech.dingbot.tw`):
/// the response is a single-series envelope keyed by name (e.g.
/// `rainfallWarnings-rkai`) whose value is a list of `{start, rain}` records —
/// a minute-aligned Unix-second [startSecond] and sixty [mm] samples, one
/// millimetre value per minute. UI can render without a live feed via
/// [placeholder].
library;

import 'dart:math' as math;

/// Rain intensity grade for the next hour, from the peak per-minute value.
enum RainHourTrendGrade {
  /// No rain forecast at all.
  none,

  /// Peak below [RainHourTrend.scatteredMm] — light, isolated showers.
  scattered,

  /// Peak `[scatteredMm, lightMm)` — steady light rain.
  light,

  /// Peak `>= lightMm` — heavy rain.
  heavy,
}

/// How the next hour reads — the structured answer the home-sheet card's
/// subtitle text is derived from.
class RainHourTrendSummary {
  const RainHourTrendSummary({
    required this.grade,
    required this.sustained,
    this.stopInMinutes,
  });

  /// Intensity grade for the hour.
  final RainHourTrendGrade grade;

  /// Rain is still falling near the end of the hour (no [stopInMinutes]).
  /// Only meaningful for [RainHourTrendGrade.light] / heavy.
  final bool sustained;

  /// Minutes from [RainHourTrend.startSecond] at which the rain is forecast to
  /// have stopped — the minute after the last wet sample. Null when [sustained]
  /// or [RainHourTrendGrade.scattered].
  final int? stopInMinutes;
}

/// Sixty minute-buckets of forecast rainfall starting at [startSecond].
class RainHourTrend {
  const RainHourTrend({required this.startSecond, required this.mm})
    : assert(mm.length == 60, 'expected 60 one-minute samples');

  /// Peak per-minute mm below which the hour reads as isolated showers.
  static const double scatteredMm = 5;

  /// Peak per-minute mm at which the hour reads as heavy rain.
  static const double lightMm = 15;

  /// The hour is "continuous" when rain still falls this late into it — the
  /// last wet minute is [sustainedFrom] or later.
  static const int sustainedFrom = 45;

  /// Intensity grade + continuity of the next hour, derived from [mm]: the peak
  /// value picks the grade, and for light/heavy the position of the last wet
  /// minute decides [RainHourTrendSummary.sustained] / stop time.
  RainHourTrendSummary get summary {
    final peak = mm.reduce(math.max);
    if (peak <= 0) {
      return const RainHourTrendSummary(
        grade: RainHourTrendGrade.none,
        sustained: false,
      );
    }
    final grade = switch (peak) {
      < scatteredMm => RainHourTrendGrade.scattered,
      < lightMm => RainHourTrendGrade.light,
      _ => RainHourTrendGrade.heavy,
    };
    if (grade == RainHourTrendGrade.scattered) {
      return RainHourTrendSummary(grade: grade, sustained: false);
    }
    final lastRain = mm.lastIndexWhere((v) => v > 0);
    final sustained = lastRain >= sustainedFrom;
    return RainHourTrendSummary(
      grade: grade,
      sustained: sustained,
      stopInMinutes: sustained ? null : lastRain + 1,
    );
  }

  /// Decodes the `rainforecast` envelope: the first non-empty series wins; its
  /// `start` (Unix seconds) and `rain` (60 mm samples) become this trend. An
  /// empty response — every series is an empty list — means the API forecasts
  /// no rain this hour, so this returns a dry trend ([isDry]) instead of
  /// failing. A series with a non-numeric `start`, non-list `rain`, or wrong
  /// sample count still throws, which `guardResult` folds into a
  /// `DecodeFailure`.
  factory RainHourTrend.decode(Map<String, dynamic> json) {
    for (final series in json.values) {
      if (series is! List<dynamic> || series.isEmpty) continue;
      // An empty series is the API's "no rain"; a non-empty one must be the
      // expected record — anything else is a malformed response, not a dry
      // hour, and keeps failing the fetch.
      final raw = series.first;
      if (raw is! Map<dynamic, dynamic>) {
        throw const FormatException('Malformed rainforecast series');
      }
      final start = raw['start'];
      final rain = raw['rain'];
      if (start is! num || rain is! List<dynamic>) {
        throw const FormatException('Malformed rainforecast series');
      }
      if (rain.length != 60) {
        throw const FormatException('Expected 60 rain samples');
      }
      return RainHourTrend(
        startSecond: start.toInt(),
        mm: [for (final value in rain) (value as num).toDouble()],
      );
    }
    // Every series was empty — the API's `[]` for "no rain this hour".
    return RainHourTrend.dry();
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

  /// The hour carries no rain at all — an empty `[]` response (the API's way of
  /// saying no rain is coming) and an all-zero series both land here. The home
  /// sheet hides the trend card for a dry hour rather than drawing an empty
  /// chart.
  bool get isDry => summary.grade == RainHourTrendGrade.none;

  /// A dry hour: all sixty samples are zero, aligned to [startUtc] (defaults to
  /// "now", minute-aligned). Used by [decode] when the API returns no forecast
  /// series at all.
  factory RainHourTrend.dry({DateTime? startUtc}) {
    final seconds =
        (startUtc ?? DateTime.now().toUtc()).millisecondsSinceEpoch ~/ 1000;
    final aligned = seconds - (seconds % 60);
    return RainHourTrend(startSecond: aligned, mm: List<double>.filled(60, 0));
  }

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
