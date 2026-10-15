import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_priority.dart';

/// Provider-facing view of the live EEW feed: a distinct [ChangeNotifier] type
/// widgets can `watch`, with EEW-specific getters over the realtime state.
///
/// Consumers must respect [status] — an [RealtimeStatus.stale]/[offline] feed
/// means the alerts may no longer be current and must not be shown as live.
class EewRealtimeController extends RealtimeNotifier<List<Eew>> {
  EewRealtimeController(super.channel);

  /// Active EEW alerts, newest first; empty when there is no alert.
  List<Eew> get alerts => state.data ?? const [];

  /// The most relevant alert, or null when there is none — ranked without an
  /// observer ([primaryEew]): an alert in progress before a cancelled one,
  /// then the highest maximum intensity, then the newest report.
  Eew? get primaryAlert => primaryEew(alerts);

  /// Current feed freshness.
  RealtimeStatus get status => state.status;

  /// Whether the feed is fresh.
  bool get isLive => status == RealtimeStatus.live;

  /// Whether the feed has aged past the freshness threshold.
  bool get isStale => status == RealtimeStatus.stale;
}
