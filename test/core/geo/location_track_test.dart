/// The delta format, from the writer's side to the reader's.
///
/// The native stores write this file and Dart only reads it, so nothing in the
/// app exercises both halves — a disagreement about the encoding would show up
/// as a track that is simply wrong, on a device, with no exception anywhere.
/// [_writeFixture] below is therefore a line-by-line restatement of what
/// `LocationTrackStore.swift` and `LocationTrackStore.kt` do, and these tests
/// assert the reader inverts it exactly.
library;

import 'dart:io';

import 'package:dpip/core/geo/location_track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

const _anchorEvery = 64;
const _scale = 10000.0;

/// Writes fixes the way the native stores do: deltas, absolute every 64th row.
void _writeFixture(String path, List<(int, double, double)> fixes) {
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
  // compactness test at the bottom of this file. A local SSD answers an fsync
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
    final previous = rowid % _anchorEvery == 0 ? null : _lastAbsolute(db);
    if (previous == null && rowid % _anchorEvery != 0) {
      rowid += _anchorEvery - rowid % _anchorEvery;
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
  final anchor = last - last % _anchorEvery;
  (int, int, int)? current;
  for (final row in db.select(
    'SELECT id, t, lat, lng FROM fix WHERE id >= ? ORDER BY id',
    [anchor],
  )) {
    final id = row['id'] as int;
    final t = row['t'] as int;
    final lat = row['lat'] as int;
    final lng = row['lng'] as int;
    current = (id % _anchorEvery == 0 || current == null)
        ? (t, lat, lng)
        : (current.$1 + t, current.$2 + lat, current.$3 + lng);
  }
  return current;
}

/// A plausible walk: a fix a minute, drifting a few metres each time.
List<(int, double, double)> _walk(int count, {int from = 1735689600}) => [
  for (var i = 0; i < count; i++)
    (from + i * 60, 25.0330 + i * 0.0003, 121.5654 + i * 0.0002),
];

void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('location_track_test');
    path = '${dir.path}/location_track.db';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('no file is an empty history, not an error', () {
    expect(LocationTrack.at(path), isNull);
  });

  test('a single fix round-trips', () async {
    _writeFixture(path, [(1735689600, 25.0330, 121.5654)]);
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);

    final fixes = await track.since(DateTime.utc(2000));
    expect(fixes, hasLength(1));
    expect(
      fixes.single.time,
      DateTime.fromMillisecondsSinceEpoch(1735689600 * 1000, isUtc: true),
    );
    expect(fixes.single.latitude, closeTo(25.0330, 1e-9));
    expect(fixes.single.longitude, closeTo(121.5654, 1e-9));
  });

  test('every fix survives several anchor boundaries', () async {
    // 200 rows crosses the 64-row boundary three times, so the reader has to
    // switch between "absolute" and "add to the running total" repeatedly. A
    // one-row-out mistake there decodes into positions that drift.
    final expected = _walk(200);
    _writeFixture(path, expected);
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);

    final fixes = await track.since(DateTime.utc(2000));
    expect(fixes, hasLength(expected.length));
    for (var i = 0; i < expected.length; i++) {
      final (time, latitude, longitude) = expected[i];
      expect(
        fixes[i].time.millisecondsSinceEpoch ~/ 1000,
        time,
        reason: 'time at $i',
      );
      // Four decimals is what the store keeps, so that is the tolerance.
      expect(fixes[i].latitude, closeTo(latitude, 5e-5), reason: 'lat at $i');
      expect(fixes[i].longitude, closeTo(longitude, 5e-5), reason: 'lng at $i');
    }
  });

  test(
    'a window starting mid-group still decodes absolute positions',
    () async {
      // The point of the anchor walk: row 100 is a delta, meaningless on its
      // own. Asking for a window that begins there must produce the same
      // coordinates as reading the whole track, not a delta read as a position.
      final expected = _walk(200);
      _writeFixture(path, expected);
      final track = LocationTrack.at(path)!;
      addTearDown(track.close);

      final all = await track.since(DateTime.utc(2000));
      final from = all[100].time;
      final window = await track.since(from);

      expect(window, hasLength(all.length - 100));
      expect(window.first.latitude, closeTo(all[100].latitude, 1e-9));
      expect(window.first.longitude, closeTo(all[100].longitude, 1e-9));
      expect(window.last.latitude, closeTo(all.last.latitude, 1e-9));
    },
  );

  test('a window older than the whole track returns all of it', () async {
    _writeFixture(path, _walk(70));
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);
    expect(await track.since(DateTime.utc(1990)), hasLength(70));
  });

  test('limit keeps the most recent fixes', () async {
    final expected = _walk(200);
    _writeFixture(path, expected);
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);

    final all = await track.since(DateTime.utc(2000));
    final tail = await track.since(DateTime.utc(2000), limit: 10);
    expect(tail, hasLength(10));
    expect(tail.last.time, all.last.time);
    expect(tail.first.time, all[190].time);
  });

  test('the first fix lands on an anchor rowid', () {
    // The writer has nothing to subtract from on the very first fix, so it
    // moves the row up to the next multiple of 64 rather than writing an
    // absolute value at a rowid the reader would treat as a delta. Everything
    // below depends on this, so it is asserted rather than assumed.
    _writeFixture(path, _walk(3));
    final db = sqlite3.sqlite3.open(path);
    addTearDown(db.close);
    final ids = db
        .select('SELECT id FROM fix ORDER BY id')
        .map((row) => row['id'] as int)
        .toList();
    expect(ids, [_anchorEvery, _anchorEvery + 1, _anchorEvery + 2]);
  });

  test('the track still decodes after the oldest groups are evicted', () async {
    // What native eviction does: delete whole anchor groups off the front.
    // The remaining rows still read correctly only because the first survivor
    // is itself an anchor — drop one row fewer and every position after it
    // would be a delta read as a coordinate, somewhere off the coast.
    final expected = _walk(200);
    _writeFixture(path, expected);

    // Rows start at rowid 64, so expected[i] is at rowid 64 + i. Deleting
    // below 128 takes the first whole group, expected[0..63].
    const dropped = _anchorEvery;
    final writer = sqlite3.sqlite3.open(path);
    writer.execute('DELETE FROM fix WHERE id < ${_anchorEvery * 2}');
    writer.close();

    final track = LocationTrack.at(path)!;
    addTearDown(track.close);
    final fixes = await track.since(DateTime.utc(2000));

    expect(fixes, hasLength(expected.length - dropped));
    final (time, latitude, longitude) = expected[dropped];
    expect(fixes.first.time.millisecondsSinceEpoch ~/ 1000, time);
    expect(fixes.first.latitude, closeTo(latitude, 5e-5));
    expect(fixes.first.longitude, closeTo(longitude, 5e-5));
    // And the tail is untouched by the eviction.
    expect(fixes.last.latitude, closeTo(expected.last.$2, 5e-5));
  });

  test('stats report the row count and the file size', () async {
    _writeFixture(path, _walk(200));
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);

    final stats = await track.stats();
    expect(stats.fixes, 200);
    expect(stats.bytes, greaterThan(0));
  });

  test('the connection cannot write', () async {
    // The separation of duties is enforced by the connection, not by care:
    // the native side owns every write, including eviction.
    _writeFixture(path, _walk(10));
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);
    await expectLater(
      track.connection.execute('DELETE FROM fix'),
      throwsA(isA<sqlite3.SqliteException>()),
    );
  });

  test('the encoding stays compact', () async {
    // The claim behind the 50 MB budget is roughly 14 bytes a row. This does
    // not pin the exact figure — page overhead and the WAL move it — but it
    // does fail if someone stores absolutes again, which would roughly double
    // it and quietly halve how much history fits.
    _writeFixture(path, _walk(20000));
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);

    final stats = await track.stats();
    expect(stats.fixes, 20000);
    expect(
      stats.bytes / stats.fixes,
      lessThan(20),
      reason: '${stats.bytes} bytes for ${stats.fixes} fixes',
    );
  });
}
