import 'package:dpip/features/home/presentation/widgets/forecast_weather_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const colors = ColorScheme.light();

  test('rain / thunder / snow win over weatherCode hundreds', () {
    expect(
      forecastWeatherVisual('午後雷陣雨', 200, colors).$1,
      Icons.thunderstorm_outlined,
    );
    expect(
      forecastWeatherVisual('短暫雨', 200, colors).$1,
      Icons.water_drop_outlined,
    );
    expect(forecastWeatherVisual('雪', 100, colors).$1, Icons.ac_unit_outlined);
  });

  test('weatherCode hundreds map clear / cloudy / overcast', () {
    expect(
      forecastWeatherVisual('晴時多雲', 100, colors).$1,
      Icons.wb_sunny_outlined,
    );
    // "晴" substring wins before the hundreds switch — use a non-晴 label.
    expect(
      forecastWeatherVisual('多雲', 200, colors).$1,
      Icons.wb_cloudy_outlined,
    );
    expect(forecastWeatherVisual('陰', 300, colors).$1, Icons.cloud_outlined);
  });
}
