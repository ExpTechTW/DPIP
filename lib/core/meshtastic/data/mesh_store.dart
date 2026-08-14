/// SQLite storage for the mesh: the conversation log and the radio's
/// utilization history.
///
/// **Not the HTTP cache database.** That one lives in the platform *cache*
/// directory, which the OS may purge whenever it wants space — correct for
/// re-fetchable bytes, wrong for a conversation. Mesh data is the opposite: it
/// exists precisely because it cannot be fetched again. So this opens its own
/// file in the application-support directory.
///
/// SQLite rather than the prefs list the log used to be: prefs is a
/// read-whole-file/write-whole-file key-value store, so every incoming message
/// re-serialised the entire log, the whole thing lived in memory, and asking
/// for "this channel, newest 50" meant filtering in Dart. Here that is an
/// indexed query, retention is one `DELETE`, and duplicate suppression is a
/// unique index instead of a linear scan.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:sqflite/sqflite.dart';

/// One line of the conversation log.
class MeshStoredMessage {
  const MeshStoredMessage({
    required this.from,
    required this.channel,
    required this.text,
    required this.timestamp,
    required this.outgoing,
  });

  final int from;
  final int channel;
  final String text;
  final DateTime timestamp;
  final bool outgoing;
}

/// One utilization sample, as the radio reported it.
class MeshMetricSample {
  const MeshMetricSample({
    required this.at,
    this.channelUtilization,
    this.airUtilTx,
    this.batteryPercent,
  });

  final DateTime at;

  /// Share of airtime the radio saw busy, and the share it spent transmitting.
  final double? channelUtilization;
  final double? airUtilTx;
  final int? batteryPercent;
}

class MeshStore {
  MeshStore(this._db, {DateTime Function()? now})
    : _now = now ?? (() => AppTime.utc.toLocal());

  static const String _messages = 'mesh_messages';
  static const String _metrics = 'mesh_metrics';

  /// How long the conversation log is kept. Generous because the whole point
  /// of the mesh is the times you cannot reach anything else; SQLite makes the
  /// size a non-issue where the old prefs blob did not.
  static const Duration messageRetention = Duration(days: 30);

  /// How long utilization samples are kept — what the chart plots.
  static const Duration metricRetention = Duration(hours: 24);

  final Database _db;
  final DateTime Function() _now;

  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts INTEGER NOT NULL,
        node INTEGER NOT NULL,
        channel INTEGER NOT NULL,
        text TEXT NOT NULL,
        outgoing INTEGER NOT NULL DEFAULT 0
      )
    ''');
    // Duplicate suppression as a constraint, not a scan: a reconnect replays
    // packets the log may already hold, and `INSERT OR IGNORE` drops them at
    // the storage layer.
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS ${_messages}_identity '
      'ON $_messages (node, channel, ts, text)',
    );
    // The read is always "this channel, newest first".
    await db.execute(
      'CREATE INDEX IF NOT EXISTS ${_messages}_channel_ts '
      'ON $_messages (channel, ts DESC)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_metrics (
        ts INTEGER PRIMARY KEY,
        channel_util REAL,
        air_util REAL,
        battery INTEGER
      )
    ''');
  }

  /// Appends [message], ignoring one the log already holds. Returns whether it
  /// was new — the caller uses that to decide whether to notify or re-render.
  Future<bool> addMessage(MeshStoredMessage message) async {
    try {
      final id = await _db.insert(_messages, {
        'ts': message.timestamp.millisecondsSinceEpoch,
        'node': message.from,
        'channel': message.channel,
        'text': message.text,
        'outgoing': message.outgoing ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      return id != 0;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store addMessage');
      return false;
    }
  }

  /// The newest [limit] messages, newest first; [channel] narrows to one
  /// conversation.
  Future<List<MeshStoredMessage>> messages({
    int? channel,
    int limit = 200,
  }) async {
    try {
      final rows = await _db.query(
        _messages,
        where: channel == null ? null : 'channel = ?',
        whereArgs: channel == null ? null : [channel],
        orderBy: 'ts DESC, id DESC',
        limit: limit,
      );
      return [for (final row in rows) _readMessage(row)];
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store messages');
      return const [];
    }
  }

  /// How many messages each channel holds — what the channel picker badges.
  Future<Map<int, int>> messageCountsByChannel() async {
    try {
      final rows = await _db.rawQuery(
        'SELECT channel, COUNT(*) AS n FROM $_messages GROUP BY channel',
      );
      return {
        for (final row in rows) (row['channel']! as int): (row['n']! as int),
      };
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store counts');
      return const {};
    }
  }

  Future<void> clearMessages() async {
    try {
      await _db.delete(_messages);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store clearMessages');
    }
  }

  /// Records a utilization sample, keyed by the moment the radio reported it
  /// so the same telemetry can't be stored twice.
  Future<void> addMetric(MeshMetricSample sample) async {
    try {
      await _db.insert(_metrics, {
        'ts': sample.at.millisecondsSinceEpoch,
        'channel_util': sample.channelUtilization,
        'air_util': sample.airUtilTx,
        'battery': sample.batteryPercent,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store addMetric');
    }
  }

  /// Utilization samples inside [metricRetention], oldest first — chart order.
  Future<List<MeshMetricSample>> metrics() async {
    try {
      final since = _now().subtract(metricRetention).millisecondsSinceEpoch;
      final rows = await _db.query(
        _metrics,
        where: 'ts >= ?',
        whereArgs: [since],
        orderBy: 'ts ASC',
      );
      return [
        for (final row in rows)
          MeshMetricSample(
            at: DateTime.fromMillisecondsSinceEpoch(row['ts']! as int),
            channelUtilization: (row['channel_util'] as num?)?.toDouble(),
            airUtilTx: (row['air_util'] as num?)?.toDouble(),
            batteryPercent: (row['battery'] as num?)?.toInt(),
          ),
      ];
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store metrics');
      return const [];
    }
  }

  /// Drops anything past its retention window. Cheap enough to run on every
  /// app start; there is no schedule to get wrong.
  Future<void> prune() async {
    try {
      final now = _now();
      await _db.delete(
        _messages,
        where: 'ts < ?',
        whereArgs: [now.subtract(messageRetention).millisecondsSinceEpoch],
      );
      await _db.delete(
        _metrics,
        where: 'ts < ?',
        whereArgs: [now.subtract(metricRetention).millisecondsSinceEpoch],
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store prune');
    }
  }

  MeshStoredMessage _readMessage(Map<String, Object?> row) => MeshStoredMessage(
    from: row['node']! as int,
    channel: row['channel']! as int,
    text: row['text']! as String,
    timestamp: DateTime.fromMillisecondsSinceEpoch(row['ts']! as int),
    outgoing: (row['outgoing']! as int) == 1,
  );
}
