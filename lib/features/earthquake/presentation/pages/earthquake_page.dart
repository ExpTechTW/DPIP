import 'package:flutter/material.dart';

/// Earthquake monitor. Placeholder — this is the swappable bottom-nav slot.
class EarthquakePage extends StatelessWidget {
  const EarthquakePage({super.key});

  /// Route path.
  static const String path = '/earthquake';

  /// Route name.
  static const String name = 'earthquake';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('地震')),
      body: const Center(child: Text('地震')),
    );
  }
}
