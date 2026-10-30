/// Client-side ranking of joined station observations (rain / weather metrics).
library;

import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';

/// How to collapse stations before sorting (legacy 「合併至」).
enum RankingMerge {
  /// One row per station.
  none,

  /// Keep the extreme station per township (`county`+`town`).
  town,

  /// Keep the extreme station per county.
  county,
}

/// Which temperature figure a ranking shows: the observation itself (at
/// whichever snapshot the list is drawn from) or one of the day's recorded
/// extremes.
///
/// Temperature is the only metric whose extremes the v5 snapshot carries
/// (`hi` / `lo` with their occurrence times), so it is the only one the app can
/// rank as an extreme without inventing one.
enum TempRankMetric {
  /// The temperature recorded at the snapshot.
  current,

  /// The day's recorded maximum (`hi`).
  high,

  /// The day's recorded minimum (`lo`).
  low,

  /// Diurnal range (`hi − lo`).
  range;

  /// Parses the deep-link values the Data hub links use: the current metric,
  /// and the aliases the standalone daily-extremes tab had before it became a
  /// chip inside the temperature tab (`?tab=tempExtremes`, `?tab=low`, …).
  static TempRankMetric parse(String? raw) => switch (raw) {
    'high' || 'tempHigh' || 'tempExtremes' || 'extremes' => TempRankMetric.high,
    'low' || 'tempLow' => TempRankMetric.low,
    'range' => TempRankMetric.range,
    _ => TempRankMetric.current,
  };
}

/// Which daily-temperature extreme to rank by.
enum TempExtremeMetric {
  /// Recorded daily maximum (`hi`).
  high,

  /// Recorded daily minimum (`lo`).
  low,

  /// Diurnal range (`hi − lo`).
  range,
}

/// Structured daily-extreme breakdown for analysis rows.
class TempExtremeDetail {
  const TempExtremeDetail({
    required this.high,
    required this.low,
    this.current,
    this.highTime,
    this.lowTime,
  });

  final double high;
  final double low;
  final double? current;
  final int? highTime;
  final int? lowTime;

  double get range => high - low;
}

/// One ranked row after join + filter + optional merge + sort.
class RankedObservation {
  const RankedObservation({
    required this.id,
    required this.station,
    required this.value,
    this.windDirection,
    this.eventTime,
    this.tempExtreme,
  });

  /// Station directory key.
  final String id;

  /// Catalogue entry for [id].
  final WeatherStation station;

  /// Ranked numeric value (mm / °C / m/s / hPa / %).
  final double value;

  /// Wind bearing (° meteorological) when ranking wind; otherwise null.
  final int? windDirection;

  /// When [value] was recorded (gust `gt`, or the ranked extreme's `hit`/`lot`).
  final int? eventTime;

  /// Full hi/lo/current breakdown when ranking daily temperature extremes.
  final TempExtremeDetail? tempExtreme;

  /// Display title under the current [RankingMerge].
  String title(RankingMerge merge) => switch (merge) {
    RankingMerge.none => station.name,
    RankingMerge.town => '${station.county}${station.town}',
    RankingMerge.county => station.county,
  };

  /// Secondary location line; empty when merge already ate it into [title].
  String? subtitle(RankingMerge merge) => switch (merge) {
    RankingMerge.none => '${station.county}${station.town}',
    RankingMerge.town || RankingMerge.county => null,
  };
}

/// Ranks rainfall for [interval]: drop null/`≤0`, sort descending.
List<RankedObservation> rankRain({
  required Map<String, WeatherStation> stations,
  required RainSnapshot snapshot,
  required RainInterval interval,
}) {
  return rankByValue(
    stations: stations,
    rows: [
      for (final o in snapshot.stations)
        RankInput(id: o.id, value: interval.valueOf(o)),
    ],
    ascending: false,
    merge: RankingMerge.none,
    requirePositive: true,
  );
}

/// Ranks a weather field (temperature / wind / pressure / humidity / gust).
List<RankedObservation> rankWeather({
  required Map<String, WeatherStation> stations,
  required WeatherSnapshot snapshot,
  required double? Function(WeatherObservation o) valueOf,
  int? Function(WeatherObservation o)? windDirectionOf,
  int? Function(WeatherObservation o)? eventTimeOf,
  required bool ascending,
  required RankingMerge merge,
  bool requirePositive = false,
}) {
  return rankByValue(
    stations: stations,
    rows: [
      for (final o in snapshot.stations)
        RankInput(
          id: o.id,
          value: valueOf(o),
          windDirection: windDirectionOf?.call(o),
          eventTime: eventTimeOf?.call(o),
        ),
    ],
    ascending: ascending,
    merge: merge,
    requirePositive: requirePositive,
  );
}

