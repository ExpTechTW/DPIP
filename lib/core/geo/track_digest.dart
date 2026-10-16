/// The movement history boiled down to something a cheap phone can draw.
///
/// The track's budget allows a few million fixes. Handing even a week of them
/// to MapLibre as one GeoJSON line is already a few thousand vertices; handing
/// it years would be a multi-megabyte string over the platform channel, parsed
/// and re-tiled natively, for a picture that cannot show more than a few
/// thousand distinct strokes at any zoom anyway. So the map never sees the
/// fixes — it sees a [TrackDigest], built off the UI isolate, whose size is
/// bounded by [TrackDigestBuilder.budget] however long the history is.
library;

import 'dart:isolate';
import 'dart:math' as math;

import 'package:dpip/core/geo/location_track.dart';
import 'package:dpip/core/logging/log.dart';

/// One straight stroke of the drawn track: the device moved between these two
/// places, with no recording gap in between.
class TrackSegment {
  const TrackSegment({
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toLatitude,
    required this.toLongitude,
    required this.time,
  });

  final double fromLatitude;
  final double fromLongitude;
  final double toLatitude;
  final double toLongitude;

  /// The **last** time this stroke was travelled. A daily commute is one
  /// stroke, not three hundred, and it is as recent as this morning — which is
  /// what its age colour should say.
  final DateTime time;
}

/// A bounded summary of every fix in a window: what [TrackDigestBuilder]
/// produces and the map layer draws.
class TrackDigest {
  const TrackDigest({
    required this.fixes,
    required this.segments,
    required this.dots,
    required this.cellE4,
    this.first,
    this.latest,
    this.bounds,
  });

  /// A window with nothing in it.
  static const empty = TrackDigest(fixes: 0, segments: [], dots: [], cellE4: 1);

  /// How many recorded fixes the window held — before any thinning, so it is
  /// the number a person would count, not the number drawn.
  final int fixes;

  /// The strokes to draw, each at most once.
  final List<TrackSegment> segments;

  /// Places visited with no stroke to or from them — a fix with a recording
  /// gap on both sides. Without these, a lone report between two long silences
  /// would simply vanish from the map. Each carries its last visit time.
  final List<TrackFix> dots;

  /// The oldest and newest fixes of the window, exactly as recorded — never
  /// thinned, because "where was I last" must not be a grid cell's stand-in.
  final TrackFix? first;
  final TrackFix? latest;

  /// The box around every fix in the window (exact, not thinned), or null when
  /// it is empty — what the camera fits.
  final ({double south, double west, double north, double east})? bounds;

  /// The grid edge the thinning settled on, in ten-thousandths of a degree
  /// (about 11 m each). 1 means nothing at all was merged: every stroke is
  /// exactly as recorded.
  final int cellE4;

  bool get isEmpty => fixes == 0;

  /// Reads every fix at or after [from] in [track] on a background isolate and
  /// returns its digest.
  ///
  /// The whole read happens off the UI isolate — opening, walking and thinning
  /// — and only the bounded result crosses back, so asking for the entire
  /// history costs the UI nothing but the wait. A failed read is logged and
  /// answers [empty], the same way [LocationTrack.since] does.
  static Future<TrackDigest> read(
    LocationTrack track,
    DateTime from, {
    int budget = TrackDigestBuilder.defaultBudget,
    Duration gap = TrackDigestBuilder.defaultGap,
  }) async {
    final path = track.path;
    try {
      return await Isolate.run(
        () => _digestFile(path, from, budget, gap),
        debugName: 'location track digest',
      );
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'reading location track digest');
      return empty;
    }
  }
}

/// The isolate's whole job. Top-level so the closure handed to [Isolate.run]
/// captures four plain values and nothing that holds a connection.
TrackDigest _digestFile(String path, DateTime from, int budget, Duration gap) {
  final builder = TrackDigestBuilder(budget: budget, gap: gap);
  LocationTrack.scan(path, from, builder.add);
  return builder.build();
}

