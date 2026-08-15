/// The air-temperature station layer.
library;

import 'package:dpip/core/a11y/color_vision.dart';
import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class TemperatureMapLayer
    extends
        WeatherStationLayer<WeatherSnapshot, WeatherObservation, WeatherTrend> {
  TemperatureMapLayer(super.repository);

  @override
  String get id => 'temperature';

  @override
  IconData get icon => Icons.thermostat_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerTemperature;

  @override
  String get unit => '°C';

  @override
  int get decimals => 1;

  @override
  double? valueOf(WeatherObservation observation) => observation.temperature;

  @override
  List<double?> trendOf(WeatherTrend trend) => trend.temperature;

  @override
  List<(double, String)> get colorStops => [
    (-5, '#4575B4'.vision),
    (5, '#74ADD1'.vision),
    (15, '#ABD9E9'.vision),
    (22, '#FFFFBF'.vision),
    (28, '#FDAE61'.vision),
    (34, '#F46D43'.vision),
    (40, '#D73027'.vision),
  ];
}
