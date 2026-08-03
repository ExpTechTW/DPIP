/// The 颱風 (typhoon) map layer — the CWA storm track (observed + forecast
/// paths, the forecast cone, forecast waypoints, and the current centre) plus a
/// scrubbable satellite-imagery overlay, from the v5 meteor typhoon feed.
library;

import 'dart:math' as math;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/widgets/typhoon_panel.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A tappable storm waypoint parsed from the geojson (a forecast point or the
/// current centre).
typedef _StormPoint = ({double lat, double lng, String? label});

/// A sheet-type [MapLayer] for the active typhoon: it renders the track geojson
/// + a satellite raster on activation, self-frames on the storm once, and drives
/// a [TyphoonPanel] (storm summary + satellite time selector) via notifiers.
class TyphoonMapLayer implements MapLayer {
  TyphoonMapLayer(this._repository);

  final MeteorTyphoonRepository _repository;

  MapLibreMapController? _controller;
  bool _added = false;
  Future<void> _ops = Future<void>.value();

  /// Satellite-image times (Unix seconds, ascending) and the shown index — read
  /// by the panel's time selector.
  final ValueNotifier<List<int>> imageFrames = ValueNotifier(const []);
  final ValueNotifier<int> selectedFrame = ValueNotifier(0);

  /// The active cyclone summary (null when none) and the tapped waypoint label.
  final ValueNotifier<TyphoonCyclone?> summary = ValueNotifier(null);
  final ValueNotifier<String?> tapped = ValueNotifier(null);

  /// Bumped on every tap that hits a waypoint — even the same one — so the panel
  /// re-pops after the user collapsed it (a same-value [tapped] wouldn't notify).
  /// Mirrors the station sheet's selectionRevision.
  final ValueNotifier<int> tapRevision = ValueNotifier(0);

  /// Tappable waypoints from the latest geojson.
  final List<_StormPoint> _points = [];

  static const String _src = 'typhoon-src';
  static const String _imgSrc = 'typhoon-img-src';
  static const String _imgLyr = 'typhoon-img-lyr';
  static const String _coneLyr = 'typhoon-cone';
  static const String _pastLyr = 'typhoon-past';
  static const String _forecastLyr = 'typhoon-forecast';
  static const String _fpointLyr = 'typhoon-fpoint';
  static const String _fpointLabelLyr = 'typhoon-fpoint-label';
  static const String _currentLyr = 'typhoon-current';

  static const List<String> _vectorLayers = [
    _coneLyr,
    _pastLyr,
    _forecastLyr,
    _fpointLyr,
    _fpointLabelLyr,
    _currentLyr,
  ];

  /// The Himawari satellite sector the PNGs project onto — corners as [lng, lat]
  /// (top-left, top-right, bottom-right, bottom-left), a fixed footprint carried
  /// over from legacy.
  static const List<List<num>> _imgCoords = [
    [110, 32],
    [150, 32],
    [150, 10],
    [110, 10],
  ];

  static const Map<String, dynamic> _emptyFc = {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

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
    final geo = (await _repository.geojson()).valueOrNull ?? _emptyFc;
    final images = (await _repository.images()).valueOrNull ?? const <int>[];
    final index = (await _repository.cyclones()).valueOrNull;
    summary.value = (index != null && index.cyclones.isNotEmpty)
        ? index.cyclones.first
        : null;
    imageFrames.value = images;
    selectedFrame.value = images.isEmpty ? 0 : images.length - 1;
    _parsePoints(geo);

    await _removeFromMap(controller);
    // Newest satellite frame, below the borders so they stay legible.
    if (images.isNotEmpty) {
      await _addImage(controller, images.last);
    }
    // Track vector overlays — one source, one layer per `kind` via a filter.
    // All are non-interactive so a tap anywhere in the storm routes to
    // map#onMapClick → onMapTap (our nearest-waypoint math), not the unhandled
    // native feature#onTap.
    await controller.addSource(_src, GeojsonSourceProperties(data: geo));
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
    _added = true;
  }

  static List<Object> _kindIs(String kind) => <Object>[
    '==',
    <Object>['get', 'kind'],
    kind,
  ];

  /// Swaps the satellite raster to the frame at [second] (tolerant remove-add).
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
    } catch (_) {
      // Not on the map yet.
    }
    try {
      await controller.removeSource(_imgSrc);
    } catch (_) {
      // Not on the map yet.
    }
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
      belowLayerId: townOutlineLayerId,
    );
  }

  @override
  Future<void> onMapTap(LatLng latLng, MapLibreMapController controller) async {
    // Nearest waypoint within ~0.5° (lon scaled by latitude).
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

  @override
  Widget buildSheet(BuildContext context) =>
      TyphoonPanel(key: const ValueKey('typhoon'), layer: this);

  /// Track / cone / centre key — colours match the vector layers above.
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
      } catch (_) {
        // Not on the map yet.
      }
    }
    for (final sourceId in [_src, _imgSrc]) {
      try {
        await controller.removeSource(sourceId);
      } catch (_) {
        // Not on the map yet.
      }
    }
  }

  /// Serialises the satellite-frame swaps (driven by the panel, off the
  /// scaffold's own op queue) so an add never races a remove.
  void _queue(Future<void> Function() op) {
    _ops = _ops.then((_) => op()).catchError((Object e, StackTrace st) {
      Log.handle(e, st, 'Typhoon layer op failed');
    });
  }
}

/// A short solid or dashed line mark for the typhoon track legend.
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

/// A filled circle mark for forecast / current-centre legend rows.
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

/// The bounding box of every coordinate in a typhoon [geo] `FeatureCollection`
/// (Points, LineStrings, Polygons), or null when it holds no finite coordinate —
/// used to frame the map on the whole storm. Pure and top-level so it is
/// unit-testable without a MapLibre controller.
LatLngBounds? typhoonGeojsonBounds(Map<String, dynamic> geo) {
  final features = geo['features'];
  if (features is! List) return null;

  double? minLat, maxLat, minLng, maxLng;
  void visit(dynamic node) {
    if (node is! List || node.isEmpty) return;
    // A coordinate pair is a list whose first two entries are numbers.
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
