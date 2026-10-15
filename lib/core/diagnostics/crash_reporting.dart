/// Crash reports to Crashlytics, from builds that are not production.
///
/// Two pieces: [CrashReporter], the one seam that touches the Firebase plugin,
/// and [ReportingCrashSink], which decides what deserves a report. The policy
/// of *which builds* report lives in `prerelease_diagnostics.dart`.
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpip/core/logging/crash_sink.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// What the diagnostics need from a crash-reporting service.
///
/// An interface so the decisions above it are testable without a platform
/// channel, and so nothing else in the app imports the Firebase plugin.
abstract interface class CrashReporter {
  /// Turns sending on or off. Persisted by the SDK across launches, which is
  /// why a production build has to say `false` every time — see
  /// [PrereleaseDiagnostics.start].
  Future<void> setCollectionEnabled(bool enabled);

  /// Drops reports recorded while collection was off, so they cannot leave the
  /// device later.
  Future<void> deleteUnsentReports();

  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    required bool fatal,
  });

  /// A line attached to whatever report this session sends next. Sends
  /// nothing on its own.
  Future<void> log(String message);

  /// A value attached to every report this session sends. Sends nothing on
  /// its own.
  Future<void> setKey(String key, Object value);
}

/// [CrashReporter] over `firebase_crashlytics`.
class FirebaseCrashReporter implements CrashReporter {
  FirebaseCrashReporter([FirebaseCrashlytics? crashlytics])
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> deleteUnsentReports() => _crashlytics.deleteUnsentReports();

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    required bool fatal,
  }) => _crashlytics.recordError(
    error,
    stackTrace,
    reason: reason,
    fatal: fatal,
    // The plugin prints the whole report to the console in debug when left
    // to its default. Every line already went through `Log` before reaching
    // the sink, so that would be a second copy in a different shape.
    printDetails: false,
  );

  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);
}

/// Forwards [Log]'s errors to a [CrashReporter], keeping only the ones a crash
/// dashboard can do something with.
///
/// Three filters, each because the alternative was measurable noise:
///
/// * **Transport failures are dropped.** A phone on a train fails every poll,
///   and `guardResult` hands each one to `Log.handle`. Those are the network's
///   story, already in the in-app log, and none is a defect in the app. Dropping
///   every [DioException] also keeps request URLs out of the report — the
///   location endpoint carries the push token and coordinates in its path.
/// * **One report per signature per session.** A layout fault re-reports every
///   frame. Crashlytics would group them into one issue anyway; sending them
///   costs a platform call, a file write and an upload each.
/// * **[maxReportsPerSession] in total.** The Android SDK keeps only the newest
///   eight recorded exceptions of a session and discards the rest, so a ninth
///   would push out the first — which is usually the one that explains the
///   others.
class ReportingCrashSink implements CrashSink {
  ReportingCrashSink(this._reporter);

  /// Matches the Android SDK's own per-session ceiling — see the class doc.
  static const int maxReportsPerSession = 8;

  final CrashReporter _reporter;
  final Set<String> _seen = {};
  int _sent = 0;
  bool _saidFull = false;

  @override
  void report(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    if (isTransportFailure(error)) return;
    if (!_seen.add(signature(error, context))) return;
    if (_sent >= maxReportsPerSession) {
      if (!_saidFull) {
        _saidFull = true;
        // `info`, not `handle`: nothing that this sink is told about may be
        // reported through the path that feeds it.
        Log.info(
          'crash reports: $maxReportsPerSession sent this session, '
          'keeping the rest in the local log only',
        );
      }
      return;
    }
    _sent++;
    unawaited(
      _reporter
          .recordError(error, stackTrace, reason: context, fatal: fatal)
          .catchError((Object failure) {
            // Never `Log.handle`: that is the call that brought us here.
            Log.warning('crash report not recorded: $failure');
          }),
    );
  }

  /// What makes two reports the same report.
  ///
  /// The first line of the message, not the stack: a stack differs by caller
  /// for what is one fault, and a message is the part a person would compare.
  /// Clipped so an error that embeds a response body cannot make the set grow
  /// without bound.
  static String signature(Object error, String? context) {
    final text = error.toString();
    final newline = text.indexOf('\n');
    final first = newline < 0 ? text : text.substring(0, newline);
    final clipped = first.length > 160 ? first.substring(0, 160) : first;
    return '${error.runtimeType}|${context ?? ''}|$clipped';
  }

  /// Whether [error] is the network failing rather than the app.
  static bool isTransportFailure(Object error) =>
      error is DioException ||
      error is SocketException ||
      error is HttpException ||
      error is TlsException ||
      error is TimeoutException;
}
