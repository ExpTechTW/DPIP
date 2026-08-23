/// The `logs` table — the app's own log, kept for 24 hours.
///
/// Talker already holds a history, but only in memory: it dies with the
/// process. That is precisely the wrong lifetime for the thing you want after
/// a crash, a background kill, or a "it did nothing when I tapped it" that the
/// user only mentions the next day. Persisting it is what makes the in-app log
/// screen worth opening.
///
/// **Buffered, not write-through.** A log line must never cost a database
/// round-trip on the calling thread — logging is called from hot paths and
/// from error handlers, and a logger that can stall the UI is worse than no
/// logger. Lines accumulate in memory and are flushed on a timer, in one
/// transaction, plus whenever the app goes to the background (the moment it is
/// most likely to be killed).
///
/// **24 hours, enforced on write, not on read.** Retention that only runs when
/// something reads the table is retention that never runs. Old rows are pruned
/// as part of the flush, so the table stays bounded whether or not anyone ever
/// opens the log screen.
library;

import 'dart:async';

import 'package:sqlite_async/sqlite_async.dart';

/// The table this store owns.
const String logTable = 'logs';

/// How long a line is kept.
const Duration logRetention = Duration(hours: 24);

/// The hard ceiling on stored lines, enforced on every write.
///
/// Two jobs. It is a backstop under the age rule, because the age rule trusts
/// a clock: a device whose clock jumps forward makes every stored line look
/// older than the window, and the age delete empties the table — throwing away
/// the record of the launch being investigated, which is the one thing this
/// table exists for. Keeping the newest rows regardless means no clock event
/// can leave it empty.
///
/// And it bounds a burst. A fault that logs every frame writes faster than any
/// sweep runs, so the cap is applied in the same transaction as the insert
/// rather than only on the hourly pass — the table cannot exceed this between
/// sweeps, only within one batch.
const int logMaxRows = 5000;

/// One persisted line.
class StoredLog {
  const StoredLog({
    required this.time,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  });

  final DateTime time;

  /// Talker's level name — `info`, `warning`, `error`, `debug`.
  final String level;

  final String message;
  final String? error;
  final String? stackTrace;
}

// The flush knobs arrive as named parameters and are copied to private
// fields; an initializing formal cannot be used because named parameters may
// not be private.
// ignore_for_file: prefer_initializing_formals
class LogStore {
  LogStore(
    this._db, {
    DateTime Function()? now,
    Duration flushInterval = const Duration(seconds: 3),
    int flushAt = 64,
  }) : _now = now ?? DateTime.now,
       _flushInterval = flushInterval,
       _flushAt = flushAt;

  final SqliteDatabase _db;
  final DateTime Function() _now;
  final Duration _flushInterval;

  /// Flush early once this many lines are waiting — a burst (a stack trace
  /// storm, a reconnect loop) should not sit in memory until the timer.
  final int _flushAt;

  final _pending = <StoredLog>[];
  Timer? _timer;
  Future<void> _databaseTail = Future<void>.value();

  /// Preserves the order in which persistence operations were requested.
  ///
  /// `Talker.cleanHistory()` is synchronous, so its database delete is fired
  /// without an await. Without this lane, a log written immediately after the
  /// clear can flush first and then be erased by the older delete. SQLite
  /// serialises statements, but not in Dart call order when two futures race.
  Future<void> _enqueueDatabase(Future<void> Function() operation) {
    final next = _databaseTail.then((_) => operation());
    _databaseTail = next.catchError((Object _) {
      // Persistence methods already swallow database errors. Keep the lane
      // usable if an unexpected asynchronous failure still escapes one.
    });
    return next;
  }

  /// Creates the table. Safe on every open.
  static Future<void> createSchema(SqliteDatabase db) async {
    // One call: this re-runs on every launch (the IF NOT EXISTS is the
    // migration mechanism), so both statements ride one background-isolate
    // round trip instead of two serial awaits.
    await db.executeMultiple(
      'CREATE TABLE IF NOT EXISTS $logTable ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'time INTEGER NOT NULL, '
      'level TEXT NOT NULL, '
      'message TEXT NOT NULL, '
      'error TEXT, '
      'stack TEXT);'
      // Both the retention delete and every read are ordered by time.
      'CREATE INDEX IF NOT EXISTS ${logTable}_time ON $logTable(time)',
    );
  }

  /// Queues a line. Returns immediately — never touches the database.
  void add(StoredLog entry) {
    _pending.add(entry);
    if (_pending.length >= _flushAt) {
      unawaited(flush());
      return;
    }
    _timer ??= Timer(_flushInterval, () => unawaited(flush()));
  }

