/// Whether the app still has what it needs to warn this user.
library;

import 'dart:async';

import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_service.dart';
import 'package:dpip/core/platform/background_execution.dart';
import 'package:dpip/core/platform/unused_app_restrictions.dart';
import 'package:flutter/widgets.dart';

/// One app-wide answer to "can a disaster alert still reach this user?", so the
/// surfaces that warn about it agree and none of them queries the OS on a
/// rebuild.
///
/// Permission state changes outside the app — in system settings, or by
/// Android revoking it after months of disuse — so there is no event to
/// subscribe to. It is re-read when the app comes back to the foreground, which
/// is the moment after any trip to settings, and on demand after the permission
/// UI acts.
///
/// **What counts:** anything that stops an alert reaching this user *and* that
/// the user can still put right.
///
///  - notifications — no alert is delivered at all;
///  - foreground location — nothing knows which township to warn about;
///  - background location — the township goes stale the moment the app closes;
///  - **background execution** — Android's "Restricted" battery state, or iOS
///    Background App Refresh being off. The second is the sharpest of the lot:
///    with it off iOS delivers no significant-change or region event *even in
///    the foreground*, so the location spine reports itself armed and never
///    fires. Nothing else in the app can see that;
///  - **unused-app restrictions** — after a few months unopened, Android
///    revokes the permissions and force-stops the package, and a stopped
///    package receives no broadcast at all, so not even the boot re-arm
///    recovers it. It is the one failure that is both permanent and silent.
///
/// **What deliberately does not count.** The Android battery (Doze) exemption:
/// the geofence spine is designed to work without it, so it is an optimisation
/// a user may knowingly decline. The iOS critical-alert entitlement: it depends
/// on an Apple grant per developer team, so a user who cannot get it would face
/// a red dot they can never clear. The app-standby bucket and the OEM battery
/// managers: not settable through any API, so a dot would be permanent by
/// construction. All of them stay on the permission page, which explains them;
/// a badge that cannot be cleared teaches people to ignore badges.
class PermissionHealth extends ChangeNotifier with WidgetsBindingObserver {
  PermissionHealth({
    required this._location,
    required this._notifications,
    // Defaulted rather than required: both are stateless platform-channel
    // facades, and every existing caller would otherwise have to name them to
    // say nothing. Injectable so a test can drive them without a platform.
    BackgroundExecutionService? execution,
    UnusedAppRestrictionsService? unusedApp,
  }) : _execution = execution ?? BackgroundExecutionService(),
       _unusedApp = unusedApp ?? UnusedAppRestrictionsService();

  final LocationService _location;
  final NotificationService _notifications;
  final BackgroundExecutionService _execution;
  final UnusedAppRestrictionsService _unusedApp;

  bool _started = false;

  /// Optimistic until the first read lands, so a freshly-launched app does not
  /// flash a warning it is about to withdraw.
  bool _notify = true;
  bool _foreground = true;
  bool _background = true;
  bool _execute = true;
  bool _keptActive = true;

  /// Whether any prerequisite is missing — what the badge watches.
  bool get needsAttention =>
      !_notify || !_foreground || !_background || !_execute || !_keptActive;

  bool get notificationsAllowed => _notify;
  bool get locationGranted => _foreground;
  bool get backgroundLocationGranted => _background;

  /// Whether the OS will run background work at all — see the class doc.
  bool get backgroundExecutionAllowed => _execute;

  /// Whether the app is exempt from being hibernated for disuse. True where the
  /// platform cannot answer, so a device with nothing to change never shows a
  /// warning it cannot clear.
  bool get keptActive => _keptActive;

  /// Begins watching. Call once, after the first frame.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning to the foreground is the only reliable moment: every grant that
    // cannot be made in-app is made in system settings, and coming back is what
    // follows.
    if (state == AppLifecycleState.resumed) unawaited(refresh());
  }

  /// Re-reads every permission. Never throws — each read already degrades to
  /// "not granted" on failure, and a diagnostic must not become a crash.
  Future<void> refresh() async {
    final notify = await _notifications.isAllowed();
    final foreground = await _location.granted();
    // Asking for background while foreground is denied answers "denied" on both
    // platforms, which is true but says nothing new — the foreground flag is
    // already carrying that.
    final background = foreground ? await _location.backgroundGranted() : false;
    final execution = await _execution.status();
    // Only a state the platform actually answered can be a problem, and only
    // one the user can act on: a profile-locked device has nothing to change.
    final execute =
        !execution.known || !execution.restricted || execution.lockedByPolicy;
    final unusedApp = await _unusedApp.status();
    final keptActive = unusedApp != UnusedAppRestrictions.restricted;
    if (notify == _notify &&
        foreground == _foreground &&
        background == _background &&
        execute == _execute &&
        keptActive == _keptActive) {
      return;
    }
    final was = needsAttention;
    _notify = notify;
    _foreground = foreground;
    _background = background;
    _execute = execute;
    _keptActive = keptActive;
    if (needsAttention != was) {
      Log.info(
        'permission health: needsAttention=$needsAttention '
        '(notify=$notify location=$foreground background=$background '
        'execute=$execute keptActive=$keptActive '
        'bucket=${execution.standbyBucket})',
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
