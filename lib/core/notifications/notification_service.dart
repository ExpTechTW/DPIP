import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_tap.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
  NotificationService(this._settings);

  final SettingsStore _settings;

  /// The last push token, or null before registration.
  String? get token => _settings.getString(SettingKeys.pushToken);

  /// Whether the OS has granted notification permission.
  Future<bool> isAllowed() => AwesomeNotifications().isNotificationAllowed();

  /// Whether the **critical-alert** permission is granted — lets EEW override
  /// silent / Do-Not-Disturb (iOS; guarded by the app entitlement). Shown as a
  /// separate onboarding step on iOS.
  Future<bool> criticalAllowed() async {
    final granted = await AwesomeNotifications().checkPermissionList(
      permissions: const [NotificationPermission.CriticalAlert],
    );
    return granted.contains(NotificationPermission.CriticalAlert);
  }

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
    final granted = await AwesomeNotifications()
        .requestPermissionToSendNotifications(
          permissions: const [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
            NotificationPermission.Vibration,
            NotificationPermission.Light,
            NotificationPermission.CriticalAlert,
          ],
        );
    // Permission is usually granted well after launch (onboarding) — by then the
    // launch-time token fetch may have found no APNs token yet. Retry now that
    // the user has decided (background; never blocks the caller).
    if (granted) unawaited(_fetchToken());
    return granted;
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
    final stored = _settings.getInt(SettingKeys.channelVersion) ?? 0;
    if (stored < NotificationChannels.version) {
      for (final channel in NotificationChannels.channels) {
        try {
          await AwesomeNotifications().setChannel(channel, forceUpdate: true);
        } catch (error, stackTrace) {
          Log.handle(error, stackTrace, 'setChannel ${channel.channelKey}');
        }
      }
      await _settings.setInt(
        SettingKeys.channelVersion,
        NotificationChannels.version,
      );
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

    messaging.onTokenRefresh.listen((token) async {
      Log.debug('Push token refreshed');
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // This stream only carries the FCM registration token (see
        // [_fetchToken] for why that's not what iOS registration needs);
        // re-read the APNs token directly rather than persist [token] as-is.
        final apns = await messaging.getAPNSToken();
        if (apns != null) {
          await _settings.setString(SettingKeys.pushToken, apns);
        }
        return;
      }
      await _settings.setString(SettingKeys.pushToken, token);
    });
    // Fire-and-forget: this can wait seconds for the iOS APNs token, and
    // `init()` is awaited at launch, so it must not block start-up.
    unawaited(_fetchToken());
  }

  /// Fetches the push token and persists it as [SettingKeys.pushToken] —
  /// the identifier every backend registration call (`/v2/location`,
  /// `/v2/notify`) keys on.
  ///
  /// **Which token, per platform, matters**: on iOS that has to be the raw
  /// **APNs** device token, not Firebase's FCM registration token — a
  /// different string the backend's own registration endpoints don't
  /// recognise (confirmed live: registering with the FCM token 202'd, as a
  /// write with no format check, but every subsequent `/v2/notify` lookup by
  /// that same value still 401'd — the legacy app stored exactly and only the
  /// APNs token on iOS for this reason, in `fcm.dart`). Android's backend
  /// registration keys on the FCM token, which is `getToken()`'s value there.
  ///
  /// `getToken()` is still awaited on iOS (its FCM-pipeline side effects are
  /// unrelated to which value gets persisted); only what gets *stored* differs
  /// by platform. The APNs token needs `registerForRemoteNotifications` to have
  /// completed first (handled by the FlutterFire app-delegate proxy) and
  /// arrives asynchronously, so poll briefly before giving up — else `getToken`
  /// itself throws `apns-token-not-set`. Recent iOS 16+ Simulators do provision
  /// an APNs token (older ones return null); either way delivery still needs
  /// the APNs auth key uploaded to the Firebase console. Best-effort: a failure
  /// just leaves the token unset until [requestPermission] or
  /// `onTokenRefresh` tries again.
  Future<void> _fetchToken() async {
    final messaging = FirebaseMessaging.instance;
    try {
      String? apnsToken;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var attempt = 0; attempt < 5; attempt++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      }
      final fcmToken = await messaging.getToken();
      final pushToken = defaultTargetPlatform == TargetPlatform.iOS
          ? apnsToken
          : fcmToken;
      if (pushToken != null) {
        await _settings.setString(SettingKeys.pushToken, pushToken);
      }
    } catch (error, stackTrace) {
      // The failure mode is platform-specific: on iOS an unready APNs token is
      // the usual cause, on Android getToken() fails at FCM registration (e.g.
      // the app's signing SHA-1 not registered in the Firebase console).
      final title = defaultTargetPlatform == TargetPlatform.iOS
          ? 'getToken (APNs may not be ready)'
          : 'getToken (FCM registration failed)';
      Log.handle(error, stackTrace, title);
    }
  }

  void _routeTap(Map<String, dynamic> data) =>
      NotificationTaps.route(NotificationTap.fromData(data));
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
  final channelKey = (data['channel'] as String?) ?? _fallbackChannelKey;
  return NotificationContent(
    id: int.tryParse((data['id'] as String?) ?? '') ?? 0,
    channelKey: channelKey,
    title: title,
    body: body,
    // Carry channel + id on the payload so an awesome-displayed tap deep-links
    // symmetrically with the FCM-delivered path.
    payload: {'channel': channelKey, 'id': data['id'] as String?},
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
