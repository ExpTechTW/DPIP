/// The rainfall station layer — dots coloured by accumulation (mm) over a
/// selectable window (`now` / `10m` / `1h` / …), tap → trend sheet.
library;

import 'dart:math' as math;

import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/widgets/station_sheet.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/rain_interval.dart';
import 'package:dpip/features/weather/domain/rain_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Localised labels for [RainInterval] (domain stays Flutter-free).
extension RainIntervalL10n on RainInterval {
  String label(AppLocalizations l10n) => switch (this) {
    RainInterval.now => l10n.rainIntervalNow,
    RainInterval.min10 => l10n.rainInterval10m,
    RainInterval.hour1 => l10n.rainInterval1h,
    RainInterval.hour3 => l10n.rainInterval3h,
    RainInterval.hour6 => l10n.rainInterval6h,
    RainInterval.hour12 => l10n.rainInterval12h,
    RainInterval.hour24 => l10n.rainInterval24h,
    RainInterval.day2 => l10n.rainInterval2d,
    RainInterval.day3 => l10n.rainInterval3d,
  };
}

class RainMapLayer implements MapLayer, StationSheetSource {
  RainMapLayer(this._repository);

  final MeteorRainRepository _repository;

  /// Selected accumulation window — default matches legacy (`now` = 今日).
  final ValueNotifier<RainInterval> interval = ValueNotifier(RainInterval.now);

  final ValueNotifier<String?> _selected = ValueNotifier<String?>(null);
  final ValueNotifier<int> _selectionRevision = ValueNotifier<int>(0);

  Map<String, WeatherStation> _stations = const {};
  Map<String, RainObservation> _observations = const {};
  bool _loaded = false;
  MapLibreMapController? _controller;

  String get _sourceId => 'rain-src';
  String get _circleId => 'rain-circle';

  String get _labelId => 'rain-label';

  @override
  String get id => 'rain';

  @override
  IconData get icon => Icons.umbrella_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerRain;

  @override
  String get unit => 'mm';

  @override
  double? get chartMinY => 0;

  @override
  double? get chartMaxY => null;

  @override
  bool get chartBars => true;

  /// Legacy precipitation colour ramp (mm).
  List<(double, String)> get colorStops => const [
    (0, '#c2c2c2'),
    (10, '#9cfcff'),
    (30, '#059bff'),
    (50, '#39ff03'),
    (100, '#fffb03'),
    (200, '#ff9500'),
    (300, '#ff0000'),
    (500, '#fb00ff'),
    (1000, '#960099'),
    (2000, '#000000'),
  ];

  static const int _decimals = 1;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => StationSheet.peekExtent;

  @override
  double get mapMinZoom => 4;

  @override
  double get mapMaxZoom => BaseMap.maxZoom;

  @override
  Future<Result<List<MapFrame>>> frames() async => const Ok([]);

  @override
  Future<void> prepare(MapLibreMapController c, List<MapFrame> frames) async {}

