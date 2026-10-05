/// CWA tsunami bulletin map layer: the source epicentre and every observed
/// coastal reading, banded by wave height, with the bulletin itself in a sheet.
library;

import 'dart:async';

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/widgets/tsunami_panel.dart';
import 'package:dpip/features/tsunami/domain/tsunami_report.dart';
import 'package:dpip/features/tsunami/domain/tsunami_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_station_labels.dart';
import 'package:dpip/shared/seismic/intensity_icon_renderer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A sheet layer: one event, no frames and no timeline.
///
/// The map carries the two things a map is for — where the earthquake was, and
/// where the wave was measured — while the sheet carries the bulletin text and
/// the per-area heights.
///
/// **Predicted coasts.** As in the legacy page, the base style's own `tsunami`
/// vector layer (CWA's coast, one line per forecast region, keyed by
/// `AREANAME`) is recoloured by predicted height and blinked.
class TsunamiMapLayer with MapLayerDefaults implements MapLayer {
  TsunamiMapLayer(this.repository);

  /// Exposed so the sheet's retry and its report picker can drive the fetch
  /// they render.
  final TsunamiRepository repository;

  /// Latest fetch. `null` is "nothing fetched yet" (the panel shows its
  /// loading state and the map is empty); `Ok(null)` is **CWA has issued
  /// nothing** — an all-clear, which is not a failure and must not be shown as
  /// one; `Ok(report)` is the picked bulletin; `Err` is a failed fetch.
  final ValueNotifier<Result<TsunamiReport?>?> state = ValueNotifier(null);

  /// The newest event's reports, newest first — the sheet's 第N報 picker.
  final ValueNotifier<List<TsunamiBulletin>> bulletins = ValueNotifier(
    const [],
  );

  /// The report currently shown, or null when there is none to show. A notifier
  /// rather than a plain field because the picker's pills read it.
  final ValueNotifier<String?> selectedId = ValueNotifier(null);

  /// The bulletin currently on the map, or null.
  TsunamiReport? get report => state.value?.valueOrNull;

  /// Wire id, also the id a notification tap asks the map for
  /// (`notificationChannelMapLayers`).
  static const String layerId = 'tsunami';

  static const String _sourceId = 'tsunami-source';
  static const String _epicenterLayerId = 'tsunami-epicenter';
  static const String _epicenterIconId = 'tsunami-epicenter-icon';
  static const String _observationLayerId = 'tsunami-observations';
  static const String _labelLayerId = 'tsunami-labels';

  /// The base style's vector source and the layer in its tiles.
  static const String _areaSourceId = 'exptech';
  static const String _areaSourceLayer = 'tsunami';
  static const String _areaLayerId = 'tsunami-areas';

  /// The legacy cadence: a half-second tick, line shown for six ticks of eight.
  static const Duration _blinkTick = Duration(milliseconds: 500);
  static const int _blinkCycle = 8;
  static const int _blinkVisible = 6;

  /// The legacy palette, kept because CWA's own bands did not change: over 3 m
  /// is the alert colour, under 30 cm the quiet one. Getters rather than
  /// `static const` because the colour-vision transform is not a compile-time
  /// constant; the legend's swatches convert these same strings, so key and map
  /// cannot drift.
  static String get bandOver3mColor => '#E543FF'.vision;
  static String get bandFrom1mColor => '#C90000'.vision;
  static String get bandFrom30cmColor => '#FFC900'.vision;
  static String get bandUnder30cmColor => '#00AAFF'.vision;

  /// A reading the height text would not parse. Neutral on purpose: it is not a
  /// band, and painting it the quiet blue would state a wave height CWA never
  /// reported.
  static String get _unknownBandColor => '#9E9E9E'.vision;

  static String get _strokeColor => '#FFFFFF'.vision;

  MapLibreMapController? _controller;

  /// Serial op lane, the same shape [DisasterMapLayer] uses: two report pills
  /// tapped in quick succession must not interleave their `setGeoJsonSource`
  /// calls, and the last tap wins because the fetch reads [_selectedId] when it
  /// starts rather than when it was queued.
  Future<void> _ops = Future<void>.value();

