import 'package:dpip/core/network/meteor_decode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MeteorDecode.deltaSeconds', () {
    test('empty in → empty out', () {
      expect(MeteorDecode.deltaSeconds(const []), isEmpty);
    });

    test('restores a delta-second list to absolute seconds (ascending)', () {
      expect(MeteorDecode.deltaSeconds(const [1784016000, 3600, 3600, 3600]), [
        1784016000,
        1784019600,
        1784023200,
        1784026800,
      ]);
    });

    test('a single base value round-trips', () {
      expect(MeteorDecode.deltaSeconds(const [1783815502]), [1783815502]);
    });
  });

  group('MeteorDecode.real / integer', () {
    test('maps the -99 sentinel to null', () {
      expect(MeteorDecode.real(-99), isNull);
      expect(MeteorDecode.integer(-99), isNull);
    });

    test('passes real values through', () {
      expect(MeteorDecode.real(31.2), 31.2);
      expect(MeteorDecode.integer(69), 69);
      expect(MeteorDecode.real(0), 0.0);
    });

    test('null in → null out', () {
      expect(MeteorDecode.real(null), isNull);
      expect(MeteorDecode.integer(null), isNull);
    });
  });
}
