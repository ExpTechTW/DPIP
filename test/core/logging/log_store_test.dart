/// The persisted log: what it keeps, what it drops, and what it must not do.
///
/// Two properties matter more than the rest. It must **never throw** — a
/// logger that can fail its caller turns a diagnostic into an outage, and it
/// is called from error handlers where there is nowhere left to report to. And
/// its retention must run on **write**, because retention that only runs when
/// something reads the table is retention that never runs: nobody opens the
/// log screen on the device that is filling up.
library;

import 'package:dpip/core/logging/log_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite_async/sqlite_async.dart';

import '../storage/memory_db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var clock = DateTime.utc(2026, 8, 15, 12);

  Future<(LogStore, SqliteDatabase)> makeStore({int flushAt = 64}) async {
    final db = openMemoryDb();
    await LogStore.createSchema(db);
    return (LogStore(db, now: () => clock, flushAt: flushAt), db);
  }

  StoredLog line(String message, {String level = 'info', DateTime? at}) =>
      StoredLog(time: at ?? clock, level: level, message: message);

  setUp(() => clock = DateTime.utc(2026, 8, 15, 12));

  test('a line survives a flush and reads back whole', () async {
    final (store, _) = await makeStore();
    store.add(
      StoredLog(
        time: clock,
        level: 'error',
        message: 'boom',
        error: 'StateError: bad',
        stackTrace: '#0 somewhere',
      ),
    );
    await store.flush();

    final stored = await store.recent();
    expect(stored, hasLength(1));
    expect(stored.single.message, 'boom');
    expect(stored.single.level, 'error');
    expect(stored.single.error, 'StateError: bad');
    expect(stored.single.stackTrace, '#0 somewhere');
  });

  test('adding does not touch the database until a flush', () async {
    final (store, _) = await makeStore();
    store.add(line('buffered'));
    expect(
      await store.count(),
      0,
      reason: 'a log call must not cost a database round-trip',
    );
    await store.flush();
    expect(await store.count(), 1);
  });

  test('a burst flushes itself without waiting for the timer', () async {
    // A reconnect loop or a stack-trace storm should not sit in memory until
    // the timer fires — that is the run most likely to end in a kill.
    final (store, _) = await makeStore(flushAt: 4);
    for (var i = 0; i < 4; i++) {
      store.add(line('line $i'));
    }
    // The flush is scheduled synchronously by the fourth `add`.
    await Future<void>.delayed(Duration.zero);
    expect(await store.count(), 4);
  });

  test('anything past 24 hours is dropped, on write', () async {
    final (store, _) = await makeStore();
    store.add(line('old', at: clock.subtract(const Duration(hours: 25))));
    store.add(line('edge', at: clock.subtract(const Duration(hours: 23))));
    await store.flush();
    // The prune runs inside the same transaction as the insert, so a line that
    // is already too old never even lands.
    expect((await store.recent()).map((e) => e.message), ['edge']);

    // Two hours on, `edge` has aged out too — and it is the *write* that
    // notices, not a reader. Nobody opens the log screen on the device that is
    // filling up.
    clock = clock.add(const Duration(hours: 2));
    store.add(line('new'));
    await store.flush();

    final messages = (await store.recent()).map((e) => e.message).toList();
    expect(messages, ['new']);
  });

  test('the row ceiling is applied on write, not only on the sweep', () async {
    // A fault that logs every frame writes faster than any sweep runs, so the
    // ceiling has to hold between sweeps — the freeze this guards against was
    // the log screen feeding itself.
    final (store, db) = await makeStore(flushAt: logMaxRows * 2);
    for (var i = 0; i < logMaxRows + 250; i++) {
      store.add(line('line $i', at: clock.add(Duration(seconds: i))));
    }
    await store.flush();
    final row = await db.get('SELECT COUNT(*) AS n FROM $logTable');
    expect(row['n'], logMaxRows);
  });

  test('the ceiling keeps the newest lines, not the oldest', () async {
    final (store, _) = await makeStore(flushAt: logMaxRows * 2);
    for (var i = 0; i < logMaxRows + 5; i++) {
      store.add(line('line $i', at: clock.add(Duration(seconds: i))));
    }
    await store.flush();
    expect(
      (await store.recent(limit: 1)).single.message,
      'line ${logMaxRows + 4}',
    );
    final all = await store.recent(limit: logMaxRows);
    expect(all.map((e) => e.message), isNot(contains('line 0')));
  });

  test('reads come back newest first', () async {
    final (store, _) = await makeStore();
    for (var i = 0; i < 3; i++) {
      store.add(line('line $i', at: clock.add(Duration(minutes: i))));
    }
    await store.flush();
    expect((await store.recent()).map((e) => e.message).toList(), [
      'line 2',
      'line 1',
      'line 0',
    ]);
  });

  test('a level filter narrows the read', () async {
    final (store, _) = await makeStore();
    store
      ..add(line('fine'))
      ..add(line('bad', level: 'error'));
    await store.flush();
    expect((await store.recent(level: 'error')).map((e) => e.message), ['bad']);
  });

  test('clear empties it', () async {
    final (store, _) = await makeStore();
    store.add(line('x'));
    await store.flush();
    await store.clear();
    expect(await store.count(), 0);
  });

  test('a closed database is survived, not propagated', () async {
    // The property that matters most: this is called from error handlers, and
    // an exception here would replace a diagnostic with a crash.
    final (store, db) = await makeStore();
    await db.close();
    store.add(line('after close'));
    await expectLater(store.flush(), completes);
    expect(await store.count(), 0);
    expect(await store.recent(), isEmpty);
    await expectLater(store.clear(), completes);
    await expectLater(store.dispose(), completes);
  });

  test('flushing an empty buffer is a no-op', () async {
    final (store, _) = await makeStore();
    await expectLater(store.flush(), completes);
    expect(await store.count(), 0);
  });
}
