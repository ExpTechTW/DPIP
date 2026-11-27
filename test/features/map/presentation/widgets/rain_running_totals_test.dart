import 'dart:math' as math;

import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_test/flutter_test.dart';

/// [mm] of rain falling evenly from [from] to [to], in Unix seconds.
typedef _Shower = ({double from, double to, double mm});

const _minute = 60.0;
const _hour = 3600.0;

/// The rain of [showers] that fell in (from, to].
double _rainIn(List<_Shower> showers, double from, double to) {
  var mm = 0.0;
  for (final shower in showers) {
    final overlap = math.min(to, shower.to) - math.max(from, shower.from);
    if (overlap > 0) mm += shower.mm * overlap / (shower.to - shower.from);
  }
  return mm;
}

/// A 24-hour rain trend as the API sends it: a sample every 10 minutes from
/// [first] to [last], each the rain of the hour before it, less [missing].
List<FlSpot> _tenMinuteSeries(
  double first,
  double last,
  List<_Shower> showers, {
  Set<double> missing = const {},
}) => [
  for (var t = first; t <= last; t += 10 * _minute)
    if (!missing.contains(t)) FlSpot(t, _rainIn(showers, t - _hour, t)),
];

/// Every rain-trend sample is the rain of the hour before it, so the running
/// total may add only samples a whole hour apart. Adding all six 10-minute
/// samples of an hour counted each shower six times and put the 24-hour total
/// above the 7-day one; adding the last sample of each clock hour still
/// counted up to 50 minutes twice at the newest end, and rain from before the
/// series at the oldest.
void main() {
  // 2026-11-28 00:00 Taipei, in Unix seconds.
  const midnight = 1795795200.0;
  double today(int h, int m) => midnight + h * _hour + m * _minute;
  double yesterday(int h, int m) => today(h, m) - 24 * _hour;

  test('ten-minute samples count each hour once', () {
    // Two hours of samples, each the rain of the hour before it: 1 mm fell in
    // the first hour, 2 mm in the second.
    final spots = [
      for (var m = 0; m < 60; m += 10)
        FlSpot(midnight + m * 60, m == 50 ? 1 : 0.5),
      for (var m = 60; m < 120; m += 10)
        FlSpot(midnight + m * 60, m == 110 ? 2 : 1.5),
    ];

    final totals = rainRunningTotals(spots);

    expect(totals.last, 3.0);
    // A bar earlier in its hour carries the hours before it.
    expect(totals.first, 0);
    expect(totals[5], 1.0);
    expect(totals[6], 1.0);
    expect(totals[11], 3.0);
  });

  test('hourly samples add up as they are', () {
    final spots = [
      for (var h = 0; h < 4; h++) FlSpot(midnight + h * 3600, h.toDouble()),
    ];
    expect(rainRunningTotals(spots), [0, 1, 3, 6]);
  });

  test('a missing hour still counts every other hour once', () {
    final spots = [
      const FlSpot(midnight + 600, 0.5),
      const FlSpot(midnight + 3000, 1),
      // 01:00–02:00 has no samples.
      const FlSpot(midnight + 2 * 3600 + 1200, 2),
    ];
    expect(rainRunningTotals(spots), [0, 1, 3]);
  });

  test('no samples, no totals', () {
    expect(rainRunningTotals(const []), isEmpty);
  });

  test('rain in the newest hour is counted once', () {
    // Seen at 14:10: 4 mm fell from 13:10 to 13:50 today. The 13:50 and the
    // 14:10 samples each hold all of it; one clock hour apiece, they made 8.
    final spots = _tenMinuteSeries(yesterday(14, 30), today(14, 10), [
      (from: today(13, 10), to: today(13, 50), mm: 4),
    ]);
    expect(spots, hasLength(143));

    expect(rainRunningTotals(spots).last, closeTo(4, 1e-9));
  });

  test('rain from before the series is not counted', () {
    // Seen at 14:10: 10 mm fell from 13:30 to 14:10 yesterday, before the 24
    // hours. The series' first three samples still hold some of it — the
    // 14:50 one, the last of its clock hour, half — but none of it fell in
    // the 24 hours up to 14:10 today.
    final spots = _tenMinuteSeries(yesterday(14, 30), today(14, 10), [
      (from: yesterday(13, 30), to: yesterday(14, 10), mm: 10),
    ]);
    expect(spots.first.y, 10);
    expect(spots[2].y, 5);

    expect(rainRunningTotals(spots), everyElement(0));
  });

  test('a series starting and ending partway through an hour', () {
    // As the API sends it: 05:40 yesterday to 05:20 today. The hours counted
    // end at 05:20, 04:20, … 06:20 yesterday, covering the 24 hours from
    // 05:20 yesterday. One shower crosses that start, one is in the middle,
    // one crosses the newest hour's start at 04:20 today.
    final first = yesterday(5, 40);
    final last = today(5, 20);
    final showers = <_Shower>[
      (from: yesterday(4, 50), to: yesterday(5, 50), mm: 6),
      (from: yesterday(18, 5), to: yesterday(19, 35), mm: 9),
      (from: today(4, 0), to: today(5, 0), mm: 6),
    ];
    final spots = _tenMinuteSeries(first, last, showers);
    expect(spots, hasLength(143));
    int at(double t) => spots.indexWhere((s) => s.x == t);

    final totals = rainRunningTotals(spots);

    // Every millimetre of the 24 hours, once: 3 + 9 + 6.
    expect(totals.last, closeTo(18, 1e-9));
    expect(
      totals.last,
      closeTo(_rainIn(showers, last - 24 * _hour, last), 1e-9),
    );
    // Before the oldest counted sample nothing is counted yet, though the
    // first bars hold the leading shower.
    expect(spots.first.y, greaterThan(0));
    expect(totals.sublist(0, at(yesterday(6, 20))), everyElement(0));
    // The oldest counted sample holds 05:20–06:20 yesterday: 3 of the 6 mm.
    expect(totals[at(yesterday(6, 20))], closeTo(3, 1e-9));
    // A bar between counted samples carries the last one before it.
    expect(totals[at(today(4, 20))], closeTo(3 + 9 + 2, 1e-9));
    expect(totals[at(today(5, 10))], closeTo(3 + 9 + 2, 1e-9));
    for (var i = 1; i < totals.length; i++) {
      expect(totals[i], greaterThanOrEqualTo(totals[i - 1]));
    }
  });

  test('a missing sample loses its minutes but counts nothing twice', () {
    // Seen at 14:10 with the 13:10 sample missing: 6 mm fell from 12:40 to
    // 13:40. 14:10 holds 13:10–13:40, 3 mm; 13:00 stands in for 13:10 and
    // holds 12:40–13:00, 2 mm. 13:00–13:10 is lost, and nothing is added
    // twice — the clock-hour rule made it 9.
    final spots = _tenMinuteSeries(
      yesterday(14, 30),
      today(14, 10),
      [(from: today(12, 40), to: today(13, 40), mm: 6)],
      missing: {today(13, 10)},
    );

    expect(rainRunningTotals(spots).last, closeTo(5, 1e-9));
  });

  test('whichever sample is missing, no rain is counted twice', () {
    // 1 mm in a single 10 minutes, tried at every 10 minutes the series can
    // see, with nothing missing and then each sample missing in turn. A
    // counted hour holds all of it or none, so the total is 0 or 1; 2 would
    // be a double count.
    final first = yesterday(14, 30);
    final last = today(14, 10);
    final gaps = <double?>[
      null,
      for (var t = first; t <= last; t += 10 * _minute) t,
    ];
    for (final gap in gaps) {
      for (var from = first - _hour; from < last; from += 10 * _minute) {
        final spots = _tenMinuteSeries(
          first,
          last,
          [(from: from, to: from + 10 * _minute, mm: 1)],
          missing: {?gap},
        );
        final total = rainRunningTotals(spots).last;
        expect(
          total == 0 || total == 1,
          isTrue,
          reason: 'rain at $from, sample $gap missing: $total mm',
        );
      }
    }
  });

  test('a 7-day series adds every hourly sample, as before', () {
    // 168 samples on the hour, each the last 10-minute sample of its clock
    // hour, so already an hour apart: every one is added, with an hour
    // missing or not.
    const start = midnight - 7 * 24 * _hour;
    final full = [
      for (var h = 1; h <= 168; h++)
        FlSpot(start + h * _hour, (h * 7 % 5) * 0.5),
    ];
    final withGap = [...full]..removeAt(100);
    for (final spots in [full, withGap]) {
      var sum = 0.0;
      final added = [for (final spot in spots) sum += spot.y];

      expect(rainRunningTotals(spots), added);
    }
  });
}
