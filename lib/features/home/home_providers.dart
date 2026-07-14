import 'package:dpip/core/geo/town_directory.dart';
import 'package:dpip/core/settings/region_store.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/features/home/presentation/home_sheet_extent.dart';
import 'package:dpip/features/home/presentation/home_weather_controller.dart';
import 'package:dpip/features/weather/domain/meteor_weather_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Home providers: the sheet-extent broadcast (drives the immersive chrome), the
/// tab-reset signal, and the header weather controller (follows the selected
/// area, reading the meteor weather repository `weatherProviders` provides).
List<SingleChildWidget> homeProviders() => [
  ChangeNotifierProvider(create: (_) => HomeSheetExtent()),
  ChangeNotifierProvider(create: (_) => HomeResetSignal()),
  ChangeNotifierProvider<HomeWeatherController>(
    create: (context) => HomeWeatherController(
      context.read<MeteorWeatherRepository>(),
      context.read<RegionStore>(),
      context.read<TownDirectory>(),
    ),
  ),
];
