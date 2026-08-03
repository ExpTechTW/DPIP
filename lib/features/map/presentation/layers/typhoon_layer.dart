/// The 颱風 (typhoon) map layer — CWA track / potential / probability / warning
/// plus scrubbable satellite imagery, from the full v5 meteor typhoon surface.
library;

import 'dart:math' as math;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_storm_band.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_weather_overlay.dart';
import 'package:dpip/features/map/presentation/widgets/typhoon_forecast_callouts.dart';
import 'package:dpip/features/map/presentation/widgets/typhoon_overlay_menu.dart';
import 'package:dpip/features/map/presentation/widgets/typhoon_panel.dart';
import 'package:dpip/core/models/lat_lng.dart' as geo;
import 'package:dpip/features/typhoon/domain/closest_frame.dart';
import 'package:dpip/features/typhoon/domain/cyclone_identity.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_intensity.dart';
import 'package:dpip/features/typhoon/domain/typhoon_overlay.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A tappable storm waypoint parsed from the overlay geojson.
typedef _StormPoint = ({
  double lat,
  double lng,
  String? label,
  String? cycloneKey,
  String kind,
});

/// Sheet-type [MapLayer]: renders every typhoon dataset on the map and drives
/// [TyphoonPanel] (summary, warning) via notifiers. Meteor satellite PNG and
/// optional radar/IR underlays are aligned to the live bulletin time.
class TyphoonMapLayer implements MapLayer {
  TyphoonMapLayer(
    this._repository, {
    required this.radar,
    required this.satellite,
  });

  final MeteorTyphoonRepository _repository;
  final RadarRepository radar;
  final SatelliteRepository satellite;

  MapLibreMapController? _controller;
  bool _added = false;
  Future<void> _ops = Future<void>.value();

  final ValueNotifier<TyphoonCyclone?> summary = ValueNotifier(null);
  final ValueNotifier<TrackPayload?> track = ValueNotifier(null);
  final ValueNotifier<TyphoonWarning?> warning = ValueNotifier(null);
  final ValueNotifier<TyphoonProbability?> probability = ValueNotifier(null);
  final ValueNotifier<String?> tapped = ValueNotifier(null);
  final ValueNotifier<int> tapRevision = ValueNotifier(0);

  /// International name of the focused cyclone (nearest to Taiwan by default).
  final ValueNotifier<String?> selectedCycloneKey = ValueNotifier(null);

  /// Strike-probability fill — off by default; mutually exclusive with the cone.
  final ValueNotifier<bool> showProbability = ValueNotifier(false);

  /// Forecast-point Flutter callout cards — on by default (overlay menu).
  final ValueNotifier<bool> showForecastCallouts = ValueNotifier(true);

  /// CAP warning county fills — off by default (opt-in via overlay menu).
  final ValueNotifier<bool> showWarningAreas = ValueNotifier(false);

  /// L7 vs L10 storm-band combo — mutually exclusive; default L7.
  final ValueNotifier<TyphoonStormBand> stormBand = ValueNotifier(
    TyphoonStormBand.level7,
  );

  /// Radar XOR Himawari IR under the vectors — frame ≤ bulletin time.
  final ValueNotifier<TyphoonWeatherOverlay> weatherOverlay = ValueNotifier(
    TyphoonWeatherOverlay.none,
  );

  /// Radar / IR tile ids (Unix seconds), ascending — for bulletin alignment.
  List<int> _radarSecs = const [];
  List<int> _satSecs = const [];

  CycloneIndex? _index;
  TyphoonPotential? _potential;
  Result<Map<String, dynamic>>? _geoResult;
  TyphoonWarning? _rawWarning;

  final List<_StormPoint> _points = [];
  List<String> _warningNames = const [];

