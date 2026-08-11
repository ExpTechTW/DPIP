import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:flutter_test/flutter_test.dart';

TownDirectory _dir() => TownDirectory.fromJson({
  '100': {
    'city': '臺北',
    'town': '中正',
    'lat': 25.03,
    'lng': 121.52,
    'cityLevel': '市',
    'townLevel': '區',
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

void main() {
  test('resolves the nearest township from a GPS fix', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => true,
      fix: () async => (lat: 25.05, lng: 121.55),
    );
    expect((await service.currentTown())?.code, '100');
  });

  test('null when location is unavailable (services off / denied)', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => false,
      fix: () async => (lat: 25.05, lng: 121.55),
    );
    expect(await service.currentTown(), isNull);
  });

  test('null when no fix could be obtained', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => true,
      fix: () async => null,
    );
    expect(await service.currentTown(), isNull);
  });

  test('a fix error degrades to null, never throws', () async {
    final service = LocationService(
      _dir(),
      isAvailable: () async => true,
      fix: () async => throw Exception('gps timeout'),
    );
    expect(await service.currentTown(), isNull);
  });

  test('lastKnownFix serves the cached fix without a live read', () async {
    var liveReads = 0;
    final service = LocationService(
      _dir(),
      lastKnown: () async => (lat: 25.05, lng: 121.55),
      fix: () async {
        liveReads++;
        return (lat: 25.05, lng: 121.55);
      },
    );
    expect(await service.lastKnownFix(), (lat: 25.05, lng: 121.55));
    expect(liveReads, 0, reason: 'the live read must not run');
  });

  test('lastKnownFix is null when no cached fix exists', () async {
    final service = LocationService(
      _dir(),
      lastKnown: () async => null,
      fix: () async => (lat: 25.05, lng: 121.55),
    );
    expect(await service.lastKnownFix(), isNull);
  });

  test('a lastKnownFix fault degrades to null, never throws', () async {
    final service = LocationService(
      _dir(),
      lastKnown: () async => throw Exception('platform fault'),
    );
    expect(await service.lastKnownFix(), isNull);
  });
}
