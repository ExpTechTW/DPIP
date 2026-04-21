library;

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:dpip/core/i18n.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// [navigationShell] 管理狀態和分頁切換。
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final destinations = [
      (sf: 'house.fill', cupertino: CupertinoIcons.house_fill, label: '首頁'.i18n),
      (sf: 'clock.fill', cupertino: CupertinoIcons.clock_fill, label: '時間'.i18n),
    ];

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: PlatformInfo.isIOS26OrHigher()
          ? IOS26NativeTabBar(
              selectedIndex: navigationShell.currentIndex,
              onTap: _onDestinationSelected,
              destinations: [
                for (final d in destinations)
                  AdaptiveNavigationDestination(icon: d.sf, label: d.label),
              ],
            )
          : CupertinoTabBar(
              currentIndex: navigationShell.currentIndex,
              onTap: _onDestinationSelected,
              items: [
                for (final d in destinations)
                  BottomNavigationBarItem(
                    icon: Icon(d.cupertino),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}
