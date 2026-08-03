/// The relative-humidity station layer.
library;

import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class HumidityMapLayer extends WeatherStationLayer {
  HumidityMapLayer(super.repository);

  @override
  String get id => 'humidity';

  @override
  IconData get icon => Icons.water_drop_outlined;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerHumidity;

  @override
  String get unit => '%';

  @override
  int get decimals => 0;

  @override
  double? get chartMinY => 0;

  @override
  double? get chartMaxY => 100;

  @override
  double? valueOf(WeatherObservation observation) =>
      observation.humidity?.toDouble();

  @override
  List<double?> trendOf(WeatherTrend trend) => [
    for (final value in trend.humidity) value?.toDouble(),
  ];

  @override
  List<(double, String)> get colorStops => const [
    (0, '#B45309'),
    (30, '#FDAE61'),
    (50, '#FFFFBF'),
    (70, '#ABD9E9'),
    (90, '#74ADD1'),
    (100, '#4575B4'),
  ];
}
