import 'package:dpip/core/settings/home_backdrop_reveal.dart';
import 'package:dpip/features/home/presentation/home_reset_signal.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// The app's persistent bottom-navigation shell.
///
/// Wraps the five top-level branches in an [IndexedStack] (via
/// [StatefulNavigationShell]) so each tab keeps its own navigation state. The
/// body extends behind the bar so, on Home, the weather backdrop shows through
/// it; the bar then fades transparent and flips its icons/labels to light as the
/// weather reveals ([HomeBackdropReveal]) instead of leaving an opaque strip.
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
      // Let the Home weather backdrop show through behind the bar.
      extendBody: true,
      body: navigationShell,
      // Only Home immerses; every other tab keeps the opaque bar (reveal 0).
      bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: context.read<HomeBackdropReveal>(),
        builder: (context, homeReveal, _) => _navBar(
          context,
          destinations,
          navigationShell.currentIndex == 0 ? homeReveal : 0,
        ),
      ),
    );
  }

  Widget _navBar(
    BuildContext context,
    List<NavigationDestination> destinations,
    double reveal,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final iconColor = Color.lerp(
      colors.onSurfaceVariant,
      Colors.white,
      reveal,
    )!;
    final selectedIconColor = Color.lerp(
      colors.onSecondaryContainer,
      Colors.white,
      reveal,
    )!;
    final labelColor = Color.lerp(
      colors.onSurfaceVariant,
      Colors.white,
      reveal,
    )!;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: Color.lerp(
          colors.surfaceContainer,
          Colors.transparent,
          reveal,
        ),
        elevation: reveal > 0 ? 0 : null,
        shadowColor: reveal > 0 ? Colors.transparent : null,
        indicatorColor: Color.lerp(
          colors.secondaryContainer,
          Colors.white.withValues(alpha: 0.22),
          reveal,
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? selectedIconColor
                : iconColor,
          ),
        ),
        labelTextStyle: WidgetStateProperty.all(
          theme.textTheme.labelMedium?.copyWith(color: labelColor),
        ),
      ),
      child: NavigationBar(
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
