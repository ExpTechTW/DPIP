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

  /// Verbose / diagnostic message.
  static void debug(String message) => talker.debug(message);

  /// Informational message.
  static void info(String message) => talker.info(message);

  /// Warning.
  static void warning(String message) => talker.warning(message);

  /// Error, with an optional [error] object and [stackTrace].
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      talker.error(message, error, stackTrace);

  /// Records a caught exception (without a message).
  static void handle(Object error, [StackTrace? stackTrace, String? message]) =>
      talker.handle(error, stackTrace, message);

  /// Routes uncaught Flutter and async errors into the log.
  ///
  /// Call once during start-up (see `bootstrap`).
  static void installErrorHandlers() {
    FlutterError.onError = (details) => talker.handle(
      details.exception,
      details.stack,
      details.summary.toString(),
    );
    PlatformDispatcher.instance.onError = (error, stack) {
      talker.handle(error, stack);
      return true;
    };
  }
}
