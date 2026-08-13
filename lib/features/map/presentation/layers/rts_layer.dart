/// The 強震監視器 (real-time seismic monitor) map layer — every reporting station
/// as a dot coloured by its live shaking intensity, refreshed from the RTS feed.
library;

import 'dart:async';

import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/widgets/rts_monitor_panel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/intensity_legend.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A realtime [MapLayer]: subscribes to the live RTS feed and repaints the
/// station dots (coloured by raw intensity `i`) on every ~1 Hz snapshot. Not
/// tap- or timeline-driven; its "sheet" is a compact monitor panel showing the
/// feed's freshness, and [buildLegend] shows the intensity scale.
class RtsMapLayer with MapLayerDefaults implements MapLayer {
  RtsMapLayer(this._feed, this._stationRepository);

  final RealtimeNotifier<Rts> _feed;
  final TremStationRepository _stationRepository;

  Map<String, SeismicStation> _stations = const {};
  MapLibreMapController? _controller;
  bool _listening = false;
  bool _added = false;
  RealtimeStatus? _appliedStatus;
  bool _stationsFetching = false;
  int _stationRetries = 0;

  /// Identity of the last payload pushed to the source: `null` when offline
  /// (empty collection was sent), else the feed's data object — skips the
  /// per-tick round trip when a status change re-notifies without new data.
  Object? _lastSent;

  static const String _sourceId = 'rts-src';
  static const String _circleId = 'rts-circle';
  static const String _labelId = 'rts-label';
  static const int _maxStationRetries = 8;
  static const double _liveOpacity = 1.0;
  static const double _staleOpacity = 0.35;

