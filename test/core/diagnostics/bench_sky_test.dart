/// The sky bench pins a backdrop only in a frame-bench build, and a scene
/// file must beat the compile-time define so one APK can measure every state.
library;

import 'package:dpip/core/diagnostics/bench_sky.dart';
import 'package:dpip/core/diagnostics/frame_bench.dart';
import 'package:dpip/core/settings/sky_time_mode.dart';
import 'package:dpip/core/settings/weather_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the override is off unless the frame-bench define is set', () {
    expect(frameBenchEnabled, isFalse);
    expect(benchWeatherOr(WeatherMode.rain), WeatherMode.rain);
    expect(benchSkyTimeOr(SkyTimeMode.night), SkyTimeMode.night);
  });

  test('parseBenchSky prefers a valid scene file over the defines', () {
    final fromDefines = parseBenchSky(
      defineWeather: 'clear',
      defineSkyTime: 'noon',
    );
    expect(fromDefines.weather, WeatherMode.clear);
    expect(fromDefines.skyTime, SkyTimeMode.noon);

    final fromFile = parseBenchSky(
      defineWeather: 'clear',
      defineSkyTime: 'noon',
      fileText: 'thunderstorm night\n',
    );
    expect(fromFile.weather, WeatherMode.thunderstorm);
    expect(fromFile.skyTime, SkyTimeMode.night);

    final comma = parseBenchSky(fileText: 'RAIN,Noon');
    expect(comma.weather, WeatherMode.rain);
    expect(comma.skyTime, SkyTimeMode.noon);

    final junk = parseBenchSky(
      defineWeather: 'snow',
      defineSkyTime: 'noon',
      fileText: 'nope dusk',
    );
    expect(junk.weather, WeatherMode.snow);
    expect(junk.skyTime, SkyTimeMode.dusk);

    final absent = parseBenchSky();
    expect(absent.weather, isNull);
    expect(absent.skyTime, isNull);
  });
}
