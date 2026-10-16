/// Writes a `location_track.db` the way the native stores do, for tests that
/// read one back.
///
/// The native stores write this file and Dart only reads it, so nothing in the
/// app exercises both halves — a disagreement about the encoding would show up
/// as a track that is simply wrong, on a device, with no exception anywhere.
/// [writeTrackFixture] is therefore a line-by-line restatement of what
/// `LocationTrackStore.swift` and `LocationTrackStore.kt` do.
library;

import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// Rows between absolute anchors — `anchorEvery` in both native stores.
const trackAnchorEvery = 64;
const _scale = 10000.0;

/// Writes fixes the way the native stores do: deltas, absolute every 64th row.
///
/// Appends when [path] already holds a track, exactly as a later background
/// wake would.
void writeTrackFixture(String path, List<(int, double, double)> fixes) {
  final db = sqlite3.sqlite3.open(path);
  db.execute('PRAGMA auto_vacuum=INCREMENTAL');
  db.execute('PRAGMA journal_mode=WAL');
  db.execute(
    'CREATE TABLE IF NOT EXISTS fix ('
    'id INTEGER PRIMARY KEY, t INTEGER NOT NULL, '
    'lat INTEGER NOT NULL, lng INTEGER NOT NULL)',
  );

  // One transaction for the whole fixture. The loop below writes a row at a
  // time because that is what the native stores do, but in WAL mode each of
  // those is its own commit and its own fsync — 20 000 of them for the
  // compactness test in `location_track_test.dart`. A local SSD answers an fsync
  // in tens of microseconds and a shared CI runner's disk in a millisecond or
  // two, which is the whole distance between a one-second test here and the
  // thirty-second timeout that took `main` red. Batching moves when the pages
  // reach the disk, not what is in them: the file comes out at exactly the
  // same 282 624 bytes, so the byte-per-fix budget still measures the encoding.
  db.execute('BEGIN');
  for (final (time, latitude, longitude) in fixes) {
    final lat = (latitude * _scale).round();
    final lng = (longitude * _scale).round();

    final last =
        db.select('SELECT IFNULL(MAX(id), 0) AS n FROM fix').first['n'] as int;
    var rowid = last + 1;
    final previous = rowid % trackAnchorEvery == 0 ? null : _lastAbsolute(db);
    if (previous == null && rowid % trackAnchorEvery != 0) {
      rowid += trackAnchorEvery - rowid % trackAnchorEvery;
    }

    db.execute('INSERT INTO fix (id, t, lat, lng) VALUES (?, ?, ?, ?)', [
      rowid,
      previous == null ? time : time - previous.$1,
      previous == null ? lat : lat - previous.$2,
      previous == null ? lng : lng - previous.$3,
    ]);
  }
  db.execute('COMMIT');
  db.close();
}

(int, int, int)? _lastAbsolute(sqlite3.Database db) {
  final last =
      db.select('SELECT IFNULL(MAX(id), 0) AS n FROM fix').first['n'] as int;
  if (last == 0) return null;
  final anchor = last - last % trackAnchorEvery;
  (int, int, int)? current;
  for (final row in db.select(
    'SELECT id, t, lat, lng FROM fix WHERE id >= ? ORDER BY id',
    [anchor],
  )) {
    final id = row['id'] as int;
    final t = row['t'] as int;
    final lat = row['lat'] as int;
    final lng = row['lng'] as int;
    current = (id % trackAnchorEvery == 0 || current == null)
        ? (t, lat, lng)
        : (current.$1 + t, current.$2 + lat, current.$3 + lng);
  }
  return current;
}
