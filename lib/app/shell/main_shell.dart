import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The app's persistent bottom-navigation shell.
///
/// Wraps the five top-level branches in an [IndexedStack] (via
/// [StatefulNavigationShell]) so each tab keeps its own navigation state.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  /// The go_router shell that owns the five branches, in the same order as the
  /// destinations built in [build].
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Bottom-navigation destinations, in branch order. The 4th slot
    // (navEarthquake) is intentionally swappable — replace this one entry (and
    // its branch in the router) to surface a different feature there.
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: const Icon(Icons.warning_amber_rounded),
        selectedIcon: const Icon(Icons.warning),
        label: l10n.navEvents,
      ),
      NavigationDestination(
        icon: const Icon(Icons.map_outlined),
        selectedIcon: const Icon(Icons.map),
        label: l10n.navMap,
      ),
      NavigationDestination(
        icon: const Icon(Icons.monitor_heart_outlined),
        selectedIcon: const Icon(Icons.monitor_heart),
        label: l10n.navEarthquake,
      ),
      NavigationDestination(
        icon: const Icon(Icons.menu),
        selectedIcon: const Icon(Icons.menu),
        label: l10n.navMore,
      ),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: destinations,
        onDestinationSelected: (index) {
          // Re-entering Home snaps its sheet back to rest.
          if (index == 0) context.read<HomeResetSignal>().fire();
          navigationShell.goBranch(
            index,
            // Tapping the active tab returns it to its initial route.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
