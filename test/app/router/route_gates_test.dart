/// The refresh behind the gated routes. The routes themselves are driven
/// through the real route table in `app_router_test.dart`.
library;

import 'package:dpip/app/router/route_gates.dart';
import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fires on a flip of the seismometer switch and nothing else', () async {
    final settings = ExperimentalSettings(SettingsStore.inMemory());
    final refresh = RouteGateRefresh()..watch(settings);
    var fired = 0;
    refresh.addListener(() => fired++);

    // Each refresh re-parses the location on screen, so the other options on
    // the same page must not cause one.
    settings.weatherMode = WeatherMode.rain;
    settings.skyTimeMode = SkyTimeMode.night;
    await settings.unlock();
    expect(fired, 0);

    await settings.setSeismometerEnabled(true);
    expect(fired, 1);
    await settings.setSeismometerEnabled(false);
    expect(fired, 2);
  });

  test('follows only the settings it was last pointed at', () async {
    final first = ExperimentalSettings(SettingsStore.inMemory());
    final second = ExperimentalSettings(SettingsStore.inMemory());
    final refresh = RouteGateRefresh()..watch(first);
    var fired = 0;
    refresh.addListener(() => fired++);

    refresh.watch(second);
    await first.setSeismometerEnabled(true);
    expect(fired, 0);
    await second.setSeismometerEnabled(true);
    expect(fired, 1);
  });
}
