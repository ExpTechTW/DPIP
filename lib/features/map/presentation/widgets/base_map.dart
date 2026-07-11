import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// An empty base map centred on Taiwan, matching the legacy map framing.
///
/// Uses a minimal raster style as a placeholder; the ExpTech vector style and
/// data layers (stations, RTS, radar, …) are added in later work.
class BaseMap extends StatelessWidget {
  const BaseMap({super.key});

  /// Centre of Taiwan (matches the legacy `DpipMap.kTaiwanCenter`).
  static const LatLng _center = LatLng(23.60, 120.85);
  static const double _zoom = 6.4;

  /// Minimal raster base style — no data layers.
  static const String _emptyStyle = '''
{
  "version": 8,
  "sources": {
    "osm": {
      "type": "raster",
      "tiles": ["https://tile.openstreetmap.org/{z}/{x}/{y}.png"],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors"
    }
  },
  "layers": [{ "id": "osm", "type": "raster", "source": "osm" }]
}
''';

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      styleString: _emptyStyle,
      initialCameraPosition: const CameraPosition(target: _center, zoom: _zoom),
      minMaxZoomPreference: const MinMaxZoomPreference(4, 11),
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }
}
