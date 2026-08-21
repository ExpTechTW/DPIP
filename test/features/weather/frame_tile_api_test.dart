import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/weather/data/frame_tile_api.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Dio adapter that records requested URLs and answers a fixed JSON body.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.body = '[1783360200, 600]'});

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

  group('FrameTileApi.windFramesFromList', () {
    test('pairs each valid time with its own cycle, newest first', () {
      expect(
        FrameTileApi.windFramesFromList([
          {'t': 1783360200, 'c': 1783339200},
          {'t': 1783367400, 'c': 1783360800},
          {'t': 1783363800, 'c': 1783360800},
        ]),
        [
          '1783367400@1783360800',
          '1783363800@1783360800',
          '1783360200@1783339200',
        ],
      );
    });

    test('rejects a row without either timestamp', () {
      expect(
        () => FrameTileApi.windFramesFromList([
          {'t': 1783360200},
        ]),
        throwsFormatException,
      );
    });

    test('rejects a wind id that cannot pin both time and cycle', () {
      expect(
        () => FrameTileApi.windFrameParts('1783360200'),
        throwsFormatException,
      );
    });
  });

  group('FrameTileApi channel-scoped list', () {
    late RegionSelection regions;

    setUp(() async {
      regions = RegionSelection(SettingsStore.inMemory({}));
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
      expect(adapter.urls[0], endsWith('/api/v2/tiles/satellite/13/list'));
      expect(adapter.urls[1], endsWith('/api/v2/tiles/satellite/14/list'));
    });

    test('raw and named channels occupy distinct paths', () async {
      final adapter = _RecordingAdapter();
      final client = ApiClient(Dio()..httpClientAdapter = adapter, regions);
      final b13 = FrameTileApi(client, 'satellite', channel: '13');
      final product = FrameTileApi(client, 'satellite', channel: 'btd_wvirw');

      await b13.getFrames();
      await product.getFrames();

      expect(adapter.urls, hasLength(2));
      expect(adapter.urls[0], isNot(adapter.urls[1]));
      expect(adapter.urls[0], contains('/satellite/13/list'));
      expect(adapter.urls[1], contains('/satellite/btd_wvirw/list'));
    });

    test('satellite tiles put channel and canonical style in the path', () {
      final adapter = _RecordingAdapter();
      final client = ApiClient(Dio()..httpClientAdapter = adapter, regions);
      final band = FrameTileApi(client, 'satellite', channel: '13');
      final product = FrameTileApi(
        client,
        'satellite',
        channel: 'btd_wvirw',
        style: 'bd',
      );

      expect(
        band.tileUrl('1783360200'),
        contains('/satellite/13/normal/1783360200/{z}/{x}/{y}.webp'),
      );
      band.style = 'jma';
      expect(
        band.tileUrl('1783360200'),
        contains('/satellite/13/jma/1783360200/{z}/{x}/{y}.webp'),
      );
      expect(
        product.tileUrl('1783360200'),
        contains('/satellite/btd_wvirw/normal/1783360200/{z}/{x}/{y}.webp'),
      );
    });

    test('each wind model hits its own list endpoint', () async {
      final adapter = _RecordingAdapter(
        body:
            '[{"t":1783360200,"c":1783339200},'
            '{"t":1783363800,"c":1783360800}]',
      );
      final client = ApiClient(Dio()..httpClientAdapter = adapter, regions);
      final gfs = FrameTileApi(client, 'wind', model: 'gfs');
      final ecmwf = FrameTileApi(client, 'wind', model: 'ecmwf');

      final frames = await gfs.getFrames();
      await ecmwf.getFrames();

      expect(frames, ['1783363800@1783360800', '1783360200@1783339200']);
      expect(adapter.urls, hasLength(2));
      expect(adapter.urls[0], isNot(adapter.urls[1]));
      expect(adapter.urls[0], endsWith('/api/v2/tiles/wind/gfs/list'));
      expect(adapter.urls[1], endsWith('/api/v2/tiles/wind/ecmwf/list'));
      // The tile URL template carries the model too, so MapLibre and the
      // warmer fetch the same field the list named.
      expect(
        gfs.tileUrl('1783360200@1783339200'),
        contains('/wind/gfs/1783339200/1783360200/{z}/{x}/{y}.webp'),
      );
      expect(
        ecmwf.tileUrl('1783360200@1783339200'),
        contains('/wind/ecmwf/1783339200/1783360200/{z}/{x}/{y}.webp'),
      );
    });

    test('a newer cycle gives the same valid time a different tile URL', () {
      final adapter = _RecordingAdapter();
      final client = ApiClient(Dio()..httpClientAdapter = adapter, regions);
      final gfs = FrameTileApi(client, 'wind', model: 'gfs');

      final old = gfs.tileUrl('1783360200@1783339200');
      final current = gfs.tileUrl('1783360200@1783360800');

      expect(old, isNot(current));
    });

    test('fetchWindBin targets the v1 binary endpoint per model', () async {
      final adapter = _RecordingAdapter();
      final client = ApiClient(Dio()..httpClientAdapter = adapter, regions);
      final gfs = FrameTileApi(client, 'wind', model: 'gfs');

      await gfs.fetchWindBin('1783360200@1783339200');

      expect(adapter.urls, hasLength(1));
      expect(
        adapter.urls.single,
        contains('/api/v1/wind/gfs/1783339200/1783360200.bin'),
      );
    });
  });
}
