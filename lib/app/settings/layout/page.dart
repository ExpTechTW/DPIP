import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/list/list_section.dart';
import '../../home/home_display_mode.dart';

class SettingsLayoutPage extends StatelessWidget {
  const SettingsLayoutPage({super.key});

  static const route = '/settings/layout';

  @override
  Widget build(BuildContext context) {
    return ListSection(
      title: '首頁樣式'.i18n,
      children: [
        Consumer<SettingsUserInterfaceModel>(
          builder: (context, model, child) {
            final tiles = [
              SwitchListTile(
                title: Text('雷達回波'.i18n),
                value: model.isEnabled(HomeDisplaySection.radar),
                onChanged: (v) => model.toggleSection(HomeDisplaySection.radar, v),
              ),
              SwitchListTile(
                title: Text('天氣預報(24h)'.i18n),
                value: model.isEnabled(HomeDisplaySection.forecast),
                onChanged: (v) => model.toggleSection(HomeDisplaySection.forecast, v),
              ),
              SwitchListTile(
                title: Text('歷史事件'.i18n),
                value: model.isEnabled(HomeDisplaySection.history),
                onChanged: (v) => model.toggleSection(HomeDisplaySection.history, v),
              ),
            ];
            return Column(
              children: ListTile.divideTiles(
                context: context,
                tiles: tiles,
              ).toList(),
            );
          },
        ),
      ],
    );
  }
}
