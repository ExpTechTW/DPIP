import 'dart:async';
import 'dart:io';

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
  /// Monotonic stopwatch for "how long after launch" markers — bootstrap-ready
  /// and first-frame among them.
  ///
  /// Started by [startClock], not by this initialiser, and the difference is
  /// not academic. A `static final` in Dart initialises **lazily, on first
  /// read**. While `..start()` here was the only thing that started it, the
  /// first read was the bootstrap-ready log line itself — so that line reported
  /// `0 ms` on every launch, and the first-frame marker measured from
  /// bootstrap-ready rather than from start. Two numbers that looked like
  /// measurements and were not.
  static final Stopwatch sinceStart = Stopwatch()..start();

  /// Starts the launch clock. Must be the first statement of `bootstrap`.
  ///
  /// Reading [sinceStart] here is what forces its lazy initialiser to run; the
  /// reset then pins zero to this moment rather than to whoever happened to
  /// look first.
  static void startClock() => sinceStart
    ..reset()
    ..start();

  /// Milliseconds since [startClock], for a phase marker.
  static int get sinceStartMs => sinceStart.elapsedMilliseconds;

  static final TalkerSettings _settings = TalkerSettings(
    useConsoleLogs: kDebugMode,
    // The tag on every line, in the log screen and in the console alike.
    // Upper case because it is a label, not prose, and it reads as a column
    // when a hundred lines are scanned for the one that is not `INFO`.
    // `WARN` rather than `WARNING` so the five that matter are within a
    // character of each other and the messages after them line up.
    //
    // Display only: the `level` column stores the enum's own name, so a
    // stored line still parses back to its [LogLevel].
    titles: {
      TalkerKey.verbose: 'VERBOSE',
      TalkerKey.debug: 'DEBUG',
      TalkerKey.info: 'INFO',
      TalkerKey.warning: 'WARN',
      TalkerKey.error: 'ERROR',
      TalkerKey.critical: 'CRITICAL',
      TalkerKey.exception: 'EXCEPTION',
    },
  );

  /// Optional crash-reporting destination. When set (in `bootstrap`), handled
  /// and uncaught errors are forwarded here in addition to the in-app log.
  static CrashSink? crashSink;

  /// Where the log is persisted, once `bootstrap` has a database. Null before
  /// that and when the database would not open — logging then behaves exactly
  /// as it always did, in memory only.
  static LogStore? store;

  static StreamSubscription<TalkerData>? _bridge;

  /// Held so the screen's history can be replaced from the table, and so
  /// clearing it clears the table too. Talker builds one itself otherwise,
  /// and keeps it private.
  static final _PersistedHistory _history = _PersistedHistory(_settings);

  /// Whether to colour the level tag in console output.
  ///
  ///     flutter run --dart-define=DPIP_LOG_COLOR=true
  ///
  /// Off by default, opt-in, **and never on iOS**. Two different reasons, and
  /// only one of them is about terminals:
  ///
  ///   * Whether an escape sequence renders is the window's business, and the
  ///     app cannot see the window — the bytes are written on the device and
  ///     read by whatever is attached to `flutter run`. VS Code's Debug
  ///     Console prints them literally; its integrated terminal renders them.
  ///     Same build, different window, so it has to be a choice.
  ///   * On iOS it never arrives intact regardless. The platform's log path
  ///     escapes the escape character itself, so even a terminal that does
  ///     support ANSI receives a backslash followed by the sequence and prints
  ///     it — flutter/flutter#20663. Turning the flag on there does nothing
  ///     but add noise, so it does not turn on.
  ///
  /// Not a font, either: a font supplies glyphs, and an escape sequence is an
  /// instruction the terminal either acts on or prints.
  static final bool enableConsoleColor =
      const bool.fromEnvironment('DPIP_LOG_COLOR') && !Platform.isIOS;

  /// Console output, one plain line per entry.
  ///
  /// The default draws every line inside a box and paints it with ANSI escapes.
  /// Neither survives the trip: `flutter run` prefixes each line with
  /// `flutter: `, so a three-line box becomes three prefixed lines around one
  /// message, and the escapes arrive as the literal text `^[[38;5;4m` because
  /// nothing on that pipe interprets them. What was meant as colour reads as
  /// noise, and the message is the only part anyone wanted.
  ///
  /// Colour is not lost so much as never delivered — turn `enableColors` back
  /// on if the output is ever read somewhere that renders it.
  static final TalkerLogger _logger = TalkerLogger(
    settings: TalkerLoggerSettings(enableColors: enableConsoleColor),
    formatter: const TagFormatter(),
  );

  /// The underlying Talker instance — used by the log screen and error hooks.
  static final Talker talker = Talker(
    settings: _settings,
    history: _history,
    logger: _logger,
  );

  /// How many lines the screen can show — Talker's own history ceiling, so
  /// reading more out of the database only evicts what was just read.
  static int get historyLimit => _settings.maxHistoryItems;

  /// Starts persisting every line to [store].
  ///
  /// Bridged off Talker's stream rather than added to each of the methods
  /// below, so nothing that already logs has to change and nothing new can
  /// forget to. Uncaught errors arrive through the same stream, which is the
  /// half that matters most after a crash.
  static void persistTo(LogStore logStore) {
    store = logStore;
    _bridge?.cancel();
    _bridge = talker.stream.listen((data) => logStore.add(_stored(data)));
    // Everything logged before the database opened is in memory and nowhere
    // else — the startup lines, and whatever went wrong while opening it.
    // Those are precisely the lines that explain a crash during launch, and
    // they were never written. Subscribing first and copying after means a
    // line arriving in between is stored twice rather than lost.
    for (final data in List<TalkerData>.of(talker.history)) {
      logStore.add(_stored(data));
    }
  }

  static StoredLog _stored(TalkerData data) => StoredLog(
    time: data.time,
    level: data.logLevel?.name ?? 'info',
    message: data.displayMessage,
    error: (data.exception ?? data.error)?.toString(),
    stackTrace: data.stackTrace?.toString(),
  );

  /// Replaces the screen's history with what is on disk.
  ///
  /// The database is the authority: every line goes through [persistTo], and
  /// what was logged before it opened is copied in there, so memory holds
  /// nothing the table does not. Keeping both and merging them was the source
  /// of every ordering and eviction problem this screen had — a replayed line
  /// evicting the running session, older lines sitting after newer ones,
  /// duplicates on each visit.
  ///
  /// [lines] is newest first, the order the store returns.
  static void reload(Iterable<TalkerData> lines) {
    // What `_handleLogData` does on the way past, and what skipping the logger
    // skips: the screen groups its filter chips by `key` and colours a card by
    // it, so a line that arrives without a title and pen derived from that key
    // is uncounted, uncoloured, and labelled `log`.
    for (final data in lines) {
      final key = data.key;
      if (key == null) continue;
      data.title = talker.settings.getTitleByKey(key);
      data.pen = talker.settings.getPenByKey(key, fallbackPen: data.pen);
    }
    _history.replaceAll(lines.toList().reversed);
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

  /// Debug-only asserts raised from inside a package, said once and then
  /// dropped for the rest of the session.
  ///
  /// Keyed on the summary rather than on the package, because there is nothing
  /// here that names the package: the framework raises these from inside the
  /// offending widget's own `build`, and the widget that *wrapped* it built in
  /// a different Element and is not on the stack. So this cannot distinguish
  /// a package's occurrence from one of ours — which is why the entry is still
  /// logged once, with its summary, instead of being dropped silently.
  ///
  /// Delete an entry when its package fixes it; the log line is the reminder.
  static const List<(String, String)> _knownBenignAsserts = [
    (
      'ListTile background color or ink splashes may be invisible',
      'talker_flutter draws its Actions sheet as a coloured box with bare '
          'ListTiles inside it (still true on 5.1.20), so opening that sheet '
          'reports once per row. Debug-only, and the sheet renders correctly. '
          'If this appears anywhere but the log screen, it is ours.',
    ),
  ];

  static final Set<String> _saidAsserts = {};

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
  static void resetErrorRepeats() {
    _repeats.clear();
    _saidAsserts.clear();
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
      // A known defect in somebody else's widget. One line, then silence —
      // this one arrives once per row of a sheet, and the sheet it floods is
      // the log screen itself.
      final summary = details.summary.toString();
      for (final (marker, explanation) in _knownBenignAsserts) {
        if (!summary.contains(marker)) continue;
        if (_saidAsserts.add(marker)) talker.warning('$summary $explanation');
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
      if (!_admitError('${details.library}/$summary')) return;
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

  @override
  List<TalkerData> get history => _entries;

  @override
  void write(TalkerData data) {
    if (!_settings.useHistory || !_settings.enabled) return;
    if (_entries.length >= _settings.maxHistoryItems) _entries.removeAt(0);
    _entries.add(data);
  }

  /// Oldest first. Used when the screen loads the stored log, which is the
  /// whole truth rather than an addition to it.
  void replaceAll(Iterable<TalkerData> lines) {
    _entries
      ..clear()
      ..addAll(lines);
    while (_entries.length > _settings.maxHistoryItems) {
      _entries.removeAt(0);
    }
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

/// One line: the level tag, then the message.
///
/// With colour on, only the tag is painted. A fully coloured line is harder to
/// read than a plain one, and the tag is the part being scanned for; it is
/// also short, so a leak into a window that cannot render it costs one token
/// rather than the whole line.
/// The widest tag DPIP writes, so every colon lands in the same column and the
/// messages read as one.
const int _tagWidth = 10; // `[CRITICAL]`

/// One log line, in the shape both the console and the dump use.
///
///     [5:32:38][INFO]    : Firebase initialized
///     [5:32:39][DEBUG]   : [rts] SSE served by {"location":"lb-tpe1"}
///
/// One shape for both, so a line pasted out of a terminal and a line pasted
/// out of an uploaded dump are the same line — nobody has to learn two.
String logLine({
  required String tag,
  required DateTime time,
  required String message,
}) {
  final clock =
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}'
      ':${time.second.toString().padLeft(2, '0')}';
  return '[$clock]${'[$tag]'.padRight(_tagWidth)}: $message';
}

/// Rewrites Talker's own line into [logLine]'s shape, and colours the tag.
///
/// Talker hands a formatter the finished string rather than the entry, and its
/// shape is fixed: `[TITLE] | TIME | message`. Rebuilding from that is a parse,
/// which is why the pattern is pinned by a test — if Talker ever changes the
/// layout, the test says so instead of the terminal.
class TagFormatter implements LoggerFormatter {
  const TagFormatter();

  /// `[INFO] | 5:32:38 655ms | message`
  static final RegExp _talkerLine = RegExp(
    r'^\[([^\]]+)\] \| (\d{1,2}):(\d{2}):(\d{2})[^|]*\| ',
  );

  @override
  String fmt(LogDetails details, TalkerLoggerSettings settings) {
    final raw = details.message?.toString() ?? '';
    final match = _talkerLine.firstMatch(raw);
    if (match == null) return raw;

    final tag = match.group(1)!;
    final clock = '${match.group(2)}:${match.group(3)}:${match.group(4)}';
    final message = raw.substring(match.end);
    final head = '[$clock]${'[$tag]'.padRight(_tagWidth)}';
    if (!settings.enableColors) return '$head: $message';
    // Only the tag is painted — see [Log.enableConsoleColor].
    return '[$clock]${details.pen.write('[$tag]'.padRight(_tagWidth))}'
        ': $message';
  }
}
