/// Read access to the movement history the native side records.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:sqlite_async/native.dart';
import 'package:sqlite_async/sqlite_async.dart';

/// One recorded position.
class TrackFix {
  const TrackFix({
    required this.time,
    required this.latitude,
    required this.longitude,
  });

  final DateTime time;

  /// Degrees, to four places — about 11 m, which is the precision the store
  /// keeps. Reading back more decimals than that would be inventing them.
  final double latitude;
  final double longitude;

  @override
  String toString() =>
      'TrackFix(${time.toIso8601String()}, $latitude, $longitude)';
}

/// Reads the track that iOS's `LocationTrackStore.swift` and Android's
/// `LocationTrackStore.kt` write.
///
/// **Read-only, and that is the whole design.** Fixes arrive while the app is
/// backgrounded and Dart is not running, so the native side owns the writes;
/// it owns the eviction too, because a 50 MB budget enforced from two places
/// is a budget enforced from neither. The connection here is opened
/// `SQLITE_OPEN_READONLY` rather than merely used carefully — a future edit
/// that tried to insert or delete would fail at the connection, not silently
/// become a second owner of the file.
///
/// ## The format it decodes
///
/// One `fix` table of `(id, t, lat, lng)`, where every value is a **delta from
/// the previous row** except on anchors, and an anchor is any row whose `id`
/// is a multiple of [_anchorEvery]. Latitude and longitude are ten-thousandths
/// of a degree; `t` is Unix seconds.
///
/// Storing differences is what makes the file small, and it costs nothing to
/// do: SQLite already writes a small integer in one byte and a large one in
/// four, so a step of a few hundred metres is a byte where an absolute
/// coordinate is four. There is no private blob, and decoding is addition.
///
/// The price is that a row cannot be read on its own — the walk has to start
/// at an anchor. That is why [since] resolves a starting rowid first instead
/// of asking for `WHERE t >= ?`, which would match rows whose `t` is an
/// interval rather than an instant.
class LocationTrack {
  LocationTrack._(this._db, this._path);

  static const _file = 'location_track.db';

  /// Rows between absolute anchors. **Must match `anchorEvery` in both native
  /// stores.** Changing it on one side would not throw — it would return
  /// positions displaced by however far the device moved since the last real
  /// anchor, which is a wrong answer that looks like a right one.
  static const _anchorEvery = 64;

  /// Degrees per stored unit.
  static const _scale = 10000.0;

  final SqliteDatabase _db;
  final String _path;

