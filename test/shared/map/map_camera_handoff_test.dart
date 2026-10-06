/// A camera hand-off is one-shot: requesting the home view does nothing until
/// the backdrop has framed a box, and [MapCameraHandoff.takePending] clears
/// the request so a later pan is left alone.
library;

import 'package:dpip/shared/map/map_camera_handoff.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

void main() {
  test('home view is a no-op until the backdrop has bounds', () {
    final handoff = MapCameraHandoff();
    var notices = 0;
    handoff.addListener(() => notices++);
    expect(handoff.hasPending, isFalse);
    handoff.requestHomeView(layerId: 'radar');
    expect(handoff.hasPending, isFalse);
    expect(handoff.takePending(), isNull);
    expect(notices, 0);

    final bounds = LatLngBounds(
      southwest: const LatLng(21, 119),
      northeast: const LatLng(26, 123),
    );
    handoff.homeBounds = bounds;
    handoff.requestHomeView(layerId: 'radar');
    expect(handoff.hasPending, isTrue);
    expect(notices, 1);
    final pending = handoff.takePending();
    expect(pending!.bounds, bounds);
    expect(pending.layerId, 'radar');
    expect(handoff.hasPending, isFalse);
    expect(handoff.takePending(), isNull);
  });

  test('an explicit request can omit the layer', () {
    final handoff = MapCameraHandoff();
    final bounds = LatLngBounds(
      southwest: const LatLng(22, 120),
      northeast: const LatLng(25, 122),
    );
    handoff.request(bounds);
    expect(handoff.takePending()!.layerId, isNull);
  });
}
