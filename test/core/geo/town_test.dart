import 'package:dpip/core/geo/town.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson maps fields and builds display names', () {
    final town = Town.fromJson({
      'code': '100',
      'city': '臺北',
      'town': '中正',
      'lat': 25.032188,
      'lng': 121.5183226,
      'cityLevel': '市',
      'townLevel': '區',
    });

    expect(town.code, '100');
    expect(town.cityName, '臺北市');
    expect(town.townName, '中正區');
    expect(town.fullName, '臺北市 中正區');
    expect(town.lat, 25.032188);
  });

  test('round-trips through toJson', () {
    final town = Town.fromJson({
      'code': '1',
      'city': 'a',
      'town': 'b',
      'lat': 1.0,
      'lng': 2.0,
      'cityLevel': '市',
      'townLevel': '區',
    });
    expect(Town.fromJson(town.toJson()), town);
  });
}
