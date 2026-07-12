import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/logging/log.dart';

/// Carries a notification tap from awesome_notifications to the app's router.
///
/// awesome delivers taps to a top-level static handler that can fire before the
/// UI/router exists (a cold start launched by a tap), so [onActionReceived]
/// either routes immediately via the live [onTap] callback or stashes the
/// channel key for [drainPending] to replay once the app is ready. The
/// channel-key → route mapping lives in the app layer (which owns the router);
/// this only carries the intent, keeping `core` free of route knowledge.
abstract final class NotificationTaps {
  const NotificationTaps._();

  /// Set by the app layer to route a tapped channel key to a screen.
  static void Function(String channelKey)? onTap;

  static String? _pending;

  /// awesome_notifications tap entry point (must be a top-level static method).
  @pragma('vm:entry-point')
  static Future<void> onActionReceived(ReceivedAction action) async {
    final channelKey = action.channelKey;
    Log.debug('Notification tapped: channelKey=$channelKey');
    if (channelKey == null) return;
    final handler = onTap;
    if (handler != null) {
      handler(channelKey);
    } else {
      _pending = channelKey;
    }
  }

  /// Replays a tap that arrived before [onTap] was registered (cold start).
  static void drainPending() {
    final channelKey = _pending;
    if (channelKey == null) return;
    _pending = null;
    onTap?.call(channelKey);
  }
}
