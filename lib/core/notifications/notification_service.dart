import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/permissions/permission_outcome.dart';
import 'package:dpip/core/permissions/system_settings.dart';
import 'package:dpip/core/notifications/notification_channels.dart';
import 'package:dpip/core/notifications/foreground_eew_announcement_gate.dart';
import 'package:dpip/core/notifications/notification_samples.dart';
import 'package:dpip/core/notifications/notification_taps.dart';
import 'package:dpip/core/notifications/plain_channels.dart';
import 'package:dpip/core/settings/setting_keys.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  NotificationService(
    this._settings, {
    ForegroundEewAnnouncementGate? foregroundEewGate,
  }) : foregroundEewGate =
           foregroundEewGate ?? ForegroundEewAnnouncementGate() {
    _foregroundEewGate = this.foregroundEewGate;
  }

  final SettingsStore _settings;

  /// Sequences foreground EEW speech before the notification channel sound.
  /// Background and terminated delivery bypass this object entirely.
  final ForegroundEewAnnouncementGate foregroundEewGate;

  /// The same gate, reachable from [onFcmSilentData].
  ///
  /// That function is a top-level entry point — awesome_notifications_fcm
  /// calls it with no service instance to reach — so the gate the visible
  /// monitor speaks through has to be published somewhere it can see. It stays
  /// null on the background isolate, which never runs this constructor and
  /// where nothing is speaking; the foreground branch there displays
  /// immediately when it is null, so a missing instance can only ever mean the
  /// warning arrives sooner, never later.
  static ForegroundEewAnnouncementGate? _foregroundEewGate;

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
    final channels = await _initChannels();
    await AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationTaps.onActionReceived,
      // Kept for operational visibility, not for one bug. `created` fires when
      // awesome accepts a notification and `displayed` when it reaches the
      // status bar, so the log answers "did the alert actually surface?" — the
      // question that matters most in an app whose reason to exist is alerts,
      // and the one that took five rebuilds to answer the last time it came up
      // because nothing recorded it.
      onNotificationCreatedMethod: onNotificationCreated,
      onNotificationDisplayedMethod: onNotificationDisplayed,
    );
    await _initMessaging(channels);
  }

  /// One line per launch saying whether push actually came up.
  ///
  /// Push is the app's reason to exist and every one of its failures is silent:
  /// a channel the OS rejected, a permission never granted, a token that never
  /// arrived — the app looks identical in all of them and simply never rings.
  /// Printed after the token settles rather than at the end of [init], because
  /// the token is fetched in the background and a line without it would say
  /// "ready" before the one thing that can still be missing is known.
  void _logStartup({required int channels, required int rejected}) {
    final stored = token;
    final kind = Platform.isIOS ? 'APNs' : 'FCM';
    final tokenText = stored == null
        ? 'MISSING — this device cannot be reached'
        : kDebugMode
        ? '$kind $stored'
        // Enough to tell two devices apart and to match against the backend,
        // without putting the whole addressable identifier in a shared log.
        : '$kind …${stored.substring(stored.length - 8)} (${stored.length})';
    final channelText = rejected == 0
        ? '$channels ok'
        : '${channels - rejected}/$channels ok, $rejected REJECTED';
    Log.info(
      'push: ${stored == null ? 'DEGRADED' : 'ready'} · '
      '${Platform.isIOS ? 'iOS' : 'Android'} · '
      'channels $channelText · token $tokenText',
    );
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
  Future<bool> openSystemSettings() async {
    Log.info('permission: opening notification settings');
    // Not awesome's `showNotificationConfigPage` — on iOS that returned
    // without navigating anywhere and without an error, which is how the
    // "Open Settings" button became the next thing that did nothing.
    return openNotificationSettingsPage();
  }

  /// Posts [channelKey]'s sample alert locally, so the user can hear and see
  /// what that channel actually does on this device.
  ///
  /// Local, not a round-trip through the backend: the thing being tested is the
  /// last hop — the channel's sound, its importance, whether the OS lets it
  /// through — and that hop is identical whether the notification came from
  /// APNs or from here. Asking the server would only add a way for the test to
  /// fail for a reason that has nothing to do with the answer.
  ///
  /// Returns false when the channel has no sample or the OS refused it.
  ///
  /// Two behaviours are deliberate rather than accidental:
  ///
  /// * **It rings for real.** A channel with `criticalAlerts` overrides the
  ///   silent switch and Do Not Disturb, at a volume the user does not control.
  ///   Nothing here softens that, because a test that is quieter than the real
  ///   alert answers the wrong question. The page warns before the tap instead.
  /// * **Tapping it navigates**, through the same [NotificationTaps] route
  ///   table as a real alert — so the test covers the tap as well, and the user
  ///   lands wherever the real one would have taken them.
  Future<bool> showTest(String channelKey) async {
    final content = testNotificationContent(channelKey);
    if (content == null) return false;
    try {
      return await AwesomeNotifications().createNotification(content: content);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'test notification for $channelKey');
      return false;
    }
  }

  Future<({int total, int rejected})> _initChannels() async {
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
        return (total: channels.length, rejected: channels.length);
      }
    }

    // Android freezes a created channel's behaviour — sound included — so a
    // changed definition cannot simply be pushed. awesome's own update path
    // makes it worse: a forced update deletes the channel under its plain key
    // and recreates it under `<key>_<digest>`, an id FCM's system-tray renders
    // can never find. The backend's pushes carry an FCM `notification` block,
    // so background delivery is exactly that path — and every upgraded install
    // fell back to the system default sound.
    //
    // The catalogue version therefore means **remove everything and register
    // again**: `removeChannel` deletes both the plain and the hashed variant
    // plus the registry entry, so each re-registration takes the "created"
    // branch — plain key, current sound files, no hash suffix ever.
    final stored = _settings.getInt(SettingKeys.channelVersion) ?? 0;
    final outdated = stored < NotificationChannels.version;

    // On the happy path this only runs when the catalogue changed. On the
    // degraded path it always runs, because it is what registers the channels
    // the seed did not.
    if (outdated || !registered) {
      if (outdated && registered) {
        var purged = true;
        for (final channel in channels) {
          if (rejected.contains(channel.channelKey)) continue;
          try {
            await AwesomeNotifications().removeChannel(channel.channelKey!);
          } catch (error, stackTrace) {
            purged = false;
            Log.handle(error, stackTrace, 'purging ${channel.channelKey}');
          }
        }
        if (!purged) {
          Log.error(
            'notifications: channel purge incomplete — stale sounds may '
            'persist on upgraded installs until the next launch',
          );
        }
      }
      for (final channel in channels) {
        if (identical(channel, seed)) continue;
        if (rejected.contains(channel.channelKey)) continue;
        try {
          await AwesomeNotifications().setChannel(channel);
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
    if (outdated) {
      await _settings.setInt(
        SettingKeys.channelVersion,
        NotificationChannels.version,
      );
    }

    // FCM renders background pushes itself against the PLAIN channel id, a
    // lookup that must not depend on how awesome hashed or re-hashed its own
    // channels this launch. Mirror the catalogue under plain keys last, after
    // every purge and re-registration above has settled.
    await PlainChannels.ensure(channels);
    return (total: channels.length, rejected: rejected.length);
  }

  Future<void> _initMessaging(({int total, int rejected}) channels) async {
    // Push belongs to awesome_notifications_fcm, on both platforms.
    //
    // `awesome_notifications` handles local notifications only — its own source
    // says so: "we do not chain to a previously-installed delegate … FCM is
    // handled by awesome_notifications_fcm". Without that companion the remote
    // path has no owner: on iOS a server push reached awesome's willPresent,
    // was claimed as its own (the payload's `content` key is awesome's model
    // format) and then had nothing to display it with, so the foreground went
    // silent and blank.
    //
    // `firebase_messaging` is gone: upstream says the two must not coexist, and
    // everything it was still doing here has an equivalent above — the two
    // token handlers replace its refresh stream and its launch-time fetch, and
    // the foreground presentation it configured is now decided by this app's
    // own notification-centre delegate (see AppDelegate).
    await AwesomeNotificationsFcm().initialize(
      onFcmTokenHandle: (token) => _storeToken(token, isApns: false),
      onNativeTokenHandle: (token) => _storeToken(token, isApns: true),
      onFcmSilentDataHandle: onFcmSilentData,
      debug: kDebugMode,
    );
    unawaited(
      _fetchToken().whenComplete(
        () =>
            _logStartup(channels: channels.total, rejected: channels.rejected),
      ),
    );
  }

  /// Submits a debug monitor warning through the same foreground EEW gate as
  /// an FCM message. The caller is compile-time gated by the demo sound flag;
  /// this guard also makes an accidental release call inert.
  Future<void> showDebugEewWarning({
    required String title,
    required String body,
  }) async {
    if (!kDebugMode) return;
    await foregroundEewGate.submit(() async {
      final created = await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: 570057,
          channelKey: 'eew_alert-important-v2',
          title: title,
          body: body,
          wakeUpScreen: true,
          category: NotificationCategory.Alarm,
          payload: const {
            'channel': 'eew_alert-important-v2',
            'id': 'demo-monitor-sound',
          },
        ),
      );
      if (!created) {
        Log.warning(
          'monitor demo warning was rejected — notification permission or '
          'channel settings may be disabled',
        );
      }
    });
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
  /// The one place [SettingKeys.pushToken] is written.
  ///
  /// Tokens arrive from three directions — awesome_notifications_fcm's two
  /// handlers, firebase's refresh stream, and the launch-time fetch — and the
  /// two kinds are **not interchangeable**: the backend keys on the raw APNs
  /// token on iOS and the FCM registration token on Android. Registering the
  /// wrong one is not a loud failure; it was measured to 202 on the write and
  /// then 401 on every later lookup, which reads as "push is broken" with no
  /// clue why.
  ///
  /// So every writer states which kind it holds and this decides, instead of
  /// each caller repeating a platform test — the version that did not repeat
  /// it let iOS overwrite a good APNs token with an FCM one seconds later.
  Future<void> _storeToken(String token, {required bool isApns}) async {
    if (token.isEmpty) return;
    if (isApns != Platform.isIOS) return;
    await _settings.setString(SettingKeys.pushToken, token);
    Log.debug('Push token stored (${isApns ? 'APNs' : 'FCM'})');
  }

  /// The APNs device token, read from the iOS side that receives it.
  static const _apns = MethodChannel('com.exptech.dpip/apns_token');

  Future<void> _fetchToken() async {
    try {
      if (Platform.isIOS) {
        // iOS hands the token to the app delegate whenever it finishes
        // registering, which is usually a moment after launch. `onNativeTokenHandle`
        // delivers it too, but only if it fires — and a token that never
        // arrives is silent: the backend keeps the device on file and simply
        // stops being able to reach it. Polling the native side closes that
        // hole without another SDK in between.
        for (var attempt = 0; attempt < 5; attempt++) {
          final token = await _apns.invokeMethod<String>('token');
          if (token != null) {
            await _storeToken(token, isApns: true);
            return;
          }
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        Log.warning(
          'APNs token still unavailable — push cannot reach this device',
        );
        return;
      }
      await _storeToken(
        await AwesomeNotificationsFcm().requestFirebaseAppToken(),
        isApns: false,
      );
    } catch (error, stackTrace) {
      // On Android this is FCM registration failing, usually the app's signing
      // SHA-1 not being registered in the Firebase console.
      Log.handle(error, stackTrace, 'push token');
    }
  }
}

/// The markers legacy stamped on every test notification, kept verbatim.
///
/// Not decoration, and not optional. The samples reproduce real CWA alerts
/// word for word, so an unmarked test is indistinguishable from the thing
/// itself: a 緊急地震速報 on a lock screen that nobody issued — photographed,
/// forwarded, and believed. The marker is the only thing standing between a
/// settings screen and a fake earthquake warning in circulation.
///
/// Chinese, like the body it prefixes. The samples are Chinese because the
/// backend only sends Chinese; a localized marker glued to an unlocalized
/// alert would read as two different messages.
const String testTitlePrefix = '[測試] ';
const String testBodyMarker = '＊＊＊這是測試訊息＊＊＊';

/// The notification a test tap posts for [channelKey], or null when the
/// channel has no sample to reproduce.
///
/// Split out from [NotificationService.showTest] so the part that decides what
/// the user sees can be tested without a platform channel — the same split
/// [contentFromData] already uses in this file.
NotificationContent? testNotificationContent(String channelKey) {
  final sample = NotificationSamples.of(channelKey);
  if (sample == null) return null;
  return NotificationContent(
    id: _testId(channelKey),
    channelKey: channelKey,
    title: '$testTitlePrefix${sample.title}',
    // The separator is `<br>` on Android and a newline on iOS because awesome
    // renders the Android body through `android.text.Html` (`Html.fromHtml`
    // and the class itself are both in the shipped dex) and takes the iOS one
    // literally. Legacy split it the same way; getting it wrong loses the line
    // break rather than failing loudly.
    //
    // The sample's *own* newlines are left exactly as they are, on both
    // platforms. On Android that means a multi-line CWA alert collapses to a
    // single line — which is precisely what a real push from the backend does
    // there, since it travels the same `Html.fromHtml` path. A test that read
    // better than the alert it reproduces would be lying about the one thing
    // it exists to show.
    body: '$testBodyMarker${Platform.isIOS ? '\n' : '<br>'} ${sample.body}',
    // The alerts this reproduces are several lines long; the default layout
    // truncates them to one, which would make every sample look alike in the
    // shade — the opposite of what the page is for.
    notificationLayout: NotificationLayout.BigText,
  );
}

/// A stable, per-channel notification id reserved for tests.
///
/// Negative, and derived from the channel's position in the catalogue, for
/// two reasons. Server alerts carry the backend's own positive ids, so a test
/// can never overwrite a real alert sitting in the shade. And one id *per
/// channel* — rather than legacy's single shared id — means re-testing a
/// channel replaces its own previous sample instead of stacking up, while two
/// different channels stay side by side where they can be compared. Comparing
/// them is most of the point.
int _testId(String channelKey) {
  final index = NotificationChannels.channels.indexWhere(
    (channel) => channel.channelKey == channelKey,
  );
  return -1000 - (index < 0 ? 0 : index);
}

/// Builds notification content from a message's `data` (preferred, legacy
/// format) falling back to its `notification` block, or null when there's
/// nothing to show.
///
/// Two payload shapes arrive here:
///
/// - **Flat** — `data['channel']` / `data['title']` / `data['body']` /
///   `data['id']`, the contract [ARCHITECTURE.md] describes.
/// - **Nested** — everything packed into `data['content']` as one JSON string
///   (`{channelKey, id, body, …}`), which is what the push producer still
///   sends: the FCM `notification` block carries the visible text while the
///   structured fields ride inside that string. Without reading it back,
///   every such message loses its channel and collapses onto the announcement
///   fallback — wrong sound, wrong tap routing.
///
/// Flat keys win where both exist. Nested JSON is parsed leniently: malformed
/// or non-object content is treated as absent, never thrown on.
/// [fallbackTitle] / [fallbackBody] stand in for an FCM `notification` block.
/// A silent-data push carries none, so its text has to come from the payload.
NotificationContent? contentFromData(
  Map<String, dynamic> data, {
  String? fallbackTitle,
  String? fallbackBody,
}) {
  final nested = _nestedContent(data);
  String? nestedField(String name) => switch (nested?[name]) {
    final String value => value,
    final int value => value.toString(),
    _ => null,
  };
  final title =
      (data['title'] as String?) ?? fallbackTitle ?? nestedField('title');
  final body = (data['body'] as String?) ?? fallbackBody ?? nestedField('body');
  if (title == null && body == null) return null;
  final channelKey =
      (data['channel'] as String?) ??
      nestedField('channelKey') ??
      _fallbackChannelKey;
  final id =
      _asNotificationId(data['id']) ?? _asNotificationId(nested?['id']) ?? 0;
  final idText = (data['id'] as String?) ?? nestedField('id');
  return NotificationContent(
    id: id,
    channelKey: channelKey,
    title: title,
    body: body,
    // Carry channel + id on the payload so an awesome-displayed tap deep-links
    // symmetrically with the FCM-delivered path.
    payload: {'channel': channelKey, 'id': idText},
    wakeUpScreen: true,
    // Deliberately NO `category: Alarm` here: awesome turns that into
    // FLAG_INSISTENT | FLAG_NO_CLEAR, which repeats the channel sound until
    // the notification is opened — reported as "the alert loops forever".
    // Insistence is a per-channel policy decision, not something every push
    // should inherit from a hardcoded default.
  );
}

/// The structured fields of a message whose producer nested them inside
/// `data['content']` as one JSON string — see [contentFromData]'s doc.
Map<String, dynamic>? _nestedContent(Map<String, dynamic> data) {
  final raw = data['content'];
  if (raw is! String || raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Coerces a payload id to the form awesome accepts.
///
/// awesome validates ids against the **signed 32-bit** range and throws —
/// killing the whole notification — on anything wider. The producer computes
/// its id as a 40-bit hex slice (`parseInt(md5slice, 16)`), so oversized ids
/// are the common case, not the edge: they are treated as absent and the
/// notification renders with id 0, replacing whatever came before it.
int? _asNotificationId(Object? value) {
  final parsed = switch (value) {
    final int v => v,
    final String s => int.tryParse(s),
    _ => null,
  };
  if (parsed == null || parsed < -0x80000000 || parsed > 0x7FFFFFFF) {
    return null;
  }
  return parsed;
}

/// Fires when awesome accepts a notification, before it is shown.
@pragma('vm:entry-point')
Future<void> onNotificationCreated(ReceivedNotification notification) async {
  Log.debug(
    'notif created: id=${notification.id} channel=${notification.channelKey} '
    'lifecycle=${notification.createdLifeCycle}',
  );
}

/// Fires when a notification actually reaches the status bar.
@pragma('vm:entry-point')
Future<void> onNotificationDisplayed(ReceivedNotification notification) async {
  Log.debug(
    'notif displayed: id=${notification.id} channel=${notification.channelKey} '
    'lifecycle=${notification.displayedLifeCycle}',
  );
}

/// Draws a push that arrived through awesome_notifications_fcm.
///
/// Runs on a background isolate when the app is not in the foreground, so
/// awesome has to be initialized here before it can be used — the isolate does
/// not inherit the one `init()` set up.
///
/// The terminated case goes through `createNotificationFromJsonData` rather
/// than a hand-built [NotificationContent]: at that point there is no engine
/// state to rely on, and the payload is already in awesome's own wire format
/// (the server sends a `content` object with `channelKey`), so handing it over
/// whole is both shorter and closer to what the sender meant.
@pragma('vm:entry-point')
Future<void> onFcmSilentData(FcmSilentData silentData) async {
  final data = silentData.data;
  if (data == null || data.isEmpty) return;

  await AwesomeNotifications().initialize(
    NotificationChannels.icon,
    NotificationChannels.channels,
    channelGroups: NotificationChannels.groups,
  );

  if (silentData.createdLifeCycle == NotificationLifeCycle.Terminated) {
    await AwesomeNotifications().createNotificationFromJsonData(
      data.cast<String, dynamic>(),
    );
    return;
  }

  final content = contentFromData(data.cast<String, dynamic>());
  if (content == null) return;

  Future<void> display() =>
      AwesomeNotifications().createNotification(content: content);

  // A foreground EEW is the one case that waits: the visible monitor may be
  // speaking the estimated intensity, and the channel's warning sound must not
  // talk over it. Every other lifecycle and every other channel displays
  // straight away, and the gate's own timeout bounds this one.
  final gate = NotificationService._foregroundEewGate;
  if (gate != null &&
      silentData.createdLifeCycle == NotificationLifeCycle.Foreground &&
      (content.channelKey?.startsWith('eew') ?? false)) {
    await gate.submit(display);
    return;
  }
  await display();
}
