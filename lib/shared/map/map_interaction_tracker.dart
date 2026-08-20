import 'package:flutter/foundation.dart';

/// Keeps map interaction active until every pointer is up and camera motion
/// has settled.
///
/// A one-finger pan can be described by one down/up pair, but a pinch cannot:
/// ending on the first lifted finger briefly restores screen-space overlays
/// while the second finger is still controlling the map. Camera callbacks also
/// cover animated, wheel, and accessibility zooms that have no pointer-down
/// event in Flutter's overlay tree.
class MapInteractionTracker {
  MapInteractionTracker({required this.onStart, required this.onEnd});

  final VoidCallback onStart;
  final VoidCallback onEnd;

  final Set<int> _pointers = <int>{};
  bool _active = false;

  bool get hasPointers => _pointers.isNotEmpty;

  void pointerDown(int pointer) {
    _pointers.add(pointer);
    _start();
  }

  /// Returns true when this event ended the whole interaction.
  bool pointerEnded(int pointer, {required bool cameraMoving}) {
    _pointers.remove(pointer);
    if (_pointers.isNotEmpty || cameraMoving) return false;
    return _finish();
  }

  void cameraMoved() => _start();

  /// Returns true when camera idle ended the whole interaction.
  bool cameraIdle() => _pointers.isEmpty && _finish();

  void _start() {
    if (_active) return;
    _active = true;
    onStart();
  }

  bool _finish() {
    if (!_active) return false;
    _active = false;
    onEnd();
    return true;
  }
}
