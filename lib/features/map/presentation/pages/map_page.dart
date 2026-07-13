import 'package:dpip/features/map/presentation/layers/radar_layer.dart';
import 'package:dpip/shared/map/map_layer.dart';
import 'package:dpip/shared/map/map_scaffold.dart';
import 'package:dpip/shared/map/radar_repository.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Full-screen map tab.
///
/// Just business logic now: it names the layers this surface offers and hands
/// them to [MapScaffold], which owns the map, the layer switcher, and the
/// timeline. Adding radar/rain/lightning/… later is one more entry in [_layers].
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Built once so each layer keeps its own MapLibre state across rebuilds.
  late final List<MapLayer> _layers = [
    RadarMapLayer(context.read<RadarRepository>()),
  ];

  @override
  Widget build(BuildContext context) => MapScaffold(layers: _layers);
}
