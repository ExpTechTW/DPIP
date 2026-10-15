/// The "DPIP Notification Settings" link in iOS Settings → DPIP →
/// Notifications, and the request it sends back into the app.
///
/// iOS shows that row only for an app that asked for
/// `UNAuthorizationOptions.providesAppNotificationSettings`. awesome's
/// permission list has no entry for it, so `NotificationSettingsLinkPlugin`
/// (ios/Runner) asks natively, and receives the tap through the
/// notification-centre delegate. This side tells it when to ask and carries
/// the tap to whoever routes it — `core` knows that settings were asked for,
/// the app layer knows which page that is.
///
/// A no-op off iOS.
library;

import 'dart:async';
import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

class NotificationSettingsLink {
  NotificationSettingsLink({MethodChannel? channel, bool? isIOS})
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/notification_settings_link'),
      _isIOS = isIOS ?? Platform.isIOS;

  final MethodChannel _channel;
  final bool _isIOS;
  void Function()? _onOpen;

  /// Asks iOS for the Settings row, once notifications are allowed.
  ///
  /// Safe on every launch: the native side does nothing until the user has
  /// allowed notifications, does nothing once the row exists, and never shows
  /// a prompt — a decided app asking for an extra option is answered without
  /// one. Best-effort: a failure only means the row is missing.
  Future<bool> provide() async {
    if (!_isIOS) return false;
    try {
      final provided = await _channel.invokeMethod<bool>('provide') ?? false;
      Log.debug('notifications: settings link provided = $provided');
      return provided;
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'notification settings link');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Starts delivering Settings-row taps to [onOpen], including one that
  /// arrived before this was called.
  ///
  /// Call once the router can navigate: a cold launch from the Settings row
  /// records the tap before Dart is running, and this is when it is replayed.
  Future<void> listen(void Function() onOpen) async {
    if (!_isIOS) return;
    _onOpen = onOpen;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open') await _drain();
    });
    await _drain();
  }

  /// Stops delivering taps.
  void stop() {
    _onOpen = null;
    if (_isIOS) _channel.setMethodCallHandler(null);
  }

  /// Takes the native request flag, which reads and clears it in one step, so
  /// a nudge and a startup check racing each other open the page once.
  Future<void> _drain() async {
    final onOpen = _onOpen;
    if (onOpen == null) return;
    try {
      final requested = await _channel.invokeMethod<bool>('take') ?? false;
      if (!requested) return;
      Log.info('notifications: opened from the system settings link');
      onOpen();
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'notification settings link');
    } on MissingPluginException {
      // No native side (tests, an engine that never registered it).
    }
  }
}
