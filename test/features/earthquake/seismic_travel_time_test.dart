/// The travel-time table is what turns "seconds since origin" into a wave
/// front, and "kilometres from the epicentre" into an arrival.
///
/// A depth that is not a tabulated key must use the nearer key, including past
/// either end of the table. Interpolating between two rows is the normal case;
/// a front whose slope crosses back through zero must clamp to zero rather
/// than draw a negative radius, and a distance past the last row has no
/// arrival — returning a stale time there would say the wave already came.
/// A bundled file that is not gzip, or gzip of something that is not the
/// depth map, must fail the load: swallowing it would start the app with no
/// wave front and no arrival time.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dpip/features/earthquake/data/seismic_travel_time_source.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SeismicTravelTimeTable (loaded from the real asset — golden)', () {
    late SeismicTravelTimeTable table;

    setUpAll(() async {
      table = await const SeismicTravelTimeSource().load();
    });

    test('loads every tabulated focal depth', () {
      // 106 depths, 0–700 km.
      expect(table.rowsByDepth, hasLength(106));
      expect(table.rowsByDepth.containsKey(0), isTrue);
      expect(table.rowsByDepth.containsKey(700), isTrue);
    });

    test('waveRadius interpolates the P/S front radii', () {
      final w = table.waveRadius(0, const Duration(seconds: 1));
      expect(w.p, closeTo(4.82039, 1e-4));
      expect(w.s, closeTo(2.84857, 1e-4));
      expect(w.sT, 0); // S arrival time only set from the very first row
    });

    test('pWaveTime / sWaveTime interpolate arrival time (ms) by distance', () {
      expect(table.pWaveTime(0, 6), closeTo(1243.0, 1e-6));
      expect(table.sWaveTime(0, 6), closeTo(2099.0, 1e-6));
      expect(table.pWaveTime(0, 100), closeTo(17683.0, 1e-6));
    });
  });

  test('waveRadius clamps a front that interpolates back through zero', () {
    // Radius falls from +8 km to -8 km across 4 s, so t = 3 s is past the
    // zero crossing and the raw interpolation is -4 km for both fronts.
    const table = SeismicTravelTimeTable({
      0: [(p: 0, r: 8, s: 0), (p: 4, r: -8, s: 4)],
    });
    final w = table.waveRadius(0, const Duration(seconds: 3));
    expect(w.p, 0);
    expect(w.s, 0);
    expect(w.sT, 0);
  });

  test('a depth between keys, or past either end, uses the nearer depth', () {
    const shallow = [(p: 2.0, r: 10.0, s: 4.0)];
    const deep = [(p: 9.0, r: 10.0, s: 18.0)];
    const table = SeismicTravelTimeTable({0: shallow, 10: deep});

    expect(table.pWaveTime(4, 10), 2000, reason: '4 km is nearer 0 than 10');
    expect(table.pWaveTime(6, 10), 9000, reason: '6 km is nearer 10');
    expect(table.pWaveTime(-40, 10), 2000, reason: 'before the first key');
    expect(table.pWaveTime(80, 10), 9000, reason: 'past the last key');
  });

  test(
    'two rows interpolate radius and arrival, and past the last is zero',
    () {
      const table = SeismicTravelTimeTable({
        0: [(p: 0, r: 0, s: 0), (p: 10, r: 20, s: 20)],
      });

      final w = table.waveRadius(0, const Duration(seconds: 5));
      expect(w.p, 10);
      expect(w.s, 5);
      expect(w.sT, 0, reason: 'arrival time is only taken from the first row');

      expect(table.pWaveTime(0, 10), 5000);
      expect(table.sWaveTime(0, 10), 10000);
      expect(table.pWaveTime(0, 21), 0);
      expect(table.sWaveTime(0, 21), 0);
    },
  );

  test('a corrupt gzip or a JSON shape that is not the table throws', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    Future<void> serve(List<int> bytes) async {
      messenger.setMockMessageHandler('flutter/assets', (
        ByteData? message,
      ) async {
        return ByteData.sublistView(Uint8List.fromList(bytes));
      });
    }

    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

    await serve([1, 2, 3, 4]);
    await expectLater(
      const SeismicTravelTimeSource().load(),
      throwsA(isA<FormatException>()),
    );

    await serve(gzip.encode(utf8.encode('[]')));
    await expectLater(
      const SeismicTravelTimeSource().load(),
      throwsA(anything),
    );
  });

  test('an exact midpoint keeps the earlier tabulated depth', () {
    const shallow = [(p: 2.0, r: 10.0, s: 4.0)];
    const deep = [(p: 9.0, r: 10.0, s: 18.0)];
    const ordered = SeismicTravelTimeTable({0: shallow, 10: deep});
    // 5 km is equally far from 0 and 10. The walk keeps the earlier key.
    expect(ordered.pWaveTime(5, 10), 2000);

    // Insertion order is not depth order. A tie must still keep the key the
    // walk saw first, which is 10 here, not the smaller depth.
    const reversed = SeismicTravelTimeTable({10: deep, 0: shallow});
    expect(reversed.pWaveTime(5, 10), 9000);
    expect(
      reversed.pWaveTime(4, 10),
      2000,
      reason: '4 km is strictly nearer 0',
    );
  });

  test('travel time uses the first row when the distance is inside it', () {
    const table = SeismicTravelTimeTable({
      10: [(p: 1.5, r: 20, s: 3)],
    });
    expect(table.pWaveTime(10, 5), 1500);
    expect(table.sWaveTime(10, 5), 3000);
  });
}
