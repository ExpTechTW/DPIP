/// A fresh in-memory database per call, for store tests.
///
/// sqlite_async runs every connection on its own background isolate, so the
/// usual `:memory:` path would give each connection a *different* database.
/// [SqliteDatabase.singleConnection] wraps one synchronous connection instead:
/// single handle, one database, no pool — exactly what a unit test wants and
/// what the production pool must not be.
library;

import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite_async/sqlite_async.dart';

/// Opens an isolated in-memory database.
///
/// `SqliteConnection.synchronousWrapper` + `SqliteDatabase.singleConnection` is
/// the documented test-only route to in-memory databases; the internal import
/// it replaces is not needed at all.
SqliteDatabase openMemoryDb() {
  final connection = SqliteConnection.synchronousWrapper(
    sqlite3.sqlite3.openInMemory(),
  );
  return SqliteDatabase.singleConnection(connection);
}
