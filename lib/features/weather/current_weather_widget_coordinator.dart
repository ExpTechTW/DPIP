import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/weather/data/current_weather_widget_publisher.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_snapshot.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_sync.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/weather/solar_time.dart';

final class CurrentWeatherWidgetCoordinator
    implements CurrentWeatherWidgetSync {
  CurrentWeatherWidgetCoordinator(
    this._regions,
    this._directory,
    this._publisher,
  );

  final RegionStore _regions;
  final TownDirectory _directory;
  final CurrentWeatherWidgetPublisher _publisher;

  @override
  Future<void> publish({
    required String regionCode,
    required WeatherRealtime weather,
  }) async {
    if (_regions.selectedCode != regionCode) {
      return;
    }

    final town = _directory.byCode(regionCode);

    if (town == null) {
      return;
    }

    final now = AppTime.utc;

    final isNight = isNightAt(now, latitude: town.lat, longitude: town.lng);

    final nextTransition = nextDayNightTransitionAt(
      now,
      latitude: town.lat,
      longitude: town.lng,
    );

    final snapshot = createCurrentWeatherWidgetSnapshot(
      regionCode: regionCode,
      regionName: town.townName,
      weather: weather,
      isNight: isNight,
      nextDayNightTransitionTime: nextTransition.millisecondsSinceEpoch ~/ 1000,
    );

    await _publisher.publish(snapshot);
  }

  @override
  Future<void> clear() async {
    await _publisher.clear();
  }
}
