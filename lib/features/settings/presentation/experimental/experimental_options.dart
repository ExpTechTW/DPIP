/// The registry of Experimental features options — the one list the page is
/// built from.
///
/// Adding an option is one entry here (plus its tile). Its category decides
/// the section, `platforms` where it is offered, `requiredSensors` which
/// hardware the device must have, and `requiresUnlock` whether it waits for
/// the Developer page's version-row unlock. Order within a category is the
/// order below; the categories' order is [ExperimentalCategory]'s.
library;

import 'package:dpip/core/platform/device_sensors.dart';
import 'package:dpip/features/settings/presentation/experimental/backdrop_options.dart';
import 'package:dpip/features/settings/presentation/experimental/experimental_option.dart';
import 'package:dpip/features/settings/presentation/experimental/seismometer_option.dart';
import 'package:material_ui/material_ui.dart';

/// Every option, in page order within its category.
const List<ExperimentalOption> experimentalOptions = [
  ExperimentalOption(
    category: ExperimentalCategory.graphics,
    platforms: everyPlatform,
    requiresUnlock: true,
    build: _weatherMode,
  ),
  ExperimentalOption(
    category: ExperimentalCategory.graphics,
    platforms: everyPlatform,
    requiresUnlock: true,
    build: _skyTime,
  ),
  // The accelerometer stream it reads exists only on the phones, and only on
  // a phone that has an accelerometer.
  ExperimentalOption(
    category: ExperimentalCategory.tools,
    platforms: {TargetPlatform.android, TargetPlatform.iOS},
    requiredSensors: {DeviceSensor.accelerometer},
    build: _seismometer,
  ),
];

Widget _weatherMode(BuildContext context, ExperimentalHost host) =>
    WeatherModeOption(watchWeatherCode: host.watchWeatherCode);

Widget _skyTime(BuildContext context, ExperimentalHost host) =>
    const SkyTimeOption();

Widget _seismometer(BuildContext context, ExperimentalHost host) =>
    const SeismometerOption();