  /// A neutral hairline separating overlapping dots — legacy uses the theme's
  /// outlineVariant, but render() has no BuildContext, so a mid-grey that reads
  /// on both light and dark tiles stands in.
  static const String _strokeColor = '#9E9E9E';
  static const Map<String, dynamic> _emptyCollection = {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

  @override
  String get id => 'monitor';

  @override
  IconData get icon => Icons.sensors_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerMonitor;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => RtsMonitorPanel.bottomStripFraction;

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    await _ensureStations();
    await _removeFromMap(controller);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: _geoJson()),
    );
    await controller.addCircleLayer(
      _sourceId,
      _circleId,
      _circleProps(_liveOpacity),
    );
    // Station id over its raw intensity, pinned under the dot; the sort key
    // lets hot stations win placement (see [stationLabelProps]).
    await controller.addSymbolLayer(
      _sourceId,
      _labelId,
      _labelProps(_liveOpacity),
      minzoom: 10,
    );
    _added = true;
    _appliedStatus = null;
    await _pushUpdate();
    if (!_listening) {
      _feed.addListener(_onFeed);
      _listening = true;
    }
  }

  void _onFeed() => unawaited(_pushUpdate());

  Future<void> _pushUpdate() async {
    final controller = _controller;
    if (controller == null || !_added) return;
    if (_stations.isEmpty) await _ensureStations();
    final status = _feed.state.status;
    // Never present aged shaking as current: hide the dots when the feed is
    // offline, and dim them while stale (the monitor panel flags the status too).
    final offline = status == RealtimeStatus.offline;
    // A status-only change (stale→live etc.) re-notifies without new data —
    // don't re-send the same payload, just re-apply the opacity below.
    final data = _feed.state.data;
    final payloadKey = offline ? null : data;
    try {
      if (!identical(payloadKey, _lastSent)) {
        _lastSent = payloadKey;
        await controller.setGeoJsonSource(
          _sourceId,
          offline ? _emptyCollection : _geoJson(),
        );
      }
      if (status != _appliedStatus) {
        _appliedStatus = status;
        final opacity = status == RealtimeStatus.live
            ? _liveOpacity
            : _staleOpacity;
        await controller.setLayerProperties(_circleId, _circleProps(opacity));
        await controller.setLayerProperties(_labelId, _labelProps(opacity));
      }
    } catch (_) {
      // Source not on the map (mid style-reload); the next render re-adds it.
    }
  }

  /// The full circle style at [opacity] — passed whole (not a partial update),
  /// since setLayerProperties resets any property left null. Colour comes from
  /// the shared instrumental-intensity palette, so the dots and the legend can
  /// never drift.
  CircleLayerProperties _circleProps(double opacity) => CircleLayerProperties(
    circleColor: InstrumentalIntensityColors.mapLibreInterpolate,
    circleRadius: _radiusExpression,
    circleStrokeColor: _strokeColor,
    circleStrokeWidth: 1,
    circleOpacity: opacity,
    // Stronger stations sort above weaker ones so a hot dot is never hidden.
    circleSortKey: _sortKey,
  );

  /// The full label style at [opacity] — station id over its raw intensity.
  /// Passed whole (setLayerProperties nulls anything omitted); the sort key
  /// places the strongest stations first so a hot reading never loses.
  SymbolLayerProperties _labelProps(double opacity) => stationLabelProps(
    textField: const <Object>['get', 'label'],
    textSize: 10,
    opacity: opacity,
    sortKey: _labelSortKey,
  );

  @override
  Widget buildSheet(BuildContext context) => RtsMonitorPanel(feed: _feed);

  @override
  Widget buildLegend(BuildContext context) => const MapLegendCard(
    child: IntensityLegend(mode: IntensityLegendMode.rts),
  );

  @override
  Future<void> clear(MapLibreMapController controller) async {
    if (_listening) {
      _feed.removeListener(_onFeed);
      _listening = false;
    }
    await _removeFromMap(controller);
    _controller = null;
  }

  @override
  void onStyleReset() => _added = false;

  /// Loads the station directory, retrying (bounded) on failure — a transient
  /// fault would otherwise leave every dot dropped (blank monitor) for the whole
  /// activation, since the feed carries only per-id intensities, not positions.
  Future<void> _ensureStations() async {
    if (_stations.isNotEmpty ||
        _stationsFetching ||
        _stationRetries >= _maxStationRetries) {
      return;
    }
    _stationsFetching = true;
    _stationRetries++;
    try {
      final directory = (await _stationRepository.stations()).valueOrNull;
      if (directory != null && directory.isNotEmpty) {
        _stations = directory;
        _stationRetries = 0;
      }
    } finally {
      _stationsFetching = false;
    }
  }

  Map<String, dynamic> _geoJson() {
    final live = _feed.state.data?.station ?? const <String, RtsStation>{};
    final features = <Map<String, dynamic>>[];
    for (final entry in live.entries) {
      final station = _stations[entry.key];
      if (station == null) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [station.longitude, station.latitude],
        },
        'properties': {
          'i': entry.value.intensityRaw,
          'label':
              '${entry.key}\n${entry.value.intensityRaw.toStringAsFixed(1)}',
        },
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    // Layers before their source; tolerate any not currently on the map.
    for (final layerId in [_circleId, _labelId]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {
        // Expected when the layer isn't on the map yet.
      }
    }
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {
      // Expected when the source isn't on the map yet.
    }
  }

  /// Dots scale with zoom so they stay legible zoomed in (legacy: 2px at z4 →
  /// 8px at z12).
  static const List<Object> _radiusExpression = [
    'interpolate',
    ['linear'],
    ['zoom'],
    4,
    2.0,
    12,
    8.0,
  ];

  /// Higher instrumental intensity draws on top; stations without an `i` sink.
  static const List<Object> _sortKey = [
    'coalesce',
    ['get', 'i'],
    -5,
  ];

  /// Labels place strongest-first: a symbol's *lower* sort key wins a collision,
  /// so negate the intensity — a hot station's reading never loses to a calm one.
  static const List<Object> _labelSortKey = [
    '-',
    0,
    [
      'coalesce',
      ['get', 'i'],
      -5,
    ],
  ];
}
