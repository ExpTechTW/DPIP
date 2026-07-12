import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys. The token can be written from a background isolate
/// (token refresh), so it lives in persistent storage, not memory.
const String _tokenKey = 'notification.pushToken';
const String _channelVersionKey = 'notification.channelVersion';

/// Fallback channel for a message with no/unknown `channel` — must be a
/// registered channel or the OS rejects the notification.
const String _fallbackChannelKey = 'announcement-general-v2';

/// Sets up push notifications.
///
/// `firebase_messaging` owns the FCM/APNs transport (token + message receipt) on
/// both platforms, and `awesome_notifications` renders the rich per-channel
/// notification and routes taps. (The legacy app used `awesome_notifications_fcm`
/// on Android, but that plugin's iOS pod is incompatible with the rewrite's
/// newer Flutter/scene lifecycle — one FCM plugin is simpler and builds cleanly.)
///
/// Message flow: the backend sends **data** messages (`channel`/`id`/`title`/
/// `body`). Foreground messages and background data-only messages are displayed
/// via awesome so every notification honours its channel; taps funnel through
/// [NotificationTaps]. A `notification`-payload message is displayed by the OS
/// directly (its tap arrives via `onMessageOpenedApp`).
class NotificationService {
  NotificationService(this._prefs);

  final SharedPreferences _prefs;

  /// The last push token, or null before registration.
  String? get token => _prefs.getString(_tokenKey);

  /// Whether the OS has granted notification permission.
  Future<bool> isAllowed() => AwesomeNotifications().isNotificationAllowed();

  /// Initializes channels, the tap listener, and the FCM/APNs transport. Call
  /// once at start-up; safe to await best-effort (a failure just means no push).
  Future<void> init() async {
    await _initChannels();
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationTaps.onActionReceived,
    );
    await _initMessaging();
  }

  /// Requests OS notification permission if not already granted; returns whether
  /// it is now allowed. Includes the **critical-alert** permission (guarded by
  /// the app's `usernotifications.critical-alerts` entitlement) so EEW alerts can
  /// override silent/Do-Not-Disturb. Call from a screen (e.g. onboarding), not at
  /// launch.
  Future<bool> requestPermission() async {
    if (await AwesomeNotifications().isNotificationAllowed()) return true;
    return AwesomeNotifications().requestPermissionToSendNotifications(
      permissions: const [
        NotificationPermission.Alert,
        NotificationPermission.Sound,
        NotificationPermission.Badge,
        NotificationPermission.Vibration,
        NotificationPermission.Light,
        NotificationPermission.CriticalAlert,
      ],
    );
  }

  Future<void> _initChannels() async {
    await AwesomeNotifications().initialize(
      NotificationChannels.icon,
      NotificationChannels.channels,
      channelGroups: NotificationChannels.groups,
      debug: kDebugMode,
    );

    // Android caches channel settings after first creation; force-update them
    // when the catalogue version changes.
    final stored = _prefs.getInt(_channelVersionKey) ?? 0;
    if (stored < NotificationChannels.version) {
      for (final channel in NotificationChannels.channels) {
        try {
          await AwesomeNotifications().setChannel(channel, forceUpdate: true);
        } catch (error, stackTrace) {
          Log.handle(error, stackTrace, 'setChannel ${channel.channelKey}');
        }
      }
      await _prefs.setInt(_channelVersionKey, NotificationChannels.version);
    }
  }

  Future<void> _initMessaging() async {
    final messaging = FirebaseMessaging.instance;

    FirebaseMessaging.onBackgroundMessage(onBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final content = contentFromMessage(message);
      if (content != null) {
        AwesomeNotifications().createNotification(content: content);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _routeTap(m.data));

    final initial = await messaging.getInitialMessage();
    if (initial != null) _routeTap(initial.data);

    messaging.onTokenRefresh.listen((token) {
      Log.debug('Push token refreshed');
      _prefs.setString(_tokenKey, token);
    });
    try {
      final token = await messaging.getToken();
      if (token != null) await _prefs.setString(_tokenKey, token);
    } catch (error, stackTrace) {
      // On iOS getToken can fail until the APNs token is ready; onTokenRefresh
      // then supplies it.
      Log.handle(error, stackTrace, 'getToken (APNs may not be ready)');
    }
  }

  void _routeTap(Map<String, dynamic> data) {
    final channelKey = data['channel'] as String?;
    if (channelKey != null) NotificationTaps.route(channelKey);
  }
}

/// Builds notification content from a message's `data` (preferred, legacy
/// format) falling back to its `notification` block, or null when there's
/// nothing to show.
NotificationContent? contentFromMessage(RemoteMessage message) {
  final data = message.data;
  final notification = message.notification;
  final title = (data['title'] as String?) ?? notification?.title;
  final body = (data['body'] as String?) ?? notification?.body;
  if (title == null && body == null) return null;
  return NotificationContent(
    id: int.tryParse((data['id'] as String?) ?? '') ?? 0,
    channelKey: (data['channel'] as String?) ?? _fallbackChannelKey,
    title: title,
    body: body,
    wakeUpScreen: true,
    category: NotificationCategory.Alarm,
  );
}

/// Displays a background/terminated **data-only** message via awesome (a
/// `notification`-payload message is shown by the OS itself). Runs on a
/// background isolate, so awesome must be initialized here before use.
@pragma('vm:entry-point')
Future<void> onBackgroundMessage(RemoteMessage message) async {
  if (message.notification != null) return;
  final content = contentFromMessage(message);
  if (content == null) return;
  await AwesomeNotifications().initialize(
    NotificationChannels.icon,
    NotificationChannels.channels,
    channelGroups: NotificationChannels.groups,
  );
  await AwesomeNotifications().createNotification(content: content);
}