  @override
  Future<void> show(
    MapLibreMapController c,
    MapFrame frame, {
    bool scrubbing = false,
  }) async {}

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    await _ensureData();
    await _removeFromMap(controller);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: _geoJson()),
    );
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
      // Dry stations (0 mm) clutter the island at overview; reveal past z8.
      filter: _visibleFilter,
      enableInteraction: false,
    );
    // Name over reading, pinned under the dot and de-collided by the engine
    // (see [stationLabelProps]).
    await controller.addSymbolLayer(
      _sourceId,
      _labelId,
      stationLabelProps(textField: const <Object>['get', 'label']),
      minzoom: 9,
      filter: _visibleFilter,
      enableInteraction: false,
    );
  }

  /// Non-zero always; zero-mm only when zoomed in past 8.
  static const List<Object> _visibleFilter = [
    'any',
    <Object>[
      '>',
      <Object>['get', 'value'],
      0,
    ],
    <Object>[
      '>',
      <Object>['zoom'],
      8,
    ],
  ];

  /// Switches the accumulation window and refreshes dots + labels in place.
  Future<void> setInterval(RainInterval next) async {
    if (interval.value == next) return;
    interval.value = next;
    final controller = _controller;
    if (controller != null) {
      try {
        await controller.setGeoJsonSource(_sourceId, _geoJson());
      } catch (_) {
        // Source gone (layer torn down) — next [render] rebuilds it.
      }
    }
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    const threshold = 0.18 * 0.18;
    final cosLat = math.cos(latLng.latitude * math.pi / 180);
    final window = interval.value;
    final zoom = controller.cameraPosition?.zoom ?? 0;
    final showZero = zoom > 8;
    String? best;
    var bestDistance = threshold;
    for (final entry in _stations.entries) {
      final observation = _observations[entry.key];
      final value = observation == null ? null : window.valueOf(observation);
      if (value == null) continue;
      if (value <= 0 && !showZero) continue;
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
  Widget buildTopTrailingChrome(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: interval,
      builder: (context, _) {
        final current = interval.value;
        return MenuAnchor(
          builder: (context, controller, child) {
            return IconButton.filledTonal(
              tooltip: l10n.rainIntervalMenu,
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              icon: Icon(
                Icons.timelapse_outlined,
                color: colors.onSecondaryContainer,
              ),
            );
          },
          menuChildren: [
            for (final option in RainInterval.values)
              MenuItemButton(
                onPressed: () => setInterval(option),
                trailingIcon: option == current
                    ? Icon(Icons.check, size: 18, color: colors.primary)
                    : null,
                child: Text(option.label(l10n)),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget buildMapOverlay(BuildContext context) => const SizedBox.shrink();

  @override
  void onMapGestureStart() {}

  @override
  void onMapGestureEnd() {}

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) async {}

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) async {}

  @override
  Widget buildSheet(BuildContext context) => ListenableBuilder(
    listenable: interval,
    builder: (context, _) => StationSheet(key: ValueKey(id), source: this),
  );

  @override
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: interval,
      builder: (context, _) => MapLegendCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              interval.value.label(l10n),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            ColorScaleLegend(stops: colorStops, unit: unit, appendUnit: true),
          ],
        ),
      ),
    );
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
  void onStyleReset() {}

  @override
  ValueListenable<String?> get selection => _selected;

  @override
  ValueListenable<int> get selectionRevision => _selectionRevision;

  @override
  String title(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return '${l10n.mapLayerRain} · ${interval.value.label(l10n)}';
  }

  @override
  String stationName(String id) => _stations[id]?.name ?? id;

  @override
  String? stationSubtitle(String id) {
    final station = _stations[id];
    return station == null ? null : '${station.county} · ${station.town}';
  }

  @override
  Color? valueColor(String id) {
    final observation = _observations[id];
    final value = observation == null
        ? null
        : interval.value.valueOf(observation);
    return value == null ? null : _rampColor(value);
  }

  @override
  String? reading(String id) {
    final observation = _observations[id];
    if (observation == null) return null;
    final value = interval.value.valueOf(observation);
    return value == null ? null : '${value.toStringAsFixed(_decimals)} $unit';
  }

  @override
  Future<Result<TrendSeries>> trend(String id, String range) async {
    final result = await _repository.trend(id, range: range);
    return result.map((t) => TrendSeries(times: t.times, values: t.rain));
  }

  @override
  void close() => _selected.value = null;

  @override
  void select(String id) {
    _selected.value = id;
    _selectionRevision.value++;
  }

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
    final window = interval.value;
    final features = <Map<String, dynamic>>[];
    for (final entry in _stations.entries) {
      final observation = _observations[entry.key];
      if (observation == null) continue;
      final value = window.valueOf(observation);
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
          'label': '${station.name}\n${value.toStringAsFixed(_decimals)} $unit',
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

  Color? _rampColor(double value) {
    final stops = colorStops;
    if (stops.isEmpty) return null;
    if (value <= stops.first.$1) return colorFromHexRgb(stops.first.$2);
    if (value >= stops.last.$1) return colorFromHexRgb(stops.last.$2);
    for (var i = 0; i < stops.length - 1; i++) {
      final (lowAt, lowHex) = stops[i];
      final (highAt, highHex) = stops[i + 1];
      if (value < lowAt || value > highAt) continue;
      final low = colorFromHexRgb(lowHex);
      final high = colorFromHexRgb(highHex);
      if (low == null || high == null) return low ?? high;
      final span = highAt - lowAt;
      return Color.lerp(low, high, span == 0 ? 0 : (value - lowAt) / span);
    }
    return colorFromHexRgb(stops.last.$2);
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
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
}
