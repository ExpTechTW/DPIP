import 'package:dpip/global.dart';
import 'package:dpip/route/welcome/tos.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';

class SettingsExperimentView extends StatefulWidget {
  const SettingsExperimentView({super.key});

  @override
  State<SettingsExperimentView> createState() => _SettingsExperimentViewState();
}

class _SettingsExperimentViewState extends State<SettingsExperimentView> with WidgetsBindingObserver {
  bool monitorEnabled = Global.preference.getBool("monitor") ?? false;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          SwitchListTile(
            title: const Text("啟用強震監視器"),
            value: monitorEnabled,
            onChanged: (value) async {
              if (!value) {
                await Global.preference.setBool("monitor", false);
                setState(() => monitorEnabled = false);
              } else {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => const TOSPage()),
                );
                setState(() => monitorEnabled = Global.preference.getBool("monitor") ?? false);
              }
            },
          ),
        ],
      ),
    );
  }
}
