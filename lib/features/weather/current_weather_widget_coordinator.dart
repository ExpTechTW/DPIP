import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/core/settings/home_area.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/core/weather/solar_time.dart';
import 'package:dpip/features/weather/data/current_weather_widget_publisher.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_snapshot.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_sync.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';

typedef CurrentWeatherWidgetTime = ({
  DateTime calibratedNow,
  Duration calibratedTimeOffset,
});

CurrentWeatherWidgetTime _appTime() => (
  calibratedNow: AppTime.utc,
  calibratedTimeOffset: AppTime.calibratedTimeOffset,
);

bool _isAppTimeSynced() => AppTime.isSynced;

Future<void> _syncAppTime() => AppTime.sync();

final class CurrentWeatherWidgetCoordinator
    implements CurrentWeatherWidgetSync {
  CurrentWeatherWidgetCoordinator(
    RegionStore regions,
    TownDirectory directory,
    CurrentWeatherWidgetPublisher publisher, {
    CurrentWeatherWidgetTime Function() time = _appTime,
    bool Function() isTimeSynced = _isAppTimeSynced,
    Future<void> Function() syncTime = _syncAppTime,
  }) : this._withTime(
         regions,
         directory,
         publisher,
         time,
         isTimeSynced,
         syncTime,
       );

  CurrentWeatherWidgetCoordinator._withTime(
    this._regions,
    this._directory,
    this._publisher,
    this._time,
    this._isTimeSynced,
    this._syncTime,
  );

  final RegionStore _regions;
  final TownDirectory _directory;
  final CurrentWeatherWidgetPublisher _publisher;
  final CurrentWeatherWidgetTime Function() _time;
  final bool Function() _isTimeSynced;
  final Future<void> Function() _syncTime;

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

    if (!_isTimeSynced()) {
      await _syncTime();
      if (!_isTimeSynced()) {
        return;
      }

      // The selected region may have changed while clock synchronization was
      // pending. A late callback must not publish for the old selection.
      if (_regions.selectedCode != regionCode) {
        return;
      }
    }

    // Both values are sampled only after the first successful sync, so schema
    // v4 never encodes unsynchronized device time as calibrated time.
    final time = _time();
    final now = time.calibratedNow;

    final isNight = isNightAt(now, latitude: town.lat, longitude: town.lng);

    final nextTransition = nextDayNightTransitionAt(
      now,
      latitude: town.lat,
      longitude: town.lng,
    );

    final sourceIdentifier = switch (_regions.selected) {
      CurrentArea(:final code) when code == regionCode => 'current-location',
      SavedArea(:final code) when code == regionCode => 'region:$code',
      _ => null,
    };

    if (sourceIdentifier == null) {
      return;
    }

    final snapshot = createCurrentWeatherWidgetSnapshot(
      sourceIdentifier: sourceIdentifier,
      regionCode: regionCode,
      regionName: town.townName,
      weather: weather,
      isNight: isNight,
      nextDayNightTransitionTime: nextTransition.millisecondsSinceEpoch ~/ 1000,
      calibratedTimeOffsetMilliseconds:
          time.calibratedTimeOffset.inMilliseconds,
    );

    await _publisher.publish(snapshot);
  }

  @override
  Future<void> clear() async {
    await _publisher.clear();
  }
}
