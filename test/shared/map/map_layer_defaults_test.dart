/// The default [MapLayer] bodies are empty on purpose: a layer that does not
/// use a hook must still be safe for the scaffold to call. Equality of
/// [MapFrame] is by id and time, and a hand-off hides the outgoing layer.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../features/map/raster_timeline_harness.dart';

class _Bare with MapLayerDefaults implements MapLayer {
  _Bare(this.id);

  @override
  final String id;

  bool? surface;

  @override
  void onSurfaceVisibility(bool visible) => surface = visible;

  @override
  String label(BuildContext context) => id;

  @override
  IconData get icon => Icons.layers;

  @override
  bool get usesTimeline => false;

  @override
  double get bottomChromeFraction => 0;

  @override
  Future<void> clear(MapLibreMapController controller) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('two frames match only when id and time both match', () {
    final time = DateTime.utc(2026, 1, 1);
    const a = 'a';
    final left = MapFrame(id: a, time: time);
    expect(left, MapFrame(id: a, time: time));
    expect(left.hashCode, MapFrame(id: a, time: time).hashCode);
    expect(left == MapFrame(id: 'b', time: time), isFalse);
    expect(left == Object(), isFalse);
  });

  test('now without an explicit clock uses the calibrated instant', () {
    final at = AppTime.utc;
    final frames = [
      MapFrame(id: 'past', time: at.subtract(const Duration(hours: 2))),
      MapFrame(id: 'future', time: at.add(const Duration(hours: 2))),
    ];
    expect(nowFrameIndex(frames), 0);
  });

  testWidgets('defaults do nothing and a hand-off records surface visibility', (
    tester,
  ) async {
    final previous = _Bare('out');
    final next = _Bare('in');
    final map = RecordingMapController();
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    final context = tester.element(find.byType(SizedBox));
    expect(await previous.frames(), const Ok(<MapFrame>[]));
    expect(previous.subtitle(context), isNull);
    await previous.prepare(map, const []);
    await previous.show(map, MapFrame(id: 'f', time: DateTime.utc(2026)));
    await previous.render(map);
    await previous.onMapTap(const LatLng(23, 121), map);
    previous.selectFeature('x');
    expect(previous.buildSheet(context), isA<SizedBox>());
    expect(previous.buildLegend(context), isA<SizedBox>());
    expect(previous.buildLegendAccessory(context), isNull);
    expect(previous.overlayFollowsCamera, isTrue);
    expect(previous.buildMapOverlay(context), isA<SizedBox>());
    expect(
      previous.buildTopTrailingChrome(
        context,
        showTownLabels: ValueNotifier(true),
        onShowTownLabelsChanged: (_) {},
        showTerrain: ValueNotifier(true),
        onShowTerrainChanged: (_) {},
        onReloadActive: () async {},
      ),
      isA<SizedBox>(),
    );
    await previous.onCameraIdle(map);
    previous.onMapIdle();
    previous.onTimelineScrubStart();
    await previous.onAmbientCacheCleared(map);
    previous.onMapGestureStart();
    previous.onMapGestureEnd();
    await previous.onMemoryPressure(map);
    previous.onStyleReset();
    expect(previous.mapMinZoom, isNonNegative);
    expect(previous.mapMaxZoom, greaterThan(previous.mapMinZoom));

    handoffMapLayerVisibility(
      previous: previous,
      next: next,
      surfaceVisible: true,
    );
    expect(previous.surface, isFalse);
    expect(next.surface, isTrue);
  });
}