/// Streams fixes in and keeps at most [budget] things to draw.
///
/// ## How it thins
///
/// Every fix is snapped to a square grid cell, and the output is the set of
/// **distinct cell-to-cell strokes** the device made, plus cells visited with
/// no stroke at all. Two consecutive fixes in the same cell add nothing; a
/// stroke already taken adds nothing but a fresher timestamp.
///
/// The set rather than the sequence, because of what a long history actually
/// looks like: the same commute, hundreds of times. Douglas–Peucker or
/// per-run thinning keeps every repetition — each one a separate polyline
/// lying on top of the last — so a year of commuting is a year's worth of
/// vertices, and the only way to fit a budget is to coarsen until home and
/// work are one cell. Distinct strokes make a repeated route cost what it costs
/// once, and the budget goes on places, not on days.
///
/// ## The budget
///
/// Cells start at the precision the file stores (1e-4°, about 11 m), so a
/// short window is drawn exactly. Whenever cells + strokes exceed [budget], the
/// cell edge doubles and what is held so far is re-snapped. That re-snap is
/// exact, not an approximation of re-reading: cells nest (a coarse cell is
/// precisely four fine ones), so a fine stroke maps to the coarse stroke the
/// same two fixes would have produced, or to nothing when both ends fall into
/// one coarse cell. Each doubling is O(budget) and the edge can double at most
/// ~22 times before one cell spans a hemisphere, so the whole pass is
/// O(fixes + budget) with memory bounded by [budget] — independent of how many
/// fixes go in.
///
/// Drawn coordinates are at most 2 × [budget] (two per stroke, one per dot).
/// At the default that is ≤ 8,000 coordinates, roughly 160 KB of GeoJSON: one
/// platform-channel write and a geojson-vt tiling that a low-end Android phone
/// does in tens of milliseconds, once per load rather than per frame.
///
/// ## Gaps
///
/// Two consecutive fixes more than [gap] apart are not joined. The device only
/// records while it is moving and background location is allowed, so a long
/// silence means "unknown", and a straight line across it would draw a route
/// nobody took — overnight at home, then the first fix two towns away in the
/// morning, is not a straight drive through the fields between.
class TrackDigestBuilder {
  TrackDigestBuilder({this.budget = defaultBudget, this.gap = defaultGap})
    : assert(budget >= 16, 'a budget under 16 cannot hold even one hemisphere');

  /// Cells + strokes held at once. See the class docs for what it costs.
  static const int defaultBudget = 4000;

  /// The longest silence still drawn as one continuous movement.
  static const Duration defaultGap = Duration(hours: 2);

  final int budget;
  final Duration gap;

  late final int _gapSeconds = gap.inSeconds;

  /// log2 of the cell edge in stored units.
  int _shift = 0;

  /// Visited cells, keyed by [_key]. Insertion-ordered, so a merged cell keeps
  /// the representative of whichever of its children was visited first.
  Map<int, _Cell> _cells = {};

  /// Distinct strokes, keyed by their two cell keys low-first (a stroke has no
  /// direction on a map), valued by the last time it was travelled.
  Map<(int, int), int> _strokes = {};

  int _fixes = 0;
  int? _prevTime;
  int _prevLat = 0;
  int _prevLng = 0;
  int _prevCell = 0;

  int _firstTime = 0;
  int _firstLat = 0;
  int _firstLng = 0;
  int _lastTime = 0;
  int _lastLat = 0;
  int _lastLng = 0;
  int _south = 0;
  int _west = 0;
  int _north = 0;
  int _east = 0;

  /// Adds one fix, in the units the file stores: Unix seconds and
  /// ten-thousandths of a degree. Fixes are expected oldest first.
  void add(int seconds, int latE4, int lngE4) {
    if (_fixes == 0) {
      _firstTime = seconds;
      _firstLat = latE4;
      _firstLng = lngE4;
      _south = _north = latE4;
      _west = _east = lngE4;
    } else {
      _south = math.min(_south, latE4);
      _north = math.max(_north, latE4);
      _west = math.min(_west, lngE4);
      _east = math.max(_east, lngE4);
    }
    _fixes++;
    _lastTime = seconds;
    _lastLat = latE4;
    _lastLng = lngE4;

    final cell = _key(latE4, lngE4, _shift);
    final known = _cells[cell];
    if (known == null) {
      _cells[cell] = _Cell(latE4, lngE4, seconds);
    } else {
      known.time = math.max(known.time, seconds);
    }

    final prevTime = _prevTime;
    // `abs`: a device clock set backwards produces a negative step, which is
    // still one movement and not a gap.
    if (prevTime != null &&
        (seconds - prevTime).abs() <= _gapSeconds &&
        cell != _prevCell) {
      final stroke = cell < _prevCell ? (cell, _prevCell) : (_prevCell, cell);
      final seen = _strokes[stroke];
      _strokes[stroke] = seen == null ? seconds : math.max(seen, seconds);
    }
    _prevTime = seconds;
    _prevLat = latE4;
    _prevLng = lngE4;
    _prevCell = cell;

    while (_cells.length + _strokes.length > budget && _shift < _maxShift) {
      _coarsen();
    }
  }

