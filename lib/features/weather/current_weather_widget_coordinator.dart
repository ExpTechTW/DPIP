import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/weather/data/current_weather_widget_publisher.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_snapshot.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_sync.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';

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

    final snapshot = createCurrentWeatherWidgetSnapshot(
      regionCode: regionCode,
      regionName: town.townName,
      weather: weather,
    );

    await _publisher.publish(snapshot);
  }

  @override
  Future<void> clear() async {
    await _publisher.clear();
  }
}
