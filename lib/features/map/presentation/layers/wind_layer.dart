/// The wind layer — station dots coloured by wind speed, the reading carries the
/// direction.
library;

import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class WindMapLayer extends WeatherStationLayer {
  WindMapLayer(super.repository);

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
