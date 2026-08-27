/// The typhoon weather underlay's chrome: which border look each underlay
/// draws, and that switching underlays never leaves one behind.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_layer.dart';
import 'package:dpip/features/map/presentation/layers/typhoon_weather_overlay.dart';
import 'package:dpip/features/typhoon/domain/meteor_typhoon_repository.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../raster_timeline_harness.dart';

/// One active cyclone, so the layer gets a bulletin time and a track to draw.
class _FakeTyphoonRepository implements MeteorTyphoonRepository {
  @override
  Future<Result<CycloneIndex>> cyclones() async => Ok(
    const CycloneIndex(
      updated: 1700000000,
      cyclones: [
        TyphoonCyclone(
          name: 'X',
          year: 2026,
          tdNo: '1',
          time: 1700000000,
          latitude: 21,
          longitude: 121,
        ),
      ],
    ),
  );

  @override
  Future<Result<TrackPayload>> track() async => Ok(
    TrackPayload(
      updated: 1700000000,
      cyclones: [
        const TyphoonTrack(
          name: 'X',
          year: 2026,
          tdNo: '1',
          analysis: [
            TrackFix(time: 1700000000 - 3600, latitude: 20, longitude: 120),
          ],
          forecast: [],
        ),
      ],
    ),
  );

  @override
  Future<Result<PotentialPayload>> potential() async =>
      Ok(const PotentialPayload(updated: 1, cyclones: []));

  @override
  Future<Result<TyphoonProbability>> probability() async =>
      Ok(const TyphoonProbability(updated: 1, cyclones: []));

  @override
  Future<Result<WarningPayload>> warning() async =>
      Ok(const WarningPayload(updated: 1, cyclones: []));

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeRadarRepository extends FakeRasterFrameSource
    implements RadarRepository {
  _FakeRadarRepository() : super(['1700000000']) {
    sourceMinZoom = 3;
    sourceMaxZoom = 12;
  }

  @override
  String tileUrl(String frame) => 'https://host/radar/$frame/{z}/{x}/{y}.webp';
}

class _FakeSatelliteRepository extends FakeRasterFrameSource
    implements SatelliteRepository {
  _FakeSatelliteRepository() : super(['1700000000']) {
    sourceMinZoom = 0;
    sourceMaxZoom = 11;
  }

  @override
  String tileUrl(String frame) => 'https://host/sat/$frame/{z}/{x}/{y}.png';

  @override
  void setStyle(String? style) {}
}

TyphoonMapLayer _layer() => TyphoonMapLayer(
  _FakeTyphoonRepository(),
  radar: _FakeRadarRepository(),
  satellite: _FakeSatelliteRepository(),
);

/// Renders the layer (bulletin set, weather overlay defaulted to radar) and
/// lets its queued ops settle.
Future<RecordingMapController> _rendered(TyphoonMapLayer layer) async {
  final controller = RecordingMapController();
  await layer.render(controller);
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return controller;
}

Future<void> _drain() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'each weather underlay carries its own published source range',
    () async {
      final layer = _layer();
      final controller = await _rendered(layer);

      expect(controller.sourceProperties['typhoon-wx-src']?['minzoom'], 3.0);
      expect(controller.sourceProperties['typhoon-wx-src']?['maxzoom'], 12.0);

      layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
      await _drain();

      expect(controller.sourceProperties['typhoon-wx-src']?['minzoom'], 0.0);
      expect(controller.sourceProperties['typhoon-wx-src']?['maxzoom'], 11.0);
    },
  );

  test('the borders stay over the underlay across a re-sync', () async {
    // The chrome sync is diff-based — it re-adds a border only when its toggle
    // changes — so anything that re-mounts the raster has to leave the borders
    // above it. `belowLayerId` inserts immediately below its anchor, which
    // makes "both quote the same anchor" the wrong answer twice over.
    final layer = _layer();
    final controller = await _rendered(layer);

    void check(String when) {
      for (final boundary in [AdminBoundary.county, AdminBoundary.town]) {
        expect(
          controller.isAbove(boundary.lineLayerId, 'typhoon-wx-lyr'),
          isTrue,
          reason: '$when: the ${boundary.name} border sank under the underlay',
        );
      }
    }

    check('on first render');

    // Switch away and back — the path that re-mounts the raster.
    layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
    await _drain();
    layer.setWeatherOverlay(TyphoonWeatherOverlay.radar);
    await _drain();
    check('after switching underlays');
  });

  test('radar underlay draws the shared white cased county frame', () async {
    final layer = _layer();
    final controller = await _rendered(layer);

    expect(
      controller.calls,
      containsAll([
        'addLineLayer:${AdminBoundary.county.casingLayerId}',
        'addLineLayer:${AdminBoundary.county.lineLayerId}',
      ]),
    );
    expect(
      controller.lineColorOf(AdminBoundary.county.lineLayerId),
      AdminOutline.lineColor,
      reason: 'the radar underlay keeps the default white core',
    );
    expect(
      controller.calls,
      isNot(contains('addLineLayer:$satelliteCountyOutlineLayerId')),
    );
  });

  test(
    'satellite underlay swaps the county frame for the bare yellow line',
    () async {
      final layer = _layer();
      final controller = await _rendered(layer);

      controller.calls.clear();
      layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
      await _drain();

      expect(
        controller.calls,
        contains('addLineLayer:$satelliteCountyOutlineLayerId'),
        reason:
            'the IR underlay draws its county frame like the standalone '
            'B13 layer — one bare line, no casing',
      );
      expect(
        controller.lineColorOf(satelliteCountyOutlineLayerId),
        satelliteOutlineColor,
      );
      expect(
        controller.belowOf(satelliteCountyOutlineLayerId),
        isNotNull,
        reason: 'the frame still sits under the typhoon vectors',
      );
      expect(
        controller.calls,
        isNot(contains('addLineLayer:${AdminBoundary.county.casingLayerId}')),
        reason: 'no black casing is drawn under the IR image',
      );
      expect(
        controller.calls,
        containsAll([
          'removeLayer:${AdminBoundary.county.casingLayerId}',
          'removeLayer:${AdminBoundary.county.lineLayerId}',
        ]),
        reason: 'the radar look is taken down when the underlay switches',
      );
    },
  );

  test('switching back to radar removes the satellite county frame', () async {
    final layer = _layer();
    final controller = await _rendered(layer);

    layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
    await _drain();
    controller.calls.clear();

    layer.setWeatherOverlay(TyphoonWeatherOverlay.radar);
    await _drain();

    expect(
      controller.calls,
      contains('removeLayer:$satelliteCountyOutlineLayerId'),
      reason: 'the bare yellow line must not survive over the radar echo',
    );
    expect(
      controller.calls,
      contains('addLineLayer:${AdminBoundary.county.casingLayerId}'),
      reason: 'the cased white frame comes back with the radar underlay',
    );
  });

  test('the county toggle removes whichever look is on', () async {
    final layer = _layer();
    final controller = await _rendered(layer);

    layer.setWeatherOverlay(TyphoonWeatherOverlay.satellite);
    await _drain();
    controller.calls.clear();

    layer.setShowCountyOutline(false);
    await _drain();

    expect(
      controller.calls,
      contains('removeLayer:$satelliteCountyOutlineLayerId'),
      reason: 'turning the county frame off over IR takes the bare line down',
    );
    expect(
      controller.calls,
      contains('removeLayer:${AdminBoundary.county.lineLayerId}'),
      reason:
          'the cased ids are torn down too — the removal is unconditional '
          'because the teardown cannot know which look was drawn',
    );
  });
}
