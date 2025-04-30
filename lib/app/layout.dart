import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class NavigationLocation extends NavigationDestination {
  final String location;

  NavigationLocation({super.key, required this.location, required Icon super.icon, required super.label})
    : super(selectedIcon: Icon(icon.icon, fill: 1));
}

class AppLayout extends StatelessWidget {
  final String location;
  final StatefulNavigationShell navigationShell;

  const AppLayout({super.key, required this.location, required this.navigationShell});

  List<NavigationLocation> get locations => [
    NavigationLocation(location: '/home', icon: Icon(Symbols.home_rounded), label: 'Home'),
    NavigationLocation(location: '/history', icon: Icon(Symbols.clock_loader_10_rounded), label: 'History'),
    NavigationLocation(location: '/map', icon: Icon(Symbols.map_rounded), label: 'Map'),
    NavigationLocation(location: '/more', icon: Icon(Symbols.note_stack_add_rounded), label: 'More'),
    NavigationLocation(location: '/me', icon: Icon(Symbols.person_rounded), label: 'Me'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SizedBox(
        height: 80 + context.padding.bottom,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: NavigationBar(
              backgroundColor: context.colors.surfaceContainerHigh.withValues(alpha: 0.8),
              selectedIndex: navigationShell.currentIndex,
              destinations: locations,
              onDestinationSelected: (value) => navigationShell.goBranch(value),
            ),
          ),
        ),
      ),
    );
  }
}
