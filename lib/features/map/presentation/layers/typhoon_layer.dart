/// The 颱風 (typhoon) map layer — CWA track / potential / probability / warning
/// plus scrubbable satellite imagery, from the full v5 meteor typhoon surface.
library;

import 'dart:math' as math;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/widgets/typhoon_panel.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';
import 'package:dpip/features/typhoon/domain/typhoon_overlay.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A tappable storm waypoint parsed from the overlay geojson.
typedef _StormPoint = ({double lat, double lng, String? label});

/// Sheet-type [MapLayer]: renders every typhoon dataset on the map and drives
/// [TyphoonPanel] (summary, warning, history, satellite) via notifiers.
class TyphoonMapLayer implements MapLayer {
  TyphoonMapLayer(this._repository);

  final MeteorTyphoonRepository _repository;

  MapLibreMapController? _controller;
  bool _added = false;
  Future<void> _ops = Future<void>.value();

  /// Satellite-image times (Unix seconds, ascending) and the shown index.
  final ValueNotifier<List<int>> imageFrames = ValueNotifier(const []);
  final ValueNotifier<int> selectedFrame = ValueNotifier(0);

  /// Dataset history clock (potential/track/probability share the same times).
  final ValueNotifier<List<int>> historyFrames = ValueNotifier(const []);

  /// Selected history second; `null` = live `/geojson` + latest datasets.
  final ValueNotifier<int?> selectedHistory = ValueNotifier(null);

  final ValueNotifier<TyphoonCyclone?> summary = ValueNotifier(null);
  final ValueNotifier<TrackPayload?> track = ValueNotifier(null);
  final ValueNotifier<TyphoonWarning?> warning = ValueNotifier(null);
  final ValueNotifier<TyphoonProbability?> probability = ValueNotifier(null);
  final ValueNotifier<String?> tapped = ValueNotifier(null);
  final ValueNotifier<int> tapRevision = ValueNotifier(0);

  final List<_StormPoint> _points = [];
  List<String> _warningNames = const [];

  static const String _src = 'typhoon-src';
  static const String _imgSrc = 'typhoon-img-src';
  static const String _imgLyr = 'typhoon-img-lyr';
  static const String _warnLyr = 'typhoon-warning-areas';
  static const String _probLyr = 'typhoon-probability';
  static const String _coneLyr = 'typhoon-cone';
  static const String _c15Lyr = 'typhoon-circle15';
  static const String _c25Lyr = 'typhoon-circle25';
  static const String _pastLyr = 'typhoon-past';
  static const String _forecastLyr = 'typhoon-forecast';
  static const String _fpointLyr = 'typhoon-fpoint';
  static const String _fpointLabelLyr = 'typhoon-fpoint-label';
  static const String _currentLyr = 'typhoon-current';

  static const List<String> _vectorLayers = [
    _warnLyr,
    _probLyr,
    _coneLyr,
    _c15Lyr,
    _c25Lyr,
    _pastLyr,
    _forecastLyr,
    _fpointLyr,
    _fpointLabelLyr,
    _currentLyr,
  ];