  /// Drops anything past the retention window, whether or not there is
  /// anything to write.
  ///
  /// [flush] also prunes, but only as part of writing a batch — it returns
  /// early when nothing is buffered. So an app left running with a quiet log
  /// (the radio disconnected, nothing failing) never pruned at all, and the
  /// table kept yesterday for as long as the process lived. This is what the
  /// hourly sweep calls; never throws, for the same reason [flush] does not.
  Future<void> prune() async {
    await _enqueueDatabase(() async {
      try {
        await _db.writeTransaction((tx) async {
          await tx.execute('DELETE FROM $logTable WHERE time < ?', [
            _now().toUtc().subtract(logRetention).millisecondsSinceEpoch,
          ]);
          // See [logMaxRows]: the newest lines survive whatever the clock says.
          await tx.execute(
            'DELETE FROM $logTable WHERE id NOT IN ('
            'SELECT id FROM $logTable ORDER BY id DESC LIMIT ?)',
            [logMaxRows],
          );
        });
      } on Object {
        // Reporting a logging failure through the logger is how a write loop
        // starts.
      }
    });
  }

  /// Writes everything queued and drops anything past the retention window.
  ///
  /// Never throws: a logger that can fail a caller is a logger that turns a
  /// diagnostic into an outage.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_pending.isEmpty) return _databaseTail;
    final batch = List<StoredLog>.of(_pending);
    _pending.clear();
    await _enqueueDatabase(() async {
      try {
        await _db.writeTransaction((tx) async {
          for (final entry in batch) {
            await tx.execute(
              'INSERT INTO $logTable (time, level, message, error, stack) '
              'VALUES (?, ?, ?, ?, ?)',
              [
                entry.time.toUtc().millisecondsSinceEpoch,
                entry.level,
                entry.message,
                entry.error,
                entry.stackTrace,
              ],
            );
          }
          await tx.execute('DELETE FROM $logTable WHERE time < ?', [
            _now().toUtc().subtract(logRetention).millisecondsSinceEpoch,
          ]);
          // The count ceiling in the same transaction as the insert, so a
          // burst cannot outrun it. `id` rather than `time` because it is the
          // primary key and monotonic: a clock that steps backwards would
          // otherwise make the newest rows look like the oldest and delete
          // them.
          await tx.execute(
            'DELETE FROM $logTable WHERE id NOT IN ('
            'SELECT id FROM $logTable ORDER BY id DESC LIMIT ?)',
            [logMaxRows],
          );
        });
      } on Object {
        // Deliberately silent: reporting a logging failure through the logger
        // is how a write loop starts.
      }
    });
  }

  /// The most recent lines, newest first.
  Future<List<StoredLog>> recent({int limit = 500, String? level}) async {
    await _databaseTail;
    try {
      final rows = level == null
          ? await _db.getAll(
              'SELECT time, level, message, error, stack FROM $logTable '
              'ORDER BY time DESC, id DESC LIMIT ?',
              [limit],
            )
          : await _db.getAll(
              'SELECT time, level, message, error, stack FROM $logTable '
              'WHERE level = ? ORDER BY time DESC, id DESC LIMIT ?',
              [level, limit],
            );
      return [
        for (final row in rows)
          StoredLog(
            time: DateTime.fromMillisecondsSinceEpoch(
              row['time']! as int,
              isUtc: true,
            ).toLocal(),
            level: row['level']! as String,
            message: row['message']! as String,
            error: row['error'] as String?,
            stackTrace: row['stack'] as String?,
          ),
      ];
    } on Object {
      return const [];
    }
  }

  /// How many lines are stored — the log screen shows it, and it is the cheap
  /// way to see that persistence is actually working.
  Future<int> count() async {
    await _databaseTail;
    try {
      final row = await _db.get('SELECT COUNT(*) AS n FROM $logTable');
      return (row['n'] as num).toInt();
    } on Object {
      return 0;
    }
  }

  /// Empties the table — the log screen's "clear" action.
  Future<void> clear() async {
    _pending.clear();
    await _enqueueDatabase(() async {
      try {
        await _db.execute('DELETE FROM $logTable');
      } on Object {
        // Nothing useful to say, and nowhere safe to say it.
      }
    });
  }

  /// Stops the timer and writes what is left.
  Future<void> dispose() async {
    await flush();
    _timer?.cancel();
    _timer = null;
  }
}
