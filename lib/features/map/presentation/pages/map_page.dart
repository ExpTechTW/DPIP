import 'package:dpip/core/realtime/realtime_notifier.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/features/map/presentation/layers/humidity_layer.dart';
import 'package:dpip/features/map/presentation/layers/pressure_layer.dart';
import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/map/presentation/layers/rts_layer.dart';
import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/map/presentation/layers/temperature_layer.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/map/presentation/layers/wind_layer.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_scaffold.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen map tab.
///
/// Just business logic now: it names the layers this surface offers and hands
/// them to [MapScaffold], which owns the map, the layer switcher, and the
/// timeline. Adding radar/rain/lightning/… later is one more entry in [_layers].
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Built once so each layer keeps its own MapLibre state across rebuilds.
  late final List<MapLayer> _layers = [
    RadarMapLayer(context.read<RadarRepository>()),
    SatelliteMapLayer(context.read<SatelliteRepository>()),
    TyphoonMapLayer(
      context.read<MeteorTyphoonRepository>(),
      radar: context.read<RadarRepository>(),
      satellite: context.read<SatelliteRepository>(),
    ),
    RtsMapLayer(
      context.read<RealtimeNotifier<Rts>>(),
      context.read<TremStationRepository>(),
    ),
    TemperatureMapLayer(context.read<MeteorWeatherRepository>()),
    HumidityMapLayer(context.read<MeteorWeatherRepository>()),
    PressureMapLayer(context.read<MeteorWeatherRepository>()),
    WindMapLayer(context.read<MeteorWeatherRepository>()),
  ];

  @override
  Widget build(BuildContext context) => MapScaffold(layers: _layers);
}
