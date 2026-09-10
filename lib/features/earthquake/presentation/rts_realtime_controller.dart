import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';

/// Provider-facing view of the live RTS feed: a distinct [ChangeNotifier] type
/// widgets can `watch`, with RTS-specific getters over the realtime state.
///
/// Consumers must respect [status] — a [RealtimeStatus.stale]/[offline] feed
/// means the shaking snapshot may no longer be current and must not be shown as
/// live.
class RtsRealtimeController extends RealtimeNotifier<Rts> {
  RtsRealtimeController(super.channel);

  /// The latest shaking snapshot, or null before the first arrives.
  Rts? get rts => state.data;

  /// Live station intensities keyed by station id; empty before any snapshot.
  Map<String, RtsStation> get stations => state.data?.station ?? const {};

  /// Live box-grid intensities keyed by box id (as a string); only non-empty
  /// for a large event the feed reports at box-grid resolution.
  Map<String, dynamic> get box => state.data?.box ?? const {};

  /// Current feed freshness.
  RealtimeStatus get status => state.status;

  /// Whether the feed is fresh.
  bool get isLive => status == RealtimeStatus.live;

  /// Whether the feed has aged past the freshness threshold.
  bool get isStale => status == RealtimeStatus.stale;

  /// Whether the last poll found no snapshot for the instant it asked for.
  ///
  /// Only a replay reaches this: RTS snapshots are retained for far less time
  /// than the EEW history, so an old enough event still has alerts to replay
  /// and no shaking left to draw. The feed is not broken, so a UI must not call
  /// it disconnected — there is simply nothing recorded that far back.
  bool get isMissingHistory => state.lastFailure is NotFoundFailure;
}
