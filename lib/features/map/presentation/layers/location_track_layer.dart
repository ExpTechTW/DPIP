/// The device's own movement history, drawn on the map.
///
/// A sheet layer, like the mesh nodes: no frames, no timeline, and nothing
/// fetched — it reads the file the native background-location path writes
/// (`LocationTrackStore` on both platforms) and draws it. The sheet carries
/// the time range, what is stored, and the one statement this layer must never
/// bury: the history exists only on this phone.
library;

import 'dart:async';

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/geo/location_track.dart';
import 'package:dpip/core/geo/track_digest.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/platform/background_location.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/features/map/presentation/widgets/location_track_sheet.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/camera_fit.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The windows the sheet offers. [week] is the default: long enough to show a
/// routine, short enough to decode in a blink on any phone.
enum TrackRange { today, week, month, all }

/// The instant [range] starts at, given the calibrated [now].
///
/// [TrackRange.today] is the Taipei calendar day — the same fixed +8 wall clock
/// every other date in the app is read in — and [TrackRange.all] is the epoch,
/// which is older than any fix.
DateTime trackRangeStart(TrackRange range, DateTime now) => switch (range) {
  TrackRange.today => _taipeiMidnight(now),
  TrackRange.week => now.toUtc().subtract(const Duration(days: 7)),
  TrackRange.month => now.toUtc().subtract(const Duration(days: 30)),
  TrackRange.all => DateTime.utc(1970),
};

DateTime _taipeiMidnight(DateTime now) {
  final wall = AppTime.taipei(now);
  return DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
  ).subtract(const Duration(hours: 8));
}

/// What the sheet shows: whether anything has ever been recorded, what is
/// stored, and the digest of the selected window.
@immutable
class LocationTrackSnapshot {
  const LocationTrackSnapshot({
    required this.recorded,
    required this.range,
    this.fixes = 0,
    this.bytes = 0,
    this.oldest,
    this.digest = TrackDigest.empty,
  });

  /// False on a fresh install, on a device that never allowed background
  /// location, and right after a clear — the sheet's empty state.
  final bool recorded;

  /// The window [digest] covers.
  final TrackRange range;

  /// Every fix in the file, whatever the window.
  final int fixes;

  /// The file's size on disk.
  final int bytes;

  /// The oldest fix still in the file.
  final DateTime? oldest;

  /// The selected window, thinned for drawing.
  final TrackDigest digest;
}

/// Summarises the fixes at or after `from` — [TrackDigest.read] in the app; a
/// test can hand in one that does not spawn an isolate.
typedef TrackDigestReader = Future<TrackDigest> Function(
  LocationTrack track,
  DateTime from,
);

class LocationTrackMapLayer with MapLayerDefaults implements MapLayer {
  LocationTrackMapLayer(
    this._backgroundLocation, {
    Future<LocationTrack?> Function()? open,
    TrackDigestReader? digest,
    DateTime Function()? now,
  }) : _open = open ?? LocationTrack.open,
       _readDigest = digest ?? TrackDigest.read,
       _now = now ?? (() => AppTime.utc);

  final BackgroundLocationService _backgroundLocation;
  final Future<LocationTrack?> Function() _open;
  final TrackDigestReader _readDigest;

  /// Calibrated now — [AppTime.utc] in the app, a fixed instant in a test so
  /// "today" does not depend on when the suite runs.
  final DateTime Function() _now;

  /// Wire id. Also what the picker groups by (see `categoryOf`).
  static const String layerId = 'location-track';

  static const String _sourceId = 'location-track-src';
  static const String _lineId = 'location-track-line';
  static const String _dotId = 'location-track-dot';
  static const String _latestId = 'location-track-latest';

  /// How many shades the age ramp is cut into.
  ///
  /// Strokes are grouped into this many features rather than one feature each:
  /// a stroke's coordinates are about 40 bytes of GeoJSON, a feature wrapper
  /// around them another 80, so grouping cuts the upload to roughly a third.
  /// Eight steps of a ramp that already fades by opacity are not visibly
  /// different from a continuous one.
  static const int _shades = 8;

