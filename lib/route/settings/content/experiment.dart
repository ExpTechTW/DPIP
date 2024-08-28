import "dart:io";

import "package:dpip/api/exptech.dart";
import "package:dpip/core/ios_get_location.dart";
import "package:dpip/global.dart";
import "package:dpip/route/welcome/pages/tos.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/util/need_location.dart";
import "package:dpip/util/speed_limit.dart";
import "package:flutter/material.dart";

class SettingsExperimentView extends StatefulWidget {
  const SettingsExperimentView({super.key});

  @override
  State<SettingsExperimentView> createState() => _SettingsExperimentViewState();
}

class _SettingsExperimentViewState extends State<SettingsExperimentView> with WidgetsBindingObserver {
  bool monitorEnabled = Global.preference.getBool("monitor") ?? false;
  double userLat = 0;
  double userLon = 0;
  bool isUserLocationValid = false;

  void _initUserLocation() async {
    if (Platform.isIOS && (Global.preference.getBool("auto-location") ?? false)) {
      await getSavedLocation();
    }

    if (!mounted) return;

    userLat = Global.preference.getDouble("user-lat") ?? 0.0;
    userLon = Global.preference.getDouble("user-lon") ?? 0.0;

    isUserLocationValid = (userLon == 0 || userLat == 0) ? false : true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          SwitchListTile(
            title: Text(context.i18n.enable_monitor),
            value: monitorEnabled,
            onChanged: (value) async {
              int limit = Global.preference.getInt("limit-monitor") ?? 0;
              int now = DateTime.now().millisecondsSinceEpoch;
              if (now - limit < 10000) {
                showLimitDialog(context);
              } else {
                Global.preference.setInt("limit-monitor", now);
                if (!value) {
                  String token = Global.preference.getString("fcm-token") ?? "";
                  if (token != "") {
                    await ExpTech().sendMonitor(token, "0");
                  }
                  await Global.preference.setBool("monitor", false);
                  setState(() => monitorEnabled = false);
                } else {
                  _initUserLocation();
                  if (!isUserLocationValid && !(Global.preference.getBool("auto-location") ?? false)) {
                    await showLocationDialog(context);
                  } else {
                    await Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute(builder: (context) => const WelcomeTosPage()),
                    );
                    setState(() => monitorEnabled = Global.preference.getBool("monitor") ?? false);
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
