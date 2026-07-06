import 'package:flutter/material.dart';

/// Landing page shown on launch.
///
/// Placeholder for the home feature; replaced as the rewrite progresses.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Route path for this page.
  static const String path = '/';

  /// Route name for this page.
  static const String name = 'home';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.public, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('DPIP', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Disaster Prevention Information Platform',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
