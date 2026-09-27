/// A TREM seismic station's fixed location, built by
/// `TremStationRepositoryImpl` from the *last* entry of a station's `info`
/// history (a station can be relocated over its lifetime). Getting
/// [latitude]/[longitude] transposed here would silently place every live
/// intensity marker at the wrong spot on the map — both are plain doubles, so
/// nothing type-checks a swapped pair.
library;

import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes id, latitude and longitude exactly as constructed', () {
    const station = SeismicStation(
      id: 'A0010',
      latitude: 24.998,
      longitude: 121.512,
    );

    expect(station.id, 'A0010');
    expect(station.latitude, 24.998);
    expect(station.longitude, 121.512);
  });
}
