import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/weather/data/meteor_lightning_api.dart';
import 'package:dpip/features/weather/data/meteor_lightning_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_rain_api.dart';
import 'package:dpip/features/weather/data/meteor_rain_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_weather_api.dart';
import 'package:dpip/features/weather/data/meteor_weather_repository_impl.dart';
import 'package:dpip/features/weather/data/radar_api.dart';
import 'package:dpip/features/weather/data/radar_repository_impl.dart';
import 'package:dpip/features/weather/data/satellite_api.dart';
import 'package:dpip/features/weather/data/satellite_repository_impl.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Weather providers: radar / satellite overlays, meteor weather / rain /
/// lightning.
///
/// Radar and satellite get **their own** warmer: cancelling one layer's warm on
/// a layer switch must not abandon the other's. A null tile cache (the DB
/// wouldn't open) degrades to a no-op warmer, never a failed launch.
List<SingleChildWidget> weatherProviders(SharedDeps deps) {
  return [
    Provider<RadarRepository>.value(
      value: RadarRepositoryImpl(
        RadarApi(deps.apiClient),
        deps.mapTileWarmer(),
      ),
    ),
    Provider<SatelliteRepository>.value(
      value: SatelliteRepositoryImpl(
        SatelliteApi(deps.apiClient),
        deps.mapTileWarmer(),
      ),
    ),
    Provider<MeteorWeatherRepository>.value(
      value: MeteorWeatherRepositoryImpl(MeteorWeatherApi(deps.apiClient)),
    ),
    Provider<MeteorRainRepository>.value(
      value: MeteorRainRepositoryImpl(MeteorRainApi(deps.apiClient)),
    ),
    Provider<MeteorLightningRepository>.value(
      value: MeteorLightningRepositoryImpl(MeteorLightningApi(deps.apiClient)),
    ),
  ];
}