  static const String _src = 'typhoon-src';
  static const String _wxSrc = 'typhoon-wx-src';
  static const String _wxLyr = 'typhoon-wx-lyr';
  static const String _warnLyr = 'typhoon-warning-areas';
  static const String _probLyr = 'typhoon-probability';
  static const String _coneLyr = 'typhoon-cone';
  static const String _c15Lyr = 'typhoon-circle15';
  static const String _avg15Lyr = 'typhoon-circle-avg15';
  static const String _c25Lyr = 'typhoon-circle25';
  static const String _avg25Lyr = 'typhoon-circle-avg25';
  static const String _pastLyr = 'typhoon-past';
  static const String _forecastLyr = 'typhoon-forecast';
  static const String _fpointLyr = 'typhoon-fpoint';
  static const String _fpointLabelLyr = 'typhoon-fpoint-label';
  static const String _currentLyr = 'typhoon-current';
  static const String _currentLabelLyr = 'typhoon-current-label';

  static const List<String> _vectorLayers = [
    _warnLyr,
    _probLyr,
    _coneLyr,
    _c15Lyr,
    _avg15Lyr,
    _c25Lyr,
    _avg25Lyr,
    _pastLyr,
    _forecastLyr,
    _fpointLyr,
    _fpointLabelLyr,
    _currentLyr,
    _currentLabelLyr,
  ];

  @override
  String get id => 'typhoon';

  @override
  IconData get icon => Icons.cyclone_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerTyphoon;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => TyphoonPanel.peekExtent;

  /// Basin-wide framing — lower than radar's floor so distant storms fit.
  @override
  double get mapMinZoom => 3;

  @override
  double get mapMaxZoom => BaseMap.maxZoom;

  @override
  String? get bakedAedTileUrl => null;

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
    final results = await Future.wait([
      _repository.geojson(),
      _repository.cyclones(),
      _repository.track(),
      _repository.potential(),
      _repository.probability(),
      _repository.warning(),
      radar.frames(),
      satellite.frames(),
    ]);

    final geoResult = results[0] as Result<Map<String, dynamic>>;
    final indexResult = results[1] as Result<CycloneIndex>;
    final trackResult = results[2] as Result<TrackPayload>;
    final potentialResult = results[3] as Result<TyphoonPotential>;
    final probabilityResult = results[4] as Result<TyphoonProbability>;
    final warningResult = results[5] as Result<TyphoonWarning>;
    final radarResult = results[6] as Result<List<String>>;
    final satResult = results[7] as Result<List<String>>;

    final trackPayload = trackResult.valueOrNull;
    final probability = probabilityResult.valueOrNull;
    final warning = warningResult.valueOrNull;
    final index = indexResult.valueOrNull;
    _radarSecs = _ascendingSecs(radarResult.valueOrNull);
    _satSecs = _ascendingSecs(satResult.valueOrNull);

    _index = index;
    _potential = potentialResult.valueOrNull;
    _geoResult = geoResult;
    _rawWarning = warning;
    track.value = trackPayload;
    this.probability.value = probability;

    final nearest = index == null || index.cyclones.isEmpty
        ? -1
        : indexOfNearestCyclone(
            index.cyclones,
            origin: const geo.LatLng(23.7, 121.0),
          );
    final key = nearest >= 0 ? cycloneKey(index!.cyclones[nearest]) : null;
    selectedCycloneKey.value = key;
    _applySelection(key);

    final overlay = _buildLiveGeo();
    _parsePoints(overlay);

