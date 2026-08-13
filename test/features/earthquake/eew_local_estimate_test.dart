import 'dart:math' as math;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_local_estimate.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';
import 'package:flutter_test/flutter_test.dart';

/// Golden tests for the EEW local-shaking estimate the alert card renders.
///
/// `estimateLocalShaking` feeds the exact golden-pinned [EewEstimator] math, so
/// the card's numbers can never drift from the hazard overlays. These pin the
/// wiring (magnitude/depth/epicentre → observer point) with the same tight
/// tolerance as the estimator tests.
void main() {
  const epicenter = LatLng(23.5, 121.5);

  Eew eew({double mag = 6.0, double depth = 10}) => Eew(
    agency: 'CWA',
    id: 'test',
    serial: 3,
    status: 0,
    isFinal: false,
    info: EewInfo(
      time: 1786362600000,
      longitude: epicenter.longitude,
      latitude: epicenter.latitude,
      depth: depth,
      magnitude: mag,
      location: '花蓮縣',
      max: 4,
    ),
  );

  test(
    'far observer — PGA branch, discrete scale from continuous intensity',
    () {
      final estimate = estimateLocalShaking(eew(), const LatLng(25.03, 121.56));
      expect(estimate.distanceKm, closeTo(170.72074942953364, 1e-9));
      expect(estimate.intensity, closeTo(1.953358110252971, 1e-9));
      expect(estimate.scale, Intensity.toScale(estimate.intensity));
      expect(estimate.scale, 2); // 1.95 → CWA 2級
      expect(estimate.sArrivalSeconds, greaterThan(0));
    },
  );

  test('near observer — PGV branch kicks in above 4.5', () {
    final estimate = estimateLocalShaking(
      eew(mag: 6.5, depth: 8),
      const LatLng(23.7, 121.5),
    );
    expect(estimate.distanceKm, closeTo(23.657581474422642, 1e-9));
    expect(estimate.intensity, closeTo(5.086728964636149, 1e-9));
    expect(estimate.scale, Intensity.toScale(estimate.intensity));
    expect(estimate.scale, 6); // 5強
  });

  test(
    's-arrival queries the CWA table on epicentral distance when provided',
    () {
      const user = LatLng(24.0, 121.5);
      const depth = 30.0;
      final epicentral = epicenter.distanceTo(user) / 1000;
      final hypocentral = math.sqrt(epicentral * epicentral + depth * depth);

      final estimate = estimateLocalShaking(
        eew(depth: depth),
        user,
        table: _table,
      );
      expect(
        estimate.sArrivalSeconds,
        (_table.sWaveTime(depth, epicentral) / 1000).round(),
      );
      // The distance is the epicentral one the table's R column is defined on —
      // feeding hypocentral instead lands on a different interpolated row.
      expect(
        (_table.sWaveTime(depth, hypocentral) / 1000).round(),
        isNot(estimate.sArrivalSeconds),
      );
    },
  );
}

/// A CWA-style travel-time table for depths 10/30 km spanning Taiwan's extent.
const SeismicTravelTimeTable _table = SeismicTravelTimeTable({
  10: [
    (p: 5.0, r: 25.0, s: 10.0),
    (p: 10.0, r: 50.0, s: 20.0),
    (p: 15.0, r: 75.0, s: 30.0),
    (p: 20.0, r: 100.0, s: 40.0),
    (p: 30.0, r: 150.0, s: 60.0),
    (p: 40.0, r: 200.0, s: 80.0),
  ],
  30: [
    (p: 5.0, r: 25.0, s: 10.0),
    (p: 10.0, r: 50.0, s: 20.0),
    (p: 15.0, r: 75.0, s: 30.0),
    (p: 20.0, r: 100.0, s: 40.0),
  ],
});
