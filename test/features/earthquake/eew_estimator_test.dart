import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests for the safety-critical EEW math.
///
/// The estimator's doc claims it is "algebraically identical" to the original
/// but nothing verified it — a silent arithmetic regression here produces a
/// wrong intensity or wrong P/S arrival second with no crash. These pin the
/// current outputs at tight tolerance so any change to the arithmetic fails CI
/// loudly. Update a golden only with a deliberate, reviewed reason.
void main() {
  const epicenter = LatLng(23.5, 121.5);
  const tol = 1e-9;

  group('EewEstimator', () {
    test('areaPgv (PGV attenuation intensity)', () {
      expect(
        EewEstimator.areaPgv(epicenter, const LatLng(25.03, 121.56), 10, 6.0),
        closeTo(2.330238583058274, tol),
      );
    });

    test('locationInfo far — PGA branch (i < 4.5)', () {
      final r = EewEstimator.locationInfo(
        mag: 6.0,
        depth: 10,
        epicenter: epicenter,
        user: const LatLng(25.03, 121.56),
      );
      expect(r.dist, closeTo(170.72074942953364, tol));
      expect(r.i, closeTo(1.953358110252971, tol));
    });

    test('locationInfo near — switches to PGV branch (i >= 4.5)', () {
      final r = EewEstimator.locationInfo(
        mag: 6.5,
        depth: 8,
        epicenter: epicenter,
        user: const LatLng(23.7, 121.5),
      );
      expect(r.dist, closeTo(23.657581474422642, tol));
      expect(r.i, closeTo(5.086728964636149, tol));
    });

    test('waveTime P/S arrival seconds', () {
      final w1 = EewEstimator.waveTime(10, 100);
      expect(w1.p, closeTo(17.51319831072981, tol));
      expect(w1.s, closeTo(30.33374927721346, tol));

      // Far/deep case hits the velocity caps (distance/7, distance/4).
      final w2 = EewEstimator.waveTime(50, 200);
      expect(w2.p, closeTo(28.571428571428573, tol));
      expect(w2.s, closeTo(50.0, tol));
    });

    test('areaPga per-region + max intensity', () {
      final r = EewEstimator.areaPga(
        epicenter: epicenter,
        depth: 10,
        mag: 6.0,
        regionCentroids: const {
          'a': LatLng(24.0, 121.5),
          'b': LatLng(25.0, 121.5),
        },
      );
      expect(r.maxIntensity, closeTo(3.4955850378038695, tol));
      expect(r.regions['a']!.i, closeTo(3.4955850378038695, tol));
      expect(r.regions['b']!.i, closeTo(1.9817905219210137, tol));
    });

    test('Intensity.fromPga', () {
      expect(Intensity.fromPga(50), closeTo(4.097940008672037, tol));
      expect(Intensity.fromPga(0.5), closeTo(0.09794000867203767, tol));
    });
  });
}