    await _removeFromMap(controller);
    await _addWarningAreas(controller, _warningNames);
    await _addVectorOverlay(controller, overlay);
    await _syncWeatherOverlay(controller);
    _added = true;
  }

  /// Bulletin clock for weather-tile alignment (always the live report).
  int? get bulletinSecond => track.value?.updated ?? summary.value?.time;

  int? get _bulletinSecond => bulletinSecond;

  /// Warning only when CAP typhoon name matches the focused storm.
  TyphoonWarning? get matchedWarning {
    final w = warning.value;
    final s = summary.value;
    if (w == null || s == null) return null;
    return warningAppliesTo(w, name: s.name, cwaName: s.cwaName) ? w : null;
  }

  /// Focus another active cyclone (map tap on its centre).
  void selectCyclone(String key) {
    if (selectedCycloneKey.value == key) {
      tapRevision.value++;
      return;
    }
    selectedCycloneKey.value = key;
    _applySelection(key);
    clearForecastSelection();
    tapRevision.value++;
    final controller = _controller;
    if (controller == null || !_added) return;
    _queue(() async {
      final geo = _buildLiveGeo();
      _parsePoints(geo);
      await _addWarningAreas(controller, _warningNames);
      await controller.setGeoJsonSource(_src, geo);
      await _syncWeatherOverlay(controller);
    });
  }

  /// Clears the sheet's tapped-forecast highlight.
  void clearForecastSelection() {
    tapped.value = null;
  }

  /// Hide Flutter forecast chips while the finger is down / camera is moving.
  final ValueNotifier<bool> suppressCallouts = ValueNotifier(false);

  @override
  void onMapGestureStart() => suppressCallouts.value = true;

  @override
  void onMapGestureEnd() => suppressCallouts.value = false;

  @override
  Future<void> onCameraIdle(MapLibreMapController controller) async {}

  @override
  Future<void> onAmbientCacheCleared(MapLibreMapController controller) async {}

  /// Active MapLibre controller (for Flutter screen-space callouts).
  MapLibreMapController? get mapController => _controller;

  /// Forecast fixes for the focused cyclone (Flutter callout source).
  List<TrackForecast> get selectedForecasts =>
      _selectedTrack?.forecast ?? const [];

  void _applySelection(String? key) {
    summary.value =
        cycloneForKey(_index, key) ??
        () {
          final t = trackForKey(track.value, key);
          if (t == null || t.analysis.isEmpty) return null;
          final last = t.analysis.last;
          return TyphoonCyclone(
            name: t.name,
            cwaName: t.cwaName,
            year: t.year,
            tdNo: t.tdNo,
            tyNo: t.tyNo,
            time: last.time,
            latitude: last.latitude,
            longitude: last.longitude,
            wind: last.wind,
            gust: last.gust,
            pressure: last.pressure,
            speed: t.now?.speed,
            direction: t.now?.direction,
          );
        }();
    final w = _rawWarning;
    final s = summary.value;
    if (w != null &&
        s != null &&
        warningAppliesTo(w, name: s.name, cwaName: s.cwaName)) {
      warning.value = w;
      _warningNames = [for (final a in w.areas) a.name];
    } else {
      warning.value = null;
      _warningNames = const [];
    }
  }

  TyphoonTrack? get _selectedTrack =>
      trackForKey(track.value, selectedCycloneKey.value);

  List<TyphoonCyclone> get _cyclones =>
      _index?.cyclones ?? const <TyphoonCyclone>[];

  Map<String, dynamic> _buildLiveGeo() {
    return _liveOverlay(
      geoResult:
          _geoResult ??
          const Ok(<String, dynamic>{
            'type': 'FeatureCollection',
            'features': <dynamic>[],
          }),
      potential: _potential,
      probability: probability.value,
      selected: _selectedTrack,
      cyclones: _cyclones,
    );
  }

  Map<String, dynamic> _liveOverlay({
    required Result<Map<String, dynamic>> geoResult,
    required TyphoonPotential? potential,
    required TyphoonProbability? probability,
    required TyphoonTrack? selected,
    required List<TyphoonCyclone> cyclones,
  }) {
    final server = geoResult.valueOrNull;
    if (server != null && server['features'] is List) {
      return augmentTyphoonGeojson(
        server,
        selected: selected,
        cyclones: cyclones,
      );
    }
    if (potential != null && probability != null) {
      return typhoonFeatureCollection(
        potential: potential,
        probability: probability,
        selected: selected,
        cyclones: cyclones,
      );
    }
    return emptyTyphoonFeatureCollection;
  }

  Future<void> _addVectorOverlay(
    MapLibreMapController controller,
    Map<String, dynamic> geo,
  ) async {
    await controller.addSource(_src, GeojsonSourceProperties(data: geo));
    // Defaults: hollow cone + storm circles. Probability / warning are opt-in
    // (and probability hides the cone — see [setShowProbability]).
    final showProb = showProbability.value;
    await controller.addFillLayer(
      _src,
      _probLyr,
      FillLayerProperties(
        fillColor: const [
          'match',
          ['get', 'p'],
          100,
          'rgba(183, 28, 28, 0.40)',
          80,
          'rgba(211, 47, 47, 0.32)',
          60,
          'rgba(239, 83, 80, 0.26)',
          40,
          'rgba(255, 138, 101, 0.20)',
          20,
          'rgba(255, 183, 77, 0.16)',
          'rgba(255, 183, 77, 0.12)',
        ],
        fillOutlineColor: 'rgba(183, 28, 28, 0.55)',
        visibility: showProb ? 'visible' : 'none',
      ),
      filter: _kindIs('probability'),
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
    await controller.addFillLayer(
      _src,
      _coneLyr,
      FillLayerProperties(
        // Hollow outline — fill fully transparent so track/radar stay readable.
        fillColor: 'rgba(255,82,82,0)',
        fillOutlineColor: 'rgba(255,82,82,0.85)',
        visibility: showProb ? 'none' : 'visible',
      ),
      filter: _kindIs('cone'),
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
    // L7 purple fill+dashed avg ↔ L10 yellow fill+dashed avg (mutex via
    // [stormBand] visibility).
    final showL7 = stormBand.value == TyphoonStormBand.level7;
    await controller.addFillLayer(
      _src,
      _c15Lyr,
      FillLayerProperties(
        fillColor: 'rgba(156, 39, 176, 0.16)',
        fillOutlineColor: 'rgba(123, 31, 162, 0.9)',
        visibility: showL7 ? 'visible' : 'none',
      ),
      filter: _kindIs('circle15'),
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
    await controller.addLineLayer(
      _src,
      _avg15Lyr,
      LineLayerProperties(
        lineColor: '#9C27B0',
        lineWidth: 2,
        lineDasharray: const [2, 1.5],
        lineCap: 'butt',
        lineJoin: 'miter',
        visibility: showL7 ? 'visible' : 'none',
      ),
      filter: _kindIs('circleAvg15'),
      enableInteraction: false,
    );
    await controller.addFillLayer(
      _src,
      _c25Lyr,
      FillLayerProperties(
        fillColor: 'rgba(255, 193, 7, 0.16)',
        fillOutlineColor: 'rgba(255, 160, 0, 0.9)',
        visibility: showL7 ? 'none' : 'visible',
      ),
      filter: _kindIs('circle25'),
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
    await controller.addLineLayer(
      _src,
      _avg25Lyr,
      LineLayerProperties(
        lineColor: '#FFC107',
        lineWidth: 2,
        lineDasharray: const [2, 1.5],
        lineCap: 'butt',
        lineJoin: 'miter',
        visibility: showL7 ? 'none' : 'visible',
      ),
      filter: _kindIs('circleAvg25'),
      enableInteraction: false,
    );
    await controller.addLineLayer(
      _src,
      _pastLyr,
      LineLayerProperties(
        // CWA intensity on each segment (`properties.intensity`).
        lineColor: <Object>[
          'match',
          <Object>['get', 'intensity'],
          TyphoonIntensity.td.wire,
          TyphoonIntensity.td.colorHex,
          TyphoonIntensity.mild.wire,
          TyphoonIntensity.mild.colorHex,
          TyphoonIntensity.moderate.wire,
          TyphoonIntensity.moderate.colorHex,
          TyphoonIntensity.intense.wire,
          TyphoonIntensity.intense.colorHex,
          '#B0BEC5',
        ],
        lineWidth: 3,
        lineCap: 'round',
        lineJoin: 'round',
      ),
      filter: _kindIs('past'),
      enableInteraction: false,
    );
    await controller.addLineLayer(
      _src,
      _forecastLyr,
      const LineLayerProperties(
        lineColor: '#EF5350',
        lineWidth: 3,
        lineDasharray: [2, 1.5],
        lineCap: 'round',
      ),
      filter: _kindIs('forecast'),
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _src,
      _fpointLyr,
      const CircleLayerProperties(
        circleRadius: 4,
        circleColor: '#FF7043',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 1.5,
      ),
      filter: _kindIs('forecastPoint'),
      enableInteraction: false,
    );
    await controller.addSymbolLayer(
      _src,
      _fpointLabelLyr,
      const SymbolLayerProperties(
        textField: ['get', 'label'],
        textFont: ['Noto Sans TC Regular'],
        textSize: 11,
        textColor: '#FFFFFF',
        textHaloColor: '#000000',
        textHaloWidth: 1.2,
        textOffset: [0, 1.2],
        textAllowOverlap: false,
        textOptional: true,
      ),
      filter: _kindIs('forecastPoint'),
      // Hide "+Nh" once Flutter callout chips take over.
      minzoom: 5,
      maxzoom: kTyphoonCalloutMinZoom,
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _src,
      _currentLyr,
      const CircleLayerProperties(
        // Selected storm larger; others still tappable.
        circleRadius: [
          'case',
          [
            '==',
            ['get', 'selected'],
            1,
          ],
          8,
          5,
        ],
        circleColor: '#D32F2F',
        circleOpacity: [
          'case',
          [
            '==',
            ['get', 'selected'],
            1,
          ],
          1,
          0.55,
        ],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: [
          'case',
          [
            '==',
            ['get', 'selected'],
            1,
          ],
          2.5,
          1.5,
        ],
      ),
      filter: _kindIs('current'),
      enableInteraction: false,
    );
    // Name tooltip beside each centre (multi-storm switcher cue).
    await controller.addSymbolLayer(
      _src,
      _currentLabelLyr,
      const SymbolLayerProperties(
        textField: ['get', 'label'],
        textFont: ['Noto Sans TC Regular'],
        textSize: 13,
        textColor: '#FFFFFF',
        textHaloColor: '#B71C1C',
        textHaloWidth: 1.4,
        textOffset: [0, 1.35],
        textAllowOverlap: true,
        textOptional: false,
      ),
      filter: _kindIs('current'),
      minzoom: 3,
      enableInteraction: false,
    );
  }

  /// Highlights warned counties on the base `city` layer (matched by NAME).
  Future<void> _addWarningAreas(
    MapLibreMapController controller,
    List<String> names,
  ) async {
    try {
      await controller.removeLayer(_warnLyr);
    } catch (_) {
      // Not present yet.
    }
    if (names.isEmpty) return;
    await controller.addFillLayer(
      'exptech',
      _warnLyr,
      FillLayerProperties(
        fillColor: 'rgba(255, 193, 7, 0.22)',
        fillOutlineColor: 'rgba(255, 143, 0, 0.85)',
        visibility: showWarningAreas.value ? 'visible' : 'none',
      ),
      sourceLayer: 'city',
      // Membership via `in` + literal — NOT `match` with a bare name list
      // (that needs label/output pairs; an even name count made the expression
      // arity odd and aborted the iOS process).
      filter: <Object>[
        'in',
        <Object>['get', 'NAME'],
        <Object>['literal', names],
      ],
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
  }

  /// Turns strike-probability on/off. On ⇒ cone hidden; off ⇒ cone restored.
  void setShowProbability(bool value) {
    if (showProbability.value == value) return;
    showProbability.value = value;
    _applyOverlayVisibility();
  }

  /// Turns forecast-point Flutter callout cards on/off.
  void setShowForecastCallouts(bool value) {
    if (showForecastCallouts.value == value) return;
    showForecastCallouts.value = value;
  }

  /// Turns CAP warning-area fills on/off (independent of cone/probability).
  void setShowWarningAreas(bool value) {
    if (showWarningAreas.value == value) return;
    showWarningAreas.value = value;
    _applyOverlayVisibility();
  }

  /// Switches the L7 ↔ L10 storm-band combo (mutually exclusive).
  void setStormBand(TyphoonStormBand band) {
    if (stormBand.value == band) return;
    stormBand.value = band;
    _applyOverlayVisibility();
  }

  /// Radar XOR Himawari IR under vectors; frame closest ≤ bulletin time.
  void setWeatherOverlay(TyphoonWeatherOverlay value) {
    if (weatherOverlay.value == value) return;
    weatherOverlay.value = value;
    final controller = _controller;
    if (controller == null || !_added) return;
    _queue(() => _syncWeatherOverlay(controller));
  }

  Future<void> _syncWeatherOverlay(MapLibreMapController controller) async {
    await _removeWeatherRaster(controller);
    final kind = weatherOverlay.value;
    if (kind == TyphoonWeatherOverlay.none) return;
    final bulletin = _bulletinSecond;
    if (bulletin == null) {
      Log.warning('Typhoon weather overlay: no bulletin time yet');
      return;
    }
    final secs = kind == TyphoonWeatherOverlay.radar ? _radarSecs : _satSecs;
    final frame = closestAtOrBefore(secs, bulletin);
    if (frame == null) {
      Log.warning('Typhoon weather overlay: no ${kind.name} frame ≤ $bulletin');
      return;
    }
    final url = kind == TyphoonWeatherOverlay.radar
        ? radar.tileUrl('$frame')
        : satellite.tileUrl('$frame');
    // Warm ambient via ApiClient before MapLibre races its own GETs.
    try {
      final bounds = await controller.getVisibleRegion();
      final zoom = controller.cameraPosition?.zoom ?? 8;
      final args = (
        frames: ['$frame'],
        south: bounds.southwest.latitude,
        west: bounds.southwest.longitude,
        north: bounds.northeast.latitude,
        east: bounds.northeast.longitude,
        zoom: zoom,
      );
      if (kind == TyphoonWeatherOverlay.radar) {
        await radar.prefetchFrameTiles(
          frames: args.frames,
          south: args.south,
          west: args.west,
          north: args.north,
          east: args.east,
          zoom: args.zoom,
        );
      } else {
        await satellite.prefetchFrameTiles(
          frames: args.frames,
          south: args.south,
          west: args.west,
          north: args.north,
          east: args.east,
          zoom: args.zoom,
        );
      }
    } catch (_) {}
    await controller.addSource(
      _wxSrc,
      RasterSourceProperties(tiles: [url], tileSize: 256),
    );
    // Sit under the bottom typhoon fill so vectors/warning stay on top.
    final below = _warningNames.isNotEmpty ? _warnLyr : _probLyr;
    await controller.addRasterLayer(
      _wxSrc,
      _wxLyr,
      RasterLayerProperties(
        rasterOpacity: kind == TyphoonWeatherOverlay.radar ? 0.85 : 1.0,
      ),
      belowLayerId: below,
    );
    Log.info('Typhoon ${kind.name} overlay @ $frame (bulletin $bulletin)');
  }

  Future<void> _removeWeatherRaster(MapLibreMapController controller) async {
    try {
      await controller.removeLayer(_wxLyr);
    } catch (_) {}
    try {
      await controller.removeSource(_wxSrc);
    } catch (_) {}
  }

  /// Newest-first API ids → ascending Unix seconds for [closestAtOrBefore].
  static List<int> _ascendingSecs(List<String>? newestFirst) {
    if (newestFirst == null || newestFirst.isEmpty) return const [];
    final secs = <int>[for (final s in newestFirst) ?int.tryParse(s)]..sort();
    return secs;
  }

  void _applyOverlayVisibility() {
    final controller = _controller;
    if (controller == null || !_added) return;
    _queue(() async {
      final showProb = showProbability.value;
      final showL7 = stormBand.value == TyphoonStormBand.level7;
      await _setLayerVisibility(controller, _probLyr, showProb);
      await _setLayerVisibility(controller, _coneLyr, !showProb);
      await _setLayerVisibility(controller, _warnLyr, showWarningAreas.value);
      await _setLayerVisibility(controller, _c15Lyr, showL7);
      await _setLayerVisibility(controller, _avg15Lyr, showL7);
      await _setLayerVisibility(controller, _c25Lyr, !showL7);
      await _setLayerVisibility(controller, _avg25Lyr, !showL7);
    });
  }

  static Future<void> _setLayerVisibility(
    MapLibreMapController controller,
    String layerId,
    bool visible,
  ) async {
    try {
      // Must use setLayerVisibility — setLayerProperties sends nulls for every
      // omitted paint prop (skipNulls: false) and clears fill-color to black.
      await controller.setLayerVisibility(layerId, visible);
    } catch (_) {
      // Layer may be absent (e.g. no warning names / no L10 yet).
    }
  }

  static List<Object> _kindIs(String kind) => <Object>[
    '==',
    <Object>['get', 'kind'],
    kind,
  ];

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    const threshold = 0.5 * 0.5;
    final cosLat = math.cos(latLng.latitude * math.pi / 180);
    _StormPoint? best;
    var bestDistance = threshold;
    for (final point in _points) {
      final dLat = point.lat - latLng.latitude;
      final dLng = (point.lng - latLng.longitude) * cosLat;
      final distance = dLat * dLat + dLng * dLng;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = point;
      }
    }
    if (best == null) {
      if (tapped.value != null) clearForecastSelection();
      return;
    }
    if (best.kind == 'current' && best.cycloneKey != null) {
      selectCyclone(best.cycloneKey!);
      return;
    }
    // Forecast callouts auto-show when zoomed; tap only drives the sheet.
    tapped.value = best.label;
    tapRevision.value++;
  }

  /// Nearest [TrackForecast] to a tapped label's coordinates (for sheet detail).
  TrackForecast? forecastForLabel(String? label) {
    if (label == null) return null;
    _StormPoint? point;
    for (final p in _points) {
      if (p.label == label) {
        point = p;
        break;
      }
    }
    if (point == null) return null;
    final forecasts = _selectedTrack?.forecast ?? const <TrackForecast>[];
    if (forecasts.isEmpty) return null;
    TrackForecast? best;
    var bestD = double.infinity;
    for (final f in forecasts) {
      final dLat = f.latitude - point.lat;
      final dLng = f.longitude - point.lng;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestD) {
        bestD = d;
        best = f;
      }
    }
    return best;
  }

  @override
  Widget buildSheet(BuildContext context) =>
      TyphoonPanel(key: const ValueKey('typhoon'), layer: this);

  @override
  Widget buildMapOverlay(BuildContext context) =>
      TyphoonForecastCalloutOverlay(layer: this);

  @override
  Widget buildTopTrailingChrome(BuildContext context) =>
      TyphoonOverlayMenu(layer: this);

  @override
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        showProbability,
        showWarningAreas,
        stormBand,
      ]),
      builder: (context, _) {
        final showProb = showProbability.value;
        final showL7 = stormBand.value == TyphoonStormBand.level7;
        return MapLegendCard(
          child: SymbolLegend(
            items: [
              SymbolLegendItem(
                swatch: const _TrackSwatch(
                  color: Color(0xFF2196F3),
                  dashed: false,
                ),
                label: l10n.typhoonIntensityTd,
              ),
              SymbolLegendItem(
                swatch: const _TrackSwatch(
                  color: Color(0xFF43A047),
                  dashed: false,
                ),
                label: l10n.typhoonIntensityMild,
              ),
              SymbolLegendItem(
                swatch: const _TrackSwatch(
                  color: Color(0xFFFB8C00),
                  dashed: false,
                ),
                label: l10n.typhoonIntensityModerate,
              ),
              SymbolLegendItem(
                swatch: const _TrackSwatch(
                  color: Color(0xFFE53935),
                  dashed: false,
                ),
                label: l10n.typhoonIntensityIntense,
              ),
              SymbolLegendItem(
                swatch: const _TrackSwatch(
                  color: Color(0xFFEF5350),
                  dashed: true,
                ),
                label: l10n.typhoonLegendForecast,
              ),
              SymbolLegendItem(
                swatch: const _DotSwatch(color: Color(0xFFFF7043)),
                label: l10n.typhoonLegendForecastPoint,
              ),
              SymbolLegendItem(
                swatch: const _DotSwatch(color: Color(0xFFD32F2F), size: 10),
                label: l10n.typhoonLegendCurrent,
              ),
              if (!showProb)
                SymbolLegendItem(
                  swatch: Container(
                    width: 16,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  label: l10n.typhoonLegendCone,
                ),
              if (showL7) ...[
                SymbolLegendItem(
                  swatch: Container(
                    width: 16,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.35),
                      border: Border.all(color: const Color(0xFF7B1FA2)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  label: l10n.typhoonLegendCircle15,
                ),
                SymbolLegendItem(
                  swatch: const _TrackSwatch(
                    color: Color(0xFF9C27B0),
                    dashed: true,
                  ),
                  label: l10n.typhoonLegendCircleAvg,
                ),
              ] else ...[
                SymbolLegendItem(
                  swatch: Container(
                    width: 16,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                      border: Border.all(color: const Color(0xFFFFA000)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  label: l10n.typhoonLegendCircle25,
                ),
                SymbolLegendItem(
                  swatch: const _TrackSwatch(
                    color: Color(0xFFFFC107),
                    dashed: true,
                  ),
                  label: l10n.typhoonLegendCircleAvg,
                ),
              ],
              if (showProb)
                SymbolLegendItem(
                  swatch: Container(
                    width: 16,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB71C1C).withValues(alpha: 0.4),
                      border: Border.all(color: const Color(0xFFB71C1C)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  label: l10n.typhoonLegendProbability,
                ),
              if (showWarningAreas.value)
                SymbolLegendItem(
                  swatch: Container(
                    width: 16,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                      border: Border.all(color: const Color(0xFFFF8F00)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  label: l10n.typhoonLegendWarningAreas,
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    await _removeFromMap(controller);
    tapped.value = null;
    _controller = null;
  }

  @override
  void onStyleReset() => _added = false;

  void _parsePoints(Map<String, dynamic> geo) {
    _points.clear();
    final features = geo['features'];
    if (features is! List) return;
    for (final feature in features) {
      if (feature is! Map) continue;
      final properties = feature['properties'];
      final kind = properties is Map ? properties['kind'] : null;
      if (kind != 'current' && kind != 'forecastPoint') continue;
      final geometry = feature['geometry'];
      if (geometry is! Map || geometry['type'] != 'Point') continue;
      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) continue;
      final lng = coordinates[0];
      final lat = coordinates[1];
      if (lng is! num || lat is! num) continue;
      _points.add((
        lat: lat.toDouble(),
        lng: lng.toDouble(),
        label: properties is Map ? properties['label'] as String? : null,
        cycloneKey: properties is Map ? properties['cyclone'] as String? : null,
        kind: kind as String,
      ));
    }
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    await _removeWeatherRaster(controller);
    for (final layerId in _vectorLayers) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {}
    }
    try {
      await controller.removeSource(_src);
    } catch (_) {}
  }

  void _queue(Future<void> Function() op) {
    _ops = _ops.then((_) => op()).catchError((Object e, StackTrace st) {
      Log.handle(e, st, 'Typhoon layer op failed');
    });
  }
}

class _TrackSwatch extends StatelessWidget {
  const _TrackSwatch({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 10),
      painter: _TrackPainter(color: color, dashed: dashed),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final y = size.height / 2;
    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    const dash = 3.0;
    const gap = 2.0;
    var x = 0.0;
    while (x < size.width) {
      final end = math.min(x + dash, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}

class _DotSwatch extends StatelessWidget {
  const _DotSwatch({required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}

/// Bounding box of every coordinate in a typhoon [geo] `FeatureCollection`.
LatLngBounds? typhoonGeojsonBounds(Map<String, dynamic> geo) {
  final features = geo['features'];
  if (features is! List) return null;

  double? minLat, maxLat, minLng, maxLng;
  void visit(dynamic node) {
    if (node is! List || node.isEmpty) return;
    if (node[0] is num && node.length >= 2 && node[1] is num) {
      final lng = (node[0] as num).toDouble();
      final lat = (node[1] as num).toDouble();
      if (!lng.isFinite || !lat.isFinite) return;
      minLat = minLat == null ? lat : math.min(minLat!, lat);
      maxLat = maxLat == null ? lat : math.max(maxLat!, lat);
      minLng = minLng == null ? lng : math.min(minLng!, lng);
      maxLng = maxLng == null ? lng : math.max(maxLng!, lng);
      return;
    }
    for (final child in node) {
      visit(child);
    }
  }

  for (final feature in features) {
    if (feature is Map && feature['geometry'] is Map) {
      visit((feature['geometry'] as Map)['coordinates']);
    }
  }
  if (minLat == null) return null;
  return LatLngBounds(
    southwest: LatLng(minLat!, minLng!),
    northeast: LatLng(maxLat!, maxLng!),
  );
}
