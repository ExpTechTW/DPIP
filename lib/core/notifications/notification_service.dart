import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences keys. The token is written from a background isolate (see
/// [_onPushToken]), so it must live in persistent storage, not memory.
const String _tokenKey = 'notification.pushToken';
const String _channelVersionKey = 'notification.channelVersion';

/// Fallback channel for a message with no/unknown `channel` — must be a
/// registered channel or the OS rejects the notification.
const String _fallbackChannelKey = 'announcement-general-v2';

/// Sets up push notifications.
///
/// Follows the legacy platform split so the two FCM plugins never contend for
/// notification resources on the same platform:
/// - **Android**: `awesome_notifications_fcm` owns FCM (token + data messages),
///   and `awesome_notifications` renders them via the channel catalogue.
/// - **iOS**: APNs delivers the notification directly; `firebase_messaging`
///   supplies only the APNs token for backend registration.
///
/// The rich display, channels, and tap routing come from `awesome_notifications`
/// on both platforms.
class NotificationService {
  NotificationService(this._prefs);

  final SharedPreferences _prefs;

  /// The last push token (FCM registration token on Android, APNs token on
  /// iOS), or null before registration. May lag a background write until
  /// [refreshToken] reloads it.
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
    await _initTransport();
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

  /// Re-reads the token from storage (it may have been written by a background
  /// isolate since this instance loaded).
  Future<String?> refreshToken() async {
    await _prefs.reload();
    return token;
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

  Future<void> _initTransport() async {
    if (Platform.isAndroid) {
      await AwesomeNotificationsFcm().initialize(
        onFcmTokenHandle: _onPushToken,
        onNativeTokenHandle: _onPushToken,
        onFcmSilentDataHandle: _onSilentData,
        debug: kDebugMode,
      );
      await AwesomeNotificationsFcm().requestFirebaseAppToken();
    } else if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) await _prefs.setString(_tokenKey, apnsToken);
    }
  }
}

/// Persists the push token. Runs on a background isolate, so it writes through
/// SharedPreferences rather than in-memory state.
@pragma('vm:entry-point')
Future<void> _onPushToken(String token) async {
  Log.debug('Push token received');
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_tokenKey, token);
}

/// Renders an incoming FCM data message as a rich local notification. Runs on a
/// background isolate for backgrounded/terminated delivery.
@pragma('vm:entry-point')
Future<void> _onSilentData(FcmSilentData silentData) async {
  final raw = silentData.data;
  if (raw == null) return;
  final data = raw.cast<String, dynamic>();
  await AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: int.tryParse((data['id'] as String?) ?? '') ?? 0,
      channelKey: (data['channel'] as String?) ?? _fallbackChannelKey,
      title: data['title'] as String?,
      body: data['body'] as String?,
      wakeUpScreen: true,
      category: NotificationCategory.Alarm,
    ),
  );
}