  /// Opens the track, or null when the native side has never written one.
  ///
  /// Absence is the ordinary state on a fresh install, and on any device that
  /// never granted background location, so it is not an error and is not
  /// logged as one.
  static Future<LocationTrack?> open() async {
    try {
      // Application Support on iOS, `filesDir` on Android — the one directory
      // both native writers were pointed at, because a reader that had to
      // guess would not fail, it would quietly report an empty history.
      final directory = await getApplicationSupportDirectory();
      return at('${directory.path}/$_file');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'opening location track');
      return null;
    }
  }

  /// Opens a track at an explicit path, or null if there is no file there.
  ///
  /// [open] is this plus the directory lookup. Split out so a test can point
  /// at a fixture and still go through the real read-only connection — the
  /// part most likely to break, and the part whose breakage looks exactly
  /// like an empty history.
  static LocationTrack? at(String path) {
    if (!File(path).existsSync()) return null;
    return LocationTrack._(
      SqliteDatabase.withFactory(_ReadOnlyFactory(path: path)),
      path,
    );
  }

  Future<void> close() => _db.close();

  /// The underlying connection, so a test can prove it rejects writes.
  ///
  /// Exposed rather than asserted in a comment: "Dart never writes here" is
  /// the load-bearing half of the design, and the only way to show it holds
  /// is to try a write and watch SQLite refuse.
  @visibleForTesting
  SqliteDatabase get connection => _db;

  /// Every fix recorded at or after [from], oldest first.
  ///
  /// [limit] keeps the most recent that many and drops the rest, which is the
  /// only bound worth having here: the budget allows a few million rows, and
  /// materialising all of them as objects would cost far more memory than the
  /// file costs disk.
  Future<List<TrackFix>> since(DateTime from, {int? limit}) async {
    try {
      final start = await _anchorAtOrBefore(from);
      final fixes = await _decodeFrom(start);
      final wanted = fixes.where((fix) => !fix.time.isBefore(from)).toList();
      if (limit == null || wanted.length <= limit) return wanted;
      return wanted.sublist(wanted.length - limit);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'reading location track');
      return const [];
    }
  }

  /// How many fixes are stored and how large the file is.
  ///
  /// For the storage screen. This file is the one part of the app's disk use
  /// that grows without anybody opening anything, so it is worth being able
  /// to see it.
  Future<({int fixes, int bytes})> stats() async {
    try {
      final row = await _db.get('SELECT COUNT(*) AS n FROM fix');
      final file = File(_path);
      return (
        fixes: ((row['n'] as num?) ?? 0).toInt(),
        bytes: file.existsSync() ? file.lengthSync() : 0,
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'location track stats');
      return (fixes: 0, bytes: 0);
    }
  }

  /// The rowid of the newest anchor no later than [time], or 0 for "start at
  /// the beginning".
  ///
  /// Only anchors are consulted because only anchors carry an absolute `t`; a
  /// delta row's `t` is an interval, and comparing it to a wall clock would
  /// match essentially at random.
  ///
  /// Descending, so the scan stops at the first hit. A window of the last day
  /// or week — what anything asking this actually wants — reads a handful of
  /// rows off the end of the rowid index and stops. Asking for a window older
  /// than the whole track is the one case that scans it all, and it correctly
  /// answers 0.
  Future<int> _anchorAtOrBefore(DateTime time) async {
    final rows = await _db.getAll(
      'SELECT id FROM fix WHERE id % $_anchorEvery = 0 AND t <= ? '
      'ORDER BY id DESC LIMIT 1',
      [time.millisecondsSinceEpoch ~/ 1000],
    );
    return rows.isEmpty ? 0 : ((rows.first['id'] as num?) ?? 0).toInt();
  }

  /// Rebuilds absolute positions from [startId] forward.
  ///
  /// [startId] has to be an anchor or 0 — the first row of the table is always
  /// an anchor, because the writer rounds up to a boundary whenever it has
  /// nothing to count from and eviction only ever deletes whole groups. The
  /// `t == null` arm below is the belt to that braces: a first row that
  /// somehow is not an anchor is read as absolute, which is the only reading
  /// that can be right.
  Future<List<TrackFix>> _decodeFrom(int startId) async {
    final rows = await _db.getAll(
      'SELECT id, t, lat, lng FROM fix WHERE id >= ? ORDER BY id',
      [startId],
    );
    final fixes = <TrackFix>[];
    var t = 0;
    var lat = 0;
    var lng = 0;
    var started = false;
    for (final row in rows) {
      final id = (row['id'] as num).toInt();
      if (!started || id % _anchorEvery == 0) {
        t = (row['t'] as num).toInt();
        lat = (row['lat'] as num).toInt();
        lng = (row['lng'] as num).toInt();
        started = true;
      } else {
        t += (row['t'] as num).toInt();
        lat += (row['lat'] as num).toInt();
        lng += (row['lng'] as num).toInt();
      }
      fixes.add(
        TrackFix(
          time: DateTime.fromMillisecondsSinceEpoch(t * 1000, isUtc: true),
          latitude: lat / _scale,
          longitude: lng / _scale,
        ),
      );
    }
    return fixes;
  }
}

/// Opens every connection `SQLITE_OPEN_READONLY`, and runs no pragma that
/// would persist anything.
///
/// sqlite_async always opens one writable "primary" connection; this replaces
/// the options it passes so that connection is read-only too. The journal-mode
/// and journal-size pragmas are suppressed the same way — the file is already
/// in WAL because the native writer put it there, and re-asserting it from
/// here would be this side taking a write lock on a file it does not own.
///
/// One reader is plenty: nothing reads this concurrently, and each connection
/// is a file handle held for the life of the app.
base class _ReadOnlyFactory extends NativeSqliteOpenFactory {
  _ReadOnlyFactory({required super.path})
    : super(
        sqliteOptions: const SqliteOptions(
          journalMode: null,
          journalSizeLimit: null,
          synchronous: null,
          maxReaders: 1,
        ),
      );

  static const _readOnly = SqliteOpenOptions(
    primaryConnection: false,
    readOnly: true,
  );

  @override
  Database openNativeConnection(SqliteOpenOptions options) =>
      super.openNativeConnection(_readOnly);
}
