import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';

/// The EEW shaking estimate for one observer location.
///
/// Derived purely from [EewEstimator] so the alert card's numbers are the same
/// golden-pinned math the map's hazard overlays use — never a second,
/// hand-rolled approximation. [distanceKm] is hypocentral (surface + depth);
/// [sArrival] is the estimated S-wave travel time from the origin, so
/// arrival = origin + [sArrival] (see [SWaveCountdown]).
class EewLocalEstimate {
  const EewLocalEstimate({
    required this.distanceKm,
    required this.intensity,
    required this.scale,
    required this.sArrival,
  });

  /// Hypocentral distance in kilometres.
  final double distanceKm;

  /// Continuous felt intensity.
  final double intensity;

  /// Discrete CWA felt intensity (0–9, see [Intensity.toScale]).
  final int scale;

  /// Estimated S-wave travel time from the earthquake origin, to the
  /// millisecond.
  ///
  /// Never rounded to a whole second: it used to be, and the cards then
  /// truncated what was left with `inSeconds` on a tick that was not aligned
  /// to anything, so "arrived" could show up to a second early or late
  /// depending on where the rounding and the tick happened to fall. Rounding
  /// is the display's business, once, at the edge ([SWaveCountdown]).
  final Duration sArrival;
}

/// One observer's S-wave arrival as a countdown — the single place the
/// "arrived" instant and the seconds shown are decided, so every card counts
/// the same way.
class SWaveCountdown {
  const SWaveCountdown(this.arrival);

  /// The countdown to [estimate]'s arrival for [eew].
  factory SWaveCountdown.of(Eew eew, EewLocalEstimate estimate) =>
      SWaveCountdown(
        DateTime.fromMillisecondsSinceEpoch(
          eew.info.time,
          isUtc: true,
        ).add(estimate.sArrival),
      );

  /// When the S wave reaches the observer.
  final DateTime arrival;

  /// Whether the S wave has arrived at [now] — true from the computed instant
  /// itself onwards, never a moment later.
  bool arrivedAt(DateTime now) => !now.isBefore(arrival);

  /// Whole seconds left at [now], rounded **up**: a countdown reads 1 until
  /// the instant of arrival and 0 only from it. Rounding down would read 0 for
  /// the last second while the wave was still on its way.
  int secondsLeftAt(DateTime now) {
    final left = arrival.difference(now).inMicroseconds;
    if (left <= 0) return 0;
    return (left + _microsPerSecond - 1) ~/ _microsPerSecond;
  }

  /// How long after [now] [secondsLeftAt] next changes — the instant a
  /// display has to redraw to stay exact — or null once arrived, when it
  /// never changes again.
  Duration? untilNextChangeAt(DateTime now) {
    final left = arrival.difference(now).inMicroseconds;
    if (left <= 0) return null;
    final intoSecond = left % _microsPerSecond;
    return Duration(
      microseconds: intoSecond == 0 ? _microsPerSecond : intoSecond,
    );
  }

  static const int _microsPerSecond = 1000000;

  @override
  bool operator ==(Object other) =>
      other is SWaveCountdown && other.arrival == arrival;

  @override
  int get hashCode => arrival.hashCode;
}

/// Estimates local shaking for [eew] at [user].
///
/// Null-returning is deliberate: the estimate is meaningless without a
/// concrete observer point, so callers pass the selected township's centroid
/// and skip the estimate entirely when no location is resolvable (全國 or a
/// 所在地 with no GPS fix) rather than inventing a default.
///
/// [EewLocalEstimate.sArrival] comes from the **CWA travel-time table**
/// ([table], the
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
  // One-entry memo. Every alert card (home, monitor, list) recomputes this on
  // its one-second countdown tick, and the inputs only move when a new serial
  // arrives or the observer moves: two haversines, the attenuation law and a
  // travel-time table scan per tick per card, for the same answer. `Eew` and
  // `LatLng` are value types, so equality is the exact "same inputs" test;
  // the table is compared by identity because it is a loaded asset that never
  // changes in place.
  final last = _last;
  if (last != null &&
      last.eew == eew &&
      last.user == user &&
      identical(last.table, table)) {
    return last.estimate;
  }
  final estimate = _estimate(eew, user, table);
  _last = (eew: eew, user: user, table: table, estimate: estimate);
  return estimate;
}

({
  Eew eew,
  LatLng user,
  SeismicTravelTimeTable? table,
  EewLocalEstimate estimate,
})?
_last;

EewLocalEstimate _estimate(
  Eew eew,
  LatLng user,
  SeismicTravelTimeTable? table,
) {
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
  final sArrivalMs = table == null
      ? EewEstimator.waveTime(eew.info.depth, epicentral).s * 1000
      : table.sWaveTime(eew.info.depth, epicentral);
  return EewLocalEstimate(
    distanceKm: location.dist,
    intensity: location.i,
    scale: Intensity.toScale(location.i),
    sArrival: Duration(milliseconds: sArrivalMs.round()),
  );
}
