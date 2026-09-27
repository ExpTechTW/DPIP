/// The `ml_model` table — machine-learned models this device has downloaded,
/// kept gzip-compressed.
///
/// Durable, not the HTTP cache: the ETag cache sits in a directory the OS may
/// empty and evicts by LRU on its own besides, and the model is what the
/// 強震監視器 needs when an earthquake has just made the network worst. It is
/// fetched once and kept.
///
/// Stored compressed (about 2.2 MB for ML v1, against 14.7 MB raw) with the
/// SHA-256 of the *uncompressed* file, so a row is only ever used for the exact
/// model its hash names.
library;

import 'dart:typed_data';

import 'package:dpip/core/logging/log.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// The table this store owns.
const String mlModelTable = 'ml_model';

/// A stored model: its gzip bytes and the SHA-256 (hex) of what they inflate
/// to.
typedef StoredModel = ({Uint8List gzip, String sha256});

class MlModelStore {
  const MlModelStore(this._db);

  /// Null when the durable database would not open: the model is then fetched
  /// again each session and nothing is kept.
  final SqliteDatabase? _db;

  static Future<void> createSchema(SqliteDatabase db) => db.execute(
    'CREATE TABLE IF NOT EXISTS $mlModelTable ('
    'name TEXT PRIMARY KEY, '
    'sha256 TEXT NOT NULL, '
    'gzip BLOB NOT NULL, '
    'fetched_at INTEGER NOT NULL)',
  );

  Future<StoredModel?> read(String name) async {
    final db = _db;
    if (db == null) return null;
    try {
      final row = await db.getOptional(
        'SELECT sha256, gzip FROM $mlModelTable WHERE name = ?',
        [name],
      );
      if (row == null) return null;
      final blob = row['gzip']! as List<int>;
      return (
        gzip: blob is Uint8List ? blob : Uint8List.fromList(blob),
        sha256: row['sha256']! as String,
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'reading the $name model');
      return null;
    }
  }

  Future<void> write(
    String name, {
    required Uint8List gzip,
    required String sha256,
    required DateTime fetchedAt,
  }) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.execute(
        'INSERT OR REPLACE INTO $mlModelTable (name, sha256, gzip, fetched_at) '
        'VALUES (?, ?, ?, ?)',
        [name, sha256, gzip, fetchedAt.toUtc().millisecondsSinceEpoch],
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing the $name model');
    }
  }

  Future<void> delete(String name) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.execute('DELETE FROM $mlModelTable WHERE name = ?', [name]);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'deleting the $name model');
    }
  }
}
