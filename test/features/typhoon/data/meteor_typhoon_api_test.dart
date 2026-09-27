/// [MeteorTyphoonApi]'s cache-split dual-host contract, the same shape as the
/// weather/rain/lightning meteor datasets: the cyclone index and every
/// dataset's `/list` are mutable; a timestamped `/{kind}/:time` snapshot is
/// immutable. The map's timeline scrubber re-requests an old snapshot every
/// time a user drags across it — on the wrong tier that is an unmemoized hit
/// against the mutable host for a storm that ended years ago, instead of a
/// request the 1-year cache answers without leaving the device. [TyphoonKind]
/// also selects the `/{kind}/…` path segment, so every kind is exercised at
/// least once, not just the one the maintainer had open.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/typhoon/data/meteor_typhoon_api.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';
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

MeteorTyphoonApi _apiWith(HttpClientAdapter adapter) => MeteorTyphoonApi(
  ApiClient(
    Dio()..httpClientAdapter = adapter,
    RegionSelection(SettingsStore.inMemory({})),
  ),
);

const _mutableHost = 'https://api.core-tnn1.exptech.dev';
const _immutableHost = 'https://static.core-tnn1.exptech.dev';
const _base = '/api/v5/meteor/typhoon';

void main() {
  test('getCyclones reads the mutable host at the dataset root', () async {
    final adapter = _RecordingAdapter('{"cyclones":[]}');

    final result = await _apiWith(adapter).getCyclones();

    expect(adapter.urls.single, '$_mutableHost$_base');
    expect(result, {'cyclones': <dynamic>[]});
  });

  test('getTrack reads the mutable host', () async {
    final adapter = _RecordingAdapter();
    await _apiWith(adapter).getTrack();
    expect(adapter.urls.single, '$_mutableHost$_base/track');
  });

  test('getPotential reads the mutable host', () async {
    final adapter = _RecordingAdapter();
    await _apiWith(adapter).getPotential();
    expect(adapter.urls.single, '$_mutableHost$_base/potential');
  });

  test('getProbability reads the mutable host', () async {
    final adapter = _RecordingAdapter();
    await _apiWith(adapter).getProbability();
    expect(adapter.urls.single, '$_mutableHost$_base/probability');
  });

  test('getWarning reads the mutable host', () async {
    final adapter = _RecordingAdapter();
    await _apiWith(adapter).getWarning();
    expect(adapter.urls.single, '$_mutableHost$_base/warning');
  });

  test("getList reads the mutable host at every kind's own path", () async {
    for (final kind in TyphoonKind.values) {
      final adapter = _RecordingAdapter('[]');

      await _apiWith(adapter).getList(kind);

      expect(
        adapter.urls.single,
        '$_mutableHost$_base/${kind.name}/list',
        reason: kind.name,
      );
    }
  });

  test('getAt reads the immutable static host, not the mutable one', () async {
    final adapter = _RecordingAdapter('{"time":1700000000}');

    final result = await _apiWith(adapter)
        .getAt(TyphoonKind.warning, 1700000000);

    expect(adapter.urls.single, '$_immutableHost$_base/warning/1700000000');
    expect(result, {'time': 1700000000});
  });
}
