import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:dpip/shared/map/map_station_handoff.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Home providers: the sheet-extent broadcast (drives the immersive chrome), the
/// tab-reset signal, the home→map camera hand-off (shared with the map tab), and
/// the header weather controller (follows the selected area, reading the meteor
/// weather repository `weatherProviders` provides).
List<SingleChildWidget> homeProviders() => [
  ChangeNotifierProvider(create: (_) => HomeSheetExtent()),
  ChangeNotifierProvider(create: (_) => HomeResetSignal()),
  ChangeNotifierProvider(create: (_) => MapCameraHandoff()),
  ChangeNotifierProvider(create: (_) => MapStationHandoff()),
  ChangeNotifierProvider<HomeWeatherController>(
    create: (context) => HomeWeatherController(
      context.read<MeteorWeatherRepository>(),
      context.read<RegionStore>(),
      context.read<TownDirectory>(),
    ),
  ),
];
