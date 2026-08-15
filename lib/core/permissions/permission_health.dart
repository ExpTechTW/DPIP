/// Whether the app still has what it needs to warn this user.
library;

import 'dart:async';

import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/notifications/notification_service.dart';
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
/// **What counts.** Only the three the app cannot work without: notifications
/// (no alert is delivered at all), foreground location (nothing knows which
/// township to warn about), and background location (the township goes stale
/// the moment the user closes the app). The Android battery exemption and
/// unused-app restrictions are deliberately *not* here even though they matter
/// — they are optimisations a user may knowingly decline, and a red dot that
/// cannot be cleared teaches people to ignore red dots. They stay on the
/// permission page where they can be read and acted on.
class PermissionHealth extends ChangeNotifier with WidgetsBindingObserver {
  PermissionHealth({required this._location, required this._notifications});

  final LocationService _location;
  final NotificationService _notifications;

  bool _started = false;

  /// Optimistic until the first read lands, so a freshly-launched app does not
  /// flash a warning it is about to withdraw.
  bool _notify = true;
  bool _foreground = true;
  bool _background = true;

  /// Whether any prerequisite is missing — what the badge watches.
  bool get needsAttention => !_notify || !_foreground || !_background;

  bool get notificationsAllowed => _notify;
  bool get locationGranted => _foreground;
  bool get backgroundLocationGranted => _background;

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
    if (notify == _notify &&
        foreground == _foreground &&
        background == _background) {
      return;
    }
    final was = needsAttention;
    _notify = notify;
    _foreground = foreground;
    _background = background;
    if (needsAttention != was) {
      Log.info(
        'permission health: needsAttention=$needsAttention '
        '(notify=$notify location=$foreground background=$background)',
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
