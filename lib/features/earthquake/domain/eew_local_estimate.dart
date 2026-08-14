import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/features/earthquake/domain/intensity.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';

/// The EEW shaking estimate for one observer location.
///
/// Derived purely from [EewEstimator] so the alert card's numbers are the same
/// golden-pinned math the map's hazard overlays use — never a second,
/// hand-rolled approximation. [distanceKm] is hypocentral (surface + depth);
/// [sArrivalSeconds] is the estimated S-wave travel time from the origin, so
/// arrival = origin + this many seconds.
class EewLocalEstimate {
  const EewLocalEstimate({
    required this.distanceKm,
    required this.intensity,
    required this.scale,
    required this.sArrivalSeconds,
  });

  /// Hypocentral distance in kilometres.
  final double distanceKm;

  /// Continuous felt intensity.
  final double intensity;

  /// Discrete CWA felt intensity (0–9, see [Intensity.toScale]).
  final int scale;

  /// Estimated S-wave travel time in seconds from the earthquake origin.
  final int sArrivalSeconds;
}

/// Estimates local shaking for [eew] at [user].
///
/// Null-returning is deliberate: the estimate is meaningless without a
/// concrete observer point, so callers pass the selected township's centroid
/// and skip the estimate entirely when no location is resolvable (全國 or a
/// 所在地 with no GPS fix) rather than inventing a default.
///
/// [sArrivalSeconds] comes from the **CWA travel-time table** ([table], the
/// same source the map's wave circles use) when it has resolved — the legacy
/// app's `sWaveTimeByDistance` query, matched on **epicentral** distance so
/// "arrived" and the wave front on the map agree. Until the table loads (a
/// near-instant asset read) it falls back to the analytic approximation, so a
/// card never waits blank; the value settles to the table's the moment the
/// future resolves.
EewLocalEstimate estimateLocalShaking(
  Eew eew,
  LatLng user, {
  SeismicTravelTimeTable? table,
}) {
  final location = EewEstimator.locationInfo(
    mag: eew.info.magnitude,
    depth: eew.info.depth,
    epicenter: eew.info.latlng,
    user: user,
  );
  // The S-wave arrival is measured from the origin to the **epicentral**
  // distance — the same table the map's wave circles use, so "arrived" and the
  // wave front on the map agree (legacy's `sWaveTimeByDistance`).
  final epicentral = eew.info.latlng.distanceTo(user) / 1000;
  final sArrivalSeconds = table == null
      ? EewEstimator.waveTime(eew.info.depth, epicentral).s.round()
      : (table.sWaveTime(eew.info.depth, epicentral) / 1000).round();
  return EewLocalEstimate(
    distanceKm: location.dist,
    intensity: location.i,
    scale: Intensity.toScale(location.i),
    sArrivalSeconds: sArrivalSeconds,
  );
}
