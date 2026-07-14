import 'package:dpip/features/weather/domain/weather_snapshot.dart';
import 'package:dpip/features/weather/domain/weather_station.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WeatherSnapshot.decode aligns field-arrays and maps -99 → null', () {
    final snapshot = WeatherSnapshot.decode(const {
      'time': 1784019000,
      'ids': ['C0TB40', 'C0SD20'],
      'wx': [200, 300],
      'temp': [31.2, 31.3],
      'rh': [69, 71],
      'pres': [1006.8, 1008.1],
      'wdir': [201, 187],
      'wspd': [2.1, 4.2],
      'gspd': [-99, -99],
      'gdir': [-99, -99],
      'hi': [31.7, 32.7],
      'lo': [26.3, 25.6],
    });

    expect(snapshot.time, 1784019000);
    expect(snapshot.stations, hasLength(2));

    final first = snapshot.stations.first;
    expect(first.id, 'C0TB40');
    expect(first.weatherCode, 200);
    expect(first.temperature, 31.2);
    expect(first.humidity, 69);
    expect(first.pressure, 1006.8);
    expect(first.windDirection, 201);
    expect(first.high, 31.7);
    expect(first.low, 26.3);
    // -99 sentinels decode to null.
    expect(first.gustSpeed, isNull);
    expect(first.gustDirection, isNull);

    expect(snapshot.stations[1].id, 'C0SD20');
    expect(snapshot.stations[1].temperature, 31.3);
  });

  test('WeatherSnapshot.decode handles an empty station list', () {
    final snapshot = WeatherSnapshot.decode(const {
      'time': 1784019000,
      'ids': <String>[],
    });
    expect(snapshot.time, 1784019000);
    expect(snapshot.stations, isEmpty);
  });

  test('WeatherStation.fromJson maps the short wire keys', () {
    final station = WeatherStation.fromJson(const {
      'n': '崇德',
      'c': '花蓮縣',
      't': '秀林鄉',
      'alt': 8,
      'lat': 24.1661,
      'lon': 121.6574,
    });
    expect(station.name, '崇德');
    expect(station.county, '花蓮縣');
    expect(station.town, '秀林鄉');
    expect(station.altitude, 8);
    expect(station.latitude, 24.1661);
    expect(station.longitude, 121.6574);
  });
}