  @override
  String get id => layerId;

  @override
  IconData get icon => Icons.tsunami_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerTsunami;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => TsunamiPanel.peekExtent;

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    await load();
  }

  /// Loads the event's report list and shows its newest report. Called on
  /// activation and by the sheet's retry button.
  Future<void> load() => _enqueue(_loadIndex);

  /// Shows another report of the same event — the sheet's 第N報 picker.
  Future<void> selectBulletin(String id) {
    selectedId.value = id;
    return _enqueue(_loadSelected);
  }

  Future<void> _loadIndex() async {
    final result = await repository.bulletins();
    final list = result.valueOrNull;
    if (list == null) {
      bulletins.value = const [];
      state.value = Err(result.failureOrNull!);
      return;
    }
    bulletins.value = list;
    if (list.isEmpty) {
      selectedId.value = null;
      state.value = const Ok(null);
      return;
    }
    // A reload (a style rebuild, a retry) keeps the report the user picked when
    // it is still part of the event; only a report that is gone falls back to
    // the newest, so a refresh mid-event never yanks the reader back to 最新報.
    final keep = list.any((bulletin) => bulletin.id == selectedId.value)
        ? selectedId.value!
        : list.first.id;
    selectedId.value = keep;
    await _loadSelected();
  }

  Future<void> _loadSelected() async {
    final id = selectedId.value;
    if (id == null) return;
    final result = await repository.report(id);
    // A newer tap landed while this fetch was in the air — its own run is
    // queued behind this one and will win; showing this result first would only
    // flash the wrong bulletin.
    if (id != selectedId.value) return;
    state.value = result;
    final controller = _controller;
    if (controller == null) return;
    await _draw(controller, result.valueOrNull);
  }

  Future<void> _draw(
    MapLibreMapController controller,
    TsunamiReport? report,
  ) async {
    await _remove(controller);
    // `Ok(null)` — CWA has issued nothing, so there is nothing to draw and the
    // map simply has no overlay.
    if (report == null) return;
    // The epicentre cross is drawn in code, like every other map icon, and the
    // legacy tsunami page used this same artwork for the same purpose.
    await controller.addImage(
      _epicenterIconId,
      await IntensityIconRenderer.render('cross'),
    );
    // Underneath the points, so a station dot is never hidden by the coast.
    await _drawAreas(controller, report);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: tsunamiGeoJson(report)),
    );
    await controller.addCircleLayer(
      _sourceId,
      _observationLayerId,
      CircleLayerProperties(
        circleRadius: const [
          Expressions.interpolate,
          ['linear'],
          [Expressions.zoom],
          6,
          5.0,
          12,
          9.0,
        ],
        circleColor: _bandColorExpression(),
        circleStrokeColor: _strokeColor,
        circleStrokeWidth: 1.5,
      ),
      filter: _kindIs(_observationKind),
      enableInteraction: false,
    );
    // Readings only appear once the map is close enough to attribute a label to
    // the dot it belongs to; nationwide view is the distribution.
    await controller.addSymbolLayer(
      _sourceId,
      _labelLayerId,
      stationLabelProps(textField: const ['get', 'label']),
      filter: _kindIs(_observationKind),
      minzoom: 7,
      enableInteraction: false,
    );
    await controller.addSymbolLayer(
      _sourceId,
      _epicenterLayerId,
      SymbolLayerProperties(
        iconImage: _epicenterIconId,
        iconSize: 1,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      filter: _kindIs(_epicenterKind),
      enableInteraction: false,
    );
  }

  Timer? _blink;
  int _blinkStep = 0;

  /// Paints each predicted region's coast in its warning band, blinking.
  ///
  /// A region the asset does not know, or one whose colour has no band, is
  /// simply not drawn — it is logged, because CWA adding a region is the one
  /// way this goes quietly out of date.
  Future<void> _drawAreas(
    MapLibreMapController controller,
    TsunamiReport report,
  ) async {
    final bands = tsunamiAreaBands(report);
    if (bands.isEmpty) return;
    // The base style's own vector source: its `tsunami` layer is CWA's coast,
    // one line per forecast region, named by `AREANAME`.
    await controller.addLineLayer(
      _areaSourceId,
      _areaLayerId,
      LineLayerProperties(
        lineColor: _areaColorExpression(bands),
        lineWidth: 10,
        lineOpacity: 1,
      ),
      sourceLayer: _areaSourceLayer,
      enableInteraction: false,
    );
    _startBlink(bands);
  }

  /// A `match` on the `area` property, as the legacy `AREANAME` one was.
  List<Object> _areaColorExpression(Map<String, TsunamiWaveBand> bands) => [
    Expressions.match,
    [Expressions.get, 'AREANAME'],
    for (final entry in bands.entries) ...[entry.key, bandColor(entry.value)],
    '#000000',
  ];

  void _startBlink(Map<String, TsunamiWaveBand> bands) {
    _blink?.cancel();
    _blinkStep = 0;
    // Colour, width and opacity every tick, as the legacy page re-sent its
    // colour with each opacity: a partial update is not guaranteed to leave the
    // properties it omits alone, and a line reset to defaults reads as gone.
    final color = _areaColorExpression(bands);
    var reported = false;
    _blink = Timer.periodic(_blinkTick, (_) {
      _blinkStep = (_blinkStep + 1) % _blinkCycle;
      final controller = _controller;
      if (controller == null) return;
      controller
          .setLayerProperties(
            _areaLayerId,
            LineLayerProperties(
              lineColor: color,
              lineWidth: 10,
              lineOpacity: _blinkStep < _blinkVisible ? 1 : 0,
            ),
          )
          .catchError((Object error, StackTrace stackTrace) {
            // Once per layer, not once per tick.
            if (reported) return;
            reported = true;
            Log.handle(error, stackTrace, 'tsunami area blink');
          });
    });
  }

  Future<void> _removeAreas(MapLibreMapController controller) async {
    _blink?.cancel();
    _blink = null;
    try {
      await controller.removeLayer(_areaLayerId);
    } catch (_) {
      // Already absent — the style may have been replaced under us.
    }
  }

  /// A `match` on each feature's band name, defaulting to the neutral colour.
  List<Object> _bandColorExpression() => [
    Expressions.match,
    [Expressions.get, 'band'],
    TsunamiWaveBand.over3m.name,
    bandOver3mColor,
    TsunamiWaveBand.from1m.name,
    bandFrom1mColor,
    TsunamiWaveBand.from30cm.name,
    bandFrom30cmColor,
    TsunamiWaveBand.under30cm.name,
    bandUnder30cmColor,
    _unknownBandColor,
  ];

  /// The band palette, for the legend and the sheet's chips.
  static String bandColor(TsunamiWaveBand band) => switch (band) {
    TsunamiWaveBand.over3m => bandOver3mColor,
    TsunamiWaveBand.from1m => bandFrom1mColor,
    TsunamiWaveBand.from30cm => bandFrom30cmColor,
    TsunamiWaveBand.under30cm => bandUnder30cmColor,
  };

  @override
  Widget buildSheet(BuildContext context) => TsunamiPanel(layer: this);

  /// The height scale, plus the epicentre mark.
  ///
  /// The four rows are the point of the layer: without them the colours on the
  /// map are decoration. The epicentre keeps a row because a cross is not
  /// obviously an earthquake to somebody who has never seen one.
  @override
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MapLegendCard(
      child: SymbolLegend(
        items: [
          SymbolLegendItem(
            swatch: LegendDot(color: const Color(0xFFE543FF).vision),
            label: l10n.tsunamiBandOver3m,
          ),
          SymbolLegendItem(
            swatch: LegendDot(color: const Color(0xFFC90000).vision),
            label: l10n.tsunamiBand1To3m,
          ),
          SymbolLegendItem(
            swatch: LegendDot(color: const Color(0xFFFFC900).vision),
            label: l10n.tsunamiBand30cmTo1m,
          ),
          SymbolLegendItem(
            swatch: LegendDot(color: const Color(0xFF00AAFF).vision),
            label: l10n.tsunamiBandUnder30cm,
          ),
          SymbolLegendItem(
            swatch: Icon(
              Icons.close,
              size: 13,
              // The epicentre artwork's own red (`IntensityIconRenderer`), so
              // the key names the mark that is actually on the map.
              color: const Color(0xFFFF0000),
            ),
            label: l10n.tsunamiLegendEpicenter,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    await _remove(controller);
    _controller = null;
    state.value = null;
    bulletins.value = const [];
    selectedId.value = null;
  }

  @override
  void onStyleReset() {
    _blink?.cancel();
    _blink = null;
    // The style reload dropped every runtime source and image; the bulletin
    // itself is untouched, and the scaffold's re-render re-adds them. Only the
    // controller is stale.
    _controller = null;
  }

  /// Queues [op] behind any load in flight, logging a failure instead of
  /// throwing it: a failed overlay op degrades the map, and the panel already
  /// has the error to show. Returning the chain (not the op) keeps a caller
  /// from having to handle an error that has nowhere useful to go.
  Future<void> _enqueue(Future<void> Function() op) {
    _ops = _ops.then((_) => op()).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      Log.handle(error, stackTrace, 'tsunami layer op');
    });
    return _ops;
  }

  Future<void> _remove(MapLibreMapController controller) async {
    await _removeAreas(controller);
    for (final id in [_epicenterLayerId, _labelLayerId, _observationLayerId]) {
      try {
        await controller.removeLayer(id);
      } catch (_) {
        // Already absent — the style may have been replaced under us.
      }
    }
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {
      // Same.
    }
  }

  static List<Object> _kindIs(String kind) => <Object>[
    '==',
    <Object>['get', 'kind'],
    kind,
  ];
}

