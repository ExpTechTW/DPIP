import 'package:dpip/features/weather/data/radar_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarApi.framesFromList', () {
    test('decodes delta-seconds and returns them newest first', () {
      // [baseSec, +600, +600] → 1783360200, 1783360800, 1783361400 (10-min steps)
      expect(RadarApi.framesFromList([1783360200, 600, 600]), [
        '1783361400',
        '1783360800',
        '1783360200',
      ]);
    });

    test('an empty list yields no frames', () {
      expect(RadarApi.framesFromList(const []), isEmpty);
    });

    test('a single-frame list is just the base second', () {
      expect(RadarApi.framesFromList([1783360200]), ['1783360200']);
    });

    test('frame ids are 10-digit seconds, usable straight in a tile URL', () {
      final frames = RadarApi.framesFromList([1783360200, 600]);
      expect(frames.first.length, 10);
    });
  });
}
