/// The wind arrows themselves — the MapLibre source, symbol layer, baked arrow
/// images and snapshot cache that draw one station-wind frame.
///
/// Split out of [WindMapLayer] for the same reason the strike marks were split
/// out of the 閃電 layer: the arrows have two homes now, the standalone 風向
/// layer and the radar echo's own wind overlay, which draws the observations
/// matching whichever radar frame is on screen. Both need the identical
/// arrows — the same speed ramp, the same baked PNGs, the same legend — so the
/// drawing lives here once and each host supplies only *which* frame to show.
///
/// Rotation is where the wind blows **toward** (meteorological "from" + 180°);
/// colour is the discrete speed bucket ([windBuckets]).
library;

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/presentation/wind_speed.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:dpip/shared/color_hex.dart';
import 'package:dpip/shared/widgets/map_color_legend.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Draws station wind arrows on one map surface.
///
/// [namespace] scopes the MapLibre source/layer ids, so the 風向 layer and the
/// radar overlay can each own a mount without colliding over one id. The baked
/// arrow images deliberately stay on shared ids: they are style-global,
/// identical, and registering one set twice would only cost memory.
class WindArrowOverlay {
  WindArrowOverlay(this._repository, {String namespace = 'wind-arrow'})
    : _sourceId = '$namespace-src',
      _layerId = '$namespace-lyr';

  final MeteorWeatherRepository _repository;

  final String _sourceId;
  final String _layerId;

  /// The reading unit the arrows encode — the legend's footer when a host asks
  /// for it, and the same string the 風向 layer's sheet prints.
  static const String unit = 'm/s';

  static const String _imagePrefix = 'wind-arrow';

  static const Map<String, dynamic> _empty = {
    'type': 'FeatureCollection',
    'features': <dynamic>[],
  };

  final Map<String, WeatherSnapshot> _cache = {};
  Map<String, WeatherStation> _stations = const {};
  List<String> _orderedIds = const [];
  Map<String, int> _indexById = const {};
  bool _mounted = false;
  // Baked bitmaps carry the corrected colours painted into them, so they must
  // be re-baked when the setting moves — see [VisionCache].
  bool _imagesReady = false;
  ColorVision? _imagesVision;
  String? _shownFrameId;

  /// Available snapshot times (Unix seconds, ascending).
  Future<Result<List<int>>> history() => _repository.history();

  /// The shared image id for speed bucket [bucket] (0 = calm … 4 = strongest).
  static String imageIdFor(int bucket) => '$_imagePrefix-$bucket';

  /// Registers one pre-coloured, outline-baked arrow image per speed bucket.
  ///
  /// Shared with [WindMapLayer], which mounts its own arrow layer on its own
  /// station source: the ids are style-global, so whichever surface bakes first
  /// serves both, and the bake is idempotent.
  static Future<void> registerImages(MapLibreMapController controller) async {
    final bytes = await _bakeArrows();
    for (var i = 0; i < bytes.length; i++) {
      await controller.addImage(imageIdFor(i), bytes[i], false);
    }
  }

  /// Speed → pre-coloured arrow image, a `step` over the [windBuckets]
  /// thresholds (weakest first).
  static List<Object> iconExpression() => <Object>[
    'step',
    <Object>['get', 'value'],
    imageIdFor(0),
    for (var i = 1; i < windBuckets.length; i++) ...[
      windBuckets[i].$1,
      imageIdFor(i),
    ],
  ];

  /// Size scales with wind speed (bigger = stronger) and with zoom. Zoom must
  /// be the OUTERMOST interpolate input (MapLibre only allows `[zoom]` at the
  /// top level), with the speed interpolate nested per zoom stop. Tuned for the
  /// 96 px glyph: ~32–80 px on screen at Taiwan overview zooms.
  static List<Object> sizeExpression() => <Object>[
    'interpolate',
    <Object>['linear'],
    <Object>['zoom'],
    5,
    <Object>[
      'interpolate',
      <Object>['linear'],
      <Object>['get', 'value'],
      0.0,
      0.35,
      3.4,
      0.42,
      8.0,
      0.52,
      13.9,
      0.65,
      32.7,
      0.85,
    ],
    11,
    <Object>[
      'interpolate',
      <Object>['linear'],
      <Object>['get', 'value'],
      0.0,
      0.70,
      3.4,
      0.85,
      8.0,
      1.05,
      13.9,
      1.30,
      32.7,
      1.70,
    ],
  ];

