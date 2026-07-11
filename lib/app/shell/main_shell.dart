import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app's persistent bottom-navigation shell.
///
/// Wraps the five top-level branches in an [IndexedStack] (via
/// [StatefulNavigationShell]) so each tab keeps its own navigation state.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  /// The go_router shell that owns the five branches, in the same order as
  /// [_destinations].
  final StatefulNavigationShell navigationShell;

  /// Bottom-navigation destinations, in branch order.
  ///
  /// The 4th slot (地震) is intentionally swappable — replace this one entry
  /// (and its branch in the router) to surface a different feature there.
  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '首頁',
    ),
    NavigationDestination(
      icon: Icon(Icons.warning_amber_rounded),
      selectedIcon: Icon(Icons.warning),
      label: '事件',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: '地圖',
    ),
    NavigationDestination(
      icon: Icon(Icons.monitor_heart_outlined),
      selectedIcon: Icon(Icons.monitor_heart),
      label: '地震',
    ),
    NavigationDestination(
      icon: Icon(Icons.menu),
      selectedIcon: Icon(Icons.menu),
      label: '更多',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the active tab returns it to its initial route.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
