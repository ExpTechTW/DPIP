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

    test('loads the full depth × dist grid', () {
      expect(table.depth, hasLength(66));
      expect(table.depth.first, 0);
      expect(table.depth.last, 300);
      expect(table.dist, hasLength(96));
      expect(table.dist.last, 600);
      expect(table.p, hasLength(66));
      expect(table.p.first, hasLength(96));
      expect(table.sp, hasLength(66));
      expect(table.s, hasLength(66));
    });

    test('waveRadius interpolates the P/S front radii at the surface', () {
      final src = table.source(0);
      final w = src.waveRadius(const Duration(seconds: 1));
      expect(w.p, closeTo(4.82039, 1e-4));
      expect(w.s, closeTo(2.84857, 1e-4));
    });

    test('arrival interpolates the P/S travel times by distance', () {
      final src = table.source(0);
      expect(src.arrival(6).p * 1000, closeTo(1243.0, 1e-6));
      expect(src.arrival(6).s * 1000, closeTo(2099.0, 1e-6));
      expect(src.arrival(100).p * 1000, closeTo(17683.0, 1e-6));
    });

    test('depth interpolation blends between the tabulated rows', () {
      final mid = table.source(1).arrival(100).p;
      final d0 = table.source(0).arrival(100).p;
      final d2 = table.source(2).arrival(100).p;
      // 1 km is exactly half-way between the 0/2 km rows.
      expect(mid, closeTo((d0 + d2) / 2, 1e-6));
    });

    test('queries clamp to the table edges instead of throwing', () {
      final src = table.source(0);
      expect(src.arrival(10000).p, table.p.first.last);
      expect(src.waveRadius(const Duration(seconds: 100000)).p, 600);
      expect(src.waveRadius(Duration.zero).p, 0);
    });
  });

  test('waveRadius returns 0 until the wave reaches the surface (synthetic)', () {
    final table = SeismicTravelTimeTable(
      depth: [0, 2],
      dist: [0, 100],
      p: [
        [0, 10],
        [0.5, 10.5],
      ],
      sp: [
        [0, 2],
        [0.3, 2.3],
      ],
    );
    final w = table.source(0).waveRadius(Duration.zero);
    expect(w.p, 0);
    expect(w.s, 0);
  });
}
