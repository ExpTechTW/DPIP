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
///
/// Every request goes through the [NotifyRequestLane] it is given: the backend
/// rate-limits these routes per address together with the location report.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/notify_request_lane.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/notification/data/notify_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Dio adapter that records requested URLs and answers a fixed JSON body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.body = '[2,1,0,2,1,0,1,1,0]', this.status = 200});

  final String body;
  final int status;
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
      status,
      headers: {
        if (body.isNotEmpty)
          Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Records the priority of every request that went through it.
class _CountingLane extends NotifyRequestLane {
  _CountingLane() : super(spacing: Duration.zero);

  final priorities = <NotifyRequestPriority>[];

  @override
  Future<T> run<T>(
    Future<T> Function() request, {
    NotifyRequestPriority priority = NotifyRequestPriority.device,
  }) {
    priorities.add(priority);
    return super.run(request, priority: priority);
  }
}

void main() {
  late RegionSelection regions;
  late _CountingLane lane;

  setUp(() {
    regions = RegionSelection(SettingsStore.inMemory({}));
    lane = _CountingLane();
  });

  test(
    'getNotify hits the exclusive core host at /api/v2/notify/{token}',
    () async {
      final adapter = _RecordingAdapter();
      final api = NotifyApi(
        ApiClient(Dio()..httpClientAdapter = adapter, regions),
        lane,
      );

      final result = await api.getNotify('push-token-1');

      expect(adapter.urls, [
        'https://api.core-tnn1.exptech.dev/api/v2/notify/push-token-1',
      ]);
      expect(result, [2, 1, 0, 2, 1, 0, 1, 1, 0]);
      expect(lane.priorities, [NotifyRequestPriority.device]);
    },
  );

  test(
    'setNotify appends /{channel}/{status} and returns the echoed settings',
    () async {
      final adapter = _RecordingAdapter(body: '[0,0,0,0,0,0,0,0,0]');
      final api = NotifyApi(
        ApiClient(Dio()..httpClientAdapter = adapter, regions),
        lane,
      );

      final result = await api.setNotify('push-token-1', 4, 1);

      expect(adapter.urls, [
        'https://api.core-tnn1.exptech.dev/api/v2/notify/push-token-1/4/1',
      ]);
      expect(result, [0, 0, 0, 0, 0, 0, 0, 0, 0]);
      expect(lane.priorities, [NotifyRequestPriority.device]);
    },
  );

  test(
    'reportLiveActivity sends /{token}/liveactivity/{pushToStartToken}/{0|1}',
    () async {
      final adapter = _RecordingAdapter(body: '', status: 204);
      final api = NotifyApi(
        ApiClient(Dio()..httpClientAdapter = adapter, regions),
        lane,
      );

      await api.reportLiveActivity('push-token-1', 'abcd', true);
      await api.reportLiveActivity('push-token-1', 'abcd', false);

      expect(adapter.urls, [
        'https://api.core-tnn1.exptech.dev/api/v2/notify/push-token-1/liveactivity/abcd/1',
        'https://api.core-tnn1.exptech.dev/api/v2/notify/push-token-1/liveactivity/abcd/0',
      ]);
      // Behind any location report or settings request waiting with it.
      expect(lane.priorities, [
        NotifyRequestPriority.deferred,
        NotifyRequestPriority.deferred,
      ]);
    },
  );
}
