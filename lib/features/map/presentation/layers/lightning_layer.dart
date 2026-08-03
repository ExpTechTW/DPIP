/// The lightning (閃電) timeline [MapLayer] — scrubbable strike snapshots.
///
/// Each frame is a window of recent strikes at that snapshot time. Colour is
/// age vs the frame clock (5 / 10 / 30 / 60 min); shape is type (circle =
/// cloud-to-cloud, cross = cloud-to-ground) — legacy look without map sprites.
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/weather/domain/lightning_snapshot.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class LightningMapLayer implements MapLayer {
  LightningMapLayer(this._repository);

  final MeteorLightningRepository _repository;

  static const String _sourceId = 'lightning-src';
  static const String _layerId = 'lightning-lyr';
  static const String _dotImageId = 'lightning-dot';
  static const String _crossImageId = 'lightning-cross';

  static const Map<String, dynamic> _empty = {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

  /// Age bucket → hex (legacy: red / yellow / green / blue).
  static const Map<int, String> _ageHex = {
    5: '#FF0000',
    10: '#FFFF00',
    30: '#00FF00',
    60: '#0000FF',
  };

  final Map<String, LightningSnapshot> _cache = {};
  List<String> _orderedIds = const [];
  Map<String, int> _indexById = const {};
  bool _mounted = false;
  bool _imagesReady = false;
  String? _shownFrameId;

  @override
  String get id => 'lightning';

  @override
  IconData get icon => Icons.bolt_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerLightning;

  @override
  bool get usesTimeline => true;

  @override
  double get bottomChromeFraction => 0;

  @override
  double get mapMinZoom => 4;

  @override
  double get mapMaxZoom => BaseMap.maxZoom;

  @override
  String? get bakedAedTileUrl => null;

  @override
  Future<void> render(MapLibreMapController controller) async {}

  @override
  Future<void> onMapTap(
    LatLng latLng,
    MapLibreMapController controller,
  ) async {}

  @override
  Widget buildSheet(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildTopTrailingChrome(BuildContext context) =>
      const SizedBox.shrink();

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
  Widget buildLegend(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MapLegendCard(
      child: SymbolLegend(
        items: [
          for (final minutes in const [5, 10, 30, 60]) ...[
            SymbolLegendItem(
              swatch: _LegendMark(
                color: colorFromHexRgb(_ageHex[minutes]!)!,
                cross: true,
              ),
              label: l10n.lightningLegendCg(minutes),
            ),
            SymbolLegendItem(
              swatch: _LegendMark(
                color: colorFromHexRgb(_ageHex[minutes]!)!,
                cross: false,
              ),
              label: l10n.lightningLegendCc(minutes),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Future<Result<List<MapFrame>>> frames() async {
    final result = await _repository.history();
    return result.map(
      (secs) => [
        for (final sec in secs)
          MapFrame(
            id: '$sec',
            time: DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true),
          ),
      ],
    );
  }

  @override
  Future<void> prepare(
    MapLibreMapController controller,
    List<MapFrame> frames,
  ) async {
    _orderedIds = [for (final f in frames) f.id];
    _indexById = {
      for (var i = 0; i < _orderedIds.length; i++) _orderedIds[i]: i,
    };
    await _ensureImages(controller);
    await _ensureSource(controller);
    if (_orderedIds.isNotEmpty) {
      await _fetchIntoCache(_orderedIds.last);
      final start = _orderedIds.length > 3 ? _orderedIds.length - 3 : 0;
      for (var i = start; i < _orderedIds.length - 1; i++) {
        unawaited(_fetchIntoCache(_orderedIds[i]));
      }
    }
  }

  @override
  Future<void> show(
    MapLibreMapController controller,
    MapFrame frame, {
    bool scrubbing = false,
  }) async {
    await _ensureImages(controller);
    await _ensureSource(controller);

    var snapshot = _cache[frame.id];
    if (snapshot == null) {
      if (scrubbing) return;
      snapshot = await _fetchIntoCache(frame.id);
      if (snapshot == null) {
        try {
          await controller.setGeoJsonSource(_sourceId, _empty);
        } catch (_) {}
        _shownFrameId = frame.id;
        return;
      }
    }

    try {
      await controller.setGeoJsonSource(_sourceId, _geoJson(snapshot));
      _shownFrameId = frame.id;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'lightning show ${frame.id}');
    }

    if (!scrubbing) {
      final i = _indexById[frame.id];
      if (i != null) {
        for (final j in [i - 1, i + 1]) {
          if (j >= 0 && j < _orderedIds.length) {
            unawaited(_fetchIntoCache(_orderedIds[j]));
          }
        }
      }
    }
  }

  @override
  Future<void> clear(MapLibreMapController controller) async {
    await _removeFromMap(controller);
    _mounted = false;
    _shownFrameId = null;
  }

  @override
  void onStyleReset() {
    _mounted = false;
    _imagesReady = false;
    _shownFrameId = null;
  }

  Future<LightningSnapshot?> _fetchIntoCache(String frameId) async {
    final existing = _cache[frameId];
    if (existing != null) return existing;
    final sec = int.tryParse(frameId);
    if (sec == null) return null;
    final result = await _repository.at(sec);
    return result.when(
      ok: (snapshot) {
        _cache[frameId] = snapshot;
        // Bound memory — keep ~40 frames.
        if (_cache.length > 40) {
          final keys = _cache.keys.toList()
            ..sort(); // oldest seconds first as string-sortable? better by int
          keys.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          for (final k in keys.take(_cache.length - 40)) {
            if (k != _shownFrameId) _cache.remove(k);
          }
        }
        return snapshot;
      },
      err: (failure) {
        Log.warning('lightning frame $frameId: ${failure.message}');
        return null;
      },
    );
  }

  Future<void> _ensureImages(MapLibreMapController controller) async {
    if (_imagesReady) return;
    try {
      await controller.addImage(_dotImageId, await _renderDot(), true);
      await controller.addImage(_crossImageId, await _renderCross(), true);
      _imagesReady = true;
    } catch (error, stackTrace) {
      // Style reload may leave images; retry next show.
      Log.handle(error, stackTrace, 'lightning addImage');
    }
  }

  Future<void> _ensureSource(MapLibreMapController controller) async {
    if (_mounted) return;
    await _removeFromMap(controller);
    await controller.addSource(
      _sourceId,
      GeojsonSourceProperties(data: _empty),
    );
    await controller.addSymbolLayer(
      _sourceId,
      _layerId,
      SymbolLayerProperties(
        iconImage: <Object>[
          'match',
          <Object>['get', 'kind'],
          'cg',
          _crossImageId,
          _dotImageId,
        ],
        iconColor: <Object>[
          'match',
          <Object>['get', 'age'],
          5,
          _ageHex[5]!,
          10,
          _ageHex[10]!,
          30,
          _ageHex[30]!,
          _ageHex[60]!,
        ],
        iconOpacity: 0.85,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconSize: <Object>[
          'interpolate',
          <Object>['linear'],
          <Object>['zoom'],
          5,
          0.35,
          15,
          1.1,
        ],
      ),
      enableInteraction: false,
    );
    _mounted = true;
  }

  Map<String, dynamic> _geoJson(LightningSnapshot snapshot) {
    final features = <Map<String, dynamic>>[];
    for (final strike in snapshot.strikes) {
      final age = _ageBucket(snapshot.time, strike.time);
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [strike.longitude, strike.latitude],
        },
        'properties': {'kind': strike.type == 1 ? 'cg' : 'cc', 'age': age},
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// Age of [strikeSec] relative to [snapshotSec], bucketed like legacy.
  static int _ageBucket(int snapshotSec, int strikeSec) {
    final age = snapshotSec - strikeSec;
    if (age < 5 * 60) return 5;
    if (age < 10 * 60) return 10;
    if (age < 30 * 60) return 30;
    return 60;
  }

  Future<Uint8List> _renderDot() async {
    const size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(size / 2, size / 2), size * 0.28, paint);
    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uint8List> _renderCross() async {
    const size = 64.0;
    const thickness = 10.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;
    // Vertical + horizontal bars.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(size / 2, size / 2),
          width: thickness,
          height: size * 0.7,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(size / 2, size / 2),
          width: size * 0.7,
          height: thickness,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _removeFromMap(MapLibreMapController controller) async {
    try {
      await controller.removeLayer(_layerId);
    } catch (_) {}
    try {
      await controller.removeSource(_sourceId);
    } catch (_) {}
  }
}

class _LegendMark extends StatelessWidget {
  const _LegendMark({required this.color, required this.cross});

  final Color color;
  final bool cross;

  @override
  Widget build(BuildContext context) {
    if (!cross) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    return SizedBox(
      width: 12,
      height: 12,
      child: CustomPaint(painter: _CrossPainter(color)),
    );
  }
}

class _CrossPainter extends CustomPainter {
  _CrossPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(c.dx, 1), Offset(c.dx, size.height - 1), paint);
    canvas.drawLine(Offset(1, c.dy), Offset(size.width - 1, c.dy), paint);
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) =>
      oldDelegate.color != color;
}
