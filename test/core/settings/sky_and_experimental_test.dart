import 'package:dpip/core/settings/experimental_settings.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each sky mode pins one hour, except auto', () {
    expect(skyTimeHour(SkyTimeMode.auto), isNull);
    expect(skyTimeHour(SkyTimeMode.dawn), 5);
    expect(skyTimeHour(SkyTimeMode.sunrise), 6);
    expect(skyTimeHour(SkyTimeMode.morning), 8.5);
    expect(skyTimeHour(SkyTimeMode.noon), 11.3);
    expect(skyTimeHour(SkyTimeMode.afternoon), 15);
    expect(skyTimeHour(SkyTimeMode.golden), 17.5);
    expect(skyTimeHour(SkyTimeMode.sunset), 18.4);
    expect(skyTimeHour(SkyTimeMode.dusk), 19.2);
    expect(skyTimeHour(SkyTimeMode.night), 1);
  });

  test('experimental settings persist a change and ignore a repeat', () async {
    final settings = ExperimentalSettings(SettingsStore.inMemory());
    expect(settings.unlocked, isFalse);
    expect(settings.weatherMode, WeatherMode.auto);
    expect(settings.skyTimeMode, SkyTimeMode.auto);

    var notified = 0;
    settings.addListener(() => notified++);
    await settings.unlock();
    settings.weatherMode = WeatherMode.rain;
    settings.skyTimeMode = SkyTimeMode.night;
    expect(settings.unlocked, isTrue);
    expect(settings.weatherMode, WeatherMode.rain);
    expect(settings.skyTimeMode, SkyTimeMode.night);
    expect(notified, 3);

    settings.weatherMode = WeatherMode.rain;
    settings.skyTimeMode = SkyTimeMode.night;
    expect(notified, 3);
  });
}
