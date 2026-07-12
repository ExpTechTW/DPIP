import 'package:dpip/core/error/failure.dart';

/// The connection/freshness phase of a realtime feed.
///
/// [connecting] never had data yet and is still within the connect grace
/// window; [live] has fresh data; [stale] has data that has aged past the
/// freshness threshold (shown, but flagged); [offline] has aged past the
/// give-up threshold or never connected. For safety-critical feeds (EEW), a
/// consumer must treat [stale]/[offline] as "do not present as current".
enum RealtimeStatus { connecting, live, stale, offline }

/// An immutable snapshot of a realtime feed: its [status], the last successful
/// [data] (kept across transient failures), and the timestamps/failure needed
/// to reason about freshness.
///
/// Age is **computed on read** ([ageAt]) rather than stored, so two states with
/// the same [status]/[data]/[dataTime] are equal even when observed at
/// different instants — this is what lets the channel emit once per real
/// transition (not once per poll) while a "N seconds ago" label still advances.
class RealtimeState<T> {
  const RealtimeState({
    required this.status,
    this.data,
    this.dataTime,
    this.fetchedAt,
    this.lastFailure,
    this.consecutiveFailures = 0,
  });

  /// The seed state before the first poll completes.
  const RealtimeState.connecting()
    : status = RealtimeStatus.connecting,
      data = null,
      dataTime = null,
      fetchedAt = null,
      lastFailure = null,
      consecutiveFailures = 0;

  /// Current connection/freshness phase.
  final RealtimeStatus status;

  /// Last payload received successfully, or null if none yet. Retained across
  /// transient failures so the UI never blanks on a dropped poll.
  final T? data;

  /// Display timestamp of the current data — for EEW, the server time of the
  /// last successful fetch; for payload-timestamped feeds, the payload's own
  /// instant. Freshness ([status]) is measured monotonically by the channel,
  /// **not** derived from this wall-clock value, so [ageAt] here is a
  /// presentation aid, not the safety signal.
  final DateTime? dataTime;

  /// Absolute time of the last successful contact (diagnostics).
  final DateTime? fetchedAt;

  /// The most recent transport failure, for messaging; null after a success.
  final Failure? lastFailure;

  /// Count of consecutive failed polls; 0 after any success.
  final int consecutiveFailures;

  /// Whether any payload has been received.
  bool get hasData => data != null;

  /// How old [dataTime] is relative to [now], or null if no data yet.
  Duration? ageAt(DateTime now) =>
      dataTime == null ? null : now.difference(dataTime!);

  static const Object _unset = Object();

  RealtimeState<T> copyWith({
    RealtimeStatus? status,
    Object? data = _unset,
    Object? dataTime = _unset,
    Object? fetchedAt = _unset,
    Object? lastFailure = _unset,
    int? consecutiveFailures,
  }) {
    return RealtimeState<T>(
      status: status ?? this.status,
      data: identical(data, _unset) ? this.data : data as T?,
      dataTime: identical(dataTime, _unset)
          ? this.dataTime
          : dataTime as DateTime?,
      fetchedAt: identical(fetchedAt, _unset)
          ? this.fetchedAt
          : fetchedAt as DateTime?,
      lastFailure: identical(lastFailure, _unset)
          ? this.lastFailure
          : lastFailure as Failure?,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RealtimeState<T> &&
      other.status == status &&
      other.data == data &&
      other.dataTime == dataTime &&
      other.fetchedAt == fetchedAt &&
      other.lastFailure == lastFailure &&
      other.consecutiveFailures == consecutiveFailures;

  @override
  int get hashCode => Object.hash(
    status,
    data,
    dataTime,
    fetchedAt,
    lastFailure,
    consecutiveFailures,
  );

  @override
  String toString() =>
      'RealtimeState($status, hasData: $hasData, dataTime: $dataTime, '
      'failures: $consecutiveFailures)';
}
