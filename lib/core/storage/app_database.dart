/// The app's two SQLite files, and the line between them.
///
/// **Two files, not one, and the split is by durability rather than by
/// subject.** The HTTP cache lives in the platform *cache* directory, which
/// the OS may empty whenever it wants space — correct for bytes that can be
/// fetched again. Everything else is in the *application-support* directory,
/// which it may not: settings the user chose, the mesh conversation, the radio
/// they paired. Putting the two in one file would make every one of those
/// hostage to a directory the system is entitled to delete.
///
/// That is also the real answer to "clearing the cache must not delete
/// anything else". A `DELETE` scoped to the right tables relies on every
/// future edit staying careful; a separate file makes the mistake unavailable.
/// [clearCache] cannot reach user data because it does not hold a handle to
/// it, and a test asserts exactly that.
///
/// Within the durable file, tables are grouped by category so each store owns
/// its own and nothing shares a row:
///
/// | file          | table            | category    |
/// |---------------|------------------|-------------|
/// | `dpip.db`            | `settings`          | config      |
/// | `dpip.db`            | `logs`              | diagnostics |
/// | `dpip.db`            | `tle`               | orbital data|
/// | `dpip.db`            | `mesh_messages`     | meshtastic  |
/// | `dpip.db`            | `mesh_channels`     | meshtastic  |
/// | `dpip.db`            | `mesh_reads`        | meshtastic  |
/// | `dpip.db`            | `mesh_metrics`      | meshtastic  |
/// | `dpip.db`            | `mesh_node_metrics` | meshtastic  |
/// | `dpip.db`            | `mesh_nodes`        | meshtastic  |
/// | `http_etag_cache.db` | `http_cache`        | cache       |
/// | `http_etag_cache.db` | `net_bucket`        | cache       |
/// | `location_track.db`  | `fix`               | movement    |
///
/// The third file is not opened here and has no handle on [AppDatabase],
/// because nothing in Dart writes it: background location arrives when Dart is
/// not running, so the native stores own both the writes and the eviction that
/// keeps it under 50 MB. Dart reads it through
/// `lib/core/geo/location_track.dart`, on a connection opened read-only. It is
/// listed here because this table is where someone looks to find out what the
/// app keeps on disk, and a file that grows on its own belongs on that list.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// The tables the cache file owns — the complete list of what [clearCache]
/// may destroy. Anything not named here is, by construction, out of reach.
const List<String> cacheTables = ['http_cache', 'net_bucket'];

/// Handles to both files. Either may be null: a database that will not open is
/// a degraded app, not a dead one.
class AppDatabase {
  const AppDatabase({required this.durable, required this.cache});

  /// Settings, orbital elements and mesh history. Survives a cache purge.
  final SqliteDatabase? durable;

  /// Re-fetchable bytes only.
  final SqliteDatabase? cache;

