import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/prefs.dart';
import 'package:dpip/features/weather/data/frame_tile_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A Dio adapter that records the URLs it is asked to fetch and answers a
/// fixed delta-encoded list, so the list endpoint a channel resolves to is
/// observable without a network.
class _RecordingAdapter implements HttpClientAdapter {
  final List<String> urls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    urls.add(options.uri.toString());
    return ResponseBody.fromString(
      '[1783360200, 600]',
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
  group('FrameTileApi.framesFromList', () {
    test('decodes delta-seconds and returns them newest first', () {
      // [baseSec, +600, +600] → 1783360200, 1783360800, 1783361400 (10-min steps)
      expect(FrameTileApi.framesFromList([1783360200, 600, 600]), [
        '1783361400',
        '1783360800',
        '1783360200',
      ]);
    });

    test('decodes delta-millis (QPESUMS) the same way', () {
      // [baseMs, +600000, +600000] → 1786208400000, 1786209000000,
      // 1786209600000 (10-min steps)
      expect(FrameTileApi.framesFromList([1786208400000, 600000, 600000]), [
        '1786209600000',
        '1786209000000',
        '1786208400000',
      ]);
    });

    test('an empty list yields no frames', () {
      expect(FrameTileApi.framesFromList(const []), isEmpty);
    });

    test('a single-frame list is just the base timestamp', () {
      expect(FrameTileApi.framesFromList([1783360200]), ['1783360200']);
    });

    test('frame ids keep their digit width, usable straight in a tile URL', () {
      final seconds = FrameTileApi.framesFromList([1783360200, 600]);
      expect(seconds.first.length, 10);
      final millis = FrameTileApi.framesFromList([1786208400000, 600000]);
      expect(millis.first.length, 13);
    });
  });

  group('FrameTileApi channel-scoped list', () {
    late RegionSelection regions;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      regions = RegionSelection(Prefs(await SharedPreferences.getInstance()));
    });

    test('each satellite channel hits its own list endpoint', () async {
      final adapter = _RecordingAdapter();
      final client = ApiClient(Dio()..httpClientAdapter = adapter, regions);
      final b13 = FrameTileApi(client, 'satellite', channel: '13');
      final b14 = FrameTileApi(client, 'satellite', channel: '14');

      await b13.getFrames();
      await b14.getFrames();

      expect(adapter.urls, hasLength(2));
      expect(adapter.urls[0], isNot(adapter.urls[1]));
      expect(adapter.urls[0], contains('list?channel=13'));
      expect(adapter.urls[1], contains('list?channel=14'));
    });

    test('channels with no query stay distinct from named channels', () async {
      final adapter = _RecordingAdapter();
      final client = ApiClient(Dio()..httpClientAdapter = adapter, regions);
      final b13 = FrameTileApi(client, 'satellite', channel: '13');
      final product = FrameTileApi(client, 'satellite', channel: 'btd_wvirw');

      await b13.getFrames();
      await product.getFrames();

      expect(adapter.urls, hasLength(2));
      expect(adapter.urls[0], isNot(adapter.urls[1]));
      expect(adapter.urls[0], contains('channel=13'));
      expect(adapter.urls[1], contains('channel=btd_wvirw'));
    });
  });
}
