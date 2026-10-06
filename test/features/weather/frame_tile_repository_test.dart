import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/region_selection.dart';
import 'package:dpip/core/settings/settings_store.dart';
import 'package:dpip/features/weather/data/frame_tile_api.dart';
import 'package:dpip/features/weather/data/frame_tile_repository.dart';
import 'package:dpip/shared/map/map_tile_warmer.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path.endsWith('.bin')) {
      return ResponseBody.fromBytes(Uint8List(8), 200);
    }
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late FrameTileRepositoryImpl repo;

  setUp(() {
    final regions = RegionSelection(SettingsStore.inMemory({}));
    final api = FrameTileApi(
      ApiClient(Dio()..httpClientAdapter = _Adapter(), regions),
      'radar',
    );
    repo = FrameTileRepositoryImpl(api, MapTileWarmer(null));
  });

  test('an empty frame list or a non-finite zoom warms nothing', () async {
    await repo.warmFrameTiles(
      frames: const [],
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: 6,
    );
    await repo.warmFrameTiles(
      frames: const ['1783360200'],
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: double.nan,
    );
    final unread = await repo.frameTileReadiness(
      frame: '1783360200',
      south: 22,
      west: 120,
      north: 25,
      east: 122,
      zoom: double.nan,
    );
    expect(unread.ready, isFalse);
    expect(unread.required, 0);
  });

  test(
    'a viewport warm fills every level and a second ask reuses it',
    () async {
      await repo.warmFrameTiles(
        frames: const ['1783360200', '1783360800'],
        south: 23,
        west: 120.5,
        north: 25,
        east: 121.8,
        zoom: 6,
        fill: true,
        immediate: true,
        refreshResident: true,
      );
      final cold = await repo.frameTileReadiness(
        frame: '1783360200',
        south: 23,
        west: 120.5,
        north: 25,
        east: 121.8,
        zoom: 6,
      );
      expect(cold.required, greaterThan(0));
      expect(cold.ready, isFalse);
      final warmed = await repo.frameTileReadiness(
        frame: '1783360200',
        south: 23,
        west: 120.5,
        north: 25,
        east: 121.8,
        zoom: 6,
        warm: true,
      );
      expect(warmed.required, cold.required);
      expect(warmed.resident, 0);

      expect(repo.sourceMaxZoom, 11);
      expect(repo.sourceMinZoom, 0);
      expect(repo.tileUrl('1783360200'), contains('/radar/1783360200/{z}/'));
      final frames = await repo.frames();
      expect(frames.valueOrNull, isNotEmpty);
      final field = await repo.fetchWindField('1@2');
      expect(field.failureOrNull, isNotNull);
      repo.setStyle('jma');
      repo.cancelTileWarm();
      await repo.abandonFrames(const ['1783360200']);
      await repo.releaseTiles();
    },
  );
}
