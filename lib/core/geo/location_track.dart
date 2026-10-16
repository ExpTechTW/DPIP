/// Read access to the movement history the native side records.
library;

import 'dart:io';

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show Database, OpenMode, sqlite3;
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

  /// The file this track reads — what a background isolate opens for itself
  /// in [scan], since a connection cannot cross an isolate boundary.
  String get path => _path;

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

  /// How many fixes are stored, how large the file is, and when the oldest
  /// surviving fix was taken (null when there is none).
  ///
  /// For the storage screen and the map's track layer. This file is the one
  /// part of the app's disk use that grows without anybody opening anything,
  /// so it is worth being able to see it — and once eviction has started,
  /// [oldest] is the honest answer to "how far back does it go".
  ///
  /// [oldest] reads the first row's `t` as an instant, which is right because
  /// the first row is always an anchor (see [_decodeFrom]); it is the same
  /// reading the decoder gives it.
  Future<({int fixes, int bytes, DateTime? oldest})> stats() async {
    try {
      final row = await _db.get('SELECT COUNT(*) AS n FROM fix');
      final first = await _db.getOptional(
        'SELECT t FROM fix ORDER BY id LIMIT 1',
      );
      final file = File(_path);
      final oldest = (first?['t'] as num?)?.toInt();
      return (
        fixes: ((row['n'] as num?) ?? 0).toInt(),
        bytes: file.existsSync() ? file.lengthSync() : 0,
        oldest: oldest == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(oldest * 1000, isUtc: true),
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'location track stats');
      return (fixes: 0, bytes: 0, oldest: null);
    }
  }

  /// Walks every fix at or after [from] in the file at [path], oldest first,
  /// handing each to [visit] in the units the file stores: Unix seconds and
  /// ten-thousandths of a degree.
  ///
  /// **Blocking — call it from a background isolate, never the UI one.** It is
  /// what makes "the whole history" readable at all: the budget allows a few
  /// million rows, and [since] would materialise every one of them as an
  /// object on the calling isolate. This streams them through a cursor
  /// instead, one row in memory at a time, so a caller that keeps only a
  /// bounded summary (the map's track digest) stays bounded however long the
  /// history is.
  ///
  /// Opens its own `SQLITE_OPEN_READONLY` connection for the same reason
  /// [_ReadOnlyFactory] does, and closes it before returning. A missing or
  /// unreadable file is not an error here: it visits nothing, and the caller
  /// sees an empty history — the same answer [open] gives.
  static void scan(
    String path,
    DateTime from,
    void Function(int seconds, int latE4, int lngE4) visit,
  ) {
    if (!File(path).existsSync()) return;
    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      final fromMs = from.millisecondsSinceEpoch;
      final anchor = db.select(_anchorQuery, [fromMs ~/ 1000]);
      final start = anchor.isEmpty
          ? 0
          : ((anchor.first.columnAt(0) as num?) ?? 0).toInt();
      final statement = db.prepare(_walkQuery);
      try {
        final cursor = statement.selectCursor([start]);
        final decoder = _Decoder();
        while (cursor.moveNext()) {
          final row = cursor.current;
          decoder.feed(
            (row.columnAt(0) as num).toInt(),
            (row.columnAt(1) as num).toInt(),
            (row.columnAt(2) as num).toInt(),
            (row.columnAt(3) as num).toInt(),
          );
          // The same cut [since] makes, in the same units: a fix stamped in
          // whole seconds is in the window when its instant is not before it.
          if (decoder.t * 1000 < fromMs) continue;
          visit(decoder.t, decoder.lat, decoder.lng);
        }
      } finally {
        statement.close();
      }
    } finally {
      db.close();
    }
  }

  /// The newest anchor at or before an instant (see [_anchorAtOrBefore]).
  static const _anchorQuery =
      'SELECT id FROM fix WHERE id % $_anchorEvery = 0 AND t <= ? '
      'ORDER BY id DESC LIMIT 1';

  /// Every row from an anchor forward, in the order the deltas chain.
  static const _walkQuery =
      'SELECT id, t, lat, lng FROM fix WHERE id >= ? ORDER BY id';

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
    final rows = await _db.getAll(_anchorQuery, [
      time.millisecondsSinceEpoch ~/ 1000,
    ]);
    return rows.isEmpty ? 0 : ((rows.first['id'] as num?) ?? 0).toInt();
  }

  /// Rebuilds absolute positions from [startId] forward.
  ///
  /// [startId] has to be an anchor or 0 — the first row of the table is always
  /// an anchor, because the writer rounds up to a boundary whenever it has
  /// nothing to count from and eviction only ever deletes whole groups.
  /// [_Decoder] is the belt to that braces.
  Future<List<TrackFix>> _decodeFrom(int startId) async {
    final rows = await _db.getAll(_walkQuery, [startId]);
    final fixes = <TrackFix>[];
    final decoder = _Decoder();
    for (final row in rows) {
      decoder.feed(
        (row['id'] as num).toInt(),
        (row['t'] as num).toInt(),
        (row['lat'] as num).toInt(),
        (row['lng'] as num).toInt(),
      );
      fixes.add(
        TrackFix(
          time: DateTime.fromMillisecondsSinceEpoch(
            decoder.t * 1000,
            isUtc: true,
          ),
          latitude: decoder.lat / _scale,
          longitude: decoder.lng / _scale,
        ),
      );
    }
    return fixes;
  }
}

/// The delta walk, written once.
///
/// [LocationTrack.since] and [LocationTrack.scan] read the rows through
/// different connections on different isolates, and the one thing they must
/// never do is disagree about what a row means — a decoder copied into two
/// places is two decoders, and the day one of them is fixed the other becomes
/// the bug.
///
/// The first row fed is read as absolute whatever its id: it is always an
/// anchor (the writer rounds up to a boundary whenever it has nothing to count
/// from, and eviction only deletes whole groups), and a first row that somehow
/// is not one is still read absolute, which is the only reading that can be
/// right.
class _Decoder {
  var _started = false;

  /// The absolute values after the last [feed].
  int t = 0;
  int lat = 0;
  int lng = 0;

  void feed(int id, int t, int lat, int lng) {
    if (!_started || id % LocationTrack._anchorEvery == 0) {
      this.t = t;
      this.lat = lat;
      this.lng = lng;
      _started = true;
    } else {
      this.t += t;
      this.lat += lat;
      this.lng += lng;
    }
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
