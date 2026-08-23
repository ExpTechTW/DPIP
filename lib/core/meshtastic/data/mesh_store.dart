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
import 'package:sqlite_async/sqlite_async.dart';

/// One line of the conversation log.
class MeshStoredMessage {
  const MeshStoredMessage({
    required this.from,
    required this.channel,
    required this.text,
    required this.timestamp,
    required this.outgoing,
    this.binary = false,
  });

  final int from;
  final int channel;

  /// What to show. A hex dump when [binary].
  final String text;
  final DateTime timestamp;
  final bool outgoing;

  /// The body was not text. Defaulted rather than required because every row
  /// written before the column existed is text by construction — the decoder
  /// that produced them could not represent anything else.
  final bool binary;
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
    this.rxPackets,
    this.txPackets,
    this.lsRx,
    this.lsRxBad,
    this.lsTx,
    this.lsRxDupe,
    this.lsTxRelay,
    this.lsTxRelayCancel,
    this.heapFree,
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

  /// Packets received/sent since the *previous* sample — deltas, not the
  /// transport's session counters, so the series survives the counters
  /// resetting on a reconnect and each point means "activity in this slice".
  final int? rxPackets;
  final int? txPackets;

  /// The **radio's own** counters over the same slice, also as deltas.
  ///
  /// Not a duplicate of [rxPackets]/[txPackets]: those count what reached the
  /// app over BLE, these count what the modem actually saw. The gap between
  /// them is packets the radio heard on channels we have no key for, plus
  /// anything the BLE queue dropped — which makes the disagreement a
  /// measurement rather than an inconsistency.
  final int? lsRx;

  /// Packets that failed CRC. Climbing while airtime stays flat is
  /// interference; climbing with airtime is congestion.
  final int? lsRxBad;

  final int? lsTx;

  /// Packets discarded as duplicates the mesh had already delivered. Near
  /// zero means this radio is somebody's only path.
  final int? lsRxDupe;

  /// Rebroadcasts this radio performed, and ones it abandoned because another
  /// node got there first.
  final int? lsTxRelay;
  final int? lsTxRelayCancel;

  /// Free heap **at this moment** — a level, not a delta. Its slope across the
  /// day is what forecasts a firmware reboot.
  final int? heapFree;
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
  static const String _reads = 'mesh_reads';

  /// How long the conversation log is kept. Generous because the whole point
  /// of the mesh is the times you cannot reach anything else; SQLite makes the
  /// size a non-issue where the old settings blob did not.
  static const Duration messageRetention = Duration(days: 30);

  /// How long utilization samples are kept — what the chart plots.
  static const Duration metricRetention = Duration(hours: 24);

  final SqliteDatabase _db;
  final DateTime Function() _now;

