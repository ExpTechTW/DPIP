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
  /// ([onActionReceived]) and FCM-delivered taps (firebase's
  /// `onMessageOpenedApp` / `getInitialMessage`).
  static void route(NotificationTap tap) {
    final handler = onTap;
    if (handler != null) {
      handler(tap);
    } else {
      _pending = tap;
    }
  }

  /// awesome_notifications tap entry point (must be a top-level static method).
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction action) async {
    Log.debug('Notification tapped: channelKey=${action.channelKey}');
    route(NotificationTap.fromData(action.payload));
  }

  /// Replays a tap that arrived before [onTap] was registered (cold start).
  static void drainPending() {
    final tap = _pending;
    if (tap == null) return;
    _pending = null;
    onTap?.call(tap);
  }
}
