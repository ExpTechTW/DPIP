import 'package:flutter/material.dart';

/// Disaster-event feed. Placeholder pending the events feature.
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  /// Route path.
  static const String path = '/events';

  /// Route name.
  static const String name = 'events';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('事件')),
      body: const Center(child: Text('事件')),
    );
  }
}
