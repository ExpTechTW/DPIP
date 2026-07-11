import 'package:flutter/material.dart';

/// "More" menu (settings, about, …). Placeholder pending those features.
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  /// Route path.
  static const String path = '/more';

  /// Route name.
  static const String name = 'more';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('更多')),
      body: const Center(child: Text('更多')),
    );
  }
}
