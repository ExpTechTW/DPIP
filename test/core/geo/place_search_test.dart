import 'package:dpip/core/geo/place_search.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:flutter_test/flutter_test.dart';

Town _town(String code, String city, String cityLevel, String town) => Town(
  code: code,
  city: city,
  town: town,
  lat: 25,
  lng: 121,
  cityLevel: cityLevel,
  townLevel: '區',
);

/// Spelled the way the bundled directory spells it: 臺, never 台.
final _directory = TownDirectory({
  '100': _town('100', '臺北', '市', '中正'),
  '103': _town('103', '臺北', '市', '大同'),
  '200': _town('200', '基隆', '市', '中正'),
  '220': _town('220', '新北', '市', '板橋'),
  '950': _town('950', '臺東', '縣', '臺東'),
});

List<String> _codes(List<Town> towns) => [for (final t in towns) t.code];

void main() {
  group('foldPlaceName', () {
    test('folds 臺 to 台, so both spellings compare equal', () {
      expect(foldPlaceName('臺北市'), foldPlaceName('台北市'));
      expect(foldPlaceName('臺北市'), '台北市');
    });

    test('drops every kind of whitespace, not just the ends', () {
      expect(foldPlaceName('  臺北市 中正區 '), '台北市中正區');
      expect(foldPlaceName('台北　中正'), '台北中正');
      expect(foldPlaceName('台\t北\n'), '台北');
    });

    test('folds full-width ASCII to half-width, and case', () {
      expect(foldPlaceName('ＡＢＣ１２３'), 'abc123');
      expect(foldPlaceName('Taipei'), 'taipei');
    });

    test('is total on the empty and all-blank string', () {
      expect(foldPlaceName(''), '');
      expect(foldPlaceName(' 　 '), '');
    });
  });

  group('PlaceSearchIndex', () {
    final index = PlaceSearchIndex(_directory);

    test('an empty query lists every city and no township', () {
      final result = index.search('  ');
      expect(result.cities, ['臺北市', '基隆市', '新北市', '臺東縣']);
      expect(result.towns, isEmpty);
    });

    test('台北 finds 臺北市 without listing all its districts', () {
      final result = index.search('台北');
      expect(result.cities, ['臺北市']);
      expect(result.towns, isEmpty);
    });

    test('a township name alone finds it on the first page', () {
      final result = index.search('板橋');
      expect(result.cities, isEmpty);
      expect(_codes(result.towns), ['220']);
    });

    test('a shared township name finds it in every city', () {
      expect(_codes(index.search('中正').towns), ['100', '200']);
    });

    test(
      'city and township together narrow to one, with or without levels',
      () {
        expect(_codes(index.search('台北中正').towns), ['100']);
        expect(_codes(index.search('臺北市 中正區').towns), ['100']);
        expect(_codes(index.search('台北市中正').towns), ['100']);
      },
    );

    test('a township named like its city is still found by its own name', () {
      final result = index.search('台東');
      expect(result.cities, ['臺東縣']);
      expect(_codes(result.towns), ['950']);
    });

    test('no match is empty on both sides', () {
      final result = index.search('東京');
      expect(result.cities, isEmpty);
      expect(result.towns, isEmpty);
    });
  });
}
