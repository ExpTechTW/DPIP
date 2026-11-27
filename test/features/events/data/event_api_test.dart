/// The DPIP card API (v2) puts the language, the card id and the township in
/// the path, and answers a near miss in any of them with a 404 — so each route
/// is pinned here exactly, together with how a failure on one core region
/// reaches the other (a 503 fails over; a 400 or 404 does not) and which feed
/// may fall back to a saved copy (history only).
///
/// The bodies are the list and detail examples of the server's `api.md` §2.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/network/stale_if_error.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/events/data/event_api.dart';
import 'package:dpip/features/events/domain/event_card.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /api/v2/dpip/en/realtime/100` (server `TestListShape`).
const _realtimeBody = '''
{"lang":"en","cards":[
  {"id":1001,"serial":1,"kind":"issue","type":"thunderstorm","hazard":"thunderstorm","status":1,"author":"test","lang":"en","title":"Taipei thunderstorm","subtitle":"Xinyi alert","send":1699996400000,"expires":1700003600000,"hasPolygon":false},
  {"id":1002,"serial":1,"kind":"issue","type":"heavy-rain","hazard":"heavy_rain","status":1,"author":"test","lang":"en","title":"Heavy rain advisory","subtitle":"Northern Taiwan","send":1699992800000,"expires":1700007200000,"hasPolygon":true},
  {"id":1003,"serial":1,"kind":"issue","type":"earthquake","hazard":"earthquake","status":1,"author":"test","lang":"zh-TW","title":"地震報告","subtitle":"規模 4.5","send":1699998800000,"expires":1700010800000,"hasPolygon":true},
  {"id":1008,"serial":1,"kind":"issue","type":"tsunami","hazard":"tsunami","status":1,"author":"test","lang":"zh-TW","title":"海嘯警報","subtitle":"東部沿海","send":1699999520000,"expires":1700021600000,"hasPolygon":false}
]}
''';

/// `GET /api/v2/dpip/zh-TW/history` (server `TestDetailReportsAndLists`).
const _historyBody = '''
{"lang":"zh-TW","cards":[
  {"id":1800000000,"serial":3,"kind":"cancel","type":"heavy-rain","hazard":"heavy_rain","status":1,"author":"cwa","lang":"zh-TW","title":"大雨特報","subtitle":"臺北市、新北市","send":1799999400000,"expires":1799999400000,"hasPolygon":false},
  {"id":1800000001,"serial":2,"kind":"update","type":"heavy-rain","hazard":"heavy_rain","status":1,"author":"cwa","lang":"zh-TW","title":"大雨特報","subtitle":"新北市","send":1799913600000,"expires":1800086400000,"hasPolygon":false},
  {"id":1800000002,"serial":2,"kind":"cancel","type":"heavy-rain","hazard":"heavy_rain","status":1,"author":"cwa","lang":"zh-TW","title":"大雨特報","subtitle":"基隆市","send":1799913600000,"expires":1799913600000,"hasPolygon":false}
]}
''';

/// `GET /api/v2/dpip/en/event/1800000000/200` (server
/// `TestDetailTranslationPerReport`).
const _detailBody = '''
{"lang":"en","cards":[
  {"id":1800000000,"serial":1,"kind":"issue","type":"heavy-rain","hazard":"heavy_rain","status":1,"author":"cwa","lang":"en",
   "title":"Heavy rain advisory","subtitle":"Taipei City","send":1799992800000,"expires":1800010800000,"area":[100],"hasPolygon":false,
   "description":"Heavy rain in Taipei City",
   "original":{"title":"大雨特報","subtitle":"臺北市","description":"臺北市有大雨"}},
  {"id":1800000000,"serial":2,"kind":"update","type":"heavy-rain","hazard":"heavy_rain","status":1,"author":"cwa","lang":"zh-TW",
   "title":"大雨特報","subtitle":"臺北市、新北市","send":1799996400000,"expires":1800021600000,"area":[100,200],"hasPolygon":false,
   "description":"新北市山區有大雨"},
  {"id":1800000000,"serial":3,"kind":"cancel","type":"heavy-rain","hazard":"heavy_rain","status":1,"author":"cwa","lang":"zh-TW",
   "title":"大雨特報","subtitle":"臺北市、新北市","send":1799999400000,"expires":1799999400000,"area":[100,200],"hasPolygon":false,
   "description":"新北市山區有大雨"}
]}
''';

