/// Carries a target framing (and optional overlay) to the map tab.
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
///
/// [layerId] is optional: Home's backdrop tap forces radar (`radar`); the nav
/// bar passes the user's [DefaultMapLayerController] id so a re-tap resets the
/// overlay to match the bar icon (e.g. 衛星 while viewing 雷達).
class MapCameraHandoff extends ChangeNotifier {
  /// The fit box the home backdrop currently frames (nationwide island, or the
  /// selected township). Only the *geography* is handed over — the map re-fits it
  /// into its own visible band, which differs from Home's (no region bar, and a
  /// timeline or a collapsed sheet instead of the weather sheet).
  LatLngBounds? homeBounds;

  LatLngBounds? _pending;
  String? _pendingLayerId;

  /// Requests the map open framed on the home backdrop's current view. No-op if
  /// the backdrop hasn't framed anything yet.
  void requestHomeView({String? layerId}) {
    final bounds = homeBounds;
    if (bounds == null) return;
    request(bounds, layerId: layerId);
  }

  /// Requests the map open framed on [bounds] (e.g. the nationwide view).
  ///
  /// When [layerId] is set, [MapScaffold] switches to that overlay before
  /// framing (must match a `MapLayer.id`).
  void request(LatLngBounds bounds, {String? layerId}) {
    _pending = bounds;
    _pendingLayerId = layerId;
    notifyListeners();
  }

  /// Consumes the pending request, or null when there is none (so the map keeps
  /// its current view / overlay).
  MapCameraRequest? takePending() {
    final bounds = _pending;
    final layerId = _pendingLayerId;
    _pending = null;
    _pendingLayerId = null;
    if (bounds == null) return null;
    return MapCameraRequest(bounds: bounds, layerId: layerId);
  }
}

/// Immutable payload returned by [MapCameraHandoff.takePending].
class MapCameraRequest {
  const MapCameraRequest({required this.bounds, this.layerId});

  final LatLngBounds bounds;

  /// Optional `MapLayer.id` to switch to (e.g. `radar` from Home).
  final String? layerId;
}
