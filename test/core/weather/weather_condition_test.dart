import 'package:dpip/core/settings/weather_mode.dart';
import 'package:dpip/core/weather/weather_condition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const colors = ColorScheme.light();

  group('weatherModeFor', () {
    test('plain families map clear / cloudy / overcast', () {
      expect(weatherModeFor(100), WeatherMode.clear);
      expect(weatherModeFor(200), WeatherMode.cloudy);
      expect(weatherModeFor(300), WeatherMode.overcast);
    });

    test('phenomenon ones digit wins over the family sky', () {
      expect(weatherModeFor(106), WeatherMode.rain);
      expect(weatherModeFor(214), WeatherMode.thunderstorm);
      expect(weatherModeFor(308), WeatherMode.snow);
      expect(weatherModeFor(105), WeatherMode.fog);
    });

    test('0 and unknown families fall back to auto', () {
      expect(weatherModeFor(0), WeatherMode.auto);
      expect(weatherModeFor(400), WeatherMode.auto);
    });
  });

  group('intensity channels', () {
    test('rain intensity scales with the phenomenon', () {
      expect(weatherRainIntensity(106), 0.35); // 有雨
      expect(weatherRainIntensity(111), 0.35); // 有陣雨
      expect(weatherRainIntensity(114), 0.70); // 有雷雨
      expect(weatherRainIntensity(117), 1.00); // 大雷雨
      expect(weatherRainIntensity(119), 0.15); // 有雷 — lightning only
    });

    test('rain-free codes carry no rain intensity', () {
      expect(weatherRainIntensity(100), isNull);
      expect(weatherRainIntensity(105), isNull); // 有霧
      expect(weatherRainIntensity(0), isNull);
    });

    test('snow intensity distinguishes heavy from light', () {
      expect(weatherSnowIntensity(108), 1.0); // 有大雪
      expect(weatherSnowIntensity(109), 0.5); // 有雪珠
      expect(weatherSnowIntensity(106), isNull); // 有雨
    });
  });

  group('weatherVisual', () {
    test('code phenomenon drives the icon regardless of the label', () {
      // 200 有雷雨 — the code, not the 多雲 label, picks the storm.
      expect(weatherVisual('多雲', 214, colors).$1, Icons.thunderstorm_outlined);
      expect(weatherVisual('晴', 106, colors).$1, Icons.water_drop_outlined);
      expect(weatherVisual('陰', 208, colors).$1, Icons.ac_unit_outlined);
      expect(weatherVisual('晴', 105, colors).$1, Icons.blur_on_outlined);
    });

    test('plain family codes map clear / cloudy / overcast', () {
      expect(weatherVisual('晴', 100, colors).$1, Icons.wb_sunny_outlined);
      expect(weatherVisual('多雲', 200, colors).$1, Icons.wb_cloudy_outlined);
      expect(weatherVisual('陰', 300, colors).$1, Icons.cloud_outlined);
    });

    test('a missing code falls back to substring matching', () {
      expect(weatherVisual('午後雷陣雨', 0, colors).$1, Icons.thunderstorm_outlined);
      expect(weatherVisual('短暫雨', 0, colors).$1, Icons.water_drop_outlined);
      expect(weatherVisual('雪', 0, colors).$1, Icons.ac_unit_outlined);
      expect(weatherVisual('晴時多雲', 0, colors).$1, Icons.wb_sunny_outlined);
      expect(weatherVisual('多雲', 0, colors).$1, Icons.cloud_outlined);
    });
  });
}
