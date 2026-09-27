/// [NotifyApi] is a thin wrapper: two GETs whose entire job is building the
/// right path and casting the decoded body to a list. A wrong path here is
/// invisible until it reaches a route that doesn't exist — the backend fronts
/// several `/api/v2/notify/...`-shaped routes, so a typo that still parses as
/// a URL just gets a working handler for the wrong thing rather than a 404.
///
/// Both endpoints are pinned to `api.core-tnn1` (`ApiTier.coreExclusiveApi`,
/// single host, no region failover) — that host shows up in every URL these
/// tests record, so a change that accidentally moved this API to a
/// region-selected tier would also show up here as a different host.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/notification/data/notify_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Dio adapter that records requested URLs and answers a fixed JSON body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.body = '[2,1,0,2,1,0,1,1,0]'});

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

void main() {
  late RegionSelection regions;

  setUp(() {
    regions = RegionSelection(SettingsStore.inMemory({}));
  });

  test(
    'getNotify hits the exclusive core host at /api/v2/notify/{token}',
    () async {
      final adapter = _RecordingAdapter();
      final api = NotifyApi(
        ApiClient(Dio()..httpClientAdapter = adapter, regions),
      );

      final result = await api.getNotify('push-token-1');

      expect(adapter.urls, [
        'https://api.core-tnn1.exptech.dev/api/v2/notify/push-token-1',
      ]);
      expect(result, [2, 1, 0, 2, 1, 0, 1, 1, 0]);
    },
  );

  test(
    'setNotify appends /{channel}/{status} and returns the echoed settings',
    () async {
      final adapter = _RecordingAdapter(body: '[0,0,0,0,0,0,0,0,0]');
      final api = NotifyApi(
        ApiClient(Dio()..httpClientAdapter = adapter, regions),
      );

      final result = await api.setNotify('push-token-1', 4, 1);

      expect(adapter.urls, [
        'https://api.core-tnn1.exptech.dev/api/v2/notify/push-token-1/4/1',
      ]);
      expect(result, [0, 0, 0, 0, 0, 0, 0, 0, 0]);
    },
  );
}