/// The warning band of every predicted region [report] carries, by the region
/// name the bundled coastline is keyed on.
///
/// Pure so it is unit-testable. A prediction whose colour has no band is left
/// out rather than defaulted — see [TsunamiWaveBand.ofWarningColor]. Two rows
/// for one region keep the **higher** band: a coast is as dangerous as its
/// worst forecast.
Map<String, TsunamiWaveBand> tsunamiAreaBands(TsunamiReport report) {
  final bands = <String, TsunamiWaveBand>{};
  for (final prediction in report.predictions) {
    final band = TsunamiWaveBand.ofWarningColor(prediction.color);
    if (band == null) continue;
    final known = bands[prediction.area];
    if (known == null || band.index > known.index) {
      bands[prediction.area] = band;
    }
  }
  return bands;
}

/// GeoJSON property naming which of the two marks a feature is.
const String _epicenterKind = 'epicenter';
const String _observationKind = 'observation';

/// The bulletin as map geometry: the source earthquake, plus every observed
/// station that reported a position.
///
/// Pure (no controller, no widgets) so the shape is unit-testable — and so the
/// one row with `null` coordinates is dropped here, in one place, rather than
/// becoming a `LatLng(null, null)` inside the style.
///
/// Each reading carries its band name in `band` (not a colour), so the circle
/// layer colours every dot by the one scale the legend keys, and a height the
/// text would not parse stays unbanded instead of silently defaulting to a
/// claim about the sea.
Map<String, dynamic> tsunamiGeoJson(TsunamiReport report) => {
  'type': 'FeatureCollection',
  'features': [
    {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [
          report.earthquake.longitude,
          report.earthquake.latitude,
        ],
      },
      'properties': {'kind': _epicenterKind},
    },
    for (final observation in report.observations)
      if (observation.longitude != null && observation.latitude != null)
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [observation.longitude, observation.latitude],
          },
          'properties': {
            'kind': _observationKind,
            if (observedBand(observation) case final band?) 'band': band.name,
            // Name over its reading, the same two-line shape every station
            // label on this map uses (`stationLabelProps`).
            'label': '${observation.name}\n${observation.height}',
          },
        },
  ],
};

/// The wave band an observation's height text reports, or null when it holds no
/// number to place on the scale.
TsunamiWaveBand? observedBand(TsunamiObservation observation) {
  final centimeters = parseObservedCentimeters(observation.height);
  return centimeters == null ? null : TsunamiWaveBand.of(centimeters);
}