  // Colours are getters, not `static const`: the colour-vision transform is not
  // a compile-time constant. The legend converts the same hexes, so the key
  // names the line it points at under every correction.

  /// The newest end of the ramp, and the last-position marker. Orange stands
  /// clear of both base-map palettes' greys and of every warning red.
  static String get _newColor => '#EF6C00'.vision;

  /// The oldest end — the same hue, paler, and drawn more transparent below.
  static String get _oldColor => '#FFB74D'.vision;
  static String get _strokeColor => '#FFFFFF'.vision;

  static const double _oldOpacity = 0.4;
  static const double _newOpacity = 0.95;

  /// The time range picked in the sheet.
  final ValueNotifier<TrackRange> range = ValueNotifier(TrackRange.week);

  /// The latest load, or null before the first one finishes.
  final ValueNotifier<LocationTrackSnapshot?> snapshot = ValueNotifier(null);

  /// A load or a clear is running. The map keeps showing the previous drawing
  /// until the new one is ready, so this is what the sheet shows instead.
  final ValueNotifier<bool> busy = ValueNotifier(false);

  MapLibreMapController? _controller;
  LocationTrack? _track;
  bool _added = false;
  bool _surfaceVisible = true;

  /// Bumped by every load and by [clear]; a load that finds it moved on drops
  /// its result instead of drawing over a newer one.
  int _generation = 0;

  /// What the last load read, to skip a foreground refresh that would only
  /// redraw the same thing.
  Object? _loadedSignature;

  /// Serial lane for the map writes — a range change landing while a refresh
  /// is drawing must not interleave two `setGeoJsonSource` calls.
  Future<void> _ops = Future<void>.value();

  /// The camera is fitted once per activation, not on every refresh: a fix
  /// arriving while the user is looking at their own street must not throw the
  /// map back out to the whole track.
  bool _framed = false;
  bool _wantFrame = false;
  Size? _frameViewport;
  double _frameTopInset = 0;
  double _frameBottomInset = 0;

  @override
  String get id => layerId;

  @override
  IconData get icon => Icons.route_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerLocationTrack;

  @override
  String? subtitle(BuildContext context) =>
      AppLocalizations.of(context).mapLayerLocationTrackSubtitle;

  @override
  bool get usesTimeline => false;

  /// How much of the map the sheet covers at rest. The sheet measures it —
  /// see [LocationTrackSheet] — and writes it back here for the scaffold's
  /// framing.
  double peekExtent = LocationTrackSheet.fallbackPeekExtent;