  /// Empties every cache table, and nothing else.
  ///
  /// It takes the cache handle and no other, so there is no path from here to
  /// the settings or the mesh log even by accident. Returns the number of rows
  /// dropped, which is what a settings screen wants to show.
  ///
  /// One transaction: the per-table counts come from SQLite's `changes()`
  /// read on the same write connection as the delete — outside one,
  /// sqlite_async's pooled readers would answer from a different connection
  /// where nothing had changed.
  Future<int> clearCache() async {
    final database = cache;
    if (database == null) return 0;
    var removed = 0;
    try {
      removed = await database.writeTransaction((tx) async {
        var dropped = 0;
        for (final table in cacheTables) {
          await tx.execute('DELETE FROM $table');
          final row = await tx.get('SELECT changes() AS n');
          dropped += ((row['n'] as num?) ?? 0).toInt();
        }
        return dropped;
      });
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'clearing cache tables');
    }
    // Reclaim the file space rather than leaving it as free pages: the point
    // of clearing a 350 MB cache is to get the storage back.
    try {
      await database.execute('VACUUM');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'vacuum after cache clear');
    }
    return removed;
  }

  /// Bytes the cache currently occupies, for a settings screen to display.
  Future<int> cacheBytes() async {
    final database = cache;
    if (database == null) return 0;
    final row = await database.get(
      'SELECT page_count * page_size AS bytes '
      'FROM pragma_page_count(), pragma_page_size()',
    );
    return ((row['bytes'] as num?) ?? 0).toInt();
  }

  /// Row count and size of every table in both files, biggest first.
  ///
  /// For the Debug page: "the database is 40 MB" is not something anyone can
  /// act on, whereas "mesh_node_metrics is 38 MB across 900,000 rows" names
  /// both the table and the retention window that is wrong.
  Future<List<TableStat>> tableStats() async => [
    ...await _statsFor(durable, 'dpip.db'),
    ...await _statsFor(cache, 'http_etag_cache.db'),
  ]..sort((a, b) => b.bytes.compareTo(a.bytes));

  static Future<List<TableStat>> _statsFor(
    SqliteDatabase? db,
    String file,
  ) async {
    if (db == null) return const [];
    try {
      final names = await db.getAll(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      );
      // `dbstat` reports the real on-disk pages, indexes included, but it is a
      // compile-time option and the system SQLite on neither platform is
      // guaranteed to have it. Try it once; if it is missing, fall back to
      // measuring the payload.
      final pages = await _pageSizes(db);
      return [
        for (final row in names)
          if (row['name'] case final String table)
            TableStat(
              file: file,
              table: table,
              rows: await _countRows(db, table),
              bytes: pages?[table] ?? await _payloadBytes(db, table),
              onDisk: pages != null,
            ),
      ];
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'table stats for $file');
      return const [];
    }
  }

  /// On-disk bytes per table from `dbstat`, or null where it is unavailable.
  static Future<Map<String, int>?> _pageSizes(SqliteDatabase db) async {
    try {
      // Joined to `sqlite_master` so an index's pages land on the table it
      // belongs to. Grouping by `dbstat.name` alone lists indexes as if they
      // were tables and leaves every table looking smaller than it is — on a
      // message log with two indexes, most of the cost would be invisible.
      final rows = await db.getAll(
        'SELECT COALESCE(m.tbl_name, d.name) AS tbl, SUM(d.pgsize) AS bytes '
        'FROM dbstat d LEFT JOIN sqlite_master m ON m.name = d.name '
        'GROUP BY tbl',
      );
      return {
        for (final row in rows)
          row['tbl']! as String: (row['bytes'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return null; // no DBSTAT_VTAB in this build
    }
  }

  static Future<int> _countRows(SqliteDatabase db, String table) async {
    final row = await db.get('SELECT COUNT(*) AS n FROM "$table"');
    return ((row['n'] as num?) ?? 0).toInt();
  }

  /// Stored payload of a table: the length of every value in every row.
  ///
  /// The fallback when `dbstat` is missing. It undercounts — page overhead,
  /// free space and indexes are invisible to it — which is why [TableStat]
  /// carries [TableStat.onDisk] rather than letting the two be confused.
  static Future<int> _payloadBytes(SqliteDatabase db, String table) async {
    final columns = await db.getAll('PRAGMA table_info("$table")');
    final names = [
      for (final column in columns)
        if (column['name'] case final String name) name,
    ];
    if (names.isEmpty) return 0;
    final sum = names.map((name) => 'COALESCE(LENGTH("$name"), 0)').join(' + ');
    final row = await db.get(
      'SELECT COALESCE(SUM($sum), 0) AS bytes FROM "$table"',
    );
    return ((row['bytes'] as num?) ?? 0).toInt();
  }
}

/// What one table costs.
class TableStat {
  const TableStat({
    required this.file,
    required this.table,
    required this.rows,
    required this.bytes,
    required this.onDisk,
  });

  /// Which of the two database files it lives in — the difference between
  /// "the OS may delete this" and "only the user can".
  final String file;
  final String table;
  final int rows;
  final int bytes;

  /// Whether [bytes] is the real on-disk figure (`dbstat`) or the measured
  /// payload, which excludes indexes and page overhead.
  final bool onDisk;
}
