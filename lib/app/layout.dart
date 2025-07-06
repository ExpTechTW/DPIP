import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';
import 'package:dpip/models/settings/map.dart';

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
              child: Selector<SettingsMapModel, MapLayer>(
                selector: (context, model) => model.layer,
                builder: (context, layer, child) {
                  return BlurredIconButton(
                    icon: const Icon(Symbols.map_rounded),
                    onPressed: () => context.push(MapPage.route(layer: layer)),
                    elevation: 2,
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: SafeArea(
              child: BlurredIconButton(
                icon: const Icon(Symbols.settings_rounded),
                onPressed: () => context.push('/settings'),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
