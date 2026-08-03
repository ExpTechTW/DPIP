import 'package:dpip/features/typhoon/domain/closest_frame.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('closestAtOrBefore', () {
    test('picks the latest frame at or before the bulletin', () {
      const secs = [100, 200, 300, 400];
      expect(closestAtOrBefore(secs, 300), 300);
      expect(closestAtOrBefore(secs, 350), 300);
      expect(closestAtOrBefore(secs, 99), isNull);
      expect(closestAtOrBefore(secs, 400), 400);
      expect(closestAtOrBefore(secs, 999), 400);
      expect(closestAtOrBefore(const [], 100), isNull);
    });
  });
}