  @override
  double get bottomChromeFraction => peekExtent;

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    // Mounted with whatever was read last, so coming back to the layer — or a
    // theme change rebuilding the style — shows the track at once instead of
    // an empty map while the file is read again.
    await _enqueue(() => _mount(controller));
    // Not awaited. `render` runs on the scaffold's serial lane, and reading a
    // long history can take seconds on a slow phone: a layer switch or a
    // base-map toggle queued behind it would wait that long. The read draws
    // through this layer's own lane when it lands; after a style rebuild it
    // finds the file unchanged and reads nothing.
    unawaited(_load(frame: !_framed, onlyIfChanged: true));
  }

  /// The most recent load, finished or not — for a test to wait on.
  @visibleForTesting
  Future<void> get pending => _pending;
  Future<void> _pending = Future<void>.value();

  /// Picks another window and fits the camera to it — a deliberate choice of
  /// what to look at, unlike a background refresh.
  Future<void> selectRange(TrackRange next) async {
    if (range.value == next) return;
    range.value = next;
    await _load(frame: true);
  }

  /// Re-reads the file when something in it may have changed: new fixes
  /// recorded while the app was in the background, or the day rolling over
  /// under "today". A refresh that would read the same thing reads nothing.
  Future<void> refresh() => _load(frame: false, onlyIfChanged: true);

  /// Deletes the whole history (after the sheet's confirmation), redraws, and
  /// answers whether the file really is empty now.
  ///
  /// Through [BackgroundLocationService.clearTrack], never a file delete from
  /// here: the native recorder holds the database open, and only it can empty
  /// the file without leaving an unlinked inode it keeps writing into. That
  /// call logs a failure rather than throwing, so the answer comes from
  /// re-reading the file — "cleared" is said only when it is true.
  Future<bool> clearTrack() async {
    busy.value = true;
    try {
      await _backgroundLocation.clearTrack();
    } finally {
      _loadedSignature = null;
      await _load(frame: false);
    }
    return !(snapshot.value?.recorded ?? false);
  }

  /// The map band the sheet leaves visible, for the camera fit. The sheet
  /// measures it, because only the sheet knows how much it covers.
  void rememberFrameMetrics({
    required Size viewport,
    required double topInset,
    required double bottomInset,
  }) {
    _frameViewport = viewport;
    _frameTopInset = topInset;
    _frameBottomInset = bottomInset;
    if (_wantFrame) _frame();
  }

  Future<void> _load({required bool frame, bool onlyIfChanged = false}) =>
      _pending = _read(frame: frame, onlyIfChanged: onlyIfChanged);

  Future<void> _read({required bool frame, required bool onlyIfChanged}) async {
    final generation = ++_generation;
    busy.value = true;
    try {
      final track = await _ensureTrack();
      if (generation != _generation) return;
      final current = range.value;
      if (track == null) {
        _loadedSignature = null;
        await _publish(LocationTrackSnapshot(recorded: false, range: current));
        return;
      }
      final stats = await track.stats();
      if (generation != _generation) return;
      // The window is compared in the units the file is stamped in: the
      // native writers stamp each fix with the device clock, so the calibrated
      // start is moved by the device's known offset before it is compared.
      final from = trackRangeStart(
        current,
        _now(),
      ).subtract(AppTime.calibratedTimeOffset);
      final signature = (
        current,
        stats.fixes,
        stats.bytes,
        stats.oldest,
        // An hour's resolution: a rolling window that moved by minutes is not
        // worth re-reading a year of history for.
        from.millisecondsSinceEpoch ~/ Duration.millisecondsPerHour,
      );
      if (onlyIfChanged && signature == _loadedSignature) return;
      if (stats.fixes == 0) {
        _loadedSignature = signature;
        await _publish(LocationTrackSnapshot(recorded: false, range: current));
        return;
      }
      final digest = await _readDigest(track, from);
      if (generation != _generation) return;
      _loadedSignature = signature;
      await _publish(
        LocationTrackSnapshot(
          recorded: true,
          range: current,
          fixes: stats.fixes,
          bytes: stats.bytes,
          oldest: stats.oldest,
          digest: digest,
        ),
      );
      if (frame && !digest.isEmpty) {
        _framed = true;
        _wantFrame = true;
        _frame();
      }
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'location track layer load');
    } finally {
      if (generation == _generation) busy.value = false;
    }
  }

  /// The open track, opening it on first use. Two loads that both find it
  /// closed share one open rather than leaving a second connection behind.
  /// Absent is not cached: the file appears the first time the native side
  /// records a fix, and the next load should find it.
  Future<LocationTrack?> _ensureTrack() async {
    final open = _track;
    if (open != null) return open;
    final opening = _opening ??= _open();
    try {
      return _track = await opening;
    } finally {
      _opening = null;
    }
  }

  Future<LocationTrack?>? _opening;

  Future<void> _publish(LocationTrackSnapshot next) async {
    snapshot.value = next;
    final controller = _controller;
    if (controller == null) return;
    await _enqueue(() => _draw(controller, next.digest));
  }

  Future<void> _mount(MapLibreMapController controller) async {
    await _removeFromMap(controller);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: trackGeoJson(snapshot.value?.digest)),
    );
    await controller.addLineLayer(
      _sourceId,
      _lineId,
      LineLayerProperties(
        lineColor: _ramp(_oldColor, _newColor),
        lineOpacity: _ramp(_oldOpacity, _newOpacity),
        lineWidth: const [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          6,
          2.0,
          12,
          3.5,
          16,
          5.0,
        ],
        lineCap: 'round',
        lineJoin: 'round',
        // Newer strokes on top, so today's route is never hidden under the
        // faded one from last month that runs along the same street.
        lineSortKey: [Expressions.get, 'r'],
      ),
      filter: _kindIs('line'),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _sourceId,
      _dotId,
      CircleLayerProperties(
        circleRadius: 3.0,
        circleColor: _ramp(_oldColor, _newColor),
        circleOpacity: _ramp(_oldOpacity, _newOpacity),
      ),
      filter: _kindIs('dot'),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _sourceId,
      _latestId,
      CircleLayerProperties(
        circleRadius: 7.0,
        circleColor: _newColor,
        circleStrokeColor: _strokeColor,
        circleStrokeWidth: 2.5,
      ),
      filter: _kindIs('latest'),
      enableInteraction: false,
    );
    _added = true;
  }

  Future<void> _draw(
    MapLibreMapController controller,
    TrackDigest digest,
  ) async {
    if (!_added || !identical(controller, _controller)) return;
    try {
      await controller.setGeoJsonSource(_sourceId, trackGeoJson(digest));
    } catch (error, stackTrace) {
      // The style can reload underneath us; the next render re-adds.
      Log.handle(error, stackTrace, 'location track draw');
    }
  }

  /// Fits the camera to the window's fixes, once the sheet has said how much
  /// of the map it covers.
  void _frame() {
    final controller = _controller;
    final viewport = _frameViewport;
    final bounds = snapshot.value?.digest.bounds;
    if (controller == null || viewport == null || bounds == null) return;
    final safe = safeFitBounds(
      LatLngBounds(
        southwest: LatLng(bounds.south, bounds.west),
        northeast: LatLng(bounds.north, bounds.east),
      ),
    );
    if (safe == null) return;
    final fit = boundsFitCamera(
      safe,
      viewport: viewport,
      topInset: _frameTopInset,
      bottomInset: _frameBottomInset,
      minZoom: mapMinZoom,
      // A track that never left one block would otherwise fit to street level
      // and look like a map with nothing on it.
      maxZoom: 15,
    );
    if (fit == null) return;
    _wantFrame = false;
    unawaited(
      controller
          .animateCamera(CameraUpdate.newLatLngZoom(fit.target, fit.zoom))
          .catchError((Object error, StackTrace stackTrace) {
            Log.handle(error, stackTrace, 'location track camera fit');
            return null;
          }),
    );
  }

  @override
  void onSurfaceVisibility(bool visible) {
    final returned = visible && !_surfaceVisible;
    _surfaceVisible = visible;
    // Back from the background (or another tab): the native side may have
    // recorded fixes in the meantime.
    if (returned && _controller != null) unawaited(refresh());
  }

  @override
  Widget buildSheet(BuildContext context) => LocationTrackSheet(layer: this);

  @override
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MapLegendCard(
      child: SymbolLegend(
        items: [
          SymbolLegendItem(
            swatch: LineSwatch(
              color: const Color(0xFFEF6C00).vision,
              width: 3,
              opacity: _newOpacity,
            ),
            label: l10n.locationTrackLegendNewer,
          ),
          SymbolLegendItem(
            swatch: LineSwatch(
              color: const Color(0xFFFFB74D).vision,
              width: 3,
              opacity: _oldOpacity,
            ),
            label: l10n.locationTrackLegendOlder,
          ),
          SymbolLegendItem(
            swatch: LegendDot(
              color: const Color(0xFFEF6C00).vision,
              size: 12,
              borderWidth: 2,
            ),
            label: l10n.locationTrackLegendLatest,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    _generation++;
    _framed = false;
    _wantFrame = false;
    busy.value = false;
    await _enqueue(() => _removeFromMap(controller));
    _controller = null;
    _loadedSignature = null;
    // The connection is the pool's isolate; there is no reason to keep it
    // while nobody is looking at the track. An open still in flight would
    // land after this and leave one behind, so it is waited out first.
    await _opening;
    final track = _track;
    _track = null;
    await track?.close();
  }

  @override
  void onStyleReset() {
    _added = false;
    _controller = null;
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    if (!_added) return;
    _added = false;
    for (final layerId in [_latestId, _dotId, _lineId]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {
        // Not present — the style may have been rebuilt under us.
      }
    }
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {
      // Same.
    }
  }

  Future<void> _enqueue(Future<void> Function() op) {
    final next = _ops.then((_) => op());
    _ops = next.catchError((Object error, StackTrace stackTrace) {
      Log.handle(error, stackTrace, 'location track map op');
    });
    return _ops;
  }

  static List<Object> _ramp(Object old, Object fresh) => [
    Expressions.interpolate,
    ['linear'],
    [Expressions.get, 'r'],
    0,
    old,
    1,
    fresh,
  ];

  static List<Object> _kindIs(String kind) => [
    Expressions.equal,
    [Expressions.get, 'kind'],
    kind,
  ];
}

/// The feature collection for [digest] — strokes and lone dots grouped into
/// [LocationTrackMapLayer._shades] shades of age, plus the last position.
///
/// `r` is the recency within the window, 0 for its oldest fix and 1 for its
/// newest; the layer's paint ramps run on it. Relative rather than absolute
/// age, so every window uses the whole ramp: "today" fades across the day and
/// "all" across the years.
@visibleForTesting
Map<String, dynamic> trackGeoJson(TrackDigest? digest) {
  final features = <Map<String, dynamic>>[];
  final first = digest?.first;
  final latest = digest?.latest;
  if (digest != null && first != null && latest != null) {
    const shades = LocationTrackMapLayer._shades;
    final start = first.time.millisecondsSinceEpoch;
    final span = latest.time.millisecondsSinceEpoch - start;
    int shadeOf(DateTime time) {
      if (span <= 0) return shades - 1;
      final r = (time.millisecondsSinceEpoch - start) / span;
      return (r * shades).floor().clamp(0, shades - 1);
    }

    final lines = List.generate(shades, (_) => <List<List<double>>>[]);
    for (final segment in digest.segments) {
      lines[shadeOf(segment.time)].add([
        [segment.fromLongitude, segment.fromLatitude],
        [segment.toLongitude, segment.toLatitude],
      ]);
    }
    final dots = List.generate(shades, (_) => <List<double>>[]);
    for (final dot in digest.dots) {
      dots[shadeOf(dot.time)].add([dot.longitude, dot.latitude]);
    }
    for (var shade = 0; shade < shades; shade++) {
      // The middle of the shade's band, so the oldest band is not drawn as
      // faint as a single fix at the very start of the window would be.
      final r = (shade + 0.5) / shades;
      if (lines[shade].isNotEmpty) {
        features.add({
          'type': 'Feature',
          'geometry': {'type': 'MultiLineString', 'coordinates': lines[shade]},
          'properties': {'kind': 'line', 'r': r},
        });
      }
      if (dots[shade].isNotEmpty) {
        features.add({
          'type': 'Feature',
          'geometry': {'type': 'MultiPoint', 'coordinates': dots[shade]},
          'properties': {'kind': 'dot', 'r': r},
        });
      }
    }
    features.add({
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [latest.longitude, latest.latitude],
      },
      'properties': {'kind': 'latest', 'r': 1},
    });
  }
  return {'type': 'FeatureCollection', 'features': features};
}
