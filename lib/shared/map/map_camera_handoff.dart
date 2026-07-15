/// Carries a target framing to the map tab so it can open on a specific view.
library;

import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// A hand-off of "frame the map to these bounds when it next opens".
///
/// The home backdrop keeps [homeBounds] in sync with what it currently shows;
/// tapping it (only when a current/saved township is selected) requests that
/// same view so the map tab lands on it. Every other entry — the nav bar, or a
/// tap while 全國 / a GPS-less 所在地 is selected — requests the nationwide
/// framing instead. The map surface consumes one pending request per open (a
/// one-shot), so a later manual pan/zoom is never clobbered.
class MapCameraHandoff extends ChangeNotifier {
  /// The geography currently VISIBLE in the home band (the screen above the
  /// resting sheet), projected from the backdrop's camera — not the raw fit box.
  /// The map fits it full-screen, so handing off the visible band (rather than
  /// the box the backdrop fit into a shorter viewport) reproduces the same
  /// horizontal framing instead of re-fitting at a different scale.
  LatLngBounds? homeBounds;

  LatLngBounds? _pending;

  /// Requests the map open framed on the home backdrop's current view. No-op if
  /// the backdrop hasn't framed anything yet.
  void requestHomeView() {
    final bounds = homeBounds;
    if (bounds == null) return;
    request(bounds);
  }

  /// Requests the map open framed on [bounds] (e.g. the nationwide view).
  void request(LatLngBounds bounds) {
    _pending = bounds;
    notifyListeners();
  }

  /// Consumes the pending request, or null when there is none (so the map keeps
  /// its current view).
  LatLngBounds? takePending() {
    final bounds = _pending;
    _pending = null;
    return bounds;
  }
}
