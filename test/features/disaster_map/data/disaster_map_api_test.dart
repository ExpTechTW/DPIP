/// [DisasterMapApi] has two very different jobs sharing one class: [tileUrl]
/// is a pure string template consumed by MapLibre's native tile loader (never
/// by this app's own HTTP stack), while the three detail getters are ordinary
/// app-fetched JSON GETs that share one `_detail(kind, id)` helper.
///
/// Both are quiet failure modes:
/// - a wrong host or path in [tileUrl] never throws — MapLibre just 404s the
///   tile forever, one request at a time, with nothing in this app's own logs
///   pointing at the template that built the URL;
/// - a copy-paste slip in `_detail`'s `kind` literal (e.g. shelter reusing
///   `'restroom'`) sends every tap on that venue type at the wrong endpoint —
///   and because the three endpoints return similarly-shaped JSON, the
///   response still decodes, so nothing errors; the pin just shows another
///   venue's data.
///
/// So this pins the exact URL each of the four methods builds, on the
/// `static.core-tnn1` host ([ApiTier.coreStaticExclusive] — single host, no
/// region failover), and that a detail response's JSON object is handed back
/// as a plain `Map<String, dynamic>`.
library;

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/disaster_map/data/disaster_map_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Dio adapter that records requested URLs and answers a fixed JSON body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.body = '{}'});

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

  test('tileUrl builds the XYZ MVT template on the static exclusive host', () {
    final api = DisasterMapApi(ApiClient(Dio(), regions));

    expect(
      api.tileUrl('aed'),
      'https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/aed/{z}/{x}/{y}.mvt',
    );
    expect(
      api.tileUrl('shelter'),
      'https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/shelter/{z}/{x}/{y}.mvt',
    );
  });

  test(
    'getAedDetail requests the aed kind and decodes the JSON object',
    () async {
      final adapter = _RecordingAdapter(
        body: '{"id": 7, "aed_id": "A007", "name": "Station 7"}',
      );
      final api = DisasterMapApi(
        ApiClient(Dio()..httpClientAdapter = adapter, regions),
      );

      final result = await api.getAedDetail(7);

      expect(adapter.urls, [
        'https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/aed/7',
      ]);
      expect(result, {'id': 7, 'aed_id': 'A007', 'name': 'Station 7'});
    },
  );

  test(
    'getRestroomDetail requests the restroom kind, not aed or shelter',
    () async {
      final adapter = _RecordingAdapter(body: '{"name": "Restroom 3"}');
      final api = DisasterMapApi(
        ApiClient(Dio()..httpClientAdapter = adapter, regions),
      );

      final result = await api.getRestroomDetail(3);

      expect(adapter.urls, [
        'https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/restroom/3',
      ]);
      expect(result, {'name': 'Restroom 3'});
    },
  );

  test(
    'getShelterDetail requests the shelter kind, not aed or restroom',
    () async {
      final adapter = _RecordingAdapter(body: '{"name": "Shelter 9"}');
      final api = DisasterMapApi(
        ApiClient(Dio()..httpClientAdapter = adapter, regions),
      );

      final result = await api.getShelterDetail(9);

      expect(adapter.urls, [
        'https://static.core-tnn1.exptech.dev/api/v2/tiles/dpm/shelter/9',
      ]);
      expect(result, {'name': 'Shelter 9'});
    },
  );
}
