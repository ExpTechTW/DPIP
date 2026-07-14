/// The 強震監視器 (real-time seismic monitor) map layer — every reporting station
/// as a dot coloured by its live shaking intensity, refreshed from the RTS feed.
library;

import 'dart:async';

import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/widgets/rts_monitor_panel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/core/error/result.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A realtime [MapLayer]: subscribes to the live RTS feed and repaints the
/// station dots (coloured by raw intensity `i`) on every ~1 Hz snapshot. Not
/// tap- or timeline-driven; its "sheet" is a compact monitor panel showing the
/// feed's freshness and the intensity legend.
class RtsMapLayer implements MapLayer {
  RtsMapLayer(this._feed, this._stationRepository);

  final RealtimeNotifier<Rts> _feed;
  final TremStationRepository _stationRepository;

  Map<String, SeismicStation> _stations = const {};
  MapLibreMapController? _controller;
  bool _listening = false;
  bool _added = false;

  static const String _sourceId = 'rts-src';
  static const String _circleId = 'rts-circle';

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
  Future<Result<List<MapFrame>>> frames() async => const Ok([]);

  @override
  Future<void> prepare(MapLibreMapController c, List<MapFrame> frames) async {}

  @override
  Future<void> show(MapLibreMapController c, MapFrame frame) async {}

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
      const CircleLayerProperties(
        circleColor: _colorExpression,
        circleRadius: _radiusExpression,
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 0.6,
      ),
    );
    _added = true;
    if (!_listening) {
      _feed.addListener(_onFeed);
      _listening = true;
    }
  }

  void _onFeed() => unawaited(_pushUpdate());

  Future<void> _pushUpdate() async {
    final controller = _controller;
    if (controller == null || !_added) return;
    try {
      await controller.setGeoJsonSource(_sourceId, _geoJson());
    } catch (_) {
      // Source not on the map (mid style-reload); the next render re-adds it.
    }
  }

  @override
  Future<void> onMapTap(
    LatLng latLng,
    MapLibreMapController controller,
  ) async {}

  @override
  Widget buildSheet(BuildContext context) => RtsMonitorPanel(feed: _feed);

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

  Future<void> _ensureStations() async {
    if (_stations.isNotEmpty) return;
    final directory = (await _stationRepository.stations()).valueOrNull;
    if (directory != null) _stations = directory;
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
        'properties': {'i': entry.value.intensityRaw},
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    try {
      await controller.removeLayer(_circleId);
    } catch (_) {
      // Expected when the layer isn't on the map yet.
    }
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {
      // Expected when the source isn't on the map yet.
    }
  }

  /// `interpolate` on the raw intensity property `i`.
  static const List<Object> _colorExpression = [
    'interpolate',
    ['linear'],
    ['get', 'i'],
    -3,
    '#0005D0',
    -2,
    '#004BF8',
    -1,
    '#009EF8',
    0,
    '#79E5FD',
    1,
    '#49E9AD',
    2,
    '#44FA34',
    3,
    '#BEFF0C',
    4,
    '#FFF000',
    5,
    '#FF9300',
    6,
    '#FC5235',
    7,
    '#B720E9',
  ];

  /// Dots grow with zoom so they stay legible when zoomed in.
  static const List<Object> _radiusExpression = [
    'interpolate',
    ['linear'],
    ['zoom'],
    4,
    3.0,
    8,
    5.0,
    12,
    9.0,
  ];
}
