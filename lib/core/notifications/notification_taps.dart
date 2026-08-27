import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_tap.dart';

/// Carries a notification tap from awesome_notifications to the app's router.
///
/// awesome delivers taps to a top-level static handler that can fire before the
/// UI/router exists (a cold start launched by a tap), so [route] either routes
/// immediately via the live [onTap] callback or stashes the [NotificationTap]
/// for [drainPending] to replay once the app is ready. The tap → route mapping
/// lives in the app layer (which owns the router); this only carries the intent
/// (channel + id), keeping `core` free of route knowledge.
abstract final class NotificationTaps {
  const NotificationTaps._();

  /// Set by the app layer to route a tap to a screen.
  static void Function(NotificationTap tap)? onTap;

  static NotificationTap? _pending;

  /// Routes [tap] now via [onTap], or stashes it for [drainPending] if the app /
  /// router isn't ready yet (cold start). Shared by awesome-displayed taps
  /// ([onActionReceived]). Firebase's `onMessageOpenedApp` /
  /// `getInitialMessage` no longer feed this: push is owned by
  /// awesome_notifications_fcm, so every notification the user can tap was
  /// displayed by awesome and arrives through [onActionReceived].
  static void route(NotificationTap tap) {
    final handler = onTap;
    if (handler != null) {
      Log.info('Notification tap: routing now, channel=${tap.channelKey}');
      handler(tap);
    } else {
      Log.info(
        'Notification tap: router not ready, stashing channel=${tap.channelKey}',
      );
      _pending = tap;
    }
  }

  /// awesome_notifications tap entry point (must be a top-level static method).
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction action) async {
    // The channel comes off the action, not the payload — see
    // [NotificationTap.fromData] for why the payload is empty on a push.
    final tap = NotificationTap.fromData(
      action.payload,
      channelKey: action.channelKey,
    );
    // The resolved map, not just its keys. `payload=[]` was the whole symptom
    // of the iOS deep link never firing, and a list of key names could not show
    // that the values behind them were the ones routing depends on.
    Log.info(
      'Notification tapped: channel=${tap.channelKey} id=${tap.id} '
      'data=${tap.data} lifeCycle=${action.actionLifeCycle?.name}',
    );
    Log.debug('Notification raw payload: ${action.payload}');
    route(tap);
  }

  /// Replays a tap that arrived before [onTap] was registered (cold start).
  static void drainPending() {
    final tap = _pending;
    if (tap == null) return;
    _pending = null;
    Log.info('Notification tap: replaying stashed channel=${tap.channelKey}');
    onTap?.call(tap);
  }
}
