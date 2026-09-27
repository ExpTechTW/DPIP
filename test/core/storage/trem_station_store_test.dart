/// The durable copy of the station directory, and the ETag beside it.
///
/// Kept in the durable file, not the HTTP cache, so the monitor can place
/// stations on a launch the network cannot help with. The ETag rides in the
/// same row as the body so the two can never describe different copies — a
/// `304` answered for one validator must never vouch for another body.
library;

import 'package:dpip/core/storage/trem_station_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_db.dart';

void main() {
  test('nothing stored reads as null', () async {
    final db = openMemoryDb();
    await TremStationStore.createSchema(db);

    expect(await TremStationStore(db).read(), isNull);
  });

  test('a write replaces the one row, body and ETag together', () async {
    final db = openMemoryDb();
    await TremStationStore.createSchema(db);
    final store = TremStationStore(db);

    await store.write(csv: 'a', etag: 'W/"1"', fetchedAt: DateTime.utc(2026));
    await store.write(csv: 'b', etag: null, fetchedAt: DateTime.utc(2026));

    final stored = await store.read();
    expect(stored?.csv, 'b');
    expect(stored?.etag, isNull, reason: 'a stale validator must not survive');
    final rows = await db.getAll('SELECT * FROM $tremStationTable');
    expect(rows, hasLength(1));
  });

  test('without a database it keeps nothing and never throws', () async {
    const store = TremStationStore(null);

    await store.write(csv: 'a', etag: 'x', fetchedAt: DateTime.utc(2026));
    expect(await store.read(), isNull);
  });

  test('the schema is safe to create on every open', () async {
    final db = openMemoryDb();
    await TremStationStore.createSchema(db);
    await TremStationStore.createSchema(db);
  });
}
