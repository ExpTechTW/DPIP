import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/weather/data/frame_tile_api.dart';
import 'package:dpip/features/weather/data/frame_tile_repository.dart';
import 'package:dpip/features/weather/data/meteor_lightning_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_rain_repository_impl.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_api.dart';
import 'package:dpip/features/weather/data/meteor_weather_api.dart';
import 'package:dpip/features/weather/data/meteor_weather_repository_impl.dart';
import 'package:dpip/features/weather/data/rain_hour_trend_api.dart';
import 'package:dpip/features/weather/data/rain_hour_trend_repository_impl.dart';
import 'package:dpip/features/weather/domain/meteor_lightning_repository.dart';
import 'package:dpip/features/weather/domain/meteor_rain_repository.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Weather providers: radar / satellite / QPESUMS overlays, meteor weather /
/// rain / lightning, the next-hour rain trend, and the wind forecast models.
///
/// The raster overlays each get **their own** warmer: cancelling one layer's
/// warm on a layer switch must not abandon the other's. A null tile cache (the
/// DB wouldn't open) degrades to a no-op warmer, never a failed launch.
List<SingleChildWidget> weatherProviders(SharedDeps deps) {
  return [
    Provider<RadarRepository>.value(
      value: FrameTileRepositoryImpl(
        FrameTileApi(deps.apiClient, 'radar'),
        deps.mapTileWarmer(),
      ),
    ),
    Provider<QpesumsRepository>.value(
      value: FrameTileRepositoryImpl(
        FrameTileApi(deps.apiClient, 'qpesums'),
        deps.mapTileWarmer(),
      ),
    ),
    Provider<SatelliteRepository>.value(
      value: FrameTileRepositoryImpl(
        FrameTileApi(deps.apiClient, 'satellite'),
        deps.mapTileWarmer(),
      ),
    ),
    // One repository per channel the satellite layer picker offers — each needs
    // its own `?channel=` on both the frame list and every tile URL, and its
    // own warmer so switching channels never abandons another channel's warm.
    Provider<Map<SatelliteChannel, SatelliteRepository>>.value(
      value: {
        for (final channel in SatelliteChannel.values)
          channel: FrameTileRepositoryImpl(
            FrameTileApi(deps.apiClient, 'satellite', channel: channel.key),
            deps.mapTileWarmer(),
          ),
      },
    ),
    // One repository per wind forecast model — each needs its own `?model=` on
    // both the frame list and every tile URL, and its own warmer. The 0.25°
    // grids stop publishing at z7.
    Provider<Map<WindForecastModel, WindForecastRepository>>.value(
      value: {
        for (final model in WindForecastModel.values)
          model: FrameTileRepositoryImpl(
            FrameTileApi(deps.apiClient, 'wind', model: model.key),
            deps.mapTileWarmer(),
            maxZoom: 7,
          ),
      },
    ),
    Provider<MeteorWeatherRepository>.value(
      value: MeteorWeatherRepositoryImpl(MeteorWeatherApi(deps.apiClient)),
    ),
    Provider<MeteorRainRepository>.value(
      value: MeteorRainRepositoryImpl(
        MeteorSnapshotApi(deps.apiClient, '/api/v5/meteor/rain'),
      ),
    ),
    Provider<MeteorLightningRepository>.value(
      value: MeteorLightningRepositoryImpl(
        MeteorSnapshotApi(deps.apiClient, '/api/v5/meteor/lightning'),
      ),
    ),
    Provider<RainHourTrendRepository>.value(
      value: RainHourTrendRepositoryImpl(RainHourTrendApi(deps.apiClient)),
    ),
  ];
}