/// Ranks daily temperature extremes (`hi` / `lo` / `hi−lo`) with full detail.
List<RankedObservation> rankTempExtremes({
  required Map<String, WeatherStation> stations,
  required WeatherSnapshot snapshot,
  required TempExtremeMetric metric,
  required bool ascending,
  required RankingMerge merge,
}) {
  return rankByValue(
    stations: stations,
    rows: [
      for (final o in snapshot.stations)
        if (o.high != null && o.low != null)
          RankInput(
            id: o.id,
            value: switch (metric) {
              TempExtremeMetric.high => o.high,
              TempExtremeMetric.low => o.low,
              TempExtremeMetric.range => o.high! - o.low!,
            },
            eventTime: switch (metric) {
              TempExtremeMetric.high => o.highTime,
              TempExtremeMetric.low => o.lowTime,
              TempExtremeMetric.range => null,
            },
            tempExtreme: TempExtremeDetail(
              high: o.high!,
              low: o.low!,
              current: o.temperature,
              highTime: o.highTime,
              lowTime: o.lowTime,
            ),
          ),
    ],
    ascending: ascending,
    merge: merge,
  );
}

/// Ranks temperature by [metric]: the reading in the snapshot itself, or one of
/// the day's recorded extremes. One entry point so the temperature tab does not
/// have to know which of the two implementations backs the chip it is on.
List<RankedObservation> rankTemperature({
  required Map<String, WeatherStation> stations,
  required WeatherSnapshot snapshot,
  required TempRankMetric metric,
  required bool ascending,
  required RankingMerge merge,
}) => switch (metric) {
  TempRankMetric.current => rankWeather(
    stations: stations,
    snapshot: snapshot,
    valueOf: (o) => o.temperature,
    ascending: ascending,
    merge: merge,
  ),
  TempRankMetric.high ||
  TempRankMetric.low ||
  TempRankMetric.range => rankTempExtremes(
    stations: stations,
    snapshot: snapshot,
    metric: switch (metric) {
      TempRankMetric.high => TempExtremeMetric.high,
      TempRankMetric.low => TempExtremeMetric.low,
      _ => TempExtremeMetric.range,
    },
    ascending: ascending,
    merge: merge,
  ),
};

class RankInput {
  const RankInput({
    required this.id,
    required this.value,
    this.windDirection,
    this.eventTime,
    this.tempExtreme,
  });

  final String id;
  final double? value;
  final int? windDirection;
  final int? eventTime;
  final TempExtremeDetail? tempExtreme;
}

/// Join → filter → optional merge → sort. Pure; presentation just renders.
List<RankedObservation> rankByValue({
  required Map<String, WeatherStation> stations,
  required Iterable<RankInput> rows,
  required bool ascending,
  required RankingMerge merge,
  bool requirePositive = false,
}) {
  var items = <RankedObservation>[];
  for (final row in rows) {
    final value = row.value;
    if (value == null) continue;
    if (requirePositive && value <= 0) continue;
    final station = stations[row.id];
    if (station == null) continue;
    items.add(
      RankedObservation(
        id: row.id,
        station: station,
        value: value,
        windDirection: row.windDirection,
        eventTime: row.eventTime,
        tempExtreme: row.tempExtreme,
      ),
    );
  }

  if (merge != RankingMerge.none) {
    final groups = <Object, RankedObservation>{};
    for (final item in items) {
      final key = merge == RankingMerge.town
          ? (item.station.county, item.station.town)
          : item.station.county;
      final prev = groups[key];
      if (prev == null) {
        groups[key] = item;
        continue;
      }
      final better = ascending
          ? item.value < prev.value
          : item.value > prev.value;
      if (better) groups[key] = item;
    }
    items = groups.values.toList();
  }

  items.sort(
    (a, b) =>
        ascending ? a.value.compareTo(b.value) : b.value.compareTo(a.value),
  );
  return items;
}
