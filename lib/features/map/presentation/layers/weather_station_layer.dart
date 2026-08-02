/// Base for the weather-family station value layers (temperature, humidity,
/// pressure, wind) — station dots coloured by value, tap → trend sheet.
library;

import 'dart:math' as math;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A sheet-driven [MapLayer]: renders every station as a dot coloured by its
/// current value (a MapLibre `interpolate` on the `value` property), and a tap
/// selects the nearest station, opening the shared [StationSheet] with its
/// reading and 24h/7d trend chart.
///
/// Concrete layers (temperature, humidity, …) supply only which value to read
/// from an observation ([valueOf]) and from the trend series ([trendOf]), plus
/// the unit and the colour ramp. All share one [MeteorWeatherRepository].
abstract class WeatherStationLayer implements MapLayer, StationSheetSource {
  WeatherStationLayer(this._repository);

  final MeteorWeatherRepository _repository;

  /// The observation value this layer plots (°C, %, hPa, m/s), or null if
  /// missing for a station.
  double? valueOf(WeatherObservation observation);

  /// The matching series from a station's trend payload.
  List<double?> trendOf(WeatherTrend trend);

  /// Decimal places for the reading text.
  int get decimals;

  /// `(value, hex colour)` stops for the dot colour, ascending by value.
  List<(double, String)> get colorStops;

  /// Whether to draw the value-coloured dot. A subclass may replace it with its
  /// own symbology (e.g. wind arrows) by returning false.
  @protected
  bool get drawCircle => true;

  /// Extra per-feature GeoJSON properties a subclass needs on the map — merged
  /// into each feature's `properties`.
  @protected
  Map<String, Object?> extraProperties(WeatherObservation observation) =>
      const {};

  /// Hook for a subclass to add its own layer(s) on [sourceId] after the base
  /// dot + labels. Any layer id added here must be listed in [extraLayerIds] so
  /// it's torn down with the rest.
  @protected
  Future<void> decorate(
    MapLibreMapController controller,
    String sourceId,
  ) async {}

  /// Ids of layers a subclass adds in [decorate], removed before the source.
  @protected
  List<String> get extraLayerIds => const [];

  final ValueNotifier<String?> _selected = ValueNotifier<String?>(null);

