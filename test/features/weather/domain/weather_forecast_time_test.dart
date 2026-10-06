import 'package:dpip/features/weather/domain/weather_forecast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('update time is a millisecond epoch, read in UTC', () {
    final forecast = WeatherForecast(
      updateTime: DateTime.utc(2026, 8, 1, 3).millisecondsSinceEpoch,
      forecast: const [],
    );
    expect(forecast.updatedAt, DateTime.utc(2026, 8, 1, 3));
  });
}
