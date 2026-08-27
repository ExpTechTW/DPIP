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
        // The origin publishes z3–12. At three Taiwan locations and three
        // content-rich frames, z11 overzoom versus native z12 stayed visually
        // near-identical (median SSIM 0.963, MAE 1.42/255), so stop at z11.
        maxZoom: 11,
        minZoom: 3,
      ),
    ),
    Provider<QpesumsRepository>.value(
      value: FrameTileRepositoryImpl(
        FrameTileApi(deps.apiClient, 'qpesums'),
        deps.mapTileWarmer(),
        // Also publishes z3–12; z11 overzoom versus z12 measured median SSIM
        // 0.980 and MAE 0.89/255, so z12 is not worth another request level.
        maxZoom: 11,
        minZoom: 3,
      ),
    ),
    Provider<SatelliteRepository>.value(
      value: FrameTileRepositoryImpl(
        FrameTileApi(deps.apiClient, 'satellite'),
        deps.mapTileWarmer(),
        // Every satellite product and colour style keeps the complete
        // published z0–11 pyramid.
        maxZoom: 11,
      ),
    ),
    // One repository per channel the satellite layer picker offers — each needs
    // its own channel path on both the frame list and every tile URL, and its
    // own warmer so switching channels never abandons another channel's warm.
    Provider<Map<SatelliteChannel, SatelliteRepository>>.value(
      value: {
        for (final channel in SatelliteChannel.values)
          channel: FrameTileRepositoryImpl(
            FrameTileApi(deps.apiClient, 'satellite', channel: channel.key),
            deps.mapTileWarmer(),
            maxZoom: 11,
          ),
      },
    ),
    // One repository per wind forecast model — each needs its own model path
    // on both the frame list and every tile URL, and its own warmer. Both
    // model endpoints publish z0–11. At three Taiwan locations across three
    // cycle positions, z6 overzoom versus native z11 measured SSIM >= 0.986 at
    // p10 for both 0.25° models; z5 still changed visibly. Stop at useful z6.
    Provider<Map<WindForecastModel, WindForecastRepository>>.value(
      value: {
        for (final model in WindForecastModel.values)
          model: FrameTileRepositoryImpl(
            FrameTileApi(deps.apiClient, 'wind', model: model.key),
            deps.mapTileWarmer(),
            maxZoom: 6,
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