  /// Bumped on every tap that (re-)selects a station — even the same one — so the
  /// sheet can pop back up after the user collapsed it (a same-value [_selected]
  /// wouldn't notify on its own).
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);
  Map<String, WeatherStation> _stations = const {};
  Map<String, WeatherObservation> _observations = const {};
  bool _loaded = false;

  String get _sourceId => 'wx-$id-src';
  String get _circleId => 'wx-$id-circle';
  String get _labelId => 'wx-$id-label';

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => StationSheet.peekExtent;

  @override
  Future<Result<List<MapFrame>>> frames() async => const Ok([]);

  @override
  Future<void> prepare(MapLibreMapController c, List<MapFrame> frames) async {}

  @override
  Future<void> show(MapLibreMapController c, MapFrame frame) async {}

  @override
  Future<void> render(MapLibreMapController controller) async {
    await _ensureData();
    await _removeFromMap(controller);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: _geoJson()),
    );
    if (drawCircle) {
      await controller.addCircleLayer(
        _sourceId,
        _circleId,
        CircleLayerProperties(
          circleColor: _colorExpression(),
          circleRadius: 6,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 1,
          circleOpacity: 0.9,
        ),
        // Non-interactive: we do our own nearest-station math in onMapTap and
        // want EVERY tap via map#onMapClick — an interactive layer would eat an
        // on-dot tap as feature#onTap (unhandled) so the station never selects.
        enableInteraction: false,
      );
    }
    // Name + value labels — shown only when zoomed in; the engine places and
    // orients them (variable anchor + collision) so they never pile up.
    await controller.addSymbolLayer(
      _sourceId,
      _labelId,
      SymbolLayerProperties(
        textField: <Object>['get', 'label'],
        textFont: const ['Noto Sans TC Regular'],
        textSize: 11,
        textColor: '#FFFFFF',
        textHaloColor: '#000000',
        textHaloWidth: 1.2,
        textLineHeight: 1.1,
        textVariableAnchor: const ['top', 'bottom', 'left', 'right'],
        textRadialOffset: 0.9,
        textJustify: 'auto',
        textAllowOverlap: false,
        textOptional: true,
      ),
      minzoom: 9,
      enableInteraction: false,
    );
    // Let a subclass add its own symbology (e.g. wind arrows) on the source.
    await decorate(controller, _sourceId);
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    // Nearest station within ~0.18° (lon scaled by latitude), so a tap in empty
    // sea doesn't select anything.
    const threshold = 0.18 * 0.18;
    final cosLat = math.cos(latLng.latitude * math.pi / 180);
    String? best;
    var bestDistance = threshold;
    for (final entry in _stations.entries) {
      final observation = _observations[entry.key];
      if (observation == null || valueOf(observation) == null) continue;
      final station = entry.value;
      final dLat = station.latitude - latLng.latitude;
      final dLon = (station.longitude - latLng.longitude) * cosLat;
      final distance = dLat * dLat + dLon * dLon;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = entry.key;
      }
    }
    if (best != null) {
      _selected.value = best;
      _selectionRevision.value++;
    }
  }

  @override
  Widget buildSheet(BuildContext context) =>
      StationSheet(key: ValueKey(id), source: this);

  @override
  Future<void> clear(MapLibreMapController controller) async {
    await _removeFromMap(controller);
    _selected.value = null;
  }

  @override
  void onStyleReset() {}

  // --- StationSheetSource ---

  @override
  ValueListenable<String?> get selection => _selected;

  @override
  ValueListenable<int> get selectionRevision => _selectionRevision;

  @override
  String title(BuildContext context) => label(context);

  @override
  String stationName(String id) => _stations[id]?.name ?? id;

  @override
  String? stationSubtitle(String id) {
    final station = _stations[id];
    return station == null ? null : '${station.county} · ${station.town}';
  }

  /// The station's latest observation — for a subclass to read extra fields
  /// (e.g. wind direction) in an overridden [reading].
  @protected
  WeatherObservation? observationOf(String id) => _observations[id];

  @override
  String? reading(String id) {
    final observation = _observations[id];
    if (observation == null) return null;
    final value = valueOf(observation);
    return value == null ? null : '${value.toStringAsFixed(decimals)} $unit';
  }

  @override
  Future<Result<TrendSeries>> trend(String id, String range) async {
    final result = await _repository.trend(id, range: range);
    return result.map((t) => TrendSeries(times: t.times, values: trendOf(t)));
  }

  @override
  void close() => _selected.value = null;

  // --- internals ---

  Future<void> _ensureData() async {
    if (_loaded) return;
    final stations = (await _repository.stations()).valueOrNull;
    final snapshot = (await _repository.latest()).valueOrNull;
    if (stations != null) _stations = stations;
    if (snapshot != null) {
      _observations = {for (final o in snapshot.stations) o.id: o};
    }
    _loaded = stations != null && snapshot != null;
  }

  Map<String, dynamic> _geoJson() {
    final features = <Map<String, dynamic>>[];
    for (final entry in _stations.entries) {
      final observation = _observations[entry.key];
      if (observation == null) continue;
      final value = valueOf(observation);
      if (value == null) continue;
      final station = entry.value;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [station.longitude, station.latitude],
        },
        'properties': {
          'id': entry.key,
          'value': value,
          // Preformatted here (name from data, value + unit from the layer) so
          // the SymbolLayer just reads one `label` string — keeps CJK out of any
          // hardcoded literal and the l10n gate clean.
          'label': '${station.name}\n${value.toStringAsFixed(decimals)} $unit',
          ...extraProperties(observation),
        },
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  List<Object> _colorExpression() => <Object>[
    'interpolate',
    <Object>['linear'],
    <Object>['get', 'value'],
    for (final (at, color) in colorStops) ...[at, color],
  ];

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    // Layers must go before their source; tolerate any that aren't on the map.
    for (final layerId in [_circleId, _labelId, ...extraLayerIds]) {
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
}
