/// [MeteorSnapshotApi]'s cache-split dual-host contract: every endpoint except
/// a timestamped history snapshot is mutable and served from `api.core-tnn1`
/// (short-lived cache); `getAt` alone is immutable and served from
/// `static.core-tnn1` (1-year cache). Get the tier backwards on either side
/// and a manual check still looks fine — the JSON still decodes — but a live
/// snapshot then gets cached for a year, or an immutable one is refetched on
/// every poll forever. So each endpoint's host is pinned here, not just its
/// path.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/weather/data/meteor_snapshot_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every URL it is asked to fetch and answers a fixed JSON body.
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

ApiClient _clientWith(HttpClientAdapter adapter) => ApiClient(
  Dio()..httpClientAdapter = adapter,
  RegionSelection(SettingsStore.inMemory({})),
);

const _mutableHost = 'https://api.core-tnn1.exptech.dev';
const _immutableHost = 'https://static.core-tnn1.exptech.dev';
const _base = '/api/v5/meteor/weather';

void main() {
  test(
    'getStation reads the mutable host and returns the decoded map',
    () async {
      final adapter = _RecordingAdapter('{"C0A940":{"n":"Taipei"}}');
      final api = MeteorSnapshotApi(_clientWith(adapter), _base);

      final result = await api.getStation();

      expect(adapter.urls.single, '$_mutableHost$_base/station');
      expect(result, {
        'C0A940': {'n': 'Taipei'},
      });
    },
  );

  test('getLatest reads the mutable host at the dataset root', () async {
    final adapter = _RecordingAdapter('{"time":1700000000}');
    final api = MeteorSnapshotApi(_clientWith(adapter), _base);

    final result = await api.getLatest();

    expect(adapter.urls.single, '$_mutableHost$_base');
    expect(result, {'time': 1700000000});
  });

  test('getList reads the mutable host', () async {
    final adapter = _RecordingAdapter('[1700000000,5]');
    final api = MeteorSnapshotApi(_clientWith(adapter), _base);

    final result = await api.getList();

    expect(adapter.urls.single, '$_mutableHost$_base/list');
    expect(result, [1700000000, 5]);
  });

  test('getAt reads the immutable static host, not the mutable one', () async {
    final adapter = _RecordingAdapter('{"time":1700000000}');
    final api = MeteorSnapshotApi(_clientWith(adapter), _base);

    final result = await api.getAt(1700000000);

    expect(adapter.urls.single, '$_immutableHost$_base/1700000000');
    expect(result, {'time': 1700000000});
  });

  test(
    'getTrend reads the mutable host with the range as a query param',
    () async {
      final adapter = _RecordingAdapter('{"id":"C0A940"}');
      final api = MeteorSnapshotApi(_clientWith(adapter), _base);

      final result = await api.getTrend('C0A940', '7d');

      expect(adapter.urls.single, '$_mutableHost$_base/trend/C0A940?range=7d');
      expect(result, {'id': 'C0A940'});
    },
  );
}
