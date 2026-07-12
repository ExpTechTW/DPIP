import 'package:dpip/core/logging/crash_sink.dart';
import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Application-wide logging facade.
///
/// Always log through [Log] — **never** use `print` or `debugPrint`. It is
/// backed by Talker, which keeps a history for the in-app log screen and
/// captures uncaught Flutter/async errors.
abstract final class Log {
  /// The underlying Talker instance — used by the log screen and error hooks.
  static final Talker talker = Talker(
    settings: TalkerSettings(useConsoleLogs: kDebugMode),
  );

  /// Optional crash-reporting destination. When set (in `bootstrap`), handled
  /// and uncaught errors are forwarded here in addition to the in-app log.
  static CrashSink? crashSink;

  /// Verbose / diagnostic message.
  static void debug(String message) => talker.debug(message);

  /// Informational message.
  static void info(String message) => talker.info(message);

  /// Warning.
  static void warning(String message) => talker.warning(message);

  /// Error, with an optional [error] object and [stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      talker.error(message, error, stackTrace);

  /// Records a caught exception (without a message) and forwards it to the
  /// [crashSink], if one is set, as a non-fatal report.
  static void handle(Object error, [StackTrace? stackTrace, String? message]) {
    talker.handle(error, stackTrace, message);
    crashSink?.report(
      error,
      stackTrace ?? StackTrace.current,
      context: message,
      fatal: false,
    );
  }

  /// Routes uncaught Flutter and async errors into the log and the [crashSink]
  /// (as fatal reports).
  ///
  /// Call once during start-up (see `bootstrap`).
  static void installErrorHandlers() {
    FlutterError.onError = (details) {
      talker.handle(
        details.exception,
        details.stack,
        details.summary.toString(),
      );
      crashSink?.report(
        details.exception,
        details.stack ?? StackTrace.current,
        context: details.summary.toString(),
        fatal: true,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      talker.handle(error, stack);
      crashSink?.report(error, stack, fatal: true);
      return true;
    };
  }
}
