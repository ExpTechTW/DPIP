import 'dart:convert';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/features/weather/data/current_weather_widget_publisher.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeWidgetSnapshotWriter implements WidgetSnapshotWriter {
  WidgetSnapshotKind? writtenKind;
  String? writtenJson;
  String? writtenSourceIdentifier;
  int clearCallCount = 0;
  WidgetSnapshotKind? clearedKind;

  @override
  Future<Result<void>> clear({required WidgetSnapshotKind kind}) async {
    clearCallCount += 1;
    clearedKind = kind;
    return const Ok(null);
  }

  @override
  Future<Result<void>> write({
    required WidgetSnapshotKind kind,
    required String json,
    String? sourceIdentifier,
  }) async {
    writtenKind = kind;
    writtenJson = json;
    writtenSourceIdentifier = sourceIdentifier;

    return const Ok(null);
  }
}

void main() {
  test('publishes current weather snapshot as JSON', () async {
    final writer = FakeWidgetSnapshotWriter();
    final publisher = CurrentWeatherWidgetPublisher(writer);

    final snapshot = CurrentWeatherWidgetSnapshot(
      sourceIdentifier: 'current-location',
      regionCode: '660',
      regionName: '西屯區',
      observationTime: 1789398000,
      stationName: '西屯',
      weather: '多雲',
      weatherCode: 200,
      condition: .cloudy,
      isNight: false,
      nextDayNightTransitionTime: 1_789_562_700,
      calibratedTimeOffsetMilliseconds: 0,
      temperature: 28.4,
      humidity: 76,
      rain: 0.0,
    );

    final result = await publisher.publish(snapshot);

    expect(result, isA<Ok<void>>());
    expect(writer.writtenKind, WidgetSnapshotKind.currentWeather);
    expect(writer.writtenSourceIdentifier, 'current-location');

    final decoded = jsonDecode(writer.writtenJson!) as Map<String, dynamic>;

    expect(decoded['regionCode'], '660');
    expect(decoded['regionName'], '西屯區');
    expect(decoded['temperature'], 28.4);
  });

  test('preserves null values when publishing', () async {
    final writer = FakeWidgetSnapshotWriter();
    final publisher = CurrentWeatherWidgetPublisher(writer);

    final snapshot = CurrentWeatherWidgetSnapshot(
      sourceIdentifier: 'current-location',
      regionCode: '660',
      regionName: '西屯區',
      observationTime: 1789398000,
      stationName: '西屯',
      weather: '多雲',
      weatherCode: 200,
      condition: .cloudy,
      isNight: false,
      nextDayNightTransitionTime: 1_789_562_700,
      calibratedTimeOffsetMilliseconds: 0,
      temperature: null,
      humidity: null,
      rain: null,
    );

    await publisher.publish(snapshot);

    final decoded = jsonDecode(writer.writtenJson!) as Map<String, dynamic>;

    expect(decoded['temperature'], isNull);
    expect(decoded['humidity'], isNull);
    expect(decoded['rain'], isNull);
  });

  test('clears the current weather snapshot', () async {
    final writer = FakeWidgetSnapshotWriter();
    final publisher = CurrentWeatherWidgetPublisher(writer);

    final result = await publisher.clear();

    expect(result, isA<Ok<void>>());
    expect(writer.clearCallCount, 1);
    expect(writer.clearedKind, WidgetSnapshotKind.currentWeather);
  });
}
