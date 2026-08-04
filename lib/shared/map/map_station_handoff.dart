/// Carries a "open this station on the map" intent from another tab.
library;

import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// One-shot hand-off: switch to [layerId], frame [bounds], open the station
/// sheet for [stationId]. Consumed by [MapScaffold] the same way
/// [MapCameraHandoff] is — pending until the map is onstage and styled.
class MapStationHandoff extends ChangeNotifier {
  _PendingStation? _pending;

  /// Queues a station focus. [layerId] must match a [MapLayer.id] that hosts a
  /// station sheet (`temperature` / `humidity` / `pressure` / `wind` / `rain`).
  void request({
    required String layerId,
    required String stationId,
    required double latitude,
    required double longitude,
  }) {
    // ~5 km box so safeFitBounds has span without zooming to house-level.
    const pad = 0.025;
    _pending = _PendingStation(
      layerId: layerId,
      stationId: stationId,
      bounds: LatLngBounds(
        southwest: LatLng(latitude - pad, longitude - pad),
        northeast: LatLng(latitude + pad, longitude + pad),
      ),
    );
    notifyListeners();
  }

  /// Consumes the pending request, or null when there is none.
  MapStationRequest? takePending() {
    final pending = _pending;
    _pending = null;
    if (pending == null) return null;
    return MapStationRequest(
      layerId: pending.layerId,
      stationId: pending.stationId,
      bounds: pending.bounds,
    );
  }
}

/// Immutable payload returned by [MapStationHandoff.takePending].
class MapStationRequest {
  const MapStationRequest({
    required this.layerId,
    required this.stationId,
    required this.bounds,
  });

  final String layerId;
  final String stationId;
  final LatLngBounds bounds;
}

class _PendingStation {
  const _PendingStation({
    required this.layerId,
    required this.stationId,
    required this.bounds,
  });

  final String layerId;
  final String stationId;
  final LatLngBounds bounds;
}
