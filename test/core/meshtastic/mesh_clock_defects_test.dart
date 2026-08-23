/// The clock defects the persistence audit found, pinned so they cannot come
/// back.
///
/// Every one is the same shape: a timestamp minted by one clock, aged out or
/// ordered against another. They are grouped here rather than scattered
/// because the *class* is what must stay fixed — a new table that repeats it
/// should fail a test that reads like a rule.
library;

import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:dpip/core/meshtastic/data/meshtastic_client_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../storage/memory_db.dart';

Future<SqliteDatabase> _open() async {
  final db = openMemoryDb();
  await MeshStore.createSchema(db);
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.utc(2026, 8, 16, 12);

  group('a radio clock cannot delete the log', () {
    test('retention is on when we stored it, not on what the radio said', () async {
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db, now: () => now);

      // A radio whose RTC sits a year in the past — a real state for a node
      // with no GPS that never met a phone with a good clock.
      await store.addMessage(
        MeshStoredMessage(
          from: 7,
          channel: 0,
          text: 'heard just now',
          timestamp: now.subtract(const Duration(days: 365)),
          outgoing: false,
        ),
      );
      await store.prune();

      // Deleting it would be silent: the chat keeps its in-memory list, so the
      // loss shows up only at the next launch — on the one durable table whose
      // contents cannot be re-fetched.
      expect(await store.messages(), hasLength(1));
    });

    test('a genuinely old message still ages out', () async {
      final db = await _open();
      addTearDown(db.close);
      var clock = now.subtract(const Duration(days: 40));
      final store = MeshStore(db, now: () => clock);
      await store.addMessage(
        MeshStoredMessage(
          from: 7,
          channel: 0,
          text: 'last month',
          timestamp: clock,
          outgoing: false,
        ),
      );
      clock = now;
      await store.prune();
      expect(await store.messages(), isEmpty);
    });

    test('rows written before the column existed are kept, not guessed at', () async {
      final db = await _open();
      addTearDown(db.close);
      // No `received_at`: its true arrival time is unknowable, and deleting on
      // a guess is the failure the column exists to stop.
      await db.execute(
        'INSERT INTO mesh_messages (ts, node, channel, text, outgoing) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          now.subtract(const Duration(days: 365)).millisecondsSinceEpoch,
          7,
          0,
          'legacy',
          0,
        ],
      );
      await MeshStore(db, now: () => now).prune();
      expect(await db.getAll('SELECT * FROM mesh_messages'), hasLength(1));
    });
  });

  group('a clock that jumps cannot delete telemetry', () {
    test('a forward step spares rows that are not actually old', () async {
      final db = await _open();
      addTearDown(db.close);
      // Launched offline with a device clock three days slow: AppTime is
      // device time, so every sample is stamped three days back.
      var clock = now.subtract(const Duration(days: 3));
      final store = MeshStore(db, now: () => clock);
      for (var i = 0; i < 5; i++) {
        await store.addMetric(
          MeshMetricSample(
            at: clock.add(Duration(minutes: i)),
            channelUtilization: 5,
          ),
        );
      }

      // Connectivity returns and the first successful sync steps the clock
      // forward by the whole error.
      clock = now;
      await store.prune();

      expect(
        await store.metrics(),
        hasLength(5),
        reason: 'the newest sample was a minute old when the clock moved',
      );
    });
  });

  group('a radio clock in the future', () {
    test('is not believed', () {
      final wall = DateTime.utc(2026, 8, 16, 12);
      final ahead = wall.add(const Duration(days: 2));
      // A future stamp parks the unread cursor beyond anything that can ever
      // arrive, so the conversation reads as permanently caught up — and it
      // sorts above replies written after it.
      expect(
        receivedAt(ahead.millisecondsSinceEpoch ~/ 1000, now: () => wall),
        wall,
      );
    });

    test('ordinary skew is', () {
      final wall = DateTime.utc(2026, 8, 16, 12);
      final slightly = wall.add(const Duration(minutes: 2));
      // Compared as instants: the stamp is rebuilt from epoch seconds and so
      // carries a local flag, which `==` on DateTime would fail on.
      expect(
        receivedAt(
          slightly.millisecondsSinceEpoch ~/ 1000,
          now: () => wall,
        ).millisecondsSinceEpoch,
        slightly.millisecondsSinceEpoch,
      );
    });

    test('and a radio with no clock at all gets ours', () {
      final wall = DateTime.utc(2026, 8, 16, 12);
      expect(receivedAt(0, now: () => wall), wall);
    });
  });

  group('read cursors do not outlive their log', () {
    test('clearing the messages clears them', () async {
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db, now: () => now);
      await store.addMessage(
        MeshStoredMessage(
          from: 7,
          channel: 2,
          text: 'read me',
          timestamp: now,
          outgoing: false,
        ),
      );
      await store.writeLastRead(2, now.millisecondsSinceEpoch);
      await store.clearMessages();

      // Left behind, the cursor points past a log that no longer exists, and
      // the next message to arrive lands below it and counts as already read.
      expect(await store.readLastReads(), isEmpty);
    });

    test('a hash channel is pruned from them too', () async {
      final db = await _open();
      addTearDown(db.close);
      final store = MeshStore(db, now: () => now);
      await store.writeLastRead(242, now.millisecondsSinceEpoch);
      await store.prune();
      expect(await store.readLastReads(), isNot(contains(242)));
    });
  });
}