  /// The speed key, strongest first — the same buckets the arrows are coloured
  /// by, drawn with the same glyph so the legend matches the map.
  ///
  /// [withUnit] appends the unit to the top row: a host that renders these
  /// inside a shared symbol block (the radar echo's chrome legend) has nowhere
  /// else to say what the numbers are, while the 風向 layer's own card prints
  /// the unit under the list and must not say it twice.
  static List<SymbolLegendItem> legendItems(
    BuildContext context, {
    bool withUnit = false,
  }) {
    // Corrected here, exactly as [windBuckets] is at its own definition: the
    // arrows are app-drawn glyphs, so the key follows the setting with them.
    final rows = <(String, String)>[
      ('≥ 32.7', '#FF006B'.vision),
      ('13.9 – 32.6', '#8000FF'.vision),
      ('8.0 – 13.8', '#0085FF'.vision),
      ('3.4 – 7.9', '#00FFF0'.vision),
      ('0.1 – 3.3', '#FFFFFF'.vision),
    ];
    final outline = Theme.of(context).colorScheme.outline;
    return [
      for (final (index, (label, hex)) in rows.indexed)
        SymbolLegendItem(
          // The arrow carries the same black outline as the map; the dark disc
          // behind pale / white glyphs keeps them readable on the frosted card.
          swatch: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: outline.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: WindArrowIcon(
              size: 14,
              outline: 1.5,
              color: colorFromHexRgb(hex) ?? Colors.white,
            ),
          ),
          label: withUnit && index == 0 ? '$label $unit' : label,
        ),
    ];
  }

  /// Registers the frame set (Unix-second ids, chronological) and warms the
  /// newest few so the first show is instant.
  Future<void> prepare(
    MapLibreMapController controller,
    List<String> frameIds,
  ) async {
    _orderedIds = List<String>.of(frameIds);
    _indexById = {
      for (var i = 0; i < _orderedIds.length; i++) _orderedIds[i]: i,
    };
    await _ensureImages(controller);
    await _ensureStations();
    await _ensureSource(controller);
    if (_orderedIds.isNotEmpty) {
      await _fetchIntoCache(_orderedIds.last);
      final start = _orderedIds.length > 3 ? _orderedIds.length - 3 : 0;
      for (var i = start; i < _orderedIds.length - 1; i++) {
        unawaited(_fetchIntoCache(_orderedIds[i]));
      }
    }
  }

  /// Draws [frameId]'s arrows.
  Future<void> show(
    MapLibreMapController controller,
    String frameId, {
    bool scrubbing = false,
  }) async {
    // Same frame already on screen — a scrub settle re-shows the same frame.
    // The cache check matters: a failed fetch leaves [_shownFrameId] set (with
    // an empty payload on screen), and the data may land in the cache later —
    // that frame must still be (re)shown.
    if (_shownFrameId == frameId && _cache.containsKey(frameId)) return;
    await _ensureImages(controller);
    await _ensureStations();
    await _ensureSource(controller);

    var snapshot = _cache[frameId];
    if (snapshot == null) {
      if (scrubbing) return;
      snapshot = await _fetchIntoCache(frameId);
      if (snapshot == null) {
        try {
          await controller.setGeoJsonSource(_sourceId, _empty);
        } catch (_) {}
        _shownFrameId = frameId;
        return;
      }
    }

    try {
      await controller.setGeoJsonSource(_sourceId, _geoJson(snapshot));
      _shownFrameId = frameId;
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'wind arrows show $frameId');
    }

    if (!scrubbing) {
      final i = _indexById[frameId];
      if (i != null) {
        for (final j in [i - 1, i + 1]) {
          if (j >= 0 && j < _orderedIds.length) {
            unawaited(_fetchIntoCache(_orderedIds[j]));
          }
        }
      }
    }
  }

  /// Mounts the layer with no arrows on it — for a host whose current frame has
  /// no observation snapshot near enough to be honest about. Clearing the
  /// features rather than removing the layer keeps "the overlay is on, there is
  /// nothing to draw" distinct from "the overlay is off".
  Future<void> showEmpty(MapLibreMapController controller) async {
    await _ensureImages(controller);
    await _ensureSource(controller);
    _shownFrameId = null;
    try {
      await controller.setGeoJsonSource(_sourceId, _empty);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'wind arrows clear features');
    }
  }

  Future<void> clear(MapLibreMapController controller) async {
    await _removeFromMap(controller);
    _mounted = false;
    _shownFrameId = null;
  }

  void onStyleReset() {
    _mounted = false;
    _imagesReady = false;
    _shownFrameId = null;
  }

  Future<WeatherSnapshot?> _fetchIntoCache(String frameId) async {
    final existing = _cache[frameId];
    if (existing != null) return existing;
    final sec = int.tryParse(frameId);
    if (sec == null) return null;
    final result = await _repository.at(sec);
    return result.when(
      ok: (snapshot) {
        _cache[frameId] = snapshot;
        // Bound memory — keep ~40 frames: drop the oldest (ids are Unix
        // seconds), never the frame that is on screen.
        if (_cache.length > 40) {
          final ids = _cache.keys.toList(growable: false)
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
          for (final id in ids.take(_cache.length - 40)) {
            if (id != _shownFrameId) _cache.remove(id);
          }
        }
        return snapshot;
      },
      err: (failure) {
        Log.warning('wind arrows frame $frameId: ${failure.message}');
        return null;
      },
    );
  }

  /// The station directory — the arrows' geometry. Fetched once; left empty on
  /// failure so the next frame retries rather than pinning an empty map.
  Future<void> _ensureStations() async {
    if (_stations.isNotEmpty) return;
    final result = await _repository.stations();
    result.when(
      ok: (stations) => _stations = stations,
      err: (failure) => Log.warning('wind arrows stations: ${failure.message}'),
    );
  }

  Future<void> _ensureImages(MapLibreMapController controller) async {
    if (_imagesReady && _imagesVision == AppColorVision.current) return;
    _imagesVision = AppColorVision.current;
    try {
      await registerImages(controller);
      _imagesReady = true;
    } catch (error, stackTrace) {
      // Style reload may leave images; retry next show.
      Log.handle(error, stackTrace, 'wind arrow addImage');
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
        // The image is picked by speed, carrying the pre-baked colour + black
        // outline — no `iconColor` tint, which would replace the baked-in
        // outline on a non-SDF image.
        iconImage: iconExpression(),
        iconRotate: <Object>['get', 'blow_to'],
        iconSize: sizeExpression(),
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        // Rotate with the map so a bearing stays geographically correct.
        iconRotationAlignment: 'map',
      ),
      enableInteraction: false,
    );
    _mounted = true;
  }

  /// One point per station that reported both a speed and a direction — a
  /// direction-less reading has no arrow to draw, and drawing it pointing north
  /// would be an invented bearing.
  Map<String, dynamic> _geoJson(WeatherSnapshot snapshot) {
    final features = <Map<String, dynamic>>[];
    for (final observation in snapshot.stations) {
      final station = _stations[observation.id];
      final speed = observation.windSpeed;
      final from = observation.windDirection;
      if (station == null || speed == null || from == null) continue;
      features.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [station.longitude, station.latitude],
        },
        'properties': {
          'id': observation.id,
          'value': speed,
          // Meteorological "from" + 180° = where the wind blows toward, which
          // is the way the glyph points.
          'blow_to': (from + 180) % 360,
        },
      });
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// Renders [Icons.navigation] (points north at 0°) as one PNG per speed
  /// bucket: each is the bucket colour with a black offset-outline baked in, so
  /// the arrow silhouette stays readable over pale tiles and bright echo.
  ///
  /// These are plain bitmaps — **not** SDF. MapLibre's SDF halos only work on
  /// true signed-distance-field images (which require a blurred source), and
  /// treating this glyph as one made `icon-halo-width` paint ~nothing.
  static Future<List<Uint8List>> _bakeArrows() async {
    // 96 px base so iconSize ≈ 0.5–1.5 reads as a clear arrow (48 px + the old
    // 0.18 floors was sub-10 px on calm stations).
    const size = 96;
    const icon = Icons.navigation;
    // Outline thickness on the 96 px canvas — 8 offset copies around the glyph.
    const halo = 5.5;
    final glyph = String.fromCharCode(icon.codePoint);
    final outline = _painter(glyph, icon, const Color(0xFF000000).vision);
    final center = Offset(
      (size - outline.width) / 2,
      (size - outline.height) / 2,
    );
    return [
      for (final (_, fill) in windBuckets)
        await _bakeOne(
          outline,
          _painter(glyph, icon, fill),
          center: center,
          size: size,
          halo: halo,
        ),
    ];
  }

  static TextPainter _painter(String glyph, IconData icon, Color color) =>
      TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: glyph,
          style: TextStyle(
            fontSize: 80,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: color,
          ),
        ),
      )..layout();

  static Future<Uint8List> _bakeOne(
    TextPainter outline,
    TextPainter fill, {
    required Offset center,
    required int size,
    required double halo,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    for (final (dx, dy) in windOutlineDirs) {
      outline.paint(canvas, center + Offset(dx * halo, dy * halo));
    }
    fill.paint(canvas, center);
    // Dispose the picture and image on the way out — the bakes run again on
    // every colour-vision change, and both native handles leaked otherwise.
    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    picture.dispose();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
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
