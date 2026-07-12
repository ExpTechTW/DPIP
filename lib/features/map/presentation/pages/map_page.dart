import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/map/data/radar_api.dart';
import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/shared/map/base_map.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

/// Full-screen map tab — the base map with the latest radar echo overlaid.
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  /// Route path.
  static const String path = '/map';

  /// Route name.
  static const String name = 'map';

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MapLibreMapController? _controller;

  Future<void> _onStyleLoaded() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      await RadarLayer(controller, context.read<RadarApi>()).showLatest();
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Failed to add radar layer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BaseMap(
        onMapCreated: (controller) => _controller = controller,
        onStyleLoaded: _onStyleLoaded,
      ),
    );
  }
}
