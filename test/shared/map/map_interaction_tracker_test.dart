import 'package:dpip/shared/map/map_interaction_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late int starts;
  late int ends;
  late MapInteractionTracker tracker;

  setUp(() {
    starts = 0;
    ends = 0;
    tracker = MapInteractionTracker(
      onStart: () => starts++,
      onEnd: () => ends++,
    );
  });

  test('pinch stays active until both pointers leave', () {
    tracker.pointerDown(1);
    tracker.pointerDown(2);

    expect(starts, 1);
    expect(tracker.pointerEnded(1, cameraMoving: false), isFalse);
    expect(tracker.cameraIdle(), isFalse);
    expect(ends, 0);

    expect(tracker.pointerEnded(2, cameraMoving: false), isTrue);
    expect(ends, 1);
  });

  test('camera-only zoom stays active until idle', () {
    tracker.cameraMoved();
    tracker.cameraMoved();

    expect(starts, 1);
    expect(ends, 0);

    expect(tracker.cameraIdle(), isTrue);
    expect(ends, 1);
  });

  test('pointer release waits for camera inertia to settle', () {
    tracker.pointerDown(7);

    expect(tracker.pointerEnded(7, cameraMoving: true), isFalse);
    expect(ends, 0);

    expect(tracker.cameraIdle(), isTrue);
    expect(ends, 1);
  });
}
