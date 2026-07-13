import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/geo/town.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final dir = TownDirectory.fromJson({
    '100': {
      'city': '臺北',
      'town': '中正',
      'lat': 25.03,
      'lng': 121.52,
      'cityLevel': '市',
      'townLevel': '區',
    },
    '900': {
      'city': '屏東',
      'town': '屏東',
      'lat': 22.68,
      'lng': 120.49,
      'cityLevel': '縣',
      'townLevel': '市',
    },
    '970': {
      'city': '花蓮',
      'town': '花蓮',
      'lat': 23.99,
      'lng': 121.60,
      'cityLevel': '縣',
      'townLevel': '市',
    },
  });

  test('fromJson injects the map key as the town code', () {
    expect(dir.byCode('100')!.code, '100');
    expect(dir.byCode('100')!.fullName, '臺北市 中正區');
  });

  test('byCode returns null for an unknown or null code', () {
    expect(dir.byCode('000'), isNull);
    expect(dir.byCode(null), isNull);
  });

  test('nearest picks the closest centroid', () {
    expect(dir.nearest(25.05, 121.55)!.code, '100'); // Taipei
    expect(dir.nearest(24.00, 121.60)!.code, '970'); // Hualien
    expect(dir.nearest(22.70, 120.50)!.code, '900'); // Pingtung
  });

  test('nearest on an empty directory is null', () {
    expect(const TownDirectory(<String, Town>{}).nearest(25, 121), isNull);
  });

  test('cities lists each city once in directory order', () {
    expect(dir.cities, ['臺北市', '屏東縣', '花蓮縣']);
  });

  test('townsInCity returns only that city\'s townships', () {
    final towns = dir.townsInCity('臺北市');
    expect(towns.map((t) => t.code), ['100']);
    expect(dir.townsInCity('花蓮縣').single.townName, '花蓮市');
    expect(dir.townsInCity('不存在市'), isEmpty);
  });
}
