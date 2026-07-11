import 'package:dpip/features/map/presentation/widgets/base_map.dart';
import 'package:flutter/material.dart';

/// Full-screen map tab. Currently an empty base map; data layers are added
/// later.
class MapPage extends StatelessWidget {
  const MapPage({super.key});

  /// Route path.
  static const String path = '/map';

  /// Route name.
  static const String name = 'map';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: BaseMap());
  }
}
