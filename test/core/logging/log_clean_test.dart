/// The screen's clear button has to clear the table, not just the screen.
///
/// `talker.cleanHistory()` empties the in-memory list; the stored log is what
/// the screen replays from on the next visit, so leaving it behind made the
/// button look broken — everything came straight back.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/logging/log_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;
  late LogStore store;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await LogStore.createSchema(db);
    store = LogStore(db);
    Log.store = store;
    Log.talker.cleanHistory();
  });

  tearDown(() async {
    Log.store = null;
    await db.close();
  });

  test('clearing the screen empties the stored log too', () async {
    store.add(
      StoredLog(
        time: DateTime.utc(2026, 8, 18),
        level: 'info',
        message: 'before',
      ),
    );
    await store.flush();
    expect((await store.recent()).length, 1);

    Log.talker.cleanHistory();
    // `clean` is synchronous and the delete is not; the write is started, not
    // waited on.
    await Future<void>.delayed(Duration.zero);
    await pumpEventQueue();

    expect(await store.recent(), isEmpty);
    expect(Log.talker.history, isEmpty);
  });

  test('clearing without a store does not throw', () async {
    Log.store = null;
    expect(Log.talker.cleanHistory, returnsNormally);
  });

  test(
    'lines logged before the database opened are written when it does',
    () async {
      // `Log.info('DPIP starting up')` runs at bootstrap.dart:111 and the store
      // opens at :139, so the lines that explain a crash during launch were the
      // ones never stored — and are the ones lost the moment the screen loads
      // the table over the top of memory.
      Log.store = null;
      Log.talker.cleanHistory();
      Log.info('DPIP starting up');

      Log.persistTo(store);
      await store.flush();

      final stored = await store.recent();
      expect(stored.map((e) => e.message), contains('DPIP starting up'));
    },
  );
}
