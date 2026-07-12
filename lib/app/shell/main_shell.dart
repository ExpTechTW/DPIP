import 'package:dpip/core/settings/home_chrome.dart';
import 'package:dpip/core/settings/home_sheet_extent.dart';
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
/// it; the bar then slides down and fades out as the sheet climbs
/// ([HomeChrome.navDismiss]) — the first chrome to clear — leaving the weather
/// unobstructed instead of an opaque strip.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  /// The go_router shell that owns the five branches, in the same order as the
  /// destinations built in [build].
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int? _lastIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = widget.navigationShell.currentIndex;

    // Reset Home's sheet as we *leave* Home — while it is hidden — so it is back
    // at rest (chrome shown) whenever Home is next shown, by a nav tap or a
    // programmatic route (e.g. a notification tap). Resetting on the way out,
    // not the way in, avoids both the stale full-extent flash and the chrome-
    // hidden dead-end a left-expanded sheet would otherwise cause.
    if (_lastIndex == 0 && index != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<HomeResetSignal>().fire();
      });
    }
    _lastIndex = index;

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
      body: widget.navigationShell,
      // Only Home dismisses the bar; every other tab keeps it (dismiss 0).
      bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: context.read<HomeSheetExtent>(),
        builder: (context, extent, child) {
          final dismiss = index == 0 ? HomeChrome.navDismiss(extent) : 0.0;
          // Slide the bar down by its own height and fade it out; stop it
          // catching taps once it is mostly gone so the sheet behind gets them.
          return IgnorePointer(
            ignoring: dismiss > 0.5,
            child: Opacity(
              opacity: 1 - dismiss,
              child: FractionalTranslation(
                translation: Offset(0, dismiss),
                child: child,
              ),
            ),
          );
        },
        child: NavigationBar(
          selectedIndex: index,
          destinations: destinations,
          onDestinationSelected: _onDestinationSelected,
        ),
      ),
    );
  }

  void _onDestinationSelected(int index) {
    // Re-entering Home (including re-tapping it while active) snaps its sheet
    // back to rest; the build-time guard above covers programmatic entry.
    if (index == 0) context.read<HomeResetSignal>().fire();
    widget.navigationShell.goBranch(
      index,
      // Tapping the active tab returns it to its initial route.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }
}
