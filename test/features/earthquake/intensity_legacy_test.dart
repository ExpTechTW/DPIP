import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2019-12-31 15:59:59 UTC = still 2019-12-31 23:59:59 Taipei → 舊制.
  final legacyInstant = DateTime.utc(2019, 12, 31, 15, 59, 59);
  // 2019-12-31 16:00:00 UTC = 2020-01-01 00:00 Taipei → 新制.
  final modernInstant = DateTime.utc(2019, 12, 31, 16);

  group('Intensity.usesLegacyScale', () {
    test('before 2020-01-01 Taipei is 舊制', () {
      expect(Intensity.usesLegacyScale(legacyInstant), isTrue);
    });

    test('from 2020-01-01 Taipei is 新制', () {
      expect(Intensity.usesLegacyScale(modernInstant), isFalse);
    });
  });

  group('Intensity.displayForReport — 舊制 (2020 以前)', () {
    test('5 →「5」+ 5弱 color index', () {
      final d = Intensity.displayForReport(5, legacyInstant);
      expect(d.label, '5');
      expect(d.colorLevel, 5);
    });

    test('6 →「6」+ 6弱 color index', () {
      final d = Intensity.displayForReport(6, legacyInstant);
      expect(d.label, '6');
      expect(d.colorLevel, 7);
    });

    test('7 →「7」+ 7 color index', () {
      final d = Intensity.displayForReport(7, legacyInstant);
      expect(d.label, '7');
      expect(d.colorLevel, 9);
    });

    test('4 stays plain', () {
      final d = Intensity.displayForReport(4, legacyInstant);
      expect(d.label, '4');
      expect(d.colorLevel, 4);
    });
  });

  group('Intensity.displayForReport — 新制', () {
    test('5 is 5⁻', () {
      final d = Intensity.displayForReport(5, modernInstant);
      expect(d.label, '5⁻');
      expect(d.colorLevel, 5);
    });

    test('7 is 6⁻', () {
      final d = Intensity.displayForReport(7, modernInstant);
      expect(d.label, '6⁻');
      expect(d.colorLevel, 7);
    });

    test('9 is 7', () {
      final d = Intensity.displayForReport(9, modernInstant);
      expect(d.label, '7');
      expect(d.colorLevel, 9);
    });
  });
}
