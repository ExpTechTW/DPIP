/// Forecast tips keep the first on-screen fix, then every stride-th point
/// after it. [ForecastCalloutData] drops missing fields and still shows a
/// free-text heading when it is not a compass point.
library;

import 'dart:math' as math;

import 'package:dpip/features/map/presentation/widgets/typhoon_forecast_callouts.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TrackForecast _fix({
  int tau = 12,
  double? pressure,
  double? wind,
  double? gust,
  double? speed,
  String? direction,
  double? r15,
  List<String>? state,
}) => TrackForecast(
  tau: tau,
  time: 1,
  latitude: 23,
  longitude: 122,
  pressure: pressure,
  wind: wind,
  gust: gust,
  speed: speed,
  direction: direction,
  r15: r15,
  state: state,
);

void main() {
  test('the first point inside the padded viewport wins', () {
    const view = Size(100, 80);
    expect(
      indexOfFirstVisibleForecast(
        screens: const [
          math.Point(-80, 0),
          math.Point(10, 10),
          math.Point(200, 200),
        ],
        viewport: view,
      ),
      1,
    );
    expect(
      indexOfFirstVisibleForecast(
        screens: const [math.Point(-100, -100)],
        viewport: view,
        pad: 10,
      ),
      -1,
    );
    expect(indexOfFirstVisibleForecast(screens: const [], viewport: view), -1);
  });

  test('picked indices start at the first visible fix and honour stride', () {
    expect(
      pickedForecastIndices(count: 0, firstVisible: 0, stride: 1),
      isEmpty,
    );
    expect(
      pickedForecastIndices(count: 5, firstVisible: -1, stride: 1),
      isEmpty,
    );
    expect(
      pickedForecastIndices(count: 5, firstVisible: 5, stride: 2),
      isEmpty,
    );
    expect(pickedForecastIndices(count: 8, firstVisible: 1, stride: 0), [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
    expect(pickedForecastIndices(count: 10, firstVisible: 2, stride: 3), [
      2,
      5,
      8,
    ]);
  });

  test('a full forecast card lists every present field and the note', () {
    final data = ForecastCalloutData.from(
      _fix(
        pressure: 960,
        wind: 40,
        gust: 50,
        speed: 18,
        direction: 'N',
        r15: 200,
        state: const ['  減弱  ', 'weakening'],
      ),
    );
    expect(data.title, '預測 +12 小時');
    expect(data.rows.map((r) => r.label), [
      '中心氣壓',
      '最大風速',
      '瞬間陣風',
      '移動時速',
      '移動方向',
      '七級風半徑',
    ]);
    expect(data.rows[4].value, isNotEmpty);
    expect(data.note, '減弱');
    expect(data.estimatedHeight, greaterThan(34));
    expect(compactForecastCalloutText(_fix(pressure: 980)), contains('980'));
  });

  test('an unknown heading is kept verbatim and a blank note is dropped', () {
    final odd = ForecastCalloutData.from(_fix(direction: '停滯'));
    expect(odd.rows.single.value, '停滯');
    final blank = ForecastCalloutData.from(_fix(state: const ['   ']));
    expect(blank.rows, isEmpty);
    expect(blank.note, isNull);
    expect(blank.estimatedHeight, 48);
  });
}
