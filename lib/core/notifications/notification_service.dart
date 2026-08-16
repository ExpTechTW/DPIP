import 'dart:async';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:dpip/core/permissions/system_settings.dart';
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

  /// Whether the critical-alert grant is a thing on this platform at all.
  ///
  /// Lives here rather than as a `Platform.isIOS` at each caller because this is
  /// the platform seam, and because a caller that guessed wrong would be badly
  /// wrong in one direction: [criticalAllowed] answers false on Android — the
  /// permission does not exist there, the notification channel carries the
  /// override instead — so treating that false as "not granted" would put a
  /// permanent, unclearable warning on every Android device.
  bool get criticalApplies => Platform.isIOS;

  /// Whether the **critical-alert** permission is granted — lets EEW override
  /// silent / Do-Not-Disturb (iOS; guarded by the app entitlement). Shown as a
  /// separate onboarding step on iOS.
  Future<bool> criticalAllowed() async {
    try {
      final granted = await AwesomeNotifications().checkPermissionList(
        permissions: const [NotificationPermission.CriticalAlert],
      );
      Log.debug('permission: criticalAllowed -> $granted');
      return granted.contains(NotificationPermission.CriticalAlert);
    } catch (error, stackTrace) {
      // Used to escape and take the caller's whole handler with it, which is
      // one of the ways a permission row can end up doing nothing at all.
      Log.handle(error, stackTrace, 'criticalAllowed');
      return false;
    }
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

  /// Requests ordinary notification permission. Call from a screen (e.g.
  /// onboarding), not at launch.
  ///
  /// Deliberately does **not** ask for the critical alert — that is
  /// [requestCritical]. iOS treats the two as separate grants, and bundling
  /// them made the critical request unreachable: this method short-circuits on
  /// "already allowed", which is true the moment the ordinary prompt is
  /// answered, so a later tap on the critical-alert row did nothing at all.
  ///
  /// A refusal is reported as [PermissionOutcome.needsSettings] rather than a
  /// bare failure, because both platforms prompt only once: a second tap is
  /// silent, and the caller has to say so instead of appearing to ignore it.
  Future<PermissionOutcome> requestPermission() async {
    final already = await AwesomeNotifications().isNotificationAllowed();
    Log.info('permission: notifications, already allowed = $already');
    if (already) return PermissionOutcome.granted;

    // Ask the plugin to prompt **only** when iOS has not decided yet.
    //
    // Once the answer is "denied", awesome does not simply return false: it
    // opens the system settings page itself and parks the completion in a
    // queue that only drains when the app comes back. From Dart that is an
    // `await` that may never return — which is exactly what happened here. The
    // notification row logged "tapped", then nothing at all, twice, while the
    // rows that take other paths answered instantly.
    //
    // So a decided-and-denied state skips the plugin entirely and goes
    // straight to the caller's own explain-then-open flow, where the app is
    // the one deciding when to navigate.
    if (!await _canPrompt()) {
      Log.info('permission: notifications already decided — settings only');
      return PermissionOutcome.needsSettings;
    }

    final granted = await AwesomeNotifications()
        .requestPermissionToSendNotifications(
          permissions: const [
            NotificationPermission.Alert,
            NotificationPermission.Sound,
            NotificationPermission.Badge,
          ],
        )
        // A backstop for every other way the plugin can fail to answer.
        // A permission button that hangs is indistinguishable from one
        // that is broken, and the fallback here is a dialog that at least
        // tells the user where to go.
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            Log.warning('permission: notification request never answered');
            return false;
          },
        );
    Log.info('permission: notifications request -> $granted');
    if (granted) {
      // Permission is usually granted well after launch (onboarding) — by then
      // the launch-time token fetch may have found no APNs token yet. Retry now
      // that the user has decided (background; never blocks the caller).
      unawaited(_fetchToken());
      return PermissionOutcome.granted;
    }
    return PermissionOutcome.needsSettings;
  }

  /// Whether the OS will still show its own prompt.
  ///
  /// `notDetermined` is the only state where asking produces a dialog. Both
  /// platforms answer once and then never again, and on iOS asking anyway
  /// hands control to the plugin's settings-page detour.
  Future<bool> _canPrompt() async {
    try {
      final statuses = await AwesomeNotifications().getPermissionStatusList(
        permissions: const [NotificationPermission.Alert],
      );
      Log.debug('permission: notification status -> $statuses');
      return statuses[NotificationPermission.Alert] ==
          NotificationPermissionStatus.notDetermined;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'notification permission status');
      // Unknown: let the plugin try rather than dead-end on a guess.
      return true;
    }
  }

  /// Requests the **critical-alert** permission, which lets an EEW sound
  /// through silent mode and Do Not Disturb. Returns whether it is granted
  /// afterwards.
  ///
  /// Its own request because iOS grants it separately from ordinary
  /// notifications, and its own *check* afterwards because
  /// `requestPermissionToSendNotifications` answers "are notifications allowed
  /// at all", which is already true here — taking it as the result would report
  /// success no matter what the user chose.
  ///
  /// It can legitimately fail with no prompt and nothing to do about it in
  /// code: the permission is gated by the
  /// `com.apple.developer.usernotifications.critical-alerts` entitlement, which
  /// Apple grants per team on request, and it must be in the *provisioning
  /// profile* as well as in `Runner.entitlements`. When it does not land,
  /// [openSystemSettings] is the only remaining path.
  Future<PermissionOutcome> requestCritical() async {
    try {
      final answered = await AwesomeNotifications()
          .requestPermissionToSendNotifications(
            permissions: const [NotificationPermission.CriticalAlert],
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () {
              Log.warning('permission: critical request never answered');
              return false;
            },
          );
      Log.info('permission: critical-alert request -> $answered');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'critical-alert request');
    }
    final granted = await criticalAllowed();
    Log.info('permission: critical-alert granted = $granted');
    return granted
        ? PermissionOutcome.granted
        : PermissionOutcome.needsSettings;
  }

  /// Opens the OS notification settings for this app — the fallback when a
  /// permission cannot be granted from inside the app any more.
  Future<void> openSystemSettings() async {
    Log.info('permission: opening notification settings');
    // Not awesome's `showNotificationConfigPage` — on iOS that returned
    // without navigating anywhere and without an error, which is how the
    // "Open Settings" button became the next thing that did nothing.
    await openAppSettingsPage();
  }

  Future<void> _initChannels() async {
    final channels = NotificationChannels.channels;

    // The normal path is one batch call — the same one this always made.
    //
    // What changed is what happens when it fails. `initialize` validates every
    // channel natively and throws on the first it rejects, so one bad sound or
    // icon used to leave the app with **no channels at all** and no push
    // transport either (the exception aborted the rest of `init`). For an app
    // whose reason to exist is earthquake alerts, "one typo silences every
    // notification" is not an acceptable failure mode, and the anonymous
    // `PlatformException` said nothing about which channel caused it.
    //
    // So a batch failure falls through to registering them one at a time,
    // which costs only the offending channel and names it in the log.
    var registered = false;
    try {
      await AwesomeNotifications().initialize(
        NotificationChannels.icon,
        channels,
        channelGroups: NotificationChannels.groups,
        debug: kDebugMode,
      );
      registered = true;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'channel batch rejected — isolating');
    }

    final rejected = <String>[];
    NotificationChannel? seed;
    if (!registered) {
      // `initialize` requires at least one channel, so the isolation pass
      // starts by finding any single channel it will accept; that one seeds
      // the plugin and the rest go in through `setChannel`.
      for (final channel in channels) {
        try {
          await AwesomeNotifications().initialize(
            NotificationChannels.icon,
            [channel],
            channelGroups: NotificationChannels.groups,
            debug: kDebugMode,
          );
          seed = channel;
          break;
        } catch (error, stackTrace) {
          rejected.add(channel.channelKey ?? '?');
          Log.handle(error, stackTrace, 'channel ${channel.channelKey}');
        }
      }
      if (seed == null) {
        Log.error(
          'notifications: no channel could be registered — every one was '
          'rejected. Alerts will not be delivered.',
        );
        return;
      }
    }

    // Android caches a channel's settings after first creation, so a changed
    // sound or importance only takes effect with `forceUpdate` — which is what
    // the catalogue version is for.
    final stored = _settings.getInt(SettingKeys.channelVersion) ?? 0;
    final force = stored < NotificationChannels.version;

    // On the happy path this only runs when the catalogue changed. On the
    // degraded path it always runs, because it is what registers the channels
    // the seed did not.
    if (force || !registered) {
      for (final channel in channels) {
        if (identical(channel, seed)) continue;
        if (rejected.contains(channel.channelKey)) continue;
        try {
          await AwesomeNotifications().setChannel(channel, forceUpdate: force);
        } catch (error, stackTrace) {
          rejected.add(channel.channelKey ?? '?');
          Log.handle(error, stackTrace, 'channel ${channel.channelKey}');
        }
      }
    }

    if (rejected.isNotEmpty) {
      Log.error(
        'notifications: ${rejected.length} of ${channels.length} channel(s) '
        'rejected — ${rejected.join(', ')}. The rest are registered.',
      );
    }
    if (force) {
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
