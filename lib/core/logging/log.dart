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

  static final TalkerSettings _settings = TalkerSettings(
    useConsoleLogs: kDebugMode,
  );

  /// Held so [replay] can write to it, and so clearing the screen clears the
  /// table too. Talker builds one itself otherwise, and keeps it private.
  static final _PersistedHistory _history = _PersistedHistory(_settings);

  /// The underlying Talker instance — used by the log screen and error hooks.
  static final Talker talker = Talker(settings: _settings, history: _history);

  /// How many lines the screen can show — Talker's own history ceiling, so
  /// reading more out of the database only evicts what was just read.
  static int get historyLimit => _settings.maxHistoryItems;

  /// Puts a line the log screen should show into its history, **without
  /// logging it**.
  ///
  /// `logCustom` is the obvious way and the wrong one: it publishes to the
  /// stream, which the persister writes from, and prints to the console when
  /// console logs are on. Replaying a day of stored lines through it therefore
  /// reprinted the whole table to the terminal *and* wrote every line back
  /// into the table it came from, growing a duplicate on each visit.
  ///
  /// Writing to history is the whole intent: the screen reads history.
  ///
  /// The normalisation below is what `_handleLogData` does on the way past,
  /// and skipping the logger skips it too. The screen groups its filter chips
  /// by `key` and colours a card by `key` first — so a line that arrives
  /// without one is uncounted, uncoloured, and lands in a chip labelled
  /// `undefined` together with every other level.
  static void replay(TalkerData data) {
    final key = data.key;
    if (key != null) {
      data.title = talker.settings.getTitleByKey(key);
      data.pen = talker.settings.getPenByKey(key, fallbackPen: data.pen);
    }
    _history.replay(data);
  }

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

  /// How many times one error may be reported before it is taken for a loop,
  /// and the window it has to repeat in to count.
  static const _repeatLimit = 8;
  static const _repeatWindow = Duration(seconds: 5);

  /// Signature -> (times seen, when the window opened). Capped, because the
  /// keys come from error text and an app that produces endless *distinct*
  /// errors must not also leak memory.
  static final Map<String, (int, Duration)> _repeats = {};

  /// Whether an error should be reported, or has become its own cause.
  ///
  /// Reporting an error is not free of consequence here: it goes to Talker,
  /// whose stream the log screen rebuilds on and the persister writes to disk
  /// from. So a fault raised *while rendering that screen* — a layout overflow
  /// is the everyday one — re-enters through the rebuild it just caused, and
  /// each turn adds a Crashlytics report and a database write. The screen
  /// stops responding, which is what a user reports as "tapping the log
  /// freezes the app".
  ///
  /// Avoiding one known overflow does not fix that; only breaking the loop
  /// does. A distinct error is always reported — this drops the *repeat*.
  static bool _admitError(String signature) {
    final now = sinceStart.elapsed;
    final prior = _repeats[signature];
    if (prior == null || now - prior.$2 > _repeatWindow) {
      if (_repeats.length > 64) _repeats.clear();
      _repeats[signature] = (1, now);
      return true;
    }
    final seen = prior.$1 + 1;
    _repeats[signature] = (seen, prior.$2);
    if (seen == _repeatLimit + 1) {
      // Once, and through `info` rather than an error, so saying "this is
      // looping" cannot itself be the next turn of the loop.
      talker.info(
        'error repeated $_repeatLimit times, suppressing: $signature',
      );
    }
    return seen <= _repeatLimit;
  }

  /// Forgets what has been seen — for tests, and for anywhere that genuinely
  /// wants a repeated error reported again.
  @visibleForTesting
  static void resetErrorRepeats() => _repeats.clear();

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
      // The library and summary rather than the stack: a layout fault reports
      // a different stack every frame while being the same fault.
      //
      // Checked before the console dump below, not after. Left after it, the
      // suppression covered the log, the crash report and the database — but
      // not the terminal, which kept printing the same fault every frame while
      // the stored record stayed clean. That is the shape the flood took: the
      // data was fine and the console was unusable.
      if (!_admitError('${details.library}/${details.summary}')) return;
      // Overriding onError replaces the framework's own console presentation,
      // whose dump carries the diagnostics our summary drops — for a layout
      // fault (e.g. a RenderFlex overflow) that includes *which* widget and its
      // creation `file:line`. Keep that rich dump in debug so such errors stay
      // locatable; release stays quiet (presentError is a near no-op there).
      // The first few still print, which is what makes the fault findable.
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
      if (!_admitError(error.runtimeType.toString())) return true;
      talker.handle(error, stack);
      crashSink?.report(error, stack, fatal: true);
      return true;
    };
  }
}

/// Talker's history, with the stored log tied to it and replay kept in its
/// place.
///
/// Two things the default could not do.
///
/// **Clearing.** The screen's clear button calls `talker.cleanHistory()`, which
/// empties the in-memory list and nothing else — so the log came straight back
/// on the next visit, replayed out of the table it was never removed from.
///
/// **Replay.** The default appends and evicts from the front, so replaying a
/// day of stored lines pushed the *live* session out — `DPIP starting up`
/// among them — and left the older lines sitting where the newer ones should
/// be. That is backwards twice over: the stored log is on disk and can be read
/// again, the running session cannot, and lines older than everything in
/// memory belong in front of it. Replay therefore inserts at the front and
/// only into free space.
class _PersistedHistory implements TalkerHistory {
  _PersistedHistory(this._settings);

  final TalkerSettings _settings;
  final _entries = <TalkerData>[];

  bool get _writable => _settings.useHistory && _settings.enabled;

  @override
  List<TalkerData> get history => _entries;

  @override
  void write(TalkerData data) {
    if (!_writable) return;
    if (_entries.length >= _settings.maxHistoryItems) _entries.removeAt(0);
    _entries.add(data);
  }

  /// A line read back off disk: older than everything here, and never worth
  /// evicting something that is not.
  void replay(TalkerData data) {
    if (!_writable) return;
    if (_entries.length >= _settings.maxHistoryItems) return;
    _entries.insert(0, data);
  }

  @override
  void clean() {
    _entries.clear();
    // Synchronous, and the delete is not, so the write is started and not
    // waited on. Nothing reads the table in between, and a failure there is
    // already swallowed — reporting a logging failure through the logger is
    // how a write loop starts.
    unawaited(Log.store?.clear() ?? Future<void>.value());
  }
}
