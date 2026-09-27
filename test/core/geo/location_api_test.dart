/// The device-location report that keys push targeting to a township.
///
/// The path is hand-built from five interpolated segments — platform, token,
/// app version, latitude, longitude — with no named-parameter safety net once
/// they hit the string. Transposing `lat`/`lng`, or losing the tier migration
/// back to the legacy host, would compile fine and fail nothing until a
/// backend engineer asks why every device is a mirror image of itself off the
/// coast of Africa. This pins the exact tier and path shape.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/geo/location_api.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every request it is asked to fetch, and answers with a scripted
/// response — the same seam `test/core/network/api_client_test.dart` uses.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionSelection regions;

  setUp(() {
    regions = RegionSelection(SettingsStore.inMemory({}));
  });

  LocationApi apiWith(_FakeAdapter adapter) =>
      LocationApi(ApiClient(Dio()..httpClientAdapter = adapter, regions));

  test(
    'reports through the core-exclusive tier, not the legacy host',
    () async {
      final adapter = _FakeAdapter((_) => _json('{"ok":true}', 200));
      await apiWith(adapter).updateDeviceLocation(
        platform: 1,
        token: 'tok-123',
        version: '4.5.6',
        lat: 25.03,
        lng: 121.5,
      );

      // Single fixed host: the migration off `api-1` this API already made.
      expect(adapter.hits, hasLength(1));
      expect(adapter.hits.single.uri.host, 'api.core-tnn1.exptech.dev');
    },
  );

  test(
    'the path interpolates platform/token/version/lat,lng in order',
    () async {
      final adapter = _FakeAdapter((_) => _json('{"ok":true}', 200));
      await apiWith(adapter).updateDeviceLocation(
        platform: 0,
        token: 'abc',
        version: '1.2.3',
        lat: 25.03,
        lng: 121.56,
      );

      expect(
        adapter.hits.single.uri.path,
        '/api/v2/location/0/abc/1.2.3/25.03,121.56',
      );
    },
  );

  test('returns the decoded body', () async {
    final adapter = _FakeAdapter((_) => _json('{"township":"信義區"}', 200));
    final result = await apiWith(adapter).updateDeviceLocation(
      platform: 1,
      token: 't',
      version: '1',
      lat: 0,
      lng: 0,
    );

    expect(result, {'township': '信義區'});
  });
}
