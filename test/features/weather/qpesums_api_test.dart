import 'package:dpip/features/weather/data/qpesums_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QpesumsApi.framesFromList', () {
    test('decodes delta-millis and returns them newest first', () {
      // [baseMs, +600000, +600000] → 1786208400000, 1786209000000,
      // 1786209600000 (10-min steps)
      expect(QpesumsApi.framesFromList([1786208400000, 600000, 600000]), [
        '1786209600000',
        '1786209000000',
        '1786208400000',
      ]);
    });

    test('an empty list yields no frames', () {
      expect(QpesumsApi.framesFromList(const []), isEmpty);
    });

    test('a single-frame list is just the base millisecond', () {
      expect(QpesumsApi.framesFromList([1786208400000]), ['1786208400000']);
    });

    test('frame ids are 13-digit millis, usable straight in a tile URL', () {
      final frames = QpesumsApi.framesFromList([1786208400000, 600000]);
      expect(frames.first.length, 13);
    });
  });
}
