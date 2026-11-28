/// Whether Live Activities are switched on for DPIP, read once on demand.
///
/// The same switch also arrives on `LiveActivityTokens.stream`, but that stream
/// is single-subscription and `LiveActivityRegistration` is its listener, so
/// the permission page asks here instead (`LiveActivityTokenPlugin`'s
/// `isEnabled`).
library;

import 'dart:io' show Platform;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

class LiveActivityAuthorization {
  LiveActivityAuthorization([MethodChannel? channel])
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/live_activity_authorization');

  final MethodChannel _channel;

  /// Whether this platform has the switch at all. Overridable so a test on the
  /// host, where `Platform.isIOS` is false, can reach the iOS branch.
  bool get applies => Platform.isIOS;

  /// True or false on iOS 18 and later; null where it does not apply — Android,
  /// iOS 17 and earlier — and when the platform did not answer. Null is never
  /// "off": a switch nobody could read must not be shown as one to turn on.
  Future<bool?> isEnabled() async {
    if (!applies) return null;
    try {
      return await _channel.invokeMethod<bool>('isEnabled');
    } on PlatformException catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'live activity isEnabled');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
