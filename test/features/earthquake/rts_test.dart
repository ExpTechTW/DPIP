import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rts.fromJson', () {
    test('maps stations (i/I wire names), time, and empty box/int', () {
      final rts = Rts.fromJson({
        'station': {
          '2012144': {'pga': 2.79, 'pgv': 0.52, 'i': -2.9, 'I': -3},
        },
        'box': <String, dynamic>{},
        'int': <dynamic>[],
        'time': 1783968266383,
      });

      expect(rts.time, 1783968266383);
      expect(rts.station, hasLength(1));
      final station = rts.station['2012144']!;
      expect(station.pga, 2.79);
      expect(station.pgv, 0.52);
      expect(station.intensityRaw, -2.9); // wire 'i'
      expect(station.intensity, -3); // wire 'I'
      expect(rts.box, isEmpty);
      expect(rts.intensities, isEmpty);
    });

    test('coerces an integer intensity float (JSON `i: -3`) to double', () {
      final rts = Rts.fromJson({
        'station': {
          'x': {'pga': 3, 'pgv': 1, 'i': -3, 'I': -3},
        },
        'time': 1,
      });
      expect(rts.station['x']!.intensityRaw, -3.0);
      expect(rts.station['x']!.pga, 3.0);
    });

    test('round-trips symmetrically through toJson', () {
      final rts = Rts.fromJson({
        'station': {
          'x': {'pga': 1.0, 'pgv': 2.0, 'i': 3.0, 'I': 4},
        },
        'time': 123,
      });
      expect(Rts.fromJson(rts.toJson()), rts);
    });

    test('missing fields fall back to defaults (robust live feed)', () {
      final rts = Rts.fromJson({'time': 5});
      expect(rts.station, isEmpty);
      expect(rts.box, isEmpty);
      expect(rts.intensities, isEmpty);
      expect(rts.time, 5);
    });
  });
}
