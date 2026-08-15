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
/// | `dpip.db`     | `settings`       | config      |
/// | `dpip.db`     | `tle`            | orbital data|
/// | `dpip.db`     | `mesh_messages`  | meshtastic  |
/// | `dpip.db`     | `mesh_metrics`   | meshtastic  |
/// | `dpip.db`     | `mesh_nodes`     | meshtastic  |
/// | `http_cache.db` | `http_cache`   | cache       |
/// | `http_cache.db` | `net_bucket`   | cache       |
/// | `http_cache.db` | `net_total`    | cache       |
library;

import 'package:dpip/core/logging/log.dart';
import 'package:sqflite/sqflite.dart';

/// Schema version of the durable database.
const int appDatabaseVersion = 1;

/// The tables the cache file owns — the complete list of what [clearCache]
/// may destroy. Anything not named here is, by construction, out of reach.
/// `net_total` is a table only on installs that predate the hourly buckets;
/// it is listed so an upgraded device's leftovers are cleared too, and
/// [clearCache] tolerates a table that is not there.
const List<String> cacheTables = ['http_cache', 'net_bucket', 'net_total'];

/// Handles to both files. Either may be null: a database that will not open is
/// a degraded app, not a dead one.
class AppDatabase {
  const AppDatabase({required this.durable, required this.cache});

  /// Settings, orbital elements and mesh history. Survives a cache purge.
  final Database? durable;

  /// Re-fetchable bytes only.
  final Database? cache;

  /// Empties every cache table, and nothing else.
  ///
  /// It takes the cache handle and no other, so there is no path from here to
  /// the settings or the mesh log even by accident. Returns the number of rows
  /// dropped, which is what a settings screen wants to show.
  Future<int> clearCache() async {
    final database = cache;
    if (database == null) return 0;
    var removed = 0;
    for (final table in cacheTables) {
      try {
        removed += await database.delete(table);
      } catch (error, stackTrace) {
        Log.handle(error, stackTrace, 'clearing $table');
      }
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
    final rows = await database.rawQuery(
      'SELECT page_count * page_size AS bytes '
      'FROM pragma_page_count(), pragma_page_size()',
    );
    return (rows.firstOrNull?['bytes'] as int?) ?? 0;
  }
}
