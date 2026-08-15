import 'dart:async';

import 'package:dpip/core/logging/crash_sink.dart';
import 'package:dpip/core/logging/log_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Application-wide logging facade.
///
/// Always log through [Log] — **never** use `print` or `debugPrint`. It is
/// backed by Talker, which keeps a history for the in-app log screen and
/// captures uncaught Flutter/async errors.
abstract final class Log {
  /// Monotonic stopwatch started when the app boots — lets any code report
  /// "how long after launch" (e.g. bootstrap-ready and first-frame markers).
  static final Stopwatch sinceStart = Stopwatch()..start();

  /// The underlying Talker instance — used by the log screen and error hooks.
  static final Talker talker = Talker(
    settings: TalkerSettings(useConsoleLogs: kDebugMode),
  );

  /// Optional crash-reporting destination. When set (in `bootstrap`), handled
  /// and uncaught errors are forwarded here in addition to the in-app log.
  static CrashSink? crashSink;

  /// Where the log is persisted, once `bootstrap` has a database. Null before
  /// that and when the database would not open — logging then behaves exactly
  /// as it always did, in memory only.
  static LogStore? store;

  static StreamSubscription<TalkerData>? _bridge;

  /// Starts persisting every line to [store].
  ///
  /// Bridged off Talker's stream rather than added to each of the methods
  /// below, so nothing that already logs has to change and nothing new can
  /// forget to. Uncaught errors arrive through the same stream, which is the
  /// half that matters most after a crash.
  static void persistTo(LogStore logStore) {
    store = logStore;
    _bridge?.cancel();
    _bridge = talker.stream.listen((data) {
      logStore.add(
        StoredLog(
          time: data.time,
          level: data.logLevel?.name ?? 'info',
          message: data.displayMessage,
          error: (data.exception ?? data.error)?.toString(),
          stackTrace: data.stackTrace?.toString(),
        ),
      );
    });
  }

  /// Writes anything still buffered — call when the app goes to the
  /// background, which is the moment it is most likely to be killed.
  static Future<void> flush() async => store?.flush();

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

  /// Drops in-memory history entries older than [age]. The persisted table has
  /// its own 24-hour retention (see [LogStore]); this only trims what Talker
  /// holds for the current session.
  static void pruneOlderThan(Duration age) {
    final cutoff = DateTime.now().subtract(age);
    talker.history.removeWhere((entry) => entry.time.isBefore(cutoff));
  }

  /// Routes uncaught Flutter and async errors into the log and the [crashSink]
  /// (as fatal reports).
  ///
  /// Call once during start-up (see `bootstrap`).
  static void installErrorHandlers() {
    FlutterError.onError = (details) {
      // iOS hot-restart race, not a crash: the engine can still own the
      // previous isolate's platform views, so a fresh isolate re-issues the
      // same view id and UiKitView creation fails with `recreating_view`.
      // [BaseMap] remounts itself with a fresh id (readiness retry), so the
      // map recovers — report it as neither a log entry nor a fatal crash.
      if (details.exception is PlatformException &&
          (details.exception as PlatformException).code == 'recreating_view') {
        return;
      }
      // Overriding onError replaces the framework's own console presentation,
      // whose dump carries the diagnostics our summary drops — for a layout
      // fault (e.g. a RenderFlex overflow) that includes *which* widget and its
      // creation `file:line`. Keep that rich dump in debug so such errors stay
      // locatable; release stays quiet (presentError is a near no-op there).
      if (kDebugMode) FlutterError.presentError(details);
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
