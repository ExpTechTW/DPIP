import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/weather/data/meteor_rain_api.dart';
import 'package:dpip/features/weather/data/meteor_rain_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_weather_api.dart';
import 'package:dpip/features/weather/data/meteor_weather_repository_impl.dart';
import 'package:dpip/features/weather/data/radar_api.dart';
import 'package:dpip/features/weather/data/radar_repository_impl.dart';
import 'package:dpip/features/weather/data/satellite_api.dart';
import 'package:dpip/features/weather/data/satellite_repository_impl.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/shared/map/ambient_prefetcher.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Weather providers: radar / satellite overlays, meteor weather + rain.
List<SingleChildWidget> weatherProviders(SharedDeps deps) => [
  Provider<RadarRepository>.value(
    value: RadarRepositoryImpl(
      RadarApi(deps.apiClient),
      AmbientPrefetcher(deps.apiClient),
    ),
  ),
  Provider<SatelliteRepository>.value(
    value: SatelliteRepositoryImpl(
      SatelliteApi(deps.apiClient),
      AmbientPrefetcher(deps.apiClient),
    ),
  ),
  Provider<MeteorWeatherRepository>.value(
    value: MeteorWeatherRepositoryImpl(MeteorWeatherApi(deps.apiClient)),
  ),
  Provider<MeteorRainRepository>.value(
    value: MeteorRainRepositoryImpl(MeteorRainApi(deps.apiClient)),
  ),
];
