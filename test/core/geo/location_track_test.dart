/// The delta format, from the writer's side to the reader's.
///
/// The native stores write this file and Dart only reads it, so nothing in the
/// app exercises both halves — a disagreement about the encoding would show up
/// as a track that is simply wrong, on a device, with no exception anywhere.
/// [writeTrackFixture] (`location_track_fixture.dart`) is therefore a
/// line-by-line restatement of what `LocationTrackStore.swift` and
/// `LocationTrackStore.kt` do, and these tests assert the reader inverts it
/// exactly.
library;

import 'dart:io';

import 'package:dpip/core/geo/location_track.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'location_track_fixture.dart';

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
    writeTrackFixture(path, [(1735689600, 25.0330, 121.5654)]);
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
    writeTrackFixture(path, expected);
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
      writeTrackFixture(path, expected);
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
    writeTrackFixture(path, _walk(70));
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);
    expect(await track.since(DateTime.utc(1990)), hasLength(70));
  });

  test('limit keeps the most recent fixes', () async {
    final expected = _walk(200);
    writeTrackFixture(path, expected);
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
    writeTrackFixture(path, _walk(3));
    final db = sqlite3.sqlite3.open(path);
    addTearDown(db.close);
    final ids = db
        .select('SELECT id FROM fix ORDER BY id')
        .map((row) => row['id'] as int)
        .toList();
    expect(ids, [trackAnchorEvery, trackAnchorEvery + 1, trackAnchorEvery + 2]);
  });

  test('the track still decodes after the oldest groups are evicted', () async {
    // What native eviction does: delete whole anchor groups off the front.
    // The remaining rows still read correctly only because the first survivor
    // is itself an anchor — drop one row fewer and every position after it
    // would be a delta read as a coordinate, somewhere off the coast.
    final expected = _walk(200);
    writeTrackFixture(path, expected);

    // Rows start at rowid 64, so expected[i] is at rowid 64 + i. Deleting
    // below 128 takes the first whole group, expected[0..63].
    const dropped = trackAnchorEvery;
    final writer = sqlite3.sqlite3.open(path);
    writer.execute('DELETE FROM fix WHERE id < ${trackAnchorEvery * 2}');
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
    writeTrackFixture(path, _walk(200));
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);

    final stats = await track.stats();
    expect(stats.fixes, 200);
    expect(stats.bytes, greaterThan(0));
  });

  test('stats name the oldest fix still stored', () async {
    final expected = _walk(200);
    writeTrackFixture(path, expected);
    // Eviction takes the oldest group, and the date has to move with it —
    // "oldest point" is how a reader learns how far back the history goes.
    final writer = sqlite3.sqlite3.open(path);
    writer.execute('DELETE FROM fix WHERE id < ${trackAnchorEvery * 2}');
    writer.close();
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);

    final stats = await track.stats();
    expect(stats.fixes, 200 - trackAnchorEvery);
    expect(
      stats.oldest!.millisecondsSinceEpoch ~/ 1000,
      expected[trackAnchorEvery].$1,
    );
  });

  test('an empty file has no oldest fix', () async {
    writeTrackFixture(path, const []);
    final track = LocationTrack.at(path)!;
    addTearDown(track.close);
    final stats = await track.stats();
    expect(stats.fixes, 0);
    expect(stats.oldest, isNull);
  });

  group('scan', () {
    List<(int, int, int)> scanned(DateTime from) {
      final out = <(int, int, int)>[];
      LocationTrack.scan(path, from, (t, lat, lng) => out.add((t, lat, lng)));
      return out;
    }

    test('visits exactly what since returns, in stored units', () async {
      // The two readers share one decoder; this pins that they also share one
      // idea of the window, from a start in the middle of an anchor group.
      writeTrackFixture(path, _walk(300));
      final track = LocationTrack.at(path)!;
      addTearDown(track.close);
      final all = await track.since(DateTime.utc(2000));
      for (final from in [DateTime.utc(2000), all[100].time, all[257].time]) {
        final expected = await track.since(from);
        final got = scanned(from);
        expect(got, hasLength(expected.length), reason: '$from');
        for (var i = 0; i < got.length; i++) {
          final (t, lat, lng) = got[i];
          expect(t * 1000, expected[i].time.millisecondsSinceEpoch);
          expect(lat / 10000, closeTo(expected[i].latitude, 1e-9));
          expect(lng / 10000, closeTo(expected[i].longitude, 1e-9));
        }
      }
    });

    test('a missing file visits nothing', () {
      expect(scanned(DateTime.utc(2000)), isEmpty);
    });

    test('a window after the last fix visits nothing', () {
      writeTrackFixture(path, _walk(70));
      expect(scanned(DateTime.utc(2100)), isEmpty);
    });
  });

  test('the connection cannot write', () async {
    // The separation of duties is enforced by the connection, not by care:
    // the native side owns every write, including eviction.
    writeTrackFixture(path, _walk(10));
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
    writeTrackFixture(path, _walk(20000));
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
