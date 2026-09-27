/// [MeteorWeatherApi]'s own two endpoints, plus the constructor wiring that
/// backs everything else: `snapshots` must be built with the weather dataset
/// root (`/api/v5/meteor/weather`), not a sibling dataset's. A copy-paste from
/// the rain or lightning API's constructor would compile fine — the shape is
/// identical — and every weather screen would start silently reading rain's
/// station directory and snapshots instead. `getRealtime` and `getForecast`
/// are both mutable, live data, so both stay on the short-lived host rather
/// than the immutable one snapshot history uses.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/weather/data/meteor_weather_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter([this.body = '{}']);

  final String body;
  final List<String> urls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    urls.add(options.uri.toString());
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

MeteorWeatherApi _apiWith(HttpClientAdapter adapter) => MeteorWeatherApi(
  ApiClient(
    Dio()..httpClientAdapter = adapter,
    RegionSelection(SettingsStore.inMemory({})),
  ),
);

const _mutableHost = 'https://api.core-tnn1.exptech.dev';

void main() {
  test('getRealtime asks the mutable host for the lat,lng pair', () async {
    final adapter = _RecordingAdapter('{"id":"C0A94"}');

    final result = await _apiWith(adapter).getRealtime(25.033, 121.5654);

    expect(
      adapter.urls.single,
      '$_mutableHost/api/v5/meteor/weather/realtime/25.033,121.5654',
    );
    expect(result, {'id': 'C0A94'});
  });

  test('getForecast asks the mutable host for the township code', () async {
    final adapter = _RecordingAdapter('{"updateTime":1700000000000}');

    final result = await _apiWith(adapter).getForecast('6300100');

    expect(
      adapter.urls.single,
      '$_mutableHost/api/v5/meteor/weather/forecast/6300100',
    );
    expect(result, {'updateTime': 1700000000000});
  });

  test(
    'snapshots is wired to the weather dataset root, not another one',
    () async {
      final adapter = _RecordingAdapter();

      await _apiWith(adapter).snapshots.getStation();

      expect(
        adapter.urls.single,
        '$_mutableHost/api/v5/meteor/weather/station',
      );
    },
  );
}
