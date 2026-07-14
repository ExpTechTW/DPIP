/// The station-pressure layer.
library;

import 'package:dpip/features/map/presentation/layers/weather_station_layer.dart';
import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_trend.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

class PressureMapLayer extends WeatherStationLayer {
  PressureMapLayer(super.repository);

  @override
  String get id => 'pressure';

  @override
  IconData get icon => Icons.compress;

  @override
  String label(BuildContext context) =>
      AppLocalizations.of(context).mapLayerPressure;

  @override
  String get unit => 'hPa';

  @override
  int get decimals => 0;

  @override
  double? valueOf(WeatherObservation observation) => observation.pressure;

  @override
  List<double?> trendOf(WeatherTrend trend) => trend.pressure;

  @override
  List<(double, String)> get colorStops => const [
    (980, '#4575B4'),
    (1000, '#ABD9E9'),
    (1013, '#FFFFBF'),
    (1025, '#FDAE61'),
    (1040, '#D73027'),
  ];
}
