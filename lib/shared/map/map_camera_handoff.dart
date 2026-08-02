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
  /// The fit box the home backdrop currently frames (nationwide island, or the
  /// selected township). Only the *geography* is handed over — the map re-fits it
  /// into its own visible band, which differs from Home's (no region bar, and a
  /// timeline or a collapsed sheet instead of the weather sheet).
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
