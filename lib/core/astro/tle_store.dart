/// The `tle` table — orbital elements and when they were fetched.
///
/// Its own table rather than two rows in `settings`, because it is its own
/// category of data: not a user choice, not re-fetchable on demand (the source
/// is a public service that asks not to be polled), and not something a
/// "reset settings" should take with it.
///
/// One row. The elements are stored as the raw TLE text they arrived as: it is
/// a few hundred bytes, it is the format every source speaks, and keeping it
/// verbatim means the parser stays the only thing that has to understand it.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:sqflite/sqflite.dart';

/// The table this store owns.
const String tleTable = 'tle';

/// What was last fetched, and when.
class StoredElements {
  const StoredElements({required this.text, required this.fetchedAt});

  final String text;
  final DateTime fetchedAt;
}

class TleStore {
  const TleStore(this._db);

  /// Null when the database would not open — the caller then falls back to the
  /// bundled snapshot, which is a complete answer on its own.
  final Database? _db;

  /// Creates the table. Safe on every open.
  ///
  /// `CHECK (id = 0)` is the single-row constraint: there is only ever one
  /// current element set, and making that a schema rule beats remembering to
  /// delete the old one.
  static Future<void> createSchema(Database db) => db.execute(
    'CREATE TABLE IF NOT EXISTS $tleTable ('
    'id INTEGER PRIMARY KEY CHECK (id = 0), '
    'text TEXT NOT NULL, '
    'fetched_at INTEGER NOT NULL)',
  );

  Future<StoredElements?> read() async {
    final db = _db;
    if (db == null) return null;
    try {
      final rows = await db.query(tleTable, limit: 1);
      final row = rows.firstOrNull;
      if (row == null) return null;
      return StoredElements(
        text: row['text']! as String,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(
          row['fetched_at']! as int,
          isUtc: true,
        ),
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'reading elements');
      return null;
    }
  }

  /// Replaces the stored elements. [text] null records only that a check
  /// happened — the set on file was already current.
  Future<void> write({String? text, required DateTime fetchedAt}) async {
    final db = _db;
    if (db == null) return;
    try {
      if (text == null) {
        await db.update(tleTable, {
          'fetched_at': fetchedAt.toUtc().millisecondsSinceEpoch,
        }, where: 'id = 0');
        return;
      }
      await db.insert(tleTable, {
        'id': 0,
        'text': text,
        'fetched_at': fetchedAt.toUtc().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'writing elements');
    }
  }
}
