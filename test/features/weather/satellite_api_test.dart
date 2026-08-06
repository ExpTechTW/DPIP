import 'package:dpip/features/weather/data/satellite_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SatelliteApi.framesFromList', () {
    test('decodes delta-seconds and returns them newest first', () {
      expect(SatelliteApi.framesFromList([1783360200, 600, 600]), [
        '1783361400',
        '1783360800',
        '1783360200',
      ]);
    });

    test('an empty list yields no frames', () {
      expect(SatelliteApi.framesFromList(const []), isEmpty);
    });

    test('a single-frame list is just the base second', () {
      expect(SatelliteApi.framesFromList([1783360200]), ['1783360200']);
    });

    test('frame ids are 10-digit seconds, usable straight in a tile URL', () {
      final frames = SatelliteApi.framesFromList([1783360200, 600]);
      expect(frames.first.length, 10);
    });
  });
}
