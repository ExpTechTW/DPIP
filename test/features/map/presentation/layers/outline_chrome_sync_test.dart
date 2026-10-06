/// Turning an admin border or the scan-range ring off removes the layers that
/// turning it on added. A throw while adding is logged and does not stick the
/// "already shown" flag.
library;

import 'package:dpip/features/map/presentation/layers/qpesums_layer.dart';
import 'package:dpip/features/weather/domain/qpesums_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../raster_timeline_harness.dart';

class _Repo extends FakeRasterFrameSource implements QpesumsRepository {
  _Repo() : super(const []);

  @override
  String tileUrl(String frame) => 'https://example.invalid/{z}/{x}/{y}';
}

class _ThrowingLines extends RecordingMapController {
  @override
  Future<void> addLineLayer(
    String sourceId,
    String layerId,
    LineLayerProperties properties, {
    String? belowLayerId,
    String? sourceLayer,
    double? minzoom,
    double? maxzoom,
    dynamic filter,
    bool enableInteraction = true,
  }) async {
    throw StateError('style gone');
  }
}

void main() {
  test('toggling a border adds it and turning it off removes it', () async {
    final outline = testReferenceOutline();
    final layer = QpesumsMapLayer(_Repo(), outline);
    final map = RecordingMapController();
    await layer.onAttached(map);
    await _until(map, 'addLineLayer:admin-county-outline');
    await _until(map, 'addLineLayer:admin-town-outline');
    expect(map.calls, contains('addLineLayer:admin-town-outline'));
    expect(map.calls, contains('addLineLayer:admin-global-outline'));
    expect(map.calls, contains('addSource:qpesums-scan-range'));

    map.calls.clear();
    layer.setShowCountyOutline(false);
    layer.setShowTownOutline(false);
    layer.setShowGlobalOutline(false);
    layer.setShowScanRange(false);
    await _until(map, 'removeLayer:admin-county-outline');
    expect(map.calls, contains('removeLayer:admin-town-outline'));
    expect(map.calls, contains('removeLayer:admin-global-outline'));
    expect(map.calls, contains('removeLayer:qpesums-scan-range-outline'));

    await layer.onDetached(map);
  });

  test('a failed add does not leave the outline marked as shown', () async {
    final layer = QpesumsMapLayer(_Repo(), testReferenceOutline());
    await layer.onAttached(_ThrowingLines());
    final fresh = RecordingMapController();
    layer.onStyleReset();
    await layer.onAttached(fresh);
    await _until(fresh, 'addLineLayer:admin-county-outline');
  });
}

Future<void> _until(RecordingMapController map, String call) async {
  for (var i = 0; i < 20 && !map.calls.contains(call); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(map.calls, contains(call));
}
