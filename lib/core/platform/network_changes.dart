/// Reports when the device's network changes underneath the app — Wi-Fi to
/// cellular, one Wi-Fi to another, offline to online — so a feed holding a
/// connection open can replace one bound to a network that is gone.
///
/// A platform channel rather than a package, like the rest of `core/platform/`:
/// Android's default-network callback and iOS's `NWPathMonitor` each answer the
/// one question asked — which network traffic currently leaves through — and
/// each side is a single system callback.
///
/// The platform sends an opaque identity per report (`wifi:<handle>`,
/// `cellular:pdp_ip0`, `none`); only whether it differs from the last one
/// matters here. Without reports the stream simply never fires, and the feeds'
/// own silence limit still catches a dead connection, only later.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

abstract final class NetworkChanges {
  const NetworkChanges._();

  static const EventChannel _channel = EventChannel('com.exptech.dpip/network');

  /// One event per real change of network, carrying the new identity.
  ///
  /// Single-subscription: the realtime service is its one listener.
  static Stream<String> get stream =>
      changesOf(_channel.receiveBroadcastStream());

  /// The change filter, over any stream of identity reports.
  ///
  /// The first report is the network the app started on — a baseline, not a
  /// change. After it, a report equal to the previous one is not a change
  /// either: iOS re-reports the same path whenever any property of it moves
  /// (cost, constrained mode), and acting on those would tear down a healthy
  /// connection for nothing. An error from the platform is logged and skipped;
  /// the reports after it still count.
  ///
  /// `Stream.multi` rather than an `async*` generator: a generator parked in
  /// `await for` does not let a cancel through until the next report arrives,
  /// which for a network that never changes again is never — the platform
  /// callback would outlive its only listener.
  @visibleForTesting
  static Stream<String> changesOf(Stream<Object?> reports) =>
      Stream<String>.multi((out) {
        String? previous;
        final subscription = reports.listen(
          (report) {
            final identity = '$report';
            if (previous == null) {
              Log.debug('network: $identity');
            } else if (identity != previous) {
              Log.info('network changed: $previous → $identity');
              out.add(identity);
            }
            previous = identity;
          },
          // The OS refused the callback, or a report failed in transit. The
          // feeds fall back on their silence limit meanwhile.
          onError: (Object error) =>
              Log.warning('network change report failed: $error'),
          onDone: out.close,
        );
        out
          ..onPause = subscription.pause
          ..onResume = subscription.resume
          ..onCancel = subscription.cancel;
      });
}
