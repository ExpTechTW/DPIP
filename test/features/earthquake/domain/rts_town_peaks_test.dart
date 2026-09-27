/// The 震度排行's memory — TREM-Lite's bottom-right list, ported.
///
/// A township has to stay listed for the minute after its stations calm
/// down: a ranking built from the latest frame alone empties the moment the
/// S wave moves on, which is the moment people look at it. And it has to
/// leave once the minute is up, or yesterday's quake would sit on the monitor
/// until the app restarts. Past six townships the list folds into counties,
/// because a list of thirty is no longer a glance.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/features/earthquake/domain/rts_town_peaks.dart';
import 'package:flutter_test/flutter_test.dart';

Town _town(String code, String city, String town) => Town(
  code: code,
  city: city,
  town: town,
  lat: 0,
  lng: 0,
  cityLevel: '縣',
  townLevel: '鄉',
);

final _towns = {
  for (final (code, city, town) in [
    ('1', '花蓮', '秀林'),
    ('2', '花蓮', '新城'),
    ('3', '花蓮', '吉安'),
    ('4', '宜蘭', '南澳'),
    ('5', '宜蘭', '蘇澳'),
    ('6', '臺東', '長濱'),
    ('7', '南投', '仁愛'),
  ])
    code: _town(code, city, town),
};

void main() {
  test('a township keeps its peak for the minute after it calms', () {
    final peaks = RtsTownPeaks();

    peaks.update({'1': 5}, 0);
    peaks.update({'1': 2}, 10000);
    expect(peaks.update({}, 59999), {'1': 5});
    expect(peaks.update({}, 60000), {'1': 2}, reason: 'the 5 has aged out');
    expect(peaks.update({}, 70000), isEmpty);
  });

  test('a replay restarted earlier drops what it left in the future', () {
    final peaks = RtsTownPeaks();

    peaks.update({'1': 6}, 100000);
    expect(peaks.update({'2': 3}, 10000), {'2': 3});
  });

  test('rows are strongest first, named county + township', () {
    final rows = rtsRanking({'4': 2, '1': 5, '2': 5}, _towns.lookup);

    expect(rows.map((r) => r.name), ['花蓮縣秀林鄉', '花蓮縣新城鄉', '宜蘭縣南澳鄉']);
    expect(rows.map((r) => r.level), [5, 5, 2]);
  });

  test('past six townships the list folds into counties', () {
    final rows = rtsRanking({
      '1': 3,
      '2': 6,
      '3': 1,
      '4': 4,
      '5': 2,
      '6': 1,
      '7': 2,
    }, _towns.lookup);

    expect(rows.map((r) => r.name), ['花蓮縣', '宜蘭縣', '南投縣', '臺東縣']);
    expect(rows.map((r) => r.level), [6, 4, 2, 1]);
    expect(rows.every((r) => r.town == null), isTrue);
  });

  test('a code the directory does not know is left out', () {
    expect(rtsRanking({'999': 7}, _towns.lookup), isEmpty);
  });
}

extension on Map<String, Town> {
  Town? lookup(String code) => this[code];
}
