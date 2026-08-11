import 'package:dpip/features/map/presentation/wind_speed.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('windSpeedBucket', () {
    test('maps speeds onto the five legacy buckets', () {
      expect(windSpeedBucket(0), 0);
      expect(windSpeedBucket(3.3), 0);
      expect(windSpeedBucket(3.4), 1);
      expect(windSpeedBucket(7.9), 1);
      expect(windSpeedBucket(8.0), 2);
      expect(windSpeedBucket(13.9), 3);
      expect(windSpeedBucket(32.7), 4);
      expect(windSpeedBucket(100), 4);
    });

    test('negative speed never escapes bucket 0', () {
      expect(windSpeedBucket(-1), 0);
    });
  });

  group('windSpeedColor', () {
    test('is the discrete bucket colour, not an interpolation', () {
      expect(windSpeedColor(0), windBuckets.first.$2);
      expect(windSpeedColor(8.0), windBuckets[2].$2);
      expect(windSpeedColor(50), windBuckets.last.$2);
    });
  });
}
