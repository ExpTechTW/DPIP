/// The wind layer — rotated arrows pointing where the wind blows toward,
/// coloured by wind speed (legacy look). The tap reading carries the exact
/// degrees + an 8-point arrow.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

class WindMapLayer extends WeatherStationLayer {
  WindMapLayer(super.repository);

  /// Shared arrow image id (registered once per render) and the arrow layer id.
  static const String _arrowImageId = 'wind-arrow';
  String get _arrowLayerId => 'wx-$id-arrow';

  /// The rendered arrow PNG, cached — the glyph never changes; its colour and
  /// rotation are applied at runtime by the layer, not baked into the image.
  Uint8List? _arrowBytes;

  @override
  String get id => 'wind';

  @override
  IconData get icon => Icons.air;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerWind;

  @override
  String get unit => 'm/s';

  @override
  int get decimals => 1;

  @override
  double? valueOf(WeatherObservation observation) => observation.windSpeed;

  @override
  List<double?> trendOf(WeatherTrend trend) => trend.windSpeed;

  // Arrows replace the dots (legacy) — the direction is the whole point.
  @override
  bool get drawCircle => false;

  @override
  List<String> get extraLayerIds => [_arrowLayerId];

  /// A `blow_to` bearing for stations that report a direction (meteorological
  /// "from" + 180° = where the wind blows toward); direction-less stations get
  /// no key and so are filtered out of the arrow layer.
  @override
  Map<String, Object?> extraProperties(WeatherObservation observation) {
    final from = observation.windDirection;
    if (from == null) return const {};
    return {'blow_to': (from + 180) % 360};
  }

  @override
  Future<void> decorate(
    MapLibreMapController controller,
    String sourceId,
  ) async {
    final bytes = _arrowBytes ??= await _renderArrow();
    // sdf: true so `iconColor` can tint the white glyph by wind speed.
    await controller.addImage(_arrowImageId, bytes, true);
    await controller.addSymbolLayer(
      sourceId,
      _arrowLayerId,
      SymbolLayerProperties(
        iconImage: _arrowImageId,
        iconRotate: <Object>['get', 'blow_to'],
        iconColor: _colorExpression(),
        iconSize: <Object>[
          'interpolate',
          <Object>['linear'],
          <Object>['zoom'],
          5,
          0.4,
          11,
          0.8,
        ],
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        // Rotate with the map so a bearing stays geographically correct.
        iconRotationAlignment: 'map',
      ),
      filter: <Object>['has', 'blow_to'],
    );
  }

  /// The speed colour ramp as a MapLibre `interpolate` on `value` — the same
  /// stops the base dot would use, reused here to tint the arrows.
  List<Object> _colorExpression() => <Object>[
    'interpolate',
    <Object>['linear'],
    <Object>['get', 'value'],
    for (final (at, color) in colorStops) ...[at, color],
  ];

  /// Renders [Icons.navigation] (points north at 0°) to a white PNG for use as
  /// an SDF icon: MapLibre tints it via `iconColor` and spins it via
  /// `iconRotate`, so one image serves every speed and bearing.
  Future<Uint8List> _renderArrow() async {
    const size = 48;
    const icon = Icons.navigation;
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 40,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    )..layout();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(
      canvas,
      Offset((size - painter.width) / 2, (size - painter.height) / 2),
    );
    final image = await recorder.endRecording().toImage(size, size);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  /// Speed reading plus the direction it blows from (degrees + 8-point arrow).
  @override
  String? reading(String id) {
    final observation = observationOf(id);
    final speed = observation?.windSpeed;
    if (speed == null) return null;
    final text = '${speed.toStringAsFixed(decimals)} $unit';
    final direction = observation!.windDirection;
    if (direction == null) return text;
    return '$text  $direction° ${_arrow(direction)}';
  }

  /// The arrow the wind blows *towards* (meteorological direction is where it
  /// comes from, so + 180°), snapped to 8 points.
  static String _arrow(int fromDegrees) {
    const arrows = ['↓', '↙', '←', '↖', '↑', '↗', '→', '↘'];
    final index = ((fromDegrees % 360) / 45).round() % 8;
    return arrows[index];
  }

  @override
  List<(double, String)> get colorStops => const [
    (0, '#ABD9E9'),
    (5, '#FFFFBF'),
    (10, '#FDAE61'),
    (17, '#F46D43'),
    (25, '#D73027'),
  ];
}
