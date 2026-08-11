import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:dpip/features/home/presentation/home_active_events_controller.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Home providers: sheet-extent chrome, tab-reset, map hand-offs, weather
/// (header + forecast), and active-events (collapsed sheet) — the latter reads
/// [EventRepository] from `eventsProviders`.
List<SingleChildWidget> homeProviders() => [
  ChangeNotifierProvider(create: (_) => HomeSheetExtent()),
  ChangeNotifierProvider(create: (_) => HomeResetSignal()),
  ChangeNotifierProvider(create: (_) => MapCameraHandoff()),
  ChangeNotifierProvider(create: (_) => MapStationHandoff()),
  ChangeNotifierProvider<HomeWeatherController>(
    create: (context) => HomeWeatherController(
      context.read<MeteorWeatherRepository>(),
      context.read<RainHourTrendRepository>(),
      context.read<RegionStore>(),
      context.read<TownDirectory>(),
      gpsFix: context.read<LocationService>().currentFix,
    ),
  ),
  ChangeNotifierProvider<HomeActiveEventsController>(
    create: (context) => HomeActiveEventsController(
      context.read<EventRepository>(),
      context.read<RegionStore>(),
    ),
  ),
];