  static Future<void> createSchema(SqliteDatabase db) async {
    // This re-runs on every launch (the IF NOT EXISTS is the migration
    // mechanism), so every statement rides one background-isolate round trip:
    // one probe per table with ALTER-added columns, then everything else in a
    // single executeMultiple, instead of ten serial awaits.
    // One probe per table that has gained columns since it shipped. An empty
    // set means the table does not exist yet, so the CREATE below makes it
    // without them and every ALTER is needed.
    final existing = <String, Set<String>>{};
    for (final table in _alterColumns.keys) {
      existing[table] = {
        for (final row in await db.getAll('PRAGMA table_info($table)'))
          row['name'] as String,
      };
    }

    await db.executeMultiple('''
      CREATE TABLE IF NOT EXISTS $_nodes (
        num INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL,
        battery INTEGER,
        last_heard INTEGER,
        latitude REAL,
        longitude REAL,
        snr REAL NOT NULL DEFAULT 0,
        via_mqtt INTEGER NOT NULL DEFAULT 0);
      CREATE INDEX IF NOT EXISTS ${_nodes}_heard ON $_nodes(last_heard DESC);
      -- The channel table, for the times there is no radio to ask.
      --
      -- A channel's *name* is only known while connected — it arrives in the
      -- config download and lives nowhere else. Without this table the chat
      -- screen fell back to the slot number the moment the radio went away, so
      -- a conversation the user knows as "DPIP" was labelled "CH2" whenever
      -- they opened the page before the radio finished configuring. The stored
      -- log outlives the connection; its labels have to as well.
      CREATE TABLE IF NOT EXISTS $_channels (
        idx INTEGER PRIMARY KEY NOT NULL,
        name TEXT NOT NULL);
      CREATE TABLE IF NOT EXISTS $_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts INTEGER NOT NULL,
        node INTEGER NOT NULL,
        channel INTEGER NOT NULL,
        text TEXT NOT NULL,
        outgoing INTEGER NOT NULL DEFAULT 0);
      -- Duplicate suppression as a constraint, not a scan: a reconnect replays
      -- packets the log may already hold, and `INSERT OR IGNORE` drops them at
      -- the storage layer.
      CREATE UNIQUE INDEX IF NOT EXISTS ${_messages}_identity
        ON $_messages (node, channel, ts, text);
      -- The read is always "this channel, newest first".
      CREATE INDEX IF NOT EXISTS ${_messages}_channel_ts
        ON $_messages (channel, ts DESC);
      CREATE TABLE IF NOT EXISTS $_metrics (
        ts INTEGER PRIMARY KEY,
        channel_util REAL,
        air_util REAL,
        battery INTEGER);
      -- What the rest of the mesh looked like, one row per node per reading.
      --
      -- The in-memory ring [MeshNodeStore] keeps is bounded by count, so on a
      -- busy mesh it holds minutes; this holds a day, which is the window in
      -- which "when did that node start failing" is a question anyone asks.
      -- The composite key makes a re-emitted reading an overwrite rather than
      -- a duplicate — the radio repeats a node's telemetry until it changes.
      CREATE TABLE IF NOT EXISTS $_nodeMetrics (
        ts INTEGER NOT NULL,
        node INTEGER NOT NULL,
        battery INTEGER,
        voltage REAL,
        snr REAL,
        PRIMARY KEY (ts, node));
      -- Both reads are "this node, over time" and "everything since T".
      CREATE INDEX IF NOT EXISTS ${_nodeMetrics}_node_ts
        ON $_nodeMetrics (node, ts);
      -- How far into each conversation the user has read — what the unread
      -- dots are computed against. Its own table rather than a column on
      -- [$_channels]: that one is replaced wholesale from the radio's table
      -- and only holds named channels, either of which would silently reset
      -- read positions.
      CREATE TABLE IF NOT EXISTS $_reads (
        channel INTEGER PRIMARY KEY NOT NULL,
        last_read INTEGER NOT NULL)
    ''');

    // Columns added after a table shipped arrive by ALTER — IF NOT EXISTS does
    // nothing for a table that already exists. On an installed one the probe
    // names what is present; on a fresh one the set is empty, so the ALTERs run
    // after the CREATE above.
    for (final entry in _alterColumns.entries) {
      final present = existing[entry.key]!;
      if (present.isEmpty) continue;
      for (final (column, type) in entry.value) {
        if (present.contains(column)) continue;
        await db.execute('ALTER TABLE ${entry.key} ADD COLUMN $column $type');
      }
    }
    // A fresh install: the CREATEs above carry none of the ALTER columns, so
    // add them now that the tables exist.
    for (final entry in _alterColumns.entries) {
      if (existing[entry.key]!.isNotEmpty) continue;
      for (final (column, type) in entry.value) {
        await db.execute('ALTER TABLE ${entry.key} ADD COLUMN $column $type');
      }
    }
  }

  /// Columns added to a table after it shipped — one list per table so the
  /// fresh and installed paths cannot drift.
  static const Map<String, List<(String, String)>> _alterColumns = {
    _metrics: [
      ('voltage', 'REAL'),
      ('nodes_total', 'INTEGER'),
      ('nodes_online', 'INTEGER'),
      ('rx_packets', 'INTEGER'),
      ('tx_packets', 'INTEGER'),
      // The radio's own counters (`LocalStats`), stored as per-sample deltas
      // like the traffic columns above. These are ground truth from the modem;
      // `rx_packets`/`tx_packets` are what survived the BLE link, and the two
      // disagreeing is itself the diagnostic.
      ('ls_rx', 'INTEGER'),
      ('ls_rx_bad', 'INTEGER'),
      ('ls_tx', 'INTEGER'),
      ('ls_rx_dupe', 'INTEGER'),
      ('ls_tx_relay', 'INTEGER'),
      ('ls_tx_relay_cancel', 'INTEGER'),
      // Absolute, not a delta: free heap is a level, and its slope over a day
      // is what forecasts a reboot.
      ('heap_free', 'INTEGER'),
    ],
    // How many hops away the node was when last heard. NULL means *unknown*,
    // which is not the same as 0 — an unset protobuf uint32 reads as 0, i.e.
    // "direct neighbour", which is a plausible and silently wrong answer.
    _nodes: [('hops_away', 'INTEGER')],
    // When *we* stored the row, by the calibrated clock.
    //
    // `ts` is the radio's own `rx_time` for an incoming message, and DPIP does
    // not set that clock. Ageing it out against our clock meant a radio whose
    // RTC sat more than the retention window in the past had every message it
    // delivered deleted by the next sweep — silently, because the chat keeps
    // its in-memory list, on the one durable table whose contents cannot be
    // re-fetched. Retention and ordering use this column; `ts` stays for
    // display and for the identity index.
    //
    // NULL on rows written before it existed, and those are kept: an old row's
    // true arrival time is unknowable, and deleting on a guess is the failure
    // this column exists to stop.
    // `binary` is nullable for the same reason `received_at` is: an existing
    // row cannot be re-examined. It reads as 0 (text), which is exactly right —
    // every row written before the column existed came out of a decoder that
    // could not produce anything else.
    _messages: [('received_at', 'INTEGER'), ('binary', 'INTEGER')],
  };

