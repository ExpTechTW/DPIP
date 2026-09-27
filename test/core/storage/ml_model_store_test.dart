/// The durable copy of a downloaded ML model.
///
/// Kept in the durable file — a cache purge must not cost a phone the model it
/// needs the next time an alert arrives — and keyed with the hash of what it
/// inflates to, so the service can tell a copy of *this* model from any other.
library;

import 'dart:typed_data';

import 'package:dpip/core/storage/ml_model_store.dart';
import 'package:flutter_test/flutter_test.dart';

import 'memory_db.dart';

void main() {
  test('a model round-trips with its hash, and a write replaces it', () async {
    final db = openMemoryDb();
    await MlModelStore.createSchema(db);
    final store = MlModelStore(db);

    expect(await store.read('m'), isNull);
    await store.write(
      'm',
      gzip: Uint8List.fromList([1]),
      sha256: 'a',
      fetchedAt: DateTime.utc(2026),
    );
    await store.write(
      'm',
      gzip: Uint8List.fromList([2, 3]),
      sha256: 'b',
      fetchedAt: DateTime.utc(2026),
    );

    final stored = await store.read('m');
    expect(stored?.gzip, [2, 3]);
    expect(stored?.sha256, 'b');
  });

  test('delete drops only the named model', () async {
    final db = openMemoryDb();
    await MlModelStore.createSchema(db);
    final store = MlModelStore(db);
    await store.write(
      'a',
      gzip: Uint8List(1),
      sha256: 'x',
      fetchedAt: DateTime.utc(2026),
    );
    await store.write(
      'b',
      gzip: Uint8List(1),
      sha256: 'y',
      fetchedAt: DateTime.utc(2026),
    );

    await store.delete('a');

    expect(await store.read('a'), isNull);
    expect(await store.read('b'), isNotNull);
  });

  test('without a database it keeps nothing and never throws', () async {
    const store = MlModelStore(null);

    await store.write(
      'm',
      gzip: Uint8List(1),
      sha256: 'x',
      fetchedAt: DateTime.utc(2026),
    );
    await store.delete('m');
    expect(await store.read('m'), isNull);
  });
}
