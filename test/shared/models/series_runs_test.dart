/// Where a series is continuous — the rule every chart in the app draws by.
library;

import 'package:dpip/shared/models/series_runs.dart';
import 'package:flutter_test/flutter_test.dart';

List<SeriesPoint<double>> _minutely(List<(int, double?)> entries) => [
  for (final (minute, value) in entries)
    (DateTime.utc(2026, 8, 16, 10).add(Duration(minutes: minute)), value),
];

void main() {
  test('an unbroken series is one run', () {
    final runs = splitSeriesRuns(_minutely([(0, 1), (1, 2), (2, 3), (3, 4)]));
    expect(runs, hasLength(1));
    expect(runs.first, hasLength(4));
  });

  test('a null is a missing observation, not a boundary', () {
    // Rows are written when something is worth recording, and different
    // fields arrive on different cadences — a row exists because *some* field
    // had news, and every other field is null for that reason alone. Treating
    // those as holes would chop a one-minute series into fragments each time
    // a fifteen-minute counter block landed between two readings.
    final runs = splitSeriesRuns(
      _minutely([(0, 1), (1, 2), (2, null), (3, 4), (4, 5)]),
    );
    expect(runs, hasLength(1));
    expect(runs.single, hasLength(4), reason: 'the null is skipped, not drawn');
  });

  test('but nulls do not hide a real absence', () {
    // Rows kept arriving; this series had nothing in any of them for an hour.
    final runs = splitSeriesRuns(
      _minutely([
        (0, 1),
        (1, 2),
        for (var m = 2; m < 62; m++) (m, null),
        (62, 3),
        (63, 4),
      ]),
    );
    expect(runs.map((r) => r.length), [2, 2]);
  });

  test('a hole with no rows in it splits it too', () {
    // The case the null rule cannot see. A recorder writes a row only when
    // there is something to record, so six hours away leaves *no rows* — two
    // adjacent, perfectly valid entries with a chasm between them. Breaking
    // on nulls alone finds nothing here and the line runs straight across.
    final runs = splitSeriesRuns(
      _minutely([(0, 1), (1, 2), (360, 3), (361, 4)]),
    );
    expect(runs.map((r) => r.length), [2, 2]);
  });

  test('the threshold follows the series own cadence', () {
    // Hourly samples: an hour is normal, not a hole.
    final hourly = <SeriesPoint<double>>[
      for (var h = 0; h < 6; h++) (DateTime.utc(2026, 8, 16, h), h.toDouble()),
    ];
    expect(splitSeriesRuns(hourly), hasLength(1));

    // The same 60-minute jump inside a minutely series is a hole.
    expect(
      splitSeriesRuns(_minutely([(0, 1), (1, 2), (61, 3), (62, 4)])),
      hasLength(2),
    );
  });

  test('one long outage cannot raise the bar until it stops counting', () {
    // The median ignores the outlier; a mean would be dragged up by the very
    // gap being looked for, and then declare it normal.
    final points = _minutely([
      (0, 1),
      (1, 2),
      (2, 3),
      (3, 4),
      (4, 5),
      (600, 6),
      (601, 7),
    ]);
    expect(splitSeriesRuns(points).map((r) => r.length), [5, 2]);
  });

  test('jitter at a fast cadence does not shatter the line', () {
    // Two missed reports on a one-minute feed is not a blackout.
    expect(
      splitSeriesRuns(_minutely([(0, 1), (1, 2), (4, 3), (5, 4)])),
      hasLength(1),
    );
  });

  test('a lone reading survives as its own run', () {
    // One sample stranded between two outages. It is real and must not be
    // discarded — whether to draw it as a dot is the painter's call.
    final runs = splitSeriesRuns(
      _minutely([(0, 1), (1, 2), (2, 3), (500, 4), (1000, 5), (1001, 6)]),
    );
    expect(runs.map((r) => r.length), [3, 1, 2]);
  });

  test('evenly spaced is continuous however wide the spacing', () {
    // Every 500 minutes *is* this series cadence; nothing is missing.
    final runs = splitSeriesRuns(_minutely([(0, 1), (500, 2), (1000, 3)]));
    expect(runs, hasLength(1));
  });

  test('an empty series is no runs, not a crash', () {
    expect(splitSeriesRuns(<SeriesPoint<double>>[]), isEmpty);
    expect(splitSeriesRuns(_minutely([(0, null)])), isEmpty);
  });
}
