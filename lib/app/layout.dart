import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class NavigationLocation extends NavigationDrawerDestination {
  NavigationLocation({super.key, required Icon super.icon, required super.label})
    : super(selectedIcon: Icon(icon.icon, fill: 1));
}

class AppLayout extends StatelessWidget {
  final String location;
  final StatefulNavigationShell navigationShell;

  AppLayout({super.key, required this.location, required this.navigationShell});

  final _scaffold = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffold,
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            top: 24,
            left: 24,
            child: SafeArea(
              child: BlurredIconButton(onPressed: () => context.push('/map/monitor'), icon: Icon(Symbols.map_rounded)),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: SafeArea(
              child: BlurredIconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(Symbols.settings_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