  /// Appends [message], ignoring one the log already holds. Returns whether it
  /// was new — the caller uses that to decide whether to notify or re-render.
  ///
  /// `RETURNING` answers "did this insert land" the way sqflite's
  /// insert-with-ignore rowid once did: the unique identity index suppresses
  /// reconnect replays, and a suppressed insert contributes no returning row.
  Future<bool> addMessage(MeshStoredMessage message) async {
    try {
      final result = await _db.execute(
        'INSERT OR IGNORE INTO $_messages '
        '(ts, received_at, node, channel, text, outgoing, binary) '
        'VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id',
        [
          message.timestamp.millisecondsSinceEpoch,
          _now().millisecondsSinceEpoch,
          message.from,
          message.channel,
          message.text,
          message.outgoing ? 1 : 0,
          message.binary ? 1 : 0,
        ],
      );
      return result.isNotEmpty;
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
      final rows = channel == null
          ? await _db.getAll(
              'SELECT id, ts, received_at, node, channel, text, outgoing, binary '
              'FROM $_messages '
              // Arrival order, falling back to the radio's stamp for rows
              // written before the column existed. Ranking incoming (radio
              // clock) and outgoing (our clock) rows together by `ts` put a
              // reply above the message it answered — visible only after a
              // restart, because live inserts land in arrival order anyway.
              'ORDER BY COALESCE(received_at, ts) DESC, id DESC LIMIT ?',
              [limit],
            )
          : await _db.getAll(
              'SELECT id, ts, received_at, node, channel, text, outgoing, binary '
              'FROM $_messages WHERE channel = ? '
              'ORDER BY COALESCE(received_at, ts) DESC, id DESC LIMIT ?',
              [channel, limit],
            );
      return [for (final row in rows) _readMessage(row)];
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store messages');
      return const [];
    }
  }

  /// How many messages each channel holds — what the channel picker badges.
  /// Channel → when the user last read it (ms). Missing = never read.
  Future<Map<int, int>> readLastReads() async {
    try {
      final rows = await _db.getAll('SELECT channel, last_read FROM $_reads');
      return {
        for (final row in rows)
          row['channel']! as int: row['last_read']! as int,
      };
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store readLastReads');
      return const {};
    }
  }