  /// Doubles the cell edge and re-snaps what is held. Exact — see the class
  /// docs.
  void _coarsen() {
    _shift++;
    final remap = <int, int>{};
    final cells = <int, _Cell>{};
    for (final MapEntry(key: old, value: cell) in _cells.entries) {
      // The representative lies inside its fine cell, so snapping it at the
      // new size lands in exactly the coarse cell that contains the fine one.
      final next = _key(cell.lat, cell.lng, _shift);
      remap[old] = next;
      final merged = cells[next];
      if (merged == null) {
        cells[next] = cell;
      } else {
        merged.time = math.max(merged.time, cell.time);
      }
    }
    final strokes = <(int, int), int>{};
    for (final MapEntry(key: (a, b), value: time) in _strokes.entries) {
      final na = remap[a]!;
      final nb = remap[b]!;
      if (na == nb) continue;
      final stroke = na < nb ? (na, nb) : (nb, na);
      final seen = strokes[stroke];
      strokes[stroke] = seen == null ? time : math.max(seen, time);
    }
    _cells = cells;
    _strokes = strokes;
    _prevCell = _key(_prevLat, _prevLng, _shift);
  }

  /// The digest of everything added so far.
  TrackDigest build() {
    if (_fixes == 0) return TrackDigest.empty;
    final joined = <int>{};
    final segments = <TrackSegment>[];
    for (final MapEntry(key: (a, b), value: time) in _strokes.entries) {
      joined
        ..add(a)
        ..add(b);
      final from = _cells[a]!;
      final to = _cells[b]!;
      segments.add(
        TrackSegment(
          fromLatitude: from.lat / _scale,
          fromLongitude: from.lng / _scale,
          toLatitude: to.lat / _scale,
          toLongitude: to.lng / _scale,
          time: _instant(time),
        ),
      );
    }
    return TrackDigest(
      fixes: _fixes,
      segments: segments,
      dots: [
        for (final MapEntry(key: key, value: cell) in _cells.entries)
          if (!joined.contains(key)) _fix(cell.time, cell.lat, cell.lng),
      ],
      cellE4: 1 << _shift,
      first: _fix(_firstTime, _firstLat, _firstLng),
      latest: _fix(_lastTime, _lastLat, _lastLng),
      bounds: (
        south: _south / _scale,
        west: _west / _scale,
        north: _north / _scale,
        east: _east / _scale,
      ),
    );
  }

  static const double _scale = 10000;

  /// Past this one cell is wider than any coordinate, so doubling again can
  /// merge nothing more.
  static const int _maxShift = 23;

  /// Packs a cell's two indices into one int. `>>` on a negative int floors,
  /// which is what makes cells nest across the equator and the meridian too.
  /// Offsets keep both indices positive: |lat| ≤ 900 000 and |lng| ≤ 1 800 000
  /// stored units both fit under 2^22, and the packed key stays under 2^46 —
  /// inside a double's 53-bit mantissa, so the key is exact on every platform.
  static int _key(int lat, int lng, int shift) =>
      ((lat >> shift) + _offset) * _span + ((lng >> shift) + _offset);

  static const int _offset = 1 << 22;
  static const int _span = 1 << 23;

  static DateTime _instant(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  static TrackFix _fix(int seconds, int lat, int lng) => TrackFix(
    time: _instant(seconds),
    latitude: lat / _scale,
    longitude: lng / _scale,
  );
}

/// One grid cell: where to draw it (the first fix that landed in it) and the
/// last time it was visited.
class _Cell {
  _Cell(this.lat, this.lng, this.time);

  final int lat;
  final int lng;
  int time;
}
