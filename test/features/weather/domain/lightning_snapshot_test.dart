import 'package:dpip/features/weather/domain/lightning_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('LightningSnapshot.decode aligns the parallel strike arrays', () {
    final snapshot = LightningSnapshot.decode(const {
      'time': 1784016300,
      'type': [0, 0, 1],
      't': [1784016300, 1784016301, 1784016302],
      'lat': [24.802, 24.804, 24.818],
      'lon': [121.008, 121.023, 120.978],
    });

    expect(snapshot.time, 1784016300);
    expect(snapshot.strikes, hasLength(3));
    final last = snapshot.strikes[2];
    expect(last.type, 1, reason: 'cloud-to-ground');
    expect(last.time, 1784016302);
    expect(last.latitude, 24.818);
    expect(last.longitude, 120.978);
  });

  test('empty strike arrays decode to no strikes', () {
    final snapshot = LightningSnapshot.decode(const {
      'time': 1,
      'type': <int>[],
      't': <int>[],
      'lat': <double>[],
      'lon': <double>[],
    });
    expect(snapshot.strikes, isEmpty);
  });
}