  static const List<List<num>> _imgCoords = [
    [110, 32],
    [150, 32],
    [150, 10],
    [110, 10],
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

  @override
  Future<Result<List<MapFrame>>> frames() async => const Ok([]);

  @override
  Future<void> prepare(MapLibreMapController c, List<MapFrame> frames) async {}

  @override
  Future<void> show(MapLibreMapController c, MapFrame frame) async {}

  @override
  Future<void> render(MapLibreMapController controller) async {
    _controller = controller;
    final results = await Future.wait([
      _repository.geojson(),
      _repository.images(),
      _repository.cyclones(),
      _repository.track(),
      _repository.potential(),
      _repository.probability(),
      _repository.warning(),
      _repository.history(TyphoonKind.potential),
    ]);

    final geoResult = results[0] as Result<Map<String, dynamic>>;
    final imagesResult = results[1] as Result<List<int>>;
    final indexResult = results[2] as Result<CycloneIndex>;
    final trackResult = results[3] as Result<TrackPayload>;
    final potentialResult = results[4] as Result<TyphoonPotential>;
    final probabilityResult = results[5] as Result<TyphoonProbability>;
    final warningResult = results[6] as Result<TyphoonWarning>;
    final historyResult = results[7] as Result<List<int>>;

    final trackPayload = trackResult.valueOrNull;
    final probability = probabilityResult.valueOrNull;
    final warning = warningResult.valueOrNull;
    final index = indexResult.valueOrNull;
    final images = imagesResult.valueOrNull ?? const <int>[];
    final history = historyResult.valueOrNull ?? const <int>[];

    summary.value = (index != null && index.cyclones.isNotEmpty)
        ? index.cyclones.first
        : null;
    track.value = trackPayload;
    this.probability.value = probability;
    this.warning.value = warning;
    imageFrames.value = images;
    selectedFrame.value = images.isEmpty ? 0 : images.length - 1;
    historyFrames.value = history;
    selectedHistory.value = null;

    final geo = _liveOverlay(
      geoResult: geoResult,
      potential: potentialResult.valueOrNull,
      probability: probability,
      track: trackPayload,
    );
    _parsePoints(geo);
    _warningNames = [
      for (final a in warning?.areas ?? const <WarningArea>[]) a.name,
    ];

    await _removeFromMap(controller);
    if (images.isNotEmpty) {
      await _addImage(controller, images.last);
    }
    await _addWarningAreas(controller, _warningNames);
    await _addVectorOverlay(controller, geo);
    _added = true;
  }

  Map<String, dynamic> _liveOverlay({
    required Result<Map<String, dynamic>> geoResult,
    required TyphoonPotential? potential,
    required TyphoonProbability? probability,
    required TrackPayload? track,
  }) {
    final server = geoResult.valueOrNull;
    if (server != null) {
      return augmentTyphoonGeojson(server, track: track);
    }
    if (potential != null && probability != null) {
      return typhoonFeatureCollection(
        potential: potential,
        probability: probability,
        track: track,
      );
    }
    return emptyTyphoonFeatureCollection;
  }

  /// Scrub dataset history — rebuilds the vector overlay from typed snapshots.
  void selectHistory(int? second) {
    selectedHistory.value = second;
    final controller = _controller;
    if (controller == null || !_added) return;
    _queue(() => _applyHistory(controller, second));
  }

  Future<void> _applyHistory(
    MapLibreMapController controller,
    int? second,
  ) async {
    if (second == null) {
      // Back to live — re-fetch latest bundle.
      final geoR = await _repository.geojson();
      final trackR = await _repository.track();
      final potR = await _repository.potential();
      final probR = await _repository.probability();
      final warnR = await _repository.warning();
      track.value = trackR.valueOrNull;
      probability.value = probR.valueOrNull;
      warning.value = warnR.valueOrNull;
      _warningNames = [
        for (final a in warning.value?.areas ?? const <WarningArea>[]) a.name,
      ];
      final geo = _liveOverlay(
        geoResult: geoR,
        potential: potR.valueOrNull,
        probability: probR.valueOrNull,
        track: trackR.valueOrNull,
      );
      _parsePoints(geo);
      await _addWarningAreas(controller, _warningNames);
      await controller.setGeoJsonSource(_src, geo);
      return;
    }

    final results = await Future.wait([
      _repository.trackAt(second),
      _repository.potentialAt(second),
      _repository.probabilityAt(second),
      _repository.warningAt(second),
    ]);
    final trackR = results[0] as Result<TrackPayload>;
    final potR = results[1] as Result<TyphoonPotential>;
    final probR = results[2] as Result<TyphoonProbability>;
    final warnR = results[3] as Result<TyphoonWarning>;

    final pot = potR.valueOrNull;
    final prob = probR.valueOrNull;
    if (pot == null || prob == null) {
      Log.warning('Typhoon history $second incomplete; keeping current overlay');
      return;
    }
    track.value = trackR.valueOrNull;
    probability.value = prob;
    warning.value = warnR.valueOrNull;
    _warningNames = [
      for (final a in warning.value?.areas ?? const <WarningArea>[]) a.name,
    ];
    final geo = typhoonFeatureCollection(
      potential: pot,
      probability: prob,
      track: trackR.valueOrNull,
    );
    _parsePoints(geo);
    await _addWarningAreas(controller, _warningNames);
    await controller.setGeoJsonSource(_src, geo);
  }

  Future<void> _addVectorOverlay(
    MapLibreMapController controller,
    Map<String, dynamic> geo,
  ) async {
    await controller.addSource(_src, GeojsonSourceProperties(data: geo));
    // Probability under the cone so the track cone stays readable.
    await controller.addFillLayer(
      _src,
      _probLyr,
      const FillLayerProperties(
        fillColor: [
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
      ),
      filter: _kindIs('probability'),
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
    await controller.addFillLayer(
      _src,
      _coneLyr,
      const FillLayerProperties(
        fillColor: 'rgba(255,82,82,0.12)',
        fillOutlineColor: 'rgba(255,82,82,0.5)',
      ),
      filter: _kindIs('cone'),
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
    await controller.addFillLayer(
      _src,
      _c15Lyr,
      const FillLayerProperties(
        fillColor: 'rgba(255, 193, 7, 0.14)',
        fillOutlineColor: 'rgba(255, 160, 0, 0.75)',
      ),
      filter: _kindIs('circle15'),
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
    await controller.addFillLayer(
      _src,
      _c25Lyr,
      const FillLayerProperties(
        fillColor: 'rgba(156, 39, 176, 0.16)',
        fillOutlineColor: 'rgba(123, 31, 162, 0.8)',
      ),
      filter: _kindIs('circle25'),
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
    await controller.addLineLayer(
      _src,
      _pastLyr,
      const LineLayerProperties(
        lineColor: '#B0BEC5',
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
      minzoom: 5,
      enableInteraction: false,
    );
    await controller.addCircleLayer(
      _src,
      _currentLyr,
      const CircleLayerProperties(
        circleRadius: 7,
        circleColor: '#D32F2F',
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2,
      ),
      filter: _kindIs('current'),
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
      const FillLayerProperties(
        fillColor: 'rgba(255, 193, 7, 0.22)',
        fillOutlineColor: 'rgba(255, 143, 0, 0.85)',
      ),
      sourceLayer: 'city',
      filter: <Object>[
        'match',
        <Object>['get', 'NAME'],
        ...names,
        true,
        false,
      ],
      belowLayerId: outlineLayerId,
      enableInteraction: false,
    );
  }

  static List<Object> _kindIs(String kind) => <Object>[
    '==',
    <Object>['get', 'kind'],
    kind,
  ];

  void showFrame(int index) {
    final frames = imageFrames.value;
    if (index < 0 || index >= frames.length) return;
    selectedFrame.value = index;
    final controller = _controller;
    if (controller == null || !_added) return;
    _queue(() => _addImage(controller, frames[index]));
  }

  Future<void> _addImage(MapLibreMapController controller, int second) async {
    try {
      await controller.removeLayer(_imgLyr);
    } catch (_) {}
    try {
      await controller.removeSource(_imgSrc);
    } catch (_) {}
    await controller.addSource(
      _imgSrc,
      ImageSourceProperties(
        url: _repository.imageUrl(second),
        coordinates: _imgCoords,
      ),
    );
    await controller.addRasterLayer(
      _imgSrc,
      _imgLyr,
      const RasterLayerProperties(rasterOpacity: 0.8),
      belowLayerId: outlineLayerId,
    );
  }

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
    tapped.value = best?.label;
    if (best != null) tapRevision.value++;
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
    final cyclones = track.value?.cyclones;
    if (cyclones == null || cyclones.isEmpty) return null;
    final forecasts = cyclones.first.forecast;
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
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MapLegendCard(
      child: SymbolLegend(
        items: [
          SymbolLegendItem(
            swatch: const _TrackSwatch(color: Color(0xFFB0BEC5), dashed: false),
            label: l10n.typhoonLegendPast,
          ),
          SymbolLegendItem(
            swatch: const _TrackSwatch(color: Color(0xFFEF5350), dashed: true),
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
          SymbolLegendItem(
            swatch: Container(
              width: 16,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withValues(alpha: 0.25),
                border: Border.all(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.7),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            label: l10n.typhoonLegendCone,
          ),
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
            label: l10n.typhoonLegendCircle15,
          ),
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
            label: l10n.typhoonLegendCircle25,
          ),
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
      ));
    }
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    for (final layerId in [..._vectorLayers, _imgLyr]) {
      try {
        await controller.removeLayer(layerId);
      } catch (_) {}
    }
    for (final sourceId in [_src, _imgSrc]) {
      try {
        await controller.removeSource(sourceId);
      } catch (_) {}
    }
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
