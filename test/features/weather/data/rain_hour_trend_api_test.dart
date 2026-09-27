/// [RainHourTrendApi] is the one weather endpoint outside the region topology
/// entirely (`exptech.dingbot.tw`, not a region-mapped tier) — every other
/// meteor endpoint is fetched against a region-pinned tier, but this one must
/// go through the client's absolute-URL path instead. Swap that for the
/// tiered call to "match the rest of the file" and the request silently
/// targets whatever host the current region selection happens to resolve to,
/// instead of the one host that actually serves this forecast — a wrong-host
/// failure that reads, in a bug report, exactly like the real host being
/// down.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/weather/data/rain_hour_trend_api.dart';
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

RainHourTrendApi _apiWith(HttpClientAdapter adapter) => RainHourTrendApi(
  ApiClient(
    Dio()..httpClientAdapter = adapter,
    RegionSelection(SettingsStore.inMemory({})),
  ),
);

void main() {
  test(
    'getForecast targets the absolute dingbot host for the township code',
    () async {
      final adapter = _RecordingAdapter('{"rainfallWarnings-x":[]}');

      final result = await _apiWith(adapter).getForecast('6300100');

      expect(
        adapter.urls.single,
        'https://exptech.dingbot.tw/api/weather/rainforecast/6300100',
      );
      expect(result, {'rainfallWarnings-x': <dynamic>[]});
    },
  );
}
