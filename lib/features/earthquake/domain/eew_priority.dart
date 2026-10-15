/// Which of several simultaneous alerts matters most to the person looking —
/// the one the Home card shows and the monitor reads aloud.
///
/// The feed's own order is no order at all: the edge builds each snapshot by
/// walking a hash table, so "the first alert" was whichever event happened to
/// hash first. With two events up at once — an aftershock during a main
/// shock, two agencies' reports of one sequence — that put a distant M4 on the
/// Home card while an M6 whose S wave had not reached the user yet sat second.
library;

import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_local_estimate.dart';
import 'package:dpip/features/earthquake/domain/seismic_travel_time.dart';

/// One alert as [rankEews] weighed it.
class RankedEew {
  const RankedEew(this.alert, {this.estimate});

  final Eew alert;

  /// The shaking estimated at the observer — null without an observer, and
  /// always null for a cancelled alert, which has none.
  final EewLocalEstimate? estimate;

  /// When the S wave reaches the observer, or null without an [estimate].
  DateTime? get arrival {
    final estimate = this.estimate;
    if (estimate == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      alert.info.time,
      isUtc: true,
    ).add(Duration(seconds: estimate.sArrivalSeconds));
  }

  /// Whether the S wave has reached the observer by [now]. False when that is
  /// unknown.
  bool arrivedAt(DateTime now) {
    final arrival = this.arrival;
    return arrival != null && !now.isBefore(arrival);
  }
}

/// [alerts] most-relevant first, for an observer at [observer] (null when
/// there is no point to estimate for) at [now].
///
/// Arrival is weighed only with both an [observer] and a [now]; without an
/// observer there is no arrival to judge and [now] may be left out.
///
/// In order of precedence:
/// 1. an alert still in progress before a cancelled one;
/// 2. one whose S wave has not reached the observer yet before one whose has
///    — the only alerts there is still time to act on;
/// 3. the higher estimated shaking at the observer (the agency's own maximum
///    intensity when there is no observer);
/// 4. the newer report.
///
/// Ties keep the feed's order, so the result is deterministic.
List<RankedEew> rankEews(
  List<Eew> alerts, {
  DateTime? now,
  LatLng? observer,
  SeismicTravelTimeTable? table,
}) {
  final entries = [
    for (final (index, alert) in alerts.indexed)
      (
        index: index,
        ranked: RankedEew(
          alert,
          estimate: observer == null || alert.isCancelled
              ? null
              : estimateLocalShaking(alert, observer, table: table),
        ),
      ),
  ];
  int byFlag(bool a, bool b) => a == b ? 0 : (a ? 1 : -1);
  entries.sort((a, b) {
    final x = a.ranked;
    final y = b.ranked;
    final cancelled = byFlag(x.alert.isCancelled, y.alert.isCancelled);
    if (cancelled != 0) return cancelled;
    if (now != null) {
      final arrived = byFlag(x.arrivedAt(now), y.arrivedAt(now));
      if (arrived != 0) return arrived;
    }
    final shaking = _shaking(y).compareTo(_shaking(x));
    if (shaking != 0) return shaking;
    final newer = _issued(y.alert).compareTo(_issued(x.alert));
    if (newer != 0) return newer;
    return a.index.compareTo(b.index);
  });
  return [for (final entry in entries) entry.ranked];
}

/// The most relevant of [alerts] (see [rankEews]), or null when there are
/// none.
Eew? primaryEew(
  List<Eew> alerts, {
  DateTime? now,
  LatLng? observer,
  SeismicTravelTimeTable? table,
}) {
  if (alerts.isEmpty) return null;
  return rankEews(
    alerts,
    now: now,
    observer: observer,
    table: table,
  ).first.alert;
}

double _shaking(RankedEew ranked) =>
    ranked.estimate?.intensity ?? ranked.alert.info.max.toDouble();

int _issued(Eew alert) => alert.reportTime ?? alert.info.time;
