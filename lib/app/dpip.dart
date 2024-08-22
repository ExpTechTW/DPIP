import 'dart:io';

import 'package:dpip/app/page/home/home.dart';
import 'package:dpip/app/page/map/map.dart';
import 'package:dpip/app/page/me/me.dart';
import 'package:dpip/app/page/report_list/report_list.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/need_location.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:dpip/global.dart';
import 'package:dpip/core/ios_get_location.dart';

class Dpip extends StatefulWidget {
  const Dpip({super.key});

  @override
  State<Dpip> createState() => _DpipState();
}

class _DpipState extends State<Dpip> {
  PageController controller = PageController();
  int currentActivePage = 0;
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Future.microtask(() => _checkAndShowLocationDialog());
  }

  void _initUserLocation() async {
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }
    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;
  }

  Future<void> _checkAndShowLocationDialog() async {
    if (!isUserLocationValid) {
      await showLocationDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentActivePage,
        destinations: [
          NavigationDestination(
            icon: const Icon(Symbols.home),
            selectedIcon: const Icon(Symbols.home, fill: 1),
            label: context.i18n.home,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.map),
            selectedIcon: const Icon(Symbols.map, fill: 1),
            label: context.i18n.map,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.summarize),
            selectedIcon: const Icon(Symbols.summarize, fill: 1),
            label: context.i18n.report,
          ),
          NavigationDestination(
            icon: const Icon(Symbols.person),
            selectedIcon: const Icon(Symbols.person, fill: 1),
            label: context.i18n.me,
          ),
        ],
        onDestinationSelected: (value) {
          setState(() {
            currentActivePage = value;
          });

          controller.jumpToPage(currentActivePage);
        },
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          HomePage(),
          MapPage(),
          ReportListPage(),
          MePage(),
        ],
      ),
    );
  }
}
