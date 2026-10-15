import 'dart:math' as math;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/features/earthquake/domain/eew_local_estimate.dart';
import 'package:dpip/shared/seismic/intensity.dart';
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
      expect(estimate.scale, 2);
      expect(estimate.sArrival, greaterThan(Duration.zero));
      final again = estimateLocalShaking(eew(), const LatLng(25.03, 121.56));
      expect(identical(again, estimate), isTrue);
    },
  );

  test('too far is level 0, and without a table the arrival is analytic', () {
    final user = const LatLng(0, 0);
    final estimate = estimateLocalShaking(eew(mag: 4, depth: 20), user);
    final epicentral = epicenter.distanceTo(user) / 1000;

    expect(estimate.scale, 0);
    expect(
      estimate.sArrival,
      Duration(
        milliseconds: (EewEstimator.waveTime(20, epicentral).s * 1000).round(),
      ),
    );
  });

  test('the same place shakes less when the focus is deep', () {
    const user = LatLng(23.7, 121.5);
    final shallow = estimateLocalShaking(eew(mag: 6.5, depth: 10), user);
    final deep = estimateLocalShaking(eew(mag: 6.5, depth: 300), user);

    expect(shallow.scale, greaterThan(deep.scale));
    expect(deep.distanceKm, greaterThan(shallow.distanceKm));
  });

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
        estimate.sArrival,
        Duration(milliseconds: _table.sWaveTime(depth, epicentral).round()),
      );
      // The distance is the epicentral one the table's R column is defined on —
      // feeding hypocentral instead lands on a different interpolated row.
      expect(
        Duration(milliseconds: _table.sWaveTime(depth, hypocentral).round()),
        isNot(estimate.sArrival),
      );
    },
  );

  test(
    'the arrival keeps its milliseconds instead of rounding to a second',
    () {
      // A table whose S time to the observer lands mid-second: 12.34 s.
      const table = SeismicTravelTimeTable({
        10: [(p: 0, r: 0, s: 0), (p: 7.0, r: 40, s: 12.34)],
      });
      final estimate = estimateLocalShaking(
        eew(),
        LatLng(epicenter.latitude + 20 / 111.19492664455873, 121.5),
        table: table,
      );
      expect(estimate.sArrival.inMilliseconds, closeTo(6170, 20));
      expect(estimate.sArrival.inMilliseconds % 1000, isNot(0));
    },
  );

  group('SWaveCountdown', () {
    final arrival = DateTime.utc(2026, 10, 16, 3, 0, 12, 340);
    final countdown = SWaveCountdown(arrival);

    test('arrived switches exactly at the computed instant, never later', () {
      expect(
        countdown.arrivedAt(arrival.subtract(const Duration(microseconds: 1))),
        isFalse,
      );
      expect(countdown.arrivedAt(arrival), isTrue);
      expect(
        countdown.arrivedAt(arrival.add(const Duration(hours: 1))),
        isTrue,
      );
    });

    test('seconds left round up — 1 until arrival, never 0 while inbound', () {
      expect(
        countdown.secondsLeftAt(
          arrival.subtract(const Duration(milliseconds: 1)),
        ),
        1,
      );
      expect(
        countdown.secondsLeftAt(arrival.subtract(const Duration(seconds: 1))),
        1,
      );
      expect(
        countdown.secondsLeftAt(
          arrival.subtract(const Duration(seconds: 1, milliseconds: 1)),
        ),
        2,
      );
      expect(
        countdown.secondsLeftAt(arrival.subtract(const Duration(seconds: 10))),
        10,
      );
      expect(countdown.secondsLeftAt(arrival), 0);
      expect(
        countdown.secondsLeftAt(arrival.add(const Duration(seconds: 3))),
        0,
      );
    });

    test('the next change lands on a whole second before the arrival', () {
      // 4.66 s out: the shown 5 becomes 4 in 0.66 s, at arrival − 4 s.
      final now = arrival.subtract(const Duration(milliseconds: 4660));
      final next = countdown.untilNextChangeAt(now)!;
      expect(next, const Duration(milliseconds: 660));
      expect(countdown.secondsLeftAt(now), 5);
      expect(countdown.secondsLeftAt(now.add(next)), 4);
      // On a boundary itself, the next change is a full second away.
      final onBoundary = arrival.subtract(const Duration(seconds: 3));
      expect(
        countdown.untilNextChangeAt(onBoundary),
        const Duration(seconds: 1),
      );
      // The last change is "arrived" itself.
      final last = arrival.subtract(const Duration(milliseconds: 250));
      expect(last.add(countdown.untilNextChangeAt(last)!), arrival);
      expect(countdown.untilNextChangeAt(arrival), isNull);
    });

    test('of() adds the travel time to the origin', () {
      final estimate = EewLocalEstimate(
        distanceKm: 0,
        intensity: 0,
        scale: 0,
        sArrival: const Duration(milliseconds: 12340),
      );
      expect(
        SWaveCountdown.of(eew(), estimate).arrival,
        DateTime.fromMillisecondsSinceEpoch(1786362612340, isUtc: true),
      );
    });
  });
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
