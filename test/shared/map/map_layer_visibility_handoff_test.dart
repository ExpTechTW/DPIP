import 'package:dpip/shared/map/map_layer.dart';
import 'package:flutter_test/flutter_test.dart';

class _VisibilityLayer implements MapLayer {
  _VisibilityLayer(this.id);

  @override
  final String id;

  final visibility = <bool>[];

  @override
  void onSurfaceVisibility(bool visible) => visibility.add(visible);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('selecting a layer restores the current surface visibility', () {
    final radar = _VisibilityLayer('radar');
    final monitor = _VisibilityLayer('monitor');

    // The monitor last owned the map when the user left its shell tab.
    monitor.onSurfaceVisibility(false);
    handoffMapLayerVisibility(
      previous: radar,
      next: monitor,
      surfaceVisible: true,
    );

    expect(radar.visibility, [false]);
    expect(
      monitor.visibility,
      [false, true],
      reason: 'the selected monitor must be allowed to replay its current EEW',
    );
  });

  test('selecting while the map is hidden keeps the new layer hidden', () {
    final radar = _VisibilityLayer('radar');
    final monitor = _VisibilityLayer('monitor');

    handoffMapLayerVisibility(
      previous: radar,
      next: monitor,
      surfaceVisible: false,
    );

    expect(radar.visibility, [false]);
    expect(monitor.visibility, [false]);
  });
}