  /// Marks [channel] read up to [ts] (ms).
  Future<void> writeLastRead(int channel, int ts) async {
    try {
      await _db.execute(
        'INSERT OR REPLACE INTO $_reads (channel, last_read) VALUES (?, ?)',
        [channel, ts],
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store writeLastRead');
    }
  }

  /// How many *received* messages each channel holds newer than its read
  /// position. Own sends never count — the user has read what they typed.
  ///
  /// Counted in SQL against the [_reads] table directly: thirty days of a
  /// busy mesh is tens of thousands of rows, and pulling them into Dart to
  /// compare timestamps would be a page-open cost for two integers a channel.
  Future<Map<int, int>> unreadCounts() async {
    try {
      final rows = await _db.getAll(
        'SELECT m.channel AS channel, COUNT(*) AS n '
        'FROM $_messages m '
        'LEFT JOIN $_reads r ON r.channel = m.channel '
        'WHERE m.outgoing = 0 AND m.ts > COALESCE(r.last_read, 0) '
        'GROUP BY m.channel',
      );
      return {for (final row in rows) row['channel']! as int: row['n']! as int};
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store unreadCounts');
      return const {};
    }
  }

  /// Newest received-message timestamp per channel — what a read position
  /// advances to when a conversation is opened.
  Future<Map<int, int>> newestIncomingTsByChannel() async {
    try {
      final rows = await _db.getAll(
        'SELECT channel, MAX(ts) AS ts FROM $_messages '
        'WHERE outgoing = 0 GROUP BY channel',
      );
      return {
        for (final row in rows) row['channel']! as int: row['ts']! as int,
      };
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store newestIncomingTsByChannel');
      return const {};
    }
  }

  Future<Map<int, int>> messageCountsByChannel() async {
    try {
      final rows = await _db.getAll(
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
      // The read cursors go with the messages, in one transaction. Left
      // behind, they point past a log that no longer exists — so the first
      // message to arrive after a clear lands *below* a cursor that outlived
      // its conversation and is counted as already read.
      await _db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM $_messages');
        await tx.execute('DELETE FROM $_reads');
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store clearMessages');
    }
  }

  /// Records a utilization sample, keyed by the moment the radio reported it
  /// so the same telemetry can't be stored twice.
  Future<void> addMetric(MeshMetricSample sample) async {
    try {
      await _db.execute(
        'INSERT OR REPLACE INTO $_metrics '
        '(ts, channel_util, air_util, battery, voltage, nodes_total, '
        'nodes_online, rx_packets, tx_packets, ls_rx, ls_rx_bad, ls_tx, '
        'ls_rx_dupe, ls_tx_relay, ls_tx_relay_cancel, heap_free) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          sample.at.millisecondsSinceEpoch,
          sample.channelUtilization,
          sample.airUtilTx,
          sample.batteryPercent,
          sample.voltage,
          sample.nodesTotal,
          sample.nodesOnline,
          sample.rxPackets,
          sample.txPackets,
          sample.lsRx,
          sample.lsRxBad,
          sample.lsTx,
          sample.lsRxDupe,
          sample.lsTxRelay,
          sample.lsTxRelayCancel,
          sample.heapFree,
        ],
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store addMetric');
    }
  }

  /// The start of [window] for [table] — from now, or from the newest row when
  /// that is older, so a clock that jumped forward cannot age out data that is
  /// not old. See the cutoff in [prune].
  Future<int> _windowStart(String table, Duration window, DateTime now) async {
    final nowMs = now.millisecondsSinceEpoch;
    try {
      final row = await _db.get('SELECT MAX(ts) AS newest FROM $table');
      final newest = (row['newest'] as num?)?.toInt();
      final anchor = newest != null && newest < nowMs ? newest : nowMs;
      return anchor - window.inMilliseconds;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store window start');
      return nowMs - window.inMilliseconds;
    }
  }

  /// Utilization samples inside [metricRetention], oldest first — chart order.
  Future<List<MeshMetricSample>> metrics() async {
    try {
      final since = await _windowStart(_metrics, metricRetention, _now());
      final rows = await _db.getAll(
        'SELECT ts, channel_util, air_util, battery, voltage, nodes_total, '
        'nodes_online, rx_packets, tx_packets, ls_rx, ls_rx_bad, ls_tx, '
        'ls_rx_dupe, ls_tx_relay, ls_tx_relay_cancel, heap_free '
        'FROM $_metrics WHERE ts >= ? ORDER BY ts ASC',
        [since],
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
            rxPackets: (row['rx_packets'] as num?)?.toInt(),
            txPackets: (row['tx_packets'] as num?)?.toInt(),
            lsRx: (row['ls_rx'] as num?)?.toInt(),
            lsRxBad: (row['ls_rx_bad'] as num?)?.toInt(),
            lsTx: (row['ls_tx'] as num?)?.toInt(),
            lsRxDupe: (row['ls_rx_dupe'] as num?)?.toInt(),
            lsTxRelay: (row['ls_tx_relay'] as num?)?.toInt(),
            lsTxRelayCancel: (row['ls_tx_relay_cancel'] as num?)?.toInt(),
            heapFree: (row['heap_free'] as num?)?.toInt(),
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
      await _db.writeTransaction((tx) async {
        for (final sample in samples) {
          await tx.execute(
            'INSERT OR REPLACE INTO $_nodeMetrics '
            '(ts, node, battery, voltage, snr) VALUES (?, ?, ?, ?, ?)',
            [
              sample.at.millisecondsSinceEpoch,
              sample.node,
              sample.battery,
              sample.voltage,
              sample.snr,
            ],
          );
        }
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'mesh store addNodeMetrics');
    }
  }

  /// Node readings inside [metricRetention], oldest first. [node] narrows to
  /// one neighbour.
  Future<List<MeshNodeMetricSample>> nodeMetrics({int? node}) async {
    try {
      final since = await _windowStart(_nodeMetrics, metricRetention, _now());
      final rows = node == null
          ? await _db.getAll(
              'SELECT ts, node, battery, voltage, snr FROM $_nodeMetrics '
              'WHERE ts >= ? ORDER BY ts ASC',
              [since],
            )
          : await _db.getAll(
              'SELECT ts, node, battery, voltage, snr FROM $_nodeMetrics '
              'WHERE ts >= ? AND node = ? ORDER BY ts ASC',
              [since, node],
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
      // On `received_at`, never on `ts` — see [_alterColumns]. A row with no
      // arrival time survives: it predates the column, and its true age is
      // unknowable.
      await _db.execute(
        'DELETE FROM $_messages '
        'WHERE received_at IS NOT NULL AND received_at < ?',
        [now.subtract(messageRetention).millisecondsSinceEpoch],
      );
      // Rows written before the channel-hash guard existed can carry a hash
      // (242, 92, …) where an index belongs; they synthesise phantom "CH242"
      // conversations in the picker. The guard stops new ones — this clears
      // the legacy ones. Slot indices are 0–7, fixed by the firmware.
      await _db.execute(
        'DELETE FROM $_messages WHERE channel > 7 OR channel < 0',
      );
      // The same shape guard on the read cursors, which are keyed by the same
      // channel number and had no prune path at all.
      await _db.execute('DELETE FROM $_reads WHERE channel > 7 OR channel < 0');
      // Measured from the newest row when that is *older* than now, not from
      // now alone.
      //
      // `ServerClock` is monotonic only between syncs: the first successful
      // one steps the clock by the device's whole error. Rows written before
      // the step carry device time, and a cutoff taken purely from the stepped
      // clock can land after every one of them — deleting a day of telemetry
      // including the sample from a minute ago. Anchoring to the data bounds
      // a forward step to one window's worth.
      //
      // The cost, accepted deliberately: while the radio is away the newest
      // row stops advancing, so the last window's samples are kept rather than
      // aged out. That is a ceiling, not growth — nothing new arrives to
      // accumulate — and every chart windows from *now* regardless, so a stale
      // day is never drawn as current.
      final metricCutoff = await _windowStart(_metrics, metricRetention, now);
      await _db.execute('DELETE FROM $_metrics WHERE ts < ?', [metricCutoff]);
      await _db.execute('DELETE FROM $_nodeMetrics WHERE ts < ?', [
        await _windowStart(_nodeMetrics, metricRetention, now),
      ]);
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
    // Not `!`: the column post-dates the table, so a row written before the
    // ALTER has NULL here and reads as text.
    binary: (row['binary'] as int?) == 1,
  );

  /// Every stored node, most recently heard first.
  /// Channel index → name, for every named channel the radio has reported.
  ///
  /// Only named channels are stored: an unnamed slot has nothing to remember,
  /// and keeping a row for it would let a stale blank outrank a name that
  /// arrives later.
  Future<Map<int, String>> readChannels() async {
    try {
      final rows = await _db.getAll('SELECT idx, name FROM $_channels');
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
      await _db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM $_channels');
        for (final entry in names.entries) {
          if (entry.value.isEmpty) continue;
          await tx.execute('INSERT INTO $_channels (idx, name) VALUES (?, ?)', [
            entry.key,
            entry.value,
          ]);
        }
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing mesh channels');
    }
  }

  /// [limit] is the caller's cap, not the table's — the store keeps whatever
  /// was written and the node table's owner decides how much of it it wants.
  /// The default is generous rather than meaningful; a caller that cares
  /// passes its own.
  Future<List<Map<String, Object?>>> readNodes({int limit = 5000}) async {
    try {
      final rows = await _db.getAll(
        'SELECT num, name, battery, last_heard, latitude, longitude, snr, '
        'via_mqtt, hops_away FROM $_nodes ORDER BY last_heard DESC LIMIT ?',
        [limit],
      );
      return [for (final row in rows) Map<String, Object?>.of(row)];
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
      await _db.writeTransaction((tx) async {
        await tx.execute('DELETE FROM $_nodes');
        for (final row in rows) {
          await tx.execute(
            'INSERT INTO $_nodes (num, name, battery, last_heard, latitude, '
            'longitude, snr, via_mqtt, hops_away) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
            [
              row['num'],
              row['name'],
              row['battery'],
              row['last_heard'],
              row['latitude'],
              row['longitude'],
              row['snr'],
              row['via_mqtt'],
              row['hops_away'],
            ],
          );
        }
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing mesh nodes');
    }
  }
}
