/// SQLite storage for the mesh: the conversation log and the radio's
/// utilization history.
///
/// **Not the HTTP cache database.** That one lives in the platform *cache*
/// directory, which the OS may purge whenever it wants space — correct for
/// re-fetchable bytes, wrong for a conversation. Mesh data is the opposite: it
/// exists precisely because it cannot be fetched again. So this opens its own
/// file in the application-support directory.
///
/// SQLite rather than the settings list the log used to be: settings is a
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
    this.voltage,
    this.nodesTotal,
    this.nodesOnline,
  });

  final DateTime at;

  /// Share of airtime the radio saw busy, and the share it spent transmitting.
  final double? channelUtilization;
  final double? airUtilTx;
  final int? batteryPercent;

  /// Pack voltage. Percent is the radio's own estimate from this and pins at
  /// 101% on external power; the volts are the measurement, and the only
  /// figure that shows a cell ageing.
  final double? voltage;

  /// How many nodes the radio's database held at this moment, and how many of
  /// them were heard recently enough to count as online. Plotted together this
  /// is the mesh's health over the day — a coverage collapse shows here before
  /// it shows anywhere else.
  final int? nodesTotal;
  final int? nodesOnline;
}

/// One reading from a *neighbouring* node.
///
/// Kept per node rather than aggregated: "the mesh is fine on average" is not
/// something anyone can act on, whereas "that repeater's pack has been falling
/// all afternoon" is.
class MeshNodeMetricSample {
  const MeshNodeMetricSample({
    required this.at,
    required this.node,
    this.battery,
    this.voltage,
    this.snr,
  });

  final DateTime at;
  final int node;
  final int? battery;
  final double? voltage;
  final double? snr;
}

class MeshStore {
  MeshStore(this._db, {DateTime Function()? now})
    : _now = now ?? (() => AppTime.utc.toLocal());

  static const String _messages = 'mesh_messages';
  static const String _nodes = 'mesh_nodes';
  static const String _metrics = 'mesh_metrics';
  static const String _channels = 'mesh_channels';
  static const String _nodeMetrics = 'mesh_node_metrics';

  /// How long the conversation log is kept. Generous because the whole point
  /// of the mesh is the times you cannot reach anything else; SQLite makes the
  /// size a non-issue where the old settings blob did not.
  static const Duration messageRetention = Duration(days: 30);

  /// How long utilization samples are kept — what the chart plots.
  static const Duration metricRetention = Duration(hours: 24);

  final Database _db;
  final DateTime Function() _now;

