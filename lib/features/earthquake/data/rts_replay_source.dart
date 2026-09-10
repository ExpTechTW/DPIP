import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/core/realtime/replay_clock.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';

/// Replays the RTS feed at a fixed point in the past — a plain **polling**
/// source (not SSE): each [fetch] asks [EarthquakeApi.getRtsAt] for the
/// snapshot at the current second of [clock], which ticks 1:1 with real time
/// from its start instant. Everything else (the channel, state model,
/// staleness) is the same spine the live [RtsRealtimeSource] uses — a replay
/// session just points it at a different source.
class RtsReplaySource extends RealtimeSource<Rts> {
  RtsReplaySource(this._api, this.clock);

  final EarthquakeApi _api;

  /// Ticks forward from the replay's start instant; owned by the caller (one
  /// per replay session) so pausing/resuming the page doesn't affect it here.
  final ReplayClock clock;

  @override
  Future<Result<Rts>> fetch() => guardResult(() async {
    final seconds = clock.now().millisecondsSinceEpoch ~/ 1000;
    final json = await _api.getRtsAt(seconds);
    return Rts.fromJson(json as Map<String, dynamic>);
  }, shouldLog: (failure) => !isIgnorableFailure(failure));

  /// A 404 is the ordinary shape of an old replay, not a fault: RTS snapshots
  /// are retained for far less time than the EEW history, so an event old
  /// enough (0403, say) still has alerts to replay and no shaking left to draw.
  /// Counted as a failure it would be one crash report and one log line **per
  /// second** for the whole session — the poll runs at 1 Hz, which never trips
  /// `Log`'s repeat suppression (8 within 5s).
  @override
  bool isIgnorableFailure(Failure failure) => failure is NotFoundFailure;

  /// Null: freshness is "did the last poll succeed", not payload age — the
  /// payload's own [Rts.time] is *intentionally* historical, so keying off it
  /// would immediately (and wrongly) read as stale.
  @override
  DateTime? timestampOf(Rts value) => null;
}
