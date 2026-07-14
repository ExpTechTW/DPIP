import 'package:dpip/features/earthquake/data/seismic_travel_time_source.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
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

  test('waveRadius clamps a negative interpolation to zero (synthetic)', () {
    // A single row so no interpolation happens and both fronts are 0 for t=0.
    const table = SeismicTravelTimeTable({
      0: [(p: 0, r: 0, s: 0)],
    });
    final w = table.waveRadius(0, Duration.zero);
    expect(w.p, 0);
    expect(w.s, 0);
  });
}
