import 'package:dpip/shared/map/map_style.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// The app's reusable base map — a MapLibre map centred on Taiwan.
///
/// This is the shared foundation every map surface builds on (home backdrop,
/// map tab, radar preview, event viewers). It is layer-agnostic: callers add
/// their own sources/layers in [onMapCreated] via the [MapLibreMapController],
/// typically anchoring overlays above [baseLayerId].
class BaseMap extends StatelessWidget {
  const BaseMap({super.key, this.onMapCreated, this.onStyleLoaded});

  /// Centre of Taiwan.
  static const LatLng taiwanCenter = LatLng(23.60, 120.85);

  /// Default zoom framing the whole island.
  static const double taiwanZoom = 6.4;

  /// Fixed 4–11 zoom range — the radar echo tiles require it.
  static const MinMaxZoomPreference zoomRange = MinMaxZoomPreference(4, 11);

  /// Called with the controller once the map is ready — add overlay layers here.
  final void Function(MapLibreMapController controller)? onMapCreated;

  /// Called once the style has finished loading (safe to add layers after this).
  final VoidCallback? onStyleLoaded;

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      initialCameraPosition: const CameraPosition(
        target: taiwanCenter,
        zoom: taiwanZoom,
      ),
      styleString: osmRasterStyle,
      minMaxZoomPreference: zoomRange,
      trackCameraPosition: true,
      onMapCreated: onMapCreated,
      onStyleLoadedCallback: onStyleLoaded,
    );
  }
}
