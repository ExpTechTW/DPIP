/// The Live Activity push-to-start token and the system's Live Activities
/// switch, from the native side (`LiveActivityTokenPlugin`).
///
/// iOS 18 and later only: the platform sends nothing on older systems, and
/// nothing exists on Android, so the stream simply never fires there. A
/// remotely started activity can only be updated and ended over a broadcast
/// channel, which needs iOS 18.
///
/// The token is issued for `EEWActivityAttributes`; it can be null on the first
/// report and arrive in a later one.
library;

import 'dart:io' show Platform;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

/// One report: the push-to-start token (lowercase hex, null until iOS issues
/// one) and whether Live Activities are switched on for the app in Settings.
typedef LiveActivityState = ({String? token, bool enabled});

abstract final class LiveActivityTokens {
  const LiveActivityTokens._();

  static const EventChannel _channel = EventChannel(
    'com.exptech.dpip/live_activity_token',
  );

  /// One state on listen, then one per change of either value.
  ///
  /// Single-subscription: `LiveActivityRegistration` is its one listener.
  static Stream<LiveActivityState> get stream => Platform.isIOS
      ? statesOf(_channel.receiveBroadcastStream())
      : const Stream<LiveActivityState>.empty();

  /// The parser, over any stream of platform reports. A malformed report is
  /// logged and skipped; the ones after it still count.
  @visibleForTesting
  static Stream<LiveActivityState> statesOf(Stream<Object?> reports) =>
      Stream<LiveActivityState>.multi((out) {
        final subscription = reports.listen(
          (report) {
            final state = _parse(report);
            if (state == null) {
              Log.warning('live activity: malformed report skipped');
              return;
            }
            out.add(state);
          },
          onError: (Object error, StackTrace stackTrace) =>
              Log.handle(error, stackTrace, 'live activity token'),
          onDone: out.close,
        );
        out.onCancel = subscription.cancel;
      });

  static LiveActivityState? _parse(Object? report) {
    if (report is! Map) return null;
    final token = report['token'];
    final enabled = report['enabled'];
    if (enabled is! bool) return null;
    if (token != null && (token is! String || token.isEmpty)) return null;
    return (token: token as String?, enabled: enabled);
  }
}
