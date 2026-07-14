import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/features/weather/data/meteor_weather_api.dart';
import 'package:dpip/features/weather/data/meteor_weather_repository_impl.dart';
import 'package:dpip/features/weather/data/radar_api.dart';
import 'package:dpip/features/weather/data/radar_repository_impl.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Weather providers: the radar overlay repository and the meteor v5 weather
/// repository. (Rain / lightning / typhoon repositories are provided as their
/// screens land; the home-header weather controller lives in the home feature.)
List<SingleChildWidget> weatherProviders(SharedDeps deps) => [
  Provider<RadarRepository>.value(
    value: RadarRepositoryImpl(RadarApi(deps.apiClient)),
  ),
  Provider<MeteorWeatherRepository>.value(
    value: MeteorWeatherRepositoryImpl(MeteorWeatherApi(deps.apiClient)),
  ),
];
