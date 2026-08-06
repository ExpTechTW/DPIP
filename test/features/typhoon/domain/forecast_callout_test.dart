import 'package:dpip/features/map/presentation/widgets/typhoon_forecast_callouts.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ForecastCalloutData lists fields without 70% circle', () {
    const f = TrackForecast(
      tau: 24,
      time: 1,
      latitude: 24,
      longitude: 122,
      wind: 43,
      gust: 53,
      pressure: 945,
      speed: 20,
      direction: 'WNW',
      r15: 320,
      r70: 160,
      state: ['減弱為熱帶性低氣壓', 'Weakening to TD'],
    );
    final d = ForecastCalloutData.from(f);
    expect(d.title, contains('+24'));
    expect(
      d.rows.map((r) => r.label),
      containsAll(['中心氣壓', '最大風速', '瞬間陣風', '移動時速', '移動方向', '七級風半徑']),
    );
    expect(d.rows.map((r) => r.label), isNot(contains('70% 機率圓')));
    expect(d.note, contains('減弱'));
  });

  test('forecastCalloutStride thins more at lower zoom', () {
    expect(forecastCalloutStride(8), 1);
    expect(forecastCalloutStride(6), 2);
    expect(forecastCalloutStride(5), 3);
    expect(forecastCalloutStride(4), 4);
  });

  test('pickedForecastIndices starts at first visible', () {
    // Track 0..6; first on-screen is index 2; stride 2 → 2,4,6
    expect(pickedForecastIndices(count: 7, firstVisible: 2, stride: 2), [
      2,
      4,
      6,
    ]);
    expect(pickedForecastIndices(count: 7, firstVisible: 0, stride: 2), [
      0,
      2,
      4,
      6,
    ]);
    expect(pickedForecastIndices(count: 5, firstVisible: 1, stride: 3), [1, 4]);
  });
}