  static Future<void> createSchema(Database db) async {
    // The node table the radio hands over on every connect, kept for the times
    // there is no radio. A row per node, not a JSON blob in a settings key:
    // 250 nodes re-serialised on every telemetry packet is exactly what the
    // key-value store was bad at.
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_nodes ('
      'num INTEGER PRIMARY KEY NOT NULL, '
      'name TEXT NOT NULL, '
      'battery INTEGER, '
      'last_heard INTEGER, '
      'latitude REAL, '
      'longitude REAL, '
      'snr REAL NOT NULL DEFAULT 0, '
      'via_mqtt INTEGER NOT NULL DEFAULT 0)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS ${_nodes}_heard ON $_nodes(last_heard DESC)',
    );

    // The channel table, for the times there is no radio to ask.
    //
    // A channel's *name* is only known while connected — it arrives in the
    // config download and lives nowhere else. Without this table the chat
    // screen fell back to the slot number the moment the radio went away, so a
    // conversation the user knows as "DPIP" was labelled "CH2" whenever they
    // opened the page before the radio finished configuring. The stored log
    // outlives the connection; its labels have to as well.
    await db.execute(
      'CREATE TABLE IF NOT EXISTS $_channels ('
      'idx INTEGER PRIMARY KEY NOT NULL, '
      'name TEXT NOT NULL)',
    );

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
    // Added after the table shipped, so they arrive by ALTER rather than in
    // the CREATE above — see [_addColumn].
    await _addColumn(db, _metrics, 'voltage', 'REAL');
    await _addColumn(db, _metrics, 'nodes_total', 'INTEGER');
    await _addColumn(db, _metrics, 'nodes_online', 'INTEGER');

    // What the rest of the mesh looked like, one row per node per reading.
    //
    // The in-memory ring [MeshNodeStore] keeps is bounded by count, so on a
    // busy mesh it holds minutes; this holds a day, which is the window in
    // which "when did that node start failing" is a question anyone asks. The
    // composite key makes a re-emitted reading an overwrite rather than a
    // duplicate — the radio repeats a node's telemetry until it changes.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_nodeMetrics (
        ts INTEGER NOT NULL,
        node INTEGER NOT NULL,
        battery INTEGER,
        voltage REAL,
        snr REAL,
        PRIMARY KEY (ts, node)
      )
    ''');
    // Both reads are "this node, over time" and "everything since T".
    await db.execute(
      'CREATE INDEX IF NOT EXISTS ${_nodeMetrics}_node_ts '
      'ON $_nodeMetrics (node, ts)',
    );
  }

  /// Adds a column to an existing table, tolerating one that is already there.
  ///
  /// The durable schema is re-applied on every open as `CREATE TABLE IF NOT
  /// EXISTS`, which silently does nothing for a table that exists — so a new
  /// *column* on an old table never appears. Checked against `table_info`
  /// rather than catching the duplicate-column error, so a genuine failure
  /// still surfaces.
  static Future<void> _addColumn(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((row) => row['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    Log.info('mesh store: added $table.$column');
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
        'voltage': sample.voltage,
        'nodes_total': sample.nodesTotal,
        'nodes_online': sample.nodesOnline,
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
            voltage: (row['voltage'] as num?)?.toDouble(),
            nodesTotal: (row['nodes_total'] as num?)?.toInt(),
            nodesOnline: (row['nodes_online'] as num?)?.toInt(),
          ),
      ];
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store metrics');
      return const [];
    }
  }

  /// Appends readings for neighbouring nodes, as one transaction.
  ///
  /// Batched because a telemetry burst arrives twenty nodes at a time and a
  /// write each would be twenty commits.
  Future<void> addNodeMetrics(List<MeshNodeMetricSample> samples) async {
    if (samples.isEmpty) return;
    try {
      await _db.transaction((txn) async {
        final batch = txn.batch();
        for (final sample in samples) {
          batch.insert(_nodeMetrics, {
            'ts': sample.at.millisecondsSinceEpoch,
            'node': sample.node,
            'battery': sample.battery,
            'voltage': sample.voltage,
            'snr': sample.snr,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store addNodeMetrics');
    }
  }

  /// Node readings inside [metricRetention], oldest first. [node] narrows to
  /// one neighbour.
  Future<List<MeshNodeMetricSample>> nodeMetrics({int? node}) async {
    try {
      final since = _now().subtract(metricRetention).millisecondsSinceEpoch;
      final rows = await _db.query(
        _nodeMetrics,
        where: node == null ? 'ts >= ?' : 'ts >= ? AND node = ?',
        whereArgs: node == null ? [since] : [since, node],
        orderBy: 'ts ASC',
      );
      return [
        for (final row in rows)
          MeshNodeMetricSample(
            at: DateTime.fromMillisecondsSinceEpoch(row['ts']! as int),
            node: row['node']! as int,
            battery: (row['battery'] as num?)?.toInt(),
            voltage: (row['voltage'] as num?)?.toDouble(),
            snr: (row['snr'] as num?)?.toDouble(),
          ),
      ];
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store nodeMetrics');
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
      final metricCutoff = now.subtract(metricRetention).millisecondsSinceEpoch;
      await _db.delete(_metrics, where: 'ts < ?', whereArgs: [metricCutoff]);
      await _db.delete(
        _nodeMetrics,
        where: 'ts < ?',
        whereArgs: [metricCutoff],
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

  /// Every stored node, most recently heard first.
  /// Channel index → name, for every named channel the radio has reported.
  ///
  /// Only named channels are stored: an unnamed slot has nothing to remember,
  /// and keeping a row for it would let a stale blank outrank a name that
  /// arrives later.
  Future<Map<int, String>> readChannels() async {
    try {
      final rows = await _db.query(_channels);
      return {
        for (final row in rows) row['idx']! as int: row['name']! as String,
      };
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'reading mesh channels');
      return const {};
    }
  }

  /// Replaces the remembered channel names.
  ///
  /// Whole-table, like [writeNodes]: the radio always reports every slot, so a
  /// merge would keep the name of a channel the user has since deleted.
  Future<void> writeChannels(Map<int, String> names) async {
    try {
      await _db.transaction((txn) async {
        await txn.delete(_channels);
        final batch = txn.batch();
        for (final entry in names.entries) {
          if (entry.value.isEmpty) continue;
          batch.insert(_channels, {'idx': entry.key, 'name': entry.value});
        }
        await batch.commit(noResult: true);
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing mesh channels');
    }
  }

  Future<List<Map<String, Object?>>> readNodes({int limit = 250}) async {
    try {
      return await _db.query(_nodes, orderBy: 'last_heard DESC', limit: limit);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'reading mesh nodes');
      return const [];
    }
  }

  /// Replaces the stored node table.
  ///
  /// A whole-table swap rather than per-row upserts: the caller already holds
  /// the authoritative set in memory, the write is debounced, and 250 rows in
  /// one transaction is cheaper than reconciling deletions.
  Future<void> writeNodes(List<Map<String, Object?>> rows) async {
    try {
      await _db.transaction((txn) async {
        await txn.delete(_nodes);
        final batch = txn.batch();
        for (final row in rows) {
          batch.insert(_nodes, row);
        }
        await batch.commit(noResult: true);
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing mesh nodes');
    }
  }
}
