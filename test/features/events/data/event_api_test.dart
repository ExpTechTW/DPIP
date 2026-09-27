/// The DPIP event feed (history + realtime, nationwide or by township) is
/// still on the legacy single host, and every method appears to fold a
/// non-list body into an empty list via `(body as List?) ?? const []`.
///
/// That fallback only actually covers a `null` body: `as List?` throws for
/// any other mismatched type instead of quietly becoming `null`, so a body
/// that is present but the wrong shape (an error object, say) throws a
/// [TypeError] out of these methods rather than degrading to "no events".
/// This pins the exact host/path per method, the working `null` case, and —
/// deliberately, since it is the real current behaviour — the throw on any
/// other unexpected shape. See the coverage report for the four call sites
/// this affects.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/events/data/event_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final ResponseBody Function(RequestOptions options) responder;
  final List<RequestOptions> hits = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    hits.add(options);
    return responder(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(String body, int status) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

/// Every method, as a call plus the path it must hit — so the host, the path
/// and the empty-list fallback can each be checked once per method without
/// four near-identical test bodies.
final Map<String, (Future<List<dynamic>> Function(EventApi), String)> _calls = {
  'getHistoryList': (
    (api) => api.getHistoryList(),
    '/api/v1/dpip/history/list',
  ),
  'getHistoryRegion': (
    (api) => api.getHistoryRegion('063'),
    '/api/v1/dpip/history/063',
  ),
  'getRealtimeList': (
    (api) => api.getRealtimeList(),
    '/api/v1/dpip/realtime/list',
  ),
  'getRealtimeRegion': (
    (api) => api.getRealtimeRegion('063'),
    '/api/v1/dpip/realtime/063',
  ),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionSelection regions;

  setUp(() {
    regions = RegionSelection(SettingsStore.inMemory({}));
  });

  EventApi apiWith(_FakeAdapter adapter) =>
      EventApi(ApiClient(Dio()..httpClientAdapter = adapter, regions));

  for (final entry in _calls.entries) {
    test('${entry.key} hits the legacy host at the right path', () async {
      final adapter = _FakeAdapter((_) => _json('[{"id":1}]', 200));
      final result = await entry.value.$1(apiWith(adapter));

      final sent = adapter.hits.single;
      expect(sent.uri.host, 'api-1.exptech.dev', reason: entry.key);
      expect(sent.uri.path, entry.value.$2, reason: entry.key);
      expect(result, [
        {'id': 1},
      ], reason: entry.key);
    });

    test('${entry.key} throws on a non-list, non-null body rather than '
        'falling back to empty', () async {
      // `(body as List?) ?? const []` reads like a safe fallback for any
      // unexpected shape, but `as` only lets `null` through — a Map still
      // fails the cast and throws. Documented here as the actual behaviour,
      // not the apparent intent.
      final adapter = _FakeAdapter((_) => _json('{"unexpected":"shape"}', 200));
      await expectLater(
        () => entry.value.$1(apiWith(adapter)),
        throwsA(isA<TypeError>()),
        reason: entry.key,
      );
    });

    test('${entry.key} folds a null body into an empty list', () async {
      final adapter = _FakeAdapter((_) => _json('null', 200));
      final result = await entry.value.$1(apiWith(adapter));

      expect(result, isEmpty, reason: entry.key);
    });
  }
}
