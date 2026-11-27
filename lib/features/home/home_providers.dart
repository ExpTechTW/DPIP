import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_sync.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/features/weather/domain/weather_realtime.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

typedef CurrentWeatherWidgetPublish = Future<void> Function({
  required String regionCode,
  required WeatherRealtime weather,
});

/// Whether this platform has a home-screen Widget fed by the app's own Home
/// selection.
///
/// iOS and Android both do; the writer each one is given decides how the
/// snapshot reaches the platform, and the Home controller does not care which.
bool _hasHomeScreenWidget(TargetPlatform platform) =>
    platform == TargetPlatform.iOS || platform == TargetPlatform.android;

/// Adapts the home controller callback to the Widget coordinator.
///
/// There is deliberately no counterpart that clears on a selection change.
/// Both platforms cache one snapshot per configured target, and each widget
/// refreshes its own target natively. iOS used to clear the whole kind here,
/// which blanked every *other* widget — a saved town, or Current Location —
/// each time the app started or Home switched towns, until that widget's own
/// background refresh happened to succeed.
@visibleForTesting
RealtimeWeatherLoadedCallback? createCurrentWeatherWidgetCallback({
  required TargetPlatform platform,
  required CurrentWeatherWidgetPublish publish,
}) {
  if (!_hasHomeScreenWidget(platform)) return null;

  return (regionCode, weather) =>
      publish(regionCode: regionCode, weather: weather);
}

/// Home providers: sheet-extent chrome, tab-reset, map hand-offs, weather
/// (header + forecast), and active-events (collapsed sheet) — the latter reads
/// [EventRepository] from `eventsProviders`.
List<SingleChildWidget> homeProviders() => [
  ChangeNotifierProvider(create: (_) => HomeSheetExtent()),
  ChangeNotifierProvider(create: (_) => HomeResetSignal()),
  ChangeNotifierProvider(create: (_) => MapCameraHandoff()),
  ChangeNotifierProvider(create: (_) => MapStationHandoff()),
  ChangeNotifierProvider<HomeWeatherController>(
    create: (context) {
      final regions = context.read<RegionStore>();
      final directory = context.read<TownDirectory>();
      final widgetSync = context.read<CurrentWeatherWidgetSync>();

      return HomeWeatherController(
        context.read<MeteorWeatherRepository>(),
        context.read<RainHourTrendRepository>(),
        regions,
        directory,
        gpsFix: context.read<LocationService>().currentFix,
        onRealtimeLoaded: createCurrentWeatherWidgetCallback(
          platform: defaultTargetPlatform,
          publish: widgetSync.publish,
        ),
      );
    },
  ),
  ChangeNotifierProvider<HomeActiveEventsController>(
    create: (context) => HomeActiveEventsController(
      context.read<EventRepository>(),
      context.read<RegionStore>(),
    ),
  ),
];
