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

  /// Current feed freshness.
  RealtimeStatus get status => state.status;

  /// Whether the feed is fresh.
  bool get isLive => status == RealtimeStatus.live;

  /// Whether the feed has aged past the freshness threshold.
  bool get isStale => status == RealtimeStatus.stale;
}
