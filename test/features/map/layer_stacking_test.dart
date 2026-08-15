/// What covers what, on every raster timeline layer.
///
/// The bug this pins: `belowLayerId` inserts a layer *immediately* below its
/// anchor, so when the radar frames and the county/township borders both quoted
/// `town-label`, the borders were on top only until the next frame mounted.
/// Dragging the timeline mounted a frame, which landed above them, and the
/// borders sank under the echo and stayed there — a map you can no longer
/// locate the weather on, which is the whole point of the overlay.
///
/// Nothing in the analyser, the anchors, or a per-layer test can see that: each
/// call is individually correct and the anchors are identical. Only the
/// resulting order shows it, so [RecordingMapController] models MapLibre's
/// insertion and these tests read the stack.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/map/presentation/layers/qpesums_layer.dart';
import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/features/map/presentation/layers/radar_scan_range.dart';
import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/map/presentation/layers/wind_forecast_layer.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:dpip/features/weather/domain/radar_repository.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/features/weather/domain/satellite_repository.dart';
import 'package:dpip/features/weather/domain/wind_field.dart';
import 'package:dpip/features/weather/domain/wind_forecast_model.dart';
import 'package:dpip/features/weather/domain/wind_forecast_repository.dart';
import 'package:dpip/shared/map/admin_outline.dart';
import 'package:dpip/shared/map/map_style.dart'
    show outlineLayerId, satelliteCountyOutlineLayerId, townLabelLayerId;
import 'package:dpip/shared/map/raster_timeline_layer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'raster_timeline_harness.dart';

class _FakeRadar extends FakeRasterFrameSource implements RadarRepository {
  _FakeRadar(super.frames);
  @override
  String tileUrl(String frame) => 'https://host/radar/$frame/{z}/{x}/{y}.webp';
}

class _FakeSatellite extends FakeRasterFrameSource
    implements SatelliteRepository {
  _FakeSatellite(super.frames);
  @override
  String tileUrl(String frame) => 'https://host/sat/$frame/{z}/{x}/{y}.webp';
  @override
  void setStyle(String? style) {}
}

class _FakeQpesums extends FakeRasterFrameSource implements QpesumsRepository {
  _FakeQpesums(super.frames);
  @override
  String tileUrl(String frame) => 'https://host/qpe/$frame/{z}/{x}/{y}.webp';
}

class _FakeWind extends FakeRasterFrameSource
    implements WindForecastRepository {
  _FakeWind(super.frames);
  @override
  String tileUrl(String frame) => 'https://host/wind/$frame/{z}/{x}/{y}.webp';
  @override
  Future<Result<WindField>> fetchWindField(String frame) async => Ok(
    WindField(
      width: 2,
      height: 2,
      lat0: 90,
      lon0: 0,
      dLat: -0.25,
      dLon: 0.25,
      uMin: -1,
      uMax: 1,
      vMin: -1,
      vMax: 1,
      timeMs: 0,
      model: 'gfs',
      u: Uint8List.fromList([127, 127, 127, 127]),
      v: Uint8List.fromList([127, 127, 127, 127]),
    ),
  );
}

List<String> _ids(int n) => [
  for (var i = 0; i < n; i++) '${1700000000 + i * 600}',
];

/// Mounts [layer], shows a frame, then scrubs to another — the sequence that
/// used to sink the borders. Returns the controller and the frame ids.
Future<(RecordingMapController, List<String>)> _scrub(
  RasterTimelineLayer layer,
) async {
  final frames = (await layer.frames()).valueOrNull!;
  final controller = RecordingMapController();
  await layer.prepare(controller, frames);
  await layer.show(controller, frames[4]);
  // Far enough to leave the preload ring, so the target must be *mounted*
  // rather than revealed — mounting is what inserts a new layer.
  await layer.show(controller, frames[8]);
  return (controller, [for (final f in frames) f.id]);
}

