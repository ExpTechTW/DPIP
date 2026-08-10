/// The lightning (閃電) timeline [MapLayer] — scrubbable strike snapshots.
///
/// Each frame is a window of recent strikes at that snapshot time. Colour is
/// age vs the frame clock (5 / 10 / 30 / 60 min); shape is type (circle =
/// cloud-to-cloud, cross = cloud-to-ground) — legacy look without map sprites.
library;

import 'dart:async';
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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class LightningMapLayer implements MapLayer {
  LightningMapLayer(this._repository);

  final MeteorLightningRepository _repository;

  static const String _sourceId = 'lightning-src';
  static const String _layerId = 'lightning-lyr';
  static const String _imagePrefix = 'lightning';

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
  Future<void> render(MapLibreMapController controller) async {}

  @override
  Future<void> onMapTap(
    LatLng latLng,
    MapLibreMapController controller,
  ) async {}

  @override
  Widget buildSheet(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildTopTrailingChrome(
    BuildContext context, {
    required ValueListenable<bool> showTownLabels,
    required ValueChanged<bool> onShowTownLabelsChanged,
  }) => const SizedBox.shrink();

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
  void selectFeature(String id) {}

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
      // One pre-coloured PNG per shape × age bucket, black outline baked in —
      // the same trick as the wind arrows. MapLibre tints a plain (non-SDF)
      // image by *replacing* its RGB, which would erase a baked outline, so the
      // colour has to be baked too; the layer picks the image by feature.
      for (final kind in const ['dot', 'cross']) {
        for (final minutes in const [5, 10, 30, 60]) {
          final fill = colorFromHexRgb(_ageHex[minutes]!)!;
          final bytes = kind == 'dot'
              ? await _renderDot(fill)
              : await _renderCross(fill);
          await controller.addImage(_imageId(kind, minutes), bytes, false);
        }
      }
      _imagesReady = true;
    } catch (error, stackTrace) {
      // Style reload may leave images; retry next show.
      Log.handle(error, stackTrace, 'lightning addImage');
    }
  }

  static String _imageId(String kind, int minutes) =>
      '$_imagePrefix-$kind-$minutes';

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
        // The image is picked by the feature's `icon` property (kind + age),
        // carrying the pre-baked colour + black outline — no `iconColor` tint,
        // which would replace the baked-in outline on a non-SDF image.
        iconImage: <Object>['get', 'icon'],
        iconOpacity: 0.85,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        // Same visual weight as the wind arrows (~35–110 px on screen at
        // Taiwan overview zooms) — strikes have no speed dimension, so this is
        // a flat zoom ramp rather than the wind layer's per-speed nested one.
        iconSize: <Object>[
          'interpolate',
          <Object>['linear'],
          <Object>['zoom'],
          5,
          0.6,
          15,
          1.8,
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
      final kind = strike.type == 1 ? 'cross' : 'dot';
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [strike.longitude, strike.latitude],
        },
        'properties': {
          'kind': strike.type == 1 ? 'cg' : 'cc',
          'age': age,
          'icon': _imageId(kind, age),
        },
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

  Future<Uint8List> _renderDot(Color fill) async {
    const size = 64.0;
    // Same proportional outline as the wind arrows (5.5 on a 96 px canvas ≈
    // 5.7 %): 4.0 on the smaller 64 px mark keeps the ring visibly as thick
    // after the layer scales both glyphs to the same on-screen size.
    const halo = 4.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Black offset-outline baked in (like the wind arrows): the PNG carries the
    // bucket colour + black ring, and the layer shows it un-tinted so the ring
    // survives.
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size * 0.28 + halo,
      Paint()..color = const Color(0xFF000000),
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size * 0.28,
      Paint()..color = fill,
    );
    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<Uint8List> _renderCross(Color fill) async {
    const size = 64.0;
    const thickness = 10.0;
    // Same proportional outline as the wind arrows — see [_renderDot].
    const halo = 4.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    // Vertical + horizontal bars, black behind the colour (see [_renderDot]).
    RRect bar(double w, double h) => RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: const Offset(size / 2, size / 2),
        width: w,
        height: h,
      ),
      const Radius.circular(2),
    );
    final black = Paint()..color = const Color(0xFF000000);
    canvas.drawRRect(bar(thickness + halo * 2, size * 0.7 + halo * 2), black);
    canvas.drawRRect(bar(size * 0.7 + halo * 2, thickness + halo * 2), black);
    canvas.drawRRect(bar(thickness, size * 0.7), Paint()..color = fill);
    canvas.drawRRect(bar(size * 0.7, thickness), Paint()..color = fill);
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
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // Same black outline the map icons bake in — pale strikes (yellow /
          // blue on the frosted card) need it to read as a mark.
          border: Border.all(color: Colors.black, width: 1.2),
        ),
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
    // Black bars first (thicker), the colour on top — the legend cross mirrors
    // the map marker's baked black outline.
    final paint = Paint()
      ..color = const Color(0xFF000000)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(c.dx, 1), Offset(c.dx, size.height - 1), paint);
    canvas.drawLine(Offset(1, c.dy), Offset(size.width - 1, c.dy), paint);
    paint
      ..color = color
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(c.dx, 1), Offset(c.dx, size.height - 1), paint);
    canvas.drawLine(Offset(1, c.dy), Offset(size.width - 1, c.dy), paint);
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) =>
      oldDelegate.color != color;
}
