/// The `trem_station` table — the seismic station directory as last fetched,
/// and the ETag it came with.
///
/// Durable, not the HTTP cache, on purpose. The cache file sits in a directory
/// the OS may empty whenever it likes, and evicts by LRU on its own besides;
/// this copy is what the 強震監視器 draws before the network has answered, and
/// on the connection an earthquake has just degraded the network may not
/// answer at all. The ETag is kept beside the body in the same row, so the
/// two cannot disagree: a `304` means "the copy you hold is current" only if
/// the copy is the one that validator was issued for.
///
/// One row, stored as the CSV it arrived as — about 6 kB — so the parser stays
/// the only thing that has to understand the format.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// The table this store owns.
const String tremStationTable = 'trem_station';

/// The directory body and the validator it was served with.
class StoredStations {
  const StoredStations({required this.csv, this.etag});

  final String csv;

  /// Null when the server sent none — the next fetch is then unconditional.
  final String? etag;
}

class TremStationStore {
  const TremStationStore(this._db);

  /// Null when the durable database would not open: the directory is then
  /// fetched fresh each session and nothing is kept.
  final SqliteDatabase? _db;

  /// Creates the table. Safe on every open. `CHECK (id = 0)` makes "one
  /// current directory" a schema rule.
  static Future<void> createSchema(SqliteDatabase db) => db.execute(
    'CREATE TABLE IF NOT EXISTS $tremStationTable ('
    'id INTEGER PRIMARY KEY CHECK (id = 0), '
    'csv TEXT NOT NULL, '
    'etag TEXT, '
    'fetched_at INTEGER NOT NULL)',
  );

  Future<StoredStations?> read() async {
    final db = _db;
    if (db == null) return null;
    try {
      final row = await db.getOptional(
        'SELECT csv, etag FROM $tremStationTable LIMIT 1',
      );
      if (row == null) return null;
      return StoredStations(
        csv: row['csv']! as String,
        etag: row['etag'] as String?,
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'reading the station directory');
      return null;
    }
  }

  /// Replaces the stored directory.
  Future<void> write({
    required String csv,
    required String? etag,
    required DateTime fetchedAt,
  }) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.execute(
        'INSERT OR REPLACE INTO $tremStationTable (id, csv, etag, fetched_at) '
        'VALUES (0, ?, ?, ?)',
        [csv, etag, fetchedAt.toUtc().millisecondsSinceEpoch],
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing the station directory');
    }
  }
}