void main() {
  test('a scrub never buries the admin borders under the echo', () async {
    final layer = RadarMapLayer(_FakeRadar(_ids(9)));
    final (controller, ids) = await _scrub(layer);

    for (final boundary in [AdminBoundary.county, AdminBoundary.town]) {
      for (final id in ids) {
        final frame = 'radar-lyr-$id';
        if (!controller.order.contains(frame)) continue;
        expect(
          controller.isAbove(boundary.lineLayerId, frame),
          isTrue,
          reason: '${boundary.name} border sank under $frame',
        );
        expect(
          controller.isAbove(boundary.casingLayerId, frame),
          isTrue,
          reason: '${boundary.name} casing sank under $frame',
        );
      }
    }
  });

  test('the borders still stay under the township names', () async {
    final layer = RadarMapLayer(_FakeRadar(_ids(9)));
    final (controller, _) = await _scrub(layer);
    // The labels are the top-most text on every surface: a border line must
    // never cross a place name.
    expect(
      controller.isAbove(townLabelLayerId, AdminBoundary.county.lineLayerId),
      isTrue,
    );
  });

  test('the scan-range circle is drawn over the echo, not under it', () async {
    final layer = RadarMapLayer(_FakeRadar(_ids(9)));
    layer.setShowScanRange(true);
    final (controller, ids) = await _scrub(layer);

    for (final id in ids) {
      final frame = 'radar-lyr-$id';
      if (!controller.order.contains(frame)) continue;
      expect(
        controller.isAbove(RadarScanRange.outlineLayerId, frame),
        isTrue,
        reason: 'the coverage circle was buried under $frame',
      );
    }
  });

  test('the seam sits between the frames and the chrome', () async {
    final layer = RadarMapLayer(_FakeRadar(_ids(9)));
    final (controller, ids) = await _scrub(layer);
    final seam = layer.frameSeamLayerId;

    for (final id in ids) {
      final frame = 'radar-lyr-$id';
      if (!controller.order.contains(frame)) continue;
      expect(controller.isAbove(seam, frame), isTrue, reason: '$frame is high');
    }
    expect(controller.isAbove(AdminBoundary.town.casingLayerId, seam), isTrue);
  });

  test('the seam is torn down with the layer', () async {
    final layer = RadarMapLayer(_FakeRadar(_ids(9)));
    final (controller, _) = await _scrub(layer);
    expect(controller.order, contains(layer.frameSeamLayerId));

    await layer.clear(controller);
    expect(
      controller.order,
      isNot(contains(layer.frameSeamLayerId)),
      reason: 'a left-over seam would anchor the next attach wrongly',
    );
  });

  test('every timeline layer keeps its own chrome above its frames', () async {
    final layers = <RasterTimelineLayer>[
      RadarMapLayer(_FakeRadar(_ids(9))),
      QpesumsMapLayer(_FakeQpesums(_ids(9))),
      WindForecastMapLayer(_FakeWind(_ids(9)), model: WindForecastModel.gfs),
    ];
    for (final layer in layers) {
      final (controller, ids) = await _scrub(layer);
      for (final id in ids) {
        final frame = '${layer.id}-lyr-$id';
        if (!controller.order.contains(frame)) continue;
        expect(
          controller.isAbove(AdminBoundary.county.lineLayerId, frame),
          isTrue,
          reason: '${layer.id}: the county border sank under $frame',
        );
      }
    }
  });

  test('opaque satellite covers the base borders instead of doubling them', () async {
    // It draws its own yellow set on top; leaving the base white one showing as
    // well drew every boundary twice, at two weights and two colours.
    final layer = SatelliteMapLayer(
      _FakeSatellite(_ids(9)),
      channel: SatelliteChannel.irClean,
    );
    final (controller, ids) = await _scrub(layer);
    for (final id in ids) {
      final frame = '${layer.id}-lyr-$id';
      if (!controller.order.contains(frame)) continue;
      expect(
        controller.isAbove(frame, outlineLayerId),
        isTrue,
        reason: 'the base border is still drawn over the imagery',
      );
      expect(
        controller.isAbove(satelliteCountyOutlineLayerId, frame),
        isTrue,
        reason: 'the yellow border sank under the imagery',
      );
    }
  });
}
