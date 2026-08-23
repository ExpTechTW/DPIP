import 'package:dpip/core/meshtastic/data/mesh_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../storage/memory_db.dart';

void main() {
  late SqliteDatabase db;
  var clock = DateTime.utc(2026, 1, 10, 12);

  setUp(() async {
    clock = DateTime.utc(2026, 1, 10, 12);
    db = openMemoryDb();
    await MeshStore.createSchema(db);
  });

  tearDown(() async => db.close());

  MeshStore store() => MeshStore(db, now: () => clock);

  MeshStoredMessage message(
    String text, {
    int from = 1,
    int channel = 0,
    DateTime? at,
    bool outgoing = false,
  }) => MeshStoredMessage(
    from: from,
    channel: channel,
    text: text,
    timestamp: at ?? clock,
    outgoing: outgoing,
  );

  group('messages', () {
    test('round-trip, newest first', () async {
      final s = store();
      await s.addMessage(
        message('older', at: clock.subtract(const Duration(minutes: 5))),
      );
      await s.addMessage(message('newer'));

      final rows = await s.messages();
      expect(rows.map((m) => m.text), ['newer', 'older']);
      expect(rows.first.outgoing, isFalse);
    });

    test('the same message twice is stored once', () async {
      final s = store();
      expect(await s.addMessage(message('same')), isTrue);
      // A reconnect replays packets the log may already hold; the unique index
      // is what decides, and the caller is told it was not new.
      expect(await s.addMessage(message('same')), isFalse);
      expect(await s.messages(), hasLength(1));
    });

    test('same text on another channel is a different message', () async {
      final s = store();
      await s.addMessage(message('hi'));
      await s.addMessage(message('hi', channel: 3));
      expect(await s.messages(), hasLength(2));
    });

    test('narrows to one channel', () async {
      final s = store();
      await s.addMessage(message('primary'));
      await s.addMessage(message('secondary', channel: 3));

      expect((await s.messages(channel: 3)).single.text, 'secondary');
    });

    test('counts per channel', () async {
      final s = store();
      await s.addMessage(message('a', at: clock));
      await s.addMessage(
        message('b', at: clock.add(const Duration(seconds: 1))),
      );
      await s.addMessage(message('c', channel: 2));

      expect(await s.messageCountsByChannel(), {0: 2, 2: 1});
    });

    test('prune drops what is past retention and keeps the rest', () async {
      // Retention is on when *we* received it, not on the radio's stamp — so
      // the old message has to be genuinely old to us, which means storing it
      // while the clock says so.
      clock = clock.subtract(const Duration(days: 31));
      await store().addMessage(message('ancient', at: clock));
      clock = clock.add(const Duration(days: 31));
      final s = store();
      await s.addMessage(message('recent'));

      await s.prune();
      expect((await s.messages()).single.text, 'recent');
    });

    test('a radio whose clock is a year behind keeps its messages', () async {
      final s = store();
      await s.addMessage(
        message('heard now', at: clock.subtract(const Duration(days: 365))),
      );
      await s.prune();
      expect(await s.messages(), hasLength(1));
    });

    test('clearMessages empties the table', () async {
      final s = store();
      await s.addMessage(message('bye'));
      await s.clearMessages();
      expect(await s.messages(), isEmpty);
    });
  });

  group('metrics', () {
    test('returns samples oldest first', () async {
      final s = store();
      await s.addMetric(
        MeshMetricSample(
          at: clock.subtract(const Duration(hours: 2)),
          channelUtilization: 3,
          airUtilTx: 1,
        ),
      );
      await s.addMetric(
        MeshMetricSample(at: clock, channelUtilization: 9, airUtilTx: 2),
      );

      final rows = await s.metrics();
      expect(rows.map((m) => m.channelUtilization), [3, 9]);
      expect(rows.last.airUtilTx, 2);
    });

    test('the same reading twice stays one row', () async {
      final s = store();
      final sample = MeshMetricSample(at: clock, channelUtilization: 5);
      await s.addMetric(sample);
      await s.addMetric(sample);
      expect(await s.metrics(), hasLength(1));
    });

    test(
      'only the last 24 hours are returned, and older rows pruned',
      () async {
        final s = store();
        await s.addMetric(
          MeshMetricSample(
            at: clock.subtract(const Duration(hours: 30)),
            channelUtilization: 1,
          ),
        );
        await s.addMetric(
          MeshMetricSample(
            at: clock.subtract(const Duration(hours: 2)),
            channelUtilization: 2,
          ),
        );

        expect((await s.metrics()).single.channelUtilization, 2);
        await s.prune();
        // The window filter and the prune agree — one is not hiding the other.
        expect((await s.metrics()).single.channelUtilization, 2);
      },
    );

    test('keeps a null reading distinguishable from zero', () async {
      final s = store();
      await s.addMetric(MeshMetricSample(at: clock, airUtilTx: 0));
      final row = (await s.metrics()).single;
      expect(row.channelUtilization, isNull);
      expect(row.airUtilTx, 0);
    });
  });

  group('binary bodies', () {
    test('the flag round-trips', () async {
      await store().addMessage(
        MeshStoredMessage(
          from: 1,
          channel: 0,
          text: '01 ff 02',
          timestamp: clock,
          outgoing: false,
          binary: true,
        ),
      );

      final rows = await store().messages(channel: 0);

      expect(rows.single.binary, isTrue);
      expect(rows.single.text, '01 ff 02');
    });

    test('a text message is not binary', () async {
      await store().addMessage(message('hello'));

      expect((await store().messages(channel: 0)).single.binary, isFalse);
    });

    test('a row written before the column existed reads as text', () async {
      // The `binary` column arrives by ALTER, so every row already on disk has
      // NULL in it. Reading that as `null == 1` -> false is the whole contract;
      // a `!` there would throw on the first message anyone had ever received.
      //
      // Simulated by putting the table back into its pre-column shape and
      // re-running createSchema, which is exactly what an upgrade does.
      await db.execute('DROP TABLE mesh_messages');
      await db.executeMultiple('''
        CREATE TABLE mesh_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ts INTEGER NOT NULL,
          node INTEGER NOT NULL,
          channel INTEGER NOT NULL,
          text TEXT NOT NULL,
          outgoing INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'INSERT INTO mesh_messages (ts, node, channel, text, outgoing) '
        'VALUES (?, ?, ?, ?, ?)',
        [clock.millisecondsSinceEpoch, 1, 0, 'from before the column', 0],
      );

      await MeshStore.createSchema(db);
      final rows = await store().messages(channel: 0);

      expect(rows.single.text, 'from before the column');
      expect(rows.single.binary, isFalse);
    });
  });
}
