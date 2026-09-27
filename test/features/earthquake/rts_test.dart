/// The `rts.v1` frame, as the TREM stream and the v3 archive both send it.
///
/// The case that matters is the one a strict model gets wrong: a station that
/// has not measured anything yet is sent without `pga`, and `alert` is sent
/// only as `1` and only while alerting. A model that required either would
/// reject the whole frame — every station on the monitor — over one new
/// sensor, and it would do so exactly when a big event brings stations in.
library;

import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a live frame: hex ids, i, pga, alert and ts', () {
    final rts = Rts.fromJson({
      'source': 'core-tnn1',
      'ts': 1790537637000,
      'stations': {
        '117825C': {'i': -0.1, 'pga': 0.51},
        '11DFDBC': {'i': 4.6, 'pga': 38.2, 'alert': 1},
      },
      'eq': <dynamic>[],
    });

    expect(rts.time, 1790537637000);
    expect(rts.stations.keys, ['117825C', '11DFDBC']);
    expect(rts.stations['117825C']!.intensity, -0.1);
    expect(rts.stations['117825C']!.pga, 0.51);
    expect(rts.stations['117825C']!.alert, isFalse);
    expect(rts.stations['11DFDBC']!.alert, isTrue);
  });

  test('a station with no pga yet still decodes, and keeps the frame', () {
    final rts = Rts.fromJson({
      'ts': 1,
      'stations': {
        'NEW': {'i': -3.0},
        'OLD': {'i': 1.2, 'pga': 2.0},
      },
    });

    expect(rts.stations, hasLength(2));
    expect(rts.stations['NEW']!.pga, 0.0);
  });

  test('an integer intensity on the wire (`i: -3`) reads as a double', () {
    final rts = Rts.fromJson({
      'ts': 1,
      'stations': {
        'x': {'i': -3, 'pga': 3},
      },
    });

    expect(rts.stations['x']!.intensity, -3.0);
    expect(rts.stations['x']!.pga, 3.0);
  });

  test('an empty frame falls back to defaults', () {
    final rts = Rts.fromJson({'ts': 5});

    expect(rts.stations, isEmpty);
    expect(rts.time, 5);
  });

  test('round-trips through toJson', () {
    final rts = Rts.fromJson({
      'ts': 123,
      'stations': {
        'x': {'i': 3.0, 'pga': 1.0, 'alert': 1},
      },
    });

    expect(Rts.fromJson(rts.toJson()), rts);
  });
}
