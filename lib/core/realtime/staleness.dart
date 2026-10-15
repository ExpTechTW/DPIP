import 'package:dpip/core/realtime/realtime_state.dart';

/// Classifies a realtime feed's freshness — the one safety-critical decision in
/// the spine, kept pure and total so it is golden-pinned like the EEW estimator.
///
/// Works in **elapsed durations, not absolute instants**, so the caller can (and
/// does) supply a monotonic measurement immune to clock changes:
/// - [age] is how long since the current data was fresh (null = no data yet).
///   The channel measures this monotonically, so a device-clock jump or server
///   resync can never make a dead feed look live.
/// - [sinceStart] is how long polling has been running with no data, used to
///   distinguish "still trying" from "gave up".
///
/// A negative [age] (data timestamped in the future — a clock anomaly) is treated
/// as **not current**: the classifier fails toward [RealtimeStatus.stale] rather
/// than presenting possibly-bad data as live.
///
/// [fallback] marks data delivered by a feed's secondary path — an SSE feed
/// answering from a periodic REST snapshot while its stream reconnects. Such
/// data is real and recent, so it is shown rather than blanked, but it is at
/// best [RealtimeStatus.stale], never [RealtimeStatus.live]: `live` promises
/// that a change reaches the screen within the feed's own latency, and a
/// snapshot taken every few seconds cannot keep that promise however fresh the
/// last one was. It still ages to offline on the same schedule.
RealtimeStatus classifyStatus({
  required Duration? age,
  required Duration sinceStart,
  required Duration staleAfter,
  required Duration offlineAfter,
  bool fallback = false,
}) {
  if (age == null) {
    return sinceStart <= offlineAfter
        ? RealtimeStatus.connecting
        : RealtimeStatus.offline;
  }
  if (age.isNegative) return RealtimeStatus.stale;
  if (age <= staleAfter) {
    return fallback ? RealtimeStatus.stale : RealtimeStatus.live;
  }
  if (age <= offlineAfter) return RealtimeStatus.stale;
  return RealtimeStatus.offline;
}
