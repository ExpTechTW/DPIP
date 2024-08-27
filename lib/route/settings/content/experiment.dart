import "package:dpip/global.dart";
import "package:dpip/route/settings/content/root.dart";
import "package:dpip/route/welcome/pages/dev.dart";
import "package:dpip/route/welcome/pages/tos.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";

class SettingsExperimentView extends StatefulWidget {
  const SettingsExperimentView({super.key});

  @override
  State<SettingsExperimentView> createState() => _SettingsExperimentViewState();
}

class _SettingsExperimentViewState extends State<SettingsExperimentView> with WidgetsBindingObserver {
  bool monitorEnabled = Global.preference.getBool("monitor") ?? false;
  bool devEnabled = Global.preference.getBool("dev") ?? false;

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
              if (!value) {
                await Global.preference.setBool("monitor", false);
                setState(() => monitorEnabled = false);
              } else {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => const WelcomeTosPage()),
                );
                setState(() => monitorEnabled = Global.preference.getBool("monitor") ?? false);
              }
            },
          ),
          SwitchListTile(
            title: Text(context.i18n.enable_dev),
            value: devEnabled,
            onChanged: (value) async {
              if (!value) {
                await Global.preference.setBool("dev", false);
                setState(() => devEnabled = false);
              } else {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => const WelcomeDevPage()),
                );
                setState(() => devEnabled = Global.preference.getBool("dev") ?? false);
              }
              SettingsRootView.updateDev();
            },
          ),
        ],
      ),
    );
  }
}
