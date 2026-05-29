/// Single stateful shell hosting all 5 bottom-nav tabs via [IndexedStack].
///
/// Tabs preserve state between switches (no rebuild) and the bottom nav is
/// fixed at the bottom of the screen. Routes can pass [initialTab] for deep
/// linking; the shell exposes [NewHomeShell.of] for descendants to switch
/// tabs programmatically.
library;

import 'package:dpip/app/map/page.dart';
import 'package:dpip/app/new_home/events/page.dart';
import 'package:dpip/app/new_home/menu/page.dart';
import 'package:dpip/app/new_home/page.dart';
import 'package:dpip/app/new_home/weather/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Home tab index.
const int tabHome = 0;

/// Events timeline tab index.
const int tabEvents = 1;

/// Map tab index.
const int tabMap = 2;

/// Weather detail tab index.
const int tabWeather = 3;

/// Menu tab index.
const int tabMenu = 4;

/// Single-instance stateful shell that hosts every tab.
class NewHomeShell extends StatefulWidget {
  /// The tab to display on first build.
  final int initialTab;

  /// Creates a [NewHomeShell] starting on [initialTab].
  const NewHomeShell({super.key, this.initialTab = tabHome});

  /// Returns the nearest enclosing [NewHomeShellState], or `null` when not
  /// inside a shell.
  static NewHomeShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<NewHomeShellState>();

  @override
  State<NewHomeShell> createState() => NewHomeShellState();
}

/// Public state allowing descendants to call [setTab].
class NewHomeShellState extends State<NewHomeShell> {
  late int _tabIndex = widget.initialTab;
  late final Set<int> _visited = {_tabIndex};

  /// Switches the active tab.
  void setTab(int index) {
    if (index == _tabIndex) return;
    setState(() {
      _visited.add(index);
      _tabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _LazyTab(visited: _visited.contains(tabHome), child: const NewHomePage()),
          _LazyTab(visited: _visited.contains(tabEvents), child: const EventsPage()),
          _LazyTab(
            visited: _visited.contains(tabMap),
            child: const MapPage(showBackButton: false),
          ),
          _LazyTab(
            visited: _visited.contains(tabWeather),
            child: const WeatherDetailPage(),
          ),
          _LazyTab(visited: _visited.contains(tabMenu), child: const MenuPage()),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _tabIndex,
        onTap: setTab,
      ),
    );
  }
}

/// Builds [child] only after its tab has been visited at least once, then
/// keeps it alive in the stack for subsequent visits.
class _LazyTab extends StatelessWidget {
  final bool visited;
  final Widget child;

  const _LazyTab({required this.visited, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!visited) return const SizedBox.shrink();
    return child;
  }
}

/// Fixed-position bottom navigation bar using the Material 3 [NavigationBar].
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        height: 72,
        backgroundColor: colors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        indicatorColor: colors.secondaryContainer,
        indicatorShape: const StadiumBorder(),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? colors.onSecondaryContainer
                : colors.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = context.texts.labelMedium ?? const TextStyle();
          return base.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? .w700 : .w500,
            color: states.contains(WidgetState.selected)
                ? colors.onSurface
                : colors.onSurfaceVariant,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        destinations: [
          NavigationDestination(
            icon: const Icon(Symbols.home_rounded),
            selectedIcon: const Icon(Symbols.home_rounded, fill: 1),
            label: '首頁'.i18n,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.history_rounded),
            selectedIcon: const Icon(Symbols.history_rounded, fill: 1),
            label: '事件'.i18n,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.map_rounded),
            selectedIcon: const Icon(Symbols.map_rounded, fill: 1),
            label: '地圖'.i18n,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.partly_cloudy_day_rounded),
            selectedIcon: const Icon(Symbols.partly_cloudy_day_rounded, fill: 1),
            label: '天氣'.i18n,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.menu_rounded),
            selectedIcon: const Icon(Symbols.menu_rounded, fill: 1),
            label: '選單'.i18n,
          ),
        ],
      ),
    );
  }
}

/// Backwards-compat shim — keeps the old name used elsewhere in routing.
///
/// Routes that wrapped a page in [NewHomeLayout] now produce a [NewHomeShell].
/// The [child] is ignored because each tab has its own dedicated widget.
class NewHomeLayout extends StatelessWidget {
  /// Ignored — the shell owns its own tab widgets. Kept for source compat.
  final Widget child;

  /// Creates a [NewHomeLayout]. The [child] argument is ignored.
  const NewHomeLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) => const NewHomeShell();
}
