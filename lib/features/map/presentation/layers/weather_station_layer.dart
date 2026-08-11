/// Base for the station-value map layers (temperature, humidity, pressure,
/// wind, rain): station dots coloured by value, tap → trend sheet.
///
/// Generic over the snapshot/observation/trend types so the weather family and
/// the rainfall layer share one implementation; concrete layers supply only
/// which value to read ([valueOf], [trendOf]), the unit, and the colour ramp.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/geo/geo_math.dart';
import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:dpip/features/weather/domain/station_value_repository.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A sheet-driven [MapLayer]: renders every station as a dot coloured by its
/// current value (a MapLibre `interpolate` on the `value` property), and a tap
/// selects the nearest station, opening the shared [StationSheet] with its
/// reading and 24h/7d trend chart.
abstract class WeatherStationLayer<
  S extends StationSnapshot<O>,
  O extends StationObservation,
  T extends TrendTimeAxis
>
    with MapLayerDefaults
    implements MapLayer, StationSheetSource {
  WeatherStationLayer(this._repository);

  final StationValueRepository<S, T> _repository;

  /// The observation value this layer plots, or null if missing for a station.
  double? valueOf(O observation);

  /// The matching series from a station's trend payload.
  List<double?> trendOf(T trend);

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
  Map<String, Object?> extraProperties(O observation) => const {};

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

  /// Optional MapLibre filter for the dot + label layers — e.g. rain hides
  /// dry stations until the map is zoomed in.
  @protected
  List<Object>? get featureFilter => null;

  /// Whether a station with [value] is a tap target at [zoom] — e.g. rain
  /// ignores ~0 readings when zoomed out.
  @protected
  bool includeInSelection(O observation, double value, double zoom) => true;

  /// Optional listenable whose change rebuilds the sheet + legend chrome
  /// (rain listens to its accumulation-window switch).
  @protected
  Listenable? get chromeListenable => null;

  /// Optional header rendered above the colour scale in the legend.
  @protected
  Widget? legendHeader(BuildContext context) => null;

  final ValueNotifier<String?> _selected = ValueNotifier<String?>(null);

  /// Bumped on every tap that (re-)selects a station — even the same one — so the
  /// sheet can pop back up after the user collapsed it (a same-value [_selected]
  /// wouldn't notify on its own).
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);
  Map<String, WeatherStation> _stations = const {};
  Map<String, O> _observations = const {};
  bool _loaded = false;
  MapLibreMapController? _controller;

  /// The controller from the last [render], for a subclass to poke the map
  /// (e.g. rain's window switch re-pushes the source).
  @protected
  MapLibreMapController? get controller => _controller;

  String get _sourceId => 'wx-$id-src';
  String get _circleId => 'wx-$id-circle';
  String get _labelId => 'wx-$id-label';

  /// The source id this layer's dots + labels live on.
  @protected
  String get sourceId => _sourceId;

  /// The current dot/label GeoJSON, re-pushable by a subclass that mutates its
  /// value source in place (e.g. rain's accumulation-window switch).
  @protected
  Map<String, dynamic> get geoJson => _geoJson();

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => StationSheet.peekExtent;

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
        filter: featureFilter,
        enableInteraction: false,
      );
    }
    // Name over reading, pinned under the dot and de-collided by the engine
    // (see [stationLabelProps]).
    await controller.addSymbolLayer(
      _sourceId,
      _labelId,
      stationLabelProps(textField: const <Object>['get', 'label']),
      minzoom: 9,
      filter: featureFilter,
      enableInteraction: false,
    );
    _controller = controller;
    // Let a subclass add its own symbology (e.g. wind arrows) on the source.
    await decorate(controller, _sourceId);
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    // Nearest station within ~0.18° (lon scaled by latitude), so a tap in empty
    // sea doesn't select anything.
    const threshold = 0.18 * 0.18;
    final cosLat = math.cos(degToRad(latLng.latitude));
    final zoom = controller.cameraPosition?.zoom ?? 0;
    String? best;
    var bestDistance = threshold;
    for (final entry in _stations.entries) {
      final observation = _observations[entry.key];
      if (observation == null) continue;
      final value = valueOf(observation);
      if (value == null || !includeInSelection(observation, value, zoom)) {
        continue;
      }
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
  Widget buildSheet(BuildContext context) {
    final sheet = StationSheet(key: ValueKey(id), source: this);
    final listenable = chromeListenable;
    return listenable == null
        ? sheet
        : ListenableBuilder(listenable: listenable, builder: (_, _) => sheet);
  }

  /// Colour scale from [colorStops] + [unit], with an optional [legendHeader].
  @override
  Widget buildLegend(BuildContext context) {
    final header = legendHeader(context);
    final scale = ColorScaleLegend(stops: colorStops, unit: unit);
    final child = header == null
        ? scale
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              header,
              const SizedBox(height: AppSpacing.xs),
              scale,
            ],
          );
    final card = MapLegendCard(child: child);
    final listenable = chromeListenable;
    return listenable == null
        ? card
        : ListenableBuilder(listenable: listenable, builder: (_, _) => card);
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    await _removeFromMap(controller);
    _controller = null;
    _selected.value = null;
  }

  @override
  void selectFeature(String id) => select(id);

  @override
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
  O? observationOf(String id) => _observations[id];

  @override
  Color? valueColor(String id) {
    final observation = observationOf(id);
    final value = observation == null ? null : valueOf(observation);
    return value == null ? null : rampColor(colorStops, value);
  }

  @override
  String? reading(String id) {
    final observation = _observations[id];
    if (observation == null) return null;
    final value = valueOf(observation);
    return value == null ? null : '${value.toStringAsFixed(decimals)} $unit';
  }

  @override
  Widget? readingIcon(String id) => null;

  @override
  double? get chartMinY => null;

  @override
  double? get chartMaxY => null;

  @override
  bool get chartBars => false;

  @override
  Future<Result<TrendSeries>> trend(String id, String range) async {
    final result = await _repository.trend(id, range: range);
    return result.map(seriesOf);
  }

  /// Builds the sheet's trend payload from a decoded trend. Wind overrides to
  /// attach the parallel direction series.
  @protected
  TrendSeries seriesOf(T trend) =>
      TrendSeries(times: trend.times, values: trendOf(trend));

  @override
  void close() => _selected.value = null;

  @override
  void select(String id) {
    _selected.value = id;
    _selectionRevision.value++;
  }

  // --- internals ---

  Future<void> _ensureData() async {
    if (_loaded) return;
    final stations = (await _repository.stations()).valueOrNull;
    final snapshot = (await _repository.latest()).valueOrNull;
    if (stations != null) _stations = stations;
    if (snapshot != null) _observations = observationsOf(snapshot);
    _loaded = stations != null && snapshot != null;
  }

  /// Latest snapshot → per-station observations keyed by station id.
  @protected
  Map<String, O> observationsOf(S snapshot) => {
    for (final o in snapshot.stations) o.id: o,
  };

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
          // Preformatted here (name from data, reading from the layer) so the
          // symbol layer reads one string — keeps CJK out of any hardcoded
          // literal and the l10n gate clean.
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
