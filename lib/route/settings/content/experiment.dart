import 'package:dpip/global.dart';
import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';

import '../../welcome/tos.dart';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              // FIXME: workaround waiting for upstream PR to merge
              // https://github.com/material-foundation/flutter-packages/pull/599
              tileColor: monitorEnabled ? context.colors.primaryContainer : context.colors.surfaceVariant,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                "啟用強震監視器",
                style: TextStyle(
                  color: monitorEnabled ? context.colors.onPrimaryContainer : context.colors.onSurfaceVariant,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
              value: monitorEnabled,
              onChanged: (value) {
                if (!value) {
                  Global.preference.setBool("monitor", false);
                  monitorEnabled = false;
                  setState(() {});
                } else {
                  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const TOSPage()),
                    (Route<dynamic> route) => route.isFirst,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
