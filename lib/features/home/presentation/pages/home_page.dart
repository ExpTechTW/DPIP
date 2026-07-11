import 'package:flutter/material.dart';

/// Home tab — the landing surface shown on launch.
///
/// Starting scaffold: a large app bar over a scrollable body that will hold the
/// status / weather / earthquake sections as those features land.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Route path.
  static const String path = '/home';

  /// Route name.
  static const String name = 'home';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text('首頁')),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('首頁')),
          ),
        ],
      ),
    );
  }
}
