import 'package:dpip/core/logging/log.dart';
import 'package:flutter/services.dart';

/// Hands the iOS EEW Live Activity widget what it needs and cannot get itself.
///
/// The widget works out the local intensity and the S-wave arrival on every
/// render, often while the app is not running, so it reads two things from
/// the App Group: the packed S-wave table and the observer (the last fix and
/// the selected township's centroid). This is the only door to them; the
/// files themselves are the native side's business
/// (`ios/Runner/EEWLiveActivityDataPlugin.swift`).
///
/// Never throws. Without the plugin (Android, tests) every call is a no-op
/// that answers null/false.
class EewLiveActivityData {
  const EewLiveActivityData({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('com.exptech.dpip/eew_live_activity_data');

  final MethodChannel _channel;

  /// The version the stored S-wave table was written for, or null when there
  /// is none.
  Future<int?> travelTimeVersion() =>
      _call<int>('travelTimeVersion', null, 'read the S-wave table version');

  /// Replaces the stored S-wave table with [table], written for [version].
  Future<bool> writeTravelTime(Uint8List table, {required int version}) async =>
      await _call<bool>('writeTravelTime', {
        'table': table,
        'version': version,
      }, 'write the S-wave table') ??
      false;

  /// Records the last GPS fix.
  Future<bool> writeFix({required double lat, required double lng}) async =>
      await _call<bool>('writeFix', {
        'lat': lat,
        'lng': lng,
      }, 'write the last fix') ??
      false;

  /// Records the selected township's centroid, or clears it when null.
  Future<bool> writeTown(({String code, double lat, double lng})? town) async =>
      await _call<bool>('writeTown', {
        'code': town?.code,
        'lat': town?.lat,
        'lng': town?.lng,
      }, 'write the selected township') ??
      false;

  Future<T?> _call<T>(
    String method,
    Map<String, Object?>? arguments,
    String what,
  ) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (error) {
      Log.warning('Live Activity data: could not $what (${error.code})');
      return null;
    }
  }
}