/// A one-report card with `addition` (server `TestDetailAreaAndAddition`).
const _additionBody = '''
{"lang":"en","cards":[{"id":42,"serial":1,"kind":"issue","type":"earthquake","hazard":"earthquake","status":1,"author":"cwa","lang":"zh-TW","title":"地震","subtitle":"規模 5",
  "send":1000,"expires":2000,"area":[],"hasPolygon":false,"addition":{"max":4,"area":["臺北市"]},"description":"說明"}]}
''';

const _unavailableBody =
    '{"statusCode":503,"error":"Service Unavailable","message":"Service Unavailable"}';
const _notFoundBody =
    '{"message":"Card 7 not found","error":"Not Found","statusCode":404}';
const _invalidRegionBody = '{"error":"Invalid region"}';

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

ResponseBody _json(String body, [int status = 200]) => ResponseBody.fromString(
  body,
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

List<int> _ids(EventCardList list) => [for (final c in list.cards) c.id];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionSelection regions;
  late List<String> coreHosts;

  setUp(() {
    regions = RegionSelection(SettingsStore.inMemory({}));
    coreHosts = [
      for (final r in regions.coreOrder) 'api.core-${r.code}.exptech.dev',
    ];
  });

  EventApi apiWith(_FakeAdapter adapter) =>
      EventApi(ApiClient(Dio()..httpClientAdapter = adapter, regions));

  /// Each route as a call, the path it must hit and the body to answer with.
  final routes = <String, (Future<Object> Function(EventApi), String, String)>{
    'realtime, nationwide': (
      (api) => api.realtime(lang: 'en'),
      '/api/v2/dpip/en/realtime',
      _realtimeBody,
    ),
    'realtime, township': (
      (api) => api.realtime(lang: 'en', region: 100),
      '/api/v2/dpip/en/realtime/100',
      _realtimeBody,
    ),
    'history, nationwide': (
      (api) => api.history(lang: 'zh-TW'),
      '/api/v2/dpip/zh-TW/history',
      _historyBody,
    ),
    'history, township': (
      (api) => api.history(lang: 'zh-TW', region: 710),
      '/api/v2/dpip/zh-TW/history/710',
      _historyBody,
    ),
    'detail, township': (
      (api) => api.detail(lang: 'en', id: 1800000000, region: 200),
      '/api/v2/dpip/en/event/1800000000/200',
      _detailBody,
    ),
    'detail, nationwide (region 0)': (
      (api) => api.detail(lang: 'zh-Hant-HK', id: 42, region: 0),
      '/api/v2/dpip/zh-Hant-HK/event/42/0',
      _additionBody,
    ),
  };

  group('paths', () {
    for (final MapEntry(key: name, value: (call, path, body))
        in routes.entries) {
      test('$name GETs $path on the selected core region', () async {
        final adapter = _FakeAdapter((_) => _json(body));
        await call(apiWith(adapter));

        final sent = adapter.hits.single;
        expect(sent.method, 'GET', reason: name);
        expect(sent.uri.scheme, 'https', reason: name);
        expect(sent.uri.host, coreHosts.first, reason: name);
        expect(sent.uri.path, path, reason: name);
        expect(sent.uri.query, isEmpty, reason: name);
        // Only history may be answered from the saved copy.
        expect(
          StaleIfError.of(sent) != null,
          name.startsWith('history'),
          reason: name,
        );
      });
    }
  });

  group('decoding', () {
    test('realtime decodes the list example', () async {
      final api = apiWith(_FakeAdapter((_) => _json(_realtimeBody)));
      final list = await api.realtime(lang: 'en', region: 100);

      expect(list.lang, 'en');
      expect(_ids(list), [1001, 1002, 1003, 1008]);
    });

    test('history decodes the list example and is current', () async {
      final api = apiWith(_FakeAdapter((_) => _json(_historyBody)));
      final fetched = await api.history(lang: 'zh-TW');

      expect(fetched.stale, isNull);
      expect(fetched.data.lang, 'zh-TW');
      expect(_ids(fetched.data), [1800000000, 1800000001, 1800000002]);
    });

    test('detail decodes every report, first to latest', () async {
      final api = apiWith(_FakeAdapter((_) => _json(_detailBody)));
      final detail = await api.detail(lang: 'en', id: 1800000000, region: 200);

      expect(detail.lang, 'en');
      expect(detail.reports, hasLength(3));
      expect(detail.latest, same(detail.reports.last));
    });

    test('detail decodes a single report with addition', () async {
      final api = apiWith(_FakeAdapter((_) => _json(_additionBody)));
      final detail = await api.detail(lang: 'en', id: 42, region: 0);

      expect(detail.reports, hasLength(1));
      expect(detail.latest, same(detail.reports.single));
    });

    test('a body of the wrong shape is a FormatException', () async {
      final api = apiWith(_FakeAdapter((_) => _json('{"unexpected":"shape"}')));

      await expectLater(
        api.realtime(lang: 'en'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        api.history(lang: 'en'),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        api.detail(lang: 'en', id: 1, region: 0),
        throwsA(isA<FormatException>()),
      );
    });

    test('a detail with no report is a FormatException', () async {
      final api = apiWith(
        _FakeAdapter((_) => _json('{"lang":"en","cards":[]}')),
      );

      await expectLater(
        api.detail(lang: 'en', id: 1, region: 0),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('failover between the core regions', () {
    // ApiClient.request decides this for every coreApi call: a 5xx is the
    // host's fault and is retried on the next region; a 4xx would repeat
    // on every region and is thrown at once.
    for (final MapEntry(key: name, value: (call, path, body))
        in routes.entries) {
      test('$name: a 503 on one region is retried on the other', () async {
        final adapter = _FakeAdapter(
          (o) => o.uri.host == coreHosts.first
              ? _json(_unavailableBody, 503)
              : _json(body),
        );
        await call(apiWith(adapter));

        expect([for (final h in adapter.hits) h.uri.host], coreHosts);
        expect([for (final h in adapter.hits) h.uri.path], [path, path]);
      });

      for (final (status, errorBody) in [
        (404, _notFoundBody),
        (400, _invalidRegionBody),
      ]) {
        test(
          '$name: a $status is thrown without trying the other region',
          () async {
            final adapter = _FakeAdapter((_) => _json(errorBody, status));

            await expectLater(
              call(apiWith(adapter)),
              throwsA(
                isA<DioException>().having(
                  (e) => e.response?.statusCode,
                  'status',
                  status,
                ),
              ),
            );
            expect(adapter.hits, hasLength(1));
          },
        );
      }
    }
  });

  group('history stale-if-error', () {
    final since = DateTime.utc(2026, 11, 27, 3);

    /// Stands in for the ETag interceptor: offers [saved] as the copy on
    /// record for the request, then answers [status].
    _FakeAdapter offering(String saved, int status, String body) =>
        _FakeAdapter((o) {
          StaleIfError.of(o)
              ?.offer((data: jsonDecode(saved), fetchedAt: since));
          return _json(body, status);
        });

    test('every region answering 503 serves the saved list, marked', () async {
      final adapter = offering(_historyBody, 503, _unavailableBody);
      final fetched = await apiWith(adapter)
          .history(lang: 'zh-TW', region: 710);

      expect(adapter.hits, hasLength(coreHosts.length));
      expect(_ids(fetched.data), [1800000000, 1800000001, 1800000002]);
      expect(fetched.stale, isNotNull);
      expect(fetched.stale!.since, since);
      expect(fetched.stale!.failure, isA<NetworkFailure>());
    });

    test('a 404 is never covered by the saved list', () async {
      final adapter = offering(_historyBody, 404, _notFoundBody);

      await expectLater(
        apiWith(adapter).history(lang: 'zh-TW'),
        throwsA(isA<DioException>()),
      );
    });

    test('with nothing saved, the 503 is thrown', () async {
      final adapter = _FakeAdapter((_) => _json(_unavailableBody, 503));

      await expectLater(
        apiWith(adapter).history(lang: 'zh-TW'),
        throwsA(isA<DioException>()),
      );
    });

    test('realtime never falls back to a saved copy', () async {
      final adapter = offering(_realtimeBody, 503, _unavailableBody);

      await expectLater(
        apiWith(adapter).realtime(lang: 'en'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
